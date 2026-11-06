extends Node3D
# chunk_loader.gd - universal chunk streaming loader for map.json (Godot 4). No game dependency.
#
# Folder layout (loader sits next to map.json; elements are in elements/):
#   <map_dir>/map.json   <map_dir>/chunk_loader.gd   <map_dir>/map_validator.gd   <map_dir>/elements/*.gd
# Use: add this script to a Node3D, set map_dir (empty = the folder this script is in). Target = your player/camera
# (target_path); if empty the active Camera3D is used.
#
# What it does:
#  - splits objects into chunk_size grid chunks (default 50 m)
#  - chunks with any part within load_dist (default 120 m) of the target are built, a little per frame (budget_ms)
#  - chunks farther than load_dist + unload_margin are freed (the margin stops flicker at the border)
#  - objects: elements/<type>.gd  -> static build() -> Node3D
#  - areas:   elements/area_<kind>.gd -> static build(area: Dictionary) -> Node3D (optional; no file = skipped,
#             the game can still read them with get_areas())
#  - every spawned node gets meta "type", "id", "data" (the "data" of map.json); the game reads what it needs
#  - if an element has static occluders() the result is stored in meta "occluders" (used by occlusion in step 5)

signal map_loaded(object_count: int)
signal chunk_loaded(key: Vector2i)
signal chunk_unloaded(key: Vector2i)
signal load_failed(message: String)

const Validator = preload("map_validator.gd")

@export var map_dir := ""
@export var auto_load := true
@export var target_path: NodePath
@export var update_interval := 0.5
@export var budget_ms := 4.0
@export var unload_margin := 20.0

var map_data: Dictionary = {}
var chunk_size := 50.0
var load_dist := 120.0

var _chunks := {}        # Vector2i -> Array of object dictionaries
var _live := {}          # Vector2i -> Node3D root (finished or still being built)
var _building := {}      # Vector2i -> next object index (only while being built)
var _queue: Array = []   # chunk keys waiting to be built
var _cache := {}         # type -> Script or null
var _has_occ := {}       # type -> bool
var _warned := {}
var _areas: Array = []   # {"d": Dictionary, "script": Script, "rect": Rect2, "node": Node3D}
var _timer := 0.0
var _active := false


func _ready() -> void:
	if auto_load:
		if map_dir == "":
			map_dir = String(get_script().resource_path).get_base_dir()
		load_map(map_dir)


func load_map(dir: String) -> bool:
	unload_map()
	map_dir = dir.rstrip("/")
	var parsed = _read_json(map_dir + "/map.json")
	if parsed == null:
		return _fail("map.json not found or not valid JSON in " + map_dir)
	var errs: Array = Validator.validate(parsed)
	if errs.size() > 0:
		return _fail("map.json invalid: %s (+%d more)" % [String(errs[0]), errs.size() - 1])
	map_data = parsed
	chunk_size = float(map_data.get("chunk_size", 50))
	load_dist = float(map_data.get("load_dist", 120))
	var count := 0
	for o in map_data.get("objects", []):
		var p: Array = o["pos"]
		var k := Vector2i(floori(float(p[0]) / chunk_size), floori(float(p[2]) / chunk_size))
		if not _chunks.has(k):
			_chunks[k] = []
		_chunks[k].append(o)
		count += 1
	for a in map_data.get("areas", []):
		var s: Script = _get_script("area_" + String(a["kind"]))
		if s == null:
			continue
		var p: Array = a["pos"]
		var rect: Rect2
		if String(a["shape"]) == "circle":
			var r := float(a["radius"])
			rect = Rect2(float(p[0]) - r, float(p[2]) - r, r * 2.0, r * 2.0)
		else:
			var sz: Array = a["size"]
			rect = Rect2(float(p[0]) - float(sz[0]) * 0.5, float(p[2]) - float(sz[1]) * 0.5, float(sz[0]), float(sz[1]))
		_areas.append({"d": a, "script": s, "rect": rect, "node": null})
	_active = true
	_timer = 0.0
	map_loaded.emit(count)
	return true


func unload_map() -> void:
	for k in _live.keys():
		if is_instance_valid(_live[k]):
			_live[k].queue_free()
	for a in _areas:
		if a["node"] != null and is_instance_valid(a["node"]):
			a["node"].queue_free()
	_chunks.clear()
	_live.clear()
	_building.clear()
	_queue.clear()
	_cache.clear()
	_has_occ.clear()
	_warned.clear()
	_areas.clear()
	map_data = {}
	_active = false


# update the load/unload decision right now (e.g. after teleporting the player)
func force_update() -> void:
	_update_ranges()


# build everything that is in range immediately (use behind a loading screen; may take a moment)
func build_all_near() -> void:
	_update_ranges()
	var old := budget_ms
	budget_ms = 1.0e9
	_build_step()
	budget_ms = old


# areas from map.json (any kind, or one kind) - for the game's own use
func get_areas(kind: String = "") -> Array:
	var out: Array = []
	for a in map_data.get("areas", []):
		if kind == "" or String(a["kind"]) == kind:
			out.append(a)
	return out


func get_stats() -> Dictionary:
	return {"chunks_total": _chunks.size(), "chunks_live": _live.size(), "queued": _queue.size()}


func _process(delta: float) -> void:
	if not _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = update_interval
		_update_ranges()
	_build_step()


func _target_pos() -> Variant:
	var t: Node3D = null
	if not target_path.is_empty():
		t = get_node_or_null(target_path) as Node3D
	if t == null:
		t = get_viewport().get_camera_3d()
	if t == null:
		return null
	return t.global_position


func _update_ranges() -> void:
	var p = _target_pos()
	if p == null:
		return
	var px: float = p.x
	var pz: float = p.z
	var unload_d := load_dist + unload_margin
	# load: only look at the grid cells around the target
	var r := int(ceil(load_dist / chunk_size)) + 1
	var cx := floori(px / chunk_size)
	var cz := floori(pz / chunk_size)
	for ix in range(cx - r, cx + r + 1):
		for iz in range(cz - r, cz + r + 1):
			var k := Vector2i(ix, iz)
			if _chunks.has(k) and not _live.has(k) and _chunk_dist(k, px, pz) <= load_dist:
				_start_chunk(k)
	# unload
	for k in _live.keys():
		if _chunk_dist(k, px, pz) > unload_d:
			_drop_chunk(k)
	# areas (few, big): spawn / free by distance to their rectangle
	for a in _areas:
		var d := _rect_dist(a["rect"], px, pz)
		if a["node"] == null and d <= load_dist:
			var n = a["script"].call("build", a["d"])
			if n is Node3D:
				var ap: Array = a["d"]["pos"]
				n.position = Vector3(float(ap[0]), float(ap[1]), float(ap[2]))
				n.set_meta("kind", a["d"]["kind"])
				n.set_meta("data", a["d"].get("data", {}))
				add_child(n)
				a["node"] = n
			else:
				_warn_once("area_" + String(a["d"]["kind"]), "build(area) must return a Node3D")
				a["node"] = null
				a["rect"] = Rect2(1.0e12, 1.0e12, 0.0, 0.0)   # never try again
		elif a["node"] != null and d > unload_d:
			if is_instance_valid(a["node"]):
				a["node"].queue_free()
			a["node"] = null


func _start_chunk(k: Vector2i) -> void:
	var root := Node3D.new()
	root.name = "chunk_%d_%d" % [k.x, k.y]
	add_child(root)
	_live[k] = root
	_building[k] = 0
	_queue.append(k)


func _drop_chunk(k: Vector2i) -> void:
	if is_instance_valid(_live[k]):
		_live[k].queue_free()
	_live.erase(k)
	_building.erase(k)
	_queue.erase(k)
	chunk_unloaded.emit(k)


func _build_step() -> void:
	var t0 := Time.get_ticks_usec()
	while not _queue.is_empty():
		var k: Vector2i = _queue[0]
		if not _live.has(k):
			_queue.pop_front()
			continue
		var list: Array = _chunks[k]
		var i: int = _building.get(k, 0)
		while i < list.size():
			_spawn(list[i], _live[k])
			i += 1
			if float(Time.get_ticks_usec() - t0) / 1000.0 >= budget_ms:
				_building[k] = i
				return
		_building.erase(k)
		_queue.pop_front()
		chunk_loaded.emit(k)


func _spawn(o: Dictionary, parent: Node3D) -> void:
	var type := String(o["type"])
	var s: Script = _get_script(type)
	if s == null:
		return
	var n = s.call("build")
	if not (n is Node3D):
		_warn_once(type, "build() must return a Node3D")
		return
	var p: Array = o["pos"]
	n.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	n.rotation_degrees.y = float(o.get("rot", 0))
	var sc := float(o.get("scale", 1.0))
	if sc != 1.0:
		n.scale = Vector3(sc, sc, sc)
	n.set_meta("type", type)
	n.set_meta("id", String(o.get("id", "")))
	n.set_meta("data", o.get("data", {}))
	if _has_occ.get(type, false):
		n.set_meta("occluders", s.call("occluders"))
	parent.add_child(n)


func _get_script(type: String) -> Script:
	if _cache.has(type):
		return _cache[type]
	var path := "%s/elements/%s.gd" % [map_dir, type]
	var s: Script = null
	if FileAccess.file_exists(path) or ResourceLoader.exists(path):
		var res = load(path)
		if res is Script and _script_has(res, "build"):
			s = res
			_has_occ[type] = _script_has(res, "occluders")
		else:
			_warn_once(type, "element script failed to load or has no static build(): " + path)
	else:
		_warn_once(type, "element file missing: " + path)
	_cache[type] = s
	return s


static func _script_has(s: Script, fname: String) -> bool:
	for m in s.get_script_method_list():
		if m["name"] == fname:
			return true
	return false


# JSON from a real file (user:// or loose res://) or from an imported JSON resource (inside an exported APK)
func _read_json(path: String) -> Variant:
	if FileAccess.file_exists(path):
		return JSON.parse_string(FileAccess.get_file_as_string(path))
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is JSON:
			return res.data
	return null


func _chunk_dist(k: Vector2i, px: float, pz: float) -> float:
	return _rect_dist(Rect2(k.x * chunk_size, k.y * chunk_size, chunk_size, chunk_size), px, pz)


static func _rect_dist(r: Rect2, px: float, pz: float) -> float:
	var dx := maxf(maxf(r.position.x - px, 0.0), px - r.end.x)
	var dz := maxf(maxf(r.position.y - pz, 0.0), pz - r.end.y)
	return sqrt(dx * dx + dz * dz)


func _warn_once(key: String, msg: String) -> void:
	if not _warned.has(key):
		_warned[key] = true
		push_warning("chunk_loader: " + key + ": " + msg)


func _fail(msg: String) -> bool:
	push_warning("chunk_loader: " + msg)
	load_failed.emit(msg)
	return false
