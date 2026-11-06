extends "element_base.gd"
# Element: Well. One file = one map object. map.json "type": "well"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Well", "category": "farm", "foot": [2.5, 2.5]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var stone := Util.mim(Util.cyl(0.9, 0.9, 12), Util.mat(Color(0.55, 0.55, 0.55)))
	stone.position = Vector3(0, 0.45, 0)
	body.add_child(stone)
	var water := Util.mim(Util.cyl(0.72, 0.05, 12), Util.mat(Color(0.1, 0.25, 0.4)))
	water.position = Vector3(0, 0.86, 0)
	body.add_child(water)
	var wood := Util.mat(Color(0.4, 0.26, 0.13))
	for sx in [-0.8, 0.8]:
		Util.part(body, Vector3(0.1, 1.8, 0.1), Vector3(sx, 1.8, 0), wood)
	var roof := PrismMesh.new()
	roof.size = Vector3(2.2, 0.8, 1.6)
	var r := Util.mim(roof, Util.mat(Color(0.5, 0.22, 0.14)))
	r.position = Vector3(0, 2.9, 0)
	r.rotation_degrees.y = 90.0
	body.add_child(r)
	_box_collider(body, Vector3(1.8, 1.0, 1.8), Vector3(0, 0.5, 0))
	return body
