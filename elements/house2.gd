extends "element_base.gd"
# Element: House 2. One file = one map object. map.json "type": "house2"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "House 2", "category": "building", "foot": [8, 6]}


static func build() -> Node3D:
	return _building(Vector3(8, 3, 6), Color(0.72, 0.82, 0.9), Color(0.25, 0.27, 0.32), 2.2, "house")
