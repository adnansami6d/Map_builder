extends "element_base.gd"
# Element: Tree. One file = one map object. map.json "type": "tree"
# Front (door side) looks to +Z when rot = 0.


static var trunk_mesh: Mesh
static var leaf_mesh: Mesh
static var trunk_mat: Material
static var leaf_mat: Material

const META := {"name": "Tree", "category": "nature", "foot": [2, 2]}


static func build() -> Node3D:
	if trunk_mesh == null:
		trunk_mesh = Util.cyl(0.4, 5.0, 8)
		leaf_mesh = Util.sphere(3.0, 12, 6)
		trunk_mat = Util.mat(Color(0.4, 0.26, 0.13))
		leaf_mat = Util.mat(Color(0.14, 0.52, 0.2))
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.4
	sh.height = 5.0
	cs.shape = sh
	cs.position = Vector3(0, 2.5, 0)
	body.add_child(cs)
	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.material_override = trunk_mat
	trunk.position = Vector3(0, 2.5, 0)
	body.add_child(trunk)
	var leaves := MeshInstance3D.new()
	leaves.mesh = leaf_mesh
	leaves.material_override = leaf_mat
	leaves.position = Vector3(0, 6.5, 0)
	body.add_child(leaves)
	return body
