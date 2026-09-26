class_name FloorGeometry
extends StaticBody3D
## Begehbare Ebene aus achsparallelen Rechtecken (lokales XZ, Oberkante bei y = 0 dieses Knotens).
## Echte Löcher (`holes`) und die Luken-Aussparung (`cutouts`) werden aus den Rechtecken herausgeschnitten:
## Dort gibt es weder Kollider noch Mesh. Kantenleisten nur an tatsächlichen Außen- und Lochkanten.
## Die Aussparung zählt für `contains()` weiter als Boden, weil die geschlossene Luke sie trägt.

const TILE_SHADER: Shader = preload("res://assets/placeholder/platform_tiles.gdshader")

@export var rects: Array[Rect2] = []
@export var holes: Array[Rect2] = []
@export var cutouts: Array[Rect2] = []
@export var thickness: float = 1.4
## Warmes Licht unter der Ebene (wie UnderGlow unter Ebene 1); wird mit der Ebene aus-/eingeblendet.
@export var under_glow: bool = false

var _built: bool = false
var _layer_default: int = 1
## Tatsächlich gebaute Teilflächen (Rechtecke minus Löcher und Aussparungen).
var _pieces: Array[Rect2] = []


func _ready() -> void:
	_layer_default = collision_layer
	build()


## Ebene ein-/ausblenden inklusive Kollision aller zugehörigen Körper (auch Lukendeckel).
func set_enabled(enabled: bool) -> void:
	visible = enabled
	collision_layer = _layer_default if enabled else 0
	for node in find_children("*", "StaticBody3D", true, false):
		var body := node as StaticBody3D
		if not body.has_meta("layer_default"):
			body.set_meta("layer_default", body.collision_layer)
		body.collision_layer = int(body.get_meta("layer_default")) if enabled else 0


## Liegt ein lokaler XZ-Punkt auf begehbarem Boden?
func contains(local_xz: Vector2) -> bool:
	var inside := false
	for r in rects:
		if r.has_point(local_xz):
			inside = true
			break
	if not inside:
		return false
	for h in holes:
		if h.has_point(local_xz):
			return false
	return true


## Sicherer Punkt: Boden ringsum im Abstand margin (keine Kante, kein Loch in der Nähe).
func is_safe_point(local_xz: Vector2, margin: float) -> bool:
	if not contains(local_xz):
		return false
	for i in 8:
		var angle := TAU * i / 8.0
		if not contains(local_xz + Vector2(cos(angle), sin(angle)) * margin):
			return false
	return true


func pieces() -> Array[Rect2]:
	return _pieces


func build() -> void:
	if _built:
		return
	_built = true
	var cuts: Array[Rect2] = []
	cuts.append_array(holes)
	cuts.append_array(cutouts)
	_pieces = _cut(rects, cuts)
	var slab_material := StandardMaterial3D.new()
	slab_material.albedo_color = Color(0.1, 0.1, 0.12)
	slab_material.roughness = 0.9
	var tile_material := ShaderMaterial.new()
	tile_material.shader = TILE_SHADER
	var rim_material := StandardMaterial3D.new()
	rim_material.albedo_color = Color(0.62, 0.55, 0.45)
	rim_material.metallic = 0.3
	rim_material.roughness = 0.5
	rim_material.emission_enabled = true
	rim_material.emission = Color(0.35, 0.16, 0.06)
	rim_material.emission_energy_multiplier = 0.6
	for r in _pieces:
		var center := Vector3(r.position.x + r.size.x * 0.5, 0.0, r.position.y + r.size.y * 0.5)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(r.size.x, thickness, r.size.y)
		shape.shape = box
		shape.position = center + Vector3.DOWN * thickness * 0.5
		add_child(shape)
		_add_box(Vector3(r.size.x, thickness, r.size.y), center + Vector3.DOWN * thickness * 0.5, slab_material)
		_add_box(Vector3(r.size.x, 0.04, r.size.y), center + Vector3.UP * 0.012, tile_material)
	for segment in _exposed_edges():
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		var inward: Vector2 = segment[2]
		var length := a.distance_to(b)
		var mid := (a + b) * 0.5 + inward * 0.09
		var size := Vector3(length, 0.03, 0.18) if absf(a.y - b.y) < 0.001 else Vector3(0.18, 0.03, length)
		_add_box(size, Vector3(mid.x, 0.04, mid.y), rim_material)
	if under_glow:
		var glow := OmniLight3D.new()
		glow.name = "UnderGlow"
		glow.position = Vector3.DOWN * 4.5
		glow.light_color = Color(1, 0.45, 0.15)
		glow.light_energy = 3.0
		glow.omni_range = 16.0
		add_child(glow)


## Rechtecke minus Ausschnitte als überlappungsfreie Teilrechtecke (je Ausschnitt bis zu 4 Teile).
static func _cut(source: Array[Rect2], cuts: Array[Rect2]) -> Array[Rect2]:
	var result: Array[Rect2] = source.duplicate()
	for cut in cuts:
		var next: Array[Rect2] = []
		for r in result:
			next.append_array(_subtract(r, cut))
		result = next
	return result


static func _subtract(r: Rect2, cut: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var i := r.intersection(cut)
	if not i.has_area():
		out.append(r)
		return out
	if i.position.y > r.position.y:
		out.append(Rect2(r.position.x, r.position.y, r.size.x, i.position.y - r.position.y))
	if i.end.y < r.end.y:
		out.append(Rect2(r.position.x, i.end.y, r.size.x, r.end.y - i.end.y))
	if i.position.x > r.position.x:
		out.append(Rect2(r.position.x, i.position.y, i.position.x - r.position.x, i.size.y))
	if i.end.x < r.end.x:
		out.append(Rect2(i.end.x, i.position.y, r.end.x - i.end.x, i.size.y))
	return out


func _solid(local_xz: Vector2) -> bool:
	for r in _pieces:
		if r.has_point(local_xz):
			return true
	return false


func _add_box(size: Vector3, pos: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	add_child(mesh_instance)


## Kantenabschnitte der Teilflächen, hinter denen keine andere Teilfläche liegt: [start, ende, nach innen].
func _exposed_edges() -> Array:
	var result: Array = []
	const STEP := 0.25
	for r in _pieces:
		var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		var inwards := [Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0)]
		for side in 4:
			var a: Vector2 = corners[side]
			var b: Vector2 = corners[(side + 1) % 4]
			var inward: Vector2 = inwards[side]
			var length := a.distance_to(b)
			var steps := maxi(roundi(length / STEP), 1)
			var run_start := -1
			for i in steps + 1:
				var exposed := false
				if i < steps:
					var p := a.lerp(b, (i + 0.5) / steps) - inward * 0.05
					exposed = not _solid(p)
				if exposed and run_start < 0:
					run_start = i
				elif not exposed and run_start >= 0:
					result.append([a.lerp(b, float(run_start) / steps), a.lerp(b, float(i) / steps), inward])
					run_start = -1
	return result
