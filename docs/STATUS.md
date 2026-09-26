# Projektstatus

**Letzte Änderung:** 26.09.2026 · M3B (Floor Variety V1: sechs handgebaute Floor-Vorlagen, zufällige Auswahl pro Run) umgesetzt, nicht committet. M3A ist als `7550fea` auf GitHub (`main`).  
**Tatsächlicher Stand:** Spielbarer 3D-Blockout mit Dummy-Assets. Standardstart ist der Abstieg mit Run-Progression (M3A).
- **Zufällige Ebenen:** Jeder Run wählt zwei von sechs handgebauten Floor-Vorlagen. Ebene 1: Open Forge, Broken Corner, Central Pit, Twin Plates oder Cross Forge. Ebene 2: Central Pit, Twin Plates, Cross Forge oder Shattered Ring, nie zweimal dieselbe.
- **Gegner:** Die Gegner stehen auf kuratierten Slots der Vorlage, immer 2 Scraplings + 1 Funkenwerfer.
- **Luke und Sturz:** Die Luke liegt je Vorlage an einer geprüften Stelle. Beim Kantensturz fällt der Spieler weiterhin senkrecht; die verborgene nächste Ebene wird so ausgerichtet, dass ein Landing-Slot passend zur Absprungstelle darunter liegt.
- **Unverändert:** Kampf, XP/Stats/Upgrades, Sturzschaden und Landeschutz.
- **Weitere Szenarien:** Training, Duell, Gruppe und Mischkampf nutzen weiter die feste Testarena.

Automatisierte Tests und die skriptgesteuerte gerenderte Prüfung sind lokal bestanden. Nutzerabnahme offen für M2A–M3B. Berichte: `docs/reports/…`, zuletzt `M3B_REPORT.md`.

| Bereich | Stand |
|---|---|
| Aktueller Auftrag | M3B — Floor Variety V1 — implementiert, Nutzerabnahme offen, nicht committet |
| M0 | IMPLEMENTIERT |
| M1 / M1.1 | IMPLEMENTIERT — Controller-Teilabnahme: Bewegung, Dauerattacke, Hammer, Kanten positiv |
| M2A–M2C | IMPLEMENTIERT (Duell, Gruppe + Profile, Mischkampf) — Profil B und Schussprofil „Scharf“ bestätigt |
| M2D | IMPLEMENTIERT (zwei Ebenen, eine Ebene sichtbar, senkrechter Kantensturz) — committet `13981ee` |
| M3A | IMPLEMENTIERT (XP-Orbs, Level, Attribute, Floor-Clear-Upgrades) — committet `7550fea`, Nutzerabnahme offen |
| M3B | IMPLEMENTIERT — 6 Vorlagen (LOW/MEDIUM/HIGH), Validator, getrennter Floor-Zufall, Slot-Spawns, Landing-Slots, Luke je Vorlage — Nutzerabnahme offen |
| M4+ / Generator | NICHT FREIGEGEBEN (kein prozeduraler Generator, keine dritte Ebene, keine neuen Gegner, keine Relikte) |
| Art Vertical Slice | NICHT FREIGEGEBEN (Hammer dort als Zweihandwaffe vorgemerkt) |
| Godot-Version | 4.7.2.stable.official (ed1daf0bf), lokal `D:\Godot_v4.7.2-stable_win64.exe` |
| Renderer | Mobile (Vulkan 1.1 Forward Mobile, lokal auf Intel UHD 620 geprüft); kein Compatibility-Fallback |
| Physik | Jolt Physics, 60 Ticks/s, Gravity 18 m/s² |
| Hauptszene | `res://scenes/main.tscn` → Abstieg/Profil B/Schuss scharf; `-- --mode=descent|mixed|group|combat|training`, `-- --profile=a|b`, `-- --shot=standard|sharp` |
| Simulation | 3D, XZ-Bewegung, Y-Schwerkraft, `CharacterBody3D` |
| Kamera | Unverändert (Pitch 48°, Yaw 45°, FOV 30°); die Vorlagen sind für diese Kamera ausgelegt (Validator-Regel) |
| Runtime-Assets | Nur Godot-Primitiven + selbst geschriebene Shader; keine externen Assets |
| Produktionspipeline | Dokumentiert, nicht gestartet |
| Import/Parse | BESTANDEN (headless, ohne Fehler) |
| Verhaltenstests | BESTANDEN — 101 Tests / 1628 Checks (M1–M3A-Regressionen + 8 M3B-Tests) |
| Gerenderte Prüfung | BESTANDEN (skriptgesteuert) — `--qa-floors` (Shots/Zeitreihen 80–88) bei 1280×720, 1600×720, 1024×768; 30/60 FPS; alte Sequenzen (`--qa-run`, `--qa-descent`) auf Testvorlagen weiter grün |
| Offene Playtestbefunde | Trefferketten ohne Schutzfenster; überlappende Markierungen; Ebene 2 möglicherweise druckvoll; M3A-Balance offen; M3B: Kantensieg-Dominanz je Vorlage, Größe/Lesbarkeit auf Controller, 4:3 nach Landung auf Ebene 2 teils ein Gegner anfangs außerhalb |
| Rundenlog | `%APPDATA%\Godot\app_userdata\Project Fall\encounter_log.txt` (mit Floor-Vorlage) |
| Android-Test | OFFEN — kein Export eingerichtet, kein Gerät |
| Controller-Test | TEILWEISE — manuell bis M2C-Feedback; M2D–M3B nur simuliert |
| Nutzerabnahme | OFFEN (M2A–M3B) |

## Nächster Schritt

Manueller Spieltest nach `docs/reports/M3B_REPORT.md` („Nächster manueller Test“): mehrere Runs, früher Sturz, HIGH-Risk-Floor mit Knockback. Danach Commit nur auf Anweisung. **Kein Generator, kein M4, keine Assets ohne ausdrückliche Freigabe.**
