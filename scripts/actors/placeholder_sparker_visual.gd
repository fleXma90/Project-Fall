class_name PlaceholderSparkerVisual
extends SparkerVisual
## M2C-Placeholder aus Godot-Primitiven. Animiert nur eigene Knoten; Gameplay kennt nur SparkerVisual.
## Ankündigung über Form statt nur Farbe: wachsende Ladungskugel, geduckte Abstützpose und
## zurückgezogenes Rohr ab der Festlegung, Rückstoß und Mündungsblitz beim Schuss.

var _action: Action = Action.NONE
var _progress: float = 0.0
var _committed: bool = false
var _move_amount: float = 0.0
var _time: float = 0.0
var _bob_phase: float = 0.0
var _flash: HitFlash
var _core_material: StandardMaterial3D
var _charge_material: StandardMaterial3D
var _flash_material: StandardMaterial3D
var _kick: float = 0.0
var _muzzle_flash_left: float = 0.0
var _hit_lean: Vector3 = Vector3.ZERO
var _squat: float = 0.0
var _defeat_time: float = -1.0
var _defeat_axis: Vector3 = Vector3.RIGHT
var _defeat_fall: bool = false

@onready var _root: Node3D = $Root
@onready var _body: Node3D = $Root/Body
@onready var _cannon: Node3D = $Root/Body/Cannon
@onready var _charge: MeshInstance3D = $Root/Body/Cannon/Charge
@onready var _muzzle_flash: MeshInstance3D = $Root/Body/Cannon/MuzzleFlash
@onready var _core: MeshInstance3D = $Root/Body/Core
@onready var _hp_label: Label3D = $HpLabel


func _ready() -> void:
	_flash = HitFlash.new(self)
	_core_material = (_core.mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
	_core.material_override = _core_material
	_charge_material = (_charge.mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
	_charge.material_override = _charge_material
	_flash_material = (_muzzle_flash.mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
	_muzzle_flash.material_override = _flash_material
	_muzzle_flash.visible = false
	_charge.visible = false


func apply_state(action: Action, progress: float, committed: bool, move_amount: float) -> void:
	_action = action
	_progress = progress
	_committed = committed
	_move_amount = move_amount


func play_fire() -> void:
	_kick = 1.0
	_muzzle_flash_left = 0.14
	_muzzle_flash.visible = true


func flash() -> void:
	_flash.trigger()


func hit_react(local_direction: Vector3) -> void:
	var flat := Vector3(local_direction.x, 0.0, local_direction.z)
	if flat.length_squared() > 0.0001:
		_hit_lean = flat.normalized() * 0.55


func set_hp(hp: float, max_hp: float) -> void:
	_hp_label.text = "HP %d" % int(ceil(hp))
	_hp_label.modulate = Color(1.0, 0.35, 0.25).lerp(Color(1.0, 0.9, 0.6), hp / maxf(max_hp, 1.0))


func play_defeat(by_fall: bool, local_direction: Vector3) -> void:
	_defeat_fall = by_fall
	_defeat_time = 0.0
	var flat := Vector3(local_direction.x, 0.0, local_direction.z)
	_defeat_axis = Vector3.UP.cross(flat.normalized()).normalized() if flat.length_squared() > 0.0001 else Vector3.RIGHT
	_hp_label.text = "KANTE!" if by_fall else "BESIEGT"
	_charge.visible = false


func reset_visual() -> void:
	_defeat_time = -1.0
	_hit_lean = Vector3.ZERO
	_kick = 0.0
	_squat = 0.0
	_muzzle_flash_left = 0.0
	_muzzle_flash.visible = false
	_charge.visible = false
	_root.transform = Transform3D.IDENTITY
	_hp_label.visible = true
	_flash.reset()


func _process(delta: float) -> void:
	_time += delta
	_flash.update(delta)

	# Mündungsblitz und Rückstoß klingen schnell ab.
	if _muzzle_flash_left > 0.0:
		_muzzle_flash_left = maxf(_muzzle_flash_left - delta, 0.0)
		var f := _muzzle_flash_left / 0.14
		_muzzle_flash.scale = Vector3.ONE * lerpf(1.6, 0.4, f)
		_flash_material.albedo_color.a = 0.9 * f
		_muzzle_flash.visible = _muzzle_flash_left > 0.0
	_kick = maxf(_kick - delta * 6.0, 0.0)

	if _defeat_time >= 0.0:
		_defeat_time += delta
		if not _defeat_fall:
			var t := clampf(_defeat_time / 0.4, 0.0, 1.0)
			var sink := clampf((_defeat_time - 0.8) / 0.6, 0.0, 1.0)
			_root.transform = Transform3D(Basis(_defeat_axis, ease(t, 0.4) * deg_to_rad(80.0)), Vector3(0.0, -sink * 0.5, 0.0))
			_hp_label.visible = sink < 0.5
		return

	# Ladungskugel wächst über das Aufladen; ab der Festlegung deutlich größer und pulsierend.
	var charging := _action == Action.CHARGE
	_charge.visible = charging
	var charge_scale := 0.0
	if charging:
		charge_scale = lerpf(0.25, 0.9, _progress)
		if _committed:
			charge_scale = 1.35 + sin(_time * 40.0) * 0.12
	_charge.scale = Vector3.ONE * maxf(charge_scale, 0.01)
	_charge_material.emission_energy_multiplier = 3.0 + (6.0 if _committed else 0.0)
	var core_target := 1.0
	if charging:
		core_target = 2.0 + _progress * 4.0
	elif _action == Action.RECOVER:
		core_target = 0.4
	_core_material.emission_energy_multiplier = lerpf(_core_material.emission_energy_multiplier, core_target, 1.0 - exp(-12.0 * delta))

	# Pose: geduckt/abgestützt ab der Festlegung, Rohr zurückgezogen; Rückstoß beim Schuss; erschlafft in Erholung.
	var squat_target := 0.0
	if charging and _committed:
		squat_target = 1.0
	elif _action == Action.RECOVER:
		squat_target = 0.4
	_squat = lerpf(_squat, squat_target, 1.0 - exp(-20.0 * delta))
	var cannon_back := 0.1 * _squat + 0.22 * _kick
	_cannon.position = Vector3(0.0, 0.85 - 0.05 * _squat, cannon_back)
	_cannon.rotation.x = deg_to_rad(8.0 * _kick)

	var move := clampf(_move_amount, 0.0, 1.0)
	_bob_phase += delta * (6.0 + 10.0 * move)
	var waddle := sin(_bob_phase) * 0.08 * move
	_hit_lean = _hit_lean.lerp(Vector3.ZERO, 1.0 - exp(-6.0 * delta))
	var recover_slump := Vector3(0.0, 0.0, -0.12) if _action == Action.RECOVER else Vector3.ZERO
	var lean_vector := Vector3(waddle, 0.0, 0.08 * _squat) + _hit_lean + recover_slump
	var lean_basis := Basis.IDENTITY
	if lean_vector.length() > 0.0001:
		lean_basis = Basis(Vector3.UP.cross(lean_vector.normalized()).normalized(), lean_vector.length())
	var squash := Vector3(1.0 + 0.1 * _squat, 1.0 - 0.14 * _squat, 1.0 + 0.1 * _squat)
	_body.transform = Transform3D(lean_basis * Basis.from_scale(squash), Vector3(0.0, absf(sin(_bob_phase)) * 0.04 * move, 0.0))
