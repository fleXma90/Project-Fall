class_name PlayerVisualState
extends RefCounted
## Vom Gameplay pro Physiktick befüllter Darstellungszustand. Gameplaytiming ist die Quelle der Wahrheit;
## ein Visual-Adapter (Placeholder oder später riggtes Modell) liest nur diese Werte.

enum Action { NONE, ATTACK_WINDUP, ATTACK_ACTIVE, ATTACK_RECOVERY, DODGE }

## Horizontale Geschwindigkeit relativ zur Laufgeschwindigkeit (0..~2).
var move_amount: float = 0.0
## Bewegungsrichtung im lokalen Raum des Player-Roots (vorne = -Z), für Strafing/Lean.
var local_move_direction: Vector3 = Vector3.ZERO
var grounded: bool = true
var falling: bool = false
var action: Action = Action.NONE
## Fortschritt der aktuellen Aktionsphase 0..1.
var action_progress: float = 0.0
## Dodge-Richtung im lokalen Raum des Player-Roots.
var local_dodge_direction: Vector3 = Vector3.ZERO
