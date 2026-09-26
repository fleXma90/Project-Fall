# Prüfungen und fünfminütiger M1-Playtest

Status: BESTANDEN / FEHLGESCHLAGEN / OFFEN / NICHT IM UMFANG. Gerät/Umgebung immer nennen.

## Nutzer-Playtest M1

**Minute 1 — Bewegung/Facing:** Kreis und Diagonalen. Auf Touch/Controller loslassen und angreifen: Richtung bleibt. Desktop seitlich laufen und mit Maus unabhängig drehen.

**Minute 2 — Hammer:** Einzelangriff und gehaltenes Attack. Sichtbarer Swing muss mit Trefferbereich zusammenpassen. Dummy vor/seitlich/hinten vergleichen. Kein Gegner-Snap. Attack halten und dabei Stick/Maus durch 360° führen sowie hart umlenken: Bewegung bleibt frei, Körper folgt ohne Sprünge, jeder Swing geht in die beim Zuschlagen (ACTIVE) aktuelle Richtung.

**Minute 3 — Knockback/Kante:** Dummy mehrfach zur offenen Kante schlagen und herunterbefördern. Player selbst über Kante laufen. Danach einmal über Kante dodgen. Kein unsichtbarer Rand; Reset genau einmal.

**Minute 4 — Dodge/Input:** Dodge im Stand, in Bewegung und während Attack. LT/RMB/Touch halten: kein Endlos-Dodge. Pause während gehaltenem Attack und fortsetzen: kein hängenbleibender Angriff.

**Minute 5 — Geräte/UI:** Controller-Wechsel/Disconnect falls vorhanden. Touch gleichzeitig bewegen + Attack + Dodge falls echtes Smartphone vorhanden. Safe-Area und Buttonerreichbarkeit prüfen.

Drei Kernfragen:

1. Ist die Richtung vorhersehbar?
2. Fühlt sich der Hammer schwer und kontrollierbar an?
3. Sind offene Kanten lesbar, ohne unfair zu wirken?

## M2A-Kampfbegegnung (Controller-Spieltest)

1. Start: Kampfmodus. Scrapling nähert sich; Ausholen, Markierung (erst Umriss, nach der Festlegung wachsende Füllung) und Hieb lesbar?
2. Nach der Festlegung seitlich ausweichen (laufen oder Dodge): Der Hieb dreht nicht nach. Dodge genau im Hieb: kein Schaden, kein Rückstoß.
3. Treffer einstecken: HP sinkt, kurzer Rückstoß, danach sofort wieder steuerbar. Körperkontakt allein macht keinen Schaden.
4. Zurückschlagen während seiner Erholung; ihn einmal per HP und einmal über die Kante besiegen. Sieg-Anzeige → Neustart.
5. Sterben lassen → Niederlage → Neustart; einmal selbst herunterfallen (Begegnung startet neu). Pause → Moduswechsel Training/Kampf mit gehaltenem RT: nichts bleibt hängen.

Kernfragen: Ist der Angriff rechtzeitig lesbar? Fühlt sich Ausweichen fair an? Ist Dauerschlagen zu stark?

## M2B-Gruppenkampf (Controller-Spieltest)

1. Gruppe/Profil A: RT halten und schlicht vorwärts auf den nächsten Gegner laufen.
2. Gruppe/Profil A: offensiv umlaufen, Ziele wechseln, gezielt dodgen (RT darf gehalten bleiben).
3. Pause → Benommenheit Profil B: beide Vorgehensweisen wiederholen und vergleichen.
4. Bei Bedarf Pause → Szenario Duell (Profil A) als Referenz.

Kernfragen: Entsteht durch drei Bedrohungen ein dynamischer Kampf? Lohnt sich Bewegung/Dodge? Ist stures RT-Halten noch universell? Sind drei gleichzeitige Markierungen lesbar? Fühlen sich Trefferketten fair an? Rundenzusammenfassungen stehen nach jeder Runde in der Ergebnisanzeige und in `user://encounter_log.txt`.

## M2C-Mischkampf (Controller-Spieltest, Standardstart)

1. Scraplings bekämpfen und den Funkenwerfer zunächst ignorieren.
2. Schüsse durch normale Bewegung und Dodge vermeiden (Aufladen, Festlegung, Schuss lesbar?).
3. Den Funkenwerfer zuerst ausschalten (Distanz überwinden, Hammer).
4. Dabei Kanten und sichere Ausweichrichtungen beachten.
5. Pause → Szenario Gruppe: mit der Drei-Scrapling-Gruppe vergleichen.
6. Pause → Funkenwerfer „Standard“ ↔ „Scharf“ vergleichen (Standardstart ist Scharf).

Kernfragen: Erzeugt der Schütze Positionierungsentscheidungen? Ist ein Schuss rechtzeitig lesbar, auch neben zwei Nahkämpfern? Fühlen sich gemischte Treffer (Hieb + Bolzen) fair an?

## M2D-Abstieg (Controller-Spieltest, Standardstart)

1. Ebene 1 räumen, zur leuchtenden Luke laufen und hineinfallen (kein Knopf): Landung ohne Schaden unter der Luke?
2. Neustart; auf Ebene 1 absichtlich über die Kante laufen oder dodgen: Fall sichtbar, Landung sicher, 12 Sturzschaden, übrige Gegner bleiben zurück?
3. Auf Ebene 2 kämpfen: Kommen die Scraplings um den Schacht herum, schießt der Funkenwerfer über den Schacht? Ist der Landeschutz spürbar/fair?
4. Gegner in den Schacht oder über die Kante schlagen.
5. Selbst in den Schacht laufen: Niederlage, Neustart wieder auf Ebene 1.

Kernfragen: Lohnt sich das Räumen gegenüber dem Sprung (12 HP)? Ist die Luke klar erkennbar? Landet ein Kantensturz so sauber wie die Luke (senkrecht, kein schräger Zug)? M2D.1: Konkurriert die Tiefe unter der Ebene mit dem Kampf? Wirkt der Übergang (alte Ebene zieht weg → Tiefe → neue Ebene taucht auf) fließend, ohne Schnitt?

## M3A-Run-Progression (Spieltest, Standardstart)

1. Ebene 1 normal spielen: XP-Orbs einsammeln, XP-Leiste und Live-Level-Up beobachten.
2. Punkte zunächst sparen: zählt das STATS-Badge korrekt hoch (+1, +2 …)?
3. Stats mitten im Kampf öffnen (Button / C / View-Back), einen Punkt verteilen, schließen: Pause und Eingaben sauber?
4. Ebene 1 räumen: Upgrade 1 aus 3 wählen, öffnet sich die Luke erst danach?
5. Auf Ebene 2: Attribute und Upgrade weiterhin aktiv?
6. Neuer Run: alles wieder Basis?
7. Zweiter Versuch: ein, zwei Gegner besiegen, dann absichtlich herunterfallen: XP/Level/Punkte bleiben, kein Upgrade.

Kernfragen: Lohnt sich das Räumen gegenüber dem Sprung? Stören die Orbs im Kampf, oder lohnt sich der Umweg dafür? Sind Level-Ups spürbar, ohne den Kampf zu unterbrechen?

## Automatisierbare M1-Regeln

| ID | Verhalten |
|---|---|
| I1 | Camera-relative Diagonalen überschreiten Maxspeed nicht |
| I2 | Neutraler Stick bewahrt Facing; Knockback/Gravity ändert es nicht |
| I3 | Gehaltener Attack respektiert vollen Zyklus |
| I4 | Gehaltener Dodge löst höchstens einmal aus |
| I5 | Maus-Facing beeinflusst Controllerbetrieb nicht ohne echte Mausinteraktion |
| I6 | Pause/Fokusverlust/Reset/Disconnect lösen Held-Inputs |
| C1 | Ein Swing trifft ein Ziel höchstens einmal |
| C2 | Außerhalb Winkel/Reichweite kein Treffer |
| C3 | Dodge-Abbruch beschleunigt nächsten Attack nicht |
| C4 | Dummy-Knockback ist zeit-/physikbasiert, kein Teleport |
| F1 | Offene Kante hat keinen Randcollider |
| F2 | Player unter Killhöhe resetten genau einmal |
| F3 | Dummy unter Killhöhe Defeat genau einmal |
| A1 | Gameplay läuft auch dann, wenn PlaceholderVisual intern anders strukturiert wird |

## Gerenderte Prüfung

Mindestens 1280×720, 1600×720 und 1024×768. Bei 30/60 Render-FPS Physiktakt unverändert. Prüfen:

- Kameraausschnitt,
- Plattformkante,
- Player-Silhouette,
- Hammerbogen,
- Touch-HUD,
- keine z-fighting-/clippingbedingte Unlesbarkeit im Blockout.

Headless ist keine visuelle Abnahme.

## Hardware

Kein echter Controller → Controller-Hardwaretest OFFEN.  
Kein echter Android-Test → Smartphone-Test OFFEN.  
Keine gerenderte Session → visuelle Prüfung OFFEN.
