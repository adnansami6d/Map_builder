extends Control
# touch_input.gd - full-screen input surface of the editor (behind all panels).
# Turns raw touch / mouse events into 4 simple signals:
#   tapped(pos)    quick tap / click without moving
#   orbit(rel)     1 finger drag (mouse: left drag)
#   pan(rel)       2 finger drag (mouse: right / middle drag, or Shift + left drag)
#   zoom(factor)   pinch (mouse: wheel); factor < 1 = zoom in
# Panels are drawn above this node, so touches on buttons never reach it.

signal tapped(pos: Vector2)
signal orbit(rel: Vector2)
signal pan(rel: Vector2)
signal zoom(factor: float)

const TAP_MOVE_PX := 14.0
const TAP_MAX_MS := 450

var _touches := {}          # finger index -> position
var _tap_start := Vector2.ZERO
var _tap_ms := 0
var _moved := false
var _use_touch := false     # once a real touch is seen, emulated mouse events are ignored
var _lmb := false
var _prev_center := Vector2.ZERO
var _prev_dist := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_use_touch = true
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_use_touch = true
		_on_drag(event)
	elif _use_touch:
		return
	elif event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)


# ---- touch ----
func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touches[e.index] = e.position
		if _touches.size() == 1:
			_tap_start = e.position
			_tap_ms = Time.get_ticks_msec()
			_moved = false
		else:
			_moved = true
			_reset_pinch()
	else:
		var was_single := _touches.size() == 1
		_touches.erase(e.index)
		if was_single and not _moved and Time.get_ticks_msec() - _tap_ms <= TAP_MAX_MS:
			tapped.emit(e.position)
		if _touches.size() >= 2:
			_reset_pinch()


func _on_drag(e: InputEventScreenDrag) -> void:
	_touches[e.index] = e.position
	if _touches.size() == 1:
		if not _moved and e.position.distance_to(_tap_start) > TAP_MOVE_PX:
			_moved = true
		if _moved:
			orbit.emit(e.relative)
	elif _touches.size() >= 2:
		var keys := _touches.keys()
		var a: Vector2 = _touches[keys[0]]
		var b: Vector2 = _touches[keys[1]]
		var center := (a + b) * 0.5
		var dist := a.distance_to(b)
		if _prev_dist > 1.0 and dist > 1.0:
			zoom.emit(_prev_dist / dist)
		pan.emit(center - _prev_center)
		_prev_center = center
		_prev_dist = dist


func _reset_pinch() -> void:
	var keys := _touches.keys()
	if keys.size() < 2:
		return
	var a: Vector2 = _touches[keys[0]]
	var b: Vector2 = _touches[keys[1]]
	_prev_center = (a + b) * 0.5
	_prev_dist = a.distance_to(b)


# ---- mouse (desktop testing) ----
func _on_mouse_button(e: InputEventMouseButton) -> void:
	match e.button_index:
		MOUSE_BUTTON_LEFT:
			if e.pressed:
				_lmb = true
				_tap_start = e.position
				_moved = false
			else:
				if _lmb and not _moved:
					tapped.emit(e.position)
				_lmb = false
		MOUSE_BUTTON_WHEEL_UP:
			if e.pressed:
				zoom.emit(0.9)
		MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				zoom.emit(1.1)


func _on_mouse_motion(e: InputEventMouseMotion) -> void:
	var mask := e.button_mask
	if (mask & MOUSE_BUTTON_MASK_RIGHT) != 0 or (mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:
		pan.emit(e.relative)
	elif (mask & MOUSE_BUTTON_MASK_LEFT) != 0 and _lmb:
		if not _moved and e.position.distance_to(_tap_start) > TAP_MOVE_PX:
			_moved = true
		if _moved:
			if e.shift_pressed:
				pan.emit(e.relative)
			else:
				orbit.emit(e.relative)
