extends "element_base.gd"
# Element: Windmill. One file = one map object. map.json "type": "windmill"
# Front (door side) looks to +Z when rot = 0.

const Spinner = preload("spinner.gd")

const META := {"name": "Windmill", "category": "industry", "foot": [6, 6]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var white := Util.mat(Color(0.93, 0.94, 0.95), 0.6)
	var grey := Util.mat(Color(0.7, 0.72, 0.75), 0.5, 0.4)
	var tower := Util.mim(_taper(0.6, 1.3, 18.0, 10), white)
	tower.position = Vector3(0, 9.0, 0)
	body.add_child(tower)
	Util.part(body, Vector3(1.6, 1.6, 3.2), Vector3(0, 18.6, 0.2), grey)
	var hub := Util.mim(Util.sphere(0.55, 8, 4), grey)
	hub.position = Vector3(0, 18.6, 2.0)
	body.add_child(hub)
	var rotor := Spinner.new()
	rotor.position = Vector3(0, 18.6, 2.2)
	body.add_child(rotor)
	for i in 3:
		var arm := Node3D.new()
		arm.rotation_degrees.z = i * 120.0
		rotor.add_child(arm)
		Util.part(arm, Vector3(0.5, 8.0, 0.14), Vector3(0, 4.6, 0), white)
	_box_collider(body, Vector3(2.4, 18.0, 2.4), Vector3(0, 9.0, 0))
	return body
