# Bericht: M1.1 — Dauerattacke: freie Kontrolle und schwereres Hammergefühl

Datum: 25.09.2026  
Umfang: M1.1-Korrektur nach manuellem Controller-Feedback (Teilabnahme M1): Kontrolle bei gehaltenem Angriff, Schlagrichtungsregel, Hammertiming und -animation  
Status: implementiert; automatisierte und skriptgesteuerte gerenderte Prüfungen bestanden  
Nutzerabnahme: **erneut offen**

## Befund: eingeschränkte Kontrolle bei gehaltenem Angriff

Gemessen mit einem neuen Test vor jeder Änderung. Simuliert wurde: RT dauerhaft gehalten, linker Stick eine volle 360°-Umdrehung in 1,5 s, danach harte Richtungswechsel alle 0,25 s.

| Messung | vorher (M1) | nachher (M1.1) |
|---|---:|---:|
| Angriffszustand aktiv (90 Ticks Umdrehung) | 90/90 | 90/90 |
| Max. Abweichung der Geschwindigkeit ggü. derselben Eingabe ohne Angriff | 1,38 m/s | 0,000 m/s |
| Max. Körperdrehung in einem Tick | 128° | 13,8° |
| Mittlere Abweichung Körper ↔ Stickrichtung (außerhalb ACTIVE) | 61,7° | 11,4° |
| Max. vertikaler Anteil des Hammerkopfs während ACTIVE | 0,93 | 0,18 |

Ursachen im Code:

1. **Gehaltenes RT bedeutet praktisch dauerhaft den Zustand ATTACK.** Nach der Recovery startet sofort der nächste Swing. Alles, was nur für „während des Angriffs“ gedacht war, galt damit ständig.
2. **Der Körper war für den ganzen Zyklus eingefroren.** `_update_root_rotation` drehte während ATTACK auf die beim Start fixierte `attack_direction`. `_start_attack` rastete den Körper dann alle 0,52 s hart auf das aktuelle Facing ein. Die Bewegungsrichtung folgte dem Stick zwar korrekt, sichtbare Ausrichtung und Treffersektor hingen aber bis zu einem Zyklus hinterher und sprangen (bis 128° in einem Tick).
3. **`attack_move_multiplier = 0.70`** machte die Bewegung bei gehaltenem RT dauerhaft 30 % langsamer. Bei jedem Übergang wurde zudem zwischen 4,6 und 3,2 m/s umbeschleunigt.
4. **Hammer:** Die Windup-Pose lag fast senkrecht über der Schulter (Neigung 72°), und das Ausholen dauerte nur 0,14 s. Der Schlag las sich deshalb als kurze Hackbewegung nach vorne/unten. Das Zurückführen lief als zweiter Rückwärtsschwung durch die Front.

Bewegung, Facing-Ermittlung, Deadzone und Input-Router waren nicht die Ursache und blieben unverändert.

## Tatsächlich vorgenommene Änderungen

**Richtungsregel** (`scripts/actors/player_controller.gd`, `scripts/combat/weapon_controller.gd`):

- Die Körperausrichtung wird jetzt vor den Aktionen aktualisiert und in allen Phasen weich zum Facing nachgeführt. Die Schärfe ist unverändert 22/s. Ausnahme ist ACTIVE: Dort ist der Körper an die fixierte Schlagrichtung gebunden.
- Neues `WeaponController.aim()`: Es wirkt nur während WINDUP. Der Player übergibt jeden Tick seine sichtbare Körperausrichtung. Beim Übergang in ACTIVE übernimmt der Treffersektor exakt diese Ausrichtung und ist ab dann fixiert. Körper, Trail und Sektor stimmen dadurch überein (Test: < 0,5°).
- `_start_attack` rastet den Körper nicht mehr ein, es gibt keinen Rotationssprung mehr.
- RECOVERY: freie Körperausrichtung, keine Treffer (unverändert). Der Trail bleibt beim Ausblenden auf der Schlagrichtung.
- Der nächste gehaltene Swing verwendet die neueste Ausrichtung. Bei neutralem Stick bleibt die letzte bewusste Richtung erhalten.
- Designentscheidung: Im Windup folgt die Schlagrichtung der *sichtbaren* Körperausrichtung, nicht dem rohen Stickwert. Bei einer Richtungsänderung ganz am Ende des Windups kann der Schlag daher noch zwischen alter und neuer Richtung liegen. Treffer und Darstellung stimmen so aber immer überein. Bei kontinuierlicher Stickdrehung beträgt der Nachlauf ≈ 11°.

**Tuning:**

- `attack_move_multiplier` von 0,70 auf **1,0** (`resources/tuning/player_tuning.tres`, Default in `player_tuning.gd`).
- Hammer: Windup/Active/Recovery von 0,14/0,10/0,28 auf **0,26/0,12/0,42 s**, Zyklus 0,80 s (`resources/weapons/hammer.tres`, Defaults in `weapon_data.gd`).
- Unverändert: Laufgeschwindigkeit, Beschleunigung, Abbremsen, Deadzone, Drehschärfe, Schaden, Reichweite, Winkel, Knockback, Dummy-HP, Dodge, Kamera, Arena, Renderer, Physiktakt.

**Placeholder-Animation** (`scripts/actors/placeholder_golem_visual.gd`, nur der Visual-Adapter):

- Die Pose besteht jetzt aus Hammer-Gier, Neigung, Oberkörperdrehung, Vorlage und Absenken. Oberkörper und Hammer tragen das Gewicht gemeinsam. Der Schwung-Pivot gleicht die Oberkörperdrehung aus, damit die Hammerrichtung exakt der Gier entspricht.
- Ruhe: Hammer steil auf der Schulter.
- Ausholen: schnell weit zur Seite nach hinten, fast waagerecht. Der Oberkörper dreht 45° mit, das Gewicht geht nach hinten und tiefer. Am Ende „hängt“ die Pose kurz.
- ACTIVE: breiter, seitlich-diagonaler Schwung von rechts hinten nach links vorne mit Vorlage. Er kreuzt die Sektormitte etwa zur Mitte des Trefferfensters.
- RECOVERY: Das Gewicht läuft nach und wird abgefangen (30 %). Danach wird der Hammer über den Rücken auf die Schulter zurückgeführt, die Drehung setzt sich also fort statt als zweiter Schwung durch die Front zu laufen.
- Ein neues Ausholen startet an der aktuell sichtbaren Pose, etwa nach einem Dodge-Abbruch, deshalb gibt es keinen Posensprung.
- Kein TimeScale-Hitstop; der Camera-Shake ist unverändert.

**Debuganzeige** (`scripts/ui/hud.gd`, F3): zeigt Bewegung, Facing, Körper und Schlagrichtung getrennt als Bildschirmwinkel (0° = oben, 90° = rechts), dazu Geschwindigkeit sowie Angriffsphase mit Fortschritt.

**Dokumente:** `AGENTS.md` (Richtungsregel), `docs/INPUT_CONTRACT.md`, `docs/COMBAT_SPEC.md`, `docs/ARCHITECTURE.md`, `docs/TUNING.md`, `docs/DECISIONS.md` (D18), `docs/PLAYTEST_CHECKLIST.md` (Minute 2), `docs/STATUS.md`.

**Tests/QA:** `tests/test_runner.gd` mit vier neuen M1.1-Tests; zeitabhängige Bestandstests auf den neuen Takt angepasst (siehe unten). In `tests/qa_capture.gd` erzeugen zwei neue Zeitreihen-Kontaktabzüge.

## Testnachweise

| Prüfung | Status | Umgebung / Befund |
|---|---|---|
| Import/Parse, Headless-Smoke | BESTANDEN | Godot 4.7.2, ohne Fehler/Warnungen |
| Regressionstests | BESTANDEN | 26 Tests / 161 Checks, Exitcode 0 (`--fixed-fps 60`) |
| Freie Bewegung bei gehaltenem RT | BESTANDEN | `test_m11_movement_identical_with_attack_held`: identische Geschwindigkeiten mit/ohne RT über 360°-Umdrehung + harte Wechsel (max. 0,000 m/s) |
| Körper folgt Stick, keine Sprünge | BESTANDEN | `test_m11_body_follows_stick_while_attack_held`: max. 13,8°/Tick, mittl. 11,4° |
| WINDUP folgt / ACTIVE fix / RECOVERY frei / nächster Swing neu | BESTANDEN | `test_m11_direction_rule_windup_active_recovery`: Umlenkung im Windup übernommen (< 5°); während ACTIVE bleiben Sektor, Körper und Trail fix (< 0,5°), Geschwindigkeit folgt dem neuen Input; Ziel in fixierter Richtung getroffen, alte Startrichtung und Rückseite nicht; Körper in RECOVERY frei; nächster Swing in neuer Richtung trifft |
| Schlag seitlich, deckt den Sektor ab | BESTANDEN | `test_m11_visual_swing_crosses_sector_sideways`: Hammergier in ACTIVE 119° → −73°, max. vertikaler Anteil 0,18 (Placeholder-Adapter) |
| Treffer/Dodge/Kante | BESTANDEN | C1 (1 Treffer/Swing), C2, C3 (Dodge-Abbruch kein schnellerer Takt), C4, I4 (Dodge nur neue Flanke), F1/F1b/F2/F3, A1 unverändert grün |
| Gerenderte Sequenz 30/60 FPS | BESTANDEN (skriptgesteuert) | Intel UHD 620, Vulkan Mobile; 1280×720 @60 und @30, 1600×720 @60, 1024×768 @60: Render 60,6/30,6 FPS bei ≈62 Physikticks je Wandsekunde (bei beiden Raten gleich); Dummy-Kantenkill und Spielerfall je genau einmal |
| Sichtbarer Schwung | BESTANDEN (skriptgesteuert) | Zeitreihe `qa/output/m11_1280x720_60/13_single_swing_sheet.png` (24 Bilder über 0,80 s): Ausholen, Querschwung mit Trail, Abfangen und Rückführung über den Rücken folgen kontinuierlich aufeinander |
| Richtungswechsel gerendert | BESTANDEN (skriptgesteuert) | `14_held_rt_360_sheet.png` (32 Bilder über 2,4 s, RT gehalten, Stick kreist): Körper dreht kontinuierlich mit, drei Swings in jeweils aktueller Richtung, Trail auf der Schlagrichtung |
| Videomitschnitt | ERSTELLT | `qa/output/m11_session.avi` (1280×720, 60 FPS feste Spielzeit, ganze QA-Sequenz). Die Kontaktabzüge aus diesem Movie-Lauf sind zeitlich verschoben (Movie-Modus langsamer als Echtzeit) und gelten nicht als Nachweis |
| Echter Controller | OFFEN | Alle Eingaben dieses Auftrags simuliert (`InputEventJoypadMotion`). Kein Hardware-Spieltest |
| Echtes Smartphone | OFFEN | ungeprüft |

Angepasste Bestandstests (Aussage erhalten):

- `test_i3_held_attack_full_cycle`: Die erwartete Swinganzahl in 2 s wird aus dem Zyklus berechnet (jetzt 3 statt 4). Der Abstand zwischen zwei Swings muss weiterhin mindestens einen vollen Zyklus betragen.
- `test_desktop_strafe_and_fixed_attack_direction`: Die Maus wird erst nach Eintritt in ACTIVE nach hinten bewegt, und der Sektor muss fix bleiben. Das Umlenken im Windup prüft jetzt der neue Richtungstest.
- `test_i2_controller_attack_keeps_released_direction`: Toleranz als Winkel < 1° statt Vektorabstand < 0,001. Grund ist die weiche Körpernachführung.
- `test_f3_dummy_hp_kill_once`: Das Zeitlimit wurde auf 6 s erhöht (5 Treffer bei 0,80-s-Takt). Weiterhin genau eine HP-Niederlage.

## Offene Punkte

- **Gefühl nicht beurteilt:** Ob sich der Hammer jetzt schwer, aber kontrollierbar anfühlt, zeigt erst der erneute Controller-Test. Das Timing 0,26/0,12/0,42 s ist ein Spieltest-Ausgangswert.
- Eine Richtungsänderung in den letzten ≈ 0,05 s des Windups landet wegen der weichen Körpernachführung nur teilweise im Schlag (bewusst: Sichtbares = Treffer). Falls sich das träge anfühlt, sind die nächsten Hebel die Drehschärfe (nur für WINDUP) oder ein kurzes Aim-Fenster.
- Mit Multiplikator 1,0 läuft der Golem während des Schwungs mit voller Geschwindigkeit. Das ist gewollt für diesen Test; ob der Hammer dadurch leichter wirkt, bleibt Spieltestfrage.
- Die Kamera ist unverändert (Feedback „eventuell zu nah“ bewusst zurückgestellt).
- Die Hammerpose in Ruhe (steil auf der Schulter) ist ein Blockout, kein Zielstil.
- Weiter offen aus M1: Smartphone, Android-Export, Displays > 60 Hz.

## Erneuter manueller Spieltest (Controller)

1. Starten: `& "D:\Godot_v4.7.2-stable_win64.exe" --path D:\Project_Fall`. Mit F3 lässt sich die Debugzeile ein- und ausblenden; sie zeigt Bewegung, Facing, Körper und Schlagrichtung.
2. RT dauerhaft halten und mit dem linken Stick Kreise, Achten und harte Umkehrungen laufen. Erwartet: Bewegung fühlt sich wie ohne Angriff an, der Körper dreht ohne Sprünge mit.
3. RT drücken und während des Ausholens den Stick umlenken. Der Schlag muss in die neue Richtung gehen. Nach dem Zuschlagen umlenken: Der laufende Schlag bleibt, der nächste geht in die neue Richtung.
4. Einzelne Schläge gegen Dummies vorne/seitlich/hinten. Wirkt der Hammer schwer (Ausholen, Querschwung, Nachlaufen)? Passt der Trail zum Treffer?
5. Kontrolle: Dodge während des Ausholens und Nachlaufens, LT halten (nur ein Dodge), Dummy über die Kante schlagen, selbst über die Kante laufen.

## Stopp

Kein M2, keine Produktionsassets, keine Kamera-/Arena-/Renderer-/Physikänderung, kein Face-before-move-Experiment, keine Installationen, kein Commit/Push.
