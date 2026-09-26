class_name LevelUpBurst
extends Node3D
## Placeholder-Effekt beim Level-Up (M3A): goldener, sich ausweitender Bodenring und aufsteigende Funken
## am Spieler. Reine Darstellung, keine Gameplaywirkung; entfernt sich selbst.

const DURATION: float = 0.9

var follow: Node3D = null
var _time: float = 0.0
var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D


func _ready() -> void:
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.68
	torus.rings = 32
	torus.ring_segments = 6
	_ring_material = StandardMaterial3D.new()
	_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_material.albedo_color = Color(1.0, 0.85, 0.35, 0.9)
	_ring_material.emission_enabled = true
	_ring_material.emission = Color(1.0, 0.75, 0.25)
	_ring_material.emission_energy_multiplier = 2.5
	torus.material = _ring_material
	_ring.mesh = torus
	_ring.position = Vector3.UP * 0.1
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)

	var sparks := CPUParticles3D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.85
	sparks.amount = 28
	sparks.lifetime = 0.8
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	sparks.emission_ring_axis = Vector3.UP
	sparks.emission_ring_radius = 0.6
	sparks.emission_ring_inner_radius = 0.3
	sparks.emission_ring_height = 0.1
	sparks.direction = Vector3.UP
	sparks.spread = 15.0
	sparks.gravity = Vector3.ZERO
	sparks.initial_velocity_min = 1.8
	sparks.initial_velocity_max = 3.2
	sparks.scale_amount_min = 0.6
	sparks.scale_amount_max = 1.1
	var quad := QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spark_material.albedo_color = Color(1.0, 0.9, 0.45)
	spark_material.emission_enabled = true
	spark_material.emission = Color(1.0, 0.8, 0.3)
	quad.material = spark_material
	sparks.mesh = quad
	sparks.position = Vector3.UP * 0.2
	add_child(sparks)
	sparks.emitting = true


func _process(delta: float) -> void:
	_time += delta
	if follow != null and is_instance_valid(follow):
		global_position = follow.global_position
	var u := clampf(_time / DURATION, 0.0, 1.0)
	_ring.scale = Vector3.ONE * (0.6 + 1.4 * u)
	_ring_material.albedo_color.a = 0.9 * (1.0 - u)
	if _time >= DURATION:
		queue_free()
