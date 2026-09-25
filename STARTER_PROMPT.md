# Cline-Startauftrag — Project Fall M0 + M1 (3D Gameplay Blockout)

Du arbeitest im neuen Projektordner von **Project Fall**, einem Godot-4-Nahkampf-Roguelike für Smartphone im Querformat und Desktop. Setze diesen Auftrag direkt im Ordner um. Liefere nicht nur einen Plan oder Chat-Codeblöcke.

## 1. Zuerst einlesen

Lies vollständig:

- `AGENTS.md`
- `docs/STATUS.md`
- `docs/GAME_SPEC.md`
- `docs/INPUT_CONTRACT.md`
- `docs/COMBAT_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/ART_DIRECTION.md`
- `docs/TUNING.md`
- M0/M1 in `docs/MILESTONES.md`
- M1 in `docs/PLAYTEST_CHECKLIST.md`
- `references/README.md`

`docs/ASSET_PIPELINE.md` nur lesen, um die spätere Austauschbarkeit zu verstehen. **Die dort beschriebene Produktionspipeline ist in diesem Auftrag nicht auszuführen.**

Prüfe vorhandene Dateien und ggf. `git status --short`. Erhalte alle Briefingdateien und Nutzerarbeit. Prüfe die lokal verfügbare stabile Godot-4-Version. Keine ungefragten Installationen, keine .NET/C#-Umstellung, kein Blender/Mixamo/Blender-MCP und kein externer 3D-Generator.

Nenne deinen M0/M1-Plan in höchstens sechs kurzen Punkten und beginne danach direkt mit der Umsetzung.

## 2. Ziel dieses Auftrags

Baue einen **spielbaren 3D-Blockout**, mit dem nur das Grundprinzip bewertet wird:

> 360° bewegen → Richtung kontrollieren → Hammer schlagen → Gegner zurückstoßen → Kanten als Risiko/Chance nutzen → ausweichen → selbst herunterfallen können.

Keine finalen Assets. Keine Contentproduktion. Kein Run-System.

## 3. Technischer Rahmen

Erstelle ein startbares Godot-4-Projekt mit typisiertem GDScript und 3D-Gameplay. Verwende einen für mobile 3D geeigneten Renderer gemäß `AGENTS.md`/`ARCHITECTURE.md` und dokumentiere die tatsächlich gewählte Einstellung und Godot-Version.

- Weltachsen: **Y = Höhe**, Bewegung auf **XZ**.
- Kamera: feste schräge Draufsicht / 2.5D-isometrische Präsentation. Sie darf dem Spieler weich folgen, aber nicht frei vom Nutzer rotiert werden.
- Spieler: `CharacterBody3D` mit echter Schwerkraft.
- Plattform: echte 3D-Oberfläche mit Kollisionskörper; wo keine Plattform ist, gibt es keinen unsichtbaren Randcollider.
- M1 darf unter dem Level eine Kill-/Reset-Zone besitzen.
- Hauptszene startet direkt in die Trainingsarena, kein Hauptmenü.

## 4. Nur Dummy-Assets verwenden

Erzeuge Player, Hammer, Dummies und Arena ausschließlich aus einfachen Godot-Primitiven/Standardmaterialien oder kleinen selbst erzeugten Placeholder-Meshes. Keine externen Modelle, Texturen oder Animationen laden.

Trotzdem muss die Szene lesbar sein:

- Player als kompakter kleiner Dummy-Golem mit Kopf/Körper/Armen oder ähnlich klarer Silhouette,
- zwei leuchtend/warm gefärbte Augen oder ein klarer Frontindikator,
- deutlich sichtbarer übergroßer Hammer,
- Dummies visuell klar vom Player unterscheidbar,
- schlichte dunkle Plattform mit eindeutig sichtbarer Oberkante und Tiefe,
- einfacher Schatten beziehungsweise Bodenkontakt.

Baue die Player-Szene so, dass die Placeholder-Visuals später unter einem `VisualRoot`/Visual-Adapter gegen ein riggtes `.glb` ausgetauscht werden können. Gameplayscript und Kollisionskörper dürfen nicht von den konkreten Placeholder-Mesh-Namen abhängen.

Die Waffe bleibt als eigene Szene/Komponente austauschbar. Plane einen stabilen Weapon-Mount, der später durch einen Hand-Bone-Socket/BoneAttachment3D gespeist werden kann, ohne die Combat-Logik umzubauen.

## 5. Trainingsarena

Eine einzige offene 3D-Plattform. **Keine klassischen Wände, Geländer oder unsichtbaren Randbarrieren.** Keine Wandkollision als Gameplaytest.

Platziere drei passive Trainingsdummies. Sie haben HP und können durch Hammertreffer zurückgestoßen werden. Zwei Niederlagen sind möglich:

1. HP fällt auf 0.
2. Dummy wird über die Plattformkante geschlagen und fällt unter die M1-Killhöhe.

Beim Spieler gilt in M1: über die Kante laufen oder dodgen → echter 3D-Fall → kurze lesbare Fallreaktion → Trainingsreset/Respawn am sicheren Spawn. **Noch kein Wechsel auf einen zweiten Floor und noch kein Sturzschaden.**

## 6. Bewegung und Facing

Alle Bewegungen sind camera-relative. Joystick/WASD „oben“ bewegt auf dem Bildschirm nach oben, indem Kamera-Forward/Right auf XZ projiziert werden.

### Touch

- dynamischer linker 360°-Stick,
- rechts großer Attack-Button und kleinerer Dodge-Button,
- echtes Multitouch mit getrennten Finger-IDs,
- Stickrichtung setzt Bewegung und Facing,
- neutraler Stick behält die letzte bewusste Facing-Richtung.

### Controller

- linker Stick: Bewegung + Facing,
- RT/R2: Attack,
- LT/L2: Dodge,
- kein rechter Stick erforderlich,
- analoges Triggerverhalten/Hysterese gemäß Inputvertrag.

### Desktop

- WASD: camera-relative Bewegung,
- Maus: unabhängiges Facing in der 3D-Welt,
- ermittle die Weltposition über Kamera-Ray und geeignete Boden-/Horizontalebene; keine rohe Screenpixelrechnung,
- LMB Attack,
- RMB oder Space Dodge.

Nirgends Auto-Aim, Lock-on oder Gegner-Snap.

## 7. Hammer und Placeholder-Animation

Noch kein Kombobaum. Ein vollständiger Hammerangriff:

- sichtbares Ausholen,
- klarer 3D-Schlagbogen,
- aktives Trefferfenster,
- Nachlauf,
- pro Ziel und Swing höchstens ein Treffer,
- Knockback auf XZ,
- keine 360°-Kreisattacke,
- Schlagrichtung beim Start fixieren.

Placeholder-Animation darf über `AnimationPlayer`, Tween oder saubere Node-Transforms umgesetzt werden. Der Hammer muss tatsächlich sichtbar schwingen; nicht nur unsichtbar Schaden im Radius verursachen.

Dodge ist eine kurze kontinuierliche Bewegung, kein Teleport. Er kann über eine offene Kante führen. Fehlender Boden wird nicht durch iFrames aufgehoben.

Einfaches Trefferfeedback: Hitflash, kleiner Impact-Flash/Partikel, optional sehr dezenter Camera-Shake. Keine große VFX-Produktion.

## 8. Architektur für spätere Produktionsassets

Im M1-Code bereits folgende Grenze respektieren:

- Gameplay-Root kontrolliert Bewegung, HP, Kollisionskörper und Combatzustand.
- Visual-Root kontrolliert nur Darstellung.
- WeaponController/Attack-Hitlogik ist unabhängig vom konkreten Hammermesh.
- Ein späteres riggtes Modell kann Player-Visuals ersetzen.
- Finale Animationen sollen später **in-place** laufen; Godot bewegt die Spielfigur.
- Kein Root-Motion-Zwang in die Gameplayarchitektur einbauen.
- Keine konkreten Mixamo-Bonenamen im Gameplaycode hardcodieren.

Nicht jetzt implementieren: Blender-Importpipeline, Retargeting, AnimationTree für nicht vorhandene Produktionsclips, LOD-System, Shaderbibliothek oder Asset-Generator.

## 9. HUD und Pause

Minimal:

- HP oben links,
- Pause oben rechts,
- kleine Debuganzeige für aktuelles Eingabegerät/Facing nur wenn hilfreich,
- Touchcontrols nur bei Touch-/Testmodus,
- Pause und vollständiger Trainingsreset per Touch, Maus/Tastatur und Controller bedienbar.

Keine Minimap, Coins, Gems, XP, Floorcounter, Ragebar oder Q/E/R-Skills.

## 10. Prüfung und Übergabe

Führe verfügbare Prüfungen aus:

- Godot-Version,
- Import/Parse,
- Headless-Smoke,
- fokussierte Input-/Combatregeln,
- tatsächliche gerenderte Session,
- 1280×720, 1600×720 und 1024×768,
- 30/60 Render-FPS mit unverändertem Physiktakt,
- echte offene Kante ohne Randcollider,
- Spielerfall/Respawn genau einmal,
- Dummy-Knockback und Kanten-Kill,
- Maus-Facing in 3D,
- Controller-/Touch-Hardware nur dann als bestanden melden, wenn tatsächlich vorhanden.

Aktualisiere `docs/STATUS.md` und erstelle `docs/reports/M1_REPORT.md` nach `docs/REPORT_TEMPLATE.md`.

**Danach stoppen. Kein M2, keine Gegner-KI, keine zweite Ebene, keine XP/Upgrades und keine Produktionsassets. Kein Commit/Push ohne ausdrücklichen Auftrag.**
