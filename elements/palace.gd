extends "element_base.gd"
# Element: Palace. One file = one map object. map.json "type": "palace"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Palace", "category": "building", "foot": [36, 20]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var stone := Util.mat(Color(0.93, 0.89, 0.8), 0.8)
	var gold := Util.mat(Color(0.85, 0.68, 0.2), 0.35, 0.6)
	var blue := Util.mat(Color(0.2, 0.3, 0.6), 0.6)
	var dark := Util.mat(Color(0.25, 0.15, 0.1), 0.8)
	Util.part(body, Vector3(24, 10, 14), Vector3(0, 5, 0), stone)
	_box_collider(body, Vector3(24, 10, 14), Vector3(0, 5, 0))
	for sx in [-1.0, 1.0]:
		Util.part(body, Vector3(9, 7, 12), Vector3(sx * 16.5, 3.5, 0), stone)   # wings
		_box_collider(body, Vector3(9, 7, 12), Vector3(sx * 16.5, 3.5, 0))
		var tw := Util.mim(Util.cyl(2.4, 16.0, 10), stone)                      # corner towers
		tw.position = Vector3(sx * 13.0, 8.0, 7.5)
		body.add_child(tw)
		var cap := Util.mim(Util.cone(3.2, 5.0, 10), blue)
		cap.position = Vector3(sx * 13.0, 18.5, 7.5)
		body.add_child(cap)
		_box_collider(body, Vector3(5, 16, 5), Vector3(sx * 13.0, 8.0, 7.5))
	var dome := Util.mim(Util.sphere(5.5, 12, 6), gold)
	dome.scale = Vector3(1, 0.8, 1)
	dome.position = Vector3(0, 12.5, 0)
	body.add_child(dome)
	var spire := Util.mim(Util.cone(0.5, 4.0, 6), gold)
	spire.position = Vector3(0, 19.0, 0)
	body.add_child(spire)
	Util.part(body, Vector3(5, 6, 0.3), Vector3(0, 3, 7.1), dark)                 # gate
	Util.part(body, Vector3(12, 0.6, 3), Vector3(0, 0.3, 8.5), stone)             # steps
	for i in 4:
		Util.part(body, Vector3(0.9, 8, 0.9), Vector3(-4.5 + i * 3.0, 4, 7.6), stone)   # columns
	Util.part(body, Vector3(14, 0.6, 1.4), Vector3(0, 8.3, 7.6), gold)
	return body
