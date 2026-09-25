class_name PlaceholderScraplingVisual
extends ScraplingVisual
## M2A-Placeholder aus Godot-Primitiven. Animiert nur eigene Knoten; Gameplay kennt nur ScraplingVisual.
## Pose = [Gier, Neigung, Oberkörperdrehung, Vorlage, Absenken] wie beim Golem-Placeholder
## (Gier > 0 = rechte Seite, Neigung > 0 = oben, vorne ist lokal -Z).

const POSE_REST: Array[float] = [35.0, -35.0, 0.0, 0.15, 0.0]      # Messer tief vorne rechts
const POSE_WINDUP: Array[float] = [115.0, 65.0, 35.0, -0.05, 0.05] # hoch über der rechten Schulter
const POSE_STRIKE: Array[float] = [-55.0, -30.0, -30.0, 0.35, 0.08] # diagonaler Hieb nach links unten
const POSE_SLUMP: Array[float] = [-62.0, -40.0, -32.0, 0.42, 0.12]  # Erholung: Messer hängt unten
## Anteil der Recovery, in dem der Scrapling sichtbar erschöpft verharrt.
const SLUMP_SHARE: float = 0.6

@export var pose_sharpness: float = 12.0

var _action: Action = Action.NONE
var _progress: float = 0.0
var _move_amount: float = 0.0
var _committed: bool = false
var _pose: Array[float] = POSE_REST.duplicate()
var _bob_phase: float = 0.0
var _time: float = 0.0
var _flash: HitFlash
var _eye_material: StandardMaterial3D
var _hit_lean: Vector3 = Vector3.ZERO
var _defeat_time: float = -1.0
var _defeat_axis: Vector3 = Vector3.RIGHT
var _defeat_fall: bool = false

@onready var _root: Node3D = $Root
@onready var _body: Node3D = $Root/Body
@onready var _swing_pivot: Node3D = $Root/Body/SwingPivot
@onready var _socket: Node3D = $Root/Body/SwingPivot/HandSocket
@onready var _arm_left: Node3D = $Root/Body/ArmLeft
@onready var _leg_left: Node3D = $Root/Body/LegLeft
@onready var _leg_right: Node3D = $Root/Body/LegRight
@onready var _eye: MeshInstance3D = $Root/Body/Eye
@onready var _hp_label: Label3D = $HpLabel


func _ready() -> void:
	_flash = HitFlash.new(self)
	_eye_material = (_eye.mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
	_eye.material_override = _eye_material


func apply_state(action: Action, progress: float, move_amount: float, committed: bool) -> void:
	_action = action
	_progress = progress
	_move_amount = move_amount
	_committed = committed


func get_weapon_socket() -> Node3D:
	return _socket


func flash() -> void:
	_flash.trigger()


func hit_react(local_direction: Vector3) -> void:
	var flat := Vector3(local_direction.x, 0.0, local_direction.z)
	if flat.length_squared() > 0.0001:
		_hit_lean = flat.normalized() * 0.5


func set_hp(hp: float, max_hp: float) -> void:
	_hp_label.text = "HP %d" % int(ceil(hp))
	_hp_label.modulate = Color(1.0, 0.35, 0.25).lerp(Color(0.75, 1.0, 1.0), hp / maxf(max_hp, 1.0))


func play_defeat(by_fall: bool, local_direction: Vector3) -> void:
	_defeat_fall = by_fall
	_defeat_time = 0.0
	var flat := Vector3(local_direction.x, 0.0, local_direction.z)
	_defeat_axis = Vector3.UP.cross(flat.normalized()).normalized() if flat.length_squared() > 0.0001 else Vector3.RIGHT
	_hp_label.text = "KANTE!" if by_fall else "BESIEGT"


func reset_visual() -> void:
	_defeat_time = -1.0
	_hit_lean = Vector3.ZERO
	_pose = POSE_REST.duplicate()
	_root.transform = Transform3D.IDENTITY
	_hp_label.visible = true
	_flash.reset()


func _process(delta: float) -> void:
	_time += delta
	_flash.update(delta)

	# Auge: normal gedimmt, ab Richtungsfestlegung und im Hieb hell (zusätzlich zur Bodenmarkierung).
	var alert := _committed and (_action == Action.WINDUP or _action == Action.ACTIVE)
	_eye_material.emission_energy_multiplier = lerpf(_eye_material.emission_energy_multiplier, 9.0 if alert else 2.0, 1.0 - exp(-25.0 * delta))

	if _defeat_time >= 0.0:
		_defeat_time += delta
		if not _defeat_fall:
			var t := clampf(_defeat_time / 0.4, 0.0, 1.0)
			var sink := clampf((_defeat_time - 0.8) / 0.6, 0.0, 1.0)
			_root.transform = Transform3D(Basis(_defeat_axis, ease(t, 0.4) * deg_to_rad(80.0)), Vector3(0.0, -sink * 0.5, 0.0))
			_hp_label.visible = sink < 0.5
		return

	var target := _target_pose()
	if _action == Action.WINDUP or _action == Action.ACTIVE or _action == Action.RECOVERY:
		_pose = target
	else:
		_pose = _blend(_pose, target, 1.0 - exp(-pose_sharpness * delta))
	var yaw := _pose[0]
	var pitch := _pose[1]
	var twist := _pose[2]
	var lean := _pose[3]
	var crouch := _pose[4]
	_swing_pivot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(-(yaw - twist)), 0.0)

	var move := clampf(_move_amount, 0.0, 1.0)
	_bob_phase += delta * (5.0 + 10.0 * move)
	var bob := absf(sin(_bob_phase)) * 0.06 * move
	_leg_left.rotation.x = sin(_bob_phase) * 0.8 * move
	_leg_right.rotation.x = -sin(_bob_phase) * 0.8 * move
	var arm_target := -sin(_bob_phase) * 0.7 * move
	if _action == Action.WINDUP:
		arm_target = -1.3  # Gegengewicht nach vorne
	elif _action == Action.HIT:
		arm_target = -2.2
	_arm_left.rotation.x = lerpf(_arm_left.rotation.x, arm_target, 1.0 - exp(-16.0 * delta))

	# Treffer-Recoil klingt ab; im Windup nach Festlegung leichtes Zittern der Anspannung.
	_hit_lean = _hit_lean.lerp(Vector3.ZERO, 1.0 - exp(-6.0 * delta))
	var tremble := sin(_time * 55.0) * 0.03 if _action == Action.WINDUP and _committed else 0.0
	var lean_vector := Vector3(tremble, 0.0, -lean) + _hit_lean
	var lean_basis := Basis.IDENTITY
	if lean_vector.length() > 0.0001:
		lean_basis = Basis(Vector3.UP.cross(lean_vector.normalized()).normalized(), lean_vector.length())
	_body.transform = Transform3D(lean_basis * Basis(Vector3.UP, deg_to_rad(-twist)), Vector3(0.0, bob - crouch, 0.0))


func _target_pose() -> Array[float]:
	var t := _progress
	match _action:
		Action.WINDUP:
			# Bis zur Festlegung ausholen (≈ erste Hälfte), danach sichtbar gespannt halten.
			var weight := 1.0 if _committed else smoothstep(0.0, 1.0, minf(t / 0.55, 1.0))
			return _blend(POSE_REST, POSE_WINDUP, weight)
		Action.ACTIVE:
			return _blend(POSE_WINDUP, POSE_STRIKE, 1.0 - pow(1.0 - t, 2.0))
		Action.RECOVERY:
			if t < SLUMP_SHARE:
				return _blend(POSE_STRIKE, POSE_SLUMP, smoothstep(0.0, 1.0, t / SLUMP_SHARE))
			return _blend(POSE_SLUMP, POSE_REST, smoothstep(0.0, 1.0, (t - SLUMP_SHARE) / (1.0 - SLUMP_SHARE)))
	return POSE_REST


static func _blend(a: Array[float], b: Array[float], weight: float) -> Array[float]:
	var result: Array[float] = []
	for i in a.size():
		result.append(lerpf(a[i], b[i], weight))
	return result
