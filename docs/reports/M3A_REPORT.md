# Bericht: M3A — Run Progression V1 (XP, Attribute, Floor-Clear-Upgrades)

Datum: 26.09.2026  
Umfang: Auftrag „M3A — Run Progression V1“ plus Nutzerergänzung: Gegner lassen sichtbare XP fallen, die man in der Nähe (leicht magnetisch) einsammelt, auch nach einem Sturz über die Kante; keine automatische Gutschrift beim Kill.  
Ausgangsstand: `13981ee` (M2D–M2D.2, GitHub `main`)  
Status: implementiert (Prototyp mit Dummy-Assets), nicht committet  
Nutzerabnahme: offen

## Spielbares Ergebnis

- **Abstieg** (Standardstart) ist jetzt ein Run mit Progression. Mischkampf, Gruppe, Duell und Training verhalten sich wie vorher (kein Run, keine XP, kein STATS-Button).
- **XP-Orbs:** Besiegte Gegner werfen grüne Orbs ab (Scrapling 3 × 10 XP, Funkenwerfer 4 × 10 XP). Nach einem Kantensieg springen sie aus der Tiefe auf die Ebene, an die letzte Bodenposition des Gegners. Ab 2.2 m Abstand werden sie zum Spieler gezogen und beim Kontakt gutgeschrieben.
- **Level:** Schwellen 60, 90, 120 … (60 + 30 · (Level − 1)), Überschuss wird übernommen. Level-Up mitten in der Aktion ohne Pause: Einblendung „LEVEL UP! +1 ATTRIBUTSPUNKT“ (Folge-Level-Ups zusammengefasst) und goldener Ring am Spieler.
- **HUD** (nur Abstieg): „LV n“, XP-Leiste und STATS-Button unter der HP-Anzeige. Mit offenen Punkten zeigt er „STATS +n“ mit grünem Rahmen.
- **Stats-Screen:** öffnet per STATS-Button, Taste C oder Controller View/Back und pausiert das Spiel. Pro Attribut sieht man Rang x/8, den aktuellen Wert und die Vorschau auf den nächsten Rang sowie einen „+“-Button. Schließen per X, Schließen-Button, C, View/Back oder Esc/B; Esc öffnet dabei keine Pause. Nicht öffnbar im Fall oder hinter anderen Fenstern.
- **Sechs Attribute:** Stärke, Vitalität (ohne Heilung), Tempo (alle Hammerphasen proportional), Beweglichkeit (inkl. Beschleunigung/Abbremsung), Wucht, Erholung.
- **Floor-Clear-Upgrade:** Nach dem Räumen von Ebene 1 werden die Orbs eingesaugt, dann folgt eine Pflichtauswahl 1 aus 3 (EBENE GERÄUMT). Erst danach öffnet sich die Luke.
- **Früher Sturz:** Fortschritt bleibt, liegende Orbs verfallen, kein Upgrade, 12 Sturzschaden. Stirbt der letzte Gegner, während der Spieler schon fällt, erscheint die Auswahl nach der Landung, bevor die Gegner der Ebene 2 aktiv werden.
- **Run-Ende:** Tod oder Ebene-2-Sturz führt zu Niederlage, „Abstieg geschafft“ zu Sieg. Die Ergebnisanzeige zeigt zusätzlich Level, verteilte/offene Punkte und Upgrades. Jeder Neustart beginnt einen neuen Run auf Basiswerten.

Fehlt bewusst: Respec, Reroll/Skip, Relikte, Meta-Progression, dritte Ebene, Floor-Variety.

## Starten

Godot-Version: 4.7.2.stable.official (geprüft)  
Renderer: Mobile (Vulkan Forward Mobile, Intel UHD 620)  
Hauptszene: `res://scenes/main.tscn` (Standard: Abstieg)  
Startweg: `& "D:\Godot_v4.7.2-stable_win64.exe" --path "D:\Project_Fall"`  
Android-Ausgabe: OFFEN (kein Export eingerichtet)

## Assetstatus

Placeholder/Production: nur Godot-Primitiven (Kugel-Orbs, Torus-Ring, Partikel) und vorhandene selbst geschriebene Shader  
Externe Assets genutzt: nein  
VisualRoot austauschbar: unverändert; keine Statlogik in Visuals/VFX

## Geänderte Dateien

| Pfad | Rolle |
|---|---|
| `scripts/run/run_state.gd` (neu) | RunState: Level/XP/Punkte/Ränge/Upgrades, XP-Formel, seedbarer RNG, Modifikator-Berechnung, Anzeigetexte |
| `scripts/run/xp_orb.gd` (neu) | Sichtbarer XP-Orb: Aufspringen, Schweben, Magnet, Sog, Einsammeln |
| `scripts/vfx/level_up_burst.gd` (neu) | Level-Up-Effekt am Spieler |
| `scripts/ui/stats_screen.gd` (neu) | Modaler Attribut-Screen |
| `scripts/ui/floor_reward_screen.gd` (neu) | Pflichtauswahl 1 aus 3 |
| `scripts/combat/weapon_controller.gd` | Laufzeitmodifikatoren (Tempo, Schaden, Knockback, Bogen, Reichweite); `data` unverändert |
| `scripts/actors/player_controller.gd` | `set_run`, `apply_run_modifiers`, `max_hp`, `move_factor`, `dodge_cooldown`, Momentum/Kinetische Erholung |
| `scripts/actors/scrapling.gd`, `sparker.gd` | `last_ground_position` (Orb-Abwurfort nach Kantensieg) |
| `scripts/levels/training_arena.gd`, `scenes/levels/training_arena.tscn` | Run-Lebenszyklus, Orbs (`Pickups`), Clear-/Sturz-Regeln, Belohnungsablauf, XP-Werte |
| `scripts/main.gd`, `scenes/main.tscn` | Stats-/Reward-Screens, Stats-Eingabe, Level-Up-Effekt, Run-Zusammenfassung im Ergebnis |
| `scripts/ui/hud.gd`, `scenes/ui/hud.tscn` | Level, XP-Leiste, STATS-Button mit Badge, Level-Up-Einblendung; Debugzeile nach unten verschoben |
| `scripts/input/input_router.gd` | Aktion `stats` (C, Controller Back) |
| `scripts/vfx/swing_trail.gd`, `attack_telegraph.gd` | Effektive Reichweite/Bogen/Phasendauer statt Rohdaten |
| `tests/test_runner.gd` | `test_r1`–`test_r12`; Abstiegs-Hilfen wählen jetzt das Pflicht-Upgrade |
| `tests/qa_capture.gd` | `--qa-run` (Shots 65–76); Abstiegssequenz/Video wählen das Upgrade |
| `docs/…` | `RUN_PROGRESSION.md` (neu), STATUS, MILESTONES, DECISIONS (D36–D40), TUNING, ARCHITECTURE, COMBAT_SPEC, PLAYTEST_CHECKLIST, INPUT_CONTRACT; M2D-Bericht: Commitstatus korrigiert |

## Runtime-Berechnung

Basiswert (unveränderte Ressource) × Attributfaktor × Upgradefaktor, Bogen und Reichweite additiv. Bei jeder Änderung von Attributen/Upgrades wird alles aus RunState + Basis neu gesetzt; nichts wird beim Floorwechsel erneut angewendet. Beispiel Stärke 2 + Verdichteter Hammerkopf: 20 × 1.10 × 1.15 = 25.3. Tabelle aller Werte: `docs/RUN_PROGRESSION.md`.

## Nachweise

| Prüfung | Status | Umgebung / Befund |
|---|---|---|
| Import/Parse | BESTANDEN | headless, ohne Fehler/Warnungen |
| Verhaltenstests | BESTANDEN | 93 Tests / 1035 Checks, davon 12 neue M3A-Tests; alle M1–M2D.2-Regressionen grün |
| Gerenderte 3D-Session | BESTANDEN (skriptgesteuert) | Shots 65–76, siehe unten |
| 16:9 / 20:9 / 4:3 | BESTANDEN | 1280×720, 1600×720, 1024×768: HUD-Panel, Stats-Screen (6 Zeilen, Buttons 64×52) und drei Karten passen, Fokusrahmen sichtbar |
| 30/60 Render-FPS | BESTANDEN | 31.3 bzw. 61.4 Render-FPS bei 60 Physikticks (Ebene 2) |
| Offene Kante/Fall | BESTANDEN | M2D-Reveal und senkrechter Fall unverändert (`test_z1`–`z10` grün) |
| Echter Controller | OFFEN | nur simulierte Events (View/Back, Trigger, Fokus) |
| Echtes Smartphone | OFFEN | kein Gerät/Export |

**Neue Tests:**
- **r1 Lebenszyklus:** Basiswerte, HUD nur im Abstieg; Mischkampf/Gruppe/Duell/Training ohne Run, ohne Orbs, ohne Stats; die Rückkehr zum Abstieg startet einen neuen Run.
- **r2 Orbs:** 30/40 XP, Orbs statt Sofortgutschrift, Magnet bei 1.6 m, kein doppeltes XP, Kantensieg gleich viel XP und Orbs sicher auf der Ebene.
- **r3 XP-Kurve:** Formel, Übertrag, mehrere Level-Ups in einem Ereignis, keine automatischen Attribute.
- **r4 Investieren:** ohne Punkte nicht möglich, genau 1 Punkt je Rang, Maximalrang 8, Plus-Button deaktiviert, ein Punkt pro Frame, Vorschau, Punkte bleiben gespart.
- **r5 Attributwirkungen:**
  - Stärke 21 Schaden, die Gegnerwaffe bleibt unverändert.
  - Vitalität 45/100 → 45/110, ohne Heilung.
  - Tempo skaliert alle Phasen; ein echter Schwung trifft das effektive Timing.
  - Beweglichkeit: gleiche Ticks bis Vollgas und bis Stopp.
  - Wucht verändert nur das Knockback-Tempo, Erholung nur die Dodge-Abklingzeit.
  - Die Ressourcen sind danach unverändert.
- **r6 Upgrades:** alle sechs; Kombination mit Stärke; kein Duplikat. Momentum stapelt nicht, wird erneuert, endet nach 1.5 s und wird durch einen echten Treffer ausgelöst. Kinetische Erholung zieht höchstens einmal pro Swing 0.20 s ab. Die Hammer-Ressource bleibt unverändert.
- **r7 Level-Up:** keine Pause, Einblendung, Badge +1/+3, Zusammenfassung „×3“, Effekt am Spieler, Welt läuft weiter, Einblendung verschwindet.
- **r8 Stats-Eingabe:**
  - C öffnet; Welt und Projektil stehen.
  - Esc schließt ohne Pause; View/Back öffnet und schließt.
  - Ein bei offenen Stats gedrückter RT greift nach dem Schließen erst nach erneutem Drücken an.
  - Der Mausklick auf STATS löst keinen Angriff aus; der Button liegt außerhalb der Touch-Zonen.
  - Im Fall lassen sich die Stats nicht öffnen.
- **r9 Floor-Upgrade:** Luke erst nach der Wahl, Sog bis 100 XP, genau 3 unterschiedliche Karten, Esc überspringt nicht, Controller-Fokus, genau ein Upgrade, gleicher Seed = gleiche Auswahl, erschöpfter Pool ohne Duplikate, kein Upgrade nach dem finalen Floor.
- **r10 Früher Sturz:** Level, Ränge, Upgrades und XP bleiben; Orbs verfallen, kein Upgrade, 12 Schaden, Modifikatoren unverändert.
- **r11 Clear im Fall:** keine Auswahl im Fall, Auswahl nach der Landung, 100 XP gutgeschrieben, Gegner erst nach der Wahl aktiv, Landeschutz danach.
- **r12 Reset:** Tod, Ebene-2-Sturz und Profilwechsel führen jeweils zu einem neuen Run: Basiswerte, keine Buffs/Orbs/Belohnung, Badge zurückgesetzt.

**Gerenderte Sequenz (`--qa-run`):**
- Shot 65: Start-HUD.
- Shot 66: Echter Hammerschlag, Orbs springen heraus (3 Orbs, 30 XP).
- Shot 67: Level-Up beim Durchlaufen, während Gegner angreifen (Pause aus, „STATS +1“).
- Shot 68: Badge „STATS +2“.
- Shots 69–70: Stats per View/Back mit Fokusrahmen; Stärke und Beweglichkeit investiert (21.0 Schaden, 4.71 m/s).
- Shot 71: Clear mit Orb-Sog.
- Shot 72: Pflichtauswahl bei geschlossener Luke (220 XP gesamt).
- Shot 73: Luke offen nach der Wahl von „Langer Griff“.
- Shot 74: Ebene 2 mit Level 3, Reichweite 2.15 m, Schaden 21 und 4.71 m/s.
- Shot 75: Neuer Run auf Basis (20.0 / 4.60 / 100).
- Shot 76: Früher Sturz: 30 XP bleiben, keine Auswahl, 88 HP.

## Offene Probleme / Vereinfachungen

- **Balance ungeprüft:** Ein vollständiger Floor gibt 100 XP, zwei Floors enden bei Level 3. 12 Sturzschaden stehen gegen Upgrade + XP des Floors. Tempo/Erholung Rang 8 und der Magnetradius 2.2 m sind Prototypwerte.
- **Orbs vs. Kampf:** Liegende Orbs verlangen Umwege. Der Sog beim Clear nimmt den Druck erst nach dem Kampf; ob das Einsammeln im Kampf reizvoll oder lästig ist, muss der Spieltest zeigen.
- **Stats-Screen ist ein Debug-/Prototyp-Layout** (nur Texte und Buttons).
- **Einblendung pausiert mit:** Die Level-Up-Anzeige hält bei geöffnetem Stats-/Upgrade-Screen an und läuft danach weiter.
- **Anzeige der Punktabstufung:** Werte werden mit 2 Nachkommastellen gerundet. Beweglichkeit Rang 1 zeigt 4.71 (rechnerisch 4.715); im Auftrag stand beispielhaft 4.72.
- **Skriptbot:** RT halten + vorwärts bleibt timingabhängig (siehe M2D); kein Tuning.

## Nächster manueller Test

1. Ebene 1 normal spielen: Orbs einsammeln, auf XP-Leiste und Live-Level-Up achten.
2. Punkte zunächst sparen: zählt „STATS +1/+2“ korrekt?
3. Stats mitten im Kampf öffnen, einen Punkt verteilen, schließen: Pause und Eingaben sauber?
4. Ebene 1 räumen, 1 aus 3 wählen: öffnet sich die Luke erst danach? Auf Ebene 2 prüfen, ob Attribute und Upgrade wirken.
5. Neuer Run (alles Basis?), dann ein, zwei Gegner besiegen und absichtlich herunterfallen: Fortschritt bleibt, aber kein Upgrade.

## Stopp

Kein M3B, keine Floor-Variety, keine Relikte, keine Assets. Kein Commit/Push ohne ausdrückliche Anweisung.
