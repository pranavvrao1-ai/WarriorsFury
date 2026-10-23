extends Camera3D

@export var move_speed: float = 7.0
@export var look_sensitivity: float = 0.003

var _mouse_captured: bool = false
var _rotation_x: float = 0.0
var _rotation_y: float = 0.0

var _cctv_cams: Array[Camera3D] = []
var _cctv_index: int = 0
var _hud_label: Label = null
var _interact_label: Label = null
var _banner_label: Label = null
var _banner_timer: float = 0.0
var _rec_time: float = 0.0

var _current_interactable: Dictionary = {}

func _ready() -> void:
	_rotation_x = rotation.x
	_rotation_y = rotation.y
	_create_hud()

func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD_Layer"
	add_child(canvas)

	# Top info HUD
	_hud_label = Label.new()
	_hud_label.position = Vector2(24, 20)
	_hud_label.add_theme_font_size_override("font_size", 16)
	_hud_label.add_theme_color_override("font_color", Color("74f4ff"))
	_hud_label.text = "[C] Cycle CCTV Cameras (1-9) | [E] Interact | [Click] Look | [WASD] Move"
	canvas.add_child(_hud_label)

	# Interaction prompt in bottom-center
	_interact_label = Label.new()
	_interact_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
	_interact_label.position = Vector2(0, -90)
	_interact_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_label.add_theme_font_size_override("font_size", 22)
	_interact_label.add_theme_color_override("font_color", Color("ffdd44"))
	_interact_label.text = ""
	canvas.add_child(_interact_label)

	# Action feedback banner (top center)
	_banner_label = Label.new()
	_banner_label.anchors_preset = Control.PRESET_CENTER_TOP
	_banner_label.position = Vector2(0, 70)
	_banner_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 20)
	_banner_label.add_theme_color_override("font_color", Color("55ffaa"))
	_banner_label.text = ""
	canvas.add_child(_banner_label)

func _refresh_cctv_list() -> void:
	_cctv_cams.clear()
	var nodes := get_tree().get_nodes_in_group("cctv_camera")
	for node in nodes:
		if node is Camera3D:
			_cctv_cams.append(node)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _cctv_index == 0:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_mouse_captured = true
		else:
			_switch_to_cam(0)
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_mouse_captured = false
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_refresh_cctv_list()
			if _cctv_cams.size() > 0:
				var next_idx := (_cctv_index + 1) % (_cctv_cams.size() + 1)
				_switch_to_cam(next_idx)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			_refresh_cctv_list()
			var req_idx: int = int(event.keycode) - int(KEY_0)
			if req_idx <= _cctv_cams.size():
				_switch_to_cam(req_idx)
		elif event.keycode == KEY_0:
			_switch_to_cam(0)
		elif event.keycode == KEY_E and _cctv_index == 0:
			_try_interact()
	elif event is InputEventMouseMotion and _mouse_captured and _cctv_index == 0:
		_rotation_y -= event.relative.x * look_sensitivity
		_rotation_x = clamp(_rotation_x - event.relative.y * look_sensitivity, -1.4, 1.4)
		rotation = Vector3(_rotation_x, _rotation_y, 0.0)

func _try_interact() -> void:
	if _current_interactable.is_empty():
		return
	var room_node := get_parent()
	if room_node != null and room_node.has_method("trigger_interaction"):
		var msg: String = room_node.trigger_interaction(_current_interactable)
		_show_banner(msg)

func _show_banner(msg: String) -> void:
	_banner_label.text = msg
	_banner_timer = 4.0

func _switch_to_cam(index: int) -> void:
	_cctv_index = index
	if _cctv_index == 0:
		make_current()
		_hud_label.text = "[C] Cycle CCTV Cameras (1-9) | [E] Interact | [Click] Look | [WASD] Move"
		_hud_label.add_theme_color_override("font_color", Color("74f4ff"))
		_interact_label.visible = true
	else:
		if _cctv_index - 1 < _cctv_cams.size():
			var target_cam: Camera3D = _cctv_cams[_cctv_index - 1]
			target_cam.make_current()
			_hud_label.add_theme_color_override("font_color", Color("ff3355"))
			_interact_label.visible = false

func _process(delta: float) -> void:
	_rec_time += delta

	# Banner timer
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner_label.text = ""

	# Check interactables when in player mode
	if _cctv_index == 0:
		var room_node := get_parent()
		if room_node != null and room_node.has_method("get_nearest_interactable"):
			_current_interactable = room_node.get_nearest_interactable(global_position)
			if not _current_interactable.is_empty():
				_interact_label.text = "⚡ [E] " + str(_current_interactable.get("prompt", "Interact"))
			else:
				_interact_label.text = ""
		else:
			_interact_label.text = ""
	else:
		_interact_label.text = ""

	# CCTV HUD blinking
	if _cctv_index > 0 and _cctv_index - 1 < _cctv_cams.size():
		var rec_blink := "● REC" if fmod(_rec_time, 1.0) < 0.6 else "○ REC"
		var cam_name := _cctv_cams[_cctv_index - 1].name
		_hud_label.text = rec_blink + " " + cam_name + " [SURVEILLANCE FEED LIVE]\n[C / 1-9] Next Camera | [0 / Click / WASD] Return to Player"

	# Auto-return from CCTV on movement
	if _cctv_index != 0:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D):
			_switch_to_cam(0)
			return

	# Movement in Player Mode
	if _cctv_index == 0:
		var move_vec := Vector3.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			move_vec -= transform.basis.z
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			move_vec += transform.basis.z
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			move_vec -= transform.basis.x
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			move_vec += transform.basis.x
		if Input.is_key_pressed(KEY_SPACE):
			move_vec += Vector3.UP
		if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_Q):
			move_vec -= Vector3.UP

		if move_vec.length_squared() > 0.0:
			var speed := move_speed
			if Input.is_key_pressed(KEY_SHIFT):
				speed *= 1.8
			position += move_vec.normalized() * speed * delta
