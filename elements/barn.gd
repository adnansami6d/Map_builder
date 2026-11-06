extends "element_base.gd"
# Element: Barn. One file = one map object. map.json "type": "barn"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Barn", "category": "building", "foot": [10, 8]}


static func build() -> Node3D:
	return _building(Vector3(10, 5, 8), Color(0.7, 0.15, 0.12), Color(0.3, 0.2, 0.14), 2.8, "barn")
