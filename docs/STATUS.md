# Projektstatus

**Letzte Änderung:** 25.09.2026 · M2C (Gemischter Kampf mit Funkenwerfer) umgesetzt  
**Tatsächlicher Stand:** Spielbarer 3D-Blockout mit Dummy-Assets. Standardstart ist der Mischkampf (zwei Scraplings + ein Funkenwerfer) mit Profil B. Gruppe (M2B), Duell (M2A) und Training (M1) sind per Szenariowahl erreichbar, Profil A/B per Pausemenü. Automatisierte Tests und skriptgesteuerte gerenderte Prüfung lokal bestanden. Nutzerfeedback: Bewegung, Stoppen, Dauerattacke, Hammer-Schwung und Kanten gefallen (nach M1.1); Profil B im Gruppenkampf bevorzugt (nach M2B) — keine vollständige Hardware- oder Balanceabnahme. M2A-, M2B- und M2C-Nutzerabnahme offen. Berichte: `docs/reports/M1_REPORT.md`, `M1_1_REPORT.md`, `M2A_REPORT.md`, `M2B_REPORT.md`, `M2C_REPORT.md`.

| Bereich | Stand |
|---|---|
| Aktueller Auftrag | M2C — Gemischter Kampf: zwei Scraplings und ein Funkenwerfer — implementiert, Nutzerabnahme offen |
| M0 | IMPLEMENTIERT |
| M1 / M1.1 | IMPLEMENTIERT — Controller-Teilabnahme: Bewegung, Dauerattacke, Hammer, Kanten positiv |
| M2A | IMPLEMENTIERT (Teilmeilenstein, Duell) — Nutzerabnahme offen |
| M2B | IMPLEMENTIERT (Teilmeilenstein, Gruppe + Profile) — Nutzerfeedback: Profil B bevorzugt |
| M2C | IMPLEMENTIERT (Teilmeilenstein, Mischkampf) — Nutzerabnahme offen |
| Restlicher M2 | NICHT FREIGEGEBEN (weitere Gegnertypen/-zahl, Bodenfallen, zweite Ebene, Sturzschaden, Abstieg) |
| M3+ | NICHT FREIGEGEBEN |
| Art Vertical Slice | NICHT FREIGEGEBEN (Hammer dort als Zweihandwaffe vorgemerkt) |
| Godot-Version | 4.7.2.stable.official (ed1daf0bf), lokal `D:\Godot_v4.7.2-stable_win64.exe` |
| Renderer | Mobile (Vulkan 1.1 Forward Mobile, lokal auf Intel UHD 620 geprüft); kein Compatibility-Fallback |
| Physik | Jolt Physics, 60 Ticks/s, Gravity 18 m/s² |
| Hauptszene | `res://scenes/main.tscn` → Gemischt/Profil B; `-- --mode=group|combat|training`, `-- --profile=a|b` |
| Simulation | 3D, XZ-Bewegung, Y-Schwerkraft, `CharacterBody3D` |
| Kamera | Unverändert: fest schräg (Pitch 48°, Yaw 45°), FOV 30°, weiches Folgen; Beurteilung zurückgestellt |
| Runtime-Assets | Nur Godot-Primitiven + selbst geschriebener Kachel-Shader; keine externen Assets |
| Produktionspipeline | Dokumentiert, nicht gestartet |
| Import/Parse | BESTANDEN (headless, ohne Fehler) |
| Verhaltenstests | BESTANDEN — 68 Tests / 669 Checks (M1–M2C, Diagnosen); Harness jetzt 16:9 und mit pausierbarer Hauptszene |
| Gerenderte Prüfung | BESTANDEN (skriptgesteuert) — 1280×720, 1600×720, 1024×768; 30/60 FPS bei 60 Physikticks; Aufnahme `qa/output/m2c_mixed_fight.avi` (nicht versioniert) |
| Diagnosebefund | Mischkampf/B: RT halten + nächster Gegner gewinnt im Skript mit 20 Schaden; „Schütze zuerst“ mit 55; timingabhängig (Aufnahme: Niederlage) |
| Offene Playtestbefunde | Trefferketten ohne Schutzfenster (Hieb + Bolzen 25 HP in 3 Ticks; letzter Knockback überschreibt); überlappende Markierungen bei engen Gruppen; Kamerabild-Regel des Schützen abhängig vom Seitenverhältnis |
| Rundenlog | `%APPDATA%\Godot\app_userdata\Project Fall\encounter_log.txt` (automatisierte Läufe gekennzeichnet) |
| Android-Test | OFFEN — kein Export eingerichtet, kein Gerät |
| Controller-Test | TEILWEISE — manuell bis M2B-Feedback; M2C nur simuliert geprüft |
| Nutzerabnahme | OFFEN (M2A, M2B, M2C) |

## Nächster Schritt

Controller-Spieltest nach `docs/reports/M2C_REPORT.md` („Manueller Spieltest“): Scraplings zuerst, Schüssen ausweichen, Schütze zuerst, Kanten beachten, Vergleich mit der Gruppe. Danach Entscheidung über Lesbarkeit, Trefferketten und weitere Freigaben. **Kein weiterer M2-Umfang ohne ausdrückliche Freigabe.**
