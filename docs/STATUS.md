# Projektstatus

**Letzte Änderung:** 25.09.2026 · M0 + M1 umgesetzt  
**Tatsächlicher Stand:** Spielbarer 3D-Gameplay-Blockout mit Dummy-Assets. Automatisierte Verhaltenstests und skriptgesteuerte gerenderte Prüfung lokal bestanden; Hardware- und Nutzerabnahme offen. Bericht: `docs/reports/M1_REPORT.md`.

| Bereich | Stand |
|---|---|
| Aktueller Auftrag | M0 + M1 (Startauftrag) — umgesetzt, wartet auf Nutzer-Playtest |
| M0 | IMPLEMENTIERT |
| M1 | IMPLEMENTIERT — Nutzerabnahme offen |
| M2+ | NICHT FREIGEGEBEN |
| Art Vertical Slice | NICHT FREIGEGEBEN |
| Godot-Version | 4.7.2.stable.official (ed1daf0bf), lokal `D:\Godot_v4.7.2-stable_win64.exe` |
| Renderer | Mobile (Vulkan 1.1 Forward Mobile, lokal auf Intel UHD 620 geprüft); kein Compatibility-Fallback |
| Physik | Jolt Physics, 60 Ticks/s, Gravity 18 m/s² |
| Hauptszene | `res://scenes/main.tscn` → Trainingsarena direkt |
| Simulation | 3D, XZ-Bewegung, Y-Schwerkraft, `CharacterBody3D` |
| Kamera | Fest schräg (Pitch 48°, Yaw 45°), schwache Perspektive FOV 30°, weiches Folgen |
| Runtime-Assets | Nur Godot-Primitiven + selbst geschriebener Kachel-Shader; keine externen Assets |
| Produktionspipeline | Dokumentiert, nicht gestartet |
| Import/Parse | BESTANDEN (headless, ohne Fehler) |
| Verhaltenstests | BESTANDEN — 22 Tests / 122 Checks (`tests/test_runner.tscn`) |
| Gerenderte Prüfung | BESTANDEN (automatisiert) — 1280×720, 1600×720, 1024×768; 30/60 FPS bei 60 Physikticks. Keine manuelle Spielsession |
| Android-Test | OFFEN — kein Export eingerichtet, kein Gerät |
| Controller-Test | OFFEN — nur simulierte Events |
| Nutzerabnahme | OFFEN |

## Nächster Schritt

Nutzer-Playtest nach `docs/PLAYTEST_CHECKLIST.md` (M1, fünf Minuten) auf Desktop, möglichst mit Controller; danach Befunde als M1-Korrektur oder Freigabe für M2 bzw. Android-Export. **Kein M2 ohne ausdrückliche Freigabe.**
