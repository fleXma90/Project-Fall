class_name AimIndicator
extends MeshInstance3D
## Dezente kurze Richtungslinie des Funkenwerfers auf dem Boden (rein visuell, kein Flächensektor).
## Während des Aufladens dünn und blass (Richtung folgt noch), ab der Festlegung breiter und kräftig.

@export var sparker: Sparker
@export var length: float = 2.2
@export var ground_offset: float = 0.05

var _material := StandardMaterial3D.new()
var _box := BoxMesh.new()


func _ready() -> void:
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_box.material = _material
	_box.size = Vector3(1.0, 0.01, length)
	mesh = _box
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true
	visible = false


func _process(_delta: float) -> void:
	if sparker == null or not sparker.visible or sparker.state != Sparker.State.CHARGE:
		visible = false
		return
	visible = true
	var committed := sparker.is_committed()
	var width := 0.12 if committed else 0.05
	_material.albedo_color = Color(1.0, 0.8, 0.3, 0.85 if committed else 0.3)
	var dir := sparker.fire_direction
	var start := sparker.global_position + dir * (0.6 + length * 0.5) + Vector3.UP * ground_offset
	global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP) * Basis.from_scale(Vector3(width, 1.0, 1.0)), start)
