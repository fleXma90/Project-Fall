class_name Sparker
extends CharacterBody3D
## M2C-Fernkampfgegner „Funkenwerfer“. Kleine lokale Zustandsmaschine:
## IDLE → APPROACH → CHARGE → RECOVER → APPROACH, dazu HIT (Trefferreaktion) und DEFEATED.
##
## - APPROACH: dreht zum Spieler und läuft heran, solange der Spieler weiter als fire_distance entfernt ist
##   (oder der Funkenwerfer nicht im Kamerabild ist). Flieht nicht.
## - CHARGE: steht; dreht bis commit_time zum Spieler (nur Drehung), danach ist die Richtung fest.
##   Nach charge_time genau ein Schuss (Signal `fired`), kein Nachführen, keine Vorhersage.
## - Hammertreffer bricht das Aufladen ab: Ein nicht abgefeuerter Schuss entsteht nie später.
## Die Bodenprüfung betrifft nur die eigene Laufentscheidung; Knockback und Schwerkraft bleiben echt.

signal defeated(enemy: Sparker, reason: DefeatReason)
## Ein Hammertreffer hat ein laufendes Aufladen abgebrochen (für die Rundenauswertung).
signal attack_interrupted(enemy: Sparker)
signal charge_started(enemy: Sparker)
## Genau ein Schuss: Mündungsposition und festgelegte Richtung.
signal fired(enemy: Sparker, origin: Vector3, direction: Vector3)

enum State { INACTIVE, IDLE, APPROACH, CHARGE, RECOVER, HIT, DEFEATED }
enum DefeatReason { HP, FALL }

@export var tuning: SparkerTuning
@export_flags_3d_physics var ground_mask: int = 1
## Prototypregel: neue Aufladungen nur, wenn der Funkenwerfer im Kamerabild ist.
@export var require_on_screen: bool = true

var target: PlayerController = null
var state: State = State.IDLE
var hp: float = 60.0
var hit_radius: float = 0.4
var hit_stun: float = 0.2
var is_defeated: bool = false
var defeat_count: int = 0
var last_defeat_reason: DefeatReason = DefeatReason.HP
var neighbors: Array[Node3D] = []
var shots_fired: int = 0
var spawn_transform: Transform3D
## Schussrichtung des laufenden Aufladens (bis zur Festlegung nachgeführt, danach fix).
var fire_direction: Vector3 = Vector3.FORWARD

var _state_time: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO
var _knockback_duration: float = 0.0
var _knockback_left: float = 0.0
var _frozen: bool = false
var _gravity: float = 18.0
var _collision_layer_default: int = 0
var _visual: SparkerVisual = null

@onready var visual_root: Node3D = $VisualRoot


func _ready() -> void:
	if tuning == null:
		tuning = SparkerTuning.new()
	hit_radius = tuning.hit_radius
	hit_stun = tuning.hit_stun
	spawn_transform = global_transform
	_collision_layer_default = collision_layer
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
	for child in visual_root.get_children():
		if child is SparkerVisual:
			_visual = child
			break
	hp = tuning.max_hp
	_update_visual_hp()


func _physics_process(delta: float) -> void:
	if state == State.INACTIVE or _frozen:
		return
	_state_time += delta
	var desired := Vector3.ZERO
	match state:
		State.IDLE:
			if _has_target():
				_enter(State.APPROACH)
		State.APPROACH:
			desired = _approach(delta)
		State.CHARGE:
			_charge(delta)
		State.RECOVER:
			if _state_time >= tuning.recovery_time:
				_enter(State.APPROACH if _has_target() else State.IDLE)
		State.HIT:
			if _state_time >= hit_stun:
				_enter(State.APPROACH if _has_target() else State.IDLE)
	_apply_horizontal_velocity(desired, delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()
	_push_visual_state(desired)


# --- Verhalten -----------------------------------------------------------------

func _has_target() -> bool:
	return target != null and is_instance_valid(target) and target.is_targetable()


func forward() -> Vector3:
	var f := -global_basis.z
	return Vector3(f.x, 0.0, f.z).normalized()


func is_committed() -> bool:
	return state == State.CHARGE and _state_time >= tuning.commit_time


func charge_progress() -> float:
	return clampf(_state_time / tuning.charge_time, 0.0, 1.0) if state == State.CHARGE else 0.0


func state_time() -> float:
	return _state_time


func is_on_screen() -> bool:
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam.is_position_in_frustum(global_position + Vector3.UP * 0.7)


func muzzle_position() -> Vector3:
	return global_position + Vector3.UP * tuning.muzzle_height + fire_direction * tuning.muzzle_forward


func knockback_remaining() -> float:
	return _knockback_left


func _enter(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _to_target() -> Vector3:
	var to := target.global_position - global_position
	to.y = 0.0
	return to


func _approach(delta: float) -> Vector3:
	if not _has_target():
		_enter(State.IDLE)
		return Vector3.ZERO
	var to := _to_target()
	var distance := to.length()
	if distance > 0.01:
		_turn_toward(to / distance, delta)
	var may_charge := distance <= tuning.fire_distance and is_on_floor() and (not require_on_screen or is_on_screen())
	if may_charge:
		start_charge()
		return Vector3.ZERO
	var separation := GroupSpacing.push(self, neighbors, tuning.separation_radius, tuning.separation_strength, forward().cross(Vector3.UP))
	var direction := Vector3.ZERO
	if distance > tuning.min_approach_distance and distance > 0.01:
		direction = to / distance
	direction += separation
	if direction.length_squared() < 0.0001:
		return Vector3.ZERO
	direction = direction.normalized()
	if not has_ground_ahead(direction):
		return Vector3.ZERO  # Nur die eigene Laufentscheidung; kein Klemmen der Position.
	return direction * tuning.move_speed


func start_charge() -> void:
	_enter(State.CHARGE)
	fire_direction = forward()
	charge_started.emit(self)


func _charge(delta: float) -> void:
	if not is_committed():
		if _has_target():
			var to := _to_target()
			if to.length() > 0.01:
				_turn_toward(to.normalized(), delta)  # nur Drehen, kein Laufen
		fire_direction = forward()
	if _state_time >= tuning.charge_time:
		_fire()
		_enter(State.RECOVER)


func _fire() -> void:
	shots_fired += 1
	if _visual != null:
		_visual.play_fire()
	fired.emit(self, muzzle_position(), fire_direction)


func _turn_toward(direction: Vector3, delta: float) -> void:
	var yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-tuning.turn_sharpness * delta))


func has_ground_ahead(direction: Vector3) -> bool:
	var probe := global_position + direction * tuning.edge_probe_distance
	var query := PhysicsRayQueryParameters3D.create(probe + Vector3.UP * 0.5, probe + Vector3.DOWN * 1.0, ground_mask)
	query.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _apply_horizontal_velocity(desired: Vector3, delta: float) -> void:
	var horizontal := Vector2(velocity.x, velocity.z)
	if _knockback_left > 0.0:
		_knockback_left = maxf(_knockback_left - delta, 0.0)
		if is_on_floor():
			horizontal = Vector2(_knockback_velocity.x, _knockback_velocity.z) * (_knockback_left / _knockback_duration)
	elif is_on_floor():
		var target_velocity := Vector2(desired.x, desired.z)
		var rate := tuning.acceleration if target_velocity != Vector2.ZERO else tuning.deceleration
		horizontal = horizontal.move_toward(target_velocity, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y


# --- Treffer / Niederlage ---------------------------------------------------------

func receive_hit(hit: HitInfo) -> bool:
	if is_defeated or state == State.INACTIVE:
		return false
	hp = maxf(hp - hit.damage, 0.0)
	if state == State.CHARGE:
		attack_interrupted.emit(self)  # abgebrochenes Aufladen: kein späterer Schuss
	_knockback_velocity = Vector3(hit.knockback_velocity.x, 0.0, hit.knockback_velocity.z)
	_knockback_duration = maxf(hit.knockback_duration, 0.001)
	_knockback_left = _knockback_duration
	velocity.x = _knockback_velocity.x
	velocity.z = _knockback_velocity.z
	_update_visual_hp()
	if _visual != null:
		_visual.flash()
		_visual.hit_react(global_basis.inverse() * _knockback_velocity.normalized())
	if hp <= 0.0:
		_defeat(DefeatReason.HP)
	else:
		_enter(State.HIT)
	return true


func fall_out() -> bool:
	var first := _defeat(DefeatReason.FALL)
	_frozen = true
	velocity = Vector3.ZERO
	visible = false
	return first


func _defeat(reason: DefeatReason) -> bool:
	if is_defeated:
		return false
	is_defeated = true
	defeat_count += 1
	last_defeat_reason = reason
	_enter(State.DEFEATED)
	collision_layer = 0
	if _visual != null:
		_visual.play_defeat(reason == DefeatReason.FALL, global_basis.inverse() * _knockback_velocity.normalized())
	defeated.emit(self, reason)
	return true


func stop_combat() -> void:
	target = null
	if state != State.DEFEATED and state != State.INACTIVE:
		_enter(State.IDLE)


func set_active(active: bool) -> void:
	visible = active
	collision_layer = _collision_layer_default if active else 0
	_enter(State.IDLE if active else State.INACTIVE)


func reset_to(spawn: Transform3D) -> void:
	spawn_transform = spawn.orthonormalized()
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	_knockback_left = 0.0
	hp = tuning.max_hp
	hit_stun = tuning.hit_stun
	is_defeated = false
	_frozen = false
	defeat_count = 0
	shots_fired = 0
	set_active(true)
	if _visual != null:
		_visual.reset_visual()
	_update_visual_hp()


func _update_visual_hp() -> void:
	if _visual != null:
		_visual.set_hp(hp, tuning.max_hp)


func _push_visual_state(desired: Vector3) -> void:
	if _visual == null:
		return
	var action := SparkerVisual.Action.NONE
	var progress := 0.0
	match state:
		State.CHARGE:
			action = SparkerVisual.Action.CHARGE
			progress = charge_progress()
		State.RECOVER:
			action = SparkerVisual.Action.RECOVER
			progress = clampf(_state_time / tuning.recovery_time, 0.0, 1.0)
		State.HIT:
			action = SparkerVisual.Action.HIT
		State.DEFEATED:
			action = SparkerVisual.Action.DEFEATED
	var move_amount := Vector2(velocity.x, velocity.z).length() / maxf(tuning.move_speed, 0.01) if desired != Vector3.ZERO else 0.0
	_visual.apply_state(action, progress, is_committed(), move_amount)
