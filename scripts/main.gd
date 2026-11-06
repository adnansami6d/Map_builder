extends Node3D
# main.gd - entry point and "document" of the map editor (step 6).
# Holds the map (same Dictionary as map.json), the 3D objects, selection and the current tool.
# ALL edits go through add_object / delete_object / duplicate_object / set_object, so the
# undo stack (step 7) and save/load (step 8) can hook in at one place.

signal selection_changed(id: String)
signal object_changed(id: String)
signal map_changed()
signal mode_changed(mode: int)

enum Mode { SELECT, MOVE, PLACE }

const ELEMENTS_DIR := "res://elements"
const DEFAULT_MAP := "res://maps/map_01/map.json"

const Library = preload("element_library.gd")
const Picker = preload("picker.gd")
const GridOverlay = preload("grid_overlay.gd")
const EditorCamera = preload("editor_camera.gd")
const EditorUI = preload("editor_ui.gd")
const Validator = preload("../runtime/map_validator.gd")

var map_data: Dictionary = {}
var mode: int = Mode.SELECT
var place_type := ""
var snap := 1.0
var selected := ""
var library: Array = []
var cam_rig            # editor_camera.gd (untyped on purpose: calls its own methods)
var grid               # grid_overlay.gd

var _ground: MeshInstance3D
var _objects_root: Node3D
var _objs := {}          # id -> object Dictionary (the same instance that is inside map_data["objects"])
var _nodes := {}         # id -> Node3D
var _aabbs := {}         # id -> AABB (world box, for picking)
var _sel_inst: MeshInstance3D
var _sel_mesh: ImmediateMesh
var _next_id := 1


func _ready() -> void:
	library = Library.scan(ELEMENTS_DIR)
	_build_world()
	_build_ui()
	_load_default_map()


func _process(_delta: float) -> void:
	grid.update_center(cam_rig.position)


# ------------------------------------------------------------------ world
func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6, 0.78, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 0.95)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.shadow_enabled = false
	add_child(sun)

	_ground = MeshInstance3D.new()
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.36, 0.55, 0.30)
	gm.roughness = 1.0
	_ground.material_override = gm
	add_child(_ground)

	_objects_root = Node3D.new()
	_objects_root.name = "Objects"
	add_child(_objects_root)

	grid = GridOverlay.new()
	add_child(grid)

	_sel_mesh = ImmediateMesh.new()
	_sel_inst = MeshInstance3D.new()
	_sel_inst.mesh = _sel_mesh
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(1.0, 0.9, 0.1)
	sm.no_depth_test = true
	_sel_inst.material_override = sm
	_sel_inst.visible = false
	add_child(_sel_inst)

	cam_rig = EditorCamera.new()
	add_child(cam_rig)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui = EditorUI.new()
	ui.main = self
	layer.add_child(ui)
	var t = ui.touch
	t.tapped.connect(_on_tap)
	t.orbit.connect(cam_rig.orbit)
	t.pan.connect(cam_rig.pan)
	t.zoom.connect(cam_rig.zoom)


# ------------------------------------------------------------------ map
static func new_map() -> Dictionary:
	return {
		"version": 1, "name": "map_01", "chunk_size": 50, "load_dist": 120,
		"occlusion_dist": 50, "ground": {"size": 600}, "objects": [], "areas": [],
	}


func _load_default_map() -> void:
	var parsed = null
	if FileAccess.file_exists(DEFAULT_MAP):
		parsed = JSON.parse_string(FileAccess.get_file_as_string(DEFAULT_MAP))
	elif ResourceLoader.exists(DEFAULT_MAP):
		var res = load(DEFAULT_MAP)
		if res is JSON:
			parsed = res.data
	if parsed is Dictionary and Validator.validate(parsed).is_empty():
		set_map(parsed)
	else:
		push_warning("main: default map not usable, starting with an empty map")
		set_map(new_map())


# replace the whole map (also used by "load" in step 8)
func set_map(d: Dictionary) -> void:
	for n in _nodes.values():
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	_aabbs.clear()
	_objs.clear()
	selected = ""
	map_data = d
	if not (map_data.get("objects") is Array):
		map_data["objects"] = []
	_next_id = 1
	for o in map_data["objects"]:
		if String(o.get("id", "")) == "" or _objs.has(String(o["id"])):
			o["id"] = _new_id()
		_objs[String(o["id"])] = o
	for o in map_data["objects"]:
		_spawn(o)
	var size := float(map_data.get("ground", {}).get("size", 600))
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size)
	_ground.mesh = pm
	cam_rig.limit = size * 0.5
	cam_rig.max_dist = maxf(size, 100.0)
	grid.set_chunk(float(map_data.get("chunk_size", 50)))
	_update_sel_box()
	selection_changed.emit("")
	map_changed.emit()


# ------------------------------------------------------------------ edit API
func add_object(type: String, pos: Vector3) -> String:
	var o := {"id": _new_id(), "type": type, "pos": [pos.x, pos.y, pos.z], "rot": 0.0}
	map_data["objects"].append(o)
	_objs[o["id"]] = o
	_spawn(o)
	map_changed.emit()
	return o["id"]


func delete_object(id: String) -> void:
	if not _objs.has(id):
		return
	var o: Dictionary = _objs[id]
	var i: int = map_data["objects"].find(o)
	if i >= 0:
		map_data["objects"].remove_at(i)
	_objs.erase(id)
	if _nodes.has(id):
		if is_instance_valid(_nodes[id]):
			_nodes[id].queue_free()
		_nodes.erase(id)
	_aabbs.erase(id)
	if selected == id:
		select("")
	map_changed.emit()


func duplicate_object(id: String) -> String:
	if not _objs.has(id):
		return ""
	var o: Dictionary = _objs[id].duplicate(true)
	o["id"] = _new_id()
	var off := 5.0
	if _aabbs.has(id):
		off = (_aabbs[id] as AABB).size.x + 1.0
	var p: Array = o["pos"]
	p[0] = float(p[0]) + off
	map_data["objects"].append(o)
	_objs[o["id"]] = o
	_spawn(o)
	map_changed.emit()
	return o["id"]


func set_object(id: String, pos: Vector3, rot: float, scl: float) -> void:
	if not _objs.has(id):
		return
	var o: Dictionary = _objs[id]
	o["pos"] = [snappedf(pos.x, 0.001), snappedf(pos.y, 0.001), snappedf(pos.z, 0.001)]
	o["rot"] = snappedf(fposmod(rot, 360.0), 0.01)
	if absf(scl - 1.0) > 0.0001:
		o["scale"] = snappedf(maxf(scl, 0.01), 0.001)
	else:
		o.erase("scale")
	var n: Node3D = _nodes[id]
	_apply_transform(n, o)
	_aabbs[id] = Picker.node_aabb(n)
	if id == selected:
		_update_sel_box()
	object_changed.emit(id)


func get_object(id: String) -> Dictionary:
	return _objs.get(id, {})


func get_object_count() -> int:
	return _objs.size()


func select(id: String) -> void:
	if id != "" and not _objs.has(id):
		id = ""
	selected = id
	_update_sel_box()
	selection_changed.emit(id)


func set_mode(m: int) -> void:
	mode = m
	mode_changed.emit(m)


func set_place_type(t: String) -> void:
	place_type = t
	mode_changed.emit(mode)


func set_snap(s: float) -> void:
	snap = s


func set_grid_visible(on: bool) -> void:
	grid.visible = on
	grid.set_chunk(grid.chunk)   # forces a rebuild next frame


# ------------------------------------------------------------------ taps
func _on_tap(pos: Vector2) -> void:
	var cam: Camera3D = cam_rig.cam
	match mode:
		Mode.SELECT:
			select(Picker.pick(cam, pos, _aabbs))
		Mode.PLACE:
			if place_type == "":
				return
			var g = Picker.ground_point(cam, pos)
			if g == null:
				return
			select(add_object(place_type, _snap_v(g)))
		Mode.MOVE:
			if selected == "":
				select(Picker.pick(cam, pos, _aabbs))
				return
			var g = Picker.ground_point(cam, pos)
			if g == null:
				return
			var o: Dictionary = _objs[selected]
			var p := _snap_v(g)
			set_object(selected, p, float(o.get("rot", 0.0)), float(o.get("scale", 1.0)))


func _snap_v(v: Vector3) -> Vector3:
	if snap > 0.0:
		return Vector3(snappedf(v.x, snap), 0.0, snappedf(v.z, snap))
	return Vector3(v.x, 0.0, v.z)


# ------------------------------------------------------------------ internals
func _new_id() -> String:
	while _objs.has("o%d" % _next_id):
		_next_id += 1
	var id := "o%d" % _next_id
	_next_id += 1
	return id


func _spawn(o: Dictionary) -> void:
	var id := String(o["id"])
	var n := Library.make(ELEMENTS_DIR, String(o["type"]))
	if n == null:
		n = _placeholder()   # keep the object in the map even if its element file is missing
	_apply_transform(n, o)
	_objects_root.add_child(n)
	_nodes[id] = n
	_aabbs[id] = Picker.node_aabb(n)


func _apply_transform(n: Node3D, o: Dictionary) -> void:
	var p: Array = o["pos"]
	n.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	n.rotation_degrees = Vector3(0.0, float(o.get("rot", 0.0)), 0.0)
	var s := float(o.get("scale", 1.0))
	n.scale = Vector3(s, s, s)


func _placeholder() -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2, 2, 2)
	mi.mesh = bm
	mi.position = Vector3(0, 1, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.9, 0.15, 0.15)
	mi.material_override = m
	n.add_child(mi)
	return n


func _update_sel_box() -> void:
	_sel_mesh.clear_surfaces()
	if selected == "" or not _aabbs.has(selected):
		_sel_inst.visible = false
		return
	var a: AABB = (_aabbs[selected] as AABB).grow(0.05)
	var c: Array = []
	for i in 8:
		c.append(a.get_endpoint(i))
	_sel_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 8:
		for j in range(i + 1, 8):
			var d := 0
			if not is_equal_approx(c[i].x, c[j].x):
				d += 1
			if not is_equal_approx(c[i].y, c[j].y):
				d += 1
			if not is_equal_approx(c[i].z, c[j].z):
				d += 1
			if d == 1:
				_sel_mesh.surface_add_vertex(c[i])
				_sel_mesh.surface_add_vertex(c[j])
	_sel_mesh.surface_end()
	_sel_inst.visible = true
