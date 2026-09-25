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
- während des Swings fixierte Richtung,
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
