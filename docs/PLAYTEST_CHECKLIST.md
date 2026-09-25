# Prüfungen und fünfminütiger M1-Playtest

Status: BESTANDEN / FEHLGESCHLAGEN / OFFEN / NICHT IM UMFANG. Gerät/Umgebung immer nennen.

## Nutzer-Playtest M1

**Minute 1 — Bewegung/Facing:** Kreis und Diagonalen. Auf Touch/Controller loslassen und angreifen: Richtung bleibt. Desktop seitlich laufen und mit Maus unabhängig drehen.

**Minute 2 — Hammer:** Einzelangriff und gehaltenes Attack. Sichtbarer Swing muss mit Trefferbereich zusammenpassen. Dummy vor/seitlich/hinten vergleichen. Kein Gegner-Snap.

**Minute 3 — Knockback/Kante:** Dummy mehrfach zur offenen Kante schlagen und herunterbefördern. Player selbst über Kante laufen. Danach einmal über Kante dodgen. Kein unsichtbarer Rand; Reset genau einmal.

**Minute 4 — Dodge/Input:** Dodge im Stand, in Bewegung und während Attack. LT/RMB/Touch halten: kein Endlos-Dodge. Pause während gehaltenem Attack und fortsetzen: kein hängenbleibender Angriff.

**Minute 5 — Geräte/UI:** Controller-Wechsel/Disconnect falls vorhanden. Touch gleichzeitig bewegen + Attack + Dodge falls echtes Smartphone vorhanden. Safe-Area und Buttonerreichbarkeit prüfen.

Drei Kernfragen:

1. Ist die Richtung vorhersehbar?
2. Fühlt sich der Hammer schwer und kontrollierbar an?
3. Sind offene Kanten lesbar, ohne unfair zu wirken?

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
