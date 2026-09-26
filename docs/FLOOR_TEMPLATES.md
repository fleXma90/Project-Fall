# Floor-Vorlagen v1 (M3B) — handgebaute Floors, zufällige Auswahl pro Run

Stand 26.09.2026. Kein prozeduraler Generator: Die sechs Geometrien sind bewusst gestaltet und automatisch geprüft. Zufällig ist nur, welche geprüfte Vorlage Ebene 1 bzw. Ebene 2 eines Abstiegs wird. Training, Duell, Gruppe und Mischkampf nutzen weiter die feste Testarena.

## System

| Teil | Ort | Rolle |
|---|---|---|
| `FloorTemplate` | `scripts/levels/floor_template.gd` | Reine Daten: ID, Name, Kantenrisiko, Tags, Rechtecke, echte Löcher, Slots, Luke; Geometrieabfragen (`contains`, `is_safe_point`, `bounds`) und `validate()` |
| `FloorTemplates` | `scripts/levels/floor_templates.gd` | Katalog der sechs Vorlagen, zwei Testvorlagen (feste M2D-Geometrie), Kandidaten je Ebene, `select_pair()` |
| `FloorGeometry` | `scripts/levels/floor_geometry.gd` | Baut aus Rechtecken minus Löchern (und Luken-Aussparung) Kollider, Körper, Kacheln, Kantenleisten; optional Licht darunter |
| Arena | `TrainingArena._build_run_floors()` | Instanziiert zu Run-Beginn nur die zwei gewählten Vorlagen unter `RunFloors`; alte Instanzen werden sofort deaktiviert und freigegeben |

Gameplay fragt nur Metadaten ab (Kantenrisiko, Slots, Luke), nie den Namen.

## Die sechs Vorlagen (lokal XZ, Oberkante y = 0)

| ID | Name | Kantenrisiko | Tags | Ausdehnung | Form |
|---|---|---|---|---|---|
| `open_forge` | Open Forge | LOW | OPEN | 17 × 14 m | Große zusammenhängende Fläche, vier Ausbuchtungen, zwei Eckkerben, keine Innenlöcher |
| `broken_corner` | Broken Corner | LOW | ASYMMETRIC | 16 × 12 m | Eine deutlich fehlende Ecke (5 × 4.5 m) und zwei kleine Randkerben |
| `central_pit` | Central Pit | MEDIUM | CENTRAL_HOLE | 16 × 13 m | Zentrales Loch 4 × 3.5 m (Laufwege ringsum ≥ 4.5 m), zwei Eckkerben |
| `twin_plates` | Twin Plates | MEDIUM | SPLIT, ASYMMETRIC | 18 × 12 m | Zwei versetzte Platten (8 × 10 m) mit 5 m breiter Verbindung |
| `cross_forge` | Cross Forge | MEDIUM | CROSS | 16 × 16 m | Breites Kreuz, Arme 7–8 m, asymmetrisch gekappte Ecken, große Mitte |
| `shattered_ring` | Shattered Ring | HIGH | CENTRAL_HOLE, ASYMMETRIC | 17 × 14 m | Asymmetrischer Schacht (5 × 4 m + Seitentasche), drei Randkerben, Ring ≥ 4 m breit |

Kantenrisiko (kuratiert, kein berechneter Score): LOW = viel sichere Fläche, Kantensiege erst nach Positionierung; MEDIUM = einzelne taktische Löcher/Kanten; HIGH = Kanten spielen eine starke Rolle, auch für den Spieler.

## Slots

Jede Vorlage hat: 1 Spielerstart, ≥ 3 Nahkampf-Slots (Scraplings), ≥ 2 Fernkampf-Slots (Funkenwerfer), ≥ 2 Landing-Slots und, falls sie Ebene 1 sein kann, eine Luke (2 × 2 m). Pro Floor werden 2 Nahkampf- und 1 Fernkampf-Slot mit dem Floor-Zufall gewählt; bei genau passender Anzahl in Reihenfolge. Gegnerzusammensetzung bleibt immer 2 Scraplings + 1 Funkenwerfer.

## Validierung (`FloorTemplate.validate()`, `test_v2`)

| Regel | Wert |
|---|---|
| Spawn-Slots und Spielerstart | Boden ringsum ≥ 1.5 m |
| Landing-Slots | Boden ringsum ≥ 1.2 m (wie M2D), ≥ 3 m zu jedem Spawn-Slot, nicht in der Luke (≥ 1.8 m) |
| Luke | Boden ringsum ≥ 2 m, ≥ 2.5 m zu Spielerstart und Spawn-Slots |
| Abstände | Spawn-Slots untereinander ≥ 2 m; Nahkampf ≥ 4 m und Fernkampf ≥ 6.2 m (Schussdistanz) vom Spielerstart |
| Kamerabild zu Kampfbeginn (nur Vorlagen für Ebene 1) | Gegner höchstens 5 m zur Kamera hin, 7.5 m davon weg (sonst unter der HUD-Zeile), seitlich 7 m − 0.2 · (Meter zur Kamera); damit auch in 4:3 lesbar |
| Ausdehnung | 10–20 m (X) bzw. 10–18 m (Z) |
| Physik (`test_v2`) | Collider genau dort, wo die Vorlage Boden meldet (0.5-m-Raster inkl. Rand), Lochmitten ohne Collider, alle Collider innerhalb der Fläche und nie höher als die Oberkante (keine Barrieren), jeder Slot hat Boden |

Fehler nennen immer die Vorlagen-ID; eine kaputte Vorlage wird nicht automatisch repariert (`test_v2` prüft eine absichtlich fehlerhafte).

## Auswahl pro Run

- Ebene 1: LOW oder MEDIUM mit Luke (Open Forge, Broken Corner, Central Pit, Twin Plates, Cross Forge).
- Ebene 2 (derzeit final): MEDIUM oder HIGH (Central Pit, Twin Plates, Cross Forge, Shattered Ring), nie dieselbe Vorlage wie Ebene 1.
- Die Auswahl steht beim Run-Start fest (`RunState.floor_template_ids`); ein neuer Run wählt neu.
- **Zufall getrennt:** `RunState.rng` (Upgrade-Karten, Reihenfolge wie in M3A) und `RunState.floor_rng` (Vorlagen und Slots) sind getrennte Generatoren. `floor_rng` wird aus dem Run-Seed abgeleitet (`hash([seed, "floors"])`) oder über `TrainingArena.floor_seed` fest gesetzt. Floor-Aufrufe verändern die Upgrade-Karten nie (`test_v3`).
- Test-/Debughilfe: `TrainingArena.forced_floor_ids = [Ebene 1, Ebene 2]`. Die M2D-/M3A-Regressionstests laufen damit auf den zwei Testvorlagen (`fixture_m2d_upper`, `fixture_m2d_ring`), die die bisherige feste Geometrie nachbilden und nie im Pool sind.

## Landung und Luke

- Senkrechter Fall wie in M2D.2: Beim Verlassen von Ebene 1 wird die noch verborgene Ebene 2 samt wartenden Gegnern einmalig so versetzt, dass ein Landing-Slot genau unter der Fallbahn liegt. Danach verschiebt sich nichts mehr relativ; keine Spielerlenkung.
- Welcher Slot: unter den sicheren Slots mit ≥ 3 m zu den Gegnern derjenige, dessen Lage auf Ebene 2 am besten zur Absprungstelle auf Ebene 1 passt (Sturz im Osten → Landung im Osten). Verschiedene Kanten nutzen so verschiedene Slots (`test_v5`).
- Luke: bei Kante und Luke gleich; die Luke liegt nie an der Außenkante, nie in einem Loch, deckt keine Slots. Ebene 2 hat keine Luke.
- Sichtbarkeit (M2D.1): Ebene 2 samt Licht, Gegnern und HP-Anzeigen ist bis zum Übergang verborgen, ihre Gegner sind ohne Ziel (`test_v6`).

## Gegnerlauf

Keine Navigation/Pfadsuche: Im Abstieg nutzen alle Gegner den lokalen Lückenumweg (`GapDetour`), in den festen Szenarien nicht. `test_v7` lässt auf jeder Vorlage einen Scrapling und einen Funkenwerfer vom entferntesten Slot zum Spieler laufen (kein Lochsturz) und stößt danach einen Scrapling per Knockback in ein Loch bzw. über die Kante (Kantensieg, Orbs auf sicherem Boden).

## Erweiterbarkeit

Neue Vorlage = neue Funktion in `FloorTemplates` + Eintrag in `all()`; `validate()` und `test_v2` prüfen sie automatisch. Später erzeugte Floors können dieselbe Schnittstelle (Rechtecke, Löcher, Slots, Luke) liefern; ein Generator ist nicht Teil von M3B.
