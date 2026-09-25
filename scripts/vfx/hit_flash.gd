class_name HitFlash
extends RefCounted
## Kurzer Treffer-Aufblitzer über ein eigenes Overlay-Material auf allen Meshes einer Darstellung.
## Hängt nicht an konkreten Mesh- oder Materialnamen.

var duration: float = 0.12
var _material := StandardMaterial3D.new()
var _left: float = 0.0
var _max_alpha: float = 0.85


func _init(root: Node, color: Color = Color.WHITE, max_alpha: float = 0.85) -> void:
	_max_alpha = max_alpha
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(color.r, color.g, color.b, 0.0)
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_overlay = _material


func trigger() -> void:
	_left = duration


func reset() -> void:
	_left = 0.0
	_material.albedo_color.a = 0.0


func update(delta: float) -> void:
	if _left > 0.0:
		_left = maxf(_left - delta, 0.0)
	_material.albedo_color.a = _max_alpha * (_left / duration)
