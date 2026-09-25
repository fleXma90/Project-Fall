# Produktionsasset-Pipeline — später, nicht M0/M1

Diese Datei beschreibt den vorgesehenen Weg von Konzept zu finalem 3D-Asset. Sie ist **keine aktuelle Freigabe**, externe Tools oder Produktionsassets zu verwenden.

## Ziel

Gameplay soll heute mit Dummy-Assets entstehen und später ohne Rewrite auf hochwertige stylisierte 3D-Assets wechseln können.

**Kanonische Kette:**

```text
Character/Weapon Concept + Turnaround
        ↓
optional AI-to-3D Base Mesh
        ↓
Blender MASTER
  cleanup / retopo / UV / materials / scale
        ↓
Rigging
  Mixamo optional für humanoide Basis
  oder Blender-Rig
        ↓
Blender MASTER
  retarget / custom combat animations / sockets
        ↓
GLB export
        ↓
Godot VisualRoot / weapon scene
        ↓
Godot VFX + gameplay integration
```

## 1. Konzept/Turnaround

Vor einem wichtigen Character-Asset zuerst ein konsistentes Sheet erzeugen:

- Front,
- Back,
- Side,
- 3/4,
- neutrale Pose,
- gleiche Proportionen und Materialien,
- Character **ohne fest integrierte Waffe**, sofern die Waffe wechselbar sein soll.

Der aktuelle Scrap-Golem soll chunky, low-/mid-poly-tauglich und riggbar bleiben: klare Gelenke, große Silhouette, wenige kleine lose Teile.

## 2. AI-to-3D ist optionaler Rohmesh-Lieferant

Ein Tool wie ein aktueller Image-to-3D-Dienst kann später einen Base Mesh liefern. Das Ergebnis gilt nicht automatisch als production-ready.

Vor Nutzung prüfen und dokumentieren:

- aktuelle Nutzungs-/Lizenzbedingungen,
- tatsächliche Exportrechte,
- Polygonzahl/Topology,
- UVs/Texturen,
- problematische Innenflächen,
- Symmetrie/Anatomie,
- Riggbarkeit.

Tool, Datum, Ausgangsbilder und relevante Lizenzgrundlage in der Assetdokumentation festhalten.

## 3. Blender ist die Masterquelle

Für Produktionsassets ist die bereinigte Blender-Datei die kontrollierte Quelle, nicht der rohe AI-Export und nicht Mixamo.

Blender-Aufgaben können manuell oder mit Blender MCP/AI-Unterstützung beschleunigt werden:

- Mesh cleanup,
- Retopology/Decimation mit visueller Kontrolle,
- Normals,
- UV/Materialstruktur,
- Scale/Origin,
- Objekttrennung,
- Rig-Aufbereitung,
- Animation-Retarget,
- Weapon Sockets,
- Batch-Export.

**MCP-Erfolg ist kein visueller Qualitätsbeweis.** Schulter, Ellbogen, Hände, Knie, Silhouette und Deformation müssen in Bewegung angesehen werden.

## 4. Maßstab und Orientierung

Projektstandard:

- Godot: 1 Unit ≈ 1 Meter.
- `+Y` = up.
- Imported Character root steht mit Fußpunkt bei Y=0.
- Neutraler Character blickt nach Import lokal nach `-Z`.
- Scale am Exportroot = 1,1,1.
- Origins/Pivots bewusst setzen; keine versteckten 100×-Skalen als Dauerlösung.

Startziel Scrap-Golem: ungefähr 1.2–1.5 m visuelle Höhe; endgültige Proportion wird im Art-Vertical-Slice festgelegt.

## 5. Rigging

Für den humanoiden Golem kann Mixamo später als schneller Basisweg dienen, sofern Geometrie und aktuelle Bedingungen passen. Mixamo ist Zulieferer, nicht Masterdatei.

Regeln:

- ein Master-Skeleton für den Player,
- nach Freigabe Bone-Namen/Hierarchie nicht bei jedem Asset neu erfinden,
- Animationen in Blender auf das Master-Rig retargeten und prüfen,
- Gameplaycode nie an einen externen Dienst oder dessen exakte Knochenbenennung koppeln.

## 6. Animationen

Weltbewegung kommt aus Godot. Produktionsanimationen sind standardmäßig **in-place**.

Erste Clipfamilie:

```text
idle
run_forward
hit_react
fall
death
dodge
hammer_attack_01
hammer_attack_02 (später)
hammer_attack_03 (später)
```

Für Desktop-Strafing später optional:

```text
run_backward
strafe_left
strafe_right
```

Mixamo eignet sich vor allem für Basismotion. Charakteristische Hammer-/Speer-/Twin-Blade-Angriffe werden bei Bedarf in Blender angepasst oder neu animiert, damit Gewicht und Timing zum Combat-Spec passen.

## 7. Waffen

Waffen sind separate Assets:

```text
player_character.glb
hammer_01.glb
spear_01.glb
twin_blade_01.glb
```

Der Player stellt einen stabilen Weapon-Mount bereit. Beim finalen Rig erfolgt die visuelle Bindung über `BoneAttachment3D`/Adapter. Combat-Reichweite und Hitbox bleiben Daten des WeaponControllers und werden nicht blind aus der Meshgröße abgeleitet.

Bei Dual-Wield später linker und rechter Mount getrennt.

## 8. Export nach Godot

Vorgesehenes Runtime-Format: **glTF 2.0 / `.glb`**.

Vor Export:

- Transformationswerte prüfen,
- ungewollte Helper/Hidden Objects entfernen,
- nur benötigte Animation-Clips,
- eindeutige Materialnamen,
- keine absoluten Dateipfade,
- keine unnötigen 8K-Texturen,
- visuelle Prüfung nach Reimport in Godot.

Rohdateien `.blend` bleiben als Source-Assets; Runtime lädt `.glb` beziehungsweise daraus erzeugte Godot-Szenen.

## 9. VFX

Combat-VFX überwiegend in Godot:

- Weapon Trails,
- `GPUParticles3D`/passende mobile Partikel,
- Impact Sparks,
- Dust Burst,
- Hitflash,
- kurzer Hit-stop,
- dezenter Camera-Shake,
- optional einfache Mesh-Ringe/Decals.

VFX darf nicht nötig sein, um Hitbox oder Plattformkante überhaupt zu verstehen. Mobile Performance messen; keine unkontrollierten transparenten Overdraw-Flächen.

## 10. Art Vertical Slice vor Massenproduktion

Bevor mehrere Figuren/Waffen produziert werden, genau **einen** vollständigen Slice erstellen:

- finalnaher Player,
- ein Hammer,
- ein Gegner,
- ein kleines Plattform-/Prop-Kit,
- 1–2 Attackanimationen,
- Hit-/Dodge-VFX,
- getesteter Godot-Import auf Smartphone + Desktop.

Erst wenn dieser Slice technisch und visuell funktioniert, Assetmenge skalieren. Dafür liegt `prompts/A1_ART_VERTICAL_SLICE.md` bereit.

## 11. Versionierung / Herkunft

Zu jedem extern oder AI-unterstützt erzeugten Produktionsasset gehören mindestens:

- lokale Source-Datei,
- Tool/Quelle,
- Datum,
- Nutzungs-/Lizenzstatus,
- Modifikationen,
- verantwortliche Masterdatei,
- Exportdatei,
- Status (raw / cleanup / rigged / approved / runtime).

Siehe `ASSET_POLICY.md` und `assets/ASSET_MANIFEST.csv`.
