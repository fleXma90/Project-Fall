class_name TrainingArena
extends Node3D
## Offene Plattform mit vier Szenarien auf derselben Geometrie:
## - MIXED (M2C, Standard): zwei Scraplings und ein Funkenwerfer.
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

enum Mode { TRAINING, COMBAT, GROUP, MIXED }  # COMBAT = Duell (M2A)
enum StunProfile { BASE, SHORT }
enum Encounter { NONE, RUNNING, VICTORY, DEFEAT }

const BOLT_SCENE: PackedScene = preload("res://scenes/combat/spark_bolt.tscn")

@export var kill_height: float = -5.0
@export var player_respawn_delay: float = 0.55
@export var dummy_respawn_delay: float = 2.5
## Profil B (seit M2C Arbeitsstand): kürzere Scrapling-Benommenheit. Profil A nutzt den Wert der Tuning-Ressource.
@export var short_hit_stun: float = 0.20

var mode: Mode = Mode.TRAINING
var stun_profile: StunProfile = StunProfile.BASE
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
## Laufende Rundenauswertung (nur Kampfszenarien) und die zuletzt abgeschlossene.
var stats: EncounterStats = null
var last_stats: EncounterStats = null

var _generation: int = 0
var _tracked_player_hp: float = 0.0

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


func _ready() -> void:
	for node in find_children("*", "TrainingDummy", true, false):
		var dummy := node as TrainingDummy
		dummies.append(dummy)
		dummy.defeated.connect(_on_dummy_defeated)
	enemies = [$Scrapling, $Scrapling2, $Scrapling3]
	# Verbindungen einmalig; Neustarts verbinden nichts erneut.
	for e in enemies:
		e.defeated.connect(func(defeated_enemy: Scrapling, reason: Scrapling.DefeatReason) -> void:
			_on_combatant_defeated(defeated_enemy, reason == Scrapling.DefeatReason.FALL))
		e.attack_interrupted.connect(_on_enemy_attack_interrupted)
		e.weapon.swing_started.connect(_on_enemy_swing_started.unbind(2))
		e.weapon.active_started.connect(_on_enemy_active_started.unbind(1))
		e.set_active(false)
	sparker.defeated.connect(func(defeated_sparker: Sparker, reason: Sparker.DefeatReason) -> void:
		_on_combatant_defeated(defeated_sparker, reason == Sparker.DefeatReason.FALL))
	sparker.attack_interrupted.connect(_on_sparker_interrupted)
	sparker.fired.connect(_on_sparker_fired)
	sparker.set_active(false)


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
		Mode.MIXED:
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
		Mode.MIXED:
			active_enemies.append(enemies[0])
			active_enemies.append(enemies[1])
			active_shooters.append(sparker)
	var all := combatants()
	for e in enemies:
		e.set_active(active_enemies.has(e))
		e.neighbors = _others(e, all)
	sparker.set_active(active_shooters.has(sparker))
	sparker.neighbors = _others(sparker, all)


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
		var look_at_point := current_player_spawn().global_position
		for i in active_enemies.size():
			var e := active_enemies[i]
			e.reset_to(spawns[i].global_transform)
			if mode != Mode.COMBAT:
				_face(e, look_at_point)
			e.hit_stun = current_hit_stun()
			e.target = player
		for s in active_shooters:
			s.reset_to(mixed_sparker_spawn.global_transform)
			_face(s, look_at_point)
			s.target = player
		encounter = Encounter.RUNNING
	if player != null:
		player.fall_count = 0
		player.reset_full(current_player_spawn().global_transform)
		_tracked_player_hp = player.hp
	if is_combat_mode():
		# Erst nach dem Spieler-Reset anlegen: die Rücksetzung der HP ist kein Schaden.
		stats = EncounterStats.new()
		stats.scenario = scenario_name(mode)
		stats.profile = profile_name()
		stats.enemies_total = combatants().size()
	InputRouter.release_all()
	restarted.emit()


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
	if enemies_remaining() == 0:
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
