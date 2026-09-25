# Tuningstartwerte v0.2 — 3D Blockout

**Startwerte; fett markierte Werte wurden in M1/M1.1 begründet geändert** (Details: `docs/reports/M1_REPORT.md`, `docs/reports/M1_1_REPORT.md`). Cline darf sie innerhalb M1 begründet verändern und muss Abweichungen im Bericht nennen. Kernregeln wie keine Zielhilfe oder offene Kanten sind nicht durch Tuning aufhebbar.

Godot-Weltmaß: ungefähr Meter.

| Parameter | Startwert | Bedeutung |
|---|---:|---|
| Player max HP | 100 | M1 Resetbasis |
| Player visuelle Höhe | ~1.35 m | nur Placeholder-Richtwert |
| Laufgeschwindigkeit | 4.6 m/s | volle analoge Stärke |
| Beschleunigung | 24 m/s² | direkter Start |
| Abbremsung | 30 m/s² | kontrolliertes Stoppen |
| Gravity | Projektstandard / ca. 18 m/s² Start | fühlbarer kurzer Fall |
| Angriff-Bewegungsmultiplikator | **1.0** (M1.1; vorher 0.70) | Bewegung bei gehaltenem Angriff unverändert |
| Stick-Deadzone | 0.18 | radial |
| Trigger an / aus | 0.35 / 0.20 | Hysterese |
| Inputbuffer | 0.10 s | keine lange Queue |
| Dodge-Dauer | 0.18 s | kontinuierlich |
| Dodge-Geschwindigkeit | 10.0 m/s | ca. 1.8 m nominell |
| Dodge-Cooldown | 0.70 s | Start-zu-Start |
| Dodge-iFrames | 0.02–0.14 s | kein Fallschutz |
| Hammer Windup | **0.26 s** (M1.1; vorher 0.14) | sichtbares Ausholen, Richtung folgt noch der Ausrichtung |
| Hammer aktiv | **0.12 s** (M1.1; vorher 0.10) | Hitfenster, Richtung fixiert |
| Hammer Recovery | **0.42 s** (M1.1; vorher 0.28) | Gesamtzyklus 0.80 s (vorher 0.52) |
| Hammer Schaden | 20 | pro Ziel/Swing einmal |
| Hammer Reichweite | 1.9 m | vom AttackOrigin |
| Hammer Winkel | 110° | kein Rundumtreffer |
| Knockback Start | **8.0 m/s** (M1; Start 6.0) | XZ-Impuls, ≈1,05 m pro Treffer |
| Knockback Abklingzeit | **0.28 s** (M1; Start 0.18) | kein Teleport |
| Dummy HP | 100 | fünf Basistreffer |
| M1 Kill/Reset-Höhe | ca. 4–6 m unter Plattform | an Arenahöhe anpassen |
| Kamera Pitch | ~48° | Startwert |
| Kamera Yaw | ~45° | Startwert |
| Orthographic Size | ~15–18 m | falls orthografisch |
| Kamera Follow-Smoothing | ~8–12 1/s | ohne schwammiges Inputgefühl |

## Scrapling (M2A, Playtest-Startwerte)

| Parameter | Wert | Bedeutung |
|---|---:|---|
| HP | 80 | vier Hammertreffer |
| Laufgeschwindigkeit | 2.6 m/s | Beschleunigung 14, Abbremsen 20 m/s² |
| Drehschärfe Verfolgen / Windup | 7 / 5 1/s | Windup nur bis zur Festlegung |
| Festlegung | 55 % des Windups (≈0.30 s) | danach kein Nachdrehen |
| Angriffsstart / Stopp-Distanz | 1.45 / 1.2 m | Mittelpunkt zu Mittelpunkt; Start nur, wenn Spieler ≤ 35° vor ihm |
| Windup / Active / Recovery | 0.55 / 0.12 / 0.85 s | Zyklus 1.52 s |
| Schaden | 15 | gegen 100 Spieler-HP |
| Reichweite / Winkel / Höhe | 1.2 m / 100° / 1.2 m | Reichweite bis Zieloberfläche; passt zum ≈0.6-m-Hackmesser am 0.38-m-Arm |
| Knockback auf Spieler | 5.5 m/s über 0.22 s | ≈0.6 m, Spieler 0.22 s im Zustand HIT |
| Trefferreaktion nach Hammertreffer | 0.4 s | kein Angriff, keine Verfolgung |
| Bodenprüfung | 0.55 m vor dem Körper | nur Laufentscheidung |

Spielerwerte (Hammer, Bewegung, Dodge) sind in M2A und M2B unverändert.

## M2B: Benommenheitsprofile und Gruppe

| Parameter | Wert | Bedeutung |
|---|---:|---|
| Profil A (Basis) | 0.40 s | Wert aus `scrapling_tuning.tres`; für alte Tests und Vergleiche |
| Profil B (kurz, **seit M2C Standard-Arbeitsstand**) | 0.20 s | `TrainingArena.short_hit_stun`; wird pro Gegnerinstanz gesetzt, die geteilte Ressource bleibt unverändert |
| Abstandshaltung Radius / Stärke | 1.6 m / 1.2 | nur CHASE, nur zu lebenden Gegnern derselben Begegnung; im Duell wirkungslos |
| Gruppenstart Spieler | (0, 0, −0.5) | zentral |
| Gruppenstart Gegner A / B / C | (4.8, −2.0) / (−4.2, −2.0) / (0.4, 3.7) | ≈5.0 / 4.5 / 4.2 m zum Spieler, ≥1.3 m zur Kante |

Zwischen A und B unterscheidet sich ausschließlich die Benommenheit. Der Knockback (8 m/s über 0.28 s) bleibt gleich; bei B handelt der Gegner schon wieder, während noch ≈0.06–0.08 s Rest-Knockback wirken.

## Funkenwerfer und Energiebolzen (M2C, Playtest-Startwerte)

Werte in `resources/tuning/sparker_tuning.tres`.

| Parameter | Wert | Bedeutung |
|---|---:|---|
| HP | 60 | drei Hammertreffer |
| Laufgeschwindigkeit | 2.0 m/s | Beschleunigung 12, Abbremsen 18 m/s² |
| Schussdistanz (Beginn des Aufladens) | bis 6.0 m | nur im Kamerabild und auf dem Boden |
| Mindestannäherung | 1.5 m | darunter läuft er nicht weiter heran, flieht aber nicht |
| Aufladen / Festlegung / Erholung | 0.65 / 0.45 / 1.00 s | nach der Festlegung 0.20 s deutlich sichtbar, dann genau ein Schuss |
| Trefferbenommenheit | 0.20 s | unabhängig vom Scrapling-Profil |
| Körper/Trefferradius | Kapsel r 0.40 m, h 1.1 m | Kapsel wie Spieler/Scrapling, keine Kantenstütze |
| Mündung | 0.85 m hoch, 0.62 m vor dem Körper | |
| Bolzen: Tempo / Schaden / Radius | 6 m/s / 10 / 0.13 m | sichtbarer Kern = Kollisionsradius, Halo 0.24 m |
| Bolzen: Lebensdauer | 2.5 s | etwa 15 m Flugweite |
| Bolzen: Knockback | 3 m/s über 0.15 s | etwa 0.2 m, Spieler 0.15 s im Zustand HIT |
| Abstandshaltung | 1.6 m / 1.2 | wie Scrapling, gegenseitig zwischen allen Gegnern |

Ab M2: Sturzschaden und Landeschutz gemäß `FLOOR_RULES.md` neu abstimmen. VFX, Partikelmengen und Schattenqualität werden erst auf realer Smartphone-Hardware budgetiert.
