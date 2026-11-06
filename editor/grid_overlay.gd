extends MeshInstance3D
# grid_overlay.gd - thin grid on the ground around the camera pivot.
# Normal lines every "step" metres (faint), chunk borders every "chunk" metres (orange).
# Rebuilt only when the pivot moves to another grid cell.

var step := 5.0
var chunk := 50.0
var radius := 100.0

var _im: ImmediateMesh
var _center := Vector2(1.0e9, 1.0e9)


func _ready() -> void:
	_im = ImmediateMesh.new()
	mesh = _im
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_chunk(c: float) -> void:
	chunk = maxf(c, 1.0)
	_center = Vector2(1.0e9, 1.0e9)


func update_center(p: Vector3) -> void:
	if not visible:
		return
	var c := Vector2(snappedf(p.x, step), snappedf(p.z, step))
	if c.distance_to(_center) < 0.1:
		return
	_center = c
	_rebuild()


func _is_chunk_line(v: float) -> bool:
	var r := fposmod(v, chunk)
	return r < 0.001 or chunk - r < 0.001


func _rebuild() -> void:
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_LINES)
	var faint := Color(1, 1, 1, 0.16)
	var strong := Color(1.0, 0.6, 0.1, 0.85)
	var x0 := _center.x - radius
	var x1 := _center.x + radius
	var z0 := _center.y - radius
	var z1 := _center.y + radius
	var y := 0.04
	var x := x0
	while x <= x1 + 0.001:
		_im.surface_set_color(strong if _is_chunk_line(x) else faint)
		_im.surface_add_vertex(Vector3(x, y, z0))
		_im.surface_set_color(strong if _is_chunk_line(x) else faint)
		_im.surface_add_vertex(Vector3(x, y, z1))
		x += step
	var z := z0
	while z <= z1 + 0.001:
		_im.surface_set_color(strong if _is_chunk_line(z) else faint)
		_im.surface_add_vertex(Vector3(x0, y, z))
		_im.surface_set_color(strong if _is_chunk_line(z) else faint)
		_im.surface_add_vertex(Vector3(x1, y, z))
		z += step
	_im.surface_end()
