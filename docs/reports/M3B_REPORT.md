# Bericht: M3B — Floor Variety V1 (handgebaute Floor-Vorlagen, zufällige Auswahl pro Run)

Datum: 26.09.2026  
Umfang: Auftrag „M3B — Floor Variety V1“; Quadropus-Screenshots nur als Gestaltungsprinzip (große lesbare Flächen, unregelmäßige Konturen, einzelne Löcher), nichts übernommen.  
Ausgangsstand: `7550fea` (M3A, GitHub `main`)  
Status: implementiert (Prototyp mit Dummy-Assets), nicht committet  
Nutzerabnahme: offen

## Spielbares Ergebnis

- Jeder Abstiegs-Run wählt zwei von sechs handgebauten Floors:
  - Ebene 1: **Open Forge**, **Broken Corner**, **Central Pit**, **Twin Plates** oder **Cross Forge**.
  - Ebene 2: **Central Pit**, **Twin Plates**, **Cross Forge** oder **Shattered Ring**, nie dieselbe wie Ebene 1.
  - Die Auswahl gilt fest für den Run; ein neuer Run wählt neu.
- Jede Vorlage hat eine eigene Silhouette: offene Fläche, fehlende Ecke, zentrales Loch, zwei Platten mit breiter Verbindung, breites Kreuz, asymmetrischer Ring um einen Schacht.
  - Löcher sind echte Löcher ohne Boden.
  - Die Kantenleisten markieren alle echten Kanten.
- Die Gegner stehen auf kuratierten Slots, immer 2 Scraplings + 1 Funkenwerfer. Zu Kampfbeginn sind alle drei im Bild, auch in 4:3.
- Die Luke liegt je Vorlage an einer geprüften, gut lesbaren Stelle.
- Kantensturz und Lukenabstieg bleiben senkrecht:
  - Die noch verborgene Ebene 2 wird so ausgerichtet, dass ein Landing-Slot unter dem Spieler liegt.
  - Der Slot passt zur Absprungstelle: Wer im Osten fällt, landet im Osten.
- Unverändert bleiben:
  - M2D.1-Reveal, 12 Sturzschaden, 0.75 s Landeschutz.
  - XP-Orbs, Stats, Floor-Clear-Upgrade und die Regeln für frühen Sturz.
- F3-Debugzeile: „FLOOR TEMPLATE: … · EDGE RISK: … · RUN FLOOR: n / 2 · Seeds“. Die Ergebnisanzeige nennt „Floors: A → B“, das Rundenlog die Vorlage je Ebene.
- Training, Duell, Gruppe und Mischkampf laufen unverändert auf der festen Testarena.

## Starten

Godot-Version: 4.7.2.stable.official (geprüft)  
Renderer: Mobile (Vulkan Forward Mobile, Intel UHD 620)  
Hauptszene: `res://scenes/main.tscn` (Standard: Abstieg)  
Startweg: `& "D:\Godot_v4.7.2-stable_win64.exe" --path "D:\Project_Fall"`  
Android-Ausgabe: OFFEN (kein Export eingerichtet)

## Assetstatus

Placeholder/Production: nur Godot-Primitiven (Box-Meshes, vorhandener Kachel-Shader)  
Externe Assets genutzt: nein  
VisualRoot austauschbar: unverändert

## Geänderte Dateien

| Pfad | Rolle |
|---|---|
| `scripts/levels/floor_template.gd` (neu) | Vorlagen-Datenklasse: Geometrie, Slots, Luke, Kantenrisiko, `validate()` |
| `scripts/levels/floor_templates.gd` (neu) | Katalog der sechs Vorlagen, zwei Testvorlagen, Kandidaten, `select_pair()` |
| `scripts/levels/floor_geometry.gd` | Löcher und Luken-Aussparung, überlappungsfreie Teilflächen, Licht darunter, `set_enabled` inkl. Kindkörper |
| `scripts/levels/training_arena.gd`, `scenes/levels/training_arena.tscn` | Run-Ebenen aus Vorlagen (`RunFloors`), Spawns aus Slots, Landing-Slot-Wahl, feste Ebene 2 samt Markern entfernt, Seeds/Testhilfen |
| `scripts/run/run_state.gd` | Getrennter `floor_rng`, gewählte Vorlagen-IDs |
| `scripts/actors/scrapling.gd`, `sparker.gd` | Ein Physiktick Ruhe nach Teleport (`_settle_ticks`) |
| `scripts/levels/encounter_stats.gd`, `scripts/ui/hud.gd`, `scripts/main.gd` | Vorlage in Rundenlog, F3-Zeile und Ergebnis |
| `tests/test_runner.gd` | `test_v1`–`v8`; M2D/M3A-Tests auf Testvorlagen; `test_z1` an geänderte Verträge angepasst |
| `tests/qa_capture.gd` | `--qa-floors` (Shots/Zeitreihen 80–88); alte Abstiegssequenzen auf Testvorlagen |
| `docs/FLOOR_TEMPLATES.md` (neu), STATUS, MILESTONES, DECISIONS (D41–D46), FLOOR_RULES, ARCHITECTURE, PLAYTEST_CHECKLIST; M3A-Bericht: Commitstatus korrigiert |

## Vorlagen

| Vorlage | Kantenrisiko | Ebene | Kurzbeschreibung |
|---|---|---|---|
| Open Forge | LOW | 1 | 17 × 14 m, zusammenhängend, Ausbuchtungen und Eckkerben |
| Broken Corner | LOW | 1 | 16 × 12 m, fehlende Ecke + zwei Kerben |
| Central Pit | MEDIUM | 1 / 2 | 16 × 13 m, zentrales Loch 4 × 3.5 m |
| Twin Plates | MEDIUM | 1 / 2 | 18 × 12 m, zwei Platten, 5 m breite Verbindung |
| Cross Forge | MEDIUM | 1 / 2 | 16 × 16 m, Kreuz mit 7–8 m breiten Armen |
| Shattered Ring | HIGH | 2 | 17 × 14 m, asymmetrischer Schacht, Ring ≥ 4 m |

Slots, Validierungsregeln, Auswahl, Zufallstrennung und Erweiterung: `docs/FLOOR_TEMPLATES.md`.

## Nachweise

| Prüfung | Status | Umgebung / Befund |
|---|---|---|
| Import/Parse | BESTANDEN | headless, ohne Fehler |
| Verhaltenstests | BESTANDEN | 101 Tests / 1628 Checks; neu 8 Tests / 586 Checks; alle M1–M3A-Regressionen grün |
| Template-Validator | BESTANDEN | alle 6 Vorlagen fehlerfrei; absichtlich kaputte Vorlage wird mit ID erkannt |
| Gerenderte 3D-Session | BESTANDEN (skriptgesteuert) | je Vorlage ein Shot, Kämpfe, Gegnerlauf, Schacht-Knockback, Lukenabstieg und früher Sturz zwischen Zufallsvorlagen |
| 16:9 / 20:9 / 4:3 | BESTANDEN mit Befund | Ebene 1 aller Vorlagen: 3/3 Gegner im Bild bei 1280×720, 1600×720, 1024×768. 4:3 nach Landung auf Shattered Ring: ein Gegner anfangs außerhalb |
| 30/60 Render-FPS | BESTANDEN | 31.4 bzw. 61.3 Render-FPS bei 60 Physikticks |
| Offene Kante/Fall | BESTANDEN | Physik-Raster: Boden nur wo die Vorlage Boden meldet, Löcher ohne Collider, keine Barrieren; senkrechte Landung (Drift < 0.3 m) auf Slots |
| Echter Controller | OFFEN | nur simulierte Events |
| Echtes Smartphone | OFFEN | kein Gerät/Export |

**Neue Tests:**
- **v1 Katalog:** 6 eindeutige Vorlagen, Kantenrisiken, Kandidaten je Ebene, Testvorlagen nicht im Pool.
- **v2 Validator und Physik:**
  - Alle Vorlagen sind gültig; eine kaputte Vorlage wird erkannt (Slot im Loch, Überlappung, Landing an der Kante).
  - Das 0.5-m-Raster für Collider stimmt mit der Bodenfläche überein.
  - Löcher haben keinen Collider; es gibt keine Collider außerhalb und keine Wände; jeder Slot hat Boden.
- **v3 Auswahl und Zufall:**
  - 80 Seeds: Regeln eingehalten, deterministisch, ≥ 8 Paare, alle 6 Vorlagen kommen vor.
  - Der Floor-Zufall ändert die Upgrade-Karten nicht.
  - Die Arena ist bei gleichem Seed reproduzierbar; `floor_seed` wirkt.
- **v4 Spawns:** Auf jeder Vorlage 2 + 1 Gegner auf den richtigen Slot-Typen, sicher, verteilt und zu Beginn im Bild. Die Gegner auf Ebene 2 warten auf ihren Slots.
- **v5 Landung:** Lukenfall senkrecht auf einen Slot. Vier Kantenstürze (rechts, Kerbe, unten, fehlende Ecke) landen senkrecht, und es werden mehrere Slots genutzt.
- **v6 Sichtbarkeit:**
  - Ebene 2, ihr Licht und ihre Gegner sind vor dem Abstieg unsichtbar und ohne Ziel.
  - Es gibt genau zwei Run-Ebenen; die feste Arena ist aus.
  - Die Überblendung ist stetig.
- **v7 Gegnerlauf:**
  - Auf allen 6 Vorlagen erreichen Scrapling und Funkenwerfer den Spieler vom entferntesten Slot aus, ohne in ein Loch zu fallen.
  - Knockback führt jeweils in ein Loch bzw. über die Kante, und die Orbs landen erreichbar.
- **v8 Run über Vorlagen:** XP, Upgrade und Stats bleiben über den Floorwechsel erhalten. Ein neuer Run gibt die alten Instanzen frei, ohne doppelte Signalverbindungen. Früher Sturz auf einer anderen Vorlage: 30 XP bleiben, kein Upgrade, 88 HP.

## Offene Probleme / Vereinfachungen

- **Behobener Altfehler:** Beim Neustart wurden Gegner im ersten Physiktick manchmal ~0.65 m verschoben. Ursache: Sie wurden aus der noch nicht aktualisierten Position eines anderen, im selben Frame teleportierten Gegners geschoben. Das ist erst mit wechselnden Slots aufgefallen. Korrektur: ein Tick Ruhe nach `reset_to`. Alle Altregressionen sind unverändert grün.
- **Kamera bestimmt die Vorlagen:** Durch die Schräglage sieht man zum Betrachter hin nur ≈ 6 m, und die obere HUD-Zeile verdeckt die hintersten Meter. Mehrere Slots wurden deshalb nach Sichtprüfung verschoben; der Validator enthält jetzt eine Kameraregel.
  - Auf Ebene 2 hängt die Landestelle von der Absprungstelle ab. In 4:3 kann ein Gegner am anderen Ende des Rings anfangs außerhalb des Bildes stehen; er läuft sofort heran.
- **Kantenrisiko ungeprüft:** Die Einstufung ist kuratiert, nicht gemessen. In den Skriptkämpfen (Bot: RT halten + vorwärts, mit Kanten-/Lochvorsicht) gab es auf Open Forge und Central Pit keine Kantensiege. Ob Central Pit oder Shattered Ring durch Knockback zu leicht werden, muss der Spieltest zeigen.
- **Navigation:** Es gibt nur den lokalen Lückenumweg, kein Pfadnetz. Auf allen 6 Vorlagen ist der Gegnerlauf getestet; an Innenecken kann der Weg eckig wirken.
- **Twin Plates:** Die 5 m breite Verbindung ist kein Engpass. Der Spielerstart liegt auf Platte A nahe der Verbindung, Gegner starten auf beiden Platten. Weil Platte B zur Kamera hin liegt, sitzen ihre Slots nahe der Verbindung (Kameraregel).
- **Testvorlagen:** Die M2D-/M3A-Regressionen laufen auf den zwei Testvorlagen (frühere feste Geometrie). Sie sind nie Teil des Zufallspools.

## Nächster manueller Test

1. Run 1: beide Floors normal räumen und auf die Unterschiede durch die Geometrie achten (F3 zeigt die Vorlage).
2. Run 2: neuen Run starten und prüfen, ob andere Vorlagen erscheinen. Floor 1 absichtlich früh verlassen: senkrechte Landung, kein Upgrade.
3. Run 3: bis auf Shattered Ring (HIGH, Ebene 2) spielen und Knockback in den Schacht nutzen. Wird der Floor zu leicht über Kantensiege?
4. Dabei beantworten: Fühlen sich Open Forge und Shattered Ring unterschiedlich an? Bleibt der Kampf lesbar? Wirkt die Gegnernavigation irgendwo unnatürlich?
5. Mit Controller: Ist die Arena groß genug, aber nicht zu groß?

## Stopp

Kein prozeduraler Generator, kein M4, keine Assets. Kein Commit/Push ohne ausdrückliche Anweisung.
