class_name FloorTemplate
extends RefCounted
## Handgebaute Floor-Vorlage (M3B). Reine Daten + Geometrieabfragen im lokalen XZ der Ebene (Oberkante y = 0):
## begehbare Rechtecke minus echte Löcher, kuratiertes Kantenrisiko, Slots für Spielerstart, Nahkampf-/Fernkampf-
## Spawns, sichere Landepunkte und (nur für nicht finale Floors) die Luke. Kein Generator: Gameplay fragt nur diese
## Metadaten ab, nie den Namen.

enum EdgeRisk { LOW, MEDIUM, HIGH }

const HATCH_SIZE := Vector2(2.0, 2.0)

## Validierungsregeln (siehe docs/FLOOR_TEMPLATES.md).
const SPAWN_EDGE_MARGIN: float = 1.5
const LANDING_EDGE_MARGIN: float = 1.2
const HATCH_EDGE_MARGIN: float = 2.0
const SPAWN_MIN_SPACING: float = 2.0
const MELEE_MIN_PLAYER_DISTANCE: float = 4.0
const RANGED_MIN_PLAYER_DISTANCE: float = 6.2
const MAX_SLOT_PLAYER_DISTANCE: float = 11.5
const LANDING_SPAWN_CLEARANCE: float = 3.0
const LANDING_HATCH_CLEARANCE: float = 1.8
const HATCH_SPAWN_CLEARANCE: float = 2.5
## Feste Kamera (Yaw 45°, Pitch 48°): zum Betrachter hin ist nur ≈ 6 m sichtbar, nach hinten ≈ 10.8 m, wobei die
## obere HUD-Zeile die letzten Meter verdeckt. Spawn-Slots liegen deshalb höchstens 5 m in Kamerarichtung und 7.5 m
## davon weg, seitlich tiefenabhängig (Gegner samt HP-Anzeige zu Kampfbeginn in 16:9, 20:9 und 4:3 lesbar). Gilt für Vorlagen, die
## Ebene 1 sein können (Spielerstart); auf Ebene 2 landet der Spieler an einem Landing-Slot.
const CAMERA_TOWARD := Vector2(0.70710678, 0.70710678)
const SPAWN_MAX_TOWARD_CAMERA: float = 5.0
const SPAWN_MAX_AWAY_FROM_CAMERA: float = 7.5
## Seitlich sichtbar (4:3 ist am schmalsten): ≈ 7 m auf Höhe des Spielers, zur Kamera hin schmaler, nach hinten breiter.
const SPAWN_SIDE_AT_PLAYER: float = 7.0
const SPAWN_SIDE_PER_TOWARD: float = 0.2
const MIN_SIZE: float = 10.0
const MAX_SIZE_X: float = 20.0
const MAX_SIZE_Z: float = 18.0

var id: StringName = &""
var display_name: String = ""
var edge_risk: EdgeRisk = EdgeRisk.LOW
var tags: PackedStringArray = []
var rects: Array[Rect2] = []
## Echter fehlender Boden (Innenlöcher und Randkerben): kein Collider, kein Mesh.
var holes: Array[Rect2] = []
var player_start: Vector2 = Vector2.ZERO
var melee_slots: Array[Vector2] = []
var ranged_slots: Array[Vector2] = []
var landing_slots: Array[Vector2] = []
var has_hatch: bool = false
var hatch_slot: Vector2 = Vector2.ZERO
## Testvorlage (feste M2D-Geometrie für Regressionstests), nie im Zufallspool.
var is_fixture: bool = false


func contains(p: Vector2) -> bool:
	var inside := false
	for r in rects:
		if r.has_point(p):
			inside = true
			break
	if not inside:
		return false
	for h in holes:
		if h.has_point(p):
			return false
	return true


## Boden ringsum im Abstand margin (8 Richtungen), wie FloorGeometry.is_safe_point.
func is_safe_point(p: Vector2, margin: float) -> bool:
	if not contains(p):
		return false
	for i in 8:
		var angle := TAU * i / 8.0
		if not contains(p + Vector2(cos(angle), sin(angle)) * margin):
			return false
	return true


func bounds() -> Rect2:
	var b := rects[0]
	for r in rects:
		b = b.merge(r)
	return b


func hatch_rect() -> Rect2:
	return Rect2(hatch_slot - HATCH_SIZE * 0.5, HATCH_SIZE)


## Floor 1 (nicht final): LOW/MEDIUM mit Luke. Floor 2 (derzeit final): MEDIUM/HIGH.
func allowed_on_floor(index: int) -> bool:
	if is_fixture:
		return false
	if index == 1:
		return edge_risk != EdgeRisk.HIGH and has_hatch
	return edge_risk != EdgeRisk.LOW


func risk_name() -> String:
	return ["LOW", "MEDIUM", "HIGH"][edge_risk]


func spawn_slots() -> Array[Vector2]:
	var all: Array[Vector2] = []
	all.append_array(melee_slots)
	all.append_array(ranged_slots)
	return all


## Geometrische Prüfung ohne Physik. Leere Liste = gültig; jeder Fehler beginnt mit der Template-ID.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	var prefix := "[%s] " % id
	if rects.is_empty():
		errors.append(prefix + "keine Geometrie")
		return errors
	var b := bounds()
	if b.size.x < MIN_SIZE or b.size.y < MIN_SIZE or b.size.x > MAX_SIZE_X or b.size.y > MAX_SIZE_Z:
		errors.append(prefix + "Ausdehnung %.1f × %.1f m außerhalb der Grenzen" % [b.size.x, b.size.y])
	if not is_fixture and (melee_slots.size() < 3 or ranged_slots.size() < 2 or landing_slots.size() < 2):
		errors.append(prefix + "zu wenige Slots (Nahkampf %d, Fernkampf %d, Landung %d)" % [melee_slots.size(), ranged_slots.size(), landing_slots.size()])
	if not is_safe_point(player_start, SPAWN_EDGE_MARGIN):
		errors.append(prefix + "Spielerstart %s ohne sicheren Boden" % player_start)
	var spawns := spawn_slots()
	for s in melee_slots:
		if s.distance_to(player_start) < MELEE_MIN_PLAYER_DISTANCE:
			errors.append(prefix + "Nahkampf-Slot %s zu nah am Spielerstart" % s)
	for s in ranged_slots:
		if s.distance_to(player_start) < RANGED_MIN_PLAYER_DISTANCE:
			errors.append(prefix + "Fernkampf-Slot %s in Schussdistanz zum Spielerstart" % s)
	for s in spawns:
		if not is_safe_point(s, SPAWN_EDGE_MARGIN):
			errors.append(prefix + "Spawn-Slot %s zu nah an fehlendem Boden" % s)
		if s.distance_to(player_start) > MAX_SLOT_PLAYER_DISTANCE:
			errors.append(prefix + "Spawn-Slot %s zu weit vom Spielerstart (Kamera)" % s)
		var d := s - player_start
		var toward := d.dot(CAMERA_TOWARD)
		var side := d.dot(Vector2(CAMERA_TOWARD.x, -CAMERA_TOWARD.y))
		var max_side := SPAWN_SIDE_AT_PLAYER - SPAWN_SIDE_PER_TOWARD * toward
		if has_hatch and (toward > SPAWN_MAX_TOWARD_CAMERA or toward < -SPAWN_MAX_AWAY_FROM_CAMERA or absf(side) > max_side):
			errors.append(prefix + "Spawn-Slot %s zu Kampfbeginn außerhalb des Kamerabilds" % s)
	for i in spawns.size():
		for j in range(i + 1, spawns.size()):
			if spawns[i].distance_to(spawns[j]) < SPAWN_MIN_SPACING:
				errors.append(prefix + "Spawn-Slots %s und %s überlappen" % [spawns[i], spawns[j]])
	for l in landing_slots:
		if not is_safe_point(l, LANDING_EDGE_MARGIN):
			errors.append(prefix + "Landing-Slot %s ohne sicheren Boden" % l)
		for s in spawns:
			if l.distance_to(s) < LANDING_SPAWN_CLEARANCE:
				errors.append(prefix + "Landing-Slot %s zu nah am Spawn %s" % [l, s])
		if has_hatch and l.distance_to(hatch_slot) < LANDING_HATCH_CLEARANCE:
			errors.append(prefix + "Landing-Slot %s liegt in der Luke" % l)
	if has_hatch:
		if not is_safe_point(hatch_slot, HATCH_EDGE_MARGIN):
			errors.append(prefix + "Luke %s zu nah an Kante/Loch" % hatch_slot)
		for s in spawns + [player_start]:
			if hatch_slot.distance_to(s) < HATCH_SPAWN_CLEARANCE:
				errors.append(prefix + "Luke %s überdeckt Slot %s" % [hatch_slot, s])
	return errors
