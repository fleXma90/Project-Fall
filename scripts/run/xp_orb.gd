class_name XpOrb
extends Node3D
## Sichtbarer XP-Orb (M3A, Nutzerwunsch): springt beim Besiegen aus dem Gegner, schwebt über dem Boden und
## wird erst in der Nähe des Spielers magnetisch angezogen. XP gibt es beim Einsammeln, nicht beim Kill.
## Keine Physik/Kollision; reine Positionslogik im Physiktakt (pausierbar, bildratenunabhängig).

signal collected(orb: XpOrb)

enum State { POP, REST, ATTRACT, DONE }

const POP_TIME: float = 0.35
const HOVER: float = 0.35

@export var magnet_radius: float = 2.2
@export var collect_radius: float = 0.55
@export var attract_start_speed: float = 2.0
@export var attract_acceleration: float = 22.0
@export var attract_max_speed: float = 16.0

var value: int = 10
var state: State = State.POP
var target: PlayerController = null
## Zu welcher Ebene der Orb gehört (für Verfall/Gutschrift beim Verlassen).
var floor_index: int = 1

var _start: Vector3
var _rest: Vector3
var _time: float = 0.0
var _speed: float = 0.0
var _vacuum: bool = false
var _mesh: MeshInstance3D


func setup(start: Vector3, rest: Vector3, xp_value: int, player: PlayerController, floor_number: int) -> void:
	_start = start
	_rest = rest + Vector3.UP * HOVER
	value = xp_value
	target = player
	floor_index = floor_number
	position = start


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.26
	sphere.radial_segments = 12
	sphere.rings = 6
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 1.0, 0.7)
	material.emission_enabled = true
	material.emission = Color(0.25, 1.0, 0.55)
	material.emission_energy_multiplier = 2.2
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	_mesh.mesh = sphere
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)


## Sofort anziehen, unabhängig vom Abstand (Ebene geräumt).
func vacuum() -> void:
	_vacuum = true
	if state == State.REST:
		_begin_attract()


func is_attracting() -> bool:
	return state == State.ATTRACT


func _physics_process(delta: float) -> void:
	_time += delta
	match state:
		State.POP:
			var u := clampf(_time / POP_TIME, 0.0, 1.0)
			global_position = _start.lerp(_rest, u) + Vector3.UP * sin(u * PI) * 0.7
			if u >= 1.0:
				state = State.REST
				if _vacuum:
					_begin_attract()
		State.REST:
			global_position = _rest + Vector3.UP * sin(_time * 4.0) * 0.06
			if _player_available():
				var to := target.global_position - global_position
				if Vector2(to.x, to.z).length() <= magnet_radius and absf(to.y) < 2.5:
					_begin_attract()
		State.ATTRACT:
			if not _player_available():
				return
			var goal := target.global_position + Vector3.UP * 0.8
			var to_goal := goal - global_position
			var accel := attract_acceleration * (3.0 if _vacuum else 1.0)
			_speed = minf(_speed + accel * delta, attract_max_speed * (1.5 if _vacuum else 1.0))
			var step := _speed * delta
			if to_goal.length() <= maxf(collect_radius, step):
				state = State.DONE
				collected.emit(self)
				queue_free()
				return
			global_position += to_goal.normalized() * step
	if _mesh != null:
		_mesh.scale = Vector3.ONE * (1.0 + sin(_time * 7.0) * 0.12)


func _begin_attract() -> void:
	state = State.ATTRACT
	_speed = attract_start_speed


func _player_available() -> bool:
	return target != null and is_instance_valid(target) and target.is_targetable()
