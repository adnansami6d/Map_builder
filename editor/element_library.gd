extends RefCounted
# element_library.gd - finds the elements (<dir>/<type>.gd) and builds them.
# Works from res:// in the editor AND inside an exported APK (where scripts are listed as
# "house.gd.remap" or "house.gdc").

const SKIP := ["util", "element_base", "spinner"]

static var _scripts := {}       # "dir/type" -> Script or null
static var _re: RegEx


static func _name_ok(t: String) -> bool:
	if _re == null:
		_re = RegEx.new()
		_re.compile("^[a-z0-9_]{1,48}$")
	return _re.search(t) != null


static func _has_build(s: Script) -> bool:
	for m in s.get_script_method_list():
		if m["name"] == "build":
			return true
	return false


# -> Array of {"type","name","category","foot"} sorted by category, then name
static func scan(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	var seen := {}
	for f in d.get_files():
		var n := String(f)
		n = n.trim_suffix(".remap")
		if n.ends_with(".gdc"):
			n = n.trim_suffix(".gdc") + ".gd"
		if not n.ends_with(".gd"):
			continue
		var type := n.get_basename()
		if seen.has(type) or SKIP.has(type) or type.begins_with("area_") or not _name_ok(type):
			continue
		seen[type] = true
		var s := _get_script(dir, type)
		if s == null:
			continue
		var meta: Dictionary = s.get_script_constant_map().get("META", {})
		out.append({
			"type": type,
			"name": String(meta.get("name", type.capitalize())),
			"category": String(meta.get("category", "other")),
			"foot": meta.get("foot", [4, 4]),
		})
	out.sort_custom(func(a, b):
		if a["category"] != b["category"]:
			return a["category"] < b["category"]
		return a["name"] < b["name"])
	return out


# build one element; null if the file is missing or broken
static func make(dir: String, type: String) -> Node3D:
	var s := _get_script(dir, type)
	if s == null:
		return null
	var n = s.call("build")
	return n if n is Node3D else null


static func _get_script(dir: String, type: String) -> Script:
	var key := dir + "/" + type
	if _scripts.has(key):
		return _scripts[key]
	var s: Script = null
	if _name_ok(type):
		var path := key + ".gd"
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is Script and _has_build(res):
				s = res
	if s == null:
		push_warning("element_library: cannot use element '%s' in %s" % [type, dir])
	_scripts[key] = s
	return s
