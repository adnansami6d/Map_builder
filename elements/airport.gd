extends "element_base.gd"
# Element: Airport. One file = one map object. map.json "type": "airport"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Airport", "category": "transport", "foot": [66, 32]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var asphalt := Util.mat(Color(0.17, 0.17, 0.19), 0.95)
	var apron := Util.mat(Color(0.32, 0.32, 0.34), 0.95)
	var white := Util.mat(Color(0.95, 0.95, 0.92), 0.8)
	var yellow := Util.mat(Color(0.95, 0.8, 0.15), 0.8)
	var wall := Util.mat(Color(0.9, 0.9, 0.86), 0.8)
	var glass := Util.mat(Color(0.45, 0.7, 0.85), 0.15, 0.2)
	var roofm := Util.mat(Color(0.2, 0.3, 0.55), 0.7)
	Util.part(body, Vector3(66.0, 0.06, 32.0), Vector3(0, 0.03, 0), Util.mat(Color(0.5, 0.62, 0.38), 1.0))   # airfield grass
	Util.part(body, Vector3(64.0, 0.08, 9.0), Vector3(0, 0.07, -10.0), asphalt)        # runway
	Util.part(body, Vector3(40.0, 0.08, 12.0), Vector3(-3.0, 0.065, 0.0), apron)       # apron
	for i in 10:
		Util.part(body, Vector3(3.0, 0.02, 0.35), Vector3(-27.0 + i * 6.0, 0.115, -10.0), white)   # centre line
	for sg in [-1.0, 1.0]:
		Util.part(body, Vector3(62.0, 0.02, 0.2), Vector3(0, 0.115, -10.0 + sg * 4.1), white)       # edge lines
		for k in 5:
			Util.part(body, Vector3(2.0, 0.02, 0.5), Vector3(sg * 29.0, 0.115, -10.0 + (k - 2) * 1.5), white)   # thresholds
	# helipad
	var ring := Util.mim(Util.cyl(4.6, 0.04, 28), yellow)
	ring.position = Vector3(-14.0, 0.12, 0.0)
	body.add_child(ring)
	var pad := Util.mim(Util.cyl(4.2, 0.05, 28), Util.mat(Color(0.2, 0.2, 0.24), 0.95))
	pad.position = Vector3(-14.0, 0.125, 0.0)
	body.add_child(pad)
	for sx in [-1.0, 1.0]:
		Util.part(body, Vector3(0.6, 0.02, 3.4), Vector3(-14.0 + sx * 1.1, 0.155, 0.0), white)
	Util.part(body, Vector3(2.2, 0.02, 0.6), Vector3(-14.0, 0.155, 0.0), white)
	# terminal (front / entrance looks to +Z)
	Util.part(body, Vector3(20.0, 5.0, 6.0), Vector3(-6.0, 2.5, 12.0), wall)
	Util.part(body, Vector3(21.0, 0.4, 7.0), Vector3(-6.0, 5.2, 12.0), roofm)
	for sz in [-1.0, 1.0]:
		Util.part(body, Vector3(18.0, 2.0, 0.1), Vector3(-6.0, 2.0, 12.0 + sz * 3.03), glass)
	Util.part(body, Vector3(6.0, 0.2, 2.4), Vector3(-6.0, 3.6, 15.9), yellow)   # entrance canopy
	_box_collider(body, Vector3(20.0, 5.0, 6.0), Vector3(-6.0, 2.5, 12.0))
	# control tower
	var shaft := Util.mim(Util.cyl(1.5, 10.0, 12), wall)
	shaft.position = Vector3(10.0, 5.0, 12.5)
	body.add_child(shaft)
	var cab := Util.mim(Util.cyl(2.6, 2.2, 12), glass)
	cab.position = Vector3(10.0, 11.1, 12.5)
	body.add_child(cab)
	var cap := Util.mim(Util.cyl(3.0, 0.4, 12), roofm)
	cap.position = Vector3(10.0, 12.4, 12.5)
	body.add_child(cap)
	Util.part(body, Vector3(0.1, 3.0, 0.1), Vector3(10.0, 14.1, 12.5), Util.mat(Color(0.3, 0.3, 0.32)))
	var lamp := Util.mim(Util.sphere(0.3, 8, 4), Util.glow(Color(1.0, 0.1, 0.05), 2.5))
	lamp.position = Vector3(10.0, 15.7, 12.5)
	body.add_child(lamp)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 1.6
	sh.height = 12.0
	cs.shape = sh
	cs.position = Vector3(10.0, 6.0, 12.5)
	body.add_child(cs)
	# hangar (big door looks to -Z, towards the apron)
	Util.part(body, Vector3(12.0, 5.0, 8.0), Vector3(24.0, 2.5, 11.0), Util.mat(Color(0.7, 0.72, 0.75), 0.6, 0.3))
	var prism := PrismMesh.new()
	prism.size = Vector3(12.6, 2.0, 8.6)
	var hroof := Util.mim(prism, Util.mat(Color(0.45, 0.47, 0.5), 0.6, 0.3))
	hroof.position = Vector3(24.0, 6.0, 11.0)
	body.add_child(hroof)
	Util.part(body, Vector3(8.0, 4.0, 0.1), Vector3(24.0, 2.0, 6.95), Util.mat(Color(0.25, 0.27, 0.3)))
	Util.part(body, Vector3(16.0, 0.08, 6.0), Vector3(14.0, 0.065, 4.0), apron)   # taxi strip to the hangar
	_box_collider(body, Vector3(12.0, 5.0, 8.0), Vector3(24.0, 2.5, 11.0))
	# small parked plane (nose to +X)
	var fus := Util.mim(Util.cyl(0.75, 8.0, 12), Util.mat(Color(0.95, 0.95, 0.95), 0.4, 0.2))
	fus.position = Vector3(5.0, 1.3, 0.5)
	fus.rotation_degrees = Vector3(0, 0, 90)
	body.add_child(fus)
	var nose := Util.mim(Util.cone(0.75, 1.6, 12), Util.mat(Color(0.8, 0.15, 0.12), 0.5))
	nose.position = Vector3(9.8, 1.3, 0.5)
	nose.rotation_degrees = Vector3(0, 0, -90)
	body.add_child(nose)
	Util.part(body, Vector3(1.8, 0.14, 10.5), Vector3(5.6, 1.9, 0.5), Util.mat(Color(0.8, 0.15, 0.12), 0.5))   # wings
	Util.part(body, Vector3(1.2, 2.0, 0.12), Vector3(1.4, 2.4, 0.5), Util.mat(Color(0.8, 0.15, 0.12), 0.5))   # tail fin
	Util.part(body, Vector3(1.0, 0.12, 3.2), Vector3(1.4, 1.7, 0.5), Util.mat(Color(0.95, 0.95, 0.95), 0.5))  # tail wing
	_box_collider(body, Vector3(9.0, 1.8, 1.6), Vector3(5.0, 1.3, 0.5))
	_box_collider(body, Vector3(1.8, 0.4, 10.5), Vector3(5.6, 1.9, 0.5))
	# windsock
	Util.part(body, Vector3(0.12, 5.0, 0.12), Vector3(30.0, 2.5, -2.0), Util.mat(Color(0.8, 0.8, 0.82)))
	var sock := Util.mim(Util.cone(0.45, 2.4, 10), Util.mat(Color(1.0, 0.5, 0.1), 0.8))
	sock.position = Vector3(31.2, 4.8, -2.0)
	sock.rotation_degrees = Vector3(0, 0, 90)
	body.add_child(sock)
	return body
