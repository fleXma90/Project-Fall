# Projektstatus

**Letzte Änderung:** 25.09.2026 · M2A (erste aktive Kampfbegegnung) umgesetzt  
**Tatsächlicher Stand:** Spielbarer 3D-Blockout mit Dummy-Assets. Standardstart ist eine Kampfbegegnung gegen einen Scrapling; der M1-Trainingsmodus ist per Moduswahl erreichbar. Automatisierte Tests und skriptgesteuerte gerenderte Prüfung lokal bestanden. Nutzerfeedback nach M1.1 (Controller): Bewegung, Stoppen, Dauerattacke, Hammer-Schwung und Kanten gefallen; Kamera wird später beurteilt. M2A-Nutzerabnahme offen. Berichte: `docs/reports/M1_REPORT.md`, `M1_1_REPORT.md`, `M2A_REPORT.md`.

| Bereich | Stand |
|---|---|
| Aktueller Auftrag | M2A — erste aktive Kampfbegegnung — implementiert, Nutzerabnahme offen |
| M0 | IMPLEMENTIERT |
| M1 / M1.1 | IMPLEMENTIERT — Controller-Teilabnahme: Bewegung, Dauerattacke, Hammer, Kanten positiv |
| M2A | IMPLEMENTIERT (begrenzter Teilmeilenstein) — Nutzerabnahme offen |
| Restlicher M2 | NICHT FREIGEGEBEN (mehrere Gegner, zweite Ebene, Sturzschaden, Abstieg) |
| M3+ | NICHT FREIGEGEBEN |
| Art Vertical Slice | NICHT FREIGEGEBEN (Hammer dort als Zweihandwaffe vorgemerkt) |
| Godot-Version | 4.7.2.stable.official (ed1daf0bf), lokal `D:\Godot_v4.7.2-stable_win64.exe` |
| Renderer | Mobile (Vulkan 1.1 Forward Mobile, lokal auf Intel UHD 620 geprüft); kein Compatibility-Fallback |
| Physik | Jolt Physics, 60 Ticks/s, Gravity 18 m/s² |
| Hauptszene | `res://scenes/main.tscn` → Kampfbegegnung (`-- --mode=training` startet das Training) |
| Simulation | 3D, XZ-Bewegung, Y-Schwerkraft, `CharacterBody3D` |
| Kamera | Unverändert: fest schräg (Pitch 48°, Yaw 45°), FOV 30°, weiches Folgen; Beurteilung zurückgestellt |
| Runtime-Assets | Nur Godot-Primitiven + selbst geschriebener Kachel-Shader; keine externen Assets |
| Produktionspipeline | Dokumentiert, nicht gestartet |
| Import/Parse | BESTANDEN (headless, ohne Fehler) |
| Verhaltenstests | BESTANDEN — 40 Tests / 335 Checks (M1, M1.1, M2A; `tests/test_runner.tscn`) |
| Gerenderte Prüfung | BESTANDEN (skriptgesteuert) — 1280×720, 1600×720, 1024×768; 30/60 FPS bei 60 Physikticks; Kampfsequenz und Zeitreihen in `qa/output/` (nicht versioniert) |
| Bekannter Playtestbefund | Dauerschlagen unterbricht den Scrapling dauerhaft (simuliert: Sieg nach 3,6 s ohne Gegnertreffer) — bewusst nicht ausgeglichen, Entscheidung offen |
| Android-Test | OFFEN — kein Export eingerichtet, kein Gerät |
| Controller-Test | TEILWEISE — manuell bis M1.1; M2A nur simuliert geprüft |
| Nutzerabnahme | OFFEN (M2A) |

## Nächster Schritt

Controller-Spieltest der Kampfbegegnung nach `docs/reports/M2A_REPORT.md` („Nächster Controller-Spieltest“) bzw. `docs/PLAYTEST_CHECKLIST.md` (Abschnitt M2A), insbesondere Lesbarkeit des Gegner-Windups und Dauerschlagen. Danach Entscheidung über Balance-Anpassungen oder weitere Freigaben. **Kein weiterer M2-Umfang ohne ausdrückliche Freigabe.**
