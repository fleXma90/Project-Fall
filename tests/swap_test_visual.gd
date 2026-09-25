extends PlayerVisual
## Test-Ersatzdarstellung (A1): völlig andere innere Struktur und Socket-Namen als der Placeholder.
## Simuliert einen späteren Adapter, dessen Hand-Socket z. B. aus einem BoneAttachment3D kommt.

var _socket := Node3D.new()


func _init() -> void:
	var rig := Node3D.new()
	rig.name = "ArbitraryRig"
	add_child(rig)
	_socket.name = "SomeOtherSocketName"
	_socket.position = Vector3(0.3, 1.0, -0.5)
	rig.add_child(_socket)
	var mesh := MeshInstance3D.new()
	mesh.mesh = CylinderMesh.new()
	add_child(mesh)


func get_weapon_socket() -> Node3D:
	return _socket
