# Meilensteine und Freigaben

Nur der ausdrücklich gesendete Auftrag autorisiert Umsetzung. Folgeprompts sind keine Freigabe.

## M0 — 3D-Projektstart

**Teil des ersten Startauftrags mit M1.**

- lokale Godot-Version prüfen,
- Projekt/Renderer dokumentieren,
- 3D-Hauptszene,
- feste schräge Camera3D,
- Inputaktionen,
- Player-/Visual-Trennung,
- nur primitive Placeholder.

Kein Blender/Mixamo/AI-3D.

## M1 — 3D Steuerung + Hammergefühl

Eine offene Trainingsplattform, Dummy-Golem, Dummy-Hammer, drei passive Dummies, HP, Hitfeedback, Knockback, echte offene Kante, Fall/Respawn, Pause/Reset.

Abnahme:

- camera-relative 360° Bewegung,
- Touch/Controller Facing bleibt nach Stickneutral,
- Desktop Maus-Facing in Weltkoordinaten,
- kein Auto-Aim,
- sichtbarer Hammer-Swing + passendes Hitfenster,
- Dummies per HP oder Kante besiegbar,
- Player kann laufen/dodgen und wirklich fallen,
- kein unsichtbarer Randcollider,
- Placeholder-Visuals austauschbar ohne Gameplayabhängigkeit.

**Stopp:** kein echter zweiter Floor, keine KI, kein XP, keine Produktionsassets.

## M2A — erste aktive Kampfbegegnung (begrenzter Teilmeilenstein)

**Ausdrücklich freigegeben am 25.09.2026, nur dieser Teil von M2.** Umsetzung: `docs/reports/M2A_REPORT.md`.

- bestehende Plattform, Kampfmodus als Standardstart; M1-Trainingsmodus per Moduswahl erreichbar,
- genau ein aktiver Nahkampfgegner (Scrapling) mit Annäherung, angekündigtem Angriff, Recovery,
- Spielerschaden über explizite Trefferschnittstelle, Dodge-iFrames wirksam,
- Gegner per HP oder Kante besiegbar, Spielertod, Sieg/Niederlage-Anzeige, sauberer Neustart.

**Nicht enthalten (bleibt gesperrt):** mehrere Gegner, zweiter Gegnertyp, zweite Ebene, Sturzschaden, regulärer Abstieg, XP/Upgrades.

## M2B — Gruppenkampf und Tempovergleich (begrenzter Teilmeilenstein)

**Ausdrücklich freigegeben am 25.09.2026, nur dieser Teil.** Umsetzung: `docs/reports/M2B_REPORT.md`.

- Szenario GRUPPE (Standardstart): genau drei Scraplings derselben Szene, feste Startpunkte aus drei Richtungen; DUELL (M2A) und TRAINING bleiben per Szenariowahl erreichbar,
- lokale Abstandshaltung zwischen lebenden Gegnern nur in CHASE (keine Navigation, kein Angriffsdirektor),
- zwei Benommenheitsprofile A (0.40 s) / B (0.20 s), auswählbar, nur mit Neustart,
- explizite Gegnerverwaltung: Sieg erst nach allen Gegnern, sauberer Reset aller Beteiligten,
- lokale Rundenzusammenfassung (Log), Diagnoseskripte „RT halten + Vorwärtslaufen“.

**Nicht enthalten (bleibt gesperrt):** weitere Gegnertypen, zweite Ebene, Abstieg, XP/Upgrades, finale Assets, Kameraumbau, neue Spielerfähigkeiten, Tuning außerhalb der beiden Profile.

## M2C — Gemischter Kampf: zwei Scraplings und ein Funkenwerfer (begrenzter Teilmeilenstein)

**Ausdrücklich freigegeben am 25.09.2026, nur dieser Teil.** Umsetzung: `docs/reports/M2C_REPORT.md`.

- Szenario MIXED (Standardstart, Profil B): zwei Scraplings + ein Funkenwerfer, feste Startpunkte; Training, Duell, Gruppe bleiben erreichbar,
- Funkenwerfer als einfache Fernkampfrolle: Annähern, sichtbares Aufladen mit Richtungsfestlegung, genau ein gerader Energiebolzen, Erholung,
- Projektilregeln: Wegprüfung, ein Treffer, Dodge verbraucht ohne Schaden, kein Friendly Fire, bleibt nach Schützentod,
- Gegnerverwaltung für beide Typen, Bereinigung von Projektilen bei Sieg/Niederlage/Fall/Neustart/Wechsel,
- Rundenzusammenfassung um Schüsse und Projektiltreffer ergänzt.

**Nicht enthalten (bleibt gesperrt):** weitere Gegnertypen oder höhere Gegnerzahl, Bodenfallen, zweite Ebene, Sturzschaden, Abstieg, XP/Loot/Upgrades, neue Waffen/Fähigkeiten, finale Assets, Kameraumbau, Android-SDK.

## M2D — Zweite Ebene: Luke und Sturz (begrenzter Teilmeilenstein)

**Ausdrücklich freigegeben am 25.09.2026** („wenn alle Gegner besiegt, öffnet sich ein Loch am Boden … wenn man runterfällt, kommt auch Ebene 2, aber mit Fallschaden“). Nutzerentscheidungen: Ebene 2 mit neuer Form und erneut Mischkampf; Sturz von Ebene 2 = Niederlage; Commit erst später gemeinsam. Umsetzung: `docs/reports/M2D_REPORT.md`.

- Szenario DESCENT „Abstieg“ (neuer Standardstart, Profil B, Schuss scharf): Ebene 1 = Mischkampf auf der bisherigen Plattform,
- nach dem Räumen öffnet sich eine markierte Luke im Boden (echtes Loch, kein Interact-Button); Abstieg dadurch ohne Schaden,
- Sturz über die Kante von Ebene 1 führt jederzeit auf Ebene 2 mit 12 % max HP Sturzschaden; verbliebene Gegner der Ebene 1 werden übersprungen,
- sichtbarer, stetiger Fall zu einem validierten sicheren Landepunkt nahe der Sturzstelle, kurzer Landeschutz nur gegen Kampftreffer,
- Ebene 2 10 m tiefer: Ring um einen Schacht, zwei Scraplings + ein Funkenwerfer, lokaler Umweg an der Lücke,
- Sturz von Ebene 2 = Niederlage (Ergebnisanzeige, Neustart ab Ebene 1); Sieg nach dem Räumen von Ebene 2.
- **M2D.2 (Nutzerkorrektur, 25.09.2026):** Kantensturz fällt senkrecht und landet sauber wie der Lukenabstieg (verborgene Ebene 2 wird versetzt statt Spieler gelenkt); Übergang als an die Fallhöhe gekoppelte Überblendung statt zeitlicher Blenden.
- **M2D.1 (Präsentationskorrektur, 25.09.2026):** nur die aktuelle Ebene sichtbar, darunter neutrale Tiefe; Übergang im Fall (alte Ebene weg, kurz Tiefe, neue Ebene erscheint). Mechanik eingefroren. Nächster vorgesehener Schritt danach: M3 (XP, Floor-Belohnung, Run-Build-Entscheidungen), noch nicht freigegeben.

**Nicht enthalten (bleibt gesperrt):** dritte Ebene, Run-Struktur, Generatoren, neue Gegnertypen, Bodenfallen, XP/Loot/Upgrades, neue Waffen/Fähigkeiten, finale Assets, Kameraumbau.

## M2 — zwei Ebenen + echte Gegner + echter Fall

**Restumfang nicht freigegeben** (M2A, M2B, M2C und M2D ausgenommen; die Kernpunkte zweier Ebenen, Sturzschaden, sichere Landung und regulärer Clear-Abstieg sind mit M2D als Prototyp umgesetzt).

Nach ausdrücklicher Freigabe:

- obere Plattform mit offenem Rand/Loch,
- untere sichere Plattform,
- zwei einfache Gegnertypen,
- Schaden/Tod/Restart,
- Player-Sturz exakt eine Ebene tiefer,
- Sturzschaden + sichere Landung,
- Gegnerknockback in Abgrund,
- regulärer Clear-Abstieg.

Keine Generatoren/XP/Upgrades.

## M3A — Run Progression V1 (begrenzter Teilmeilenstein)

**Ausdrücklich freigegeben am 26.09.2026, nur dieser Teil.** Umsetzung: `docs/reports/M3A_REPORT.md`, Regeln: `docs/RUN_PROGRESSION.md`.

- RunState je Abstiegs-Run (bleibt über Ebenenwechsel, neuer Run bei Tod/Sturz/Neustart/Szenariowechsel),
- XP (Scrapling 30, Funkenwerfer 40) als sichtbare, magnetisch einsammelbare Orbs (Nutzerwunsch), Level-Formel 60 + 30 · (Level − 1), Live-Level-Up ohne Pause, +1 Attributspunkt,
- sechs Attribute (Stärke, Vitalität, Tempo, Beweglichkeit, Wucht, Erholung), Rang 0–8, Stats-Screen per Button/C/View-Back,
- Floor-Clear-Upgrade 1 aus 3 (6er-Pool) vor dem regulären Abstieg; früher Sturz ohne Upgrade; Clear im Fall = Auswahl nach der Landung,
- Effektive Werte = Basisressource × Attribut × Upgrade, jederzeit neu berechnet; keine Ressourcenmutation.

**Nicht enthalten (gesperrt):** M3B, Floor-Variety/Generatoren, dritte Ebene, Relikte, Boss-Belohnungen, Meta-Währung, Save/Load, Shops, Inventar, mehrere Waffen, neue Gegner/Hazards, Produktionsassets, Kameraumbau.

## M3B — Floor Variety V1 (begrenzter Teilmeilenstein)

**Ausdrücklich freigegeben am 26.09.2026, nur dieser Teil.** Umsetzung: `docs/reports/M3B_REPORT.md`, Vorlagen: `docs/FLOOR_TEMPLATES.md`.

- sechs handgebaute Floor-Vorlagen (Open Forge, Broken Corner, Central Pit, Twin Plates, Cross Forge, Shattered Ring) mit kuratiertem Kantenrisiko LOW/MEDIUM/HIGH,
- Auswahl pro Abstiegs-Run: Ebene 1 LOW/MEDIUM, Ebene 2 MEDIUM/HIGH, nie doppelt; getrennter, deterministischer Floor-Zufall,
- Spawn-, Landing- und Luken-Slots je Vorlage, Validator, senkrechte Landung über Slot-Ausrichtung der verborgenen Ebene,
- feste Testarena für Training/Duell/Gruppe/Mischkampf unverändert.

**Nicht enthalten (gesperrt):** prozeduraler Generator, zufällige Gegnerzusammensetzung, neue Gegner/mehr Gegner, Boss, Relikte, dritte Ebene, Shops, Meta-Progression, neue Attribute/Upgrades/Waffen, Bodenfallen, zerstörbare Floors, Produktionsassets, dynamische Kamera.

## M3 — erster Run-Build

RunState, überschaubares XP-Grundwachstum und wenige mechanische Hammer-Upgrades. Tod setzt Run-Macht zurück. Floorwechsel behält sie. Keine permanente Statprogression. (Mit M3A als erster Teil umgesetzt; Rest nicht freigegeben.)

## A1 — Art Vertical Slice (separater Produktionsauftrag)

Kann nach tragfähigem M1/M2 ausdrücklich beauftragt werden; nicht automatisch Teil der Nummernfolge.

Ein finalnaher Scrap-Golem, ein Hammer (vorgesehen als **Zweihandwaffe**; der M1-Placeholder hält ihn einhändig und bleibt bis dahin so), ein Gegner, kleines Plattform-/Prop-Kit, erste echte Animationen und VFX. Pipeline gemäß `ASSET_PIPELINE.md`.

Ziel: beweisen, dass AI/Blender/Mixamo/GLB/Godot technisch und visuell zusammen funktionieren, **bevor** viele Assets produziert werden.

## M4 — kleine vollständige Run-Schleife

Fünf Floors inklusive Boss als möglicher erster Schnitt. Nur nach M3-Freigabe. Wenige geprüfte Layoutvarianten, klare Sieg/Tod-Schleife.

## M5+ — Content/Polish

Weitere Waffen, Gegner, Produktionsgrafik, Audio, Settings/Rebinding, Save/Resume, zusätzliche Plattformen. Jeweils separat begrenzen.
