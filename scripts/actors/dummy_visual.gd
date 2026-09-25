class_name DummyVisual
extends Node3D
## Placeholder-Darstellung des Trainingsdummys: Hitflash, Wackeln, HP-Anzeige, Umfallen.
## Der Flash nutzt ein eigenes Overlay-Material und hängt nicht an konkreten Mesh-Materialien.

@export var wobble_stiffness: float = 140.0
@export var wobble_damping: float = 9.0
@export var flash_duration: float = 0.12

var _flash_material := StandardMaterial3D.new()
var _flash_left: float = 0.0
var _wobble_axis: Vector3 = Vector3.RIGHT
var _wobble_angle: float = 0.0
var _wobble_velocity: float = 0.0
var _defeat_time: float = -1.0
var _defeat_axis: Vector3 = Vector3.RIGHT
var _defeat_fall: bool = false

@onready var _pivot: Node3D = $Wobble
@onready var _hp_label: Label3D = $HpLabel


func _ready() -> void:
	_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_material.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	for mesh in find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = _flash_material


func flash() -> void:
	_flash_left = flash_duration


func hit_react(local_direction: Vector3) -> void:
	var flat := Vector3(local_direction.x, 0.0, local_direction.z)
	if flat.length_squared() < 0.0001:
		return
	_wobble_axis = Vector3.UP.cross(flat.normalized()).normalized()
	_wobble_velocity += 7.0


func set_hp(hp: float, max_hp: float) -> void:
	_hp_label.text = "HP %d" % int(ceil(hp))
	var ratio := hp / maxf(max_hp, 1.0)
	_hp_label.modulate = Color(1.0, 0.35, 0.25).lerp(Color(1.0, 0.95, 0.8), ratio)


func play_defeat(by_fall: bool, local_direction: Vector3) -> void:
	_defeat_fall = by_fall
	_defeat_time = 0.0
	var flat := Vector3(local_direction.x, 0.0, local_direction.z)
	_defeat_axis = Vector3.UP.cross(flat.normalized()).normalized() if flat.length_squared() > 0.0001 else Vector3.RIGHT
	_hp_label.text = "KANTE!" if by_fall else "K.O."


func reset_visual() -> void:
	_defeat_time = -1.0
	_wobble_angle = 0.0
	_wobble_velocity = 0.0
	_flash_left = 0.0
	_pivot.transform = Transform3D.IDENTITY
	_pivot.scale = Vector3.ONE
	_hp_label.visible = true


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
	_flash_material.albedo_color.a = 0.85 * (_flash_left / flash_duration)

	if _defeat_time >= 0.0:
		_defeat_time += delta
		if not _defeat_fall:
			# Umkippen in Stoßrichtung, dann einsinken.
			var t := clampf(_defeat_time / 0.35, 0.0, 1.0)
			var sink := clampf((_defeat_time - 0.6) / 0.5, 0.0, 1.0)
			_pivot.transform = Transform3D(Basis(_defeat_axis, ease(t, 0.4) * deg_to_rad(85.0)), Vector3(0.0, -sink * 0.6, 0.0))
			_pivot.scale = Vector3.ONE * (1.0 - sink * 0.6)
			_hp_label.visible = sink < 0.5
		return

	# Gedämpfte Feder für Trefferwackeln.
	var accel := -wobble_stiffness * _wobble_angle - wobble_damping * _wobble_velocity
	_wobble_velocity += accel * delta
	_wobble_angle += _wobble_velocity * delta
	_pivot.transform = Transform3D(Basis(_wobble_axis, clampf(_wobble_angle, -0.8, 0.8)), Vector3.ZERO)
