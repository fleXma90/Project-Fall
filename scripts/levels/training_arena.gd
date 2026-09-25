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
## Ausgangshöhen der zurückgelassenen Gegner der Ebene 1 (sie ziehen mit der Ebene nach oben weg).
var _upper_combatant_base_y: Dictionary = {}

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
@onready var upper_floor: FloorGeometry = $Platform
@onready var hatch: DescentHatch = $Platform/Hatch
@onready var lower_floor: FloorGeometry = $LowerFloor
@onready var lower_scrapling_spawns: Array[Marker3D] = [$LowerScraplingSpawnA, $LowerScraplingSpawnB]
@onready var lower_sparker_spawn: Marker3D = $LowerSparkerSpawn
@onready var lower_fallback_landing: Marker3D = $LowerFallbackLanding
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
	# Ebene 2 hat einen Schacht in der Mitte: lokaler Umweg statt Stehenbleiben an der Lücke.
	for e in lower_enemies:
		e.gap_detour = true
	for s in lower_shooters:
		s.gap_detour = true
	# Eigene Kopie: Die Nebelhöhe folgt der aktiven Ebene, die Szenenressource bleibt unverändert.
	environment = environment.duplicate() as Environment
	($WorldEnvironment as WorldEnvironment).environment = environment
	_base_fog_height = environment.fog_height
	_upper_base_position = upper_floor.position
	_lower_base_position = lower_floor.global_position
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
	sparker.set_active(active_shooters.has(sparker))
	sparker.neighbors = _others(sparker, all)
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
	return lower_floor.global_position.y


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
			Mode.MIXED, Mode.DESCENT:
				spawns.append_array(mixed_scrapling_spawns)
		var look_at_point := current_player_spawn().global_position
		for i in active_enemies.size():
			var e := active_enemies[i]
			e.reset_to(spawns[i].global_transform)
			if mode != Mode.COMBAT:
				_face(e, look_at_point)
			e.hit_stun = current_hit_stun()
			e.target = player
		for s in active_shooters:
			s.tuning = current_sparker_tuning()  # vor reset_to: Werte gelten ab der neuen Runde
			s.reset_to(mixed_sparker_spawn.global_transform)
			_face(s, look_at_point)
			s.target = player
		if mode == Mode.DESCENT:
			_reset_lower_combatants()
		encounter = Encounter.RUNNING
	if player != null:
		player.fall_count = 0
		player.reset_full(current_player_spawn().global_transform)
		_tracked_player_hp = player.hp
	if is_combat_mode():
		# Erst nach dem Spieler-Reset anlegen: die Rücksetzung der HP ist kein Schaden.
		_begin_stats()
	InputRouter.release_all()
	restarted.emit()


func _begin_stats() -> void:
	stats = EncounterStats.new()
	stats.scenario = scenario_name(mode)
	if mode == Mode.DESCENT:
		stats.scenario += " · Ebene %d" % floor_index()
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
	hatch.close()
	upper_floor.set_enabled(true)
	# Ebene 2 existiert im Abstieg physisch an ihrer Grundposition, bleibt aber bis zum Übergang verborgen.
	lower_floor.global_position = _lower_base_position
	lower_floor.set_enabled(mode == Mode.DESCENT)
	for c in upper_combatants():
		c.set_physics_process(true)
	_upper_combatant_base_y.clear()
	_apply_transition(0.0)
	if mode == Mode.DESCENT:
		# Nach einem Abstieg sind die aktiven Gegner die der Ebene 2: auf Ebene 1 zurückschalten.
		active_enemies.assign([enemies[0], enemies[1]])
		active_shooters.assign([sparker])


func _reset_lower_combatants() -> void:
	var center := lower_floor.global_position
	for i in lower_enemies.size():
		var e := lower_enemies[i]
		e.reset_to(lower_scrapling_spawns[i].global_transform)
		_face(e, center)
		e.hit_stun = current_hit_stun()
		e.target = null  # warten, bis der Spieler landet
		e.visible = false  # erst im Übergang zeigen (zusammen mit Ebene 2)
		_set_floor_transparency(e, 0.0)
	for s in lower_shooters:
		s.tuning = current_sparker_tuning()
		s.reset_to(lower_sparker_spawn.global_transform)
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
		# Sturz vor dem Räumen: verbleibende Gegner der Ebene 1 werden übersprungen.
		_stop_all_combatants()
		clear_projectiles()
		_finish_stats(EncounterStats.Outcome.SKIPPED)
	descent = Descent.DROPPING
	player.protect_from_combat(10.0)  # während des Falls; bei der Landung auf landing_protection verkürzt
	# Senkrechter Fall wie durch die Luke: Der Schwung klingt kurz ab, kein seitliches Lenken.
	player.settle_fall(fall_settle_time)
	var drop_point := player.global_position + player.settle_drift()
	drop_point.y = lower_floor_height()
	# Ebene 2 ist noch verborgen: Sie wird samt wartenden Gegnern so versetzt, dass ein geprüfter sicherer
	# Punkt (Boden ringsum, Abstand zu Gegnern) genau unter dem Spieler liegt. Luke: in der Regel kein Versatz.
	var safe := find_landing_point(drop_point)
	var shift := Vector3(drop_point.x - safe.x, 0.0, drop_point.z - safe.z)
	if shift.length_squared() > 0.0001:
		lower_floor.global_position += shift
		for c in lower_combatants():
			c.global_position += shift
	landing_point = drop_point
	# Ebene 1 ist ab jetzt nur noch Kulisse: keine Kollision, zurückgelassene Gegner ziehen mit ihr weg.
	upper_floor.collision_layer = 0
	for c in upper_combatants():
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
	lower_floor.visible = lower_visible
	_set_floor_transparency(lower_floor, 1.0 - lower_reveal)
	for c in lower_combatants():
		c.visible = lower_visible
		_set_floor_transparency(c, 1.0 - lower_reveal)
	var depth := smoothstep(0.15, 0.9, progress) * (lower_floor_height() if mode == Mode.DESCENT else 0.0)
	environment.fog_height = _base_fog_height + depth
	depth_backdrop.follow_floor(depth)


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
	return lower_fallback_landing.global_position


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
		for c in combatants():
			c.set("target", player)
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
	if enemies_remaining() == 0 and descent == Descent.FLOOR_1:
		# Abstieg: Ebene 1 geräumt → Luke öffnet sich, die Begegnung läuft weiter.
		descent = Descent.FLOOR_1_CLEARED
		clear_projectiles()
		_finish_stats(EncounterStats.Outcome.CLEARED)
		hatch.open()
		floor_cleared.emit(1)
	elif enemies_remaining() == 0:
		encounter = Encounter.VICTORY
		clear_projectiles()
		_finish_stats(EncounterStats.Outcome.VICTORY)
		encounter_finished.emit(true)


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
