class_name DescentHatch
extends Node3D
## Luke im Boden der oberen Ebene (regulärer Abstieg). Geschlossen ist sie normaler Boden mit echtem
## Kollider; nach dem Räumen der Ebene öffnet sie sich: Kollider aus, Klappen schwingen nach unten,
## Markierung leuchtet. Kein Interact-Button und kein unsichtbarer Trigger: Der Spieler fällt durch
## das echte Loch. Die umgebende FloorGeometry spart die Lukenfläche aus.

const TILE_SHADER: Shader = preload("res://assets/placeholder/platform_tiles.gdshader")

## Öffnung auf XZ (lokal, zentriert).
@export var size: Vector2 = Vector2(2.0, 2.0)
@export var open_duration: float = 0.45

var is_open: bool = false

var _shape: CollisionShape3D
var _flaps: Array[Node3D] = []
var _marker: Node3D
var _marker_material: StandardMaterial3D
var _glow: OmniLight3D
var _tween: Tween
var _time: float = 0.0


func _ready() -> void:
	var body := StaticBody3D.new()
	body.name = "Lid"
	body.collision_mask = 0
	add_child(body)
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.2, size.y)
	_shape.shape = box
	_shape.position = Vector3.DOWN * 0.1
	body.add_child(_shape)
	var tiles := ShaderMaterial.new()
	tiles.shader = TILE_SHADER
	var underside := StandardMaterial3D.new()
	underside.albedo_color = Color(0.1, 0.1, 0.12)
	for side in [-1.0, 1.0]:
		# Scharnier an der Außenkante; die Klappe liegt zur Mitte hin.
		var pivot := Node3D.new()
		pivot.position = Vector3(side * size.x * 0.5, 0.0, 0.0)
		add_child(pivot)
		var flap := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(size.x * 0.5 - 0.02, 0.06, size.y - 0.02)
		mesh.material = underside
		flap.mesh = mesh
		flap.position = Vector3(-side * size.x * 0.25, -0.03, 0.0)
		pivot.add_child(flap)
		var top := MeshInstance3D.new()
		var top_mesh := BoxMesh.new()
		top_mesh.size = Vector3(size.x * 0.5 - 0.02, 0.02, size.y - 0.02)
		top_mesh.material = tiles
		top.mesh = top_mesh
		top.position = Vector3(-side * size.x * 0.25, 0.012, 0.0)
		pivot.add_child(top)
		_flaps.append(pivot)
	_marker_material = StandardMaterial3D.new()
	_marker_material.albedo_color = Color(1.0, 0.72, 0.3)
	_marker_material.emission_enabled = true
	_marker_material.emission = Color(1.0, 0.55, 0.15)
	_marker_material.emission_energy_multiplier = 2.0
	_marker = Node3D.new()
	add_child(_marker)
	var half := size * 0.5 + Vector2(0.14, 0.14)
	for bar in [[Vector3(0, 0, -half.y), Vector3(half.x * 2.0 + 0.1, 0.05, 0.1)],
			[Vector3(0, 0, half.y), Vector3(half.x * 2.0 + 0.1, 0.05, 0.1)],
			[Vector3(-half.x, 0, 0), Vector3(0.1, 0.05, half.y * 2.0)],
			[Vector3(half.x, 0, 0), Vector3(0.1, 0.05, half.y * 2.0)]]:
		var m := MeshInstance3D.new()
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = bar[1]
		bar_mesh.material = _marker_material
		m.mesh = bar_mesh
		m.position = (bar[0] as Vector3) + Vector3.UP * 0.07
		_marker.add_child(m)
	_glow = OmniLight3D.new()
	_glow.position = Vector3.DOWN * 1.0
	_glow.light_color = Color(1.0, 0.6, 0.25)
	_glow.light_energy = 2.5
	_glow.omni_range = 4.0
	add_child(_glow)
	close()


func _process(delta: float) -> void:
	if not is_open:
		return
	_time += delta
	_marker_material.emission_energy_multiplier = 2.0 + sin(_time * 5.0) * 0.9


## Öffnet die Luke (idempotent). Der Kollider wird zum nächsten Physikschritt deaktiviert.
func open() -> void:
	if is_open:
		return
	is_open = true
	_time = 0.0
	_shape.set_deferred("disabled", true)
	_marker.visible = true
	_glow.visible = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in _flaps.size():
		var side := -1.0 if i == 0 else 1.0
		_tween.tween_property(_flaps[i], "rotation:z", side * deg_to_rad(95.0), open_duration)


## Schließt sofort (Neustart).
func close() -> void:
	is_open = false
	if _tween != null:
		_tween.kill()
		_tween = null
	_shape.set_deferred("disabled", false)
	for flap in _flaps:
		flap.rotation = Vector3.ZERO
	_marker.visible = false
	_glow.visible = false


## Liegt die Weltposition (XZ) über der Öffnung, ggf. mit Toleranz?
func contains_world(world_position: Vector3, margin: float = 0.0) -> bool:
	var local := to_local(world_position)
	return absf(local.x) <= size.x * 0.5 + margin and absf(local.z) <= size.y * 0.5 + margin
