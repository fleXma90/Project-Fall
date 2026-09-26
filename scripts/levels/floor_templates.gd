class_name FloorTemplates
extends RefCounted
## Katalog der handgebauten Floor-Vorlagen (M3B) und Auswahl pro Run. Kein Generator: Zufällig ist nur,
## welche geprüfte Vorlage Ebene 1 bzw. Ebene 2 eines Abstiegs wird. Werte: docs/FLOOR_TEMPLATES.md.

## Feste M2D-Geometrie als Testvorlagen (Regressionstests M2D/M3A), nie im Zufallspool.
const FIXTURE_UPPER: StringName = &"fixture_m2d_upper"
const FIXTURE_RING: StringName = &"fixture_m2d_ring"

static var _pool: Array[FloorTemplate] = []
static var _fixtures: Array[FloorTemplate] = []


## Die sechs spielbaren Vorlagen.
static func all() -> Array[FloorTemplate]:
	if _pool.is_empty():
		_pool = [_open_forge(), _broken_corner(), _central_pit(), _twin_plates(), _cross_forge(), _shattered_ring()]
	return _pool


static func fixtures() -> Array[FloorTemplate]:
	if _fixtures.is_empty():
		_fixtures = [_fixture_upper(), _fixture_ring()]
	return _fixtures


static func by_id(id: StringName) -> FloorTemplate:
	for t in all() + fixtures():
		if t.id == id:
			return t
	return null


static func candidates(floor_index: int) -> Array[FloorTemplate]:
	var result: Array[FloorTemplate] = []
	for t in all():
		if t.allowed_on_floor(floor_index):
			result.append(t)
	return result


## Zwei unterschiedliche Vorlagen für Ebene 1 (LOW/MEDIUM, mit Luke) und Ebene 2 (MEDIUM/HIGH).
## forced (Test-/Debughilfe) überspringt die Zufallswahl.
static func select_pair(rng: RandomNumberGenerator, forced: Array[StringName] = []) -> Array[FloorTemplate]:
	var pair: Array[FloorTemplate] = []
	if forced.size() >= 2:
		pair.assign([by_id(forced[0]), by_id(forced[1])])
		return pair
	var first_pool := candidates(1)
	var first := first_pool[rng.randi_range(0, first_pool.size() - 1)]
	var second_pool: Array[FloorTemplate] = []
	for t in candidates(2):
		if t != first:
			second_pool.append(t)
	var second := second_pool[rng.randi_range(0, second_pool.size() - 1)]
	pair.assign([first, second])
	return pair


# --- Vorlagen ----------------------------------------------------------------------------

static func _make(id: StringName, display_name: String, risk: FloorTemplate.EdgeRisk, tags: PackedStringArray) -> FloorTemplate:
	var t := FloorTemplate.new()
	t.id = id
	t.display_name = display_name
	t.edge_risk = risk
	t.tags = tags
	return t


## T1: große zusammenhängende Fläche, unregelmäßige Außenkontur, keine Innenlöcher.
static func _open_forge() -> FloorTemplate:
	var t := _make(&"open_forge", "Open Forge", FloorTemplate.EdgeRisk.LOW, ["OPEN"])
	t.rects = [Rect2(-7, -5.5, 14, 11), Rect2(-4, -7, 7, 1.5), Rect2(-8.5, -2.5, 1.5, 5), Rect2(7, -3.5, 1.5, 5), Rect2(-2.5, 5.5, 6, 1.5)]
	t.holes = [Rect2(5.5, 4, 1.5, 1.5), Rect2(-7, -5.5, 1.5, 1.5)]
	t.player_start = Vector2(0, 1)
	t.melee_slots = [Vector2(4.5, -3), Vector2(-4, -2.8), Vector2(5, 2.5), Vector2(-4.5, 2.8)]
	t.ranged_slots = [Vector2(1, -5.4), Vector2(-6.3, -0.5)]
	t.landing_slots = [Vector2(1.5, 4), Vector2(-1.0, -1.8), Vector2(-1.3, 4.5)]
	t.has_hatch = true
	t.hatch_slot = Vector2(2.0, -2.0)
	return t


## T2: große Fläche mit deutlich fehlender Ecke und zwei kleinen Einbuchtungen.
static func _broken_corner() -> FloorTemplate:
	var t := _make(&"broken_corner", "Broken Corner", FloorTemplate.EdgeRisk.LOW, ["ASYMMETRIC"])
	t.rects = [Rect2(-8, -6, 16, 12)]
	t.holes = [Rect2(3, -6, 5, 4.5), Rect2(-8, 1, 1.5, 2.5), Rect2(-2, 4.5, 2.5, 1.5)]
	t.player_start = Vector2(0.5, 1.5)
	t.melee_slots = [Vector2(4.5, 2.8), Vector2(-4.5, 1.5), Vector2(-3.8, -2.2), Vector2(1.2, -4)]
	t.ranged_slots = [Vector2(-5.8, -2.6), Vector2(-1.5, -4.5)]
	t.landing_slots = [Vector2(1.8, 4.2), Vector2(6, -0.2)]
	t.has_hatch = true
	t.hatch_slot = Vector2(-0.8, -1.8)
	return t


## T3: große Fläche mit klarem zentralem Loch (4 × 3.5 m).
static func _central_pit() -> FloorTemplate:
	var t := _make(&"central_pit", "Central Pit", FloorTemplate.EdgeRisk.MEDIUM, ["CENTRAL_HOLE"])
	t.rects = [Rect2(-8, -6.5, 16, 13)]
	t.holes = [Rect2(-2, -2, 4, 3.5), Rect2(6, -6.5, 2, 2), Rect2(-8, 4.5, 2.5, 2)]
	t.player_start = Vector2(1, 3.8)
	t.melee_slots = [Vector2(4, -3.5), Vector2(5.5, 1.5), Vector2(-5.5, 1), Vector2(-4.5, -1)]
	t.ranged_slots = [Vector2(2.5, -5), Vector2(5.5, -1.0)]
	t.landing_slots = [Vector2(3, 4.5), Vector2(-2.3, -4.4)]
	t.has_hatch = true
	t.hatch_slot = Vector2(-3.5, 3.5)
	return t


## T4: zwei Platten, 5 m breite Verbindung (kein Steg).
static func _twin_plates() -> FloorTemplate:
	var t := _make(&"twin_plates", "Twin Plates", FloorTemplate.EdgeRisk.MEDIUM, ["SPLIT", "ASYMMETRIC"])
	t.rects = [Rect2(-9, -6, 8, 10), Rect2(1, -4, 8, 10), Rect2(-1, -2.5, 2, 5)]
	t.player_start = Vector2(-3.2, 1.2)
	t.melee_slots = [Vector2(2.5, -1.8), Vector2(2.5, 1.5), Vector2(-7, -1.5)]
	t.ranged_slots = [Vector2(4.5, 0.5), Vector2(-6.5, -4.5)]
	t.landing_slots = [Vector2(-5, 2.6), Vector2(6.5, 4), Vector2(-3, -4.5)]
	t.has_hatch = true
	t.hatch_slot = Vector2(-3.5, -2.3)
	return t


## T5: breites Kreuz mit großer Mitte (asymmetrisch gekappte Ecken, Arme 7–8 m breit).
static func _cross_forge() -> FloorTemplate:
	var t := _make(&"cross_forge", "Cross Forge", FloorTemplate.EdgeRisk.MEDIUM, ["CROSS"])
	t.rects = [Rect2(-8, -8, 16, 16)]
	t.holes = [Rect2(-8, -8, 4.5, 3.5), Rect2(4.5, -8, 3.5, 4), Rect2(-8, 4, 3.5, 4), Rect2(4, 4.5, 4, 3.5)]
	t.player_start = Vector2(0, 1.5)
	t.melee_slots = [Vector2(-5.5, 0), Vector2(5.5, -1), Vector2(-2, -5.2), Vector2(-1, 5.8)]
	t.ranged_slots = [Vector2(0, -6.5), Vector2(6.3, 1)]
	t.landing_slots = [Vector2(-2.5, -1.8), Vector2(3, 3), Vector2(-3.2, 3.2)]
	t.has_hatch = true
	t.hatch_slot = Vector2(2.8, -2.2)
	return t


## T6: asymmetrischer Ring um großen Schacht, Randkerben; Laufwege ≥ 4 m. Nur Ebene 2 (keine Luke).
static func _shattered_ring() -> FloorTemplate:
	var t := _make(&"shattered_ring", "Shattered Ring", FloorTemplate.EdgeRisk.HIGH, ["CENTRAL_HOLE", "ASYMMETRIC"])
	t.rects = [Rect2(-8.5, -7, 17, 14)]
	t.holes = [Rect2(-3, -3, 5, 4), Rect2(2, -2, 1.5, 2.5), Rect2(-8.5, -7, 2.5, 2), Rect2(6, 5, 2.5, 2), Rect2(-8.5, 3, 1.5, 2.5)]
	t.player_start = Vector2(-1, 4.8)
	t.melee_slots = [Vector2(-6.2, 0.8), Vector2(6.3, -1), Vector2(3, 4.5), Vector2(-1.5, -4.8)]
	t.ranged_slots = [Vector2(1.5, -5.2), Vector2(5.2, 3.8)]
	t.landing_slots = [Vector2(-3.5, 4.2), Vector2(5, -5), Vector2(-5.5, -3.5)]
	return t


## Testvorlage: bisherige Ebene 1 (13 × 10 m, Luke bei (0, 3), Spawns wie im Mischkampf).
static func _fixture_upper() -> FloorTemplate:
	var t := _make(FIXTURE_UPPER, "M2D-Ebene 1 (Test)", FloorTemplate.EdgeRisk.LOW, ["FIXTURE"])
	t.is_fixture = true
	t.rects = [Rect2(-6.5, -5, 13, 10)]
	t.player_start = Vector2(0, -0.5)
	t.melee_slots = [Vector2(4.8, -2), Vector2(-4.2, -2)]
	t.ranged_slots = [Vector2(-5, 3.6)]
	t.landing_slots = [Vector2(0, -0.5), Vector2(-3, 1.5)]
	t.has_hatch = true
	t.hatch_slot = Vector2(0, 3)
	return t


## Testvorlage: bisheriger Ebene-2-Ring (17 × 14 m, Schacht 5 × 4 m).
static func _fixture_ring() -> FloorTemplate:
	var t := _make(FIXTURE_RING, "M2D-Ebene 2 (Test)", FloorTemplate.EdgeRisk.HIGH, ["FIXTURE", "CENTRAL_HOLE"])
	t.is_fixture = true
	t.rects = [Rect2(-8.5, -7, 17, 14)]
	t.holes = [Rect2(-2.5, -3, 5, 4)]
	t.player_start = Vector2(0, 4)
	t.melee_slots = [Vector2(-6.5, -1), Vector2(6.5, -1)]
	t.ranged_slots = [Vector2(0, -5.5)]
	t.landing_slots = [Vector2(0, 4), Vector2(4, 4.5)]
	return t
