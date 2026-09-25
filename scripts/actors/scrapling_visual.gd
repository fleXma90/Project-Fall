class_name ScraplingVisual
extends Node3D
## Schnittstelle zwischen Scrapling-Gameplay und austauschbarer Darstellung unter `VisualRoot`.
## M2A: PlaceholderScraplingVisual. Gameplay ruft nur diese Methoden auf.

enum Action { NONE, WINDUP, ACTIVE, RECOVERY, HIT, DEFEATED }


## Pro Physiktick: aktuelle Aktion, Fortschritt 0..1, Laufanteil 0..1, Richtung im Windup festgelegt.
func apply_state(_action: Action, _progress: float, _move_amount: float, _committed: bool) -> void:
	pass


func get_weapon_socket() -> Node3D:
	return null


func flash() -> void:
	pass


## Hammertreffer; Stoßrichtung im lokalen Raum des Scrapling-Roots.
func hit_react(_local_direction: Vector3) -> void:
	pass


func set_hp(_hp: float, _max_hp: float) -> void:
	pass


func play_defeat(_by_fall: bool, _local_direction: Vector3) -> void:
	pass


func reset_visual() -> void:
	pass
