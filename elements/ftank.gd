extends "element_base.gd"
# Element: Fuel Tank. One file = one map object. map.json "type": "ftank"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Fuel Tank", "category": "industry", "foot": [10, 10]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var steel := Util.mat(Color(0.45, 0.47, 0.5), 0.5, 0.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Util.part(body, Vector3(0.45, 9.0, 0.45), Vector3(sx * 3.0, 4.5, sz * 3.0), steel)
	var tank := Util.mim(Util.cyl(4.5, 5.0, 16), Util.mat(Color(0.2, 0.55, 0.3), 0.5, 0.3))
	tank.position = Vector3(0, 11.5, 0)
	body.add_child(tank)
	var cap := Util.mim(Util.sphere(4.5, 16, 6), Util.mat(Color(0.2, 0.55, 0.3), 0.5, 0.3))
	cap.scale = Vector3(1, 0.4, 1)
	cap.position = Vector3(0, 14.0, 0)
	body.add_child(cap)
	Util.part(body, Vector3(0.3, 9.0, 0.3), Vector3(0, 4.5, 4.4), steel)          # fill pipe
	Util.part(body, Vector3(2.0, 2.2, 1.6), Vector3(0, 1.1, 4.8), Util.mat(Color(0.85, 0.7, 0.1)))   # pump booth
	_box_collider(body, Vector3(7, 9, 7), Vector3(0, 4.5, 0))
	_box_collider(body, Vector3(2.0, 2.2, 1.6), Vector3(0, 1.1, 4.8))
	return body
