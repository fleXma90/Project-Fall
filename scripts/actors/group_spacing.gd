class_name GroupSpacing
extends RefCounted
## Lokale Abstandshaltung zwischen lebenden Gegnern einer Begegnung (Scrapling, Funkenwerfer).
## Liefert nur einen Beitrag zur Laufabsicht; bewegt nichts selbst.


## Summe der Wegdrück-Vektoren zu nahen, sichtbaren und unbesiegten Nachbarn (XZ).
static func push(self_node: Node3D, neighbors: Array[Node3D], radius: float, strength: float, fallback: Vector3) -> Vector3:
	var result := Vector3.ZERO
	for other in neighbors:
		if other == self_node or not is_instance_valid(other) or not other.visible or bool(other.get("is_defeated")):
			continue
		var away := self_node.global_position - other.global_position
		away.y = 0.0
		var distance := away.length()
		if distance >= radius:
			continue
		if distance < 0.001:
			away = fallback  # deckungsgleich: seitlich ausweichen
			distance = 0.001
		result += away.normalized() * (1.0 - distance / radius)
	return result * strength
