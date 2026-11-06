extends Control
# editor_ui.gd - all editor panels, built in code (no .tscn needed). Landscape layout:
#   top bar     title, hint, stats, Grid, Snap, zoom -/+
#   left panel  element palette (grouped by category)
#   right panel properties of the selected object (position, rotation, scale)
#   bottom bar  tools [Select] [Move] [Place]   actions [Copy] [Delete]
# The 3D area behind the panels is touch_input.gd (member "touch"); main.gd connects its signals.

const TouchInput = preload("touch_input.gd")

const TOP_H := 56.0
const BOTTOM_H := 64.0
const LEFT_W := 230.0
const RIGHT_W := 270.0

var main              # main.gd (untyped on purpose)
var touch              # touch_input.gd

var _syncing := false
var _t := 0.0
var _hint: Label
var _stats: Label
var _right: PanelContainer
var _id_label: Label
var _pos: Array = []
var _rot: SpinBox
var _scl: SpinBox
var _mode_btns := {}
var _copy_btn: Button
var _del_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font_size = 20
	theme = th

	touch = TouchInput.new()
	add_child(touch)

	_build_top()
	_build_left()
	_build_right()
	_build_bottom()

	main.selection_changed.connect(_on_selection)
	main.object_changed.connect(_on_object_changed)
	main.mode_changed.connect(_on_mode)
	_on_selection(main.selected)
	_on_mode(main.mode)
	_update_stats()


func _process(delta: float) -> void:
	_t += delta
	if _t >= 0.5:
		_t = 0.0
		_update_stats()


# ------------------------------------------------------------------ builders
func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.15, 0.88)
	sb.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _btn(text: String, toggle := false) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = toggle
	b.custom_minimum_size = Vector2(0, 44)
	return b


func _build_top() -> void:
	var p := _panel()
	add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	p.offset_bottom = TOP_H
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)

	var title := Label.new()
	title.text = "3D Map Creator"
	h.add_child(title)

	_hint = Label.new()
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.clip_text = true
	_hint.modulate = Color(0.75, 0.9, 1.0)
	h.add_child(_hint)

	_stats = Label.new()
	h.add_child(_stats)

	var gcb := CheckButton.new()
	gcb.text = "Grid"
	gcb.button_pressed = true
	gcb.toggled.connect(func(on: bool): main.set_grid_visible(on))
	h.add_child(gcb)

	var snap := OptionButton.new()
	snap.add_item("Snap off")
	snap.add_item("Snap 1 m")
	snap.add_item("Snap 5 m")
	snap.select(1)
	snap.item_selected.connect(func(i: int): main.set_snap([0.0, 1.0, 5.0][i]))
	h.add_child(snap)

	var zo := _btn("-")
	zo.custom_minimum_size.x = 44
	zo.pressed.connect(func(): main.cam_rig.zoom(1.25))
	h.add_child(zo)
	var zi := _btn("+")
	zi.custom_minimum_size.x = 44
	zi.pressed.connect(func(): main.cam_rig.zoom(0.8))
	h.add_child(zi)


func _build_left() -> void:
	var p := _panel()
	add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	p.offset_left = 0.0
	p.offset_right = LEFT_W
	p.offset_top = TOP_H
	p.offset_bottom = -BOTTOM_H
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)

	if main.library.is_empty():
		var l := Label.new()
		l.text = "No elements found in res://elements"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		return
	var group := ButtonGroup.new()
	var cat := ""
	for e in main.library:
		if String(e["category"]) != cat:
			cat = String(e["category"])
			var l := Label.new()
			l.text = cat.to_upper()
			l.modulate = Color(0.6, 0.8, 1.0)
			v.add_child(l)
		var b := _btn(String(e["name"]), true)
		b.button_group = group
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_pick_element.bind(String(e["type"])))
		v.add_child(b)


func _build_right() -> void:
	_right = _panel()
	add_child(_right)
	_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_right.offset_left = -RIGHT_W - 6.0
	_right.offset_right = -6.0
	_right.offset_top = TOP_H + 6.0
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_right.add_child(v)

	_id_label = Label.new()
	_id_label.modulate = Color(1.0, 0.92, 0.4)
	v.add_child(_id_label)

	var g := GridContainer.new()
	g.columns = 2
	v.add_child(g)
	for ax in ["X", "Y", "Z"]:
		_add_row(g, ax, -1000000.0, 1000000.0, 0.01)
	_pos = [g.get_child(1), g.get_child(3), g.get_child(5)]
	_rot = _add_row(g, "Rot", 0.0, 360.0, 1.0)
	_scl = _add_row(g, "Scale", 0.1, 20.0, 0.05)

	var rb := HBoxContainer.new()
	v.add_child(rb)
	var rm := _btn("-15")
	rm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rm.pressed.connect(func(): _rot.value = fposmod(_rot.value - 15.0, 360.0))
	rb.add_child(rm)
	var rp := _btn("+15")
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rp.pressed.connect(func(): _rot.value = fposmod(_rot.value + 15.0, 360.0))
	rb.add_child(rp)


func _add_row(g: GridContainer, label: String, lo: float, hi: float, step: float) -> SpinBox:
	var l := Label.new()
	l.text = label
	g.add_child(l)
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size = Vector2(150, 40)
	s.value_changed.connect(func(_v: float): _apply_props())
	g.add_child(s)
	return s


func _build_bottom() -> void:
	var p := _panel()
	add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	p.offset_top = -BOTTOM_H
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)

	var group := ButtonGroup.new()
	var modes := [["Select", 0], ["Move", 1], ["Place", 2]]
	for m in modes:
		var b := _btn(String(m[0]), true)
		b.button_group = group
		b.custom_minimum_size.x = 110
		b.pressed.connect(func(): main.set_mode(int(m[1])))
		h.add_child(b)
		_mode_btns[int(m[1])] = b

	h.add_child(VSeparator.new())

	_copy_btn = _btn("Copy")
	_copy_btn.custom_minimum_size.x = 110
	_copy_btn.pressed.connect(func():
		var id: String = main.duplicate_object(main.selected)
		if id != "":
			main.select(id))
	h.add_child(_copy_btn)

	_del_btn = _btn("Delete")
	_del_btn.custom_minimum_size.x = 110
	_del_btn.pressed.connect(func(): main.delete_object(main.selected))
	h.add_child(_del_btn)


# ------------------------------------------------------------------ callbacks
func _on_pick_element(type: String) -> void:
	main.set_place_type(type)
	main.set_mode(2)


func _on_mode(m: int) -> void:
	for k in _mode_btns:
		(_mode_btns[k] as Button).set_pressed_no_signal(k == m)
	match m:
		0:
			_hint.text = "Tap an object to select it"
		1:
			_hint.text = "Tap the ground to move the selected object"
		2:
			var nm := "pick an element on the left"
			for e in main.library:
				if e["type"] == main.place_type:
					nm = String(e["name"])
			_hint.text = "Tap the ground to place: " + nm


func _on_selection(id: String) -> void:
	_right.visible = id != ""
	_copy_btn.disabled = id == ""
	_del_btn.disabled = id == ""
	if id != "":
		_fill(id)


func _on_object_changed(id: String) -> void:
	if id == main.selected:
		_fill(id)


func _fill(id: String) -> void:
	var o: Dictionary = main.get_object(id)
	if o.is_empty():
		return
	_syncing = true
	_id_label.text = "%s  (%s)" % [id, String(o["type"])]
	var p: Array = o["pos"]
	for i in 3:
		(_pos[i] as SpinBox).value = float(p[i])
	_rot.value = float(o.get("rot", 0.0))
	_scl.value = float(o.get("scale", 1.0))
	_syncing = false


func _apply_props() -> void:
	if _syncing or main.selected == "":
		return
	var pos := Vector3((_pos[0] as SpinBox).value, (_pos[1] as SpinBox).value, (_pos[2] as SpinBox).value)
	main.set_object(main.selected, pos, _rot.value, _scl.value)


func _update_stats() -> void:
	_stats.text = "Objects %d | FPS %d" % [main.get_object_count(), Engine.get_frames_per_second()]
