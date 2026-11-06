extends "element_base.gd"
# Element: Storage. One file = one map object. map.json "type": "storage"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Storage", "category": "industry", "foot": [30, 18]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var wall := Util.mat(Color(0.62, 0.55, 0.45), 0.9)
	Util.part(body, Vector3(30, 8, 0.6), Vector3(0, 4, -8.7), wall)
	_box_collider(body, Vector3(30, 8, 0.6), Vector3(0, 4, -8.7))
	for sx in [-1.0, 1.0]:
		Util.part(body, Vector3(0.6, 8, 18), Vector3(sx * 14.7, 4, 0), wall)
		_box_collider(body, Vector3(0.6, 8, 18), Vector3(sx * 14.7, 4, 0))
	var prism := PrismMesh.new()
	prism.size = Vector3(31, 4.5, 19)
	var roof := Util.mi(prism, Color(0.35, 0.3, 0.28))
	roof.position = Vector3(0, 10.25, 0)
	body.add_child(roof)
	Util.part(body, Vector3(29, 0.1, 17), Vector3(0, 0.06, 0), Util.mat(Color(0.5, 0.45, 0.4)))   # floor
	Util.part(body, Vector3(8, 3.0, 8), Vector3(-6, 1.5, -4), Util.mat(Color(0.9, 0.8, 0.35)))     # rice heap
	Util.part(body, Vector3(8, 3.0, 8), Vector3(6, 1.5, -4), Util.mat(Color(0.85, 0.62, 0.3)))     # wheat heap
	return body
