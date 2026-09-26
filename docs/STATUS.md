# Projektstatus

**Letzte Änderung:** 26.09.2026 · M3A (Run-Progression: XP-Orbs, Level, Attribute, Floor-Clear-Upgrades) umgesetzt, nicht committet. M2D–M2D.2 sind als `13981ee` auf GitHub (`main`).  
**Tatsächlicher Stand:** Spielbarer 3D-Blockout mit Dummy-Assets. Standardstart ist der Abstieg, erstmals mit Run-Progression.
- **Ebene 1:** Mischkampf (zwei Scraplings + ein Funkenwerfer). Besiegte Gegner werfen sichtbare XP-Orbs ab, die man in der Nähe einsammelt. Level-Ups kommen live ohne Pause und geben je 1 Attributspunkt; der Spieler verteilt die Punkte selbst im Stats-Screen (6 Attribute).
- **Räumen oder Springen:** Ist Ebene 1 geräumt, folgt eine Pflichtauswahl 1 aus 3 Run-Upgrades, danach öffnet sich die Luke. Ein früher Sturz über die Kante behält den Fortschritt, gibt aber kein Upgrade und kostet 12 Sturzschaden.
- **Ebene 2:** Ring um einen Schacht, erneut Mischkampf. Ein Sturz dort ist eine Niederlage, der Neustart beginnt einen komplett neuen Run.
- **Weitere Szenarien:** Mischkampf (M2C), Gruppe (M2B), Duell (M2A) und Training (M1) bleiben per Szenariowahl erreichbar und laufen ohne Run-Progression.

Automatisierte Tests und die skriptgesteuerte gerenderte Prüfung sind lokal bestanden. Nutzerabnahme offen für M2A–M2D und M3A. Berichte: `docs/reports/M1_REPORT.md` … `M2D_REPORT.md`, `M3A_REPORT.md`.

| Bereich | Stand |
|---|---|
| Aktueller Auftrag | M3A — Run-Progression V1 — implementiert, Nutzerabnahme offen, nicht committet |
| M0 | IMPLEMENTIERT |
| M1 / M1.1 | IMPLEMENTIERT — Controller-Teilabnahme: Bewegung, Dauerattacke, Hammer, Kanten positiv |
| M2A | IMPLEMENTIERT (Teilmeilenstein, Duell) — Nutzerabnahme offen |
| M2B | IMPLEMENTIERT (Teilmeilenstein, Gruppe + Profile) — Nutzerfeedback: Profil B bevorzugt |
| M2C | IMPLEMENTIERT (Teilmeilenstein, Mischkampf) — Nutzerfeedback: Schussprofil „Scharf“ bestätigt |
| M2D | IMPLEMENTIERT (zwei Ebenen) + M2D.1 (eine Ebene sichtbar) + M2D.2 (senkrechter Kantensturz, fließender Übergang) — committet `13981ee` |
| M3A | IMPLEMENTIERT — XP-Orbs (Nutzerwunsch), Level, 6 Attribute, Stats-Screen, Floor-Clear-Upgrade 1 aus 3 (6er-Pool), Run-Lebenszyklus — Nutzerabnahme offen |
| M3B+ / Floor-Variety | NICHT FREIGEGEBEN (keine dritte Ebene, keine Generatoren, keine Relikte) |
| Art Vertical Slice | NICHT FREIGEGEBEN (Hammer dort als Zweihandwaffe vorgemerkt) |
| Godot-Version | 4.7.2.stable.official (ed1daf0bf), lokal `D:\Godot_v4.7.2-stable_win64.exe` |
| Renderer | Mobile (Vulkan 1.1 Forward Mobile, lokal auf Intel UHD 620 geprüft); kein Compatibility-Fallback |
| Physik | Jolt Physics, 60 Ticks/s, Gravity 18 m/s² |
| Hauptszene | `res://scenes/main.tscn` → Abstieg/Profil B/Schuss scharf; `-- --mode=descent|mixed|group|combat|training`, `-- --profile=a|b`, `-- --shot=standard|sharp` |
| Simulation | 3D, XZ-Bewegung, Y-Schwerkraft, `CharacterBody3D` |
| Kamera | Unverändert: fest schräg (Pitch 48°, Yaw 45°), FOV 30°, weiches Folgen; im Abstieg folgt sie bis Ebene 2 nach unten |
| Runtime-Assets | Nur Godot-Primitiven + selbst geschriebene Shader (Kacheln, Tiefenschein); keine externen Assets |
| Produktionspipeline | Dokumentiert, nicht gestartet |
| Import/Parse | BESTANDEN (headless, ohne Fehler) |
| Verhaltenstests | BESTANDEN — 93 Tests / 1035 Checks (M1–M2D.2-Regressionen + 12 M3A-Tests) |
| Gerenderte Prüfung | BESTANDEN (skriptgesteuert) — M3A-Sequenz 65–76 bei 1280×720, 1600×720, 1024×768; 30/60 FPS bei 60 Physikticks |
| Diagnosebefund | Mischkampf/B: RT halten + nächster Gegner timingabhängig; im Abstieg verlor der Skriptbot teils auf Ebene 1/2 |
| Offene Playtestbefunde | Trefferketten ohne Schutzfenster; überlappende Markierungen bei engen Gruppen; Kamerabild-Regel des Schützen abhängig vom Seitenverhältnis; Ebene 2 möglicherweise druckvoll; M3A-Balance offen (XP-Kurve, 12 Sturzschaden vs. Clear-Belohnung, Magnetradius, Tempo/Erholung-Obergrenzen) |
| Rundenlog | `%APPDATA%\Godot\app_userdata\Project Fall\encounter_log.txt` (automatisierte Läufe gekennzeichnet) |
| Android-Test | OFFEN — kein Export eingerichtet, kein Gerät |
| Controller-Test | TEILWEISE — manuell bis M2C-Feedback; M2D und M3A nur simuliert geprüft (View/Back, Fokus) |
| Nutzerabnahme | OFFEN (M2A, M2B, M2C, M2D, M3A) |

## Nächster Schritt

Manueller Spieltest nach `docs/reports/M3A_REPORT.md` („Nächster manueller Test“): XP-Orbs und Live-Level-Up, Punkte sparen und im Kampf verteilen, Floor-Upgrade vor der Luke, neuer Run auf Basis, früher Sturz ohne Upgrade. Danach Commit nur auf Anweisung. **Kein M3B, keine Floor-Variety, keine Relikte ohne ausdrückliche Freigabe.**
