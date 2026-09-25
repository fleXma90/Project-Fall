# Project Fall — Godot/Cline Starterpaket

**Version:** 1.2 · 24.09.2026  
**Status:** Spezifikation + Referenzen. Noch kein implementiertes Spiel.  
**Codename:** `Project Fall` — kein Veröffentlichungsname.

Project Fall ist ein direkt gesteuertes Nahkampf-Roguelike für Smartphone im Querformat und Desktop. Ein kleiner Schrottgolem kämpft auf offenen, zerbrochenen Plattformen, kann Gegner über Kanten schlagen und selbst in tiefere Ebenen fallen. Der Build entsteht innerhalb des Runs; permanente Kampfwert-Metaprogression ist nicht Teil des Kerns.

## Was sich in v1.2 geändert hat

Die technische Richtung ist jetzt **stilisiertes 3D mit 2.5D/isometrischer Präsentation** statt klassischem 2D-Sprite-Gameplay. Der erste Prototyp verwendet absichtlich nur primitive Dummy-Assets. Finale Figuren, Waffen, Animationen und Umgebungsmodelle kommen erst nach einem tragfähigen Gameplay-Kern.

Der spätere Produktionsweg ist bereits vorbereitet: Konzept/Turnaround → optional AI-to-3D → Blender als Masterquelle → optional Mixamo für Basis-Rig/Animationen → Cleanup/Retarget/Custom-Combat-Animationen in Blender → `.glb` → Godot. Details stehen in `docs/ASSET_PIPELINE.md`.

**Für M0/M1 werden Blender, Mixamo, Blender MCP und externe 3D-Generatoren ausdrücklich nicht benötigt.**

## So startest du

1. Paket in einen neuen Projektordner entpacken, z. B. `D:\Project Fall`. `AGENTS.md` und `STARTER_PROMPT.md` müssen direkt im geöffneten Projektordner liegen.
2. Genau diesen Ordner in VS Code öffnen.
3. In Cline prüfen, dass `AGENTS.md` und `.clinerules/00-project-fall.md` berücksichtigt werden.
4. Eine neue Cline-Aufgabe im Act-Modus starten und `STARTER_PROMPT.md` vollständig ausführen lassen.
5. Cline erstellt `project.godot`, die 3D-Trainingsarena und den spielbaren M0/M1-Prototyp direkt im Projektordner.
6. Danach den manuellen Ablauf aus `docs/PLAYTEST_CHECKLIST.md` spielen. Erst nach dem Test M2 oder die Art-Pipeline freigeben.

Du musst vorher **kein leeres Godot-Projekt** anlegen. Ein bereits nichtleeres anderes Spielprojekt darf nicht still in Project Fall umgebaut werden.

## M0/M1: nur Gameplay-Blockout

Der erste Auftrag soll ausschließlich den Kern testen:

- feste schräge 3D-Kamera mit gut lesbarer Smartphone-Perspektive,
- 360°-Bewegung auf der XZ-Ebene,
- Touch: linker Stick + Attack + Dodge,
- Desktop: WASD + Maus-Facing + LMB Attack + RMB/Space Dodge,
- Controller: linker Stick + RT Attack + LT Dodge,
- Primitive/CSG-/Mesh-Dummyfigur mit sichtbarem Dummy-Hammer,
- drei Dummy-Ziele,
- echter 3D-Knockback,
- offene Plattform ohne Wände/Geländer/unsichtbare Randbarrieren,
- Spieler und Dummies können physisch über die Kante fallen,
- M1-Fall setzt den Spieler nach kurzer Reaktion am Spawn zurück,
- kein echter Mehr-Floor-Wechsel bis M2.

Die Placeholder-Szene soll so strukturiert sein, dass später ein riggtes `.glb` die Visuals ersetzt, ohne Bewegung, Kollisionskörper, Input oder Trefferlogik neu schreiben zu müssen.

## Steuerung

| Gerät | Bewegung | Facing/Schlagrichtung | Angriff | Dodge |
|---|---|---|---|---|
| Smartphone | linker virtueller 360°-Stick | letzte bewusste Stickrichtung | rechter Attack-Button | rechter Dodge-Button |
| Desktop | WASD, camera-relative | Mausprojektion in die 3D-Welt | LMB | RMB oder Space |
| Controller | linker Stick, camera-relative | letzte bewusste Stickrichtung | RT/R2 | LT/L2 |

**Keine Zielhilfe, kein Lock-on, kein automatisches Drehen zum Gegner und kein erforderlicher rechter Stick.**

## Visuelle Richtung

Nicht Pixel-Art. Nicht realistisches High-End-3D. Ziel ist **stylized 3D / 2.5D presentation**:

- chunky Low-/Mid-Poly-Figuren,
- große, klare Silhouetten,
- wenige große Materialflächen statt Kleinstetails,
- warme emissive Akzente auf dunkler Schmiedewelt,
- feste schräge Kamera,
- VFX und Trails hauptsächlich in Godot,
- Produktionsmodelle später als separate `.glb`-Assets.

Die PNGs in `references/` sind nur visuelle Referenzen. Der darin teilweise eingebrannte Altname **Forgefall** ist verworfen und darf nicht übernommen werden.

## Wichtige Dateien

| Datei | Zweck |
|---|---|
| `STARTER_PROMPT.md` | Erster ausführbarer Cline-Auftrag für M0 + M1 |
| `AGENTS.md` | Dauerhafte Projektregeln |
| `docs/ARCHITECTURE.md` | 3D-Projektstruktur, Kamera, Player/Visual-Trennung |
| `docs/ASSET_PIPELINE.md` | Spätere Blender/Mixamo/GLB-Pipeline |
| `docs/ART_DIRECTION.md` | Stylized-3D-Zielbild und Placeholder-Regeln |
| `docs/INPUT_CONTRACT.md` | Touch/Desktop/Controller-Verhalten |
| `docs/COMBAT_SPEC.md` | Hammer, Knockback, Dodge und Hitlogik |
| `docs/FLOOR_RULES.md` | Offene Kanten, echte 3D-Fälle und späterer Floor-Wechsel |
| `docs/MILESTONES.md` | Freigabegrenzen |
| `docs/PLAYTEST_CHECKLIST.md` | Technische + manuelle Prüfung |
| `prompts/A1_ART_VERTICAL_SLICE.md` | Späterer, noch nicht freigegebener Asset-Vertical-Slice |

## Grundsatz für finale Assets

Gameplay referenziert **keine konkreten Placeholder-Meshes**. Physik und Trefferlogik leben am Gameplay-Root; Visuals werden unter einem austauschbaren `VisualRoot`/Visual-Adapter instanziiert. Waffen sind separate Szenen/Modelle. Das spätere Player-Rig liefert Animationen und Hand-Sockets, verändert aber nicht die Kernsteuerung.

## Abnahmeprinzip

„Code vorhanden“, „Headless-Test bestanden“, „gerendert geprüft“, „auf echtem Controller/Smartphone geprüft“ und „vom Nutzer spielerisch abgenommen“ sind getrennte Zustände. Keine Geräte- oder Artqualität behaupten, die nicht tatsächlich geprüft wurde.
