# Projektstatus

**Letzte Änderung:** 25.09.2026 · M2D + M2D.1 + M2D.2 (zweite Ebene; eine Ebene sichtbar; senkrechter Kantensturz, fließender Übergang) umgesetzt, nicht committet  
**Tatsächlicher Stand:** Spielbarer 3D-Blockout mit Dummy-Assets. Standardstart ist der Abstieg: Ebene 1 Mischkampf (zwei Scraplings + ein Funkenwerfer), nach dem Räumen eine Luke zur Ebene 2 (ohne Schaden), Sturz über die Kante jederzeit mit 12 Sturzschaden; Ebene 2 = Ring um einen Schacht mit erneutem Mischkampf, Sturz dort = Niederlage. Profil B, Schuss scharf. Mischkampf (M2C), Gruppe (M2B), Duell (M2A) und Training (M1) sind per Szenariowahl erreichbar. Automatisierte Tests und skriptgesteuerte gerenderte Prüfung lokal bestanden. Nutzerfeedback: Bewegung, Stoppen, Dauerattacke, Hammer-Schwung und Kanten gefallen (nach M1.1); Profil B im Gruppenkampf bevorzugt (nach M2B) — keine vollständige Hardware- oder Balanceabnahme. M2A-, M2B-, M2C- und M2D-Nutzerabnahme offen. Berichte: `docs/reports/M1_REPORT.md`, `M1_1_REPORT.md`, `M2A_REPORT.md`, `M2B_REPORT.md`, `M2C_REPORT.md`, `M2D_REPORT.md`.

| Bereich | Stand |
|---|---|
| Aktueller Auftrag | M2D — Zweite Ebene (Luke nach dem Räumen, Sturz mit Sturzschaden, Ebene 2 mit Schacht) — implementiert, Nutzerabnahme offen, **nicht committet** (Commit später gemeinsam) |
| M0 | IMPLEMENTIERT |
| M1 / M1.1 | IMPLEMENTIERT — Controller-Teilabnahme: Bewegung, Dauerattacke, Hammer, Kanten positiv |
| M2A | IMPLEMENTIERT (Teilmeilenstein, Duell) — Nutzerabnahme offen |
| M2B | IMPLEMENTIERT (Teilmeilenstein, Gruppe + Profile) — Nutzerfeedback: Profil B bevorzugt |
| M2C | IMPLEMENTIERT (Teilmeilenstein, Mischkampf) — Nutzerfeedback: Schussprofil „Scharf“ bestätigt |
| M2D | IMPLEMENTIERT (Teilmeilenstein, zwei Ebenen) + M2D.1 Präsentation (eine Ebene sichtbar, Tiefe) + M2D.2 (senkrechter Kantensturz, an die Fallhöhe gekoppelte Überblendung) — Nutzerabnahme offen |
| Restlicher M2 | NICHT FREIGEGEBEN (weitere Gegnertypen/-zahl, Bodenfallen, dritte Ebene, Run-Struktur) |
| M3+ | NICHT FREIGEGEBEN |
| Art Vertical Slice | NICHT FREIGEGEBEN (Hammer dort als Zweihandwaffe vorgemerkt) |
| Godot-Version | 4.7.2.stable.official (ed1daf0bf), lokal `D:\Godot_v4.7.2-stable_win64.exe` |
| Renderer | Mobile (Vulkan 1.1 Forward Mobile, lokal auf Intel UHD 620 geprüft); kein Compatibility-Fallback |
| Physik | Jolt Physics, 60 Ticks/s, Gravity 18 m/s² |
| Hauptszene | `res://scenes/main.tscn` → Abstieg/Profil B/Schuss scharf; `-- --mode=descent|mixed|group|combat|training`, `-- --profile=a|b`, `-- --shot=standard|sharp` |
| Simulation | 3D, XZ-Bewegung, Y-Schwerkraft, `CharacterBody3D` |
| Kamera | Unverändert: fest schräg (Pitch 48°, Yaw 45°), FOV 30°, weiches Folgen; im Abstieg folgt sie nur zusätzlich bis Ebene 2 nach unten |
| Runtime-Assets | Nur Godot-Primitiven + selbst geschriebener Kachel-Shader; keine externen Assets |
| Produktionspipeline | Dokumentiert, nicht gestartet |
| Import/Parse | BESTANDEN (headless, ohne Fehler) |
| Verhaltenstests | BESTANDEN — 81 Tests / 878 Checks (M1–M2D.2 inkl. Schussprofil „Scharf“, Abstieg, Übergang, senkrechter Kantensturz, Diagnosen) |
| Gerenderte Prüfung | BESTANDEN (skriptgesteuert) — 1280×720, 1600×720, 1024×768; 30/60 FPS bei 60 Physikticks; Aufnahme `qa/output/m2d2_descent_skip.avi` (nicht versioniert) |
| Diagnosebefund | Mischkampf/B: RT halten + nächster Gegner timingabhängig; im Abstieg verlor der Skriptbot auf Ebene 1 und nach Kantensprung auf Ebene 2 (Zangenangriff um den Schacht) |
| Nutzerfeedback M2C | Funkenwerfer verständlich, aber zu leicht auszuweichen → Schussprofil „Scharf“ (Festlegung 0.55/0.70 s, Bolzen 11 m/s) als Standardstart, „Standard“ wählbar; Reaktionsfenster bei 5 m: 0.6 s → 0.3 s |
| Offene Playtestbefunde | Trefferketten ohne Schutzfenster; überlappende Markierungen bei engen Gruppen; Kamerabild-Regel des Schützen abhängig vom Seitenverhältnis; M2D: Überspringen von Ebene 1 kostet nur 12 HP (Prototypwert, Bewertung mit M3-Belohnung); Ebene 2 möglicherweise druckvoll (Fallführung durch senkrechten Fall ersetzt, M2D.2) |
| Rundenlog | `%APPDATA%\Godot\app_userdata\Project Fall\encounter_log.txt` (automatisierte Läufe gekennzeichnet) |
| Android-Test | OFFEN — kein Export eingerichtet, kein Gerät |
| Controller-Test | TEILWEISE — manuell bis M2C-Feedback; M2D nur simuliert geprüft |
| Nutzerabnahme | OFFEN (M2A, M2B, M2C, M2D) |

## Nächster Schritt

Controller-Spieltest nach `docs/reports/M2D_REPORT.md` („Nächster manueller Test“, Nachtrag M2D.2): Luke, Kantensturz, Übergang, Ebene 2, Schacht. Danach Commit (Nutzerentscheidung: gemeinsam mit der zweiten Ebene, nur auf Anweisung) und Entscheidung über Belohnung fürs Räumen, Trefferketten und weitere Freigaben. **Kein weiterer Umfang ohne ausdrückliche Freigabe.**
