extends "element_base.gd"
# Element: Power Station. One file = one map object. map.json "type": "powerstation"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Power Station", "category": "industry", "foot": [58, 58]}


static func _bag_fence(body: StaticBody3D, m: Material, x: float, z: float, sx: float, sz: float) -> void:
	Util.part(body, Vector3(sx, 2.2, sz), Vector3(x, 1.1, z), m)
	_box_collider(body, Vector3(sx, 2.2, sz), Vector3(x, 1.1, z))


static func _pylon(body: StaticBody3D, x: float, z: float, m: Material) -> void:
	var H := 18.0
	var lean := rad_to_deg(atan(1.0 / H))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Util.part(body, Vector3(0.22, H, 0.22), Vector3(x + sx * 1.0, H / 2.0, z + sz * 1.0), m, Vector3(-sz * lean, 0, sx * lean))
	Util.part(body, Vector3(0.3, 0.3, 7.0), Vector3(x, H - 1.5, z), m)
	Util.part(body, Vector3(0.3, 0.3, 5.0), Vector3(x, H - 5.0, z), m)
	_box_collider(body, Vector3(2.4, H, 2.4), Vector3(x, H / 2.0, z))


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var pad := Util.mat(Color(0.5, 0.52, 0.5), 1.0)
	var wallm := Util.mat(Color(0.82, 0.83, 0.8), 0.9)
	var roofm := Util.mat(Color(0.3, 0.36, 0.45), 0.7)
	var conc := Util.mat(Color(0.72, 0.72, 0.7), 0.95)
	var steel := Util.mat(Color(0.7, 0.72, 0.75), 0.5, 0.6)
	var yellow := Util.mat(Color(0.95, 0.8, 0.15), 0.8)
	var tfm := Util.mat(Color(0.42, 0.48, 0.55), 0.6, 0.3)
	var redm := Util.mat(Color(0.85, 0.15, 0.12), 0.6)
	var fencem := Util.mat(Color(0.25, 0.3, 0.25), 0.9)
	var glass := Util.mat(Color(0.45, 0.7, 0.85), 0.15, 0.2)
	var dark := Util.mat(Color(0.08, 0.08, 0.09), 1.0)
	Util.part(body, Vector3(58.0, 0.08, 58.0), Vector3(0, 0.04, 0), pad)
	# turbine hall
	Util.part(body, Vector3(30.0, 9.0, 14.0), Vector3(-8.0, 4.5, -18.0), wallm)
	Util.part(body, Vector3(31.0, 0.8, 15.0), Vector3(-8.0, 9.4, -18.0), roofm)
	Util.part(body, Vector3(26.0, 1.4, 0.15), Vector3(-8.0, 6.5, -10.92), glass)
	Util.part(body, Vector3(4.0, 4.0, 0.15), Vector3(-8.0, 2.0, -10.92), yellow)
	_box_collider(body, Vector3(30.0, 9.5, 14.0), Vector3(-8.0, 4.75, -18.0))
	# cooling towers
	for z in [-19.0, -2.0]:
		var ct := Util.mim(_taper(5.0, 7.0, 24.0, 16), conc)
		ct.position = Vector3(19.0, 12.0, z)
		body.add_child(ct)
		_box_collider(body, Vector3(12.0, 24.0, 12.0), Vector3(19.0, 12.0, z))
	# chimney with red beacon
	var ch := Util.mim(_taper(0.9, 1.3, 30.0, 10), conc)
	ch.position = Vector3(-24.0, 15.0, -4.0)
	body.add_child(ch)
	var bc := Util.mim(Util.sphere(0.4, 8, 4), Util.glow(Color(1.0, 0.1, 0.05), 2.5))
	bc.position = Vector3(-24.0, 30.4, -4.0)
	body.add_child(bc)
	_box_collider(body, Vector3(2.6, 30.0, 2.6), Vector3(-24.0, 15.0, -4.0))
	# control cabin
	Util.part(body, Vector3(8.0, 4.0, 6.0), Vector3(-22.0, 2.0, 6.0), wallm)
	Util.part(body, Vector3(8.4, 0.4, 6.4), Vector3(-22.0, 4.2, 6.0), roofm)
	Util.part(body, Vector3(5.0, 1.0, 0.12), Vector3(-22.0, 2.6, 9.04), glass)
	_box_collider(body, Vector3(8.0, 4.4, 6.0), Vector3(-22.0, 2.2, 6.0))
	# transformers
	for x in [-20.0, -12.0, -4.0]:
		Util.part(body, Vector3(4.0, 3.4, 3.0), Vector3(x, 1.7, 15.0), tfm)
		Util.part(body, Vector3(2.4, 0.5, 1.8), Vector3(x, 3.65, 15.0), redm)
		for k in [-0.8, 0.8]:
			Util.part(body, Vector3(0.3, 1.4, 0.3), Vector3(x + k, 4.6, 15.0), yellow)
		_box_collider(body, Vector3(4.0, 3.4, 3.0), Vector3(x, 1.7, 15.0))
	# pylons + wires
	for px in [12.0, 24.0]:
		_pylon(body, px, 15.0, steel)
	for dz in [-3.0, 0.0, 3.0]:
		Util.part(body, Vector3(12.0, 0.06, 0.06), Vector3(18.0, 16.5, 15.0 + dz), dark)
	# fence (gate on the +Z side)
	_bag_fence(body, fencem, -28.5, 0.0, 0.15, 57.0)
	_bag_fence(body, fencem, 28.5, 0.0, 0.15, 57.0)
	_bag_fence(body, fencem, 0.0, -28.5, 57.0, 0.15)
	_bag_fence(body, fencem, -16.0, 28.5, 24.0, 0.15)
	_bag_fence(body, fencem, 16.0, 28.5, 24.0, 0.15)
	return body
