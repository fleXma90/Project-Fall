# Bericht: M0 + M1 — 3D-Gameplay-Blockout

Datum: 25.09.2026  
Umfang: Startauftrag M0 + M1 (`STARTER_PROMPT.md`): startbares Godot-4-Projekt, Trainingsarena mit offener Plattform, Dummy-Golem mit Hammer, drei passive Dummies, Fall/Respawn, Touch/Controller/Desktop-Input, HUD/Pause/Reset  
Status: implementiert; automatisierte und gerenderte Prüfungen lokal bestanden; Hardware-/Gefühlsabnahme offen  
Nutzerabnahme: offen

## Spielbares Ergebnis

Der Nutzer kann auf Desktop (und per simuliertem Touch/Controller geprüft):

- sich 360° camera-relative auf einer offenen 3D-Plattform bewegen (WASD / linker Stick / Touch-Stick),
- die Blickrichtung mit der Maus (Ray/Ebene in 3D) bzw. mit der letzten Stickrichtung steuern; neutraler Stick behält das Facing,
- mit LMB / RT / Touch-Attack einen sichtbaren Hammer-Swing ausführen (Ausholen → Schlagbogen mit Trail → Nachlauf), gehalten wiederholt im vollen Takt,
- drei Dummies treffen (Hitflash, Funken/Flash, dezenter Camera-Shake, Wackeln, HP-Anzeige) und per XZ-Knockback verschieben,
- Dummies per HP (5 Treffer) oder über die Kante besiegen; sie respawnen nach 2,5 s,
- mit RMB/Space / LT / Touch-Dodge kontinuierlich ausweichen (auch über die Kante),
- selbst über die Kante laufen oder dodgen → echter Fall mit Fallpose → Respawn am Spawn,
- per Pause-Button, Esc oder Start pausieren; im Menü „Weiter“, „Training zurücksetzen“, „Touch-Testmodus“ (per Touch/Maus/Controller bedienbar). Debug: R = Reset, F2 = Touch-Testmodus, F3 = Debugzeile.

Fehlt bewusst (nicht im Umfang): Gegner-KI, Schaden am Player, zweite Ebene, Sturzschaden, XP/Upgrades, Produktionsassets, Audio.

## Starten

Godot-Version: **4.7.2.stable.official (ed1daf0bf)**, geprüft (`D:\Godot_v4.7.2-stable_win64.exe --version`)  
Renderer: **Mobile** (`rendering/renderer/rendering_method="mobile"`); tatsächlich lokal: *Vulkan 1.1.95 – Forward Mobile – Intel UHD Graphics 620*. Kein Compatibility-Fallback nötig.  
Physik: Jolt Physics (explizit gesetzt), 60 Ticks/s, Gravity 18 m/s²  
Hauptszene: `res://scenes/main.tscn` (startet direkt in die Trainingsarena)  
Startweg: Editor → Projekt öffnen → F5, oder `& "D:\Godot_v4.7.2-stable_win64.exe" --path "D:\Project_Fall"`  
Android-Ausgabe: **nicht erstellt** — keine Exportvorlage/`export_presets.cfg`, Android-SDK nicht geprüft (kein ungefragtes Setup).

Prüfbefehle:

```powershell
$G = "D:\Godot_v4.7.2-stable_win64.exe"
& $G --headless --path . --import
& $G --headless --path . --quit-after 300
& $G --headless --path . --fixed-fps 60 res://tests/test_runner.tscn          # Exitcode 0 = alle Tests grün
& $G --path . --resolution 1280x720 --max-fps 60 res://tests/qa_capture.tscn -- --qa-out=qa/output/1280x720_60
```

## Assetstatus

Placeholder/Production: nur Godot-Primitiven (Box/Cylinder/Capsule/Sphere-Meshes, StandardMaterial3D), ein selbst geschriebener Kachel-Shader (`assets/placeholder/platform_tiles.gdshader`), ImmediateMesh-Trail, CPUParticles3D, Engine-Standardschrift.  
Externe Assets genutzt: **nein** (Manifest bleibt leer).  
VisualRoot austauschbar: **geprüft** (Test A1: Placeholder entfernt, anders strukturierter Adapter mit fremdem Socket-Namen eingesetzt → Weapon-Mount folgt, Angriff trifft; ganz ohne Visual läuft Bewegung weiter).

Architekturgrenzen:

- `Player` (`CharacterBody3D`, `player_controller.gd`) besitzt Bewegung, HP, Kollision, Facing-/Attack-/Dodge-Zustand. Er kennt die Darstellung nur über `PlayerVisual` (`apply_state`, `get_weapon_socket`, `play_respawn`) und findet sie per Typ unter `VisualRoot` — keine Mesh-/Knotennamen.
- `PlaceholderGolemVisual` animiert nur eigene Knoten (Body-Bob, Beine, Lean, Dodge-Squash, Fallpose, Hammerbogen am `SwingPivot`) aus Gameplay-Phase + Fortschritt. Später ersetzt ein Adapter um ein riggtes `.glb` diese Szene und liefert den Hand-Socket (z. B. `BoneAttachment3D`) — keine Bone-Namen im Gameplaycode.
- `WeaponController` besitzt Timing, `swing_id`, Trefferabfrage (Kugel-Query + Sektorprüfung) aus `WeaponData` (`resources/weapons/hammer.tres`). Die Waffe `scenes/weapons/hammer.tscn` hängt unter `WeaponMount`, der dem Socket rein visuell folgt. Reichweite/Winkel nie aus der Meshgröße.
- Weltbewegung kommt ausschließlich aus Godot-Code (kein Root-Motion); Animationen können später in-place laufen.

## Geänderte Dateien

Neu (keine Briefingdatei überschrieben, außer `docs/STATUS.md` wie beauftragt):

| Pfad | Rolle |
|---|---|
| `project.godot` | Projekt, Mobile-Renderer, 60 Hz, Gravity, Landscape, Stretch `canvas_items`/`expand`, Autoload `InputRouter`, Layer-Namen |
| `scripts/input/input_router.gd` | Zentraler Router: aktive Quelle, Touch-Fingerbesitz, Trigger-Hysterese 0.35/0.20, radiale Deadzone 0.18, Buffer 0.10 s, Release bei Pause/Fokus/Disconnect/Quellenwechsel; registriert Eingabeaktionen zur Laufzeit |
| `scripts/actors/player_controller.gd`, `player_tuning.gd`, `resources/tuning/player_tuning.tres` | Player-Gameplay + Tuning |
| `scripts/actors/player_visual.gd`, `player_visual_state.gd` | Visual-Adapter-Schnittstelle |
| `scripts/actors/placeholder_golem_visual.gd`, `scenes/actors/placeholder_golem.tscn` | M1-Placeholder-Golem |
| `scenes/actors/player.tscn` | Player: Collision, VisualRoot, WeaponController/WeaponMount/Hammer, AttackOrigin, SwingTrail |
| `scripts/combat/weapon_controller.gd`, `weapon_data.gd`, `hit_info.gd`, `resources/weapons/hammer.tres`, `scenes/weapons/hammer.tscn` | Combat-Logik, Hammerdaten, separate Waffenszene |
| `scripts/actors/training_dummy.gd`, `dummy_visual.gd`, `scenes/actors/training_dummy.tscn` | Passiver Dummy (HP, Knockback, idempotente Niederlage) |
| `scripts/levels/training_arena.gd`, `scenes/levels/training_arena.tscn`, `assets/placeholder/platform_tiles.gdshader` | Offene Plattform 13 × 10 m, Killhöhe −5 m, Spawn, 3 Dummies, Respawn/Reset |
| `scripts/camera/camera_rig.gd` | Feste schräge Kamera, weiches Folgen, dezenter Shake |
| `scripts/vfx/swing_trail.gd`, `impact_burst.gd`, `scenes/vfx/impact_burst.tscn` | Swing-Trail (zeigt den tatsächlichen Treffersektor), Impact |
| `scripts/ui/hud.gd`, `pause_menu.gd`, `touch_controls.gd`, `safe_area.gd`, `scenes/ui/*.tscn` | HUD, Pause, Touchcontrols, Safe-Area |
| `scripts/main.gd`, `scenes/main.tscn` | Verdrahtung |
| `tests/test_runner.gd/.tscn`, `tests/swap_test_visual.gd` | 22 Headless-Verhaltenstests |
| `tests/qa_capture.gd/.tscn` | Gerenderte QA-Sequenz mit Screenshots + FPS/Tick-Messung |
| `assets/ASSET_MANIFEST.csv.import` | `importer="keep"`, damit Godot das Manifest nicht als Übersetzungstabelle importiert (Manifest selbst unverändert) |
| `docs/STATUS.md`, `docs/reports/M1_REPORT.md` | Status/Bericht |

## Nachweise

| Prüfung | Status | Umgebung / Befund |
|---|---|---|
| Import/Parse | BESTANDEN | `--headless --import` ohne Fehler/Warnungen; Headless-Smoke `--quit-after 300` ohne Fehler |
| Verhaltenstests | BESTANDEN | 22 Tests / 122 Checks, Exitcode 0 (`--fixed-fps 60`). Eingaben als echte InputEvents über `Viewport.push_input` durch den Router |
| Gerenderte 3D-Session | BESTANDEN (automatisiert) | Windows 10, Intel UHD 620, Vulkan Forward Mobile; QA-Sequenz mit 12 Screenshots je Konfiguration in `qa/output/` (nicht versioniert). **Keine manuelle Spielsession** |
| 16:9 / 20:9 / 4:3 | BESTANDEN (Screenshots) | 1280×720, 1600×720, 1024×768 (Canvas 1280×960): HUD, Pause, Touchcontrols, Plattformkanten lesbar, keine Überlappung der Controls |
| 30/60 Render-FPS | BESTANDEN | `--max-fps 60`: 60,7 FPS / 61,7 Physikticks pro Wandsekunde; `--max-fps 30`: 30,7 FPS / 61,7 Ticks. `physics_ticks_per_second` bleibt 60; Messabweichung ≈3 % zwischen Spiel- und Wanduhr, bei beiden Raten gleich |
| Offene Kante/Fall | BESTANDEN | F1: einziger statischer Collider ist die Plattform, Raycasts 0,1 m außerhalb aller vier Kanten treffen nichts, keine Barriere in 0,1/0,6/1,5 m Höhe; F1b: Player/Dummy mit Schwerpunkt 0,2 m jenseits der Kante fallen; F2: Laufen und Dodge über die Kante fallen unter −5 m, Reset genau einmal, kein Sturzschaden; F3: Kanten-Kill und HP-Kill je genau einmal |
| Echter Controller | OFFEN | Kein Controller geprüft. Nur simulierte `InputEventJoypadMotion`/-Button-Events (Stick, RT/LT-Hysterese, Disconnect-Pfad per Direktaufruf) |
| Echtes Smartphone | OFFEN | Kein Gerät/Export. Touch nur simuliert (`InputEventScreenTouch/Drag`, 3–4 Finger) und im Desktop-Touch-Testmodus |

Einzelne automatisierte Regeln (Checkliste):

| ID | Status | Nachweis |
|---|---|---|
| I1 | BESTANDEN | W bewegt auf dem Bildschirm exakt nach oben (dx ≈ 0), Diagonale ≤ 4,6 m/s |
| I2 | BESTANDEN | Stick-Facing bleibt nach Neutral, bei Fremdgeschwindigkeit/Gravitation und Rauschen in der Deadzone; Controller rechts-oben → loslassen → RT: Schlag bleibt rechts-oben, Dummy links bleibt unberührt |
| I3 | BESTANDEN | RT 2 s gehalten → genau 4 Swings, Abstand ≥ 0,52 s; schnelles Nachdrücken erzeugt keinen Extra-Swing |
| I4 | BESTANDEN | LT 2 s → 1 Dodge; Trigger-Pendeln 0,25–0,30 → 0 Dodges; Space mit Echo → 1 Dodge |
| I5 | BESTANDEN | Mausmikrobewegung übernimmt nicht und dreht nicht; echte Bewegung übernimmt |
| I6 | BESTANDEN | Pause/Fokusverlust/Disconnect/Reset lösen Held-Inputs; gehaltener RT nach Pause gelatcht bis Loslassen; Disconnect pausiert |
| Touch | BESTANDEN (simuliert) | Stick + Attack + Dodge gleichzeitig unabhängig, kein Fingerdiebstahl, gehaltener Dodge-Finger → kein Zweit-Dodge, emulierte Maus zählt nicht als Angriff |
| Maus 3D | BESTANDEN | 12 Richtungen, max. Abweichung < 1° (Ray/Ebene in Spielerhöhe); Maus auf Player behält Facing; A + Maus rechts: Bewegung links, Facing rechts |
| UI | BESTANDEN | Klick auf Pause-Button öffnet Pause ohne Weltangriff |
| C1 | BESTANDEN | Ein Swing trifft ein Ziel genau einmal (−20 HP) |
| C2 | BESTANDEN | Rückseite, 90°-Seite, zu weit, Höhenunterschied → kein Treffer; zwei Ziele im Sektor → beide |
| C3 | BESTANDEN | Dodge-Abbruch: nächster Swing frühestens 0,52 s nach dem ersten |
| C4 | BESTANDEN | Max. Schritt ≤ v/60 (kein Teleport); 1,05 m bei 60 Hz vs. 0,99 m bei 30 Hz Physik |
| F1–F3 | BESTANDEN | siehe oben |
| A1 | BESTANDEN | siehe Assetstatus |

## Tuning-Abweichungen von `docs/TUNING.md`

| Parameter | TUNING | M1 | Grund |
|---|---:|---:|---|
| Knockback Start / Abklingzeit | 6,0 m/s / 0,18 s | **8,0 m/s / 0,28 s** | Startwerte ergeben bei linearem Abklingen nur ≈0,54 m pro Treffer; Hammer soll „hohen Knockback“ haben. Gemessen jetzt ≈1,05 m |
| Kamera | ortho 15–18 m | **Perspektive, FOV 30°, Abstand 23 m** (Pitch 48°, Yaw 45°) → ≈12 m sichtbare Höhe | Bei 16 m war der Golem nur ≈50 px hoch; schwache Perspektive zeigt Plattformseiten/Falltiefe besser |
| neu: Luftsteuerung | – | 4 m/s² | Ein Fall soll nicht zurückgelenkt werden können |
| neu: `floor_max_angle` Player/Dummy | Godot 45° | **20°** | Bei 45° standen Kapseln mit Schwerpunkt bis ≈0,28 m jenseits der Kante noch auf der Kantenrundung (gerenderter Befund, Regressionstest F1b) |
| neu: weitere | – | Drehschärfe 22/s (nur Darstellung), FALLING ab 0,12 s Luftzeit, Maus-Mindestabstand 0,25 m, Killhöhe −5 m, Player-Respawn 0,55 s, Dummy-Respawn 2,5 s, Kamera folgt beim Fallen nur bis y = −1,5 | M1-Startwerte |

Alle übrigen Werte entsprechen `TUNING.md` (Speed 4,6, Accel 24, Decel 30, Attack-Multiplikator 0,70, Dodge 0,18 s / 10 m/s / Cooldown 0,70 s / iFrames 0,02–0,14 s, Hammer 0,14/0,10/0,28 s, 20 Schaden, 1,9 m, 110°, Dummy 100 HP).

## Offene Probleme / Vereinfachungen

- **Kein Hardwaretest:** Controller, Smartphone, Safe-Area auf echtem Gerät und App-Hintergrund-Pause sind nur implementiert bzw. simuliert. Reconnect-Latch ist implementiert, aber ungetestet.
- **Keine manuelle Spielsession:** Spielgefühl (Gewicht des Hammers, Dodge-Timing, Kantenfairness) ist nicht beurteilt; alle gerenderten Nachweise stammen aus einer skriptgesteuerten Sequenz.
- **Kein Android-Export** eingerichtet; Mobile-Renderer nur auf Windows/Vulkan geprüft.
- **Physik-Interpolation aus:** Auf Displays > 60 Hz kann Bewegung zwischen Physikticks gestuft wirken (nicht geprüft).
- Trefferfenster prüft während der 0,10 s Aktivphase den vollen 110°-Sektor (kein fortschreitender Bogen); der Trail zeichnet genau diesen Sektor.
- Knockbackrichtung = normalisierte Summe aus Schlagrichtung und radialer Richtung (vorhersehbar, aber Gefühlstest offen).
- Dodge-iFrames existieren (`is_invulnerable()`), haben in M1 mangels Schadensquellen keine Wirkung.
- Eingabeaktionen werden im Code registriert (`input_router.gd`) und erscheinen nicht in den Projekteinstellungen; Rebinding ist nicht im Umfang.
- Placeholder: Der rechte Arm zeigt in Ruhepose nach hinten oben (Hammer auf der Schulter) — Blockout, nicht Zielstil. Debugzeile ist standardmäßig sichtbar (F3).
- Eine echte Maus über dem Fenster setzt beim Start sofort Maus-Facing (erwartetes Verhalten, aber beim ersten Eindruck sichtbar).

## Nächster manueller Test

1. Projekt im Editor öffnen, F5: Kreis/Diagonalen mit WASD laufen, Maus unabhängig drehen, LMB halten — wirkt der Hammer schwer und die Richtung vorhersehbar?
2. Rechten Dummy mehrfach Richtung Kante schlagen, bis er fällt; danach selbst über die Kante laufen und einmal mit Space über die Kante dodgen — genau ein Reset, keine unsichtbare Wand?
3. Controller anschließen: Stick schräg → loslassen → RT; LT 2 s halten; Start → Menü mit Steuerkreuz/A bedienen; Controller während gehaltenem RT abziehen.
4. Esc während gehaltenem LMB, fortsetzen → kein hängender Angriff; „Training zurücksetzen“ im Menü.
5. Falls Android-Gerät vorhanden: Export einrichten und Stick + gehaltener Attack + Dodge mit drei Fingern, Safe-Area und Buttonerreichbarkeit prüfen.

## Stopp

M2 (zweite Ebene, Gegner-KI, Sturzschaden), M3 (XP/Upgrades), A1 (Art Vertical Slice) und Produktionsassets wurden nicht begonnen. Kein Blender/Mixamo/MCP/AI-3D, keine Installationen, kein Commit/Push.
