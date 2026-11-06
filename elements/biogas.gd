extends "element_base.gd"
# Element: Biogas Plant. One file = one map object. map.json "type": "biogas"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Biogas Plant", "category": "industry", "foot": [14, 14]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var green := Util.mat(Color(0.3, 0.55, 0.3), 0.6)
	var tank := Util.mim(Util.cyl(5.5, 4.0, 18), Util.mat(Color(0.7, 0.7, 0.66), 0.8))
	tank.position = Vector3(0, 2.0, 0)
	body.add_child(tank)
	var dome := Util.mim(Util.sphere(5.5, 18, 6), green)
	dome.scale = Vector3(1, 0.55, 1)
	dome.position = Vector3(0, 4.0, 0)
	body.add_child(dome)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 5.5
	sh.height = 6.0
	cs.shape = sh
	cs.position = Vector3(0, 3.0, 0)
	body.add_child(cs)
	Util.part(body, Vector3(4, 2.6, 3), Vector3(0, 1.3, 9.5), Util.mat(Color(0.6, 0.6, 0.62)))   # control hut
	_box_collider(body, Vector3(4, 2.6, 3), Vector3(0, 1.3, 9.5))
	Util.part(body, Vector3(0.35, 6, 0.35), Vector3(4.2, 3, -4.2), Util.mat(Color(0.3, 0.3, 0.32)), Vector3.ZERO)   # pipe
	return body
