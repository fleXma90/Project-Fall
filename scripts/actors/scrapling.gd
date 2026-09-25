class_name Scrapling
extends CharacterBody3D
## M2A-Nahkampfgegner. Kleine lokale Zustandsmaschine: IDLE → CHASE → ATTACK → CHASE, dazu HIT
## (Treffer-Reaktion) und DEFEATED. Timing, Trefferfenster, Sektor und „ein Treffer pro Swing“ kommen
## aus dem wiederverwendeten WeaponController mit eigener WeaponData.
##
## Richtungsregel: Im Windup dreht der Scrapling bis zur Festlegung (commit_fraction) zum Spieler;
## danach, in ACTIVE und in RECOVERY kein Nachdrehen und keine Bewegung.
## Die Bodenprüfung betrifft nur die eigene Laufentscheidung; Knockback und Schwerkraft bleiben echt.

signal defeated(enemy: Scrapling, reason: DefeatReason)

enum State { INACTIVE, IDLE, CHASE, ATTACK, HIT, DEFEATED }
enum DefeatReason { HP, FALL }

@export var tuning: ScraplingTuning
@export_flags_3d_physics var ground_mask: int = 1

var target: PlayerController = null
var state: State = State.IDLE
var hp: float = 80.0
var hit_radius: float = 0.38
var is_defeated: bool = false
var defeat_count: int = 0
var last_defeat_reason: DefeatReason = DefeatReason.HP
var spawn_transform: Transform3D

var _knockback_velocity: Vector3 = Vector3.ZERO
var _knockback_duration: float = 0.0
var _knockback_left: float = 0.0
var _hit_left: float = 0.0
var _frozen: bool = false
var _gravity: float = 18.0
var _collision_layer_default: int = 0
var _visual: ScraplingVisual = null

@onready var visual_root: Node3D = $VisualRoot
@onready var weapon: WeaponController = $WeaponController


func _ready() -> void:
	if tuning == null:
		tuning = ScraplingTuning.new()
	hit_radius = tuning.hit_radius
	spawn_transform = global_transform
	_collision_layer_default = collision_layer
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
	for child in visual_root.get_children():
		if child is ScraplingVisual:
			_visual = child
			break
	weapon.set_socket(_visual.get_weapon_socket() if _visual != null else null)
	hp = tuning.max_hp
	_update_visual_hp()


func _physics_process(delta: float) -> void:
	if state == State.INACTIVE or _frozen:
		return
	var desired := Vector3.ZERO
	match state:
		State.IDLE:
			if _has_target():
				state = State.CHASE
		State.CHASE:
			desired = _chase(delta)
		State.ATTACK:
			_attack(delta)
		State.HIT:
			_hit_left -= delta
			if _hit_left <= 0.0:
				state = State.CHASE if _has_target() else State.IDLE
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


## Richtung im Windup festgelegt (oder bereits ACTIVE/RECOVERY): kein Nachdrehen mehr.
func is_committed() -> bool:
	if state != State.ATTACK:
		return false
	return weapon.phase != WeaponController.Phase.WINDUP or weapon.phase_progress() >= tuning.commit_fraction


func _to_target() -> Vector3:
	var to := target.global_position - global_position
	to.y = 0.0
	return to


func _chase(delta: float) -> Vector3:
	if not _has_target():
		state = State.IDLE
		return Vector3.ZERO
	var to := _to_target()
	var distance := to.length()
	if distance > 0.01:
		_turn_toward(to / distance, tuning.turn_sharpness, delta)
	var facing_ok := rad_to_deg(forward().angle_to(to)) <= tuning.attack_start_max_angle if distance > 0.01 else true
	if distance <= tuning.attack_start_distance and facing_ok and is_on_floor():
		start_attack()
		return Vector3.ZERO
	if distance <= tuning.stop_distance:
		return Vector3.ZERO
	var direction := to / distance
	if not has_ground_ahead(direction):
		return Vector3.ZERO  # Nur die eigene Laufentscheidung; kein Klemmen der Position.
	return direction * tuning.move_speed


func start_attack() -> void:
	state = State.ATTACK
	weapon.start_swing(forward())


func _attack(delta: float) -> void:
	if not is_committed() and _has_target():
		var to := _to_target()
		if to.length() > 0.01:
			_turn_toward(to.normalized(), tuning.windup_turn_sharpness, delta)
		weapon.aim(forward())
	if weapon.tick(delta):
		state = State.CHASE if _has_target() else State.IDLE


func _turn_toward(direction: Vector3, sharpness: float, delta: float) -> void:
	var yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-sharpness * delta))


## Bodenprüfung für die beabsichtigte Laufrichtung (Ray nach unten vor dem Körper).
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
		# In der Luft bleibt der Schwung ballistisch erhalten.
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
	# Ein unterbrochener Angriff erzeugt keine späteren Treffer.
	weapon.cancel()
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
		state = State.HIT
		_hit_left = tuning.hit_stun
	return true


## Von der Arena beim Unterschreiten der Killhöhe aufgerufen. Gefallene Gegner werden nicht weiter simuliert.
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
	state = State.DEFEATED
	weapon.cancel()
	collision_layer = 0
	if _visual != null:
		_visual.play_defeat(reason == DefeatReason.FALL, global_basis.inverse() * _knockback_velocity.normalized())
	defeated.emit(self, reason)
	return true


## Kampf anhalten (z. B. Spielertod): laufenden Angriff abbrechen, nicht mehr verfolgen.
func stop_combat() -> void:
	weapon.cancel()
	target = null
	if state != State.DEFEATED and state != State.INACTIVE:
		state = State.IDLE


func set_active(active: bool) -> void:
	visible = active
	collision_layer = _collision_layer_default if active else 0
	weapon.cancel()
	state = State.IDLE if active else State.INACTIVE


## Sauberer Neustart an einer Startposition: HP, Geschwindigkeit, Zustände, Timer, Trefferlisten.
func reset_to(spawn: Transform3D) -> void:
	spawn_transform = spawn.orthonormalized()
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	_knockback_left = 0.0
	_hit_left = 0.0
	hp = tuning.max_hp
	is_defeated = false
	_frozen = false
	defeat_count = 0
	weapon.cancel()
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
	var action := ScraplingVisual.Action.NONE
	var progress := 0.0
	match state:
		State.ATTACK:
			match weapon.phase:
				WeaponController.Phase.WINDUP:
					action = ScraplingVisual.Action.WINDUP
				WeaponController.Phase.ACTIVE:
					action = ScraplingVisual.Action.ACTIVE
				WeaponController.Phase.RECOVERY:
					action = ScraplingVisual.Action.RECOVERY
			progress = weapon.phase_progress()
		State.HIT:
			action = ScraplingVisual.Action.HIT
			progress = 1.0 - _hit_left / tuning.hit_stun
		State.DEFEATED:
			action = ScraplingVisual.Action.DEFEATED
	var move_amount := Vector2(velocity.x, velocity.z).length() / maxf(tuning.move_speed, 0.01) if desired != Vector3.ZERO else 0.0
	_visual.apply_state(action, progress, move_amount, is_committed())
