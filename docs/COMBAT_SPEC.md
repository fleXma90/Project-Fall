# Nahkampf und Bewegungsgefühl v0.2 — 3D

## M1: ein Hammer

Ein vollständiger Angriff reicht: Windup → Active → Recovery. Noch kein Kombobaum.

Der Hammer schwingt sichtbar als 3D-Objekt um den Player. Die Trefferlogik bildet einen begrenzten Sektor/Reichweitenbereich vor dem Player ab; kein unsichtbarer Rundumkreis.

Pro `swing_id` wird ein Ziel höchstens einmal getroffen. Mehrere unterschiedliche Ziele im Sektor sind erlaubt. Trefferfläche und sichtbarer Hammerbogen sollen zeitlich/räumlich plausibel übereinstimmen.

Keine Wall-Slam-Mechanik: normale Kampfflächen besitzen keine klassischen Wände.

## Richtung und Rotation

Player-Root dreht sich um Y weich zu `facing_direction`. Touch/Controller-Facing folgt letzter Stickrichtung; Desktop-Facing folgt Mausweltpunkt.

Seit M1.1 (ersetzt die frühere Fixierung beim Attackstart):

- **WINDUP:** Der Körper dreht weiter zum Facing; die bevorstehende `attack_direction` folgt der sichtbaren Körperausrichtung.
- **ACTIVE:** `attack_direction` wird beim Eintritt fixiert; Körper, Trail und Treffersektor bleiben darauf. Kein nachträgliches Herumziehen des aktiven Sektors, auch nicht zu einem Gegner.
- **RECOVERY:** Freie Körperausrichtung, keine Treffer.
- Bewegung (Richtung und Geschwindigkeit) bleibt in allen Phasen vom aktuellen Input abhängig; kein Vorwärtszwang, kein Angriffsschritt.

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

## Schaden und Gegner — M2A (umgesetzt)

M2A ist ein begrenzter Teilmeilenstein: genau ein aktiver Nahkampfgegner (Scrapling) auf der bestehenden Plattform. Werte: `docs/TUNING.md`.

**Trefferschnittstelle.** Alle Ziele (Dummy, Scrapling, Player) implementieren `receive_hit(hit: HitInfo) -> bool`. Rückgabe `true` = Treffer angewendet. Der `WeaponController` verbraucht ein Ziel für einen Swing erst bei `true`; höchstens ein angewendeter Treffer pro Ziel und `swing_id`.

**Spieler wird getroffen.**

- Gültiger Treffer: HP −Schaden, Hitflash, zeitbasierter XZ-Knockback (linear abklingend) im Zustand HIT für die Knockbackdauer. In HIT keine Aktionen; der Impuls wird nicht von der Laufgeschwindigkeit überschrieben. Danach normale Steuerung.
- Dodge-iFrames (0.02–0.14 s nach Dodgestart): Treffer wird abgewehrt, **weder Schaden noch Knockback**. Er verbraucht den Swing nicht: Endet das iFrame-Fenster, während der gegnerische ACTIVE-Sektor den Spieler noch erfasst, trifft der Angriff normal. Dodge schützt nicht vor fehlendem Boden.
- Treffer während eines eigenen Angriffs: Der Angriff wird abgebrochen (keine spätere Hitbox). Der Angriffstakt läuft ab dem Start des abgebrochenen Angriffs weiter; es gibt keinen früheren Folgeangriff.
- HP ≤ 0: einmalig DEAD, laufende Angriffe enden, keine Eingaben. Im Kampfmodus: Niederlage.

**Scrapling (kleine lokale Zustandsmaschine).** IDLE → CHASE → ATTACK (WINDUP/ACTIVE/RECOVERY) → CHASE, dazu HIT und DEFEATED.

- CHASE: dreht zum Spieler, läuft auf begehbarem Boden bis zur Stopp-Distanz. Er greift an, wenn der Spieler in Startdistanz und grob vor ihm ist. Eine Bodenprüfung vor dem Körper verhindert nur die *eigene* Laufentscheidung über die Kante. Sie wirkt nicht auf Knockback oder Schwerkraft: keine Klemmung, keine Immunität.
- WINDUP: dreht bis zur **Festlegung** (55 % des Windups) zum Spieler, danach nicht mehr. Die Bodenmarkierung zeigt vor der Festlegung nur den Umriss. Danach füllt sie sich von innen nach außen bis zum Hieb, und das Auge leuchtet auf.
- ACTIVE: fixierte Richtung, kein Nachdrehen, keine Bewegung, Treffer nur hier (begrenzte Reichweite, Winkel, Höhe; ein Treffer pro Angriff). Körperkontakt verursacht nie Schaden.
- RECOVERY: sichtbares Verharren mit gesenkter Waffe, keine Bewegung, keine Treffer.
- Hammertreffer: Knockback, Hitflash, HIT-Reaktion (0.4 s, kein Angriff, keine Verfolgung). Ein laufender Angriff wird abgebrochen und trifft nicht nachträglich. Kein Hyperarmor.
- HP- und Fall-Niederlage werden genau einmal verarbeitet. Danach keine Angriffe, Trefferabfragen oder Verfolgung. Ein gefallener Gegner wird nicht weiter simuliert.

**Bodenmarkierung.** Sie zeigt exakt den Bereich, in dem der Spielermittelpunkt getroffen würde, mit derselben Regel wie die Trefferprüfung: Abstand ≤ Reichweite + Spielerradius, Winkel ≤ halber Bogen + atan(Radius/Abstand). Lesbarkeit entsteht über die Form (Umriss → wachsende Füllung), nicht nur über Farbe.

**Bekannter Playtestbefund (M2A).** Gehaltener Angriff mit Annäherung unterbricht den Scrapling dauerhaft: Hammer-Windup 0.26 s gegen Gegner-Windup 0.55 s, dazu 0.4 s Trefferreaktion. Bewusst nicht durch Hyperarmor o. Ä. ausgeglichen; siehe `docs/reports/M2A_REPORT.md`.

## Nicht im Umfang

Mehrere aktive Gegner, zweiter Gegnertyp, Sturzschaden, zweite Ebene, Charge/Sprung/Projektil, Combo-/Heavy-/Ausdauersysteme.
