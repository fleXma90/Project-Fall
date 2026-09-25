class_name TrainingDummy
extends CharacterBody3D
## Passiver Trainingsdummy: HP, zeitbasierter XZ-Knockback, Schwerkraft, idempotente Niederlage.
## Kennt seine Darstellung nur über DummyVisual unter `VisualRoot`.

signal defeated(dummy: TrainingDummy, reason: DefeatReason)

enum DefeatReason { HP, FALL }

@export var max_hp: float = 100.0
## Radius des Trefferkörpers für die Sektorprüfung der Waffe.
@export var hit_radius: float = 0.4
@export var ground_friction: float = 30.0

var hp: float = 100.0
var is_defeated: bool = false
var defeat_count: int = 0
var last_defeat_reason: DefeatReason = DefeatReason.HP
var spawn_transform: Transform3D

var _knockback_velocity: Vector3 = Vector3.ZERO
var _knockback_duration: float = 0.0
var _knockback_left: float = 0.0
var _frozen: bool = false
var _gravity: float = 18.0
var _collision_layer_default: int = 0
var _visual: DummyVisual = null

@onready var visual_root: Node3D = $VisualRoot


func _ready() -> void:
	spawn_transform = global_transform
	_collision_layer_default = collision_layer
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 18.0))
	for child in visual_root.get_children():
		if child is DummyVisual:
			_visual = child
			break
	hp = max_hp
	_update_visual_hp()


func _physics_process(delta: float) -> void:
	if _frozen:
		return
	var horizontal := Vector2(velocity.x, velocity.z)
	if _knockback_left > 0.0:
		_knockback_left = maxf(_knockback_left - delta, 0.0)
		if is_on_floor():
			# Linear abklingender Impuls über die Knockback-Dauer (kein Teleport, FPS-unabhängig).
			var factor := _knockback_left / _knockback_duration
			horizontal = Vector2(_knockback_velocity.x, _knockback_velocity.z) * factor
		# In der Luft bleibt der horizontale Schwung ballistisch erhalten.
	elif is_on_floor():
		horizontal = horizontal.move_toward(Vector2.ZERO, ground_friction * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()


func receive_hit(hit: HitInfo) -> bool:
	if is_defeated:
		return false
	hp = maxf(hp - hit.damage, 0.0)
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
	return true


## Von der Arena beim Unterschreiten der Killhöhe aufgerufen.
func fall_out() -> bool:
	var first := _defeat(DefeatReason.FALL)
	# Ein gefallener Dummy wird nicht unsichtbar weiter simuliert.
	_frozen = true
	velocity = Vector3.ZERO
	visible = false
	return first


func respawn() -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	_knockback_left = 0.0
	hp = max_hp
	is_defeated = false
	_frozen = false
	visible = true
	collision_layer = _collision_layer_default
	if _visual != null:
		_visual.reset_visual()
	_update_visual_hp()


## Setzt Niederlagenzähler zurück (vollständiger Trainingsreset).
func reset_stats() -> void:
	defeat_count = 0


func _defeat(reason: DefeatReason) -> bool:
	if is_defeated:
		return false
	is_defeated = true
	defeat_count += 1
	last_defeat_reason = reason
	# Kein weiteres Treffen/Blockieren; Boden-Kollision (Maske) bleibt für den Umfall erhalten.
	collision_layer = 0
	if _visual != null:
		_visual.play_defeat(reason == DefeatReason.FALL, global_basis.inverse() * _knockback_velocity.normalized())
	defeated.emit(self, reason)
	return true


func _update_visual_hp() -> void:
	if _visual != null:
		_visual.set_hp(hp, max_hp)
