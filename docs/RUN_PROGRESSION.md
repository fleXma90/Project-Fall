# Run-Progression v1 (M3A) — XP, Attribute, Floor-Clear-Upgrades

Stand 26.09.2026. Alle Zahlen sind **Prototypwerte**, keine finale Balance. Nur im Szenario **Abstieg**; Training, Duell, Gruppe und Mischkampf nutzen keine Run-Progression.

## Zwei getrennte Systeme

| System | Auslöser | Wirkung | Unterbricht das Spiel? |
|---|---|---|---|
| XP / Level / Attribute | XP-Orbs besiegter Gegner einsammeln | Level-Up → +1 Attributspunkt; Spieler verteilt selbst im Stats-Screen | Nein (nur Einblendung); der Stats-Screen pausiert erst, wenn der Spieler ihn öffnet |
| Floor-Clear-Upgrade | Alle Gegner eines nicht finalen Floors besiegt | Pflichtauswahl 1 aus 3 Run-Upgrades; danach öffnet sich die Luke | Ja (modal, kein Überspringen) |

## XP

- Scrapling **30 XP**, Funkenwerfer **40 XP**; HP- und Kantensieg gleich. Jeder Gegner genau einmal (die Niederlage wird nur einmal gemeldet).
- **Sichtbare Orbs (Nutzerentscheidung):** Die XP werden nicht beim Kill gutgeschrieben. Der besiegte Gegner wirft Orbs zu je höchstens 10 XP ab (Scrapling 3, Funkenwerfer 4). Beim HP-Sieg springen sie aus dem Gegner. Beim Kantensieg springen sie aus der Tiefe zurück auf die Ebene, an die letzte Bodenposition des Gegners (sicher nach innen gezogen, mindestens 0.6 m zur Kante).
- Orbs schweben über dem Boden und werden erst in **2.2 m** Nähe zum Spieler magnetisch angezogen. Die Anziehung beschleunigt: Start 2 m/s, 22 m/s², höchstens 16 m/s. Einsammeln bei 0.55 m.
- **Geräumter Floor:** Alle liegenden Orbs werden eingesaugt. Die Upgrade-Auswahl erscheint nach 0.8 s bzw. sobald die Orbs angekommen sind (spätestens 1.6 s, Rest wird gutgeschrieben). Auf dem finalen Floor werden liegende Orbs vor der Ergebnisanzeige gutgeschrieben.
- **Früher Sturz:** Noch liegende Orbs der verlassenen Ebene verfallen. Noch lebende, übersprungene Gegner geben nichts. Ausnahme: Wird die Ebene im selben Moment doch noch geräumt (letzter Gegner fällt gleichzeitig), werden ihre Orbs und XP gutgeschrieben.
- Level-Formel: `xp_to_next(level) = 60 + 30 · (level − 1)`, also 60, 90, 120, 150 … Überschuss wird übernommen. Ein Ereignis kann mehrere Level-Ups auslösen. Jedes Level-Up gibt genau **1 Attributspunkt**, keine automatische Steigerung.
- Level-Up: keine Pause, kein Fenster, keine Zeitlupe. Einblendung „LEVEL UP! +1 ATTRIBUTSPUNKT“ (schnelle Folge-Level-Ups zusammengefasst, z. B. „×2“) und ein goldener Ring mit Funken am Spieler.

## Attribute (Rang 0–8, 1 Punkt je Rang, kein Respec)

| Attribut | Pro Rang | Effektive Berechnung | Rang 8 |
|---|---|---|---|
| STÄRKE (`power`) | +5 % Hammerschaden | `20 × (1 + 0.05·r) × Hammerkopf` | 28.0 |
| VITALITÄT (`vitality`) | +10 Max-HP, **ohne Heilung** | `100 + 10·r` | 180 |
| TEMPO (`haste`) | +3 % Angriffstempo | jede Phase `Basis / (1 + 0.03·r)` (Windup, Active, Recovery proportional) | 0.80 s → 0.645 s Zyklus |
| BEWEGLICHKEIT (`agility`) | +2.5 % Laufgeschwindigkeit | Tempo, Beschleunigung und Abbremsung `× (1 + 0.025·r)` (gleiche Zeit bis Vollgas/Stopp) | 4.60 → 5.52 m/s |
| WUCHT (`impact`) | +6 % Hammer-Knockback-Tempo | `8 × (1 + 0.06·r) × Einschlag`, Dauer 0.28 s unverändert | 11.84 m/s |
| ERHOLUNG (`recovery`) | −4 % Dodge-Abklingzeit | `0.70 × (1 − 0.04·r)` | 0.476 s |

Nicht verändert: Dodge-Tempo/-Dauer/-Distanz, iFrames, Fallgeschwindigkeit, Gegnerwerte, erhaltener Knockback. Der Sturzschaden bleibt 12 % der **Basis**-Max-HP (= 12), unabhängig von Vitalität.

## Floor-Clear-Upgrades (je Run höchstens einmal)

| ID | Name | Effekt |
|---|---|---|
| `dense_head` | Verdichteter Hammerkopf | Hammerschaden × 1.15 |
| `heavy_impact` | Schwerer Einschlag | Hammer-Knockback-Tempo × 1.30 |
| `wide_swing` | Weiter Schwung | Trefferbogen + 25° (110° → 135°) |
| `long_grip` | Langer Griff | Reichweite + 0.25 m (1.9 → 2.15 m) |
| `momentum_core` | Momentum-Kern | Erster erfolgreicher Treffer eines Swings: Laufgeschwindigkeit × 1.2 (inkl. Beschleunigung/Abbremsung) für 1.5 s; erneuter Treffer setzt nur die Dauer zurück, kein Stapeln |
| `kinetic_recovery` | Kinetische Erholung | Erster erfolgreicher Treffer eines Swings: verbleibende Dodge-Abklingzeit − 0.20 s (min. 0), höchstens einmal pro Swing |

Auswahl: drei unterschiedliche, noch nicht besessene Upgrades, gemischt mit dem seedbaren RNG des Runs (Fisher-Yates). Bleiben weniger übrig, werden nur die verbleibenden gezeigt. Kein Reroll, kein Überspringen. Die Luke bleibt bis zur Auswahl geschlossen. Nach dem finalen Floor (derzeit Ebene 2) gibt es kein Upgrade.

**Kombinationsreihenfolge:** Basiswert (Ressource) × Attributfaktor × Upgradefaktor; Bogen und Reichweite additiv. Beispiel: Stärke 2 + Hammerkopf = 20 × 1.10 × 1.15 = 25.3 Schaden. Effektive Werte werden bei jeder Änderung vollständig neu aus RunState + Basisdaten berechnet (`PlayerController.apply_run_modifiers`), nie aufmultipliziert; Floorwechsel wenden nichts erneut an.

## Clear vs. Sturz

| Situation | XP/Level/Attribute/Upgrades | Floor-Upgrade | Liegende Orbs | Sturzschaden |
|---|---|---|---|---|
| Ebene 1 geräumt → Auswahl → Luke | bleiben | ja (vor der Luke) | eingesaugt | 0 |
| Ebene 1 geräumt, dann über die Kante (vor/nach der Auswahl) | bleiben | ja (offene Auswahl erscheint nach der Landung) | gutgeschrieben | 12 |
| Früher Sturz, Ebene nicht geräumt | bleiben | **nein** | verfallen | 12 |
| Letzter Gegner stirbt, während der Spieler bereits fällt | bleiben | ja, **nach der Landung**, bevor Ebene-2-Gegner aktiv werden; Landeschutz beginnt nach der Auswahl | gutgeschrieben | 12 |

Ein Floorwechsel heilt nicht und setzt nichts zurück. Der Stats-Screen öffnet nicht automatisch; das STATS-Badge bleibt, solange Punkte offen sind.

## Run-Lebenszyklus

- Ein `RunState` (`scripts/run/run_state.gd`, RefCounted) gehört genau einem Abstiegs-Run und wird von der Arena bei jedem Neustart im Abstieg neu erzeugt: neuer Run, Tod, Ebene-2-Sturz, Neustart nach „Abstieg geschafft“, Szenario- oder Profilwechsel. Er bleibt über Ebene 1 → 2 erhalten.
- Neuer Run: Level 1, 0 XP, 0 Punkte, alle Ränge 0, keine Upgrades, Basis-Max-HP und volle HP, keine Buff-Timer, keine offene Auswahl, keine Orbs.
- Keine Speicherung, keine Meta-Währung, keine permanente Progression.
- Die Ergebnisanzeige zeigt zusätzlich Level, verteilte/offene Punkte und gewählte Upgrades.

## Bedienung

| | Stats öffnen/schließen | Upgrade wählen |
|---|---|---|
| Smartphone | STATS-Button oben links (48 px hoch, außerhalb der Touch-Gameplayzonen), X/Schließen | Karte antippen |
| Desktop | Taste C (Esc schließt nur Stats, öffnet keine Pause) | Klick / Enter auf Karte |
| Controller | View/Back (Start bleibt Pause), B schließt | Steuerkreuz/Stick + A |

Stats öffnen nur im laufenden Abstieg mit Boden unter den Füßen, nie im Fall/Übergang und nie hinter einem anderen Overlay. Öffnen und Schließen lösen alle gehaltenen Eingaben; ein gehaltener RT greift nach dem Schließen erst nach erneutem Drücken an (bestehende Trigger-Verriegelung).

## Offene Balancefragen

- 12 Sturzschaden gegen den Wert des Floor-Upgrades und der XP des Floors: Lohnt sich Räumen spürbar?
- XP-Kurve: Ein vollständiger Floor gibt 100 XP. Das reicht bis Level 2 plus 40 XP; mit zwei vollständig geräumten Floors (200 XP) endet der Run bei Level 3 mit 50 XP Rest. Sind Punkte selten genug und trotzdem spürbar?
- Tempo 8 (−19 % Zyklus) und Erholung 8 (0.476 s) als Obergrenze: fühlt sich der Hammer noch schwer an?
- Magnetradius 2.2 m: zu klein im hektischen Kampf, zu groß für die Entscheidung „Orbs holen vs. Position halten“?
