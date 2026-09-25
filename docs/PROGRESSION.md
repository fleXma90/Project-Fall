# Run-Progression — Entwurf für M3 und später

**Nicht Teil von M0/M1/M2.** Dieser Vorschlag konkretisiert den gewünschten Run-Fokus, nicht eine permanente Upgrade-Wirtschaft. Zahlen und Auswahlhäufigkeit werden erst beim jeweiligen Auftrag abgestimmt beziehungsweise spielerisch getestet.

## Drei getrennte Aufgaben

**Erfahrung/Run-Level:** Grundwerte halten mit der steigenden Schwierigkeit mit. Vorgeschlagen ist eine kurze Auswahl aus drei überschaubaren Stat-Verbesserungen, etwa maximale HP, Waffenschaden oder Angriffstempo. Kein Popup für jeden einzelnen eingesammelten Orb. Der erste XP-Entwurf soll nicht mehrmals pro kurzer Ebene den Kampf unterbrechen.

**Floor-Upgrades:** Nach einem regulären Clear eine Auswahl aus drei mechanischen Verbesserungen. Sie formen, wie der Hammer gespielt wird. Ein frühzeitiger Sturz ohne Clear bringt diese Auswahl nicht. Karten pausieren das Gameplay und lösen alle gehaltenen Kampfeingaben.

**Relikte:** Seltene Regeländerungen nach besonderen Begegnungen. Erst wenn der Grundpool spielbar ist. Keine zusätzliche Aktionsleiste. M3 beginnt ohne eigenes komplexes Reliktsystem; in M4 kann ein erster Boss eine passive Belohnung tragen.

## Vorschläge für den ersten mechanischen Pool

| ID | Effektidee | Entscheidung/Begrenzung |
|---|---|---|
| `heavy_head` | Mehr Rückstoß des Hammers | Gegner bewegen statt nur Schaden steigern |
| `wide_swing` | Breiterer Schlagbogen | Reichweite und maximaler Winkel bleiben klar begrenzt |
| `aftershock` | Jeder dritte vollständige Schlag erzeugt eine kurze Stoßwelle | Nur neue Trefferereignisse; kein rekursives Proc-System |
| `sweet_spot` | Treffer nahe der Mitte des Hammerbogens verursachen etwas mehr Rückstoß und Schaden | Belohnt saubere manuelle Ausrichtung; keine Zielhilfe |
| `dodge_charge` | Erster Schlag kurz nach einem Dodge verursacht mehr Rückstoß | Angriffstakt bleibt unverändert |
| `ember_wake` | Dodge hinterlässt kurz eine kleine schädliche Spur | Kein Zusatzbutton, keine unendlichen Partikel |

Diese sechs Ideen sind ein begrenzter erster Kandidatenpool, keine fertig ausbalancierten Inhalte. Eine M3-Freigabe muss konkrete Werte festhalten. Nicht alle Effekte ungetestet aktivieren und dann über viele Runs Statistiken sammeln, bevor der einzelne Effekt sichtbar funktioniert.

Ein Build muss auch auf einer großen sicheren Plattform funktionieren. Ein reiner Kanten-/Fallbonus braucht deshalb zusätzlich einen Nutzen gegen Gegner, die nicht hinuntergestoßen werden können. Keine Gegner automatisch in Löcher teleportieren und keine versteckte Kantenanziehung einbauen, um Rückstoß-Upgrades stärker wirken zu lassen.

## Technische Regeln

Effekte besitzen stabile IDs. Angebote enthalten nur anwendbare, nicht ausgeschöpfte Optionen; keine dreifach identische Karte. Caps und Stack-Verhalten werden vor Implementierung definiert. Bei zu kleinem Pool eine kleinere ehrliche Auswahl oder einen dokumentierten zulässigen Ersatz zeigen, keine leere Karte.

Run-State und konstante Inhaltsdefinitionen sind getrennt. Modifikatoren aus Basiswerten und aktuellem Run neu berechnen, nicht durch mehrfaches blindes Aufmultiplizieren bei jedem Szenenwechsel.

Der Zufallsseed bestimmt Angebote und Inhaltsauswahl innerhalb derselben Spiel-/Datenversion. Keine Behauptung plattformübergreifend bitidentischer Actionphysik. Gameplay-Zufall getrennt von kosmetischen Partikeln halten.

Nach Tod, Victory-Neustart oder „Neuer Run“: XP, Level, gewählte Run-Upgrades, HP-Modifikatoren und Angebotshistorie zurücksetzen. Nutzeroptionen dürfen erhalten bleiben. Floor-Wechsel setzt diese Run-Daten nicht zurück.

## MVP-Grenzen

Kein Shop, keine zwei Währungen, keine Premium-Gems, keine Raritätslotterie mit fünfzig minimal verschiedenen Hämmern, kein permanenter Skillbaum. Vollständiges Save/Resume, Inhalt-Freischaltungen und mehr Waffen kommen erst nach einer brauchbaren kurzen Run-Schleife.
