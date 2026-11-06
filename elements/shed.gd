extends "element_base.gd"
# Element: Shed. One file = one map object. map.json "type": "shed"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "Shed", "category": "building", "foot": [5, 4]}


static func build() -> Node3D:
	return _building(Vector3(5, 2.6, 4), Color(0.55, 0.42, 0.28), Color(0.3, 0.32, 0.36), 1.2, "shed")
