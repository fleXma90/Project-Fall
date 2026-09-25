class_name PlaceholderGolemVisual
extends PlayerVisual
## M1-Placeholder aus Godot-Primitiven. Animiert ausschließlich eigene Knoten per Transform.
## Wird später durch einen Adapter um ein riggtes Modell ersetzt; Gameplay bleibt unverändert.
##
## Angriffspose = [Gier, Neigung, Oberkörperdrehung, Vorlage, Absenken]:
## - Gier/Neigung (Grad) geben die Hammerrichtung relativ zum Player-Root an
##   (Gier > 0 = rechte Seite, Neigung > 0 = oben; vorne ist lokal -Z).
## - Oberkörperdrehung (Grad, > 0 = nach rechts) dreht Body samt Schulter; der Schwung-Pivot
##   gleicht sie aus, damit die Hammerrichtung exakt der Gier entspricht (Trail/Sektor passen).
## - Vorlage (rad, > 0 = nach vorne) und Absenken (m) tragen das Gewicht.
## Der Schlag läuft breit von rechts hinten nach links vorne; das Zurückführen setzt die Drehung
## um den Rücken fort (Gier −210° ≙ 150°), statt als zweiter Schwung durch die Front zu laufen.

const POSE_REST: Array[float] = [150.0, 60.0, 0.0, 0.0, 0.0]        # Hammer steil auf der Schulter
const POSE_WINDUP: Array[float] = [120.0, 6.0, 45.0, -0.14, 0.10]   # weit zur Seite ausgeholt, Gewicht hinten
const POSE_STRIKE: Array[float] = [-78.0, -6.0, -30.0, 0.22, 0.05]  # Kopf quer durch den Sektor
const POSE_FOLLOW: Array[float] = [-112.0, -20.0, -42.0, 0.28, 0.10] # Gewicht nachlaufen lassen und abfangen
const POSE_REST_WRAP: Array[float] = [-210.0, 60.0, 0.0, 0.0, 0.0]   # = Ruhepose, über den Rücken erreicht
const POSE_FALLING: Array[float] = [120.0, 85.0, 0.0, 0.0, 0.0]
## Anteil der Recovery für das Abfangen des Gewichts, danach Rückführung.
const FOLLOW_SHARE: float = 0.3

@export var pose_sharpness: float = 14.0
@export var lean_sharpness: float = 12.0

var _state := PlayerVisualState.new()
var _pose: Array[float] = POSE_REST.duplicate()
var _windup_from: Array[float] = POSE_REST.duplicate()
var _last_action: PlayerVisualState.Action = PlayerVisualState.Action.NONE
var _bob_phase: float = 0.0
var _lean: Vector3 = Vector3.ZERO
var _squash: float = 0.0
var _respawn_time: float = -1.0
var _time: float = 0.0
var _flash: HitFlash
var _hit_direction: Vector3 = Vector3.BACK

@onready var _body: Node3D = $Body
@onready var _swing_pivot: Node3D = $Body/SwingPivot
@onready var _socket: Node3D = $Body/SwingPivot/HandSocket
@onready var _arm_left: Node3D = $Body/ArmLeft
@onready var _leg_left: Node3D = $Body/LegLeft
@onready var _leg_right: Node3D = $Body/LegRight


func _ready() -> void:
	_flash = HitFlash.new(self, Color(1.0, 0.45, 0.35))


func apply_state(state: PlayerVisualState) -> void:
	_state = state


func get_weapon_socket() -> Node3D:
	return _socket


func play_respawn() -> void:
	_respawn_time = 0.0
	_flash.reset()


func play_hit(local_direction: Vector3) -> void:
	_flash.trigger()
	var flat := Vector3(local_direction.x, 0.0, local_direction.z)
	_hit_direction = flat.normalized() if flat.length_squared() > 0.0001 else Vector3.BACK


func _process(delta: float) -> void:
	_time += delta
	_flash.update(delta)
	var s := _state
	var attacking := _is_attack(s.action)

	# Neues Ausholen startet an der aktuell sichtbaren Pose (kein Sprung nach Dodge o. Ä.).
	if s.action == PlayerVisualState.Action.ATTACK_WINDUP and _last_action != s.action:
		_windup_from = _pose.duplicate()
		_windup_from[0] = POSE_REST[0] + wrapf(_windup_from[0] - POSE_REST[0], -180.0, 180.0)
	_last_action = s.action

	# Angriffe direkt aus dem Gameplaytiming, sonst weich geglättet.
	var target := _target_pose(s)
	if attacking:
		_pose = target
	else:
		# Gier auf den nächstgelegenen gleichwertigen Winkel bringen (−210° ≙ 150°), dann glätten.
		_pose[0] = target[0] + wrapf(_pose[0] - target[0], -180.0, 180.0)
		_pose = _blend(_pose, target, 1.0 - exp(-pose_sharpness * delta))
	var yaw := _pose[0]
	var pitch := _pose[1]
	var twist := _pose[2]
	var attack_lean := _pose[3]
	var crouch := _pose[4]
	_swing_pivot.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(-(yaw - twist)), 0.0)

	# Laufen: Bob, Beine, linker Arm.
	var move := clampf(s.move_amount, 0.0, 1.0) if s.grounded else 0.0
	_bob_phase += delta * (4.0 + 9.0 * move)
	var bob := absf(sin(_bob_phase)) * 0.07 * move
	_leg_left.rotation.x = sin(_bob_phase) * 0.7 * move
	_leg_right.rotation.x = -sin(_bob_phase) * 0.7 * move
	var arm_target := -sin(_bob_phase) * 0.6 * move
	if s.falling:
		arm_target = -2.6 + sin(_time * 22.0) * 0.35  # Arm hochgerissen
	elif attacking:
		arm_target = -0.9 - crouch * 4.0  # linker Arm greift zum Griff / fängt ab
	_arm_left.rotation.x = lerpf(_arm_left.rotation.x, arm_target, 1.0 - exp(-18.0 * delta))

	# Lean: in Laufrichtung, beim Dodge stark, beim Fallen taumelnd; Angriffsvorlage kommt aus der Pose.
	var lean_target := s.local_move_direction * 0.10 * move
	var squash_target := 0.0
	if s.dead:
		lean_target = Vector3(0.0, 0.0, 1.25)  # nach hinten umgekippt
		squash_target = 0.6
	elif s.action == PlayerVisualState.Action.HIT:
		lean_target = _hit_direction * 0.45  # vom Treffer weggestoßen
		squash_target = 0.5
	elif s.action == PlayerVisualState.Action.DODGE:
		lean_target = s.local_dodge_direction * 0.42
		squash_target = 1.0
	elif s.falling:
		lean_target = Vector3(sin(_time * 13.0) * 0.25, 0.0, 0.3)
	_lean = _lean.lerp(lean_target, 1.0 - exp(-lean_sharpness * delta))
	_squash = lerpf(_squash, squash_target, 1.0 - exp(-20.0 * delta))

	var lean_vector := _lean + Vector3(0.0, 0.0, -attack_lean)
	var lean_basis := Basis.IDENTITY
	var lean_amount := lean_vector.length()
	if lean_amount > 0.0001:
		lean_basis = Basis(Vector3.UP.cross(lean_vector / lean_amount).normalized(), lean_amount)
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
			lean_basis * Basis(Vector3.UP, deg_to_rad(-twist)) * Basis.from_scale(squash_scale * pop),
			Vector3(0.0, bob - crouch, 0.0))


func _target_pose(s: PlayerVisualState) -> Array[float]:
	var t := s.action_progress
	match s.action:
		PlayerVisualState.Action.ATTACK_WINDUP:
			# Schnell ausholen, oben kurz „hängen“ lassen: sichtbare Antizipation.
			return _blend(_windup_from, POSE_WINDUP, 1.0 - pow(1.0 - t, 2.4))
		PlayerVisualState.Action.ATTACK_ACTIVE:
			# Zügiger, breiter Schwung; kreuzt die Sektormitte etwa zur Hälfte des Trefferfensters.
			return _blend(POSE_WINDUP, POSE_STRIKE, smoothstep(0.0, 1.0, t))
		PlayerVisualState.Action.ATTACK_RECOVERY:
			if t < FOLLOW_SHARE:
				return _blend(POSE_STRIKE, POSE_FOLLOW, 1.0 - pow(1.0 - t / FOLLOW_SHARE, 2.0))
			var u := smoothstep(0.0, 1.0, (t - FOLLOW_SHARE) / (1.0 - FOLLOW_SHARE))
			var pose := _blend(POSE_FOLLOW, POSE_REST_WRAP, u)
			pose[1] += sin(u * PI) * 30.0  # über den Rücken anheben
			return pose
	if s.falling:
		var falling := POSE_FALLING.duplicate()
		falling[0] += sin(_time * 17.0) * 12.0
		return falling
	return POSE_REST


static func _is_attack(action: PlayerVisualState.Action) -> bool:
	return action == PlayerVisualState.Action.ATTACK_WINDUP \
			or action == PlayerVisualState.Action.ATTACK_ACTIVE \
			or action == PlayerVisualState.Action.ATTACK_RECOVERY


static func _blend(a: Array[float], b: Array[float], weight: float) -> Array[float]:
	var result: Array[float] = []
	for i in a.size():
		result.append(lerpf(a[i], b[i], weight))
	return result
