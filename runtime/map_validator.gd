extends RefCounted
# Checks a parsed map.json (Dictionary) before the loader uses it. Universal: no game dependency.
# Use:  var errs: Array = preload("map_validator.gd").validate(JSON.parse_string(text))
#       if errs.size() > 0: show errs[0] ...

const MAX_OBJECTS := 200000
const MAX_AREAS := 20000
const MAX_COORD := 1000000.0
const MAX_ERRORS := 30

static var _re: RegEx


# "type" / "kind" become file names (elements/<type>.gd), so only a-z 0-9 _ are allowed (blocks ../ tricks)
static func name_ok(t) -> bool:
	if not (t is String):
		return false
	if _re == null:
		_re = RegEx.new()
		_re.compile("^[a-z0-9_]{1,48}$")
	return _re.search(t) != null


static func _num(v) -> bool:
	return (v is float or v is int) and is_finite(float(v)) and absf(float(v)) <= MAX_COORD


static func _vec(v, n: int) -> bool:
	if not (v is Array) or v.size() != n:
		return false
	for x in v:
		if not _num(x):
			return false
	return true


static func validate(d) -> Array:
	var errs: Array = []
	if not (d is Dictionary):
		return ["map.json: top level must be an object { }"]
	if not (d.get("version") is float or d.get("version") is int) or int(d["version"]) != 1:
		errs.append("version must be 1")
	for k in ["chunk_size", "load_dist", "occlusion_dist"]:
		if d.has(k) and not (_num(d[k]) and float(d[k]) > 0.0):
			errs.append("%s must be a number > 0" % k)
	if d.has("ground") and not (d["ground"] is Dictionary and _num(d["ground"].get("size", 0))):
		errs.append("ground must be {\"size\": number}")
	var ids := {}
	var objs = d.get("objects", [])
	if not (objs is Array):
		errs.append("objects must be a list [ ]")
		objs = []
	if objs.size() > MAX_OBJECTS:
		errs.append("too many objects (max %d)" % MAX_OBJECTS)
		objs = []
	for i in objs.size():
		if errs.size() >= MAX_ERRORS:
			break
		var o = objs[i]
		var tag := "objects[%d]" % i
		if not (o is Dictionary):
			errs.append(tag + ": must be an object { }")
			continue
		if not name_ok(o.get("type")):
			errs.append(tag + ": type must be a-z 0-9 _ only (1-48 chars)")
		if not _vec(o.get("pos"), 3):
			errs.append(tag + ": pos must be [x, y, z] numbers")
		if o.has("rot") and not _num(o["rot"]):
			errs.append(tag + ": rot must be a number (degrees)")
		if o.has("scale") and not (_num(o["scale"]) and float(o["scale"]) > 0.0):
			errs.append(tag + ": scale must be a number > 0")
		if o.has("data") and not (o["data"] is Dictionary):
			errs.append(tag + ": data must be an object { }")
		if o.has("id"):
			if not (o["id"] is String):
				errs.append(tag + ": id must be text")
			elif ids.has(o["id"]):
				errs.append(tag + ": duplicate id " + String(o["id"]))
			else:
				ids[o["id"]] = true
	var areas = d.get("areas", [])
	if not (areas is Array):
		errs.append("areas must be a list [ ]")
		areas = []
	if areas.size() > MAX_AREAS:
		errs.append("too many areas (max %d)" % MAX_AREAS)
		areas = []
	for i in areas.size():
		if errs.size() >= MAX_ERRORS:
			break
		var a = areas[i]
		var tag := "areas[%d]" % i
		if not (a is Dictionary):
			errs.append(tag + ": must be an object { }")
			continue
		if not name_ok(a.get("kind")):
			errs.append(tag + ": kind must be a-z 0-9 _ only (1-48 chars)")
		if not _vec(a.get("pos"), 3):
			errs.append(tag + ": pos must be [x, y, z] numbers")
		var shape = a.get("shape")
		if shape == "rect":
			if not _vec(a.get("size"), 2):
				errs.append(tag + ": rect needs size [w, d]")
		elif shape == "circle":
			if not (_num(a.get("radius")) and float(a["radius"]) > 0.0):
				errs.append(tag + ": circle needs radius > 0")
		else:
			errs.append(tag + ": shape must be rect or circle")
		if a.has("data") and not (a["data"] is Dictionary):
			errs.append(tag + ": data must be an object { }")
	return errs
