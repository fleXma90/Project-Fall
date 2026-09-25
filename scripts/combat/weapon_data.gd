class_name WeaponData
extends Resource
## Gameplaydaten einer Waffe. Reichweite/Winkel werden nie aus der Meshgröße abgeleitet.

@export var display_name: String = "Hammer"
@export var windup: float = 0.26
@export var active: float = 0.12
@export var recovery: float = 0.42
@export var damage: float = 20.0
## Reichweite in Metern vom AttackOrigin (XZ, bis zur Zieloberfläche).
@export var attack_range: float = 1.9
@export var arc_degrees: float = 110.0
## Maximaler Höhenunterschied AttackOrigin → Zielursprung.
@export var max_height_difference: float = 1.5
@export var knockback_speed: float = 8.0
@export var knockback_duration: float = 0.28


func total_duration() -> float:
	return windup + active + recovery
