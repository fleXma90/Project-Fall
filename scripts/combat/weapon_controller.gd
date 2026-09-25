class_name WeaponController
extends Node3D
## Timing, swing_id und Trefferabfrage einer Nahkampfwaffe.
##
## Unabhängig vom konkreten Waffenmesh: Die Waffe ist eine separate Szene unter `WeaponMount`.
## Liefert der Visual-Adapter einen Hand-Socket (Placeholder-Marker oder später BoneAttachment3D),
## folgt der Mount ihm rein visuell. Reichweite/Winkel kommen ausschließlich aus `data`.

signal swing_started(swing_id: int, direction: Vector3)
signal hit_landed(target: Node3D, point: Vector3, hit: HitInfo)

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

@export var data: WeaponData
@export var attack_origin: Node3D
@export_flags_3d_physics var hit_mask: int = 4
## Zusätzlicher Suchradius für Zielkörper (die exakte Prüfung nutzt deren hit_radius).
@export var query_margin: float = 0.8

var phase: Phase = Phase.IDLE
var swing_id: int = 0
## Beim Start fixierte Schlagrichtung (XZ, normalisiert).
var direction: Vector3 = Vector3.FORWARD

var _phase_time: float = 0.0
var _hit_ids: Dictionary = {}
var _socket: Node3D = null
var _query_shape := SphereShape3D.new()

@onready var mount: Node3D = $WeaponMount
@onready var _mount_rest: Transform3D = mount.transform


func _process(_delta: float) -> void:
	if _socket != null and is_instance_valid(_socket):
		mount.global_transform = _socket.global_transform


## Visual-Adapter liefert optional einen Hand-Socket. null = Ruhelage des Mounts.
func set_socket(socket: Node3D) -> void:
	_socket = socket
	if _socket == null:
		mount.transform = _mount_rest


func is_busy() -> bool:
	return phase != Phase.IDLE


func start_swing(attack_direction: Vector3) -> void:
	var flat := Vector3(attack_direction.x, 0.0, attack_direction.z)
	direction = flat.normalized() if flat.length_squared() > 0.0001 else Vector3.FORWARD
	swing_id += 1
	phase = Phase.WINDUP
	_phase_time = 0.0
	_hit_ids.clear()
	swing_started.emit(swing_id, direction)


func cancel() -> void:
	phase = Phase.IDLE
	_phase_time = 0.0


## Fortschritt der aktuellen Phase 0..1.
func phase_progress() -> float:
	var duration := _phase_duration(phase)
	return clampf(_phase_time / duration, 0.0, 1.0) if duration > 0.0 else 0.0


## Einen Physiktick simulieren. Gibt true zurück, wenn der Swing beendet ist.
func tick(delta: float) -> bool:
	if phase == Phase.IDLE:
		return true
	_phase_time += delta
	while _phase_time >= _phase_duration(phase):
		_phase_time -= _phase_duration(phase)
		if phase == Phase.ACTIVE:
			_query_hits()  # Aktives Fenster wird auch bei großen Ticks mindestens einmal geprüft.
		phase = _next_phase(phase)
		if phase == Phase.IDLE:
			_phase_time = 0.0
			return true
	if phase == Phase.ACTIVE:
		_query_hits()
	return false


## Reine Geometrieregel: liegt ein Zielkörper im begrenzten Schlagsektor?
static func is_in_sector(origin: Vector3, attack_dir: Vector3, target_pos: Vector3, target_radius: float,
		attack_range: float, arc_degrees: float, max_height: float) -> bool:
	var to_target := target_pos - origin
	if absf(to_target.y) > max_height:
		return false
	to_target.y = 0.0
	var distance := to_target.length()
	if distance - target_radius > attack_range:
		return false
	if distance < 0.001:
		return true
	var flat_dir := Vector3(attack_dir.x, 0.0, attack_dir.z).normalized()
	var half_arc := deg_to_rad(arc_degrees) * 0.5 + atan2(target_radius, distance)
	return flat_dir.angle_to(to_target / distance) <= half_arc


func _query_hits() -> void:
	if data == null or attack_origin == null:
		return
	var origin := attack_origin.global_position
	_query_shape.radius = data.attack_range + query_margin
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _query_shape
	params.transform = Transform3D(Basis.IDENTITY, origin)
	params.collision_mask = hit_mask
	params.collide_with_bodies = true
	params.collide_with_areas = false
	var owner_body := get_parent() as CollisionObject3D
	if owner_body != null:
		params.exclude = [owner_body.get_rid()]
	var results := get_world_3d().direct_space_state.intersect_shape(params, 32)
	for result in results:
		var target := result.get("collider") as Node3D
		if target == null or not target.has_method("receive_hit"):
			continue
		var id := target.get_instance_id()
		if _hit_ids.has(id):
			continue
		var radius_value: Variant = target.get("hit_radius")
		var target_radius: float = radius_value if radius_value is float else 0.4
		if not is_in_sector(origin, direction, target.global_position, target_radius,
				data.attack_range, data.arc_degrees, data.max_height_difference):
			continue
		_hit_ids[id] = true
		var hit := _make_hit(origin, target.global_position)
		if target.call("receive_hit", hit):
			var toward_origin := origin - target.global_position
			toward_origin.y = 0.0
			var point := target.global_position + Vector3.UP * 0.8 + toward_origin.normalized() * target_radius
			hit_landed.emit(target, point, hit)


func _make_hit(origin: Vector3, target_pos: Vector3) -> HitInfo:
	var radial := target_pos - origin
	radial.y = 0.0
	# Knockback: Mischung aus Schlagrichtung und radialem Wegstoßen, beides auf XZ.
	var push := direction
	if radial.length_squared() > 0.0025:
		push = (radial.normalized() + direction).normalized()
	var hit := HitInfo.new()
	hit.swing_id = swing_id
	hit.damage = data.damage
	hit.knockback_velocity = push * data.knockback_speed
	hit.knockback_duration = data.knockback_duration
	hit.attack_direction = direction
	hit.source = get_parent() as Node3D
	return hit


func _phase_duration(p: Phase) -> float:
	match p:
		Phase.WINDUP:
			return data.windup
		Phase.ACTIVE:
			return data.active
		Phase.RECOVERY:
			return data.recovery
	return INF


func _next_phase(p: Phase) -> Phase:
	match p:
		Phase.WINDUP:
			return Phase.ACTIVE
		Phase.ACTIVE:
			return Phase.RECOVERY
	return Phase.IDLE
