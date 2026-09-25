class_name TrainingArena
extends Node3D
## Offene Plattform mit zwei Modi auf derselben Geometrie:
## - COMBAT (M2A, Standard): Spieler gegen genau einen Scrapling; Sieg/Niederlage, Neustart.
## - TRAINING (M1): drei passive Dummies mit Auto-Respawn, Spieler-Respawn nach Fall.
## Die Killhöhe ist keine Randbarriere: Sie liegt weit unter der Plattform.

signal player_fell(count: int)
signal dummy_defeated(dummy: TrainingDummy, reason: TrainingDummy.DefeatReason)
## Begegnung entschieden (genau einmal pro Runde): true = Gegner besiegt, false = Spieler besiegt.
signal encounter_finished(victory: bool)
## Arena wurde neu gestartet (Moduswechsel, Neustart, Spielerfall im Kampf).
signal restarted

enum Mode { TRAINING, COMBAT }
enum Encounter { NONE, RUNNING, VICTORY, DEFEAT }

@export var kill_height: float = -5.0
@export var player_respawn_delay: float = 0.55
@export var dummy_respawn_delay: float = 2.5

var mode: Mode = Mode.TRAINING
var encounter: Encounter = Encounter.NONE
var player: PlayerController = null
var player_fall_count: int = 0
var dummy_hp_defeats: int = 0
var dummy_fall_defeats: int = 0
var dummies: Array[TrainingDummy] = []

var _generation: int = 0

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var combat_player_spawn: Marker3D = $CombatPlayerSpawn
@onready var enemy_spawn: Marker3D = $EnemySpawn
@onready var enemy: Scrapling = $Scrapling
@onready var effects: Node3D = $Effects


func _ready() -> void:
	for node in find_children("*", "TrainingDummy", true, false):
		var dummy := node as TrainingDummy
		dummies.append(dummy)
		dummy.defeated.connect(_on_dummy_defeated)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.set_active(false)


func setup(p: PlayerController) -> void:
	player = p
	player.died.connect(_on_player_died)
	set_mode(mode)


## Moduswechsel setzt die jeweilige Begegnung vollständig zurück.
func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	for dummy in dummies:
		dummy.set_active(mode == Mode.TRAINING)
	enemy.set_active(mode == Mode.COMBAT)
	restart()


func current_player_spawn() -> Marker3D:
	return combat_player_spawn if mode == Mode.COMBAT else player_spawn


## Vollständiger Neustart des aktuellen Modus: Beteiligte an sichere Startpositionen, HP, Zustände,
## Timer, Trefferlisten, Effekte und gehaltene Eingaben zurücksetzen.
func restart() -> void:
	_generation += 1  # verwirft ausstehende Respawn-Timer der alten Runde
	player_fall_count = 0
	dummy_hp_defeats = 0
	dummy_fall_defeats = 0
	for effect in effects.get_children():
		effect.queue_free()
	if mode == Mode.TRAINING:
		encounter = Encounter.NONE
		for dummy in dummies:
			dummy.respawn()
			dummy.reset_stats()
	else:
		enemy.reset_to(enemy_spawn.global_transform)
		enemy.target = player
		encounter = Encounter.RUNNING
	if player != null:
		player.fall_count = 0
		player.reset_full(current_player_spawn().global_transform)
	InputRouter.release_all()
	restarted.emit()


## Kompatibilität für M1-Aufrufe.
func reset_training() -> void:
	restart()


func add_effect(effect: Node3D, world_position: Vector3) -> void:
	effect.position = effects.to_local(world_position)
	effects.add_child(effect)


func _physics_process(_delta: float) -> void:
	if player != null and player.global_position.y < kill_height:
		if player.fall_out():
			player_fall_count += 1
			player_fell.emit(player_fall_count)
			_after_player_fall()
	if mode == Mode.TRAINING:
		for dummy in dummies:
			if dummy.visible and dummy.global_position.y < kill_height:
				dummy.fall_out()
	elif enemy.visible and enemy.global_position.y < kill_height:
		enemy.fall_out()


func _after_player_fall() -> void:
	# Verbindung statt await: wird beim Freigeben der Arena automatisch getrennt.
	get_tree().create_timer(player_respawn_delay, false, true).timeout.connect(
			_on_player_fall_timeout.bind(_generation))


func _on_player_fall_timeout(generation: int) -> void:
	if generation != _generation or player == null or player.state != PlayerController.State.OUT:
		return
	if mode == Mode.COMBAT and encounter == Encounter.RUNNING:
		# Im Kampf setzt ein Spielerfall die ganze Begegnung zurück (kein Weiterkämpfen am Spawn).
		restart()
	elif not (mode == Mode.COMBAT and encounter == Encounter.DEFEAT):
		player.respawn_at(current_player_spawn().global_transform)


func _on_player_died() -> void:
	if mode != Mode.COMBAT or encounter != Encounter.RUNNING:
		return
	encounter = Encounter.DEFEAT
	enemy.stop_combat()
	encounter_finished.emit(false)


func _on_enemy_defeated(_enemy: Scrapling, _reason: Scrapling.DefeatReason) -> void:
	if mode != Mode.COMBAT or encounter != Encounter.RUNNING:
		return
	encounter = Encounter.VICTORY
	encounter_finished.emit(true)


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
