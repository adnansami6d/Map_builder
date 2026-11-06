extends "element_base.gd"
# Element: House. One file = one map object. map.json "type": "house"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "House", "category": "building", "foot": [8, 6]}


static func build() -> Node3D:
	return _building(Vector3(8, 3, 6), Color(0.93, 0.88, 0.72), Color(0.5, 0.22, 0.14), 2.2, "house")
