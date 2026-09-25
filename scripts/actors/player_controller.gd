class_name PlayerController
extends CharacterBody3D
## Gameplay-Root des Players: Bewegung, Facing, HP, Kollisionskörper, Angriffs-/Dodge-Zustand.
##
## Kennt die Darstellung nur über die PlayerVisual-Schnittstelle unter `VisualRoot` und die Waffe nur
## über den WeaponController. Richtungen sind getrennte, normalisierte XZ-Vektoren.
## Weltbewegung kommt immer aus diesem Script (kein Root-Motion).

signal fell_out
signal respawned
signal health_changed(current: float, maximum: float)
signal hit_landed(target: Node3D, point: Vector3)

enum State { MOVE, ATTACK, DODGE, FALLING, OUT }

@export var tuning: PlayerTuning

var state: State = State.MOVE
var hp: float = 100.0
## Camera-relative Bewegungsabsicht auf XZ, Länge 0..1 (analoge Stärke bleibt erhalten).
var move_direction: Vector3 = Vector3.ZERO
## Letzte bewusste Blickrichtung. Wird nur von Stick-/Mausabsicht gesetzt.
var facing_direction: Vector3 = Vector3.FORWARD
## Beim Angriffsstart aus facing_direction kopiert und für den Swing fixiert.
var attack_direction: Vector3 = Vector3.FORWARD
## Beim Dodge-Start fixiert.
var dodge_direction: Vector3 = Vector3.FORWARD
var fall_count: int = 0

var _clock: float = 0.0
var _attack_ready_time: float = 0.0
var _dodge_ready_time: float = 0.0
var _dodge_elapsed: float = 0.0
var _airborne_time: float = 0.0
var _gravity: float = 18.0
var _visual: PlayerVisual = null
var _visual_state := PlayerVisualState.new()

@onready var visual_root: Node3D = $VisualRoot
@onready var weapon: WeaponController = $WeaponController


func _ready() -> void:
	if tuning == null:
		tuning = PlayerTuning.new()
	hp = tuning.max_hp
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
	weapon.hit_landed.connect(_on_weapon_hit)
	refresh_visual()


## Sucht den aktuellen Visual-Adapter unter VisualRoot. Nach einem Austausch erneut aufrufen.
func refresh_visual() -> void:
	_visual = null
	for child in visual_root.get_children():
		if child is PlayerVisual:
			_visual = child
			break
	weapon.set_socket(_visual.get_weapon_socket() if _visual != null else null)


func _physics_process(delta: float) -> void:
	_clock += delta
	if state == State.OUT:
		return
	var cam := get_viewport().get_camera_3d()
	move_direction = camera_relative(InputRouter.move_input, cam)
	_update_facing(cam)
	_update_actions(delta)
	_apply_horizontal_velocity(delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()
	_update_airborne(delta)
	_update_root_rotation(delta)
	_push_visual_state()


# --- Richtungen --------------------------------------------------------------

## Bildschirmvektor (x rechts, y oben) → XZ-Weltvektor über auf XZ projizierte Kamera-Achsen.
static func camera_relative(screen_input: Vector2, cam: Camera3D) -> Vector3:
	if screen_input == Vector2.ZERO:
		return Vector3.ZERO
	var forward := Vector3.FORWARD
	var right := Vector3.RIGHT
	if cam != null:
		var basis := cam.global_basis
		var f := Vector3(-basis.z.x, 0.0, -basis.z.z)
		if f.length_squared() < 0.0001:
			f = Vector3(basis.y.x, 0.0, basis.y.z)  # Kamera blickt senkrecht nach unten
		forward = f.normalized()
		right = Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	var world := right * screen_input.x + forward * screen_input.y
	return world.limit_length(1.0)


## Kamera-Ray gegen horizontale Ebene in Höhe plane_y. Gibt null zurück, wenn kein Schnitt existiert.
static func project_screen_to_plane(cam: Camera3D, screen_pos: Vector2, plane_y: float) -> Variant:
	var origin := cam.project_ray_origin(screen_pos)
	var normal := cam.project_ray_normal(screen_pos)
	return Plane(Vector3.UP, plane_y).intersects_ray(origin, normal)


func _update_facing(cam: Camera3D) -> void:
	if InputRouter.uses_mouse_facing():
		if cam == null:
			return
		var hit: Variant = project_screen_to_plane(cam, InputRouter.mouse_position, global_position.y)
		if hit == null:
			return
		var to_point: Vector3 = (hit as Vector3) - global_position
		to_point.y = 0.0
		if to_point.length() > tuning.mouse_facing_min_distance:
			facing_direction = to_point.normalized()
	elif InputRouter.uses_stick_facing() and move_direction.length_squared() > 0.000001:
		facing_direction = move_direction.normalized()


# --- Aktionen ----------------------------------------------------------------

func _update_actions(delta: float) -> void:
	if state == State.DODGE:
		_dodge_elapsed += delta
		if _dodge_elapsed >= tuning.dodge_duration:
			_end_dodge()
	if state == State.ATTACK and weapon.tick(delta):
		state = State.MOVE

	var grounded := is_on_floor()
	var can_dodge := (state == State.MOVE or state == State.ATTACK) and grounded and _clock >= _dodge_ready_time
	if can_dodge and InputRouter.consume_dodge_press():
		_start_dodge()
		return
	var can_attack := state == State.MOVE and grounded and _clock >= _attack_ready_time
	if can_attack and (InputRouter.attack_held or InputRouter.consume_attack_press()):
		_start_attack()


func _start_attack() -> void:
	attack_direction = facing_direction
	state = State.ATTACK
	# Voller Takt ab Start: Dodge-Abbruch beschleunigt den nächsten Angriff nicht.
	_attack_ready_time = _clock + weapon.data.total_duration()
	rotation.y = yaw_for_direction(attack_direction)
	weapon.start_swing(attack_direction)


func _start_dodge() -> void:
	if state == State.ATTACK:
		weapon.cancel()
	dodge_direction = move_direction.normalized() if move_direction.length_squared() > 0.0001 else facing_direction
	state = State.DODGE
	_dodge_elapsed = 0.0
	_dodge_ready_time = _clock + tuning.dodge_cooldown


func _end_dodge() -> void:
	state = State.MOVE
	var horizontal := Vector2(velocity.x, velocity.z).limit_length(tuning.move_speed)
	velocity.x = horizontal.x
	velocity.z = horizontal.y


func is_invulnerable() -> bool:
	return state == State.DODGE and _dodge_elapsed >= tuning.dodge_iframe_start \
			and _dodge_elapsed <= tuning.dodge_iframe_end


# --- Bewegung ----------------------------------------------------------------

func _apply_horizontal_velocity(delta: float) -> void:
	var horizontal := Vector2(velocity.x, velocity.z)
	if state == State.DODGE:
		horizontal = Vector2(dodge_direction.x, dodge_direction.z) * tuning.dodge_speed
	else:
		var speed := tuning.move_speed
		if state == State.ATTACK:
			speed *= tuning.attack_move_multiplier
		var target := Vector2(move_direction.x, move_direction.z) * speed
		if is_on_floor():
			var rate := tuning.acceleration if target != Vector2.ZERO else tuning.deceleration
			horizontal = horizontal.move_toward(target, rate * delta)
		elif target != Vector2.ZERO:
			# In der Luft nur schwache Steuerung; ohne Eingabe bleibt der Schwung erhalten.
			horizontal = horizontal.move_toward(target, tuning.air_acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y


func _update_airborne(delta: float) -> void:
	if is_on_floor():
		_airborne_time = 0.0
		if state == State.FALLING:
			state = State.MOVE
		return
	_airborne_time += delta
	if state == State.MOVE and _airborne_time >= tuning.fall_state_delay and velocity.y < 0.0:
		state = State.FALLING


static func yaw_for_direction(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


func _update_root_rotation(delta: float) -> void:
	var target := attack_direction if state == State.ATTACK else facing_direction
	var weight := 1.0 - exp(-tuning.turn_sharpness * delta)
	rotation.y = lerp_angle(rotation.y, yaw_for_direction(target), weight)


func _push_visual_state() -> void:
	if _visual == null:
		return
	var s := _visual_state
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	s.move_amount = horizontal.length() / maxf(tuning.move_speed, 0.01)
	s.local_move_direction = global_basis.inverse() * horizontal.normalized() if horizontal.length() > 0.05 else Vector3.ZERO
	s.grounded = is_on_floor()
	s.falling = state == State.FALLING
	s.action = PlayerVisualState.Action.NONE
	s.action_progress = 0.0
	if state == State.ATTACK:
		match weapon.phase:
			WeaponController.Phase.WINDUP:
				s.action = PlayerVisualState.Action.ATTACK_WINDUP
			WeaponController.Phase.ACTIVE:
				s.action = PlayerVisualState.Action.ATTACK_ACTIVE
			WeaponController.Phase.RECOVERY:
				s.action = PlayerVisualState.Action.ATTACK_RECOVERY
		s.action_progress = weapon.phase_progress()
	elif state == State.DODGE:
		s.action = PlayerVisualState.Action.DODGE
		s.action_progress = clampf(_dodge_elapsed / tuning.dodge_duration, 0.0, 1.0)
		s.local_dodge_direction = global_basis.inverse() * dodge_direction
	_visual.apply_state(s)


# --- Fall / Respawn ----------------------------------------------------------

## Von der Arena beim Unterschreiten der Killhöhe aufgerufen. Idempotent: true nur beim ersten Mal.
func fall_out() -> bool:
	if state == State.OUT:
		return false
	state = State.OUT
	weapon.cancel()
	velocity = Vector3.ZERO
	fall_count += 1
	visual_root.visible = false
	weapon.visible = false
	fell_out.emit()
	return true


func respawn_at(spawn: Transform3D) -> void:
	global_position = spawn.origin
	velocity = Vector3.ZERO
	var forward := -spawn.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		facing_direction = forward.normalized()
	attack_direction = facing_direction
	rotation.y = yaw_for_direction(facing_direction)
	weapon.cancel()
	state = State.MOVE
	_airborne_time = 0.0
	_attack_ready_time = _clock
	_dodge_ready_time = _clock
	visual_root.visible = true
	weapon.visible = true
	if _visual != null:
		_visual.play_respawn()
	respawned.emit()


## Vollständiger Trainingsreset: Respawn plus volle HP.
func reset_full(spawn: Transform3D) -> void:
	hp = tuning.max_hp
	health_changed.emit(hp, tuning.max_hp)
	respawn_at(spawn)


func _on_weapon_hit(target: Node3D, point: Vector3, _hit: HitInfo) -> void:
	hit_landed.emit(target, point)
