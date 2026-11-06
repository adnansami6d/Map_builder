extends RefCounted
# picker.gd - screen tap -> 3D. No physics needed (works for every element, even without colliders).
#   ground_point(cam, pos)       where the tap hits the ground plane (y = 0), or null
#   pick(cam, pos, aabbs)        id of the nearest object whose box the tap ray hits, or ""
#   node_aabb(node)              world box around all meshes of an object (node must be in the tree)


static func ground_point(cam: Camera3D, pos: Vector2) -> Variant:
	var o := cam.project_ray_origin(pos)
	var d := cam.project_ray_normal(pos)
	return Plane(Vector3.UP, 0.0).intersects_ray(o, d)


static func pick(cam: Camera3D, pos: Vector2, aabbs: Dictionary) -> String:
	var o := cam.project_ray_origin(pos)
	var d := cam.project_ray_normal(pos)
	var best := ""
	var best_t := INF
	for id in aabbs:
		var box: AABB = aabbs[id]
		var hit = box.intersects_ray(o, d)
		if hit != null:
			var t := o.distance_to(hit)
			if t < best_t:
				best_t = t
				best = String(id)
	return best


static func node_aabb(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var a: AABB = mi.global_transform * mi.get_aabb()
		if first:
			box = a
			first = false
		else:
			box = box.merge(a)
	if first:
		return AABB(n.global_position - Vector3(1, 0, 1), Vector3(2, 2, 2))
	return box.grow(0.25)
