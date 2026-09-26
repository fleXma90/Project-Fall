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

### Schussprofile des Funkenwerfers (M2C-Nachtrag nach Nutzerfeedback „zu leicht auszuweichen“)

| Wert | Standard (Ressource) | Scharf (Testprofil, **aktueller Standardstart**) |
|---|---:|---:|
| Aufladen gesamt | 0.65 s | 0.70 s |
| Richtungsfestlegung | 0.45 s | 0.55 s |
| Zeit Festlegung → Schuss | 0.20 s | 0.15 s |
| Bolzentempo | 6 m/s | 11 m/s |
| Gemessenes Reaktionsfenster bei 5 m (spätestes seitliches Loslaufen nach der Festlegung) | 0.6 s | 0.3 s |

Scharf ist eine Laufzeitkopie der Ressource (`TrainingArena.sharp_*`); alle anderen Werte (Schaden, Radius, Lebensdauer, Knockback, HP, Tempo) sind identisch. Wechsel nur mit Neustart.

## Abstieg (M2D, Playtest-Startwerte)

| Wert | Start | Ort |
|---|---:|---|
| Höhenunterschied Ebene 1 → Ebene 2 | 10 m | `LowerFloor` in `training_arena.tscn` |
| Sturzschaden (Kante) | 12 % max HP, mind. 1 (= 12) | `TrainingArena.fall_damage_fraction` |
| Sturzschaden (Luke) | 0 | — |
| Landeschutz gegen Kampftreffer | 0.75 s | `TrainingArena.landing_protection` |
| Landepunkt: Boden ringsum / Abstand zu Gegnern | 1.2 m / 3 m | `landing_edge_margin` / `landing_enemy_clearance` |
| Ebene 1 verlassen ab | 0.6 m unter der Oberkante | `descent_leave_height` |
| Abklingen der Horizontalen nach dem Verlassen (M2D.2) | Zeitkonstante 0.12 s (≈0.5 m Restweg beim Laufen) | `fall_settle_time` |
| Killhöhe Gegner Ebene 1 im Abstieg | −3 m | `upper_enemy_kill_height` |
| Killhöhe Ebene 2 | 5 m unter Ebene 2 | `lower_kill_depth` |
| Luke | 2 × 2 m | `DescentHatch.size` |
| Übergang (nach Fallfortschritt 0..1): Ebene 1 auflösen / Aufsteigen / Ebene 2 einblenden | 0.05–0.5 / bis 6 m / 0.35–0.8 | `upper_fade_range` / `upper_rise` / `lower_reveal_range` (nur Darstellung) |
| Tiefenschein | Intensität 0.045, 18 m unter der Ebene; 70 Funken | `depth_glow.gdshader`, `DepthBackdrop` |
| Ebene 2 | 17 × 14 m mit Schacht 5 × 4 m | `LowerFloor.rects` |

Gegnerwerte auf Ebene 2 sind identisch mit Ebene 1 (Profil B, Schussprofil wie gewählt). Sturzschaden und Landeschutz sind Startwerte, nicht final.

## Run-Progression (M3A, Prototypwerte)

| Wert | Start | Ort |
|---|---:|---|
| XP Scrapling / Funkenwerfer | 30 / 40 | `TrainingArena.scrapling_xp` / `sparker_xp` |
| XP je Orb | höchstens 10 | `xp_per_orb` |
| Level-Schwelle | 60 + 30 · (Level − 1) | `RunState.xp_to_next` |
| Magnetradius / Einsammeln / Anziehung | 2.2 m / 0.55 m / 2 → 16 m/s, 22 m/s² (Sog ×3/×1.5) | `XpOrb` |
| Upgrade-Auswahl nach Clear | 0.8 s, höchstens 1.6 s (Orbs) | `reward_delay` / `reward_max_delay` |
| Attribute je Rang (max. 8) | Stärke +5 %, Vitalität +10 HP, Tempo +3 %, Beweglichkeit +2.5 %, Wucht +6 %, Erholung −4 % | `RunState` |
| Upgrades | Hammerkopf ×1.15, Einschlag ×1.30, Bogen +25°, Reichweite +0.25 m, Momentum ×1.2 für 1.5 s, Dodge −0.20 s | `RunState` |

Details, Berechnungsreihenfolge und offene Balancefragen: `RUN_PROGRESSION.md`. Die Basisressourcen (`player_tuning.tres`, `hammer.tres`) bleiben unverändert.

Ab M2: VFX-Budget weiterhin offen. VFX, Partikelmengen und Schattenqualität werden erst auf realer Smartphone-Hardware budgetiert.
