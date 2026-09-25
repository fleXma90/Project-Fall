class_name SparkBolt
extends Node3D
## Energiebolzen des Funkenwerfers: gerade Flugbahn ohne Gravitation, Richtung beim Abschuss fixiert,
## kein Homing. Alle Werte werden beim Abschuss kopiert – der Bolzen hängt nicht vom Schützen ab.
##
## Kontaktregeln: Pro Tick wird der gesamte zurückgelegte Weg per Kugel-Sweep geprüft (kein Durchspringen),
## zusätzlich eine Startüberlappung. Kollidiert nur mit Spieler und Weltgeometrie (kein Friendly Fire).
## Der erste Kontakt verbraucht den Bolzen – auch wenn der Spieler ihn per Dodge-iFrames abwehrt.

signal player_contact(bolt: SparkBolt, applied: bool)
signal spent(bolt: SparkBolt, reason: String)

## Welt (1) + Spieler (2); Gegner (3) werden nicht getroffen.
@export_flags_3d_physics var collision_mask: int = 3

var direction: Vector3 = Vector3.FORWARD
var speed: float = 6.0
var damage: float = 10.0
var radius: float = 0.13
var lifetime: float = 2.5
var knockback_speed: float = 3.0
var knockback_duration: float = 0.15
var shooter_name: String = ""
var age: float = 0.0
var is_spent: bool = false

var _shape := SphereShape3D.new()


## Werte beim Abschuss übernehmen (Kopie, keine Referenz auf den Schützen).
func setup(origin: Vector3, flight_direction: Vector3, tuning: SparkerTuning, shooter: String) -> void:
	direction = Vector3(flight_direction.x, 0.0, flight_direction.z).normalized()
	speed = tuning.projectile_speed
	damage = tuning.projectile_damage
	radius = tuning.projectile_radius
	lifetime = tuning.projectile_lifetime
	knockback_speed = tuning.projectile_knockback_speed
	knockback_duration = tuning.projectile_knockback_duration
	shooter_name = shooter
	_shape.radius = radius
	position = origin
	basis = Basis.looking_at(direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	if is_spent:
		return
	age += delta
	if age >= lifetime:
		_spend("lifetime")
		return
	var space := get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _shape
	params.collision_mask = collision_mask
	params.collide_with_areas = false
	params.transform = Transform3D(Basis.IDENTITY, global_position)
	# Startüberlappung (z. B. Abschuss aus nächster Nähe).
	var overlap := space.intersect_shape(params, 4)
	if not overlap.is_empty():
		_contact(overlap)
		return
	var motion := direction * speed * delta
	params.motion = motion
	var fractions := space.cast_motion(params)
	if fractions[1] < 1.0:
		# Kontakt entlang des Weges: bis zum Kontaktpunkt bewegen und dort auswerten.
		global_position += motion * fractions[1]
		params.motion = Vector3.ZERO
		params.transform = Transform3D(Basis.IDENTITY, global_position)
		_contact(space.intersect_shape(params, 4))
		return
	global_position += motion


func _contact(results: Array[Dictionary]) -> void:
	var target: Node = null
	for result in results:
		var collider := result.get("collider") as Node
		if collider != null and collider.has_method("receive_hit"):
			target = collider
			break
	if target == null:
		_spend("world")
		return
	var hit := HitInfo.new()
	hit.damage = damage
	hit.knockback_velocity = direction * knockback_speed
	hit.knockback_duration = knockback_duration
	hit.attack_direction = direction
	hit.source = self
	hit.source_name = "Funkenbolzen (%s)" % shooter_name
	var applied: bool = target.call("receive_hit", hit)
	player_contact.emit(self, applied)
	_spend("player")


func _spend(reason: String) -> void:
	if is_spent:
		return
	is_spent = true
	spent.emit(self, reason)
	queue_free()
