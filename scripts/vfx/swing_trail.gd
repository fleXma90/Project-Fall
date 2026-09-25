class_name SwingTrail
extends MeshInstance3D
## Breiter Hammer-Schlagbogen als Godot-seitige Trail-Geometrie.
## Liest Timing, Richtung, Reichweite und Winkel vom WeaponController; hat selbst keine Gameplaywirkung.
## Zeichnet den tatsächlichen Treffersektor (rechts → links), damit Visual und Hitfenster übereinstimmen.

@export var weapon: WeaponController
@export var segments: int = 22
@export var ribbon_width: float = 0.85
@export var height_start: float = 1.5
@export var height_end: float = 0.25
@export var color: Color = Color(1.0, 0.55, 0.15)
@export var fade_time: float = 0.14

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	mesh = _mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true


func _process(_delta: float) -> void:
	_mesh.clear_surfaces()
	if weapon == null or weapon.data == null:
		return
	var reveal := 0.0
	var alpha := 0.0
	match weapon.phase:
		WeaponController.Phase.ACTIVE:
			reveal = pow(weapon.phase_progress(), 0.8)
			alpha = 0.9
		WeaponController.Phase.RECOVERY:
			var faded := weapon.phase_progress() * weapon.data.recovery / fade_time
			reveal = 1.0
			alpha = 0.9 * (1.0 - clampf(faded, 0.0, 1.0))
	if alpha <= 0.01 or reveal <= 0.01:
		return

	# Weltfest in der fixierten Schlagrichtung am aktuellen Player-Ursprung.
	var owner_node := weapon.get_parent() as Node3D
	global_transform = Transform3D(Basis(Vector3.UP, atan2(-weapon.direction.x, -weapon.direction.z)),
			owner_node.global_position if owner_node != null else weapon.global_position)

	var half := weapon.data.arc_degrees * 0.5
	var outer := weapon.data.attack_range
	var inner := maxf(outer - ribbon_width, 0.2)
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in segments + 1:
		var u := float(i) / float(segments) * reveal
		var angle := deg_to_rad(half - weapon.data.arc_degrees * u)  # rechts (+) → links (-)
		var dir := Vector3(sin(angle), 0.0, -cos(angle))
		var height := lerpf(height_start, height_end, u)
		# Neuester Teil des Bogens am hellsten.
		var head := 1.0 - (reveal - u) / maxf(reveal, 0.001)
		var a := alpha * (0.25 + 0.75 * head)
		_mesh.surface_set_color(Color(color.r, color.g, color.b, a * 0.35))
		_mesh.surface_add_vertex(dir * inner + Vector3.UP * (height - 0.1))
		_mesh.surface_set_color(Color(color.r, color.g * 1.2, color.b, a))
		_mesh.surface_add_vertex(dir * outer + Vector3.UP * (height + 0.05))
	_mesh.surface_end()
