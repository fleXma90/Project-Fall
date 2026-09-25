class_name ScraplingTuning
extends Resource
## Bewegungs- und KI-Werte des Scraplings (M2A-Playtest-Startwerte, keine fertige Balance).
## Angriffstiming, Schaden, Reichweite und Winkel liegen in der WeaponData der Gegnerwaffe.

@export var max_hp: float = 80.0
@export var move_speed: float = 2.6
@export var acceleration: float = 14.0
@export var deceleration: float = 20.0
## Drehschärfe (1/s) beim Verfolgen.
@export var turn_sharpness: float = 7.0
## Drehschärfe (1/s) im Windup bis zur Richtungsfestlegung.
@export var windup_turn_sharpness: float = 5.0
## Anteil des Windups, ab dem Richtung und Ausrichtung festgelegt sind (danach kein Nachdrehen).
@export_range(0.0, 1.0) var commit_fraction: float = 0.55
## Abstand (Mittelpunkt zu Mittelpunkt), ab dem ein Angriff beginnt.
@export var attack_start_distance: float = 1.45
## Maximaler Winkel zwischen Blickrichtung und Spieler für einen Angriffsstart.
@export var attack_start_max_angle: float = 35.0
## Unterhalb dieses Abstands läuft der Scrapling nicht weiter auf den Spieler zu.
@export var stop_distance: float = 1.2
## Trefferreaktion nach einem Hammertreffer (kein Angriff, keine Verfolgung). Basisprofil A.
## Testprofile setzen den Wert pro Instanz (Scrapling.hit_stun), nie an dieser geteilten Ressource.
@export var hit_stun: float = 0.4
## Bodenprüfung vor der eigenen Laufbewegung (nur Laufentscheidung, nicht Physik).
@export var edge_probe_distance: float = 0.55
@export var hit_radius: float = 0.38
## Gruppen-Abstandshaltung (nur CHASE, nur zu anderen lebenden Gegnern der Begegnung).
@export var separation_radius: float = 1.6
@export var separation_strength: float = 1.2
@export var ground_friction: float = 30.0
