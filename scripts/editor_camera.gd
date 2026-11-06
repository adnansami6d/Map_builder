extends Node3D
# editor_camera.gd - orbit camera rig. This node is the pivot (the point we look at);
# the Camera3D sits "distance" metres behind it. Driven by touch_input.gd signals.

var yaw := 30.0          # degrees
var pitch := -45.0       # degrees, -88 (almost top-down) .. -8 (almost horizontal)
var distance := 70.0
var min_dist := 3.0
var max_dist := 800.0
var limit := 300.0       # the pivot stays inside +-limit metres (set from ground size)
var cam: Camera3D


func _init() -> void:
	cam = Camera3D.new()
	cam.near = 0.2
	cam.far = 3000.0
	cam.fov = 60.0
	add_child(cam)


func _ready() -> void:
	cam.make_current()
	_apply()


func orbit(rel: Vector2) -> void:
	yaw -= rel.x * 0.3
	pitch = clampf(pitch - rel.y * 0.3, -88.0, -8.0)
	_apply()


func pan(rel: Vector2) -> void:
	var k := distance * 0.0016
	var a := deg_to_rad(yaw)
	var right := Vector3(cos(a), 0.0, -sin(a))
	var fwd := Vector3(-sin(a), 0.0, -cos(a))
	position -= right * rel.x * k
	position += fwd * rel.y * k
	position.x = clampf(position.x, -limit, limit)
	position.z = clampf(position.z, -limit, limit)
	position.y = 0.0


func zoom(factor: float) -> void:
	distance = clampf(distance * factor, min_dist, max_dist)
	_apply()


func focus_on(p: Vector3) -> void:
	position = Vector3(p.x, 0.0, p.z)


func _apply() -> void:
	rotation_degrees = Vector3(pitch, yaw, 0.0)
	cam.position = Vector3(0.0, 0.0, distance)
