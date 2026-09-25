# Technischer Rahmen — 3D Gameplay, 2.5D Präsentation

## Ziel

Project Fall wird technisch als 3D-Spiel gebaut, aber mit einer festen, schrägen Kamera und stark kontrollierter Lesbarkeit. Dadurch funktionieren freie 360°-Bewegung, echte Plattformkanten, Knockback und spätere riggte Modelle ohne 8-Richtungs-Spriteproduktion.

## Projektvorgaben

| Bereich | Startentscheidung |
|---|---|
| Engine | stabile Godot-4-Version, lokal tatsächlich prüfen |
| Sprache | typisiertes GDScript |
| Welt | 3D, Y = Höhe, XZ = Kampfebene |
| Player | `CharacterBody3D` + Schwerkraft |
| Kamera | feste schräge Draufsicht, sanft folgend, nicht frei drehbar |
| Renderer | Mobile bevorzugt für mobile-first 3D; tatsächliche Wahl dokumentieren |
| Physik | 60 Ticks/s |
| UI | Godot Control-Nodes, Landscape/Safe-Area |
| Hauptzielgeräte | Android + Windows zuerst real testen |
| Runtime-3D-Format später | glTF 2.0 / `.glb` |

Kein stilles Engine-/Renderer-Upgrade. Fehlt lokal eine sinnvolle Vulkan-/Mobile-Konfiguration, Compatibility kann bewusst als Fallback verwendet werden; der Wechsel muss im Bericht stehen.

## Koordinaten und Facing

Einheitlich:

- `+Y` ist oben.
- Player bewegt sich horizontal auf XZ.
- Lokales visuelles „vorne“ eines Produktionscharakters wird beim Import auf **-Z** normalisiert.
- Camera-relative Eingabe: Kamera-Forward und -Right auf XZ projizieren und normalisieren.
- Touch/Controller-Facing folgt dem letzten gültigen Bewegungsvektor.
- Desktop-Facing folgt einer Maus-Raycast-/Plane-Schnittposition in 3D.

Gameplay verwendet normalisierte XZ-Richtungsvektoren. Kein Gegner darf die Facing-/Attack-Richtung verändern.

## Kamera

M1: `Camera3D` auf einem einfachen CameraRig. Orthographic oder sehr schwache Perspektive ist erlaubt; bevorzugt wird die Variante, bei der Plattformkanten und Figuren auf kleinen Displays klar lesbar sind. Startwerte stehen in `TUNING.md` und sind ausdrücklich testbar.

Die Kamera darf dem Player weich folgen, aber:

- keine freie Spielerrotation,
- kein Zoom als Gameplaymechanik,
- kein Shake, der Kanten unlesbar macht,
- Mausprojektion muss trotz CameraRig stabil in Weltkoordinaten erfolgen.

## Player-Szene und Visual-Trennung

Empfohlene minimale Struktur:

```text
Player (CharacterBody3D)
├─ CollisionShape3D
├─ VisualRoot (Node3D)
│  └─ PlaceholderVisual (M1)
├─ WeaponRoot (Node3D)
│  ├─ WeaponMount (Node3D/Marker3D)
│  └─ <weapon scene>
├─ AttackOrigin (Marker3D)
└─ PlayerController.gd
```

Die endgültige Struktur darf besser benannt werden. Wichtig ist die Abhängigkeit:

**Gameplay → Visual-Adapter-Schnittstelle**, niemals **Gameplay → konkrete Placeholder-Mesh-Knoten**.

Später kann `PlaceholderVisual` durch eine importierte riggte Character-Szene ersetzt werden. Falls der Hand-Socket aus dem Skeleton kommt, bindet der Visual-Adapter/BoneAttachment3D den Weapon-Mount. WeaponController und Trefferlogik bleiben unverändert.

## Bewegung und Fall

`CharacterBody3D` erhält horizontale Zielgeschwindigkeit und normale Y-Schwerkraft. Offene Plattformen besitzen nur Collider dort, wo physisch Boden vorhanden ist. Keine unsichtbaren Randwände.

M1 erkennt einen Fall über eine Kill-/Reset-Höhe unter dem Trainingslevel. M2 ergänzt echten Übergang zur nächsten Ebene. Player und Dummies sollen während eines Knockbacks weiterhin Schwerkraft und Bodenstatus korrekt verarbeiten.

Root-Motion ist im Kern **nicht** die Quelle der Weltbewegung. Animationen laufen später in-place; Godot bestimmt Position, Dodge-Distanz, Knockback und Fall.

## Hammer / Hit Detection

WeaponController besitzt Timing und Swing-ID. Ein 3D-Sektor kann als zeitlich aktivierte `Area3D`/Shape oder als gezielte PhysicsDirectSpaceState-Abfrage umgesetzt werden. Anforderungen:

- begrenzte Reichweite,
- begrenzter Winkel,
- Richtung folgt im Windup der Körperausrichtung und ist ab der aktiven Phase fixiert,
- ein Treffer je Ziel/Swing,
- Visual und Hitfenster zeitlich plausibel synchron,
- kein Ziel-Snap.

Der konkrete Placeholder-Hammer ist reine Darstellung. Spätere Waffenmodelle dürfen den Gameplayradius nicht still aus ihrer Meshgröße ableiten.

## InputRouter

Ein kleiner zentraler Router verwaltet Rohinputs, aktive Quelle, Touch-Fingerbesitz und Triggerhysterese. Player konsumiert semantische Werte/Absichten:

```text
move_input
facing_intent
attack_held / attack_pressed
 dodge_pressed
```

Keine Rohinputs in jeder Waffe duplizieren. Pause, Fokusverlust, Disconnect und Szenenwechsel lösen gehaltene Zustände.

## Szenenstruktur — nur bei tatsächlichem Bedarf

```text
project.godot
scenes/
  main.tscn
  actors/player.tscn
  actors/training_dummy.tscn
  weapons/hammer.tscn
  levels/training_arena.tscn
  ui/hud.tscn
  ui/touch_controls.tscn
scripts/
  input/input_router.gd
  actors/player_controller.gd
  actors/training_dummy.gd
  combat/weapon_controller.gd
  levels/training_arena.gd
resources/
  tuning/player_tuning.tres
  weapons/hammer.tres
assets/
  placeholder/
  production/
  ASSET_MANIFEST.csv
blender/
  README.md
references/
docs/
```

Keine leeren Manager für spätere Features anlegen. Verzeichnisse dürfen angepasst werden.

## Kampfbegegnung M2A

Die Arena (`scenes/levels/training_arena.tscn`, `TrainingArena`) hat zwei Modi auf derselben Geometrie: COMBAT (Standard) und TRAINING. `restart()` setzt den aktuellen Modus vollständig zurück: Startpositionen, HP, Zustände, Timer, Trefferlisten, Effekte (`Effects`-Knoten) und gehaltene Eingaben. `Main` zeigt nach Sieg/Niederlage die Ergebnisanzeige (`EncounterOverlay`) und pausiert dahinter.

```text
Scrapling (CharacterBody3D, scrapling.gd)   # HP, KI-Zustände, Knockback, Bodenprüfung
├─ CollisionShape3D
├─ VisualRoot
│  └─ PlaceholderScrapling (ScraplingVisual)  # austauschbar
├─ WeaponController (+ WeaponMount / Cleaver-Szene)  # wiederverwendet, eigene WeaponData
├─ AttackOrigin
├─ SwingTrail (VFX)
└─ AttackTelegraph (VFX, Bodenmarkierung)
```

M2B: Die Arena hat drei Szenarien (GROUP Standard, COMBAT = Duell, TRAINING) und verwaltet `enemies` (alle drei Instanzen) und `active_enemies` (Teilnehmer der Runde) explizit. Signale werden einmalig in `_ready` verbunden. Das Benommenheitsprofil wird pro Instanz gesetzt (`Scrapling.hit_stun`). `EncounterStats` (`scripts/levels/encounter_stats.gd`) fasst jede Kampfrunde zusammen, auch nach Spielerfall oder Abbruch; `Main` schreibt sie in `user://encounter_log.txt`.

M2C: Szenario MIXED. Die Arena führt `active_enemies` (Scraplings) und `active_shooters` (Funkenwerfer); `combatants()` liefert beide. Beide Typen teilen nur eine kleine Duck-Typing-Schnittstelle (`defeated`, `is_defeated`, `fall_out`, `stop_combat`, `set_active`, `reset_to`, `target`, `neighbors`), ohne gemeinsame Basisklasse. Die Abstandshaltung liegt in `GroupSpacing` (`scripts/actors/group_spacing.gd`). Der Funkenwerfer (`scenes/actors/sparker.tscn`, Visual-Adapter `SparkerVisual`, Placeholder `PlaceholderSparkerVisual`, `AimIndicator`) meldet Schüsse per Signal; die Arena erzeugt `SparkBolt`-Instanzen (`scenes/combat/spark_bolt.tscn`) im Knoten `Projectiles` und entfernt sie beim Rundenende oder Neustart.

M2D: Szenario DESCENT. Die Plattform (`Platform`) ist jetzt eine `FloorGeometry` (`scripts/levels/floor_geometry.gd`): achsparallele Rechtecke erzeugen Kollider, Körper, Kacheln und Kantenleisten nur an echten Außen-/Lochkanten; `contains()`/`is_safe_point()` dienen der Landepunktprüfung. Die Luke (`Platform/Hatch`, `DescentHatch`) ist geschlossen ein echter Kollider und öffnet sich zu einem echten Loch. Ebene 2 (`LowerFloor`, ebenfalls `FloorGeometry`, 10 m tiefer) existiert nur im Abstieg (`set_enabled`). Die Arena führt `descent` (FLOOR_1 → FLOOR_1_CLEARED → DROPPING → FLOOR_2) und schaltet `active_enemies`/`active_shooters` bei der Landung auf `lower_enemies`/`lower_shooters` um; die übrigen Szenarien laufen unverändert über den bisherigen Pfad. Der Player bietet `settle_fall()` (M2D.2, zuvor `guide_fall_to()`), `apply_fall_damage()` und `protect_from_combat()`. `Main` senkt die Kamera-Folgegrenze beim Abstieg (`descent_started`) und setzt sie beim Neustart zurück; Nebelhöhe folgt der Ebene über eine Laufzeitkopie des Environments. Ebene 1 wird nach der Landung per `GeometryInstance3D.transparency` ausgeblendet. `GapDetour` (`scripts/actors/gap_detour.gd`) ist ein lokaler Umweg an Lücken und nur für die Gegner der Ebene 2 aktiv (`gap_detour`).

M2D.1 (nur Darstellung): Ebene 2 ist im Abstieg physisch aktiv, aber bis zum Übergang unsichtbar. `DepthBackdrop` (`scripts/levels/depth_backdrop.gd`) stellt die neutrale Tiefe unter der aktuellen Ebene dar und folgt ihr (`follow_floor`). M2D.2: Der Übergang ist eine reine Funktion des Fallfortschritts (`_apply_transition(progress)`, `progress` aus der Spielerhöhe zwischen Verlassen und Ebene 2). Er setzt Transparenz, Höhe von Ebene 1 samt zurückgelassenen Gegnern (deren Physik ist währenddessen aus), Sichtbarkeit von Ebene 2, Nebelhöhe und `DepthBackdrop` stetig und bildratenunabhängig; `restart()` ruft `_apply_transition(0)` und setzt Ebene 2 an ihre Grundposition zurück. Der Player bietet statt der Fallführung `settle_fall()` (Abklingen der Horizontalen) und `settle_drift()`; beim Verlassen wird die verborgene Ebene 2 samt Gegnern einmalig versetzt, damit der sichere Punkt unter dem Spieler liegt. Später bei erzeugten Floors kann die nächste Ebene erst zu Beginn des Abstiegs entstehen; das ist jetzt nicht umgesetzt.

Treffer laufen über `receive_hit(hit: HitInfo) -> bool` (Player, Dummy, Scrapling, Funkenwerfer); `HitInfo.source_name` hält die Quelle lesbar, auch wenn sie später entfernt wird. Keine gemeinsame Actor-Basisklasse, kein KI-Framework; Werte in `resources/tuning/scrapling_tuning.tres` und `resources/weapons/scrapling_cleaver.tres`.

## Produktionsasset-Integration später

Siehe `ASSET_PIPELINE.md`. Grundvertrag:

1. Blender-Masterdatei ist die kontrollierte DCC-Quelle.
2. ein Master-Rig je Characterfamilie,
3. Weapon-Modelle separat,
4. In-place Animation-Clips,
5. Godot-Import als `.glb`,
6. VisualRoot austauschen, Gameplay nicht neu schreiben,
7. VFX überwiegend engine-seitig.

## Tests

Typische lokale Prüfungen, nur wenn entsprechende Dateien existieren:

```powershell
& $Godot --version
& $Godot --headless --path . --import
& $Godot --headless --path . --quit-after 120
& $Godot --headless --path . --script tests/test_runner.gd
& $Godot --path . --resolution 1280x720
```

Headless beweist kein Spielgefühl und keine gerenderte 3D-Qualität.
