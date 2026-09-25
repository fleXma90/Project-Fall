# Art Direction — Stylized 3D / 2.5D Schmiedewelt

## Festgelegte Richtung

Technisch 3D, präsentiert wie ein sehr gut lesbares 2.5D-Actionspiel. **Keine Pixel-Art und keine klassische 8-Richtungs-Spriteproduktion.** Ebenso kein realistisches High-End-3D.

Zielstil:

- stylized / cartoon-clean,
- chunky Low-/Mid-Poly-Geometrie,
- große überzeichnete Silhouetten,
- wenige große Materialflächen,
- hand-painted/vereinfachte Oberflächen,
- warme emissive Akzente gegen kühle dunkle Böden,
- klare Treffer- und Bewegungs-VFX,
- lesbar auf 6–7-Zoll-Smartphones.

## M1 ist ausdrücklich nur Blockout

M1 verwendet primitives 3D. Mindestlesbarkeit:

- kleiner kompakter Golem-Dummy,
- klar erkennbare Front/Blickrichtung,
- übergroßer Hammer,
- deutlich andere Dummies,
- dunkle Plattform mit gut sichtbarer Oberkante,
- sichtbarer Swing und Dodge,
- einfacher Impact.

M1 soll **nicht** so aussehen, als seien Boxen/Capsules bereits der finale Stil. Es testet ausschließlich Komposition, Kamera und Gameplay.

## Player-Zielbild später

Scrap-Golem:

- großer Kopf / kompakter Torso,
- kurze Beine,
- große Hände,
- wenige robuste Metallplatten,
- leuchtende Augen,
- optional kleiner Stoff-/Schal-Akzent,
- übergroße separate Werkzeugwaffe.

Keine hunderten Schrauben, Kabel oder photorealistischen Verschleißdetails. Silhouette schlägt Mikrodetail.

## Kamera

Schräge feste Kamera von oben, grob im Bereich 40–55° Pitch. Orthographic oder schwache Perspektive nach Lesbarkeit wählen. Plattformseiten und tieferer Hintergrund sollen Tiefe vermitteln, ohne dass die Kamera frei rotieren muss.

Ziele:

- Player und Gegner nicht durch Perspektive verdecken,
- offene Kanten klar sichtbar,
- Swing-Arcs verständlich,
- Touchfinger verdecken nicht ständig die wichtigste Gefahr,
- Desktop und Mobile zeigen dieselbe Spielwelt.

## Welt

Dunkles Metall/Stein mit einzelnen warmen Schmelz-/Ofenlichtquellen. Begehbare Oberflächen ruhiger als Hintergrund/VFX. Tiefe kann mit Nebel, dunkleren Ebenen, Ketten, Ofenlichtern und Parallaxwirkung angedeutet werden.

Normale Kampfplattformen besitzen keine klassischen Wände/Geländer als Begrenzung. Dekorative Pfeiler/Props können später existieren, dürfen aber nicht unlesbar zu „unsichtbaren Wänden“ werden. Der grundlegende Raum entsteht durch Boden versus Abgrund.

## Gegner

Jeder Typ bekommt eine andere Silhouette und Bewegungscharakteristik. Gefahr nicht nur über Farbe darstellen. Windup, Größe, Pose und Timing informieren über Angriff.

## Animation

Später skeletal 3D. Ein Clip funktioniert rundum, weil das Character-Root im Raum gedreht wird. Produktionsanimationen in-place.

Wichtiger als viele Clips:

- gutes Timing,
- klarer Windup,
- sichtbarer Kontaktmoment,
- Gewichtsverlagerung,
- Follow-through.

Der Hammer darf nicht wie ein leichtes Schwert wirken.

## VFX

Godot-seitig und sparsam:

- breite Hammertrail-Geometrie,
- Funken,
- Dust/Impact Burst,
- kurzer Flash,
- kleiner Screen-/Camera-Shake,
- später unterschiedliche VFX-Sprache pro Waffentyp.

Effekte verdecken nie Plattformkanten oder Gegnerwindups vollständig.

## HUD

M1: HP oben links, Pause oben rechts, Touchstick links unten, Attack/Dodge rechts unten. Desktop blendet Touchcontrols aus. Keine Fake-Systeme aus den Konzeptbildern.

## Referenzbilder

Die vier Konzeptbilder definieren Stimmung und Lesbarkeit, nicht exakte Geometrie, UI, Features oder Produktionsqualität. Der eingebrannte Altname `Forgefall` ist nicht zu übernehmen.
