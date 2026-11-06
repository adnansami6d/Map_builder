extends "element_base.gd"
# Element: Bunker. One file = one map object. map.json "type": "bunker"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Bunker", "category": "military", "foot": [30, 22]}


static func _bag_wall(body: StaticBody3D, ma: Material, mb: Material, cx: float, cz: float, sx: float, sz: float) -> void:
	Util.part(body, Vector3(sx, 0.6, sz), Vector3(cx, 0.3, cz), ma)
	var long_x := sx > sz
	Util.part(body, Vector3(sx - 0.5 if long_x else sx, 0.6, sz if long_x else sz - 0.5), Vector3(cx, 0.9, cz), mb)
	_box_collider(body, Vector3(sx, 1.2, sz), Vector3(cx, 0.6, cz))


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var dirt := Util.mat(Color(0.55, 0.47, 0.32), 1.0)
	var bag_a := Util.mat(Color(0.76, 0.68, 0.47), 1.0)
	var bag_b := Util.mat(Color(0.68, 0.6, 0.41), 1.0)
	var concrete := Util.mat(Color(0.58, 0.59, 0.57), 0.95)
	var dark := Util.mat(Color(0.08, 0.08, 0.09), 1.0)
	var crate := Util.mat(Color(0.32, 0.38, 0.22), 0.9)
	Util.part(body, Vector3(30.0, 0.05, 22.0), Vector3(0, 0.025, 0), dirt)
	Util.part(body, Vector3(10.0, 2.8, 6.0), Vector3(0, 1.4, -3.5), concrete)
	Util.part(body, Vector3(11.0, 0.4, 7.0), Vector3(0, 3.0, -3.5), concrete)
	Util.part(body, Vector3(6.0, 0.6, 0.12), Vector3(0, 1.9, -0.47), dark)
	Util.part(body, Vector3(1.6, 2.0, 0.12), Vector3(3.0, 1.0, -0.47), dark)
	_box_collider(body, Vector3(11.0, 3.2, 7.0), Vector3(0, 1.6, -3.5))
	_bag_wall(body, bag_a, bag_b, -14.0, 0.0, 0.9, 20.0)
	_bag_wall(body, bag_a, bag_b, 14.0, 0.0, 0.9, 20.0)
	_bag_wall(body, bag_a, bag_b, 0.0, -10.0, 28.0, 0.9)
	_bag_wall(body, bag_a, bag_b, -8.75, 9.0, 10.5, 0.9)
	_bag_wall(body, bag_a, bag_b, 8.75, 9.0, 10.5, 0.9)
	_bag_wall(body, bag_a, bag_b, -7.0, 4.0, 3.5, 0.9)
	_bag_wall(body, bag_a, bag_b, 7.0, 4.0, 3.5, 0.9)
	_bag_wall(body, bag_a, bag_b, 0.0, 5.5, 2.5, 0.9)
	for p in [Vector3(-10.0, 0.4, -6.0), Vector3(-10.0, 0.4, -7.3), Vector3(-8.7, 0.4, -6.6)]:
		Util.part(body, Vector3(1.1, 0.8, 1.1), p, crate)
	return body
