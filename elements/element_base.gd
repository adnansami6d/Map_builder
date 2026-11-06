extends RefCounted
# Base for all elements in res://elements/ (and user maps: <map>/elements/).
# Every element file must have:  const META := {...}  and  static func build() -> Node3D
# (children use Util and the helpers below straight from this base file)
# Optional: static func occluders() -> Array   # [{"pos": Vector3, "size": Vector3}] wall boxes for culling (step 5)

const Util = preload("util.gd")



static func _box_collider(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)


static func _building(size: Vector3, wall: Color, roof_col: Color, roof_h: float, kind: String) -> Node3D:
	var body := StaticBody3D.new()
	var walls := Util.mi(Util.box(size), wall)
	walls.position = Vector3(0, size.y / 2.0, 0)
	body.add_child(walls)
	_box_collider(body, size, Vector3(0, size.y / 2.0, 0))
	var prism := PrismMesh.new()
	prism.size = Vector3(size.x + 0.8, roof_h, size.z + 0.8)
	var roof := Util.mi(prism, roof_col)
	roof.position = Vector3(0, size.y + roof_h / 2.0, 0)
	body.add_child(roof)

	var trim := Util.mat(Color(0.95, 0.95, 0.92))
	var door_m := Util.mat(Color(0.32, 0.2, 0.1))
	var glass := Util.mat(Color(0.55, 0.75, 0.9), 0.2, 0.2)
	var fz := size.z / 2.0 + 0.02
	match kind:
		"house":
			Util.part(body, Vector3(1.2, 2.0, 0.08), Vector3(0, 1.0, fz), door_m)
			for sx in [-2.4, 2.4]:
				Util.part(body, Vector3(1.3, 1.2, 0.06), Vector3(sx, 1.7, fz), trim)
				Util.part(body, Vector3(1.1, 1.0, 0.08), Vector3(sx, 1.7, fz + 0.01), glass)
			Util.part(body, Vector3(0.9, 3.4, 0.9), Vector3(size.x * 0.28, size.y + roof_h * 0.65, -size.z * 0.15), Util.mat(Color(0.5, 0.3, 0.25)))   # chimney
		"barn":
			Util.part(body, Vector3(4.2, 3.6, 0.08), Vector3(0, 1.8, fz), door_m)
			Util.part(body, Vector3(0.18, 3.6, 0.1), Vector3(0, 1.8, fz + 0.02), trim)
			Util.part(body, Vector3(4.4, 0.18, 0.1), Vector3(0, 3.7, fz + 0.02), trim)
			Util.part(body, Vector3(4.2, 0.14, 0.1), Vector3(0, 1.8, fz + 0.03), trim, Vector3(0, 0, 40))
			Util.part(body, Vector3(4.2, 0.14, 0.1), Vector3(0, 1.8, fz + 0.03), trim, Vector3(0, 0, -40))
		"shed":
			Util.part(body, Vector3(1.1, 1.9, 0.08), Vector3(0, 0.95, fz), door_m)
	return body


static func _taper(top: float, bottom: float, h: float, radial: int = 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = radial
	c.rings = 1
	return c
