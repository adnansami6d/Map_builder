extends "element_base.gd"
# Element: Silo. One file = one map object. map.json "type": "silo"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Silo", "category": "farm", "foot": [5, 5]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var metal := Util.mat(Color(0.75, 0.77, 0.8), 0.35, 0.7)
	var tube := Util.mim(Util.cyl(2.2, 9.0, 20), metal)
	tube.position = Vector3(0, 4.5, 0)
	body.add_child(tube)
	for i in 3:
		var ring := Util.mim(Util.cyl(2.25, 0.18, 20), Util.mat(Color(0.5, 0.52, 0.55), 0.4, 0.6))
		ring.position = Vector3(0, 2.0 + i * 3.0, 0)
		body.add_child(ring)
	var dome := Util.mim(Util.sphere(2.2, 20, 8), Util.mat(Color(0.6, 0.15, 0.12), 0.5, 0.3))
	dome.scale = Vector3(1, 0.55, 1)
	dome.position = Vector3(0, 9.0, 0)
	body.add_child(dome)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 2.2
	sh.height = 9.0
	cs.shape = sh
	cs.position = Vector3(0, 4.5, 0)
	body.add_child(cs)
	return body
