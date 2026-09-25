# Bericht: M2B — Gruppenkampf und Tempovergleich

Datum: 25.09.2026  
Umfang: ausschließlich M2B: Gruppenkampf gegen drei Scraplings, zwei Benommenheitsprofile, explizite Gegnerverwaltung, lokale Rundenzusammenfassung, Diagnoseskripte. Grundlage: Commit `5336e45` (M1.1 + M2A), lokal unverändert vorgefunden.  
Status: implementiert; automatisierte und skriptgesteuerte gerenderte Prüfungen bestanden  
Nutzerabnahme: **offen**. Automatisierte Ergebnisse sind keine Balance-Aussage.

## Startwege, Szenario- und Profilwahl

```powershell
cd D:\Project_Fall
$G = "D:\Godot_v4.7.2-stable_win64.exe"
& $G --path .                               # Gruppe (3 Scraplings), Profil A — Standard
& $G --path . -- --profile=b                # Gruppe, Profil B (kurze Benommenheit)
& $G --path . -- --mode=combat              # Duell (M2A), gleichwertig: --mode=duel
& $G --path . -- --mode=combat --profile=a  # Duell/Basis = M2A-Vergleichsbasis
& $G --path . -- --mode=training            # Training (M1)
& $G --path . -- --mode=group               # Gruppe explizit
```

Im Spiel (Touch, Maus, Controller), Pausemenü:
- **Szenario:** zyklisch Gruppe → Duell → Training.
- **Benommenheit:** Profil A ↔ B.
- **Kampf neu starten.**

Szenario- und Profilwechsel starten die Begegnung immer vollständig neu, also nie mitten in einem Angriff. Nach Sieg oder Niederlage bietet die Ergebnisanzeige „Neustart“ und „Szenario wechseln“ und zeigt die Rundenzusammenfassung. Die Moduszeile oben zeigt z. B. „GRUPPE · Gegner 2/3 · Profil A“.

**Rundenlog:** Jede Kampfrunde wird zusammengefasst, auch Spielerfall und Abbruch. Die Zusammenfassung erscheint in der Konsole und wird lokal angehängt an `%APPDATA%\Godot\app_userdata\Project Fall\encounter_log.txt`. Die Datei enthält bereits Einträge der automatisierten QA-Läufe dieses Auftrags; vor dem eigenen Test ggf. löschen.

## Änderungen gegenüber M2A

| Bereich | Änderung |
|---|---|
| Szenarien | `TrainingArena.Mode` um `GROUP` erweitert (Standardstart). `COMBAT` bleibt das Duell (M2A, unverändert), `TRAINING` unverändert. |
| Gegnerverwaltung | `enemies` (drei Instanzen derselben `scrapling.tscn`) und `active_enemies` (Teilnehmer). Sieg erst nach allen; Tod/Fall stoppt alle; Reset setzt alle zurück. Signale einmalig verbunden. |
| Startpositionen | Spieler zentral (0, −0.5); Gegner fest bei (4.8, −2.0), (−4.2, −2.0), (0.4, 3.7): ≈5.0 / 4.5 / 4.2 m entfernt, ≥1.3 m zur Kante, außerhalb der Angriffsreichweite, alle im Kamerabild. Keine Dummies. |
| Abstandshaltung | Nur in CHASE: Wegdrück-Vektor zu lebenden Nachbarn im Radius 1.6 m, addiert zur Laufabsicht. In Stopp-Distanz nur langsames seitliches Abrücken. Die Bodenprüfung gilt für die resultierende Richtung. Kein Teleport, keine Klemmung, keine Wirkung auf Knockback, Schwerkraft, Angriffe. Im Duell leer (wirkungslos). |
| Benommenheitsprofile | A = 0.40 s (Wert der Tuning-Ressource, Standard), B = 0.20 s. Gesetzt pro Instanz (`Scrapling.hit_stun`); die geteilte `scrapling_tuning.tres` bleibt unverändert (per Test geprüft). Sonst identisch. |
| Auswertung | `EncounterStats`: Szenario, Profil, Ergebnis (Sieg/Niederlage/Spielerfall/Abbruch), Dauer ohne Pausen, tatsächlicher HP-Verlust und Treffer, Siege per HP/Kante, gestartete Gegnerangriffe, davon ACTIVE, davon vor ACTIVE abgebrochen. Neue Signale `WeaponController.active_started` und `Scrapling.attack_interrupted` (nur Auswertung). |
| UI | Pausemenü: Szenario-Zyklus, Profil-Button. HUD: Szenario · Gegner x/3 · Profil. Debugzeile (F3): Zustand/Phase/Festlegung aller Gegner. Ergebnisanzeige mit Zusammenfassung. |

Unverändert: sämtliche Spielerwerte (Bewegung, Hammer 0.26/0.12/0.42, Faktor 1.0, Reichweite, Winkel, Knockback, Dodge), Gegnerangriff (0.55/0.12/0.85 s, Schaden 15, Reichweite/Winkel, Festlegung, Unterbrechung), HP 80, 2.6 m/s, Kamera, Plattform, Renderer, Physiktakt. Kein Hammer-Cooldown, keine Zielhilfe, kein Angriffsdirektor, keine Hyperarmor oder Unverwundbarkeit, keine Schadenslimits.

## Testergebnisse

Alle 56 Headless-Tests grün (582 Checks, Exitcode 0). Die M1/M1.1-Tests laufen im Training, die M2A-Tests ausdrücklich im Duell mit Profil A.

| Neue Prüfung | Befund |
|---|---|
| g1 drei eigenständige Gegner | 3 aktiv, je 2 Nachbarn, eigene Waffen; Start außerhalb der Reichweite, nicht an der Kante, im Kamerabild; Startdistanzen verschieden. In 6 s greift jeder eigenständig an (3/4/4 Angriffe); minimaler Gegnerabstand 1.95 m (keine Überlagerung). Duell: nur 1 Gegner, keine Nachbarn. |
| g2 Profile ohne Tuningteilung | A: alle 0.40 s; B: alle 0.20 s. Geteilte Ressource in allen Werten gleich der Datei; Gegnerangriff unverändert. Knockback-Strecke A = B = 0.94 m. Bei B handelt der Gegner mit 0.06 s Rest-Knockback wieder, bei A nicht. |
| g3 Mehrzieltreffer | Ein Hammerschlag trifft alle drei Gegner im Sektor, jeden genau einmal (je −20 HP). |
| g4 gleichzeitige Gegnertreffer | Drei Angriffe mit identischer `swing_id` 1 treffen im selben Tick. Drei getrennte Treffer (Quelle je Gegner), HP 100 → 85 → 70 → 55. |
| g5 Sieg erst nach allen, gemischt | Kein Sieg nach 1/3 und 2/3; HP-, Kanten- und HP-Kill mit anschließendem Fall ergeben 1 Sieg und Zusammenfassung HP 2 / Kante 1. Drei Niederlagen im selben Tick ergeben genau 1 Ergebnis. |
| g6 Tod/Fall/Reset/Szenario | Tod: alle Gegner stoppen, genau eine Niederlage-Zusammenfassung. Spielerfall: Zusammenfassung vor dem Reset, genau 1 Reset, keine Angriffe während des Falls. Nach Neustart alle am Start, volle HP, keine Effekte/Eingaben. Nach 3 Neustarts keine doppelten Signalverbindungen. Training deaktiviert alle Gegner. |
| g7 alte/abgebrochene Angriffe | Ein laufender Angriff verschwindet mit dem Neustart, danach kein Schaden. Von zwei gleichzeitigen Angriffen trifft nur der nicht unterbrochene; der Abbruch vor ACTIVE wird gezählt. |
| g8 Kante + Abstandshaltung | Der Nachbar drückt den Läufer zur Kante (Druck 0.68). Der Läufer bleibt auf der Plattform (max. x 6.31 < 6.5) und läuft trotzdem 3.1 m weiter. Hammertreffer Richtung Kante: Fall-Niederlage genau einmal. |
| g9 Spieler unverändert | Werte unverändert; Bewegung mit/ohne gehaltenes RT in der Gruppe identisch; 3 Swings in 2 s. |

Gerendert (skriptgesteuert, Intel UHD 620, Vulkan Mobile): 1280×720 @60 und @30, 1600×720 @60, 1024×768 @60. Render-FPS 60.6–61.0 bzw. 30.7–30.9 bei 61–63 Physikticks je Wandsekunde.
- **Gruppenstart:** alle drei Gegner aus drei Richtungen im Bild.
- **Zeitreihe** `30_group_fight_sheet.png` (40 Bilder / 4 s): Laufen, Zuschlagen, Gegner an der Kante, mehrere gleichzeitige Markierungen, Treffer.
- **Drei gleichzeitige Markierungen** und Treffer (HP 55).
- **Pause mit Szenario- und Profilwahl:** Profilwechsel per Klick übernommen.
- **Sieg** (2× HP, 1× Kante), **Niederlage mit Zusammenfassung**, **Spielerfall → Reset.**

**Gameplay-Aufnahme:** `qa/output/m2b_group_fight.avi` (1280×720, 7.6 s, Godot Movie Maker, keine Zusatzsoftware). Sie zeigt einen skriptgesteuerten Gruppenkampf (RT gehalten, kantenvorsichtig zum nächsten Gegner) mit dem Ergebnis Niederlage nach 6.1 s. Das ist kein menschliches Spiel.

## Diagnose: RT halten + Vorwärtslaufen (Skript, kein Spieler)

Strategie: RT dauerhaft, Stick zum nächsten lebenden Gegner, ab 1.3 m stehen bleiben. Jede Zeile beginnt mit identischem Neustart; nichts wurde nachjustiert.

| Szenario / Profil | Ergebnis |
|---|---|
| Duell / A | Sieg, 3.6 s, **0 Schaden**; 4 Gegnerangriffe, 0 ACTIVE, 4 vor ACTIVE abgebrochen |
| Duell / B | identisch zu A (Sieg, 3.6 s, 0 Schaden, 0/4 ACTIVE) |
| Gruppe / A (ohne Kantenvorsicht) | **Spielerfall** nach 3.1 s: Das Skript folgt einem zurückgestoßenen Gegner über die Kante |
| Gruppe / B (ohne Kantenvorsicht) | Spielerfall nach 3.2 s (gleiches Muster) |
| Gruppe / A (kantenvorsichtig) | Sieg, 8.1 s, 60 Schaden (4 Treffer); 10 Angriffe, 4 ACTIVE, 6 abgebrochen |
| Gruppe / B (kantenvorsichtig) | Sieg, 8.7 s, 75 Schaden (5 Treffer); 10 Angriffe, 5 ACTIVE, 5 abgebrochen |

Sensitivität (kantenvorsichtig, Spieler wartet vor dem ersten Drücken):

| Startverzögerung | 0 s | 0.25 s | 0.5 s | 0.8 s | 1.2 s |
|---|---|---|---|---|---|
| A | Sieg, 60 Schaden | Sieg, 75 | Sieg, 90 | Sieg, 75 | Niederlage (6.6 s) |
| B | Sieg, 75 | Sieg, 45 | Niederlage (4.7 s) | Sieg, 75 | Sieg, 90 |

Die Videoaufnahme (0.8 s Verzögerung, leicht anderer Eingabetakt) endete mit einer Niederlage.

Einordnung:
- Im Duell bleibt stures RT-Halten eine universelle, schadensfreie Lösung. Profil B ändert daran nichts: Der Gegner erreicht nie ACTIVE.
- In der Gruppe gewinnt dasselbe Skript meist, verliert aber 45–100 von 100 HP und gelegentlich die Runde. Gegnerangriffe erreichen ACTIVE (3–7 pro Runde), weil nicht alle drei gleichzeitig unterbrochen werden können. RT-Halten ist dort also nicht mehr kostenlos, aber nach dieser Diagnose auch nicht zuverlässig verlierend.
- Das Ergebnis reagiert stark auf kleine Timingunterschiede.
- Zwischen A und B zeigt die kleine Stichprobe (je 6 Läufe) keinen belastbaren Unterschied.
- Ob Umlaufen, Zielwechsel und Dodge besser abschneiden, kann ein Skript nicht beurteilen; das ist die offene Spieltestfrage.

## Beobachtungen

- **Überlagerung:** Die Abstandshaltung verhindert Stapeln (≥1.95 m im Test g1). Stehen alle drei eng um den Spieler, überlappen sich ihre Bodenmarkierungen stark (`31_group_three_telegraphs.png`). Welcher Gegner wohin schlägt, erkennt man dann vor allem an Körperpose, Auge und Waffe, weniger an der Markierung. Auch HP-Anzeigen der Figuren überlappen gelegentlich.
- **Angriffsdruck:** Mit drei Gegnern gibt es fast immer mindestens einen, der ausholt. In der Zeitreihe sieht man regelmäßig zwei gleichzeitige Ankündigungen.
- **Unterbrechungen:** Der Hammer unterbricht weiterhin jeden getroffenen Gegner. Treffer auf mehrere Gegner (g3) unterbrechen alle gleichzeitig; das ist ein starkes Werkzeug gegen Gruppen, wenn sie gebündelt stehen.
- **Trefferketten:** Drei gleichzeitige Treffer kosten 45 HP in einem Tick, ohne Schutzfenster. Der letzte Knockback überschreibt die vorherigen. Theoretisch sind 100 HP in ≈2 Gegnerzyklen verloren. In der Videoaufnahme 7 Treffer in 6.1 s. Kein Schutz eingebaut (nicht beauftragt); konkreter Playtestbefund: prüfen, ob sich das fair anfühlt.
- **Profil B:** Der Gegner beginnt wieder zu handeln, während 0.06–0.08 s Rest-Knockback wirken. Er gleitet dann kurz im Zustand CHASE; ein Angriffsstart während des Gleitens ist möglich. Die Darstellung zeigt dabei Laufen statt Treffer-Recoil.
- **Kamera:** unverändert. Alle drei Gegner starten im Bild; in 4:3 ist der seitliche Rand knapper. Kein Herauszoomen vorgenommen.
- **QA-Hinweis:** Die Rundenauswertung zählte zunächst eine HP-Rücksetzung als Schaden, wenn die Vorrunde künstlich über 100 HP lag (nur QA). Behoben: Die Auswertung wird jetzt nach dem Spieler-Reset angelegt.

## Offene Hardware- und Gefühlsfragen

- Alle Eingaben dieses Auftrags simuliert; kein Controller- oder Smartphone-Test.
- Ist die Gruppe lesbar genug, v. a. bei überlappenden Markierungen?
- Fühlen sich gleichzeitige Treffer fair an?
- Lohnt sich Bewegung/Dodge spürbar mehr als RT-Halten?
- Ist Profil B spürbar anders?
- Weiter offen aus M1/M2A: Smartphone/Android, Displays > 60 Hz, Kamera, Zweihandhammer.

## Manueller Test

1. Gruppe/Basis (`& $G --path .`): RT halten und schlicht vorwärtslaufen.
2. Gruppe/Basis: offensiv umlaufen, Ziele wechseln, dodgen (RT darf gehalten bleiben).
3. Pause → Benommenheit Profil B: dieselben Vorgehensweisen vergleichen.
4. Bei Bedarf Pause → Szenario Duell, Profil A, als Referenz.

Nach jeder Runde steht die Zusammenfassung in der Ergebnisanzeige und im Log.

## Stopp

Keine weiteren Gegnertypen, keine zweite Ebene, kein Abstieg, keine XP/Upgrades, keine finalen Assets, keine Kamera- oder Spieleränderung, kein Tuning außerhalb der Profile. Keine Installationen, kein Commit/Push.
