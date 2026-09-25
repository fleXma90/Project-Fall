class_name PlaceholderGolemVisual
extends PlayerVisual
## M1-Placeholder aus Godot-Primitiven. Animiert ausschließlich eigene Knoten per Transform.
## Wird später durch einen Adapter um ein riggtes Modell ersetzt; Gameplay bleibt unverändert.
##
## Hammerpose = (Gier a, Neigung p) in Grad am rechten Schulter-Pivot.
## a > 0 = zur rechten Seite des Golems, p > 0 = nach oben. Vorne ist lokal -Z.

const POSE_REST := Vector2(150.0, 40.0)        # Hammer auf der Schulter
const POSE_WINDUP := Vector2(115.0, 72.0)      # weit ausgeholt über rechter Schulter
const POSE_STRIKE_END := Vector2(-60.0, -28.0) # Kopf schlägt links vorne auf
const POSE_FALLING := Vector2(120.0, 85.0)

@export var pose_sharpness: float = 14.0
@export var lean_sharpness: float = 12.0

var _state := PlayerVisualState.new()
var _pose: Vector2 = POSE_REST
var _bob_phase: float = 0.0
var _lean: Vector3 = Vector3.ZERO
var _squash: float = 0.0
var _respawn_time: float = -1.0
var _time: float = 0.0

@onready var _body: Node3D = $Body
@onready var _swing_pivot: Node3D = $Body/SwingPivot
@onready var _socket: Node3D = $Body/SwingPivot/HandSocket
@onready var _arm_left: Node3D = $Body/ArmLeft
@onready var _leg_left: Node3D = $Body/LegLeft
@onready var _leg_right: Node3D = $Body/LegRight


func apply_state(state: PlayerVisualState) -> void:
	_state = state


func get_weapon_socket() -> Node3D:
	return _socket


func play_respawn() -> void:
	_respawn_time = 0.0


func _process(delta: float) -> void:
	_time += delta
	var s := _state
	var attacking := s.action == PlayerVisualState.Action.ATTACK_WINDUP \
			or s.action == PlayerVisualState.Action.ATTACK_ACTIVE \
			or s.action == PlayerVisualState.Action.ATTACK_RECOVERY

	# Hammerpose: Angriffe direkt aus dem Gameplaytiming, sonst weich geglättet.
	var target_pose := _target_pose(s)
	if attacking:
		_pose = target_pose
	else:
		_pose = _pose.lerp(target_pose, 1.0 - exp(-pose_sharpness * delta))
	_swing_pivot.rotation = Vector3(deg_to_rad(_pose.y), deg_to_rad(-_pose.x), 0.0)

	# Laufen: Bob, Beine, linker Arm.
	var move := clampf(s.move_amount, 0.0, 1.0) if s.grounded else 0.0
	_bob_phase += delta * (4.0 + 9.0 * move)
	var bob := absf(sin(_bob_phase)) * 0.07 * move
	_leg_left.rotation.x = sin(_bob_phase) * 0.7 * move
	_leg_right.rotation.x = -sin(_bob_phase) * 0.7 * move
	var arm_swing := -sin(_bob_phase) * 0.6 * move
	if s.falling:
		arm_swing = -2.6 + sin(_time * 22.0) * 0.35  # Arm hochgerissen
	_arm_left.rotation.x = lerpf(_arm_left.rotation.x, arm_swing, 1.0 - exp(-18.0 * delta))

	# Lean: in Laufrichtung, beim Dodge stark, beim Fallen taumelnd.
	var lean_target := s.local_move_direction * 0.10 * move
	var squash_target := 0.0
	if s.action == PlayerVisualState.Action.DODGE:
		lean_target = s.local_dodge_direction * 0.42
		squash_target = 1.0
	elif s.falling:
		lean_target = Vector3(sin(_time * 13.0) * 0.25, 0.0, 0.3)
	elif s.action == PlayerVisualState.Action.ATTACK_ACTIVE or s.action == PlayerVisualState.Action.ATTACK_RECOVERY:
		lean_target = Vector3(0.0, 0.0, -0.18)
	_lean = _lean.lerp(lean_target, 1.0 - exp(-lean_sharpness * delta))
	_squash = lerpf(_squash, squash_target, 1.0 - exp(-20.0 * delta))

	var lean_basis := Basis.IDENTITY
	var lean_amount := _lean.length()
	if lean_amount > 0.0001:
		lean_basis = Basis(Vector3.UP.cross(_lean / lean_amount).normalized(), lean_amount)
	var twist := deg_to_rad((_pose.x - POSE_REST.x) * 0.08)
	var lunge := -0.12 if s.action == PlayerVisualState.Action.ATTACK_ACTIVE else 0.0
	var squash_scale := Vector3(1.0 + 0.12 * _squash, 1.0 - 0.14 * _squash, 1.0 + 0.12 * _squash)

	var pop := 1.0
	if _respawn_time >= 0.0:
		_respawn_time += delta
		var t := clampf(_respawn_time / 0.32, 0.0, 1.0)
		pop = 1.0 + sin(t * PI * 1.5) * (1.0 - t) * 0.35 if t > 0.25 else lerpf(0.2, 1.1, t / 0.25)
		if t >= 1.0:
			_respawn_time = -1.0
			pop = 1.0

	_body.transform = Transform3D(
			lean_basis * Basis(Vector3.UP, twist) * Basis.from_scale(squash_scale * pop),
			Vector3(0.0, bob, lunge))


func _target_pose(s: PlayerVisualState) -> Vector2:
	var t := s.action_progress
	match s.action:
		PlayerVisualState.Action.ATTACK_WINDUP:
			return POSE_REST.lerp(POSE_WINDUP, ease(t, 0.5))
		PlayerVisualState.Action.ATTACK_ACTIVE:
			return POSE_WINDUP.lerp(POSE_STRIKE_END, pow(t, 1.4))
		PlayerVisualState.Action.ATTACK_RECOVERY:
			if t < 0.3:
				return POSE_STRIKE_END + Vector2(0.0, sin(t / 0.3 * PI) * 7.0)
			var u := smoothstep(0.0, 1.0, (t - 0.3) / 0.7)
			return POSE_STRIKE_END.lerp(POSE_REST, u) + Vector2(0.0, sin(u * PI) * 45.0)
	if s.falling:
		return POSE_FALLING + Vector2(sin(_time * 17.0) * 12.0, 0.0)
	return POSE_REST
