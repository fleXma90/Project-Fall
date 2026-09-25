class_name PlayerTuning
extends Resource
## Bewegungs- und Dodge-Tuning des Players. Startwerte siehe docs/TUNING.md.

@export var max_hp: float = 100.0
@export var move_speed: float = 4.6
@export var acceleration: float = 24.0
@export var deceleration: float = 30.0
## Horizontale Steuerbarkeit in der Luft. Klein, damit ein Fall nicht zurückgelenkt werden kann.
@export var air_acceleration: float = 4.0
@export var attack_move_multiplier: float = 0.70
## Visuelle Drehgeschwindigkeit des Roots zum Facing (1/s). Trefferlogik nutzt Richtungsvektoren.
@export var turn_sharpness: float = 22.0
@export var dodge_duration: float = 0.18
@export var dodge_speed: float = 10.0
@export var dodge_cooldown: float = 0.70
@export var dodge_iframe_start: float = 0.02
@export var dodge_iframe_end: float = 0.14
## Luftzeit, ab der aus MOVE der Zustand FALLING wird.
@export var fall_state_delay: float = 0.12
## Maus-Weltpunkt näher als dieser Abstand ändert das Facing nicht.
@export var mouse_facing_min_distance: float = 0.25
