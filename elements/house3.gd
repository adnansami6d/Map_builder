extends "element_base.gd"
# Element: House 3. One file = one map object. map.json "type": "house3"
# Front (door side) looks to +Z when rot = 0.


const META := {"name": "House 3", "category": "building", "foot": [7, 6]}


static func build() -> Node3D:
	return _building(Vector3(7, 3.2, 6), Color(0.9, 0.78, 0.55), Color(0.35, 0.25, 0.2), 2.4, "house")
