extends CharacterBody3D

@export var walk_speed: float = 4.5
@export var sprint_speed: float = 8.5
@export var jump_velocity: float = 4.2
@export var look_sensitivity: float = 0.003

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var is_frozen: bool = false
var _mouse_captured: bool = false
var _cctv_cams: Array[Camera3D] = []
var _cctv_index: int = 0
var _hud_label: Label = null
var _interact_label: Label = null
var _banner_label: Label = null
var _banner_timer: float = 0.0
var _rec_time: float = 0.0
var _audio: Node = null
var _character_visual: Node3D = null
var _model_animator: AnimationPlayer = null
var _idle_anim: StringName = &""
var _walk_anim: StringName = &""
var _run_anim: StringName = &""
var _was_moving: bool = false

var _current_interactable: Dictionary = {}

func _ready() -> void:
	_create_hud()
	_audio = get_node_or_null("../AudioManager")
	_attach_character_model()

func _attach_character_model() -> void:
	var model_path := "res://characters/male3.glb"
	if not ResourceLoader.exists(model_path):
		push_warning("Player model missing: " + model_path)
		return
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_warning("Player model could not be imported as a scene: " + model_path)
		return
	_character_visual = packed.instantiate() as Node3D
	if _character_visual == null:
		push_warning("Player model root is not Node3D.")
		return
	_character_visual.name = "PlayerCharacterVisual"
	add_child(_character_visual)
	_play_idle_animation(_character_visual)

func _play_idle_animation(root: Node) -> void:
	if root is AnimationPlayer and _model_animator == null:
		_model_animator = root as AnimationPlayer
		for animation_name in _model_animator.get_animation_list():
			var lower_name := String(animation_name).to_lower()
			if _idle_anim == &"" and lower_name.contains("idle"):
				_idle_anim = StringName(animation_name)
			elif _walk_anim == &"" and (lower_name.contains("walk") or lower_name.contains("run")):
				_walk_anim = StringName(animation_name)
			if _run_anim == &"" and lower_name.contains("run"):
				_run_anim = StringName(animation_name)
	for child in root.get_children():
		_play_idle_animation(child)
	if root == _character_visual:
		_update_character_animation(false)

func _update_character_animation(moving: bool) -> void:
	if _model_animator == null:
		return
	var target: StringName = _idle_anim
	if moving:
		target = _run_anim if Input.is_key_pressed(KEY_SHIFT) and _run_anim != &"" else _walk_anim
	if target != &"" and _model_animator.current_animation != target:
		_model_animator.play(target)

func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD_Layer"
	add_child(canvas)

	# Top info HUD
	_hud_label = Label.new()
	_hud_label.position = Vector2(24, 20)
	_hud_label.add_theme_font_size_override("font_size", 16)
	_hud_label.add_theme_color_override("font_color", Color("74f4ff"))
	_hud_label.text = "[Shift] Sprint | [WASD] Walk | [Space] Jump | [E] Interact | [C] CCTV (1-9)"
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
		if node is Camera3D and node != camera:
			_cctv_cams.append(node)

func _unhandled_input(event: InputEvent) -> void:
	if is_frozen:
		return

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
		rotate_y(-event.relative.x * look_sensitivity)
		head.rotate_x(-event.relative.y * look_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -1.4, 1.4)

func _try_interact() -> void:
	if _current_interactable.is_empty():
		return
	var room_node := get_parent()
	if room_node != null and room_node.has_method("trigger_interaction"):
		var msg: String = room_node.trigger_interaction(_current_interactable)
		if not msg.is_empty():
			_show_banner(msg)

func _show_banner(msg: String) -> void:
	_banner_label.text = msg
	_banner_timer = 4.0

func _switch_to_cam(index: int) -> void:
	_cctv_index = index
	if _cctv_index == 0:
		camera.make_current()
		_hud_label.text = "[Shift] Sprint | [WASD] Walk | [Space] Jump | [E] Interact | [C] CCTV (1-9)"
		_hud_label.add_theme_color_override("font_color", Color("74f4ff"))
		_interact_label.visible = true
	else:
		if _cctv_index - 1 < _cctv_cams.size():
			var target_cam: Camera3D = _cctv_cams[_cctv_index - 1]
			target_cam.make_current()
			_hud_label.add_theme_color_override("font_color", Color("ff3355"))
			_interact_label.visible = false

func _physics_process(delta: float) -> void:
	_rec_time += delta

	# Banner timer
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner_label.text = ""

	# Check interactables
	if _cctv_index == 0 and not is_frozen:
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

	# CCTV HUD
	if _cctv_index > 0 and _cctv_index - 1 < _cctv_cams.size():
		var rec_blink := "● REC" if fmod(_rec_time, 1.0) < 0.6 else "○ REC"
		var cam_name := _cctv_cams[_cctv_index - 1].name
		_hud_label.text = rec_blink + " " + cam_name + " [SURVEILLANCE FEED LIVE]\n[C / 1-9] Next Camera | [0 / Click / WASD] Return to Player"

	# Auto return from CCTV on movement input
	if _cctv_index != 0:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D):
			_switch_to_cam(0)
			return
		return # Don't move player while viewing CCTV feeds

	# If frozen by narrative events, only apply gravity
	if is_frozen:
		velocity.x = lerp(velocity.x, 0.0, delta * 14.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 14.0)
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
	var moving_now := Vector2(velocity.x, velocity.z).length() > 0.8 and is_on_floor()
	if moving_now and not _was_moving and _audio != null and _audio.has_method("play_footstep"):
		_audio.play_footstep()
	_was_moving = moving_now
	_update_character_animation(moving_now)
		return

	# --- SOLID WALKING PHYSICS (NO FLYING) ---
	# Gravity: only fall when not on floor
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Jump only when on solid floor
		if Input.is_key_pressed(KEY_SPACE) and _current_interactable.is_empty():
			velocity.y = jump_velocity

	# Input movement
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0

	input_dir = input_dir.normalized()
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Walk vs Sprint
	var current_speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed

	if direction.length_squared() > 0.0:
		velocity.x = lerp(velocity.x, direction.x * current_speed, delta * 12.0)
		velocity.z = lerp(velocity.z, direction.z * current_speed, delta * 12.0)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 14.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 14.0)

	move_and_slide()
