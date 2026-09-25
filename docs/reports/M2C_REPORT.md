# Bericht: M2C — Gemischter Kampf: zwei Scraplings und ein Funkenwerfer

Datum: 25.09.2026  
Umfang: ausschließlich M2C: Szenario MIXED mit neuer Fernkampfrolle (Funkenwerfer + Energiebolzen), Profil B als Standard, Gegnerverwaltung für zwei Typen, Projektilbereinigung, knappe Erweiterung der Rundenzusammenfassung. Grundlage: lokaler, ungecommitteter M2B-Stand auf Commit `5336e45` (vorhanden, nicht angeglichen).  
Status: implementiert; automatisierte und skriptgesteuerte gerenderte Prüfungen bestanden  
Nutzerabnahme: **offen**. Nutzerfeedback vor M2C: Profil B fühlte sich im Gruppenkampf besser an. Das ist keine vollständige Hardware- oder Balanceabnahme.

## Startweg und Szenariowahl

```powershell
cd D:\Project_Fall
$G = "D:\Godot_v4.7.2-stable_win64.exe"
& $G --path .                               # Gemischt (2 Scraplings + Funkenwerfer), Profil B — Standard
& $G --path . -- --mode=mixed --profile=a   # Gemischt mit Profil A (Vergleich)
& $G --path . -- --mode=group               # Gruppe (3 Scraplings), ohne Profilangabe jetzt Profil B
& $G --path . -- --mode=combat --profile=a  # Duell/Basis = M2A-Vergleichsbasis (auch --mode=duel)
& $G --path . -- --mode=training            # Training (M1)
```

Bestehende Startargumente wurden nicht umgedeutet. Neu ist `--mode=mixed`, und ohne Profilangabe gilt jetzt B.

Im Spiel führt Pause → „Szenario“ zyklisch durch Gemischt → Gruppe → Duell → Training. „Benommenheit“ wechselt zwischen Profil A und B; beides startet die Runde vollständig neu. Die Moduszeile zeigt z. B. „GEMISCHT · Gegner 2/3 · Profil B“, die Debugzeile (F3) den Zustand aller Gegner inklusive Aufladefortschritt.

## Tatsächliche Regeln und Werte

**Szenario MIXED:**
- Spieler zentral bei (0, −0.5).
- Scraplings bei (4.8, −2.0) und (−4.2, −2.0), also ≈5.0 bzw. 4.5 m entfernt.
- Funkenwerfer bei (−5.0, 3.6), 6.5 m entfernt und damit außerhalb seiner Schussdistanz.
- Alle stehen ≥1.4 m von der Kante und sind zu Beginn im Bild (gerendert 3/3 in 16:9, 20:9, 4:3).
- Keine Dummies. Die vorhandene Abstandshaltung wirkt gegenseitig zwischen allen drei Gegnern. Kein Angriffsdirektor.

**Funkenwerfer** (`scripts/actors/sparker.gd`, Werte `resources/tuning/sparker_tuning.tres`):

| Wert | Einstellung |
|---|---|
| HP / Tempo | 60 / 2.0 m/s |
| Schussdistanz | Aufladen beginnt ab ≤ 6.0 m, nur im Kamerabild und auf dem Boden |
| Aufladen / Festlegung / Erholung | 0.65 / 0.45 / 1.00 s |
| Trefferbenommenheit | 0.20 s, unabhängig vom Scrapling-Profil |
| Körper | Kapsel r 0.40 m; ein Zylinder hätte wieder eine Kantenstütze erzeugt |

- **Annähern:** Er dreht zum Spieler und läuft heran, solange die Distanz über 6 m liegt oder er nicht im Bild ist. Unter 1.5 m läuft er nicht weiter heran, flieht aber auch nicht. Die Bodenprüfung gilt nur für seine eigene Laufentscheidung.
- **Aufladen:** Er steht und dreht bis 0.45 s nur zum Spieler, ohne zu laufen. Danach ist die Richtung fest. Nach 0.65 s folgt genau ein Schuss in diese Richtung, ohne Nachführen oder Vorhersage. Danach 1.0 s Erholung.
- **Ankündigung:** Rohrausrichtung und wachsende Ladungskugel. Ab der Festlegung (die letzten 0.20 s) geht er in eine geduckte, abgestützte Pose, zieht das Rohr zurück, die Kugel pulsiert größer, und die dezente Bodenlinie (2.2 m, kein Flächensektor) wird breiter. Beim Schuss folgen Mündungsblitz und Rückstoß.
- **Hammertreffer:** normaler Schaden (drei Treffer = besiegt) und voller Knockback (8 m/s). Aufladen wird abgebrochen; der Schuss entsteht nie später. Kein Hyperarmor.

**Energiebolzen** (`scripts/combat/spark_bolt.gd`, `scenes/combat/spark_bolt.tscn`):

| Wert | Einstellung |
|---|---|
| Tempo / Schaden | 6 m/s / 10 |
| Kollisionsradius | 0.13 m, entspricht dem sichtbaren Kern; Halo 0.24 m, kurzer Schweif, Lichtfleck am Boden |
| Lebensdauer | 2.5 s |
| Knockback | 3 m/s über 0.15 s, gemessen 0.20 m |

- **Flugbahn:** gerade, ohne Gravitation, Richtung beim Abschuss fix, kein Homing, kein Hitscan.
- **Unabhängig vom Schützen:** Alle Werte werden beim Abschuss kopiert. Der Bolzen fliegt weiter, wenn der Schütze danach getroffen oder besiegt wird, solange die Runde läuft; es bleibt keine Referenz auf den Schützen.
- **Wegprüfung:** Pro Tick ein Kugel-Sweep (`cast_motion`) entlang des Weges plus Startüberlappung. Er kollidiert nur mit Spieler und Weltgeometrie (Maske Welt + Spieler), nicht mit Gegnern; es gibt keinen Friendly Fire, er fliegt über Lücken, und der Hammer zerstört ihn nicht.
- **Kontakt:** über die vorhandene Spieler-Trefferschnittstelle `receive_hit`, höchstens ein Treffer, danach verbraucht. Kontakt während Dodge-iFrames: kein Schaden, kein Knockback, Bolzen verbraucht (nur dieser Typ; Nahkampfregeln unverändert).
- **Bereinigung:** Projektile werden bei Sieg, Niederlage, Spielerfall, Neustart sowie Szenario- und Profilwechsel sofort entfernt. Pause hält Bolzen und Lebensdauer an, ohne sie zu löschen.

**Gegnerverwaltung:** Die Arena führt `active_enemies` (Scraplings) und `active_shooters` (Funkenwerfer), `combatants()` liefert beide. Gemeinsame kleine Duck-Typing-Schnittstelle, keine Basisklasse. Sieg erst nach allen drei; HP- und Fall-Niederlage je Gegner genau einmal. Signale werden einmalig verbunden.

**Rundenzusammenfassung:** Im Mischkampf ergänzt um Schüsse, abgebrochene Aufladungen und Projektiltreffer. Automatisierte Läufe sind im Log als `[AUTOMATISIERT (headless)]` bzw. `[AUTOMATISIERT (QA-Sequenz)]` gekennzeichnet. Bestehende Logzeilen wurden nicht gelöscht (`%APPDATA%\Godot\app_userdata\Project Fall\encounter_log.txt`).

**Unverändert:** Spielerbewegung, Stoppen, voller Angriffstempo-Faktor, Hammer (0.26/0.12/0.42 s, Schaden, Reichweite, Winkel, Knockback), M1.1-Richtungsregel, Dodge/iFrames, Angriffswiederholung, alle Scrapling-Werte außer dem gewählten Profil, Kamera, Plattform, Renderer, Physiktakt.

## Tests

Alle 68 Headless-Tests grün (669 Checks, Exitcode 0). Alte Duell- und Profil-A-Tests laufen weiterhin ausdrücklich in ihrem Szenario und Profil; der neue Standard verändert sie nicht.

| Neue Prüfung | Befund |
|---|---|
| x1 Start/Standard | Gemischt, Profil B ohne Angabe; 2 Scraplings (0.20 s) + 1 Funkenwerfer, dritter Scrapling und Dummies inaktiv; Ressource unverändert (0.40 s); niemand in Reichweite oder an der Kante, alle im Bild; Profil A erreichbar und nur für Scraplings wirksam |
| x2 Zyklus | APPROACH → CHARGE (39 Ticks = 0.65 s, Festlegung nach 28 Ticks ≈ 0.45 s) → genau 1 Projektil → RECOVER (60 Ticks) → APPROACH; keine Bewegung beim Aufladen/Erholen; stehender Spieler −10 HP |
| x3 kein Nachführen | Vor der Festlegung dreht er mit; danach bleiben Richtung, Drehung und Position fix; der Bolzen fliegt in die festgelegte Richtung; ausgewichener Spieler nicht getroffen |
| x4 Abbruch | Hammertreffer bei 0.30 s und bei 0.55 s (nach der Festlegung) bricht ab; kein spätes Projektil |
| x5 Schützentod | Abgefeuerter Bolzen trifft nach Tod des Schützen (Quelle „Funkenbolzen (Sparker)“); Runde läuft weiter |
| x6 Kontaktregeln | Ein Treffer, dann verbraucht (Knockback 0.20 m). Dodge-Kontakt: 1 abgewehrt, 0 Schaden, 0 Knockback, verbraucht. Kein Friendly Fire (Scrapling in der Flugbahn unverletzt). 3 m pro Tick ohne Durchspringen. Startüberlappung genau 1 Treffer. Spieler 3.5 m unter der Plattform nicht getroffen. |
| x7 Niederlagen/Sieg | Funkenwerfer per HP (3 Treffer); Scrapling per Fall; Scrapling per HP; Sieg genau einmal nach 3/3; Projektile nach Sieg entfernt; Zusammenfassung HP 2 / Kante 1. Funkenwerfer per echtem Hammerschlag über die Kante: Fall-Niederlage genau einmal. |
| x8 Bereinigung | Pause friert Bolzen samt Lebensdauer ein, ohne ihn zu löschen; danach fliegt er weiter. Neustart, Profilwechsel, Szenariowechsel, Spielertod und Spielerfall entfernen Projektile und Aufladungen. Keine doppelten Signalverbindungen. |
| x9 Spieler | Werte unverändert; Bewegung mit/ohne gehaltenes RT identisch |
| x10 Trefferkette | Scrapling-Hieb (15, Knockback 5.5 m/s) in Tick 32 und Bolzen (10, 3 m/s) in Tick 35 werden beide angewendet: 25 HP in 3 Ticks |

**Korrekturen am Test-Harness (keine Spielfehler, aber wichtig für frühere Nachweise):**
- **Pause in Tests/QA:** Testläufer und QA-Knoten laufen mit `PROCESS_MODE_ALWAYS`, und die darunter geladene Hauptszene hatte das geerbt. In Headless-Tests und QA-Sequenzen bis M2B lief die Welt hinter dem Pausemenü weiter; im echten Spiel nicht, dort hängt die Hauptszene unter der Wurzel. Frühere Pausetests prüften nur Flags und gehaltene Eingaben. Jetzt ist die Hauptszene in beiden Harnesses ausdrücklich pausierbar, und x8 prüft das tatsächliche Anhalten.
- **Testfenster:** Headless startete quadratisch (1280×1280) und damit schmaler als jedes Zielformat. Jetzt fest 16:9 (1280×720).
- **i1:** Die Mindestbewegung ist relativ zur Fensterhöhe statt in absoluten Pixeln angegeben; die Aussage ist unverändert.

## Gerenderte Nachweise (skriptgesteuert, keine Hardwareabnahme)

Intel UHD 620, Vulkan Mobile; 1280×720 @60 und @30, 1600×720 @60, 1024×768 @60. Render 60.6–61.0 bzw. 30.6–31.0 FPS bei 61–65 Physikticks je Wandsekunde. Bilder in `qa/output/m2c_*`.

- **Unterscheidbarkeit:** `39_mixed_start` — Funkenwerfer (petrolfarbener Tank, Kanone, oranger Kern) klar anders als die rostroten Scraplings; alle drei im Bild.
- **Aufladung:** `40_sparker_charge_sheet` (32 Bilder / 2.2 s): Ladungskugel wächst, dünne → breite Richtungslinie ab der Festlegung (!), Mündungsblitz, gerader Flug mit Lichtfleck, Einschlag.
- **Einzelbilder:** `41`/`42` Aufladen vor und nach der Festlegung, `43` Bolzen im Flug in Spielgröße gut sichtbar.
- **Ausweichen und Annäherung:** `44` Dodge durch den Bolzen (HP 90 → 90), `45` Annäherung und Hammertreffer (Funkenwerfer 60 → 40 HP, Aufladen unterbrochen), `46` Kantensturz des Funkenwerfers (Fall-Niederlage).
- **Gemischter Kampf:** `47_mixed_fight_sheet` (40 Bilder / 5 s, RT gehalten, nächster Gegner): Nahkampfmarkierungen und Bolzen gleichzeitig erkennbar. Die Bodenlinie verdeckt keine Nahkampfmarkierung.
- **Rundenende:** `48` Sieg, `49` Niederlage mit Zusammenfassung, `50`/`51` Spielerfall und Reset, `52` Pause mit „Szenario: Gemischt › Gruppe“ und Profil B.
- **Aufnahme:** `qa/output/m2c_mixed_fight.avi` (1280×720, 7.4 s, Godot Movie Maker): Skriptkampf mit Ergebnis Niederlage nach 5.9 s (8 Treffer: 6 Nahkampf, 2 Bolzen).

## Diagnose (Skripte, identischer Start, Profil B, keine Wertänderung)

| Skript (RT gehalten, kantenvorsichtig) | Ergebnis |
|---|---|
| Nächster Gegner zuerst | Sieg, 10.3 s, 20 Schaden (2 Bolzentreffer). 7 Nahkampfangriffe, alle vor ACTIVE unterbrochen. 5 Schüsse, 2 Aufladungen abgebrochen. |
| Schütze zuerst | Sieg, 9.4 s, 55 Schaden (4 Treffer). 4 Nahkampfangriffe erreichen ACTIVE, weil das Skript den Scraplings den Rücken zudreht. 1 Schuss, 3 Aufladungen abgebrochen. |
| Videoaufnahme (nächster Gegner, 0.8 s späterer Start) | Niederlage, 5.9 s |

Wie in M2B reagiert das Ergebnis stark auf kleine Timingunterschiede. Die Skripte sind keine menschlichen Spieler. Keine Taktik wurde auf ein gewünschtes Ergebnis hin getunt.

## Offene Punkte

- **Trefferketten und Knockback-Überlagerung:** In x10 überschreibt der schwache Bolzen-Knockback (3 m/s, 0.15 s) den laufenden stärkeren Hieb-Knockback (5.5 m/s) nach 3 Ticks. Der Rückstoß des Hiebs wird dadurch verkürzt und wechselt die Richtung. Ohne Schutzfenster sind 25 HP in 3 Ticks möglich, mit zwei Scraplings plus Bolzen bis 40 HP fast gleichzeitig. Bewusst nicht mit iFrames oder Limits gelöst; offener Fairnessbefund.
- **Übersicht:** Drei Gegner plus Bolzen bleiben im Bild lesbar. Der Bolzen kann aber von hinten bzw. außerhalb des Blicks kommen. HP-Anzeigen überlappen gelegentlich.
- **Kamerabild-Regel:** „Nur im Bild aufladen“ hängt vom Seitenverhältnis ab. Auf schmalen Bildschirmen lädt der Funkenwerfer seitlich später auf. Kein Offscreen-HUD (nicht beauftragt).
- **Dominanz nach Annäherung:** gewollt; im Skript bleibt er nach Annäherung unterlegen.
- **Hardware und Gefühl:** Controller und Smartphone ungeprüft. Offen: Lesbarkeit des Aufladens neben zwei Nahkämpfern, Fairness gemischter Treffer, Vergleich mit der Gruppe.

## Manueller Spieltest

1. `& $G --path .` (Gemischt, Profil B): Scraplings bekämpfen und den Funkenwerfer zunächst ignorieren.
2. Schüsse durch normale Bewegung und Dodge vermeiden. Sind Aufladen, Festlegung und Schuss rechtzeitig lesbar?
3. Den Funkenwerfer zuerst ausschalten (Distanz überwinden, Hammer).
4. Dabei Kanten und sichere Ausweichrichtungen beachten.
5. Pause → Szenario Gruppe: mit der Drei-Scrapling-Gruppe vergleichen.

## Stopp

Keine weiteren Gegnertypen oder höhere Gegnerzahl, keine Bodenfallen, keine zweite Ebene, kein Sturzschaden oder Abstieg, keine XP/Loot/Upgrades, keine neuen Waffen/Fähigkeiten, keine finalen Assets, kein Kameraumbau, kein Android-Setup. Keine Installationen, kein Commit/Push.

## Nachtrag: Schussprofil „Scharf“ (nach Nutzerfeedback)

**Feedback:** Der Funkenwerfer ist verständlich, aber sehr leicht auszuweichen. Nach der Festlegung genügen 1–2 Schritte.

**Befund:** Ab der Festlegung blieben ≈0.8–1.1 s bis zum Einschlag (0.20 s Rest-Aufladen + 6 m/s Flug); ein seitlicher Schritt von ≈0.5 m dauert ≈0.1 s. Gemessen (`test_d11`, 5 m Abstand): Seitliches Loslaufen bis zu 0.6 s nach der Festlegung reichte noch.

**Umsetzung (Option A):** Umschaltbares Schussprofil wie die Benommenheitsprofile.

| | Standard | Scharf |
|---|---|---|
| Aufladen / Festlegung | 0.65 / 0.45 s | 0.70 / 0.55 s |
| Bolzentempo | 6 m/s | 11 m/s |
| Treffer nach der Festlegung (stehender Spieler, 5 m) | ≈0.85 s | 0.42 s |
| Spätestes Ausweichen nach der Festlegung (5 m) | 0.6 s | 0.3 s |

- „Scharf“ ist jetzt der Standardstart. „Standard“ bleibt per Pausemenü („Funkenwerfer: … › wechseln“) oder `-- --shot=standard` wählbar, „Scharf“ per `-- --shot=sharp`. Ein Wechsel startet die Runde vollständig neu.
- Die Werte liegen in einer Laufzeitkopie pro Funkenwerfer-Instanz. Die Datei `sparker_tuning.tres` bleibt unverändert (per Test geprüft), alle anderen Werte sind identisch.
- Weiterhin kein Homing, keine Vorhersage; Ankündigung und Regeln unverändert. HUD zeigt „Schuss scharf/standard“, die Rundenzusammenfassung das Schussprofil.
- Tests: alle bisherigen Mischkampf-Tests laufen ausdrücklich mit „Standard“. Neu: `test_y1` (Werte, nur drei Abweichungen, Ressource unverändert, Timing 33/42 Ticks, Bolzen 11.0 m/s, Wechsel mit Neustart), `test_d10` (Skript RT halten + nächster Gegner mit „Scharf“: Sieg, 10 Schaden – Einzellauf, keine Balance-Aussage), `test_d11` (Reaktionsfenster, Tabelle oben).
- Offen: Ob „Scharf“ im Mischkampf mit Nahkämpfern zu viel Druck erzeugt oder genau richtig ist, zeigt nur der manuelle Spieltest.

