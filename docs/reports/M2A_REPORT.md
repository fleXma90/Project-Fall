# Bericht: M2A — Erste aktive Kampfbegegnung

Datum: 25.09.2026  
Umfang: ausdrücklich freigegebener Teil von M2: genau ein aktiver Nahkampfgegner (Scrapling) auf der bestehenden Plattform, Spielerschaden, Sieg/Niederlage, Neustart, Moduswahl Kampf/Training. Grundlage: lokaler, ungecommitteter M1.1-Stand; lokal vollständig vorhanden, nicht an den Remote-Stand angeglichen.  
Status: implementiert; automatisierte und skriptgesteuerte gerenderte Prüfungen bestanden  
Nutzerabnahme: **offen**

## Spielbares Ergebnis

Beim normalen Start beginnt die Kampfbegegnung:

- Spieler (links unten) gegen einen **Scrapling** (rechts oben), etwa 8 m Abstand, einander zugewandt; keine Trainingsdummies.
- Der Scrapling nähert sich auf begehbarem Boden. In Reichweite holt er sichtbar aus. Die Bodenmarkierung zeigt zuerst nur den Umriss, denn die Richtung folgt noch. Bei der Festlegung leuchtet sein Auge auf, und die Markierung füllt sich bis zum Hieb von innen nach außen. Dann folgt ein diagonaler Hieb mit Trail, danach eine gut erkennbare Erholung mit gesenkter Waffe.
- Der Spieler kann ausweichen (laufen oder Dodge; iFrames wirken), Schaden und Rückstoß erhalten, zurückschlagen und den Gegner per HP (4 Hammertreffer) oder über die Kante besiegen.
- Der Spieler kann sterben (HP 0) oder herunterfallen. Ein Fall startet die Begegnung neu.
- Nach Sieg oder Niederlage erscheint eine Ergebnisanzeige mit „Neustart“ und „Zum Training wechseln“. Das Spiel ist dahinter pausiert.
- Pausemenü: „Kampf neu starten“ und „Modus wechseln: Training/Kampf“. Der M1-Trainingsmodus (drei Dummies, bisheriges Verhalten) bleibt so erreichbar.
- HUD: Spieler-HP oben links, Modus und Scrapling-HP oben mittig, Pause oben rechts. Die Debugzeile (F3) zeigt auch Gegnerzustand, Waffenphase und Festlegung.

Nicht enthalten: mehrere Gegner, zweiter Gegnertyp, zweite Ebene, Sturzschaden, Abstieg, XP/Upgrades, finale Zweihandanimation, Kameraänderung.

## Starten

Godot 4.7.2 stable, Mobile-Renderer (Vulkan Forward Mobile), Jolt, 60 Physikticks.

```powershell
cd D:\Project_Fall
$G = "D:\Godot_v4.7.2-stable_win64.exe"
& $G --path .                          # Kampfbegegnung (Standard)
& $G --path . -- --mode=training       # direkt im M1-Trainingsmodus
& $G --headless --path . --fixed-fps 60 res://tests/test_runner.tscn   # Tests, Exitcode 0 = grün
```

Steuerung unverändert. Neustart: Pausemenü, Ergebnisanzeige (Button, Enter, A) oder R.

## Tatsächliche Regeln

**Trefferschnittstelle:** `receive_hit(hit: HitInfo) -> bool` bei Player, Dummy und Scrapling. Es gibt keine gemeinsame Vererbungshierarchie. Der wiederverwendete `WeaponController` verbraucht ein Ziel pro Swing erst, wenn es den Treffer annimmt.

**Spieler getroffen:**

- HP −15 und Hitflash (rötlich).
- Knockback 5,5 m/s, linear abklingend über 0,22 s, im Zustand HIT. In HIT gibt es keine Aktionen, und die Laufeingabe überschreibt den Impuls nicht; gemessen ≈0,47 m. Danach sofort normale Steuerung.
- Ein laufender eigener Angriff wird abgebrochen. Der Takt läuft ab dem Start des abgebrochenen Angriffs weiter; es gibt keinen früheren Folgeangriff.

**Dodge-iFrames** (0,02–0,14 s, unverändert): Innerhalb des Fensters gibt es weder Schaden noch Knockback. Der abgewehrte Kontakt verbraucht den gegnerischen Swing nicht: Endet das Fenster, während der ACTIVE-Sektor den Spieler noch erfasst, trifft er normal. Gemessen: 7 abgewehrte Prüfungen, danach ein Treffer bei Dodge-Zeit 0,15 s. Dodge schützt nicht vor fehlendem Boden.

**Spielertod:** einmalig DEAD, Angriffe enden. Der Scrapling bricht seinen Angriff ab und verfolgt nicht mehr. Nach 0,9 s erscheint die Niederlage-Anzeige.

**Scrapling-Zustände:** IDLE → CHASE → ATTACK (WINDUP/ACTIVE/RECOVERY) → CHASE, dazu HIT und DEFEATED (lokale Zustandsmaschine in `scripts/actors/scrapling.gd`).

- Angriffsstart bei ≤ 1,45 m Abstand, wenn der Spieler ≤ 35° vor ihm steht; bis 1,2 m läuft er heran.
- Im Windup dreht er bis 55 % (≈0,30 s) zum Spieler, danach ist die Richtung fixiert.
- ACTIVE: kein Nachdrehen, keine Bewegung, Treffer nur hier, höchstens ein Treffer pro Angriff.
- RECOVERY: kein Schaden, keine Bewegung.
- Körperkontakt verursacht nie Schaden.
- Hammertreffer: Knockback, Hitflash, Rückwärtsneigung, 0,4 s Trefferreaktion; ein laufender Angriff wird abgebrochen.
- Ein Gegner mit HP 0, der danach noch herunterfällt, zählt nicht doppelt.

**Kante:** Eine Bodenprüfung 0,55 m vor dem Körper verhindert nur seine eigene Laufentscheidung über den Rand; er stoppt bei x ≈ 6,13, die Kante liegt bei 6,5. Knockback und Schwerkraft sind unberührt: Der Hammer schlägt ihn über die Kante (Fall-Niederlage).

**Bodenmarkierung:** Sie zeigt den exakten Trefferbereich für den Spielermittelpunkt nach derselben Formel wie die Trefferprüfung. Lesbarkeit entsteht über die Form (Umriss → wachsende Füllung), zusätzlich über das Auge.

**Neustart** (Button, R, Moduswechsel, Spielerfall im Kampf): Startpositionen, HP, Geschwindigkeiten, Zustände, Timer, Trefferlisten, Effekte, ausstehende Ergebnis- und Respawn-Timer und gehaltene Eingaben werden zurückgesetzt.

**Tuning:** Werte in `resources/tuning/scrapling_tuning.tres` und `resources/weapons/scrapling_cleaver.tres`; Tabelle in `docs/TUNING.md`.
- HP 80, 2,6 m/s.
- Windup/Active/Recovery 0,55/0,12/0,85 s, Schaden 15.
- Reichweite 1,2 m bis zur Zieloberfläche. Das passt zum ≈0,6-m-Hackmesser am 0,38-m-Arm; wirksam also ≈1,58 m zum Spielermittelpunkt.
- Winkel 100°, Höhe 1,2 m.

Spielerwerte sind unverändert, und M1.1 ist erhalten: Angriffsfaktor 1,0, Hammer 0,26/0,12/0,42 s, Richtungsregel.

## Geänderte und neue Dateien

| Pfad | Rolle |
|---|---|
| `scripts/actors/scrapling.gd`, `scrapling_tuning.gd`, `scenes/actors/scrapling.tscn`, `resources/tuning/scrapling_tuning.tres` | Gegner-Gameplay und Daten |
| `scripts/actors/scrapling_visual.gd`, `placeholder_scrapling_visual.gd`, `scenes/actors/placeholder_scrapling.tscn` | austauschbare Gegnerdarstellung (Schnittstelle + Placeholder) |
| `scenes/weapons/scrapling_cleaver.tscn`, `resources/weapons/scrapling_cleaver.tres` | separate Gegnerwaffe + Daten (wiederverwendeter `WeaponController`) |
| `scripts/vfx/attack_telegraph.gd`, `scripts/vfx/hit_flash.gd` | Bodenmarkierung; gemeinsamer Hitflash (Dummy, Golem, Scrapling) |
| `scripts/actors/player_controller.gd` | `receive_hit`, iFrames ausgewertet, Zustände HIT/DEAD, Signale `damaged`/`hit_evaded`/`died` |
| `scripts/actors/player_visual.gd`, `player_visual_state.gd`, `placeholder_golem_visual.gd` | `play_hit`, Treffer-/Niederlagepose, Hitflash |
| `scripts/combat/weapon_controller.gd` | Ziel erst bei angenommenem Treffer verbraucht |
| `scripts/actors/training_dummy.gd`, `dummy_visual.gd` | `set_active` für Moduswahl; Hitflash-Helfer |
| `scripts/levels/training_arena.gd`, `scenes/levels/training_arena.tscn` | Modi, Begegnungszustand, `restart()`, Spawns, Effekte-Knoten |
| `scripts/main.gd`, `scenes/main.tscn` | Kampf als Standard, Moduswechsel, Ergebnisanzeige, Trefferfeedback |
| `scripts/ui/encounter_overlay.gd`, `scenes/ui/encounter_overlay.tscn` | Sieg/Niederlage + Neustart |
| `scripts/ui/pause_menu.gd`, `scenes/ui/pause_menu.tscn`, `scripts/ui/hud.gd`, `scenes/ui/hud.tscn` | Moduswahl, Moduszeile, Debugzeile |
| `tests/test_runner.gd`, `tests/qa_capture.gd` | 14 neue Tests (e1–e14), Kampfsequenz in der QA |
| `docs/…` | STATUS, COMBAT_SPEC, ARCHITECTURE, TUNING, MILESTONES, ART_DIRECTION (Zweihandhammer vorgemerkt), INPUT_CONTRACT, DECISIONS (D19), PLAYTEST_CHECKLIST |

## Prüfungen

| Prüfung | Status | Befund |
|---|---|---|
| Import/Parse, Headless-Smoke | BESTANDEN | ohne Fehler/Warnungen |
| Regression M1/M1.1 | BESTANDEN | alle 26 Bestandstests grün, u. a. M1.1-Bewegung bei gehaltenem RT unverändert (0,000 m/s Abweichung) |
| M2A-Tests | BESTANDEN | 14 neue Tests; gesamt 40 Tests / 335 Checks, Exitcode 0 |
| Annäherung/Angriffsablauf (e1) | BESTANDEN | CHASE → WINDUP (33 Ticks) → ACTIVE (8) → RECOVERY (51) → CHASE; Start erst in Reichweite; keine Bewegung ab der Festlegung |
| Kein Kontaktschaden, Schaden nur in ACTIVE, 1 Treffer pro Angriff (e2, e3) | BESTANDEN | 1,5 s Körperkontakt ohne Schaden; 5 s Nahkampf: jeder Treffer in ACTIVE, je Swing höchstens einer |
| Kein Nachdrehen nach Festlegung (e4) | BESTANDEN | vor der Festlegung folgt die Richtung, danach bleiben Sektor, Drehung und Position fix; ausgewichener Spieler nicht getroffen |
| Reichweite/Winkel/Höhe (e5) | BESTANDEN | vorne/60° getroffen; zu weit, 90°, hinten, zu hoch nicht |
| Dodge-iFrames (e6) | BESTANDEN | kein Schaden/Knockback im Fenster, danach normaler Treffer; ohne Dodge Treffer |
| Gültiger Treffer (e7) | BESTANDEN | HP −15, 0,47 m Rückstoß trotz Gegenlenken, kein Teleport, danach normale Steuerung |
| Abgebrochene Angriffe (e8) | BESTANDEN | unterbrochener Gegnerangriff trifft nie; unterbrochener Spielerangriff trifft nie und beschleunigt den Folgeangriff nicht |
| Niederlage genau einmal (e9) | BESTANDEN | HP-Niederlage + späterer Fall = 1; Kanten-Niederlage per Hammer trotz Bodenprüfung = 1; Sieg je Runde einmal gemeldet |
| Bodenprüfung (e10) | BESTANDEN | Verfolgung stoppt vor der Kante, kein Sturz |
| Spielertod + Neustart (e11) | BESTANDEN | Tod einmal, Kampf stoppt, Anzeige + Pause; Klick auf Neustart setzt alles zurück, ohne Weltangriff |
| Spielerfall im Kampf (e12) | BESTANDEN | Begegnung genau einmal zurückgesetzt, Gegner greift während des Falls nicht an |
| Moduswechsel/Pause (e13) | BESTANDEN | per Button bei gehaltenem RT: keine hängende Eingabe, kein Klick-Angriff; Dummies nur im Training, Gegner nur im Kampf |
| Gerenderte Kampfsequenz | BESTANDEN (skriptgesteuert) | Intel UHD 620, Vulkan Mobile. 1280×720 @60 und @30, 1600×720 @60, 1024×768 @60. Zeitreihe `16_enemy_cycle_sheet.png` (40 Bilder/3,6 s): Ausholen → Markierung (Umriss → Füllung) → Hieb mit Trail und Einschlag → Erholung. Einzelbilder: Festlegung, Ausweichen seitlich aus dem fixierten Sektor (HP 100), Treffer (HP 85), Konter (Gegner-HP 60), Kantensturz → Sieg-Anzeige, Niederlage-Anzeige, Pause mit Moduswahl; Neustart per Button setzt HP 100/80 |
| 30/60 Render-FPS | BESTANDEN | 60,6 bzw. 30,6 FPS bei ≈62–63 Physikticks je Wandsekunde (bei beiden Raten gleich) |
| Echter Controller / Smartphone | OFFEN | alles simuliert; keine Hardwareabnahme |

Beobachtung aus der QA: In einem gerenderten Lauf blieben in der M1.1-Zeitreihe „RT gehalten + 360°“ nach dem ersten Swing weitere Swings aus. Die Wiederholung, nun mit Protokoll der Eingabequellen, lief korrekt (3 Swings, kein Quellenwechsel), ebenso die drei weiteren Läufe. Die wahrscheinliche Ursache ist eine echte Maus-/Systemeingabe über dem QA-Fenster: Sie schaltet die Quelle um, und der gehaltene Trigger wird dann gelatcht (gewolltes Verhalten). Belegt ist das nicht. Die Headless-Tests zum gehaltenen Angriff sind grün.

## Playtestbefund: Dauerschlagen

Messung (`test_e14`, simuliert): Der Spieler hält RT und läuft auf den Scrapling zu. **Nach 3,6 s ist der Scrapling besiegt, mit 4 Hammertreffern. Er beginnt 4 Angriffe, erreicht aber nie ACTIVE; der Spieler nimmt 0 Schaden.**

Ursache: Hammer-Windup 0,26 s gegen Gegner-Windup 0,55 s, jeder Treffer unterbricht (0,4 s Reaktion), und der Spieler folgt dem Knockback mit voller Geschwindigkeit. Laut Auftrag **nicht ausgeglichen**: kein Hyperarmor, keine Immunität.

Mögliche Hebel für eine spätere Entscheidung:
- Gegner-Windup verkürzen,
- Trefferreaktion kürzer oder nicht bei jedem Treffer,
- größerer Rückstoß aus der Reichweite,
- Gegner greift aus größerer Distanz an,
- Spieler-Knockback beim eigenen Treffer.

## Offene Punkte

- Das Gefühl ist nicht beurteilt (Lesbarkeit des Windups, Fairness des Ausweichens, Dauerschlagen).
- Der Scrapling ist nur wenig kleiner als der Golem; Silhouette und Farbe unterscheiden sich klar, die Größe kaum.
- iFrames werten den Spielerzustand des vorigen Physikticks aus (Gegner wird vor dem Spieler verarbeitet): höchstens 1 Tick (16 ms) Versatz.
- Die Ergebnisanzeige pausiert das Spiel. Nach einem Sieg kann man bis zum Neustart nicht weiterlaufen.
- Weiter offen: Smartphone, Android-Export, Displays > 60 Hz, Kamera (bewusst zurückgestellt), Zweihandhammer (Art-Meilenstein).

## Nächster Controller-Spieltest

1. Starten (`& $G --path .`), den Scrapling kommen lassen. Sind Ausholen, Auge und Markierung rechtzeitig lesbar?
2. Nach dem Aufleuchten zur Seite laufen bzw. dodgen: Der Hieb geht ins Leere. Dodge genau im Hieb: kein Schaden.
3. Einen Treffer einstecken: Ist der Rückstoß nachvollziehbar und die Steuerung danach sofort wieder da?
4. Einmal gezielt in der Erholung kontern, einmal über die Kante schlagen, einmal RT durchhalten (Dauerschlagen). Ist das zu stark?
5. Sterben, herunterfallen, Neustart und Pause → Moduswechsel mit gehaltenem RT: Bleibt nichts hängen?

## Stopp

Restlicher M2 (mehrere Gegner, zweite Ebene, Sturzschaden, Abstieg), M3, Art-Meilenstein, Kamera, Face-before-move und Android-Setup wurden nicht begonnen. Keine Installationen, kein Commit/Push.
