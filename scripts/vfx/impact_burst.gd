extends Node3D
## Kurzer Treffer-Impact: Funken + Flash. Entfernt sich selbst.

@export var lifetime: float = 0.6

@onready var _sparks: CPUParticles3D = $Sparks
@onready var _flash: MeshInstance3D = $Flash


func _ready() -> void:
	_sparks.emitting = true
	var material := _flash.material_override as StandardMaterial3D
	if material != null:
		material = material.duplicate() as StandardMaterial3D
		_flash.material_override = material
	_flash.scale = Vector3.ONE * 0.3
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_flash, "scale", Vector3.ONE * 1.4, 0.12).set_ease(Tween.EASE_OUT)
	if material != null:
		tween.tween_property(material, "albedo_color:a", 0.0, 0.14)
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)
