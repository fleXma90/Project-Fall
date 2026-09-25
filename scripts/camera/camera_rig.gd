class_name CameraRig
extends Node3D
## Feste schräge Kamera (2.5D/isometrische Präsentation). Folgt dem Ziel weich, ist nicht vom Spieler drehbar.

@export var target: Node3D
@export_range(20.0, 80.0) var pitch_degrees: float = 48.0
@export var yaw_degrees: float = 45.0
@export var distance: float = 23.0
@export var orthographic: bool = false
@export var fov_degrees: float = 30.0
@export var ortho_size: float = 16.0
## Follow-Smoothing in 1/s.
@export var follow_sharpness: float = 10.0
## Beim Fallen folgt die Kamera nur bis zu dieser Höhe nach unten, damit der Fall lesbar bleibt.
@export var min_follow_height: float = -1.5
@export var look_height: float = 0.5
@export var max_shake: float = 0.08

var _shake_left: float = 0.0
var _shake_duration: float = 0.1
var _shake_strength: float = 0.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	apply_view()
	snap_to_target()


func apply_view() -> void:
	rotation = Vector3(deg_to_rad(-pitch_degrees), deg_to_rad(yaw_degrees), 0.0)
	camera.position = Vector3(0.0, 0.0, distance)
	camera.rotation = Vector3.ZERO
	camera.near = 0.5
	camera.far = 200.0
	if orthographic:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = ortho_size
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = fov_degrees


func snap_to_target() -> void:
	if target != null:
		global_position = _goal()


## Sehr dezenter Shake; Stärke 0..1 wird auf max_shake begrenzt.
func add_shake(strength: float, duration: float = 0.1) -> void:
	_shake_strength = clampf(maxf(_shake_strength, strength), 0.0, 1.0)
	_shake_duration = duration
	_shake_left = duration


func _process(delta: float) -> void:
	if target != null:
		global_position = global_position.lerp(_goal(), 1.0 - exp(-follow_sharpness * delta))
	var offset := Vector3.ZERO
	if _shake_left > 0.0:
		_shake_left = maxf(_shake_left - delta, 0.0)
		var amount := max_shake * _shake_strength * (_shake_left / _shake_duration)
		offset = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * amount
		if _shake_left == 0.0:
			_shake_strength = 0.0
	camera.position = Vector3(0.0, 0.0, distance) + offset


func _goal() -> Vector3:
	var goal := target.global_position
	goal.y = maxf(goal.y, min_follow_height) + look_height
	return goal
