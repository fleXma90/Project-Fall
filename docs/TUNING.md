# Tuningstartwerte v0.2 — 3D Blockout

**Ungetestete Startwerte.** Cline darf sie innerhalb M1 begründet verändern und muss Abweichungen im Bericht nennen. Kernregeln wie keine Zielhilfe oder offene Kanten sind nicht durch Tuning aufhebbar.

Godot-Weltmaß: ungefähr Meter.

| Parameter | Startwert | Bedeutung |
|---|---:|---|
| Player max HP | 100 | M1 Resetbasis |
| Player visuelle Höhe | ~1.35 m | nur Placeholder-Richtwert |
| Laufgeschwindigkeit | 4.6 m/s | volle analoge Stärke |
| Beschleunigung | 24 m/s² | direkter Start |
| Abbremsung | 30 m/s² | kontrolliertes Stoppen |
| Gravity | Projektstandard / ca. 18 m/s² Start | fühlbarer kurzer Fall |
| Angriff-Bewegungsmultiplikator | 0.70 | Bewegung bleibt möglich |
| Stick-Deadzone | 0.18 | radial |
| Trigger an / aus | 0.35 / 0.20 | Hysterese |
| Inputbuffer | 0.10 s | keine lange Queue |
| Dodge-Dauer | 0.18 s | kontinuierlich |
| Dodge-Geschwindigkeit | 10.0 m/s | ca. 1.8 m nominell |
| Dodge-Cooldown | 0.70 s | Start-zu-Start |
| Dodge-iFrames | 0.02–0.14 s | kein Fallschutz |
| Hammer Windup | 0.14 s | lesbar |
| Hammer aktiv | 0.10 s | Hitfenster |
| Hammer Recovery | 0.28 s | Gesamt ~0.52 s |
| Hammer Schaden | 20 | pro Ziel/Swing einmal |
| Hammer Reichweite | 1.9 m | vom AttackOrigin |
| Hammer Winkel | 110° | kein Rundumtreffer |
| Knockback Start | 6.0 m/s | XZ-Impuls |
| Knockback Abklingzeit | 0.18 s | kein Teleport |
| Dummy HP | 100 | fünf Basistreffer |
| M1 Kill/Reset-Höhe | ca. 4–6 m unter Plattform | an Arenahöhe anpassen |
| Kamera Pitch | ~48° | Startwert |
| Kamera Yaw | ~45° | Startwert |
| Orthographic Size | ~15–18 m | falls orthografisch |
| Kamera Follow-Smoothing | ~8–12 1/s | ohne schwammiges Inputgefühl |

Ab M2: Sturzschaden und Landeschutz gemäß `FLOOR_RULES.md` neu abstimmen. VFX, Partikelmengen und Schattenqualität werden erst auf realer Smartphone-Hardware budgetiert.
