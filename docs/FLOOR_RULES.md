# Floor-, Kanten- und Fallregeln v1.1 — echte 3D-Geometrie

## Grundregel

Tragender Boden ist echte 3D-Geometrie mit Collider. Wo kein Boden ist, gibt es **keinen** unsichtbaren Randcollider. Normale Kampfflächen besitzen keine klassischen Wände oder Geländer als Begrenzung.

Spieler, Dummies und später Gegner stehen unter Schwerkraft. Verlassen sie den Boden, fallen sie physisch entlang Y.

Dekorative Hintergrundobjekte dürfen nicht unverständlich in die Spielfläche kollidieren.

## M1

Eine offene Trainingsplattform. Spieler und Dummies können über den Rand fallen.

- Player unter definierter Killhöhe → Fallreaktion → Reset am Spawn.
- Dummy unter Killhöhe → einmalige Niederlage.
- Kein Sturzschaden.
- Kein echter Floorwechsel.
- Keine zweite Ebene nötig.

Eine Kill-/Reset-Zone weit unter dem Boden ist erlaubt; sie ist keine unsichtbare Randbarriere.

## M2 echter Abstieg

Zwei handgefertigte Ebenen auf unterschiedlichen Y-Höhen. Ein Fall der oberen Ebene landet tatsächlich auf der unteren Ebene, sofern überlebt und ein sicherer Landing-Flow ausgelöst wird.

Startvorschlag: einmaliger Sturzschaden 12 % max HP, mindestens 1. Kann tödlich sein. Der Wert ist Tuning, nicht final.

Ankunft erfolgt an einem validierten sicheren Punkt; nicht dieselbe XZ-Koordinate erzwingen, wenn dort Loch/Gegner wäre. Kurze Landeschutzzeit gegen Kampfschaden, kein Schutz vor erneut fehlendem Boden.

## Regulärer Abstieg

Nach Clear wird ein markierter sicherer Abstieg aktiv. Kein Interact-Button nötig: Zone kurz halten/betreten. Regulärer Abstieg verursacht keinen Sturzschaden.

### Umsetzung M2D (Prototyp, 25.09.2026)

Szenario „Abstieg“: Ebene 2 liegt 10 m tiefer (Ring um einen Schacht). Sturz über die Kante von Ebene 1 → Landung auf Ebene 2 mit 12 % max HP Sturzschaden; Luke nach dem Räumen → Landung ohne Schaden. Landepunkt: validiert (1.2 m Boden ringsum, 3 m Abstand zu Gegnern). Seit M2D.2 fällt der Spieler senkrecht (kurz abklingender Schwung); die noch verborgene Ebene 2 wird versetzt, nicht der Spieler gelenkt. Landeschutz 0.75 s nur gegen Kampftreffer. Sturz von Ebene 2 = Niederlage. Details: `COMBAT_SPEC.md` (M2D), `reports/M2D_REPORT.md`.

## Dodge / Tunneling

Da echte 3D-Physik verwendet wird, darf ein schneller Dodge keine unrealistische Kantenbrücke erzeugen. Collider, Physiktakt und Bewegung so umsetzen, dass der Player bei fehlendem Boden zuverlässig in Falling übergeht. Kein künstlicher „Support-Sweep“, der einen großen Luftspalt als Boden behandelt.

## Gegner

Normale freiwillige Navigation soll sichere Plattformfläche respektieren. Erzwungener Knockback darf über die Kante führen. Ein fallender Gegner wird einmal als besiegt behandelt und nicht unsichtbar weiter simuliert.

## Boss später

Bossplattform ebenfalls grundsätzlich offen. Für den ersten Boss kann Player-Fall tödlich sein und der Boss selbst knockback-resistent gegen Kantenkill, um Skip-Probleme zu vermeiden. Erst beim Boss-Meilenstein finalisieren.
