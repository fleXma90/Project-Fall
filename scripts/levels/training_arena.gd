class_name TrainingArena
extends Node3D
## Offene Plattform mit fünf Szenarien:
## - DESCENT (Abstieg, Standard): Ebene 1 wie MIXED; nach dem Räumen öffnet sich eine Luke (regulärer
##   Abstieg ohne Schaden), ein Sturz über die Kante führt jederzeit mit Sturzschaden auf Ebene 2
##   (Ring um einen Schacht, erneut zwei Scraplings + ein Funkenwerfer). Sturz von Ebene 2 = Niederlage.
## - MIXED (M2C): zwei Scraplings und ein Funkenwerfer.
## - GROUP (M2B): drei Scraplings.
## - COMBAT (M2A-Duell): genau ein Scrapling (Vergleichsbasis).
## - TRAINING (M1): drei passive Dummies mit Auto-Respawn, Spieler-Respawn nach Fall.
## Beide Gegnertypen teilen nur eine kleine Schnittstelle (Duck Typing): Signal `defeated`, `is_defeated`,
## `fall_out()`, `stop_combat()`, `set_active()`, `reset_to()`, `target`, `neighbors`.
## Benommenheitsprofile A/B wirken nur auf die Scrapling-Instanzen (Scrapling.hit_stun), nie auf die
## geteilte Tuning-Ressource. Die Killhöhe ist keine Randbarriere: Sie liegt weit unter der Plattform.

signal player_fell(count: int)
signal dummy_defeated(dummy: TrainingDummy, reason: TrainingDummy.DefeatReason)
## Begegnung entschieden (genau einmal pro Runde): true = alle Gegner besiegt, false = Spieler besiegt.
signal encounter_finished(victory: bool)
## Arena wurde neu gestartet (Szenario-/Profilwechsel, Neustart, Spielerfall im Kampf).
signal restarted
## Rundenzusammenfassung einer Kampfrunde (genau einmal pro Runde, auch bei Spielerfall/Abbruch).
signal round_summarized(stats: EncounterStats)
## Ein Energiebolzen wurde erzeugt (für Tests/Auswertung).
signal projectile_spawned(bolt: SparkBolt)
## Abstieg: Ebene 1 geräumt, Luke offen.
signal floor_cleared(index: int)
## Abstieg: Spieler hat Ebene 1 verlassen (regular = durch die offene Luke) und fällt zum Landepunkt.
signal descent_started(regular: bool, landing_point: Vector3)
## Abstieg: Spieler ist auf Ebene 2 gelandet (fall_damage 0 bei regulärem Abstieg).
signal floor_landed(fall_damage: float)
## M3A: Ein Szenario hat begonnen; run ist der neue Abstiegs-Run (null in allen anderen Szenarien).
signal run_started(run: RunState)
## M3A: XP-Orb eingesammelt (bzw. beim Räumen gutgeschrieben).
signal xp_collected(amount: int)
## M3A: Pflichtauswahl 1 aus 3 nach dem Räumen eines nicht finalen Floors.
signal floor_reward_offered(choices: Array[StringName])

enum Mode { TRAINING, COMBAT, GROUP, MIXED, DESCENT }  # COMBAT = Duell (M2A)
enum StunProfile { BASE, SHORT }
## Schussprofil des Funkenwerfers: STANDARD = Werte der Tuning-Ressource, SHARP = spätere Festlegung + schnellerer Bolzen.
enum ShotProfile { STANDARD, SHARP }
enum Encounter { NONE, RUNNING, VICTORY, DEFEAT }
## Fortschritt im Abstieg (nur Mode.DESCENT; sonst NONE).
enum Descent { NONE, FLOOR_1, FLOOR_1_CLEARED, DROPPING, FLOOR_2 }

const BOLT_SCENE: PackedScene = preload("res://scenes/combat/spark_bolt.tscn")

@export var kill_height: float = -5.0
@export var player_respawn_delay: float = 0.55
@export var dummy_respawn_delay: float = 2.5
## Profil B (seit M2C Arbeitsstand): kürzere Scrapling-Benommenheit. Profil A nutzt den Wert der Tuning-Ressource.
@export var short_hit_stun: float = 0.20
## Schussprofil „Scharf“ (Testprofil): nur diese drei Werte weichen von der Tuning-Ressource ab.
@export var sharp_charge_time: float = 0.70
@export var sharp_commit_time: float = 0.55
@export var sharp_projectile_speed: float = 11.0

@export_group("Abstieg")
## Einmaliger Sturzschaden beim Sturz über die Kante (Anteil max HP, mindestens 1; kann tödlich sein).
@export var fall_damage_fraction: float = 0.12
## Schutz nur gegen Kampftreffer nach der Landung (s); kein Schutz vor fehlendem Boden.
@export var landing_protection: float = 0.75
## Landepunkt: Mindestabstand zu Kanten/Schacht und zu lebenden Gegnern der Ebene 2.
@export var landing_edge_margin: float = 1.2
@export var landing_enemy_clearance: float = 3.0
## Unter dieser Höhe hat der Spieler Ebene 1 unumkehrbar verlassen (Oberkante 0).
@export var descent_leave_height: float = -0.6
## Nach dem Verlassen klingt die horizontale Bewegung mit dieser Zeitkonstante ab: senkrechter Fall wie durch die Luke.
@export var fall_settle_time: float = 0.12
## Gegner der Ebene 1 gelten darunter als abgestürzt (bevor sie Ebene 2 erreichen).
@export var upper_enemy_kill_height: float = -3.0
## Killhöhe unter Ebene 2 (Oberkante − diese Tiefe).
@export var lower_kill_depth: float = 5.0
## Übergang (nur Darstellung), an die Fallhöhe gekoppelt statt an Zeit: Fortschritt 0 beim Verlassen von Ebene 1,
## 1 kurz vor der Landung. Ebene 1 zieht nach oben weg und löst sich auf, Ebene 2 taucht überlappend aus der Tiefe auf.
@export var upper_fade_range: Vector2 = Vector2(0.05, 0.5)
@export var upper_rise: float = 6.0
@export var lower_reveal_range: Vector2 = Vector2(0.35, 0.8)

@export_group("Run-Progression")
## XP je besiegtem Gegner (HP- und Kantensieg gleich), als sichtbare Orbs zu je höchstens xp_per_orb.
@export var scrapling_xp: int = 30
@export var sparker_xp: int = 40
@export var xp_per_orb: int = 10
## 0 = zufälliger Run-Seed; Tests setzen einen festen Wert für reproduzierbare Upgrade-Auswahl.
@export var run_seed: int = 0
## Zeit zwischen dem Räumen von Ebene 1 und der Upgrade-Auswahl (liegende Orbs werden eingesaugt);
## sind dann noch Orbs unterwegs, wird bis reward_max_delay gewartet und der Rest gutgeschrieben.
@export var reward_delay: float = 0.8
@export var reward_max_delay: float = 1.6

@export_group("Floor-Vorlagen")
## Höhe der Oberkante von Ebene 2 relativ zu Ebene 1.
@export var lower_floor_offset: float = -10.0
## 0 = Floor-Seed aus dem Run-Seed abgeleitet (getrennt vom Upgrade-Zufall); Test/Debug: fester Wert.
@export var floor_seed: int = 0
## Test-/Debughilfe: feste Vorlagen-IDs [Ebene 1, Ebene 2] statt Zufallswahl.
@export var forced_floor_ids: Array[StringName] = []

var mode: Mode = Mode.TRAINING
var stun_profile: StunProfile = StunProfile.BASE
var shot_profile: ShotProfile = ShotProfile.STANDARD
var encounter: Encounter = Encounter.NONE
var player: PlayerController = null
var player_fall_count: int = 0
var dummy_hp_defeats: int = 0
var dummy_fall_defeats: int = 0
var dummies: Array[TrainingDummy] = []
## Alle Scrapling-Instanzen der Szene; active_enemies = an der aktuellen Runde beteiligte Scraplings.
var enemies: Array[Scrapling] = []
var active_enemies: Array[Scrapling] = []
## Beteiligte Funkenwerfer der aktuellen Runde (MIXED: genau einer).
var active_shooters: Array[Sparker] = []
## Abstieg: Gegner der Ebene 2 (warten ohne Ziel, bis der Spieler landet).
var lower_enemies: Array[Scrapling] = []
var lower_shooters: Array[Sparker] = []
var descent: Descent = Descent.NONE
## true = letzter Abstieg durch die offene Luke (kein Sturzschaden).
var descent_regular: bool = false
var landing_point: Vector3 = Vector3.ZERO
var last_fall_damage: float = 0.0
## M3A: aktueller Abstiegs-Run (nur Mode.DESCENT) und Floor-Clear-Belohnung.
var run: RunState = null
## Anspruch auf ein Floor-Upgrade besteht (Floor geräumt), Auswahl steht aus.
var reward_pending: bool = false
var reward_offered: bool = false
var reward_choices: Array[StringName] = []
## Laufende Rundenauswertung (nur Kampfszenarien) und die zuletzt abgeschlossene.
var stats: EncounterStats = null
var last_stats: EncounterStats = null

var _generation: int = 0
var _tracked_player_hp: float = 0.0
## Geteilte Tuning-Ressource (unverändert) und Laufzeitkopie für das Schussprofil „Scharf“.
var _base_sparker_tuning: SparkerTuning
var _sharp_sparker_tuning: SparkerTuning
var _base_fog_height: float = 0.0
## Übergang: Fortschritt und daraus abgeleitete Blenden (0..1), lesbar für Tests.
var transition_progress: float = 0.0
var upper_fade: float = 0.0
var lower_reveal: float = 0.0
var _upper_base_position: Vector3
var _lower_base_position: Vector3
## M3B: Vorlagen des aktuellen Abstiegs (null außerhalb des Abstiegs).
var upper_template: FloorTemplate = null
var lower_template: FloorTemplate = null
## Ausgangshöhen der zurückgelassenen Gegner der Ebene 1 (sie ziehen mit der Ebene nach oben weg).
var _upper_combatant_base_y: Dictionary = {}
## Ebene, auf der der Kampf läuft (1 bis zur Landung auf Ebene 2).
var _active_floor: int = 1
## XP von Gegnern, die erst nach dem Verlassen ihrer Ebene besiegt wurden (nur bei Clear gutgeschrieben).
var _left_floor_xp: int = 0

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var combat_player_spawn: Marker3D = $CombatPlayerSpawn
@onready var enemy_spawn: Marker3D = $EnemySpawn
@onready var group_player_spawn: Marker3D = $GroupPlayerSpawn
@onready var group_enemy_spawns: Array[Marker3D] = [$GroupEnemySpawnA, $GroupEnemySpawnB, $GroupEnemySpawnC]
@onready var mixed_player_spawn: Marker3D = $MixedPlayerSpawn
@onready var mixed_scrapling_spawns: Array[Marker3D] = [$MixedScraplingSpawnA, $MixedScraplingSpawnB]
@onready var mixed_sparker_spawn: Marker3D = $MixedSparkerSpawn
## Duellgegner (zugleich erster Gruppen-/Mixed-Scrapling).
@onready var enemy: Scrapling = $Scrapling
@onready var sparker: Sparker = $Sparker
@onready var effects: Node3D = $Effects
@onready var projectiles: Node3D = $Projectiles
@onready var pickups: Node3D = $Pickups
## Feste Testarena (Training/Duell/Gruppe/Mischkampf); im Abstieg deaktiviert.
@onready var fixed_floor: FloorGeometry = $Platform
@onready var fixed_hatch: DescentHatch = $Platform/Hatch
@onready var run_floors: Node3D = $RunFloors
## Aktive Ebenen: außerhalb des Abstiegs die feste Arena, im Abstieg die Instanzen der gewählten Vorlagen.
@onready var upper_floor: FloorGeometry = $Platform
@onready var hatch: DescentHatch = $Platform/Hatch
var lower_floor: FloorGeometry = null
@onready var environment: Environment = ($WorldEnvironment as WorldEnvironment).environment
@onready var depth_backdrop: DepthBackdrop = $DepthBackdrop


func _ready() -> void:
	for node in find_children("*", "TrainingDummy", true, false):
		var dummy := node as TrainingDummy
		dummies.append(dummy)
		dummy.defeated.connect(_on_dummy_defeated)
	enemies = [$Scrapling, $Scrapling2, $Scrapling3]
	lower_enemies = [$LowerScraplingA, $LowerScraplingB]
	lower_shooters = [$LowerSparker]
	# Verbindungen einmalig; Neustarts verbinden nichts erneut.
	for e: Scrapling in enemies + lower_enemies:
		e.defeated.connect(func(defeated_enemy: Scrapling, reason: Scrapling.DefeatReason) -> void:
			_on_combatant_defeated(defeated_enemy, reason == Scrapling.DefeatReason.FALL))
		e.attack_interrupted.connect(_on_enemy_attack_interrupted)
		e.weapon.swing_started.connect(_on_enemy_swing_started.unbind(2))
		e.weapon.active_started.connect(_on_enemy_active_started.unbind(1))
		e.set_active(false)
	var all_shooters: Array[Sparker] = [sparker]
	all_shooters.append_array(lower_shooters)
	for s in all_shooters:
		s.defeated.connect(func(defeated_sparker: Sparker, reason: Sparker.DefeatReason) -> void:
			_on_combatant_defeated(defeated_sparker, reason == Sparker.DefeatReason.FALL))
		s.attack_interrupted.connect(_on_sparker_interrupted)
		s.fired.connect(_on_sparker_fired)
		s.set_active(false)
	# Ebenen im Abstieg haben Löcher/Kerben: lokaler Umweg statt Stehenbleiben an der Lücke.
	for e in lower_enemies:
		e.gap_detour = true
	for s in lower_shooters:
		s.gap_detour = true
	# Eigene Kopie: Die Nebelhöhe folgt der aktiven Ebene, die Szenenressource bleibt unverändert.
	environment = environment.duplicate() as Environment
	($WorldEnvironment as WorldEnvironment).environment = environment
	_base_fog_height = environment.fog_height
	_upper_base_position = upper_floor.position
	_base_sparker_tuning = sparker.tuning
	_sharp_sparker_tuning = _base_sparker_tuning.duplicate() as SparkerTuning
	_sharp_sparker_tuning.charge_time = sharp_charge_time
	_sharp_sparker_tuning.commit_time = sharp_commit_time
	_sharp_sparker_tuning.projectile_speed = sharp_projectile_speed


func setup(p: PlayerController) -> void:
	player = p
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	player.health_changed.connect(_on_player_health_changed)
	set_mode(mode)


func is_combat_mode() -> bool:
	return mode != Mode.TRAINING


## Szenariowechsel setzt die jeweilige Begegnung vollständig zurück.
func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_apply_participants()
	restart()


## Profilwechsel nur mit vollständigem Neustart (nie mitten in einem Angriff).
## Schussprofilwechsel nur mit vollständigem Neustart (nie mitten in einem Aufladen).
func set_shot_profile(profile: ShotProfile) -> void:
	shot_profile = profile
	restart()


func shot_profile_name() -> String:
	var t := current_sparker_tuning()
	return "%s (Festlegung %.2f s, Bolzen %.0f m/s)" % ["Scharf" if shot_profile == ShotProfile.SHARP else "Standard",
			t.commit_time, t.projectile_speed]


func current_sparker_tuning() -> SparkerTuning:
	return _sharp_sparker_tuning if shot_profile == ShotProfile.SHARP else _base_sparker_tuning


func set_stun_profile(profile: StunProfile) -> void:
	stun_profile = profile
	restart()


func current_hit_stun() -> float:
	return short_hit_stun if stun_profile == StunProfile.SHORT else enemy.tuning.hit_stun


static func scenario_name(m: Mode) -> String:
	match m:
		Mode.COMBAT:
			return "Duell"
		Mode.GROUP:
			return "Gruppe"
		Mode.MIXED:
			return "Gemischt"
		Mode.DESCENT:
			return "Abstieg"
	return "Training"


func profile_name() -> String:
	return "%s (%s, %.2f s)" % ["B" if stun_profile == StunProfile.SHORT else "A",
			"kurz" if stun_profile == StunProfile.SHORT else "Basis", current_hit_stun()]


## Alle Gegner der aktuellen Runde (Scraplings und Funkenwerfer).
func combatants() -> Array[Node3D]:
	var all: Array[Node3D] = []
	all.append_array(active_enemies)
	all.append_array(active_shooters)
	return all


func enemies_remaining() -> int:
	var remaining := 0
	for c in combatants():
		if not bool(c.get("is_defeated")):
			remaining += 1
	return remaining


## Spielerstart: im Abstieg aus der Vorlage von Ebene 1, sonst der Marker des Szenarios.
func player_start_transform() -> Transform3D:
	if mode == Mode.DESCENT and upper_template != null:
		var start := upper_template.player_start
		return Transform3D(Basis.IDENTITY, upper_floor.to_global(Vector3(start.x, 0.05, start.y)))
	return current_player_spawn().global_transform


func current_player_spawn() -> Marker3D:
	match mode:
		Mode.COMBAT:
			return combat_player_spawn
		Mode.GROUP:
			return group_player_spawn
		Mode.MIXED, Mode.DESCENT:
			return mixed_player_spawn
	return player_spawn


func _apply_participants() -> void:
	for dummy in dummies:
		dummy.set_active(mode == Mode.TRAINING)
	active_enemies.clear()
	active_shooters.clear()
	match mode:
		Mode.COMBAT:
			active_enemies.append(enemies[0])
		Mode.GROUP:
			active_enemies.append_array(enemies)
		Mode.MIXED, Mode.DESCENT:
			active_enemies.append(enemies[0])
			active_enemies.append(enemies[1])
			active_shooters.append(sparker)
	var all := combatants()
	for e in enemies:
		e.set_active(active_enemies.has(e))
		e.neighbors = _others(e, all)
		e.gap_detour = mode == Mode.DESCENT  # Vorlagen mit Löchern/Kerben; feste Arenen unverändert
	sparker.set_active(active_shooters.has(sparker))
	sparker.neighbors = _others(sparker, all)
	sparker.gap_detour = mode == Mode.DESCENT
	var lower := lower_combatants()
	var no_neighbors: Array[Node3D] = []
	for c in lower:
		c.call("set_active", mode == Mode.DESCENT)
		c.set("neighbors", _others(c, lower) if mode == Mode.DESCENT else no_neighbors)


## Gegner der Ebene 2 (unabhängig davon, ob sie gerade kämpfen).
func lower_combatants() -> Array[Node3D]:
	var all: Array[Node3D] = []
	all.append_array(lower_enemies)
	all.append_array(lower_shooters)
	return all


## Gegner der Ebene 1 im Abstieg (dieselben Instanzen wie im Mischkampf).
func upper_combatants() -> Array[Node3D]:
	var all: Array[Node3D] = [enemies[0], enemies[1], sparker]
	return all


## Aktuelle Ebene im Abstieg (1 oder 2); außerhalb des Abstiegs immer 1.
func floor_index() -> int:
	return 2 if descent == Descent.DROPPING or descent == Descent.FLOOR_2 else 1


func lower_floor_height() -> float:
	return lower_floor.global_position.y if lower_floor != null else lower_floor_offset


## Nachbarn für die Abstandshaltung; leer, wenn self_node nicht an der Runde teilnimmt.
static func _others(self_node: Node3D, all: Array[Node3D]) -> Array[Node3D]:
	var others: Array[Node3D] = []
	if not all.has(self_node):
		return others
	for other in all:
		if other != self_node:
			others.append(other)
	return others


## Vollständiger Neustart des aktuellen Szenarios: Beteiligte an sichere Startpositionen, HP, Zustände,
## Timer, Trefferlisten, Effekte, Projektile, ausstehende Timer und gehaltene Eingaben zurücksetzen.
func restart() -> void:
	_finish_stats(EncounterStats.Outcome.ABORTED)  # nur falls eine Runde noch lief
	_generation += 1  # verwirft ausstehende Respawn-Timer der alten Runde
	player_fall_count = 0
	dummy_hp_defeats = 0
	dummy_fall_defeats = 0
	for effect in effects.get_children():
		effect.queue_free()
	clear_projectiles()
	# M3A: Jeder Neustart im Abstieg beginnt einen neuen Run (Basiswerte); andere Szenarien ohne Run.
	# M3B: Der Run wählt zuerst seine Floor-Vorlagen; Spawns und Start kommen aus ihnen.
	run = RunState.new(run_seed, floor_seed) if mode == Mode.DESCENT else null
	_build_run_floors()
	_reset_floors()
	if mode == Mode.TRAINING:
		encounter = Encounter.NONE
		for dummy in dummies:
			dummy.respawn()
			dummy.reset_stats()
	else:
		var spawns: Array[Marker3D] = []
		match mode:
			Mode.COMBAT:
				spawns.append(enemy_spawn)
			Mode.GROUP:
				spawns.append_array(group_enemy_spawns)
			Mode.MIXED:
				spawns.append_array(mixed_scrapling_spawns)
		var look_at_point := player_start_transform().origin
		var enemy_spawns: Array[Transform3D] = []
		var shooter_spawns: Array[Transform3D] = []
		if mode == Mode.DESCENT:
			enemy_spawns = _slot_transforms(upper_floor, _pick_slots(upper_template.melee_slots, active_enemies.size()))
			shooter_spawns = _slot_transforms(upper_floor, _pick_slots(upper_template.ranged_slots, active_shooters.size()))
		else:
			for marker in spawns:
				enemy_spawns.append(marker.global_transform)
			shooter_spawns.append(mixed_sparker_spawn.global_transform)
		for i in active_enemies.size():
			var e := active_enemies[i]
			e.reset_to(enemy_spawns[i])
			if mode != Mode.COMBAT:
				_face(e, look_at_point)
			e.hit_stun = current_hit_stun()
			e.target = player
		for i in active_shooters.size():
			var s := active_shooters[i]
			s.tuning = current_sparker_tuning()  # vor reset_to: Werte gelten ab der neuen Runde
			s.reset_to(shooter_spawns[i])
			_face(s, look_at_point)
			s.target = player
		if mode == Mode.DESCENT:
			_reset_lower_combatants()
		encounter = Encounter.RUNNING
	if player != null:
		player.set_run(run)  # vor reset_full: volle Basis-HP
		player.fall_count = 0
		player.reset_full(player_start_transform())
		_tracked_player_hp = player.hp
	if is_combat_mode():
		# Erst nach dem Spieler-Reset anlegen: die Rücksetzung der HP ist kein Schaden.
		_begin_stats()
	InputRouter.release_all()
	run_started.emit(run)
	restarted.emit()


func _begin_stats() -> void:
	stats = EncounterStats.new()
	stats.scenario = scenario_name(mode)
	if mode == Mode.DESCENT:
		stats.scenario += " · Ebene %d" % floor_index()
		var template := lower_template if floor_index() == 2 else upper_template
		if template != null:
			stats.floor_template = "%s (%s)" % [template.display_name, template.risk_name()]
	stats.profile = profile_name()
	stats.has_shooter = not active_shooters.is_empty()
	if stats.has_shooter:
		stats.profile += " · Schuss " + shot_profile_name()
	stats.enemies_total = combatants().size()


## Ebenen, Luke, Nebel und Sichtbarkeit auf den Szenariostart zurücksetzen.
func _reset_floors() -> void:
	descent = Descent.FLOOR_1 if mode == Mode.DESCENT else Descent.NONE
	descent_regular = false
	last_fall_damage = 0.0
	_active_floor = 1
	_left_floor_xp = 0
	reward_pending = false
	reward_offered = false
	reward_choices.clear()
	_clear_orbs()
	hatch.close()
	upper_floor.set_enabled(true)
	# Ebene 2 existiert im Abstieg physisch an ihrer Grundposition, bleibt aber bis zum Übergang verborgen.
	if lower_floor != null:
		lower_floor.global_position = _lower_base_position
		lower_floor.set_enabled(true)
	for c in upper_combatants():
		c.set_physics_process(true)
	_upper_combatant_base_y.clear()
	_apply_transition(0.0)
	if mode == Mode.DESCENT:
		# Nach einem Abstieg sind die aktiven Gegner die der Ebene 2: auf Ebene 1 zurückschalten.
		active_enemies.assign([enemies[0], enemies[1]])
		active_shooters.assign([sparker])


## M3B: Ebenen des Runs aus den gewählten Vorlagen instanziieren (nur diese zwei existieren). Alte Instanzen
## werden sofort deaktiviert und freigegeben; außerhalb des Abstiegs gilt die feste Arena.
func _build_run_floors() -> void:
	for child in run_floors.get_children():
		if child is FloorGeometry:
			(child as FloorGeometry).set_enabled(false)
		run_floors.remove_child(child)
		child.queue_free()
	upper_template = null
	lower_template = null
	lower_floor = null
	if mode != Mode.DESCENT:
		fixed_floor.set_enabled(true)
		upper_floor = fixed_floor
		hatch = fixed_hatch
		_upper_base_position = upper_floor.position
		return
	fixed_floor.set_enabled(false)
	var pair := FloorTemplates.select_pair(run.floor_rng, forced_floor_ids)
	upper_template = pair[0]
	lower_template = pair[1]
	run.floor_template_ids.assign([upper_template.id, lower_template.id])
	upper_floor = _instantiate_floor(upper_template, 0.0, true)
	upper_floor.name = "Floor1_%s" % upper_template.id
	hatch = upper_floor.get_node("Hatch") as DescentHatch
	lower_floor = _instantiate_floor(lower_template, lower_floor_offset, false)
	lower_floor.name = "Floor2_%s" % lower_template.id
	_upper_base_position = upper_floor.position
	_lower_base_position = lower_floor.global_position


func _instantiate_floor(template: FloorTemplate, height: float, with_hatch: bool) -> FloorGeometry:
	var floor_node := FloorGeometry.new()
	floor_node.collision_mask = 0
	floor_node.rects = template.rects.duplicate()
	floor_node.holes = template.holes.duplicate()
	floor_node.under_glow = height < 0.0
	floor_node.position = Vector3(0.0, height, 0.0)
	var new_hatch: DescentHatch = null
	if with_hatch and template.has_hatch:
		floor_node.cutouts = [template.hatch_rect()]
		new_hatch = DescentHatch.new()
		new_hatch.name = "Hatch"
		new_hatch.size = FloorTemplate.HATCH_SIZE
		new_hatch.position = Vector3(template.hatch_slot.x, 0.0, template.hatch_slot.y)
	run_floors.add_child(floor_node)
	if new_hatch != null:
		floor_node.add_child(new_hatch)
	return floor_node


## n Slots aus der Liste: bei genau n in Reihenfolge, sonst per Floor-Zufall (nie der Upgrade-Zufall).
func _pick_slots(slots: Array[Vector2], n: int) -> Array[Vector2]:
	var pool: Array[Vector2] = slots.duplicate()
	if pool.size() > n and run != null:
		for i in range(pool.size() - 1, 0, -1):
			var j := run.floor_rng.randi_range(0, i)
			var tmp := pool[i]
			pool[i] = pool[j]
			pool[j] = tmp
	return pool.slice(0, mini(n, pool.size()))


static func _slot_transforms(floor_node: FloorGeometry, slots: Array[Vector2]) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for slot in slots:
		result.append(Transform3D(Basis.IDENTITY, floor_node.to_global(Vector3(slot.x, 0.02, slot.y))))
	return result


func _reset_lower_combatants() -> void:
	var bounds := lower_template.bounds()
	var center := lower_floor.to_global(Vector3(bounds.get_center().x, 0.0, bounds.get_center().y))
	var enemy_spawns := _slot_transforms(lower_floor, _pick_slots(lower_template.melee_slots, lower_enemies.size()))
	var shooter_spawns := _slot_transforms(lower_floor, _pick_slots(lower_template.ranged_slots, lower_shooters.size()))
	for i in lower_enemies.size():
		var e := lower_enemies[i]
		e.reset_to(enemy_spawns[i])
		_face(e, center)
		e.hit_stun = current_hit_stun()
		e.target = null  # warten, bis der Spieler landet
		e.visible = false  # erst im Übergang zeigen (zusammen mit Ebene 2)
		_set_floor_transparency(e, 0.0)
	for i in lower_shooters.size():
		var s := lower_shooters[i]
		s.tuning = current_sparker_tuning()
		s.reset_to(shooter_spawns[i])
		_face(s, center)
		s.target = null
		s.visible = false
		_set_floor_transparency(s, 0.0)


static func _set_floor_transparency(root: Node, value: float) -> void:
	for node in root.find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).transparency = value


static func _face(node: Node3D, point: Vector3) -> void:
	var to := point - node.global_position
	node.rotation.y = PlayerController.yaw_for_direction(Vector3(to.x, 0.0, to.z).normalized())


## Kompatibilität für M1-Aufrufe.
func reset_training() -> void:
	restart()


func add_effect(effect: Node3D, world_position: Vector3) -> void:
	effect.position = effects.to_local(world_position)
	effects.add_child(effect)


## Erzeugt einen Energiebolzen mit beim Abschuss kopierten Werten (unabhängig vom Schützen).
func spawn_projectile(origin: Vector3, direction: Vector3, tuning: SparkerTuning, shooter_name: String) -> SparkBolt:
	var bolt := BOLT_SCENE.instantiate() as SparkBolt
	bolt.setup(projectiles.to_local(origin), direction, tuning, shooter_name)
	bolt.player_contact.connect(_on_bolt_player_contact)
	projectiles.add_child(bolt)
	projectile_spawned.emit(bolt)
	return bolt


## Entfernt alle Projektile sofort (Sieg, Niederlage, Spielerfall, Neustart, Szenario-/Profilwechsel).
func clear_projectiles() -> void:
	for bolt in projectiles.get_children():
		projectiles.remove_child(bolt)
		bolt.queue_free()


func _physics_process(delta: float) -> void:
	if stats != null and encounter == Encounter.RUNNING:
		stats.duration += delta  # Physikzeit: Pausen zählen nicht
	if mode == Mode.DESCENT:
		_descent_physics()
		return
	if player != null and player.global_position.y < kill_height:
		if player.fall_out():
			player_fall_count += 1
			player_fell.emit(player_fall_count)
			_after_player_fall()
	if mode == Mode.TRAINING:
		for dummy in dummies:
			if dummy.visible and dummy.global_position.y < kill_height:
				dummy.fall_out()
	else:
		for c in combatants():
			if c.visible and c.global_position.y < kill_height:
				c.call("fall_out")


# --- Abstieg ------------------------------------------------------------------------

func _descent_physics() -> void:
	var lower_limit := lower_floor_height() - lower_kill_depth
	for c in upper_combatants():
		if c.visible and c.global_position.y < upper_enemy_kill_height:
			c.call("fall_out")
	for c in lower_combatants():
		if c.visible and c.global_position.y < lower_limit:
			c.call("fall_out")
	if player == null:
		return
	var y := player.global_position.y
	if encounter != Encounter.RUNNING:
		# Entschiedene Runde: nur verhindern, dass ein Körper endlos weiterfällt.
		if y < (lower_limit if floor_index() == 2 else kill_height):
			player.fall_out()
		return
	match descent:
		Descent.FLOOR_1, Descent.FLOOR_1_CLEARED:
			if y < descent_leave_height and player.is_targetable():
				_begin_drop()
		Descent.DROPPING:
			_apply_transition(_drop_progress(y))
			if player.is_on_floor() and y < lower_floor_height() + 1.0:
				_land()
			elif y < lower_limit:
				_player_lost_on_lower_floor()
		Descent.FLOOR_2:
			if y < lower_limit:
				_player_lost_on_lower_floor()


## Spieler hat Ebene 1 verlassen: Art des Abstiegs festhalten, Ebene 1 beenden, Landepunkt bestimmen.
func _begin_drop() -> void:
	descent_regular = descent == Descent.FLOOR_1_CLEARED and hatch.is_open and hatch.contains_world(player.global_position, 0.3)
	if descent == Descent.FLOOR_1:
		# Sturz vor dem Räumen: verbleibende Gegner der Ebene 1 werden übersprungen (keine XP, kein Upgrade).
		# Liegengebliebene Orbs werden eingefroren und verfallen bei der Landung – außer die Ebene wird im
		# selben Moment doch noch geräumt (dann Gutschrift).
		_stop_all_combatants()
		clear_projectiles()
		_finish_stats(EncounterStats.Outcome.SKIPPED)
		_suspend_orbs(1)
	else:
		# Geräumte Ebene: noch liegende XP werden gutgeschrieben; eine offene Upgrade-Auswahl bleibt bestehen.
		_credit_orbs(1)
	descent = Descent.DROPPING
	player.protect_from_combat(10.0)  # während des Falls; bei der Landung auf landing_protection verkürzt
	# Senkrechter Fall wie durch die Luke: Der Schwung klingt kurz ab, kein seitliches Lenken.
	player.settle_fall(fall_settle_time)
	var drop_point := player.global_position + player.settle_drift()
	drop_point.y = lower_floor_height()
	# Ebene 2 ist noch verborgen: Sie wird samt wartenden Gegnern so versetzt, dass ein validierter Landing-Slot
	# der Vorlage (Boden ringsum, Abstand zu Gegnern) genau unter dem Spieler liegt – bei Kante und Luke gleich.
	var safe := choose_landing_slot(drop_point)
	var shift := Vector3(drop_point.x - safe.x, 0.0, drop_point.z - safe.z)
	if shift.length_squared() > 0.0001:
		lower_floor.global_position += shift
		for c in lower_combatants():
			c.global_position += shift
	landing_point = drop_point
	# Ebene 1 ist ab jetzt nur noch Kulisse: keine Kollision, zurückgelassene Gegner ziehen mit ihr weg.
	upper_floor.collision_layer = 0
	for c in upper_combatants():
		if not bool(c.get("is_defeated")) and not bool(c.call("is_on_floor")) and c.global_position.y < -0.2:
			continue  # fällt bereits über die Kante: darf regulär besiegt werden (Clear im selben Moment)
		c.set_physics_process(false)
		_upper_combatant_base_y[c] = c.global_position.y
	descent_started.emit(descent_regular, landing_point)


## Fortschritt des Übergangs aus der Fallhöhe: 0 beim Verlassen, 1 kurz vor der Oberkante von Ebene 2.
func _drop_progress(y: float) -> float:
	var span := descent_leave_height - (lower_floor_height() + 1.0)
	return clampf((descent_leave_height - y) / span, 0.0, 1.0)


## Darstellung des Übergangs für einen Fortschritt 0..1 (stetig, bildratenunabhängig):
## Ebene 1 steigt und löst sich auf, Nebel und Tiefe wandern mit, Ebene 2 taucht überlappend auf.
func _apply_transition(progress: float) -> void:
	transition_progress = progress
	upper_fade = smoothstep(upper_fade_range.x, upper_fade_range.y, progress)
	lower_reveal = smoothstep(lower_reveal_range.x, lower_reveal_range.y, progress)
	var rise := upper_rise * smoothstep(0.0, upper_fade_range.y + 0.1, progress)
	upper_floor.position = _upper_base_position + Vector3.UP * rise
	upper_floor.visible = upper_fade < 1.0
	_set_floor_transparency(upper_floor, upper_fade)
	for c in upper_combatants():
		if _upper_combatant_base_y.has(c):
			c.global_position.y = float(_upper_combatant_base_y[c]) + rise
		_set_floor_transparency(c, upper_fade)
	var lower_visible := mode == Mode.DESCENT and lower_reveal > 0.0
	if lower_floor != null:
		lower_floor.visible = lower_visible
		_set_floor_transparency(lower_floor, 1.0 - lower_reveal)
	for c in lower_combatants():
		c.visible = lower_visible
		_set_floor_transparency(c, 1.0 - lower_reveal)
	var depth := smoothstep(0.15, 0.9, progress) * (lower_floor_height() if mode == Mode.DESCENT else 0.0)
	environment.fog_height = _base_fog_height + depth
	depth_backdrop.follow_floor(depth)


## Landing-Slot der Vorlage von Ebene 2 (Weltposition bei aktueller Lage): sicher, mit Abstand zu den wartenden
## Gegnern und in der Lage, die der Absprungstelle auf Ebene 1 am besten entspricht (Sturz im Osten → Landung
## im Osten der neuen Ebene). Ohne gültigen Slot: Suche um near (Rückfall, bei validen Vorlagen nie nötig).
func choose_landing_slot(near: Vector3) -> Vector3:
	var upper_center := upper_template.bounds().get_center()
	var drop_local := upper_floor.to_local(near)
	var drop_offset := Vector2(drop_local.x, drop_local.z) - upper_center
	var lower_center := lower_template.bounds().get_center()
	var best := Vector3.ZERO
	var best_score := INF
	for slot in lower_template.landing_slots:
		if not lower_floor.is_safe_point(slot, landing_edge_margin):
			continue
		var world := lower_floor.to_global(Vector3(slot.x, 0.0, slot.y))
		if _lower_enemy_clearance(world) < landing_enemy_clearance:
			continue
		var score := (slot - lower_center).distance_to(drop_offset)
		if score < best_score:
			best = world
			best_score = score
	return best if best_score < INF else find_landing_point(near)


func _lower_enemy_clearance(point: Vector3) -> float:
	var nearest := INF
	for c in lower_combatants():
		if bool(c.get("is_defeated")):
			continue
		var offset := c.global_position - point
		nearest = minf(nearest, Vector2(offset.x, offset.z).length())
	return nearest


## Validierter sicherer Landepunkt nahe near: Boden ringsum (Abstand zu Kanten und Schacht) und
## Abstand zu lebenden Gegnern der Ebene 2. Suche in Ringen um den Wunschpunkt, deterministisch.
func find_landing_point(near: Vector3) -> Vector3:
	var local := lower_floor.to_local(near)
	var origin := Vector2(local.x, local.z)
	for ring in 30:
		var radius := ring * 0.5
		var count := 1 if ring == 0 else 16
		for i in count:
			var angle := TAU * i / count
			var candidate := origin + Vector2(cos(angle), sin(angle)) * radius
			if not lower_floor.is_safe_point(candidate, landing_edge_margin):
				continue
			var world := lower_floor.to_global(Vector3(candidate.x, 0.0, candidate.y))
			if _clear_of_lower_enemies(world):
				return world
	var fallback := lower_template.landing_slots[0]
	return lower_floor.to_global(Vector3(fallback.x, 0.0, fallback.y))


func _clear_of_lower_enemies(point: Vector3) -> bool:
	for c in lower_combatants():
		if bool(c.get("is_defeated")):
			continue
		var offset := c.global_position - point
		if Vector2(offset.x, offset.z).length() < landing_enemy_clearance:
			return false
	return true


## Landung auf Ebene 2: Gegner der Ebene 2 übernehmen, Sturzschaden, Landeschutz.
func _land() -> void:
	descent = Descent.FLOOR_2
	_active_floor = 2
	_discard_orbs(1)  # Orbs einer nicht geräumten, verlassenen Ebene verfallen
	active_enemies.assign(lower_enemies)
	active_shooters.assign(lower_shooters)
	_begin_stats()
	var damage := 0.0
	if not descent_regular:
		damage = maxf(ceilf(player.tuning.max_hp * fall_damage_fraction), 1.0)
	last_fall_damage = damage
	stats.fall_damage = damage
	player.protect_from_combat(landing_protection)
	player.apply_fall_damage(damage)  # kann tödlich sein → _on_player_died
	if encounter == Encounter.RUNNING:
		# Ausstehendes Floor-Upgrade (Clear im Moment des Sturzes) zuerst wählen; Gegner erst danach aktiv.
		if not (reward_pending and _offer_reward(_generation)):
			_activate_current_combatants()
	_apply_transition(1.0)
	# Zurückgelassene Gegner der Ebene 1 endgültig deaktivieren (Neustart setzt sie zurück).
	for c in upper_combatants():
		c.call("set_active", false)
		c.set_physics_process(true)
		_set_floor_transparency(c, 0.0)
	floor_landed.emit(damage)


func _player_lost_on_lower_floor() -> void:
	player.fall_out()
	player_fall_count += 1
	player_fell.emit(player_fall_count)
	encounter = Encounter.DEFEAT
	_stop_all_combatants()
	clear_projectiles()
	_finish_stats(EncounterStats.Outcome.PLAYER_FALL)
	encounter_finished.emit(false)


func _stop_all_combatants() -> void:
	for c in combatants():
		c.call("stop_combat")


func _after_player_fall() -> void:
	if is_combat_mode() and encounter == Encounter.RUNNING:
		# Alle Gegner beenden ihren Kampf; Zusammenfassung vor dem Reset sichern.
		_stop_all_combatants()
		clear_projectiles()
		_finish_stats(EncounterStats.Outcome.PLAYER_FALL)
	# Verbindung statt await: wird beim Freigeben der Arena automatisch getrennt.
	get_tree().create_timer(player_respawn_delay, false, true).timeout.connect(
			_on_player_fall_timeout.bind(_generation))


func _on_player_fall_timeout(generation: int) -> void:
	if generation != _generation or player == null or player.state != PlayerController.State.OUT:
		return
	if is_combat_mode() and encounter == Encounter.RUNNING:
		# Im Kampf setzt ein Spielerfall die ganze Begegnung zurück (kein Weiterkämpfen am Spawn).
		restart()
	elif not (is_combat_mode() and encounter == Encounter.DEFEAT):
		player.respawn_at(current_player_spawn().global_transform)


func _on_player_died() -> void:
	if not is_combat_mode() or encounter != Encounter.RUNNING:
		return
	encounter = Encounter.DEFEAT
	_stop_all_combatants()
	clear_projectiles()
	_finish_stats(EncounterStats.Outcome.DEFEAT)
	encounter_finished.emit(false)


func _on_player_damaged(_hit: HitInfo) -> void:
	if stats != null:
		stats.hits_taken += 1


## Tatsächlicher HP-Verlust (der letzte Treffer kann mehr Schaden haben als Rest-HP).
func _on_player_health_changed(current: float, _maximum: float) -> void:
	if stats != null and current < _tracked_player_hp:
		stats.damage_taken += _tracked_player_hp - current
	_tracked_player_hp = current


func _on_combatant_defeated(c: Node3D, by_fall: bool) -> void:
	if not is_combat_mode() or encounter != Encounter.RUNNING or not combatants().has(c):
		return
	if stats != null:
		if by_fall:
			stats.enemies_fall_defeated += 1
		else:
			stats.enemies_hp_defeated += 1
	if run != null:
		_drop_xp(c, by_fall)
	if enemies_remaining() == 0 and mode == Mode.DESCENT and _active_floor == 1:
		_on_upper_floor_cleared()
	elif enemies_remaining() == 0:
		encounter = Encounter.VICTORY
		clear_projectiles()
		_vacuum_orbs(_active_floor)
		_finish_stats(EncounterStats.Outcome.VICTORY)
		encounter_finished.emit(true)


# --- Run-Progression: XP-Orbs und Floor-Clear-Belohnung (M3A) --------------------------------

func is_final_floor() -> bool:
	return mode != Mode.DESCENT or _active_floor == 2


func xp_for(c: Node3D) -> int:
	return sparker_xp if c is Sparker else scrapling_xp


## Ebene, auf der sich der Spieler befindet (während des Falls gilt Ebene 1 als verlassen).
func _player_floor() -> int:
	return 1 if descent == Descent.FLOOR_1 or descent == Descent.FLOOR_1_CLEARED else 2


## XP eines besiegten Gegners als Orbs abwerfen: HP-Sieg am Gegner, Kantensieg an seiner letzten
## Bodenposition (sicher auf die Ebene gezogen). Hat der Spieler diese Ebene schon verlassen, gibt es
## keine Orbs; die XP zählen nur, falls die Ebene dadurch geräumt wird.
func _drop_xp(c: Node3D, by_fall: bool) -> void:
	var amount := xp_for(c)
	var enemy_floor := 2 if lower_combatants().has(c) else 1
	if enemy_floor != _player_floor():
		_left_floor_xp += amount
		return
	var floor_node: FloorGeometry = lower_floor if enemy_floor == 2 else upper_floor
	var origin: Vector3 = c.get("last_ground_position") if by_fall else c.global_position
	var center := _safe_floor_point(floor_node, origin, 0.6)
	var start := c.global_position + Vector3.UP * 0.6
	var count := maxi(ceili(float(amount) / float(xp_per_orb)), 1)
	var remaining := amount
	for i in count:
		var value := mini(xp_per_orb, remaining)
		remaining -= value
		var angle := TAU * i / count + 0.7
		var rest := center + Vector3(cos(angle), 0.0, sin(angle)) * (0.5 + 0.25 * (i % 2))
		var local := floor_node.to_local(rest)
		if not floor_node.is_safe_point(Vector2(local.x, local.z), 0.25):
			rest = center
		var orb := XpOrb.new()
		orb.setup(start, rest, value, player, enemy_floor)
		orb.collected.connect(_on_orb_collected)
		pickups.add_child(orb)


## Nächster Punkt mit Boden ringsum (Abstand margin), auf Höhe der Ebenenoberkante.
func _safe_floor_point(floor_node: FloorGeometry, near: Vector3, margin: float) -> Vector3:
	var local := floor_node.to_local(near)
	var origin := Vector2(local.x, local.z)
	for ring in 24:
		var count := 1 if ring == 0 else 12
		for i in count:
			var angle := TAU * i / count
			var candidate := origin + Vector2(cos(angle), sin(angle)) * ring * 0.4
			if floor_node.is_safe_point(candidate, margin):
				return floor_node.to_global(Vector3(candidate.x, 0.0, candidate.y))
	return floor_node.to_global(Vector3(origin.x, 0.0, origin.y))


func orbs(floor_number: int = 0) -> Array[XpOrb]:
	var result: Array[XpOrb] = []
	for node in pickups.get_children():
		var orb := node as XpOrb
		if orb != null and not orb.is_queued_for_deletion() and (floor_number == 0 or orb.floor_index == floor_number):
			result.append(orb)
	return result


func _on_orb_collected(orb: XpOrb) -> void:
	_grant_xp(orb.value)


func _grant_xp(amount: int) -> void:
	if run == null or amount <= 0:
		return
	run.add_xp(amount)
	xp_collected.emit(amount)


func _vacuum_orbs(floor_number: int) -> void:
	for orb in orbs(floor_number):
		orb.vacuum()


## Liegende Orbs sofort gutschreiben (Ebene geräumt und verlassen, Rundenende).
func _credit_orbs(floor_number: int) -> void:
	for orb in orbs(floor_number):
		pickups.remove_child(orb)
		orb.queue_free()
		_grant_xp(orb.value)


func credit_remaining_orbs() -> void:
	_credit_orbs(0)


func _suspend_orbs(floor_number: int) -> void:
	for orb in orbs(floor_number):
		orb.visible = false
		orb.process_mode = Node.PROCESS_MODE_DISABLED


func _discard_orbs(floor_number: int) -> void:
	for orb in orbs(floor_number):
		pickups.remove_child(orb)
		orb.queue_free()


func _clear_orbs() -> void:
	for node in pickups.get_children():
		pickups.remove_child(node)
		node.queue_free()


## Ebene 1 geräumt: Anspruch auf ein Floor-Upgrade. Die Luke öffnet erst nach der Auswahl.
func _on_upper_floor_cleared() -> void:
	reward_pending = true
	clear_projectiles()
	if descent == Descent.FLOOR_1:
		descent = Descent.FLOOR_1_CLEARED
		_finish_stats(EncounterStats.Outcome.CLEARED)
		_vacuum_orbs(1)
		get_tree().create_timer(reward_delay, false, true).timeout.connect(_offer_reward.bind(_generation, reward_delay))
	else:
		# Der Spieler fällt bereits (Clear im selben Moment): Belohnung bleibt, Auswahl nach der Landung.
		_credit_orbs(1)
		_grant_xp(_left_floor_xp)
		_left_floor_xp = 0
	floor_cleared.emit(1)


## Auswahl anbieten, sobald der Spieler sicher steht (nicht im Fall) und die Orbs eingesammelt sind
## (spätestens nach reward_max_delay, Rest wird gutgeschrieben). true = Auswahl angezeigt.
func _offer_reward(generation: int, waited: float = INF) -> bool:
	if generation != _generation or run == null or not reward_pending or reward_offered:
		return false
	if encounter != Encounter.RUNNING or descent == Descent.DROPPING:
		return false
	if descent == Descent.FLOOR_1_CLEARED and not orbs(1).is_empty():
		if waited < reward_max_delay:
			get_tree().create_timer(0.1, false, true).timeout.connect(_offer_reward.bind(generation, waited + 0.1))
			return false
		_credit_orbs(1)
	reward_choices = run.roll_upgrade_choices(3)
	if reward_choices.is_empty():
		_finish_reward()  # Pool erschöpft: nichts zu wählen
		return false
	reward_offered = true
	floor_reward_offered.emit(reward_choices)
	return true


## Pflichtauswahl anwenden: genau ein Upgrade, danach Luke öffnen bzw. Kampf auf Ebene 2 starten.
func choose_floor_reward(id: StringName) -> bool:
	if run == null or not reward_offered or not reward_choices.has(id):
		return false
	run.add_upgrade(id)
	_finish_reward()
	return true


func _finish_reward() -> void:
	reward_pending = false
	reward_offered = false
	reward_choices.clear()
	if descent == Descent.FLOOR_1_CLEARED:
		hatch.open()
	elif descent == Descent.FLOOR_2 and encounter == Encounter.RUNNING:
		player.protect_from_combat(landing_protection)  # Landeschutz beginnt mit dem Kampfstart
		_activate_current_combatants()


func _activate_current_combatants() -> void:
	for c in combatants():
		if not bool(c.get("is_defeated")):
			c.set("target", player)


func _on_enemy_swing_started() -> void:
	if stats != null:
		stats.enemy_attacks_started += 1


func _on_enemy_active_started() -> void:
	if stats != null:
		stats.enemy_attacks_active += 1


func _on_enemy_attack_interrupted(_e: Scrapling) -> void:
	if stats != null:
		stats.enemy_attacks_interrupted += 1


func _on_sparker_interrupted(_s: Sparker) -> void:
	if stats != null:
		stats.charges_interrupted += 1


func _on_sparker_fired(s: Sparker, origin: Vector3, direction: Vector3) -> void:
	if encounter != Encounter.RUNNING:
		return
	if stats != null:
		stats.shots_fired += 1
	spawn_projectile(origin, direction, s.tuning, String(s.name))


func _on_bolt_player_contact(_bolt: SparkBolt, applied: bool) -> void:
	if stats != null and applied:
		stats.projectile_hits += 1


func _finish_stats(outcome: EncounterStats.Outcome) -> void:
	if stats == null:
		return
	stats.outcome = outcome
	last_stats = stats
	stats = null
	round_summarized.emit(last_stats)


func _on_dummy_defeated(dummy: TrainingDummy, reason: TrainingDummy.DefeatReason) -> void:
	if reason == TrainingDummy.DefeatReason.FALL:
		dummy_fall_defeats += 1
	else:
		dummy_hp_defeats += 1
	dummy_defeated.emit(dummy, reason)
	get_tree().create_timer(dummy_respawn_delay, false, true).timeout.connect(
			_respawn_dummy.bind(dummy.get_instance_id(), _generation))


func _respawn_dummy(dummy_id: int, generation: int) -> void:
	var dummy := instance_from_id(dummy_id) as TrainingDummy
	if generation == _generation and dummy != null and dummy.is_defeated and mode == Mode.TRAINING:
		dummy.respawn()
