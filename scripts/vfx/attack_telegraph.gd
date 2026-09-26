class_name AttackTelegraph
extends MeshInstance3D
## Bodenmarkierung für einen angekündigten gegnerischen Angriff (rein visuell).
##
## Zeigt exakt den Bereich, in dem der Mittelpunkt eines Ziels mit Radius target_radius getroffen würde:
## Abstand ≤ Reichweite + Radius und Winkel ≤ halber Bogen + atan(Radius / Abstand) — dieselbe Regel wie
## WeaponController.is_in_sector. Lesbarkeit nicht nur über Farbe:
## - Windup vor der Festlegung: nur Umriss (Richtung folgt noch),
## - nach der Festlegung: Umriss + Füllung, die bis zum Hieb von innen nach außen wächst,
## - ACTIVE: vollständig gefüllt; RECOVERY: ausgeblendet.

@export var weapon: WeaponController
@export var enemy: Scrapling
@export var target_radius: float = 0.38
@export var ground_offset: float = 0.06
@export var color: Color = Color(1.0, 0.25, 0.15)
@export var outline_width: float = 0.07
@export var rings: int = 8
@export var segments: int = 18

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	mesh = _mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = false
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true


func _process(_delta: float) -> void:
	_mesh.clear_surfaces()
	if weapon == null or weapon.data == null or enemy == null or not enemy.visible:
		return
	var fill := 0.0
	var outline_alpha := 0.0
	match weapon.phase:
		WeaponController.Phase.WINDUP:
			outline_alpha = 0.55
			if enemy.is_committed():
				var start := enemy.tuning.commit_fraction
				fill = clampf((weapon.phase_progress() - start) / maxf(1.0 - start, 0.001), 0.0, 1.0)
				outline_alpha = 0.95
		WeaponController.Phase.ACTIVE:
			fill = 1.0
			outline_alpha = 1.0
		_:
			return
	var origin := enemy.global_position + Vector3.UP * ground_offset
	global_transform = Transform3D(Basis(Vector3.UP, atan2(-weapon.direction.x, -weapon.direction.z)), origin)

	var outer := weapon.effective_range() + target_radius
	var inner := 0.25
	if fill > 0.0:
		_draw_region(inner, lerpf(inner, outer, fill), Color(color.r, color.g, color.b, 0.35 + 0.25 * fill))
	_draw_outline(inner, outer, Color(color.r, color.g * 1.4, color.b, outline_alpha))


## Halber Trefferwinkel (rad) für einen Zielmittelpunkt im Abstand d.
func _half_angle(d: float) -> float:
	return deg_to_rad(weapon.effective_arc()) * 0.5 + atan2(target_radius, d)


func _point(d: float, u: float) -> Vector3:
	# u = -1 (links) … +1 (rechts); vorne ist lokal -Z.
	var angle := _half_angle(d) * u
	return Vector3(sin(angle) * d, 0.0, -cos(angle) * d)


func _draw_region(r0: float, r1: float, fill_color: Color) -> void:
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(fill_color)
	for i in rings:
		var da := lerpf(r0, r1, float(i) / rings)
		var db := lerpf(r0, r1, float(i + 1) / rings)
		for j in segments:
			var ua := lerpf(-1.0, 1.0, float(j) / segments)
			var ub := lerpf(-1.0, 1.0, float(j + 1) / segments)
			var p00 := _point(da, ua)
			var p01 := _point(da, ub)
			var p10 := _point(db, ua)
			var p11 := _point(db, ub)
			_mesh.surface_add_vertex(p00)
			_mesh.surface_add_vertex(p10)
			_mesh.surface_add_vertex(p11)
			_mesh.surface_add_vertex(p00)
			_mesh.surface_add_vertex(p11)
			_mesh.surface_add_vertex(p01)
	_mesh.surface_end()


func _draw_outline(r0: float, r1: float, line_color: Color) -> void:
	var points: Array[Vector3] = []
	for i in rings + 1:  # linke Seite nach außen
		points.append(_point(lerpf(r0, r1, float(i) / rings), -1.0))
	for j in range(1, segments + 1):  # äußerer Bogen links → rechts
		points.append(_point(r1, lerpf(-1.0, 1.0, float(j) / segments)))
	for i in range(rings - 1, -1, -1):  # rechte Seite nach innen
		points.append(_point(lerpf(r0, r1, float(i) / rings), 1.0))
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(line_color)
	for k in points.size() - 1:
		var a := points[k]
		var b := points[k + 1]
		var side := (b - a).cross(Vector3.UP).normalized() * outline_width * 0.5
		_mesh.surface_add_vertex(a - side)
		_mesh.surface_add_vertex(b - side)
		_mesh.surface_add_vertex(b + side)
		_mesh.surface_add_vertex(a - side)
		_mesh.surface_add_vertex(b + side)
		_mesh.surface_add_vertex(a + side)
	_mesh.surface_end()
