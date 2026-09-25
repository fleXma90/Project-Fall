# AGENTS.md — Project Fall

Gilt für das gesamte Projekt. Project Fall ist ein neues Godot-4-Nahkampf-Roguelike mit **3D-Simulation und fester 2.5D/isometrischer Präsentation**. Arbeite zuerst am spielbaren Kern und halte finale Art-Produktion vom Gameplay-Prototyp getrennt.

## Vor jedem Auftrag

Lies zuerst `docs/STATUS.md`, den aktuellen Nutzerauftrag und die dazu passende Spezifikation. Inspiziere vorhandene Dateien sowie, falls vorhanden, `git status --short`. Uncommittete Arbeit ist Nutzerarbeit und bleibt erhalten.

Für M0/M1 zusätzlich lesen: `docs/INPUT_CONTRACT.md`, `docs/COMBAT_SPEC.md`, `docs/ARCHITECTURE.md`, `docs/ART_DIRECTION.md`, `docs/TUNING.md`, die M0/M1-Abschnitte in `docs/MILESTONES.md` und `references/README.md`.

Die spätere Produktionspipeline steht in `docs/ASSET_PIPELINE.md`. Sie ist **keine Freigabe**, jetzt Blender, Mixamo, Blender MCP oder einen AI-3D-Dienst zu benutzen.

## Verbindliche Produktgrenzen

- Singleplayer. Smartphone im Querformat und Desktop; Controller von M1 an.
- Smartphone: linker 360°-Stick, rechts Attack und Dodge.
- Desktop: WASD camera-relative, Maus bestimmt die Schlagrichtung, LMB Attack, RMB oder Space Dodge.
- Controller: linker Stick camera-relative und zugleich Facing, RT Attack, LT Dodge. Kein erforderlicher rechter Stick.
- Keine Zielhilfe, kein Lock-on, keine magnetische Reichweitenkorrektur und kein automatisches Drehen zu Gegnern.
- Angriff wird nur durch Angriffseingabe ausgelöst; Halten darf vollständige Angriffe wiederholen. Dodge braucht eine neue Druckflanke.
- Keine permanenten Kampfwert-Upgrades zwischen Runs.
- Kein Jump, kein Parieren, keine zusätzlichen aktiven Skillbuttons, kein Ausdauer-/Rage-System im vereinbarten Kern.
- **3D-Welt:** Bewegung auf XZ, Höhe/Schwerkraft auf Y. Offene Kanten sind echte physische Kanten.
- Normale Kampfplattformen haben **keine klassischen Wände, Geländer oder unsichtbaren Randbarrieren**. Fehlender Boden führt zum Fall, nicht zur Kollision.
- Konzeptbilder sind Art-Referenzen, keine Featureliste.

## Art-/Asset-Grundregel

M0/M1 nutzt nur **selbst erzeugte primitive Dummy-Assets**: Box/Capsule/Cylinder/CSG/StandardMaterial oder ähnlich einfache Godot-Meshes. Keine externe Figurenbibliothek und keine halbfertige Produktionsfigur als technische Voraussetzung.

Gameplay und Visuals müssen trennbar bleiben:

- `CharacterBody3D`/Kollisionskörper und Gameplayscript bleiben unabhängig vom konkreten Modell.
- Ein austauschbarer `VisualRoot` beziehungsweise kleiner Visual-Adapter enthält Placeholder oder später das riggte Modell.
- Gameplaycode darf nicht auf Namen wie `PlaceholderHead`, `BoxMesh3D` oder einzelne Materialinstanzen angewiesen sein.
- Waffen sind separate Szenen/Modelle. Der Gameplaycode kennt einen stabilen Weapon-Mount/Adapter, nicht die intern wechselnde Bone-Struktur.
- Placeholder-Animation darf per `AnimationPlayer`, Tween oder Node-Transform erfolgen. Finale Skeletal-Animation wird später integriert.
- VFX-Logik gehört grundsätzlich in Godot und darf nicht an gebackene Placeholder-Grafik gekoppelt werden.

Der spätere Produktionsweg ist in `docs/ASSET_PIPELINE.md` dokumentiert. Blender ist dort die kanonische DCC-/Masterstufe; `.glb` ist das vorgesehene Engine-Format. Mixamo oder AI-to-3D sind optionale Zulieferer, nicht die Quelle der Gameplayarchitektur.

## Umfang und Arbeitsmodus

Implementiere **nur den ausdrücklich beauftragten Meilenstein**. Der erste Startauftrag umfasst M0 + M1. M2+, Art-Vertical-Slice und Produktionsassets bleiben gesperrt, bis sie ausdrücklich beauftragt werden.

Priorität: jüngste Nutzerentscheidung → konkrete Verhaltensverträge → Meilensteinumfang → allgemeine Vision → Bildreferenzen. Ein vorhandener Folgeprompt ist keine Freigabe.

Keine Shops, Craftingbäume, Meta-Währungen, Multiplayer, Cloud-Dienste, Analytics, große Save-Frameworks, prozeduralen Generatoren oder leeren Manager auf Vorrat. Keine Architektur für hypothetische Systeme, die im aktuellen Meilenstein nicht gebraucht wird.

## Technische Regeln

- Godot 4 stable, Standard/GDScript, typisiertes GDScript.
- 3D-Gameplay mit `CharacterBody3D` und normaler Y-Schwerkraft.
- Start-Renderer: für dieses mobile-first 3D-Projekt bevorzugt Godots **Mobile-Renderer**, sofern die lokal vorhandene stabile Version und Zielhardware ihn unterstützen. Keine stille Renderer-Änderung; tatsächliche Wahl dokumentieren. Falls die Umgebung nur Compatibility sinnvoll unterstützt, den Grund offen festhalten.
- Physiktakt standardmäßig 60 Hz.
- Kamera: fest/sanft folgend, schräg von oben, keine frei drehbare Spielerkamera in M1.
- Bewegungsvektoren werden camera-relative auf die XZ-Ebene projiziert.
- Maus-Facing entsteht durch Ray/Plane- beziehungsweise Ray/World-Schnitt in 3D; niemals aus rohen Screenpixeln direkt in Weltkoordinaten.
- `move_direction`, `facing_direction`, `attack_direction` und `dodge_direction` bleiben getrennte Zustände.
- Attack-Richtung folgt während des Ausholens (WINDUP) der bewussten Ausrichtung und wird beim Eintritt in die aktive Trefferphase (ACTIVE) fixiert; Gegner beeinflussen sie nicht.
- Kein Teleport-Dodge und kein FPS-abhängiger Knockback.
- Offene Kanten erhalten keine unsichtbaren Schutzcollider.
- M1 darf einen Kill-/Reset-Plane unter der Arena verwenden; das ist keine Randbarriere.

## Placeholder-Animation und spätere Austauschbarkeit

M1 soll trotz Dummy-Assets Bewegung lesbar machen: einfacher Body-Bob/Lean, klarer Hammer-Aushol- und Schlagbogen, sichtbare Dodge-Bewegung, Hitflash/Impact. Das muss kein finales Rig sein.

Die Player-Szene soll eine stabile Schnittstelle besitzen, z. B. sinngemäß:

```text
Player (CharacterBody3D)
├─ CollisionShape3D
├─ VisualRoot (Node3D)         # austauschbar
│  └─ PlaceholderVisual        # M1; später GLB/rigged scene
├─ WeaponController
│  └─ WeaponMount / WeaponVisual
├─ AttackOrigin (Marker3D)
└─ ...
```

Die exakten Knotennamen dürfen besser gewählt werden, aber die Trennung muss erhalten bleiben. Spätere Produktionsmodelle dürfen die Gameplay-Root-Position, Kollisionsform, Bewegung oder Trefferregeln nicht heimlich ersetzen.

## Prüfen und berichten

Nach Änderungen Import/Parse-Smoke und fokussierte Verhaltenstests ausführen, sofern die Engine verfügbar ist. Eine tatsächlich gerenderte Session prüfen, wenn möglich. Fehlendes Fenster, Controller oder Smartphone als **OFFEN** markieren statt bestandene Tests zu erfinden.

Für M1 mindestens prüfen: camera-relative Bewegung, Mausprojektion, Facing im Stillstand, Attack-Hitfenster, Knockback, Kantenfall, Reset, gehaltene Inputs, 16:9/20:9/4:3-Layouts und 30/60 Render-FPS bei konstantem Physiktakt.

`docs/STATUS.md` und einen Bericht nach `docs/REPORT_TEMPLATE.md` aktualisieren. Keine Commit-/Push-Aktion ohne ausdrücklichen Auftrag.

## Dateien, Assets und Sicherheit

Keine destruktiven Worktree-Resets, kein `git clean`, keine fremden Dateien löschen oder überschreiben. Keine globalen Tools, SDKs, Blender-Erweiterungen oder MCP-Server ungefragt installieren.

Externe Produktionsassets nur mit nachvollziehbarer Herkunft und Nutzungsgrundlage gemäß `docs/ASSET_POLICY.md`. AI-generierte Rohmodelle, Mixamo-Clips oder Blender-MCP-Ergebnisse werden nicht allein durch ihre technische Erzeugung automatisch zu freigegebenen Produktionsassets. Bildreferenzen nicht als Runtime-Texturen oder Storegrafik ausschneiden.
