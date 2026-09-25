# Bericht: M2D — Zweite Ebene (Luke und Sturz)

Datum: 25.09.2026  
Umfang: Nutzerauftrag „wenn alle Gegner besiegt, öffnet sich ein kleines Portal oder Loch am Boden und man kann durch zur nächsten Ebene; in Ebene 1 wenn man runterfällt, kommt auch Ebene 2, aber mit Fallschaden“. Nutzerentscheidungen: Ebene 2 mit neuer Form + Mischkampf; Sturz von Ebene 2 = Niederlage; Commit später gemeinsam.  
Status: implementiert inkl. M2D.1 (eine Ebene sichtbar) und M2D.2 (senkrechter Kantensturz, fließender Übergang), Prototyp mit Dummy-Assets, nicht committet  
Nutzerabnahme: offen

## Spielbares Ergebnis

- Neuer Standardstart **„Abstieg“** (Profil B, Schuss scharf). Ebene 1 ist der bekannte Mischkampf (2 Scraplings + Funkenwerfer) auf der bisherigen Plattform.
- **Luke:** Sind alle drei Gegner besiegt, öffnet sich eine 2 × 2 m Luke im Boden (leuchtender Rahmen, Klappen schwingen nach unten, Licht aus dem Schacht). HUD: „Ebene 1 · geräumt – Luke offen“. Hineinlaufen genügt, kein Knopf. Landung ohne Schaden direkt unter der Luke.
- **Sturz über die Kante:** jederzeit, auch mitten im Kampf oder nach dem Räumen. Landung auf Ebene 2 mit **12 Sturzschaden** (12 % max HP), HUD-Hinweis „Sturzschaden 12“. Übrige Gegner der Ebene 1 bleiben zurück, fliegende Bolzen verschwinden.
- **Fall:** sichtbar und stetig (Kamera folgt nach unten), kein Schnitt, kein Teleport. Landung an einem geprüften sicheren Punkt nahe der Sturzstelle (1.2 m Boden ringsum, 3 m Abstand zu Gegnern). 0.75 s Landeschutz gegen Kampftreffer. Ebene 1 blendet danach aus.
- **Ebene 2** (10 m tiefer): Ring um einen 5 × 4 m Schacht. Zwei Scraplings kommen von den Flanken um den Schacht herum, der Funkenwerfer steht gegenüber und kann über den Schacht schießen. Gegner lassen sich in den Schacht schlagen.
- **Ende:** Sieg nach dem Räumen von Ebene 2 („Abstieg geschafft – Ebene 2 geräumt!“). Sturz von Ebene 2 (Kante oder Schacht) = Niederlage. Neustart beginnt wieder auf Ebene 1 mit vollen HP.
- Mischkampf, Gruppe, Duell und Training sind unverändert über das Pausemenü erreichbar (Zyklus Abstieg → Gemischt → Gruppe → Duell → Training). Dort existiert Ebene 2 nicht (keine Kollision, unsichtbar), und ein Sturz setzt wie bisher zurück.

Fehlt bewusst: dritte Ebene, Run-Struktur, neue Gegnertypen, Belohnung für das Räumen (außer „kein Sturzschaden“).

## Starten

Godot-Version: 4.7.2.stable.official (geprüft)  
Renderer: Mobile (Vulkan Forward Mobile, Intel UHD 620)  
Hauptszene: `res://scenes/main.tscn` (Standard: Abstieg)  
Startweg: `& "D:\Godot_v4.7.2-stable_win64.exe" --path "D:\Project_Fall"`; nur Mischkampf: `-- --mode=mixed`; Abstieg explizit: `-- --mode=descent`  
Android-Ausgabe: OFFEN (kein Export eingerichtet)

## Assetstatus

Placeholder/Production: nur Godot-Primitiven und der vorhandene selbst geschriebene Kachel-Shader  
Externe Assets genutzt: nein  
VisualRoot austauschbar: unverändert (keine Änderungen an Visual-Adaptern)

## Geänderte Dateien

| Pfad | Rolle |
|---|---|
| `scripts/levels/floor_geometry.gd` (neu) | Begehbare Ebene aus Rechtecken: Kollider, Körper, Kacheln, Kantenleisten nur an echten Kanten; `contains`, `is_safe_point`, `set_enabled` |
| `scripts/levels/descent_hatch.gd` (neu) | Luke: geschlossen echter Kollider, offen echtes Loch mit Klappen, Rahmen und Licht |
| `scripts/actors/gap_detour.gd` (neu) | Lokaler Umweg an Lücken (45/90/135°, bevorzugte Seite bleibt) |
| `scenes/levels/training_arena.tscn` | `Platform` jetzt `FloorGeometry` mit Lukenaussparung + `Hatch`; `LowerFloor` (Ebene 2) mit Licht, Spawns, `LowerScraplingA/B`, `LowerSparker`, Ersatzlandepunkt |
| `scripts/levels/training_arena.gd` | Modus DESCENT, Zustände FLOOR_1 → FLOOR_1_CLEARED → DROPPING → FLOOR_2, Landepunktsuche, Sturzschaden, Landeschutz, Ausblenden von Ebene 1, Nebel je Ebene, Signale `floor_cleared`, `descent_started`, `floor_landed` |
| `scripts/levels/encounter_stats.gd` | Ergebnisse „Ebene geräumt“ / „Sturz (Ebene übersprungen)“, `fall_damage`, `has_shooter` |
| `scripts/actors/player_controller.gd` | `settle_fall`/`settle_drift` (M2D.2, ersetzt `guide_fall_to`), `apply_fall_damage` (+ Signal `fall_damaged`), `protect_from_combat` |
| `scripts/actors/scrapling.gd`, `sparker.gd` | Option `gap_detour` (nur Ebene 2 aktiv; Ebene-1-Verhalten unverändert) |
| `scripts/main.gd` | Standardstart Abstieg, `--mode=descent`, Szenariozyklus, Kamera-Folgegrenze beim Abstieg, Landeeffekt |
| `scripts/ui/hud.gd`, `encounter_overlay.gd` | Ebenenanzeige, Luke/Sturz-Status, Landehinweis, Siegestitel |
| `tests/test_runner.gd` | `test_z1`–`test_z9`; `test_f1` prüft jetzt „alle Collider innerhalb der Plattform + lückenlos begehbar“ statt „genau ein Collider“ |
| `tests/qa_capture.gd` | Abstiegssequenz (`--qa-descent`, auch im Gesamtlauf), Video (`--qa-descent-movie`, `--qa-skip`) |
| `docs/…` | STATUS, MILESTONES (M2D), COMBAT_SPEC, TUNING, ARCHITECTURE, DECISIONS (D28–D32), PLAYTEST_CHECKLIST, FLOOR_RULES |

## Nachweise

| Prüfung | Status | Umgebung / Befund |
|---|---|---|
| Import/Parse | BESTANDEN | headless, ohne Fehler/Warnungen |
| Verhaltenstests | BESTANDEN | 80 Tests / 855 Checks (davon neu: 9 Tests / 110 Checks). Alle bisherigen Tests unverändert grün, außer `test_f1` (Prüfung an zerlegte Plattform angepasst, Regel gleich streng) |
| Gerenderte 3D-Session | BESTANDEN (skriptgesteuert) | Sequenz 53–64: Start Ebene 1, Luke offen, Lukenabstieg (Zeitreihe), Landung, Ebene 2 (3/3 Gegner im Bild), Kampf-Zeitreihe, Kantensturz (Zeitreihe), Landung mit Sturzschaden, Sieg, Neustart, Schachtsturz, Niederlage |
| 16:9 / 20:9 / 4:3 | BESTANDEN (skriptgesteuert) | 1280×720, 1600×720, 1024×768: Ebene 2 mit allen drei Gegnern im Bild, identische Landepunkte |
| 30/60 Render-FPS | BESTANDEN | 31.3 bzw. 61.2 Render-FPS bei 60 Physikticks auf Ebene 2 |
| Offene Kante/Fall | BESTANDEN | echte Löcher (Luke, Schacht), keine Barrieren; Fall stetig (max. horizontaler Schritt < 14 m/s pro Tick geprüft, Höhe monoton fallend), Gegner der Ebene 1 erreichen Ebene 2 nie |
| Video | ERSTELLT | `qa/output/m2d_descent.avi` (Ebene-1-Kampf), `qa/output/m2d_descent_skip.avi` (Kantensturz + Ebene 2), nicht versioniert |
| Echter Controller | OFFEN | nur simulierte Eingaben |
| Echtes Smartphone | OFFEN | kein Gerät/Export |

Neue Tests: z1 Start/Aufbau/Zyklus (auch: Luke trägt geschlossen, andere Szenarien ohne Ebene 2) · z2 Luke nach Räumen, echtes Hineinlaufen per Stick, kein Schaden, Landung unter der Luke, stetiger Fall · z3 Kantensturz mit Stick: übersprungen, Bolzen entfernt, 12 Schaden, sicherer Landepunkt nahe der Sturzstelle, Gegnerabstand, Landeschutz endet · z4 Kantensturz nach dem Räumen kostet trotzdem 12 · z5 tödlicher Sturzschaden = Niederlage · z6 Schachtsturz = Niederlage, Ergebnisanzeige, Neustart vollständig auf Ebene 1 · z7 Sieg genau einmal inkl. Schacht-Kantensieg · z8 Scrapling läuft um den Schacht (ohne Umweg bleibt er stehen) · z9 abgestürzter Ebene-1-Gegner erreicht Ebene 2 nicht.

## Offene Probleme / Vereinfachungen

- **Skriptbot verliert:** „RT halten + nächsten Gegner anlaufen“ verlor im Video auf Ebene 1 (100 Schaden in 8 s) und nach dem Kantensprung auch auf Ebene 2 (88 Schaden in 10.5 s). Konsistent mit M2C (timingabhängig); stures Halten ist kein Selbstläufer. Kein Tuning vorgenommen.
- **Ebene 2 ist druckvoll:** Beide Scraplings kommen gleichzeitig von zwei Seiten um den Schacht, der Funkenwerfer schießt über den Schacht. In der Kampf-Zeitreihe 80 Schaden in 5 s (Bot). Ob das zu hart ist, muss der Spieltest zeigen.
- **Überspringen ist billig:** Der Kantensprung kostet 12 HP und überspringt Ebene 1 komplett. Das Räumen bringt derzeit nur „kein Sturzschaden“. Balancefrage für später (z. B. Belohnung), nicht umgesetzt.
- **Fallführung (überholt durch M2D.2, jetzt senkrechter Fall):** korrigiert nur die Horizontale (höchstens 14 m/s). Bei großen Korrekturen, etwa nach einem weiten Dodge über die Kante, kann sie wie ein seitlicher Zug wirken. Visuell zu prüfen.
- **Aufpoppen/Ausblenden:** Gegner der Ebene 2 werden erst beim Verlassen von Ebene 1 sichtbar, weil ihre HP-Anzeigen sonst durch Ebene 1 schienen. Übersprungene Gegner der Ebene 1 verschwinden mit dem Ausblenden von Ebene 1 nach 0.5 s.
- **Killhöhe:** Die Killhöhe der Ebene-1-Gegner liegt im Abstieg bei −3 m statt −5 m. Ein Kantensieg zählt dort also etwas früher.
- **Bestehende Befunde:** Trefferketten ohne Schutzfenster, überlappende Markierungen und die Kamerabild-Regel des Funkenwerfers gelten unverändert auch auf Ebene 2.

## Nächster manueller Test

1. Ebene 1 räumen und in die Luke laufen: Ist die Luke klar erkennbar, fühlt sich der Abstieg gut an?
2. Neustart und absichtlich über die Kante: Wirkt der Fall natürlich? Sind 12 Sturzschaden spürbar und fair?
3. Auf Ebene 2 kämpfen: Ist der Druck von zwei Seiten plus Schuss über den Schacht zu hart? Sind die 0.75 s Landeschutz spürbar?
4. Gegner in den Schacht schlagen, dann selbst hineinlaufen: Niederlage, Neustart auf Ebene 1.
5. Entscheiden, ob das Räumen von Ebene 1 eine Belohnung braucht.

## Nachtrag M2D.1 — eine Ebene sichtbar, Übergang im Fall (25.09.2026)

Anlass: Nutzerfeedback. Die dauerhaft sichtbare Ebene 2 unter Ebene 1 wirkt wie ein zweites aktives Spielfeld, konkurriert mit dem Kampf und nimmt dem Abstieg den Reveal. Gewünscht war nur eine Präsentationskorrektur; **die Mechanik bleibt eingefroren**.

**Umgesetzt (nur Darstellung):**
- Im Kampf ist nur die aktuelle Ebene sichtbar. Ebene 2 existiert physisch (Kollision aktiv), ist aber samt Gegnern, HP-Anzeigen und Licht unsichtbar.
- Unter der aktuellen Ebene liegt eine neutrale Tiefe (`DepthBackdrop`): dunkler Abgrund mit fleckigen Glutnestern (additiver, selbst geschriebener Shader `assets/placeholder/depth_glow.gdshader`) und langsam aufsteigende Funken (`CPUParticles3D`). Sie gilt in allen Szenarien und folgt beim Abstieg nach unten.
- Übergang beim Verlassen von Ebene 1 (Luke oder Kante): Ebene 1 und zurückgelassene Gegner blenden in 0.3 s aus, danach kurz nur Tiefe, Nebel und Funken. Ebene 2 samt Gegnern blendet ab 5.5 m über ihrer Oberkante in 0.2 s ein; die Kamera folgt die ganze Zeit. Nie sind beide Ebenen gleichzeitig sichtbar.
- Gemessen, Luke: verlassen → Ebene 1 weg nach 0.30 s → Ebene 2 sichtbar nach weiteren 0.15 s → Landung 0.35 s später. Gesamt 0.8 s, Kante gleich.
- Unverändert: 12 Sturzschaden, 0.75 s Landeschutz, Luke nach dem Räumen, stetiger Fall ohne Teleport, Gegner der Ebene 2 greifen erst ab der Landung an, Ebene-2-Sturz = Niederlage.

**Prototyp-Regeln (bewusst nicht final, gemäß Feedback):**
- Sturz von Ebene 2 = Niederlage gilt nur, weil es keine Ebene 3 gibt. Im Run soll ein normaler Sturz eine Ebene tiefer führen.
- 12 Sturzschaden ist ein Testwert. Überspringen ist dadurch wohl zu günstig, wird aber erst bewertet, wenn das Räumen belohnt wird (M3: z. B. XP, Upgrade, Heilung). Keine künstliche Erhöhung jetzt.
- 0.75 s Landeschutz sind für den Prototyp gedacht; später lieber sichere Spawn-/Aktivierungslogik statt langer unsichtbarer iFrames.
- Ebene 2 (Ring + Schacht) bleibt; der Druck auf Ebene 2 wird erst nach dem Controller-Spieltest beurteilt.

**Befund Fallführung (Diagnose `test_z10`, Mechanik unverändert) — überholt durch M2D.2:**

| Sturz | ballistische Landestelle | tatsächliche Landung | Korrektur | max. geführt | größte Änderung pro Tick |
|---|---|---|---:|---:|---:|
| Über die Kante laufen (4.6 m/s) | (11.5, 0.5) | (6.9, 2.4) | 5.0 m | 6.9 m/s | 10.7 m/s |
| Weiter Dodge über die Kante | (12.0, 0.5) | (7.0, 2.6) | 5.5 m | 7.9 m/s | 11.8 m/s |

Schon ein normaler Lauf über die Kante würde ballistisch rund 3 m neben Ebene 2 landen (Ebene 1 13 × 10 m, Ebene 2 17 × 14 m). Beim Einsetzen der Führung (3 m unter der Oberkante) kehrt sich die horizontale Bewegung in einem Tick um, von 4.6 m/s nach außen auf etwa 7 m/s nach innen. Das ist die befürchtete **sichtbare Umlenkung**, kein kleiner Korrekturimpuls. Die neue Darstellung verdeckt sie teilweise, weil Ebene 2 dann noch unsichtbar ist. Die Figur schwenkt aber sichtbar zurück, ebenso die Kamera.

Nicht geändert, weil die Mechanik eingefroren ist. Optionen zur Entscheidung:
1. **Ebene 2 breiter als Ebene 1** (etwa 5 m Überstand je Seite): Normale Stürze landen physisch ohne nennenswerte Korrektur. Das behebt die Ursache, verändert aber die Kampffläche von Ebene 2.
2. **Weiche Führung:** früher einsetzen und die Beschleunigung begrenzen (Kurve statt Knick). Die Korrektur bleibt gleich groß, wirkt aber weniger künstlich.
3. **Beides:** kleine Korrekturen, weich ausgeführt. Das wäre meine Empfehlung.

**Nachweise M2D.1:** 81 Tests / 872 Checks grün (neu: Reihenfolge und „nie beide Ebenen sichtbar“ in z2/z3, Tiefenlage in z1/z6, Diagnose z10). Gerendert bei 1280×720 und 1600×720 mit 60 FPS sowie 1024×768 mit 30 FPS (31.3/61.4 Render-FPS bei 60 Physikticks); Ebene 2 mit 3/3 Gegnern im Bild. Der Tiefenschein wurde nach Sichtprüfung zweimal gedimmt, weil er zuerst wie ein Lavasee wirkte. Ein Renderlauf wurde durch echte Controller-/Mauseingaben am Rechner gestört (Quellenwechsel im Log) und wiederholt. Video: `qa/output/m2d1_descent_skip.avi` (nicht versioniert; Kantensprung, Übergang, Ebene-2-Kampf; der Skriptbot gewann diesmal mit 42 Schaden, vorher verlor er, also timingabhängig).

## Nachtrag M2D.2 — sauberer Kantensturz, fließender Übergang (25.09.2026)

Nutzerfeedback: „Wenn man von der Kante fällt, soll man auf der nächsten Ebene trotzdem sauber landen wie wenn man die Ebene davor schafft; aktuell fällt man schräg nach unten, das sieht komisch aus.“ Außerdem: „Der Übergang wirkt leicht abgehakt, wie ein Schnitt: Ebene 1 wird ausgeblendet, dann erscheint Ebene 2.“ Damit sind die Optionen zur Fallführung aus M2D.1 überholt.

**Senkrechter Kantensturz statt Fallführung:**
- Beim Verlassen von Ebene 1 klingt der horizontale Schwung mit 0.12 s Zeitkonstante ab: rund 0.5 m Restweg, danach fällt der Spieler senkrecht. Keine Eingabe, kein seitliches Lenken, bei Kante und Luke gleich.
- Die Landestelle ist die Position beim Verlassen plus Restweg. Die zu diesem Zeitpunkt noch unsichtbare Ebene 2 wird samt wartenden Gegnern einmalig versetzt, sodass dort ein geprüfter sicherer Punkt liegt (1.2 m Boden ringsum, 3 m Abstand zu Gegnern). Man sieht davon nichts, weil sie erst später auftaucht. Bei der Luke ist kein Versatz nötig. Neustart setzt Ebene 2 an ihre Grundposition zurück.
- Gemessen (`test_z10`): Lauf und Dodge über die Kante driften je 0.51 m. Ab 30 % des Falls ist das Horizontaltempo höchstens 0.25 m/s. Ebene 2 wurde um (1.8, −1.8) m versetzt. Die Landung trifft den Landepunkt auf unter 0.3 m.
- Die Fallführung (`guide_fall_to`, 14 m/s) ist entfernt.

**Übergang als Überblendung, gekoppelt an die Fallhöhe:**
- Statt fester Zeitblenden (0.3 s aus, Pause, 0.2 s ein) hängt der Übergang am Fallfortschritt 0..1. Ebene 1 samt zurückgelassenen Gegnern steigt bis 6 m nach oben weg und löst sich auf. Ebene 2 taucht überlappend aus der Tiefe auf und ist vor der Landung vollständig da. Nebel und Tiefe wandern stetig mit. Das ist bildratenunabhängig.
- Gemessen, Luke (Ticks nach dem Verlassen): Ebene 2 taucht nach 23 Ticks auf, dann ist Ebene 1 zu 80 % aufgelöst. Ebene 1 ist nach 29 Ticks weg, Ebene 2 nach 39 Ticks vollständig da, die Landung folgt nach 48 Ticks. Größter Blendsprung 0.09 pro Tick. Kante gleich.
- Tests prüfen: kein Blendsprung über 0.2 pro Tick, Ebene 2 erscheint erst, wenn Ebene 1 mindestens zur Hälfte aufgelöst ist, Ebene 2 ist vor der Landung vollständig, Gegner der Ebene 2 werden nie vor ihrer Ebene sichtbar.

**Unverändert:** 12 Sturzschaden, 0.75 s Landeschutz, Luke nach dem Räumen, Gegner der Ebene 2 greifen ab der Landung an, Ebene-2-Sturz = Niederlage (Prototyp-Regeln wie in M2D.1).

**Nachweise M2D.2:** 81 Tests / 878 Checks grün. Gerenderte Zeitreihen bei 1280×720: Luke und Kante mittig senkrecht fallend, Ebene 1 zieht weg, Tiefe, Ebene 2 taucht auf. Video `qa/output/m2d2_descent_skip.avi` (nicht versioniert): Kantensprung, Übergang, Ebene-2-Kampf; der Skriptbot gewann diesmal mit nur 12 Schaden (Sturzschaden), timingabhängig. Die Renderläufe zeigen Controller-/Maus-Quellenwechsel durch echte Geräte am Rechner, ohne Einfluss auf die ausgewerteten Sequenzen.

## Stopp

Keine dritte Ebene, Run-Struktur, neue Gegnertypen, Upgrades oder Produktionsassets. Kein Commit/Push (Nutzerentscheidung: später gemeinsam).
