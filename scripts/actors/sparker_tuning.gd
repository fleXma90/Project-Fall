class_name SparkerTuning
extends Resource
## Werte des Funkenwerfers und seines Energiebolzens (M2C-Playtest-Startwerte, keine fertige Balance).

@export var max_hp: float = 60.0
@export var move_speed: float = 2.0
@export var acceleration: float = 12.0
@export var deceleration: float = 18.0
@export var turn_sharpness: float = 6.0
## Maximale Distanz zum Spieler, ab der ein Aufladen beginnen darf.
@export var fire_distance: float = 6.0
## Unterhalb dieser Distanz läuft er nicht weiter heran (flieht aber auch nicht).
@export var min_approach_distance: float = 1.5
@export var charge_time: float = 0.65
## Ab diesem Zeitpunkt im Aufladen ist die Schussrichtung festgelegt (kein Drehen mehr).
@export var commit_time: float = 0.45
@export var recovery_time: float = 1.0
@export var hit_stun: float = 0.2
@export var hit_radius: float = 0.4
@export var edge_probe_distance: float = 0.55
@export var separation_radius: float = 1.6
@export var separation_strength: float = 1.2
@export var ground_friction: float = 30.0
## Mündungshöhe über dem Boden und Abstand vor dem Körpermittelpunkt.
@export var muzzle_height: float = 0.85
@export var muzzle_forward: float = 0.62

@export_group("Energiebolzen")
@export var projectile_speed: float = 6.0
@export var projectile_damage: float = 10.0
@export var projectile_radius: float = 0.13
@export var projectile_lifetime: float = 2.5
@export var projectile_knockback_speed: float = 3.0
@export var projectile_knockback_duration: float = 0.15
