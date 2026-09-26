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

## Gruppenkampf — M2B (umgesetzt)

- Szenario GRUPPE: drei Scraplings derselben Szene, jeder mit eigener Zustandsmaschine und eigener Waffe (eigene Trefferliste). Kein Angriffsdirektor: Gleichzeitige Angriffe sind erlaubt.
- Abstandshaltung: In CHASE addiert jeder Gegner einen Wegdrück-Vektor zu nahen lebenden Nachbarn (Radius 1.6 m) zu seiner Laufabsicht. Innerhalb der Stopp-Distanz rückt er nur langsam seitlich ab. Die Bodenprüfung gilt für die resultierende Richtung. Keine Wirkung auf Knockback, Schwerkraft, WINDUP (nach der Festlegung), ACTIVE oder RECOVERY.
- Hammer: ein Schlag trifft alle Gegner im Sektor, jeden höchstens einmal pro Swing.
- Gegnertreffer: jeder Gegnerangriff höchstens ein Treffer. Treffer verschiedener Gegner sind getrennt (eigene Waffe, `HitInfo.source`), auch bei gleicher `swing_id` und im selben Physiktick. Jeder gültige Treffer wendet Schaden und Knockback an, der letzte Knockback überschreibt den vorherigen. Es gibt keine zusätzliche Unverwundbarkeit nach Treffern und keine gemeinsame Abklingzeit.
- Sieg erst, wenn alle Gegner der Runde besiegt sind (HP oder Fall, je Gegner genau einmal); gleichzeitige Niederlagen erzeugen genau ein Ergebnis. Spielertod oder -fall beendet den Kampf aller Gegner.
- Benommenheitsprofile A/B: siehe `TUNING.md`; Wechsel nur mit vollständigem Neustart.
- Gehaltener Angriff bleibt erlaubt und wird nicht bestraft; kein zusätzlicher Hammer-Cooldown.

## Mischkampf und Funkenwerfer — M2C (umgesetzt)

- Szenario MIXED (Standard): zwei Scraplings + ein Funkenwerfer. Sieg erst, wenn alle drei besiegt sind; kein Angriffsdirektor.
- **Funkenwerfer:** APPROACH (dreht, läuft heran, solange der Spieler weiter als 6 m entfernt ist oder er nicht im Kamerabild ist) → CHARGE (steht; dreht bis 0.45 s nur zum Spieler, danach fixe Richtung) → nach 0.65 s genau ein Schuss → RECOVER 1.0 s. Er flieht nicht. Kein Nahkampfangriff, Charge, Sprung, Fächer oder Flächenschaden. Neue Aufladungen beginnen nur im Kamerabild; begonnene enden regulär.
- Lesbarkeit: sichtbare Rohrausrichtung, wachsende Ladungskugel, ab der Festlegung geduckte Abstützpose, zurückgezogenes Rohr und kräftigere dezente Richtungslinie am Boden (kein Flächensektor), Mündungsblitz und Rückstoß beim Schuss.
- Hammertreffer: normaler Schaden und Knockback, 0.20 s Benommenheit; ein laufendes Aufladen wird abgebrochen, ein nicht abgefeuerter Schuss entsteht nie später. Kein Hyperarmor.
- **Energiebolzen:** gerade, ohne Gravitation, Richtung beim Abschuss fix, kein Homing/Hitscan. Werte beim Abschuss kopiert: Er fliegt weiter, auch wenn der Schütze danach getroffen oder besiegt wird (solange die Begegnung läuft). Pro Tick Kugel-Sweep entlang des Weges plus Startüberlappung (kein Durchspringen). Er kollidiert nur mit Spieler und Weltgeometrie, nicht mit Gegnern (kein Friendly Fire), fliegt über Lücken und wird vom Hammer nicht zerstört.
- Kontakt mit dem Spieler: über `receive_hit`, höchstens ein Treffer, danach verbraucht. Während Dodge-iFrames: kein Schaden, kein Knockback, Bolzen trotzdem verbraucht (nur dieser Projektiltyp).
- Echte 3D-Höhe: Ein Spieler weit unter der Plattform wird nicht wegen gleicher XZ-Position getroffen.
- Bereinigung: Projektile werden bei Sieg, Niederlage, Spielerfall, Neustart, Szenario- und Profilwechsel entfernt; Pause hält sie samt Lebensdauer an, ohne sie zu löschen.
- Schussprofile: „Standard“ (Festlegung 0.45 s, Bolzen 6 m/s) und „Scharf“ (Festlegung 0.55 s von 0.70 s, Bolzen 11 m/s; aktueller Standardstart). Ankündigung, Regeln und Ausweichbarkeit bleiben gleich, nur das Reaktionsfenster ist kürzer. Kein Homing, keine Vorhersage.
- Mehrquellen-Treffer (Nahkampf + Bolzen) bleiben nach den bestehenden Regeln erlaubt: Jeder gültige Treffer wendet Schaden und Knockback an, der letzte Knockback überschreibt den vorherigen. Offener Fairnessbefund, siehe `M2C_REPORT.md`.

## Zwei Ebenen und Abstieg — M2D (umgesetzt)

- Szenario DESCENT (Standardstart): Ebene 1 ist der unveränderte Mischkampf (dieselben Instanzen, Werte und Regeln).
- **Regulärer Abstieg:** Sind alle Gegner der Ebene 1 besiegt, öffnet sich die Luke (2 × 2 m, leuchtender Rahmen, Klappen schwingen nach unten). Wer hineinläuft, fällt durch das echte Loch; kein Knopf, kein unsichtbarer Trigger. Kein Sturzschaden. Die Begegnung läuft weiter (keine Ergebnisanzeige nach Ebene 1).
- **Sturz über die Kante:** jederzeit möglich, auch nach dem Räumen. Einmaliger Sturzschaden 12 % max HP (mindestens 1, derzeit 12) bei der Landung; kann tödlich sein. Noch lebende Gegner der Ebene 1 hören auf zu kämpfen und bleiben zurück (übersprungen), fliegende Bolzen werden entfernt.
- **Fall und Landung (M2D.2):** Unter 0.6 m unter der Oberkante gilt Ebene 1 als verlassen. Danach klingt die horizontale Bewegung mit 0.12 s Zeitkonstante ab (≈0.5 m Restweg beim Laufen), keine Eingabe, kein Lenken: Der Spieler fällt senkrecht, bei Kante und Luke gleich. Landestelle = Position beim Verlassen + Restweg. Die noch verborgene Ebene 2 wird samt wartenden Gegnern so versetzt, dass dort ein geprüfter sicherer Punkt liegt (mindestens 1.2 m Boden ringsum, 3 m Abstand zu Gegnern). Bei der Luke ist in der Regel kein Versatz nötig. Landung ohne Rutschen, kein Teleport des Spielers.
- **Landeschutz:** 0.75 s nach der Landung (und während des Falls) wirken keine Kampftreffer; Bolzen werden dabei wie bei Dodge-iFrames verbraucht. Kein Schutz vor fehlendem Boden.
- **Ebene 2:** Ring um einen 5 × 4 m Schacht; zwei Scraplings (Flanken) + ein Funkenwerfer (gegenüber). Sie warten verborgen und ohne Ziel, erscheinen beim Abstieg und greifen ab der Landung an. An Lücken weichen sie lokal aus (Drehung 45°/90°/135°, bevorzugte Seite bleibt), statt stehenzubleiben; Knockback in den Schacht bleibt ein Kantensieg.
- **Niederlage/Sieg:** Sturz von Ebene 2 (Kante oder Schacht) = Niederlage mit Ergebnisanzeige; Neustart beginnt wieder auf Ebene 1 mit vollen HP. Sieg erst nach allen Gegnern der Ebene 2.
- Gegner der Ebene 1, die über die Kante fallen, gelten 3 m unter der Oberkante als besiegt und erreichen Ebene 2 nie.
- **Darstellung (M2D.1/M2D.2):** Nur die aktuelle Ebene ist sichtbar; darunter neutrale Tiefe (Dunkelheit, Glutnester, Funken). Der Übergang ist an die Fallhöhe gekoppelt (nicht an Zeit): Ebene 1 samt zurückgelassenen Gegnern steigt bis 6 m nach oben weg und löst sich auf; Ebene 2 taucht überlappend auf, sobald Ebene 1 zu ≈80 % aufgelöst ist, und ist vor der Landung vollständig da. Nebel und Tiefe wandern stetig mit. Übergang ≈ 0.8 s, Kamera folgt.
- **Prototyp-Regeln (nicht final):** Ebene-2-Sturz = Niederlage nur mangels Ebene 3; 12 Sturzschaden ist Testwert; 0.75 s Landeschutz später durch sichere Aktivierung ersetzen.

## Run-Modifikatoren — M3A (umgesetzt)

- Nur im Abstieg und nur für den Spieler: Stärke/Hammerkopf skalieren Hammerschaden, Wucht/Einschlag das Knockback-Tempo (Dauer unverändert), Tempo alle drei Hammerphasen proportional (Rang 0 exakt 0.26/0.12/0.42 s, Rang 8 ≈ 0.21/0.10/0.34 s), Weiter Schwung/Langer Griff Bogen und Reichweite. Die Richtungsregel (M1.1) und Attack-Hold bleiben unverändert.
- Beweglichkeit und Momentum skalieren Lauftempo samt Beschleunigung/Abbremsung (gleiche Zeit bis Vollgas und Stopp). Dodge-Tempo, -Dauer und iFrames bleiben gleich; Erholung/Kinetische Erholung verändern nur die Dodge-Abklingzeit.
- Gegnerangriffe, erhaltener Knockback, Landeschutz (0.75 s) und Sturzschaden (12) bleiben unverändert.
- Details und Werte: `RUN_PROGRESSION.md`.

## Nicht im Umfang

Weitere Gegnertypen, dritte Ebene, Run-Struktur, Charge/Sprung, Combo-/Heavy-/Ausdauersysteme.
