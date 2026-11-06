extends RefCounted
# Standalone helpers for element scripts. No dependency on any game project.
# Use:  Util.mi(...), Util.part(...)  (element_base.gd already preloads this file as Util)

static var _mats := {}


# one shared material per look (cheap on phones). Never change a material you got from here.
static func mat(color: Color, rough: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [color.to_html(true), rough, metal]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if color.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m


static func glow(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var key := "glow_%s_%s" % [color.to_html(true), energy]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	_mats[key] = m
	return m


static func mi(mesh: Mesh, color: Color, rough: float = 0.85, metal: float = 0.0) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = mat(color, rough, metal)
	return n


static func mim(mesh: Mesh, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = material
	return n


static func part(parent: Node, size: Vector3, pos: Vector3, material: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var n := mim(box(size), material)
	n.position = pos
	n.rotation_degrees = rot_deg
	parent.add_child(n)
	return n


static func box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func sphere(r: float, radial: int = 16, rings: int = 8) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = radial
	s.rings = rings
	return s


static func cyl(r: float, h: float, radial: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = radial
	c.rings = 1
	return c


static func cone(r: float, h: float, radial: int = 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = r
	c.height = h
	c.radial_segments = radial
	c.rings = 1
	return c


# many copies of one mesh in ONE draw call
static func multi(parent: Node, mesh: Mesh, material: Material, xforms: Array, colors: Array = []) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors.size() == xforms.size() and colors.size() > 0
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = material
	parent.add_child(inst)
	return inst
