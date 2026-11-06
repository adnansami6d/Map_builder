extends "element_base.gd"
# Element: Fuel Station. One file = one map object. map.json "type": "fuelstation"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Fuel Station", "category": "transport", "foot": [44, 34]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var slab := Util.mat(Color(0.55, 0.56, 0.55), 1.0)
	var white := Util.mat(Color(0.93, 0.93, 0.9), 0.7)
	var redm := Util.mat(Color(0.85, 0.15, 0.12), 0.6)
	var grey := Util.mat(Color(0.7, 0.72, 0.75), 0.5, 0.5)
	var wallm := Util.mat(Color(0.88, 0.85, 0.75), 0.9)
	var roofm := Util.mat(Color(0.3, 0.36, 0.45), 0.7)
	var glass := Util.mat(Color(0.45, 0.7, 0.85), 0.15, 0.2)
	var island := Util.mat(Color(0.35, 0.35, 0.37), 0.9)
	Util.part(body, Vector3(44.0, 0.06, 34.0), Vector3(0, 0.03, 0), slab)
	# canopy + 4 pillars + 4 pumps
	Util.part(body, Vector3(18.0, 0.5, 9.0), Vector3(0, 5.2, -2.0), white)
	Util.part(body, Vector3(18.2, 0.3, 9.2), Vector3(0, 4.85, -2.0), redm)
	for sx in [-8.0, 8.0]:
		for sz in [-5.0, 1.0]:
			Util.part(body, Vector3(0.5, 5.0, 0.5), Vector3(sx, 2.5, sz), grey)
			_box_collider(body, Vector3(0.6, 5.0, 0.6), Vector3(sx, 2.5, sz))
	Util.part(body, Vector3(16.0, 0.2, 1.6), Vector3(0, 0.16, -2.0), island)
	for x in [-6.0, -2.0, 2.0, 6.0]:
		Util.part(body, Vector3(0.9, 1.7, 0.7), Vector3(x, 1.05, -2.0), redm)
		Util.part(body, Vector3(0.6, 0.5, 0.05), Vector3(x, 1.5, -1.62), glass)
		_box_collider(body, Vector3(0.9, 1.7, 0.7), Vector3(x, 1.05, -2.0))
	# sign
	var lab := Label3D.new()
	lab.text = "FUEL"
	lab.font_size = 96
	lab.pixel_size = 0.03
	lab.modulate = Color(1.0, 0.85, 0.1)
	lab.outline_modulate = Color(0, 0, 0)
	lab.outline_size = 14
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.position = Vector3(0, 7.4, -2.0)
	body.add_child(lab)
	# shop booth
	Util.part(body, Vector3(8.0, 3.2, 5.0), Vector3(-16.0, 1.6, -10.0), wallm)
	Util.part(body, Vector3(8.6, 0.4, 5.6), Vector3(-16.0, 3.4, -10.0), roofm)
	Util.part(body, Vector3(5.0, 1.0, 0.1), Vector3(-16.0, 1.8, -7.45), glass)
	_box_collider(body, Vector3(8.0, 3.4, 5.0), Vector3(-16.0, 1.7, -10.0))
	# two storage tanks (lying cylinders) at the back
	for x in [2.0, 12.0]:
		var tk := Util.mim(Util.cyl(1.7, 8.0, 12), grey)
		tk.rotation_degrees.z = 90.0
		tk.position = Vector3(x, 1.8, -13.5)
		body.add_child(tk)
		Util.part(body, Vector3(1.0, 0.5, 1.0), Vector3(x, 3.7, -13.5), redm)
		_box_collider(body, Vector3(8.0, 3.6, 3.6), Vector3(x, 1.8, -13.5))
	return body
