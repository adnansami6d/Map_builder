extends "element_base.gd"
# Element: Shop. One file = one map object. map.json "type": "shop"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Shop", "category": "building", "foot": [6, 5]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	Util.part(body, Vector3(6, 3, 5), Vector3(0, 1.5, 0), Util.mat(Color(0.92, 0.85, 0.65)))
	_box_collider(body, Vector3(6, 3, 5), Vector3(0, 1.5, 0))
	Util.part(body, Vector3(6.6, 0.25, 5.6), Vector3(0, 3.1, 0), Util.mat(Color(0.75, 0.2, 0.18)))
	Util.part(body, Vector3(5.4, 0.15, 1.8), Vector3(0, 2.7, 3.3), Util.mat(Color(0.95, 0.9, 0.3)))   # awning
	Util.part(body, Vector3(1.0, 2.0, 0.1), Vector3(-1.6, 1.0, 2.52), Util.mat(Color(0.32, 0.2, 0.1)))
	Util.part(body, Vector3(2.4, 1.0, 0.1), Vector3(1.1, 1.6, 2.52), Util.mat(Color(0.55, 0.75, 0.9), 0.2, 0.2))
	Util.part(body, Vector3(3.0, 0.7, 0.9), Vector3(1.1, 0.45, 3.2), Util.mat(Color(0.5, 0.34, 0.18)))   # counter
	return body
