extends "element_base.gd"
# Element: Mobile Tower. One file = one map object. map.json "type": "tower"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Mobile Tower", "category": "industry", "foot": [8, 8]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var steel := Util.mat(Color(0.78, 0.8, 0.82), 0.5, 0.6)
	var red := Util.mat(Color(0.85, 0.15, 0.12), 0.6)
	var H := 30.0
	var lean := rad_to_deg(atan(1.2 / H))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Util.part(body, Vector3(0.18, H + 0.05, 0.18), Vector3(sx * 1.0, H / 2.0, sz * 1.0), steel, Vector3(-sz * lean, 0, sx * lean))
	for i in 6:
		var h := 2.5 + i * 5.0
		var s := 1.6 - 1.2 * h / H
		var m := red if i % 2 == 0 else steel
		for sg in [-1.0, 1.0]:
			Util.part(body, Vector3(s * 2.0, 0.12, 0.12), Vector3(0, h, sg * s), m)
			Util.part(body, Vector3(0.12, 0.12, s * 2.0), Vector3(sg * s, h, 0), m)
	for i in 3:   # panel antennas
		var a := i * TAU / 3.0
		Util.part(body, Vector3(0.5, 1.7, 0.2), Vector3(sin(a) * 0.95, 28.0, cos(a) * 0.95), Util.mat(Color(0.92, 0.92, 0.9)), Vector3(0, rad_to_deg(a), 0))
	Util.part(body, Vector3(0.1, 2.5, 0.1), Vector3(0, 31.0, 0), steel)
	var beacon := Util.mim(Util.sphere(0.4, 8, 4), Util.glow(Color(1.0, 0.1, 0.05), 2.5))
	beacon.position = Vector3(0, 32.4, 0)
	body.add_child(beacon)
	Util.part(body, Vector3(3.0, 2.4, 2.4), Vector3(3.2, 1.2, 0), Util.mat(Color(0.7, 0.72, 0.74)))   # equipment hut
	Util.part(body, Vector3(0.1, 2.0, 0.1), Vector3(2.2, 3.4, 1.0), steel)
	_box_collider(body, Vector3(3.4, H, 3.4), Vector3(0, H / 2.0, 0))
	_box_collider(body, Vector3(3.0, 2.4, 2.4), Vector3(3.2, 1.2, 0))
	return body
