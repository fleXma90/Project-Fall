class_name HitInfo
extends RefCounted
## Daten eines einzelnen Treffers. Ziele implementieren `receive_hit(hit: HitInfo) -> bool`.

var swing_id: int = 0
var damage: float = 0.0
## Horizontale Startgeschwindigkeit des Knockbacks (XZ, m/s).
var knockback_velocity: Vector3 = Vector3.ZERO
var knockback_duration: float = 0.0
var attack_direction: Vector3 = Vector3.FORWARD
var source: Node3D = null
## Lesbarer Quellenname (bleibt gültig, auch wenn die Quelle später entfernt wird).
var source_name: String = ""
