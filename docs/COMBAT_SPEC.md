# Nahkampf und Bewegungsgefühl v0.2 — 3D

## M1: ein Hammer

Ein vollständiger Angriff reicht: Windup → Active → Recovery. Noch kein Kombobaum.

Der Hammer schwingt sichtbar als 3D-Objekt um den Player. Die Trefferlogik bildet einen begrenzten Sektor/Reichweitenbereich vor dem Player ab; kein unsichtbarer Rundumkreis.

Pro `swing_id` wird ein Ziel höchstens einmal getroffen. Mehrere unterschiedliche Ziele im Sektor sind erlaubt. Trefferfläche und sichtbarer Hammerbogen sollen zeitlich/räumlich plausibel übereinstimmen.

Keine Wall-Slam-Mechanik: normale Kampfflächen besitzen keine klassischen Wände.

## Richtung und Rotation

Player-Root dreht sich um Y zu `facing_direction`. Touch/Controller-Facing folgt letzter Stickrichtung; Desktop-Facing folgt Mausweltpunkt.

Beim Attackstart wird `attack_direction` fixiert. Der aktive Swing dreht nicht nachträglich zum nächsten Gegner. Eine neue Bewegungs-/Facing-Eingabe darf für die nächste Aktion gespeichert werden, nicht die laufende Hitbox magnetisieren.

## Knockback

Ein Treffer erzeugt einen zeitbasierten XZ-Impuls. Kein Teleport. Dummies/Enemy-Körper bleiben der Schwerkraft unterworfen und können über offene Kanten hinausgeschoben werden.

HP-Kill und Fall-Kill sind idempotent: dasselbe Ziel darf nicht doppelt besiegt werden.

## Dodge

Kurze kontinuierliche XZ-Bewegung mit fixierter Richtung, begrenzten iFrames und Cooldown. Dodge kann Attack abbrechen, aber nicht den nächsten Attack-Takt beschleunigen.

Kein Jump. Kein Kanten-Schutz. Verlässt der Player während Dodge den Boden, setzt die normale 3D-Fallbewegung ein.

## Zustände

Kleiner Zustandssatz genügt:

- idle/move,
- attack windup/active/recovery,
- dodge,
- hit reaction,
- falling,
- dead.

Pause ist übergeordnet. Kein doppeltes State-Machine-System nur für Placeholder-Animation.

## Placeholder-Animation

M1 darf Node-Transforms/AnimationPlayer verwenden:

- leichter Body-Bob beim Laufen,
- sichtbares Hammer-Ausholen,
- Swing-Pivot durch den Schlagbogen,
- kleiner Lean/Stretch beim Dodge,
- Hitflash/Impact.

Gameplaytiming ist Quelle der Wahrheit. Visuals folgen ihm. Späteres riggtes Modell ersetzt nur Darstellung/Animationsadapter.

## Schaden ab M2

Gegnerkontakt verursacht nicht pro Physiktick automatisch Schaden. Gegnerschaden kommt aus angekündigten Angriffen mit eigenen Hitfenstern. Windups müssen in fester Kamera lesbar sein.
