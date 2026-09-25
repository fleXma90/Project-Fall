class_name DepthBackdrop
extends Node3D
## Neutrale Tiefe unter der aktuellen Ebene: additiver Glutschein weit unten und langsam aufsteigende
## Funken. Zeigt keinen konkreten nächsten Floor; keine Kollision. Folgt beim Abstieg der aktiven Ebene.

const GLOW_SHADER: Shader = preload("res://assets/placeholder/depth_glow.gdshader")

## Abstand des Glutscheins unter der Oberkante der aktuellen Ebene.
@export var glow_depth: float = 18.0
@export var glow_size: float = 140.0
## Funkenband: Mitte unter der Oberkante, Ausdehnung.
@export var ember_depth: float = 9.0
@export var ember_extents: Vector3 = Vector3(16.0, 2.0, 13.0)

var _tween: Tween


func _ready() -> void:
	var glow := MeshInstance3D.new()
	glow.name = "Glow"
	var plane := PlaneMesh.new()
	plane.size = Vector2(glow_size, glow_size)
	var glow_material := ShaderMaterial.new()
	glow_material.shader = GLOW_SHADER
	plane.material = glow_material
	glow.mesh = plane
	glow.position = Vector3.DOWN * glow_depth
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glow)

	var embers := CPUParticles3D.new()
	embers.name = "Embers"
	embers.position = Vector3.DOWN * ember_depth
	embers.amount = 70
	embers.lifetime = 5.0
	embers.preprocess = 5.0
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	embers.emission_box_extents = ember_extents
	embers.direction = Vector3.UP
	embers.spread = 20.0
	embers.gravity = Vector3(0.0, 0.1, 0.0)
	embers.initial_velocity_min = 0.3
	embers.initial_velocity_max = 0.8
	embers.scale_amount_min = 0.5
	embers.scale_amount_max = 1.2
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.6, 0.2, 0.0))
	ramp.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	ramp.add_point(0.2, Color(1.0, 0.55, 0.15, 1.0))
	ramp.add_point(0.7, Color(1.0, 0.35, 0.08, 0.8))
	embers.color_ramp = ramp
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var ember_material := StandardMaterial3D.new()
	ember_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ember_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	ember_material.vertex_color_use_as_albedo = true
	quad.material = ember_material
	embers.mesh = quad
	add_child(embers)


## Setzt die Tiefe unter die Ebene mit Oberkante floor_y (duration 0 = sofort).
func follow_floor(floor_y: float, duration: float = 0.0) -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	if duration <= 0.0:
		position.y = floor_y
		return
	_tween = create_tween()
	_tween.tween_property(self, "position:y", floor_y, duration)
