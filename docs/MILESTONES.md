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

## M2 — zwei Ebenen + echte Gegner + echter Fall

**Restumfang nicht freigegeben** (M2A ausgenommen).

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

## M3 — erster Run-Build

RunState, überschaubares XP-Grundwachstum und wenige mechanische Hammer-Upgrades. Tod setzt Run-Macht zurück. Floorwechsel behält sie. Keine permanente Statprogression.

## A1 — Art Vertical Slice (separater Produktionsauftrag)

Kann nach tragfähigem M1/M2 ausdrücklich beauftragt werden; nicht automatisch Teil der Nummernfolge.

Ein finalnaher Scrap-Golem, ein Hammer (vorgesehen als **Zweihandwaffe**; der M1-Placeholder hält ihn einhändig und bleibt bis dahin so), ein Gegner, kleines Plattform-/Prop-Kit, erste echte Animationen und VFX. Pipeline gemäß `ASSET_PIPELINE.md`.

Ziel: beweisen, dass AI/Blender/Mixamo/GLB/Godot technisch und visuell zusammen funktionieren, **bevor** viele Assets produziert werden.

## M4 — kleine vollständige Run-Schleife

Fünf Floors inklusive Boss als möglicher erster Schnitt. Nur nach M3-Freigabe. Wenige geprüfte Layoutvarianten, klare Sieg/Tod-Schleife.

## M5+ — Content/Polish

Weitere Waffen, Gegner, Produktionsgrafik, Audio, Settings/Rebinding, Save/Resume, zusätzliche Plattformen. Jeweils separat begrenzen.
