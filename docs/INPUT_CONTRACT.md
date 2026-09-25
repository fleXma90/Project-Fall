# Eingabevertrag v1.1 — 3D, drei Eingabewege

Dieser Vertrag definiert Verhalten, nicht eine konkrete Klasse.

## Aktionen

| Aktion | Desktop | Controller | Touch |
|---|---|---|---|
| Bewegung | WASD; Pfeile optional | linker Stick | linker virtueller Stick |
| Facing | Mausprojektion in Welt | letzte gültige Stickrichtung | letzte gültige Stickrichtung |
| Attack | LMB halten | RT/R2 halten | Attack halten |
| Dodge | RMB oder Space, neu drücken | LT/L2, neu drücken | Dodge neu berühren |
| Pause | Escape | Start/Menu | Pausebutton |
| Reset | Pausenmenü; R optional Debug | Pausenmenü | Pausenmenü |
| Moduswahl Kampf/Training (M2A) | Pausenmenü | Pausenmenü | Pausenmenü |
| Neustart nach Sieg/Niederlage (M2A) | Button, Enter oder R | A auf fokussiertem Button | Button |

## Camera-relative Bewegung

Input ist bildschirmbezogen, aber technisch in 3D: Kamera-Forward und Kamera-Right werden auf XZ projiziert. Stick/WASD oben bedeutet visuell Bildschirm oben. Diagonalgeschwindigkeit wird normalisiert; Analogstärke bleibt erhalten.

`move_direction`, `facing_direction`, `attack_direction`, `dodge_direction` sind getrennte Zustände.

## Touch / Controller Facing

Gültiger Stickinput setzt Bewegung und Facing. Geht der Stick in die Deadzone, bleibt die letzte bewusste Facing-Richtung bestehen. Knockback, Restgeschwindigkeit, Schwerkraft oder Kollisionsgleiten ändern Facing nicht. Anfangsrichtung ohne Input: sinnvoll camera-right oder definierte Arena-Vorne-Richtung.

Kein rechter Stick nötig. Keine automatische Zielauswahl.

## Desktop Facing

Mausposition wird über `Camera3D` in die 3D-Welt projiziert. Geeignet ist Raycast auf tatsächlichen Boden oder eine horizontale Plane in Spielerhöhe; die resultierende Richtung wird auf XZ projiziert. Wenn der Weltpunkt praktisch am Player liegt, letzte gültige Richtung behalten.

Der Player kann mit WASD seitlich/rückwärts relativ zum Facing laufen und zur Maus schlagen.

## Attack

Richtungsregel (seit M1.1, nach Controller-Feedback):

- Bewegung bleibt in allen Angriffsphasen camera-relative und vom aktuellen Input abhängig.
- **WINDUP:** Die bevorstehende `attack_direction` folgt der bewussten aktuellen Stick-/Mausausrichtung (über die sichtbare, weich nachgeführte Körperausrichtung).
- **ACTIVE:** Beim Eintritt wird `attack_direction` fixiert. Treffersektor, Körperausrichtung und Trail bleiben auf dieser Richtung; die Position darf sich durch normale Bewegung ändern.
- **RECOVERY:** Körperausrichtung wieder frei; keine Treffer.
- Der nächste (gehaltene) Angriff nutzt die neueste Richtung. Neutraler Stick behält die letzte bewusste Richtung.

Gegnerposition verändert den Winkel nie.

Gedrückthalten darf den nächsten vollständigen Angriff starten, sobald Zustand/Takt erlauben. Loslassen/erneutes Drücken resetten keinen Cooldown. UI-Klicks dürfen keinen Weltangriff auslösen.

## Dodge

Neue Druckflanke nötig. Gehaltenes LT/RMB/Space/Touch erzeugt nicht pro Cooldown einen neuen Dodge.

Richtung beim Start:

1. aktueller gültiger Bewegungsvektor,
2. sonst Facing.

Dodge-Richtung bleibt für diesen Dodge fixiert. Dodge ist eine schnelle bodennahe Bewegung und **kein Sprung**. Er kann über eine offene Kante führen; es gibt keinen Randcollider, der ihn rettet.

## Touch

Dynamischer linker Stick mit eigener Finger-ID. Angriff und Dodge besitzen separate Finger. Bewegung + gehaltenes Attack + Dodge mit drittem Kontakt unterstützen. Kein Finger darf von einer anderen Control gestohlen werden.

Safe-Area beachten. Keine doppelte Mouse-Emulation als zusätzlichen Angriff zählen. Bei Pause, App-Hintergrund, Szenenwechsel oder Touch-Cancel alle Besitzer lösen.

## Controller

Linker Stick radial. RT/LT analog mit Hysterese; nicht pauschal Bumper verwenden. Disconnect des aktiven Controllers löst Inputs und pausiert sinnvoll. Reconnect übernimmt keine gehaltenen Altinputs.

Menüs vollständig mit Controller erreichbar.

## Gerätewechsel

Ein zentraler Router verwaltet aktive Eingabequelle. Stickrauschen oder unbewegte Maus übernehmen nicht. Beim echten Wechsel alte Held-States/Buffer lösen; Facing bleibt bis zur ersten gültigen Richtung der neuen Quelle erhalten.

## Direkt prüfbare Beispiele

- Controller schräg rechts oben → loslassen → RT: Schlag bleibt rechts oben, auch wenn links ein Dummy steht.
- Desktop A halten, Maus rechts: Bewegung links, Facing/Schlag rechts.
- LT zwei Sekunden halten: höchstens ein Dodge.
- Dodge über Plattformkante: Player fällt physisch.
- Maus bewegt sich im Controllerbetrieb nicht: sie dreht Player nicht heimlich.
- Drei Touchkontakte: Stick, Attack, Dodge bleiben unabhängig.
