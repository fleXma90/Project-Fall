class_name GapDetour
extends RefCounted
## Lokaler Umweg an Lücken (z. B. Schacht in Ebene 2): Fehlt vor der Laufrichtung Boden, wird die Richtung
## um 45°, 90° bzw. 135° gedreht. Die zuletzt erfolgreiche Seite wird vollständig zuerst geprüft; gewechselt
## wird nur, wenn sie ganz blockiert ist (kein Hin- und Herpendeln entlang einer Kante).
## Kein Pfadnetz; betrifft nur die freiwillige Laufentscheidung, nie Knockback oder Schwerkraft.

const ANGLES: Array[float] = [45.0, 90.0, 135.0]


## Liefert eine Richtung mit Boden oder Vector3.ZERO. side ist ein Einzelelement-Array mit der bevorzugten Seite (±1)
## und wird bei Erfolg aktualisiert.
static func steer(direction: Vector3, side: Array[float], has_ground: Callable) -> Vector3:
	for sign_value in [side[0], -side[0]]:
		for angle in ANGLES:
			var candidate := direction.rotated(Vector3.UP, deg_to_rad(angle) * sign_value)
			if has_ground.call(candidate):
				side[0] = sign_value
				return candidate
	return Vector3.ZERO
