class_name SparkerVisual
extends Node3D
## Schnittstelle zwischen Funkenwerfer-Gameplay und austauschbarer Darstellung unter `VisualRoot`.
## M2C: PlaceholderSparkerVisual. Gameplay ruft nur diese Methoden auf.

enum Action { NONE, CHARGE, RECOVER, HIT, DEFEATED }


## Pro Physiktick: Aktion, Fortschritt 0..1, Richtung festgelegt, Laufanteil 0..1.
func apply_state(_action: Action, _progress: float, _committed: bool, _move_amount: float) -> void:
	pass


## Schuss wurde abgegeben (Mündungsimpuls/Rückstoß).
func play_fire() -> void:
	pass


func flash() -> void:
	pass


func hit_react(_local_direction: Vector3) -> void:
	pass


func set_hp(_hp: float, _max_hp: float) -> void:
	pass


func play_defeat(_by_fall: bool, _local_direction: Vector3) -> void:
	pass


func reset_visual() -> void:
	pass
