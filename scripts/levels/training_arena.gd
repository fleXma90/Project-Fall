class_name TrainingArena
extends Node3D
## M1-Trainingsarena: eine offene Plattform, drei Dummies, Killhöhe, Respawn und Trainingsreset.
## Die Killhöhe ist keine Randbarriere: Sie liegt weit unter der Plattform.

signal player_fell(count: int)
signal dummy_defeated(dummy: TrainingDummy, reason: TrainingDummy.DefeatReason)

@export var kill_height: float = -5.0
@export var player_respawn_delay: float = 0.55
@export var dummy_respawn_delay: float = 2.5

var player: PlayerController = null
var player_fall_count: int = 0
var dummy_hp_defeats: int = 0
var dummy_fall_defeats: int = 0
var dummies: Array[TrainingDummy] = []

var _generation: int = 0

@onready var player_spawn: Marker3D = $PlayerSpawn


func _ready() -> void:
	for node in find_children("*", "TrainingDummy", true, false):
		var dummy := node as TrainingDummy
		dummies.append(dummy)
		dummy.defeated.connect(_on_dummy_defeated)


func setup(p: PlayerController) -> void:
	player = p
	player.reset_full(player_spawn.global_transform)


func _physics_process(_delta: float) -> void:
	if player != null and player.global_position.y < kill_height:
		if player.fall_out():
			player_fall_count += 1
			player_fell.emit(player_fall_count)
			_respawn_player_later()
	for dummy in dummies:
		if dummy.visible and dummy.global_position.y < kill_height:
			dummy.fall_out()


## Vollständiger Trainingsreset: Player, Dummies, Zähler, gehaltene Inputs.
func reset_training() -> void:
	_generation += 1
	player_fall_count = 0
	dummy_hp_defeats = 0
	dummy_fall_defeats = 0
	for dummy in dummies:
		dummy.respawn()
		dummy.reset_stats()
	if player != null:
		player.fall_count = 0
		player.reset_full(player_spawn.global_transform)
	InputRouter.release_all()


func _respawn_player_later() -> void:
	# Verbindung statt await: wird beim Freigeben der Arena automatisch getrennt.
	get_tree().create_timer(player_respawn_delay, false, true).timeout.connect(
			_respawn_player.bind(_generation))


func _respawn_player(generation: int) -> void:
	if generation == _generation and player != null and player.state == PlayerController.State.OUT:
		player.respawn_at(player_spawn.global_transform)


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
	if generation == _generation and dummy != null and dummy.is_defeated:
		dummy.respawn()
