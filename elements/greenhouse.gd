extends "element_base.gd"
# Element: Greenhouse. One file = one map object. map.json "type": "greenhouse"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Greenhouse", "category": "farm", "foot": [12, 6]}


static func build() -> Node3D:
	var body := StaticBody3D.new()
	var size := Vector3(12, 3.0, 6)
	var frame := Util.mat(Color(0.9, 0.9, 0.9), 0.4, 0.4)
	var glass := Util.mat(Color(0.7, 0.9, 0.85, 0.35), 0.1)
	var g := Util.mim(Util.box(size), glass)
	g.position = Vector3(0, size.y / 2.0, 0)
	body.add_child(g)
	var prism := PrismMesh.new()
	prism.size = Vector3(size.x, 1.6, size.z)
	var roof := Util.mim(prism, glass)
	roof.position = Vector3(0, size.y + 0.8, 0)
	body.add_child(roof)
	for i in 5:
		var x := -size.x / 2.0 + i * size.x / 4.0
		for sz in [-size.z / 2.0, size.z / 2.0]:
			Util.part(body, Vector3(0.12, size.y, 0.12), Vector3(x, size.y / 2.0, sz), frame)
	Util.part(body, Vector3(size.x, 0.12, 0.12), Vector3(0, size.y, size.z / 2.0), frame)
	Util.part(body, Vector3(size.x, 0.12, 0.12), Vector3(0, size.y, -size.z / 2.0), frame)
	for i in 4:   # green plants inside
		Util.part(body, Vector3(size.x - 1.5, 0.5, 0.8), Vector3(0, 0.3, -2.0 + i * 1.33), Util.mat(Color(0.2, 0.55, 0.2)))
	_box_collider(body, size, Vector3(0, size.y / 2.0, 0))
	return body
