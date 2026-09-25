class_name PlayerVisual
extends Node3D
## Schnittstelle zwischen Player-Gameplay und austauschbarer Darstellung unter `VisualRoot`.
##
## M1: PlaceholderGolemVisual. Später: Adapter um ein riggtes .glb, der Clips in-place abspielt
## und einen Hand-Socket (z. B. BoneAttachment3D) über get_weapon_socket() liefert.
## Gameplay ruft nur diese Methoden auf und kennt keine inneren Knoten.


func apply_state(_state: PlayerVisualState) -> void:
	pass


## Knoten, dem der Weapon-Mount visuell folgt. null = Mount bleibt in Ruhelage.
func get_weapon_socket() -> Node3D:
	return null


func play_respawn() -> void:
	pass


## Gültiger gegnerischer Treffer; Richtung des Rückstoßes im lokalen Raum des Player-Roots.
func play_hit(_local_direction: Vector3) -> void:
	pass
