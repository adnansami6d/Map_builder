extends "element_base.gd"
# Element: Solar Field. One file = one map object. map.json "type": "solar"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Solar Field", "category": "industry", "foot": [36, 27]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var gravel := Util.mat(Color(0.6, 0.6, 0.57), 1.0)
	var panel_m := Util.mat(Color(0.1, 0.2, 0.45), 0.25, 0.3)
	var post_m := Util.mat(Color(0.72, 0.73, 0.75), 0.5, 0.5)
	var cab := Util.mat(Color(0.82, 0.83, 0.8), 0.9)
	Util.part(body, Vector3(36.0, 0.05, 27.0), Vector3(0, 0.025, 0), gravel)
	var panels: Array = []
	var posts: Array = []
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(25.0))
	for r in 5:
		var z := -10.0 + r * 4.6
		for i in 11:
			var x := -16.5 + i * 3.3
			panels.append(Transform3D(tilt, Vector3(x, 1.25, z)))
			posts.append(Transform3D(Basis(), Vector3(x, 0.6, z)))
		_box_collider(body, Vector3(35.0, 1.8, 2.0), Vector3(0, 0.9, z))
	Util.multi(body, Util.box(Vector3(3.1, 0.07, 2.0)), panel_m, panels)
	Util.multi(body, Util.box(Vector3(0.12, 1.2, 0.12)), post_m, posts)
	Util.part(body, Vector3(3.0, 2.4, 2.0), Vector3(-14.0, 1.2, 11.5), cab)
	Util.part(body, Vector3(1.6, 1.6, 1.0), Vector3(-10.0, 0.8, 11.5), cab)
	_box_collider(body, Vector3(3.0, 2.4, 2.0), Vector3(-14.0, 1.2, 11.5))
	return body
