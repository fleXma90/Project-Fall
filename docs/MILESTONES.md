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

## M2 — zwei Ebenen + echte Gegner + echter Fall

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

Ein finalnaher Scrap-Golem, ein Hammer, ein Gegner, kleines Plattform-/Prop-Kit, erste echte Animationen und VFX. Pipeline gemäß `ASSET_PIPELINE.md`.

Ziel: beweisen, dass AI/Blender/Mixamo/GLB/Godot technisch und visuell zusammen funktionieren, **bevor** viele Assets produziert werden.

## M4 — kleine vollständige Run-Schleife

Fünf Floors inklusive Boss als möglicher erster Schnitt. Nur nach M3-Freigabe. Wenige geprüfte Layoutvarianten, klare Sieg/Tod-Schleife.

## M5+ — Content/Polish

Weitere Waffen, Gegner, Produktionsgrafik, Audio, Settings/Rebinding, Save/Resume, zusätzliche Plattformen. Jeweils separat begrenzen.
