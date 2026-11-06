extends "element_base.gd"
# Element: Seed Shop. One file = one map object. map.json "type": "seedshop"
# Front (door side) looks to +Z when rot = 0.

const Shop = preload("shop.gd")

const META := {"name": "Seed Shop", "category": "building", "foot": [6, 5]}


static func build() -> Node3D:
	var body := Shop.build()
	Util.part(body, Vector3(6.6, 0.25, 5.6), Vector3(0, 3.12, 0), Util.mat(Color(0.2, 0.6, 0.25)))
	Util.part(body, Vector3(5.4, 0.15, 1.8), Vector3(0, 2.72, 3.3), Util.mat(Color(0.35, 0.8, 0.3)))
	for i in 3:
		Util.part(body, Vector3(0.8, 0.5, 0.5), Vector3(-1.2 + 0.9 * float(i), 0.25, 4.1), Util.mat(Color(0.8, 0.7, 0.45)))
	Util.part(body, Vector3(4.0, 0.9, 0.1), Vector3(0, 3.9, 2.6), Util.mat(Color(0.15, 0.5, 0.2)))
	return body
