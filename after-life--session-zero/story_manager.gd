extends Node
## WARRIOR'S FURY: THE FINAL LEVEL - STORY DIRECTOR
## Orchestrates Act I, Act II, Act III, Act IV, and Post-Credits Scene.

enum Act {
	ACT1_CAFE_NIGHT,      # 11:47 PM - Afterlife Cafe, Terminal 07, Unknown Player Chat
	ACT2_SIMULATION,      # 2189 Neo-Eden - Glitched Dystopia, Nexus Core Confrontation
	ACT3_AWAKENING,       # 6:13 AM - Wake up at Terminal 07, 6 hours played
	ACT4_VANISHING_CAFE,  # Next Afternoon - Cafe is gone, vacant unit, receipt & phone call
	POST_CREDITS          # Terminal boots Session 002
}

var current_act: Act = Act.ACT1_CAFE_NIGHT

@onready var room_root: Node3D = get_parent()
var player: CharacterBody3D = null

# Story UI elements
var canvas_layer: CanvasLayer = null
var dialog_box: Panel = null
var dialog_speaker: Label = null
var dialog_text: Label = null
var dialog_prompt: Label = null

var flash_overlay: ColorRect = null
var receipt_panel: Panel = null
var receipt_front: Label = null
var receipt_back: Label = null
var receipt_is_flipped: bool = false

var phone_overlay: Panel = null
var blue_eye_overlay: Panel = null
var post_credits_overlay: Panel = null

var active_dialog_queue: Array[Dictionary] = []
var active_dialog_callback: Callable

var terminal07_screen: Panel = null
var terminal07_chat_step: int = 0
var _exit_triggered: bool = false
var _nexus_confronted: bool = false
var phone_step: int = 0

func _ready() -> void:
	_setup_ui()
	call_deferred("_init_story")

func _init_story() -> void:
	player = room_root.get_node_or_null("Player")
	print("STORY MANAGER INITIALIZED. Player: %s" % str(player))
	# Wire proximity trigger zones
	_wire_trigger_zone("TriggerZone_Terminal07", "_on_zone_terminal07_entered")
	_wire_trigger_zone("TriggerZone_NexusStage", "_on_zone_nexus_entered")
	_wire_trigger_zone("TriggerZone_ExitCafe", "_on_zone_exit_entered")
	set_act(Act.ACT1_CAFE_NIGHT)

func _wire_trigger_zone(zone_name: String, callback: String) -> void:
	var zone := room_root.get_node_or_null(zone_name)
	if zone == null:
		return
	var cb := Callable(self, callback)
	if zone.body_entered.is_connected(cb):
		return
	zone.body_entered.connect(cb)

func _on_zone_terminal07_entered(body: Node3D) -> void:
	if body == player and current_act == Act.ACT1_CAFE_NIGHT:
		if not terminal07_screen.visible:
			call_deferred("launch_terminal07")

func _on_zone_nexus_entered(body: Node3D) -> void:
	if body == player and current_act == Act.ACT2_SIMULATION and not _nexus_confronted:
		_nexus_confronted = true
		call_deferred("on_nexus_stage_confrontation")

func _on_zone_exit_entered(body: Node3D) -> void:
	if body == player and current_act == Act.ACT3_AWAKENING and not _exit_triggered:
		_exit_triggered = true
		call_deferred("on_player_exited_cafe_act3")

func _setup_ui() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "StoryUI"
	add_child(canvas_layer)

	# Fullscreen flash / fade overlay
	flash_overlay = ColorRect.new()
	flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_overlay.color = Color(1, 1, 1, 0)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(flash_overlay)

	# Dialogue Box (Bottom of screen)
	dialog_box = Panel.new()
	dialog_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_box.offset_top = -180
	dialog_box.offset_bottom = -20
	dialog_box.offset_left = 60
	dialog_box.offset_right = -60
	dialog_box.visible = false
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(0.04, 0.06, 0.1, 0.94)
	style_box.border_color = Color("42eaff")
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(8)
	dialog_box.add_theme_stylebox_override("panel", style_box)
	canvas_layer.add_child(dialog_box)

	dialog_speaker = Label.new()
	dialog_speaker.position = Vector2(24, 16)
	dialog_speaker.add_theme_font_size_override("font_size", 20)
	dialog_speaker.add_theme_color_override("font_color", Color("ff3eaa"))
	dialog_box.add_child(dialog_speaker)

	dialog_text = Label.new()
	dialog_text.position = Vector2(24, 48)
	dialog_text.size = Vector2(800, 80)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.add_theme_font_size_override("font_size", 18)
	dialog_text.add_theme_color_override("font_color", Color("e8f5ff"))
	dialog_box.add_child(dialog_text)

	dialog_prompt = Label.new()
	dialog_prompt.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	dialog_prompt.offset_left = -220
	dialog_prompt.offset_top = -32
	dialog_prompt.offset_right = -20
	dialog_prompt.add_theme_font_size_override("font_size", 14)
	dialog_prompt.add_theme_color_override("font_color", Color("74f4ff"))
	dialog_prompt.text = "[E / CLICK] CONTINUE ▶"
	dialog_box.add_child(dialog_prompt)

	# Interactive Terminal 07 CRT Screen Popup
	_setup_terminal07_ui()

	# Physical Receipt Inspection Modal
	_setup_receipt_ui()

	# Incoming Phone Call Modal
	_setup_phone_ui()

	# Post-Credits UI
	_setup_post_credits_ui()

func _setup_terminal07_ui() -> void:
	terminal07_screen = Panel.new()
	terminal07_screen.set_anchors_preset(Control.PRESET_CENTER)
	terminal07_screen.size = Vector2(760, 520)
	terminal07_screen.position = Vector2(-380, -260)
	terminal07_screen.visible = false
	var term_style := StyleBoxFlat.new()
	term_style.bg_color = Color(0.02, 0.04, 0.08, 0.96)
	term_style.border_color = Color("42eaff")
	term_style.set_border_width_all(3)
	term_style.set_corner_radius_all(10)
	terminal07_screen.add_theme_stylebox_override("panel", term_style)
	canvas_layer.add_child(terminal07_screen)

	var term_header := Label.new()
	term_header.position = Vector2(24, 18)
	term_header.add_theme_font_size_override("font_size", 22)
	term_header.add_theme_color_override("font_color", Color("74f4ff"))
	term_header.text = "◈ WARRIOR'S FURY [v1.0.4] — TERMINAL #07 ◈"
	terminal07_screen.add_child(term_header)

	var term_body := Label.new()
	term_body.name = "BodyText"
	term_body.position = Vector2(24, 60)
	term_body.size = Vector2(710, 360)
	term_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	term_body.add_theme_font_size_override("font_size", 18)
	term_body.add_theme_color_override("font_color", Color("e0f0ff"))
	terminal07_screen.add_child(term_body)

	var btn_container := HBoxContainer.new()
	btn_container.name = "ButtonBox"
	btn_container.position = Vector2(24, 440)
	btn_container.size = Vector2(710, 50)
	terminal07_screen.add_child(btn_container)

	var btn_action := Button.new()
	btn_action.name = "BtnAction"
	btn_action.text = "REPLY: 'Who is this?'"
	btn_action.custom_minimum_size = Vector2(240, 45)
	btn_action.pressed.connect(_on_terminal07_advance)
	btn_container.add_child(btn_action)

func _setup_receipt_ui() -> void:
	receipt_panel = Panel.new()
	receipt_panel.set_anchors_preset(Control.PRESET_CENTER)
	receipt_panel.size = Vector2(420, 560)
	receipt_panel.position = Vector2(-210, -280)
	receipt_panel.visible = false
	var r_style := StyleBoxFlat.new()
	r_style.bg_color = Color("ece8db") # Aged paper color
	r_style.border_color = Color("928b7a")
	r_style.set_border_width_all(2)
	r_style.set_corner_radius_all(4)
	receipt_panel.add_theme_stylebox_override("panel", r_style)
	canvas_layer.add_child(receipt_panel)

	receipt_front = Label.new()
	receipt_front.name = "Front"
	receipt_front.position = Vector2(24, 30)
	receipt_front.size = Vector2(372, 440)
	receipt_front.add_theme_font_size_override("font_size", 16)
	receipt_front.add_theme_color_override("font_color", Color("1b1812"))
	receipt_front.text = """
========================================
       AFTERLIFE GAMING LOUNGE
       SECTOR 4 // METRO PLAZA
========================================
DATE: 2026-10-23         TIME: 11:47 PM
TERMINAL: 07
MEMBERSHIP: GUEST PASS
RATE: UNLIMITED ALL-NIGHT SESSION
----------------------------------------
ITEM: WARRIOR'S FURY ACCESS
STATUS: CONFIRMED
OPERATOR: NEXUS-01
----------------------------------------

PLAYER 07 — SESSION STATUS: INCOMPLETE

========================================
   "PLAY UNTIL REALITY DISSOLVES"
========================================
"""
	receipt_panel.add_child(receipt_front)

	receipt_back = Label.new()
	receipt_back.name = "Back"
	receipt_back.position = Vector2(24, 180)
	receipt_back.size = Vector2(372, 200)
	receipt_back.add_theme_font_size_override("font_size", 28)
	receipt_back.add_theme_color_override("font_color", Color("941a1a")) # Blood red ink
	receipt_back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	receipt_back.text = "\n\n\"YOU WOKE UP\nTOO EARLY.\""
	receipt_back.visible = false
	receipt_panel.add_child(receipt_back)

	var flip_btn := Button.new()
	flip_btn.text = "🔄 FLIP RECEIPT OVER [F]"
	flip_btn.position = Vector2(24, 500)
	flip_btn.size = Vector2(180, 40)
	flip_btn.pressed.connect(_toggle_receipt_flip)
	receipt_panel.add_child(flip_btn)

	var close_btn := Button.new()
	close_btn.text = "CLOSE [ESC]"
	close_btn.position = Vector2(220, 500)
	close_btn.size = Vector2(176, 40)
	close_btn.pressed.connect(func(): _close_receipt())
	receipt_panel.add_child(close_btn)

func _setup_phone_ui() -> void:
	phone_overlay = Panel.new()
	phone_overlay.set_anchors_preset(Control.PRESET_CENTER)
	phone_overlay.size = Vector2(360, 580)
	phone_overlay.position = Vector2(-180, -290)
	phone_overlay.visible = false
	var ph_style := StyleBoxFlat.new()
	ph_style.bg_color = Color(0.05, 0.06, 0.08, 0.98)
	ph_style.border_color = Color("ff2244")
	ph_style.set_border_width_all(3)
	ph_style.set_corner_radius_all(24)
	phone_overlay.add_theme_stylebox_override("panel", ph_style)
	canvas_layer.add_child(phone_overlay)

	var ph_icon := Label.new()
	ph_icon.position = Vector2(0, 50)
	ph_icon.size = Vector2(360, 60)
	ph_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ph_icon.add_theme_font_size_override("font_size", 44)
	ph_icon.text = "📞"
	phone_overlay.add_child(ph_icon)

	var ph_call_status := Label.new()
	ph_call_status.name = "CallStatus"
	ph_call_status.position = Vector2(20, 120)
	ph_call_status.size = Vector2(320, 30)
	ph_call_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ph_call_status.add_theme_font_size_override("font_size", 18)
	ph_call_status.add_theme_color_override("font_color", Color("ff4466"))
	ph_call_status.text = "INCOMING CALL..."
	phone_overlay.add_child(ph_call_status)

	var ph_caller := Label.new()
	ph_caller.name = "CallerName"
	ph_caller.position = Vector2(20, 155)
	ph_caller.size = Vector2(320, 35)
	ph_caller.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ph_caller.add_theme_font_size_override("font_size", 22)
	ph_caller.add_theme_color_override("font_color", Color("ffffff"))
	ph_caller.text = "UNKNOWN CALLER"
	phone_overlay.add_child(ph_caller)

	var ph_convo := Label.new()
	ph_convo.name = "ConvoText"
	ph_convo.position = Vector2(24, 210)
	ph_convo.size = Vector2(312, 250)
	ph_convo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ph_convo.add_theme_font_size_override("font_size", 16)
	ph_convo.add_theme_color_override("font_color", Color("a5c5e5"))
	phone_overlay.add_child(ph_convo)

	var ph_btn := Button.new()
	ph_btn.name = "AnswerBtn"
	ph_btn.text = "ANSWER [E]"
	ph_btn.position = Vector2(40, 490)
	ph_btn.size = Vector2(280, 50)
	ph_btn.pressed.connect(_on_phone_answer_pressed)
	phone_overlay.add_child(ph_btn)

	# Blue Eye Stinger Overlay
	blue_eye_overlay = Panel.new()
	blue_eye_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	blue_eye_overlay.visible = false
	var eye_style := StyleBoxFlat.new()
	eye_style.bg_color = Color(0.01, 0.01, 0.02, 1.0)
	blue_eye_overlay.add_theme_stylebox_override("panel", eye_style)
	canvas_layer.add_child(blue_eye_overlay)

	var eye_lbl := Label.new()
	eye_lbl.name = "EyeLabel"
	eye_lbl.set_anchors_preset(Control.PRESET_CENTER)
	eye_lbl.offset_left = -400
	eye_lbl.offset_top = -120
	eye_lbl.offset_right = 400
	eye_lbl.offset_bottom = 120
	eye_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eye_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eye_lbl.add_theme_font_size_override("font_size", 34)
	eye_lbl.add_theme_color_override("font_color", Color("00ddff"))
	eye_lbl.text = "◉          ◉\n\n[YOUR EYES ARE GLOWING BLUE]\n\nCUT TO BLACK."
	blue_eye_overlay.add_child(eye_lbl)

func _setup_post_credits_ui() -> void:
	post_credits_overlay = Panel.new()
	post_credits_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	post_credits_overlay.visible = false
	var pc_style := StyleBoxFlat.new()
	pc_style.bg_color = Color(0.01, 0.02, 0.04, 1.0)
	post_credits_overlay.add_theme_stylebox_override("panel", pc_style)
	canvas_layer.add_child(post_credits_overlay)

	var pc_content := Label.new()
	pc_content.name = "PCContent"
	pc_content.set_anchors_preset(Control.PRESET_CENTER)
	pc_content.offset_left = -420
	pc_content.offset_top = -180
	pc_content.offset_right = 420
	pc_content.offset_bottom = 180
	pc_content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pc_content.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pc_content.add_theme_font_size_override("font_size", 22)
	pc_content.add_theme_color_override("font_color", Color("00ff99"))
	pc_content.text = """
==================================================
           POST-CREDITS SCENE
==================================================

A dark room. A lonely monitor illuminates an empty chair.

WARRIOR'S FURY — SESSION 002

"SUBJECT IS BEGINNING TO QUESTION REALITY."
"PROCEED TO NEXT STAGE?"

The cursor moves by itself...
[ YES ]

STAGE COMPLETE.
THANK YOU FOR PLAYING 'AFTER LIFE: SESSION ZERO'.
"""
	post_credits_overlay.add_child(pc_content)

	var restart_btn := Button.new()
	restart_btn.text = "REPLAY STORY FROM ACT I"
	restart_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	restart_btn.offset_left = -160
	restart_btn.offset_top = -90
	restart_btn.offset_right = 160
	restart_btn.offset_bottom = -40
	restart_btn.pressed.connect(func():
		post_credits_overlay.visible = false
		set_act(Act.ACT1_CAFE_NIGHT)
	)
	post_credits_overlay.add_child(restart_btn)

# --- ACT MANAGEMENT ---
func set_act(new_act: Act) -> void:
	current_act = new_act
	if room_root != null and room_root.has_method("apply_story_act"):
		room_root.apply_story_act(current_act)

	match current_act:
		Act.ACT1_CAFE_NIGHT:
			_start_act_1()
		Act.ACT2_SIMULATION:
			_start_act_2()
		Act.ACT3_AWAKENING:
			_start_act_3()
		Act.ACT4_VANISHING_CAFE:
			_start_act_4()
		Act.POST_CREDITS:
			_start_post_credits()

# ==============================================================================
# --- ACT I: 11:47 PM - THE CAFE THAT SHOULDN'T EXIST ---
# ==============================================================================
func _start_act_1() -> void:
	if player:
		player.is_frozen = false
		player.global_position = Vector3(0, 0.05, 30.0)
	show_banner_story("ACT I: 11:47 PM — Find Terminal #07 inside Afterlife Gaming Lounge")
	call_deferred("_override_terminal07_for_act1")

func _override_terminal07_for_act1() -> void:
	if room_root != null and room_root.has_method("override_interactable_callback"):
		room_root.override_interactable_callback("Terminal #07", Callable(self, "launch_terminal07"))

func launch_terminal07() -> void:
	if player:
		player.is_frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	terminal07_screen.visible = true
	terminal07_chat_step = 0
	_update_terminal07_step()

func _update_terminal07_step() -> void:
	var body: Label = terminal07_screen.get_node("BodyText")
	var btn: Button = terminal07_screen.get_node("ButtonBox/BtnAction")

	match terminal07_chat_step:
		0:
			body.text = """[GAME READY: WARRIOR'S FURY - FINAL LEVEL]
Current Level: LEVEL 99 - CITADEL ASCENT
Player: GUEST_07

A direct message window opens in the corner of your screen:

UNKNOWN PLAYER: "Still trying to beat the final level?"
"""
			btn.text = "MC: 'Who is this?'"
		1:
			body.text += "\nMC: 'Who is this?'\n\nUNKNOWN PLAYER: 'Someone who's already beaten it.'"
			btn.text = "MC: 'Then tell me how.'"
		2:
			body.text += "\n\nMC: 'Then tell me how.'\n\nUNKNOWN PLAYER: 'Come back tomorrow. There's an event you won't want to miss.'"
			btn.text = "MC: 'What's the prize?'"
		3:
			body.text += "\n\nMC: 'What's the prize?'\n\nUNKNOWN PLAYER: 'Everything you've ever wanted.'\n\n[SCREEN GLITCHES MOMENTARILY...]\n>>> PLAYER 07 IDENTIFIED <<<"
			btn.text = "CONTINUE PLAYING..."
		4:
			body.text += "\n\n========================================\nWOULD YOU LIKE TO ENTER THE FINAL LEVEL?\n========================================"
			btn.text = "CLICK: [ YES ]"

func _on_terminal07_advance() -> void:
	terminal07_chat_step += 1
	if terminal07_chat_step <= 4:
		_update_terminal07_step()
	else:
		# Player clicked YES -> Trigger Flash Whiteout -> ACT II
		terminal07_screen.visible = false
		trigger_whiteout(func():
			set_act(Act.ACT2_SIMULATION)
		)

# ==============================================================================
# --- ACT II: NEO-EDEN 2189 - THE SIMULATION ---
# ==============================================================================
func _start_act_2() -> void:
	_nexus_confronted = false
	if player:
		player.is_frozen = false
		player.global_position = Vector3(0, 0.05, 0.0)
	show_dialog("NEXUS [AI CONSTRUCT]", "Welcome to Neo-Eden, Player 07. Clear the simulation stages to find your exit.", func():
		show_banner_story("ACT II: THE SIMULATION (2189) — Confront NEXUS Core on the Arena Stage")
	)

func on_nexus_stage_confrontation() -> void:
	if player:
		player.is_frozen = true
	show_dialog_sequence([
		{"speaker": "NEXUS [CORE]", "text": "You keep searching for the exit, Player 07."},
		{"speaker": "PROTAGONIST", "text": "Because this isn't real."},
		{"speaker": "NEXUS [CORE]", "text": "Then why are you afraid to die?"},
		{"speaker": "PROTAGONIST", "text": "Because it feels real."},
		{"speaker": "NEXUS [CORE]", "text": "Perhaps that is the only difference that matters."},
		{"speaker": "UNKNOWN STATIC", "text": "See you when you wake up..."}
	], func():
		trigger_whiteout(func():
			set_act(Act.ACT3_AWAKENING)
		)
	)

# ==============================================================================
# --- ACT III: 6:13 AM - THE AWAKENING ---
# ==============================================================================
func _start_act_3() -> void:
	_exit_triggered = false
	if player:
		player.is_frozen = false
		player.global_position = Vector3(-6.5, 0.05, 8.0) # Seated at Terminal 07
	show_dialog("PROTAGONIST", "*Gasps for air!* My hands are shaking... Was it just a vivid dream?!", func():
		show_banner_story("ACT III: 6:13 AM — Speak with the Receptionist at the counter")
	)
	call_deferred("_override_receptionist_for_act3")

func _override_receptionist_for_act3() -> void:
	if room_root != null and room_root.has_method("override_interactable_callback"):
		room_root.override_interactable_callback("OPERATOR", Callable(self, "talk_receptionist_act3"))
		room_root.override_interactable_callback("NEXUS-01", Callable(self, "talk_receptionist_act3"))

func talk_receptionist_act3() -> void:
	show_dialog_sequence([
		{"speaker": "PROTAGONIST", "text": "Hey... how long was I asleep?"},
		{"speaker": "RECEPTIONIST [NEXUS-01]", "text": "You weren't asleep. You've been playing Warrior's Fury for six hours straight."},
		{"speaker": "PROTAGONIST", "text": "Six hours?! It's 6:13 AM already... I should head home."},
		{"speaker": "TERMINAL SCREEN", "text": "[GLITCH: THANK YOU FOR PARTICIPATING, PLAYER 07]"}
	], func():
		show_banner_story("Walk out through the front doors to head home")
	)

func on_player_exited_cafe_act3() -> void:
	if player:
		player.is_frozen = true
	trigger_fade_black(func():
		set_act(Act.ACT4_VANISHING_CAFE)
	)

# ==============================================================================
# --- ACT IV: THE CAFÉ THAT NEVER EXISTED (NEXT AFTERNOON) ---
# ==============================================================================
func _start_act_4() -> void:
	if player:
		player.is_frozen = false
		player.global_position = Vector3(0, 0.05, 32.0)
	show_dialog("PROTAGONIST", "Wait... what happened to the cafe?! Where are the neon signs?! The doors?!", func():
		show_banner_story("ACT IV: Ask Chef Hiro at the Street Cart what happened to Afterlife")
	)
	call_deferred("_override_shopkeeper_for_act4")

func _override_shopkeeper_for_act4() -> void:
	if room_root != null and room_root.has_method("override_interactable_callback"):
		room_root.override_interactable_callback("RAMEN", Callable(self, "talk_shopkeeper_act4"))
		room_root.override_interactable_callback("HIRO", Callable(self, "talk_shopkeeper_act4"))

func talk_shopkeeper_act4() -> void:
	show_dialog_sequence([
		{"speaker": "PROTAGONIST", "text": "Excuse me! What happened to the gaming café right here? AFTERLIFE?"},
		{"speaker": "CHEF HIRO", "text": "Gaming café? Son, that commercial unit has been empty and abandoned for years."},
		{"speaker": "PROTAGONIST", "text": "No! I was literally here this morning! Playing at Terminal 07!"},
		{"speaker": "CHEF HIRO", "text": "You've got the wrong place. Nobody has set foot in that building in a decade."},
		{"speaker": "PROTAGONIST", "text": "Wait... my pocket. The paper receipt from last night!"}
	], func():
		show_receipt()
	)

func show_receipt() -> void:
	if player:
		player.is_frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	receipt_panel.visible = true
	receipt_front.visible = true
	receipt_back.visible = false
	receipt_is_flipped = false

func _toggle_receipt_flip() -> void:
	receipt_is_flipped = !receipt_is_flipped
	receipt_front.visible = !receipt_is_flipped
	receipt_back.visible = receipt_is_flipped

func _close_receipt() -> void:
	receipt_panel.visible = false
	call_deferred("_trigger_phone_call")

func _trigger_phone_call() -> void:
	phone_step = 0
	if player:
		player.is_frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	phone_overlay.visible = true
	var status: Label = phone_overlay.get_node("CallStatus")
	var btn: Button = phone_overlay.get_node("AnswerBtn")
	var convo: Label = phone_overlay.get_node("ConvoText")
	status.text = "INCOMING CALL..."
	btn.text = "ANSWER [E]"
	convo.text = ""

func _on_phone_answer_pressed() -> void:
	var status: Label = phone_overlay.get_node("CallStatus")
	var btn: Button = phone_overlay.get_node("AnswerBtn")
	var convo: Label = phone_overlay.get_node("ConvoText")

	phone_step += 1
	match phone_step:
		1:
			status.text = "CALL CONNECTED [00:03]"
			convo.text = "UNKNOWN: 'Did you enjoy the game?'"
			btn.text = "MC: 'Who are you? What happened to the café?!'"
		2:
			convo.text += "\n\nMC: 'Who are you?! What happened to that place?'\n\nUNKNOWN: 'What place?'"
			btn.text = "MC: 'The Afterlife Gaming Café!'"
		3:
			convo.text += "\n\nMC: 'The café!'\n\nUNKNOWN: 'There was never a café.'"
			btn.text = "CONTINUE LISTENING..."
		4:
			convo.text += "\n\nUNKNOWN: 'Now get some sleep. Your next session begins tonight.'"
			btn.text = "HANG UP"
		5:
			# Phone screen goes black -> Glowing blue eyes reflection
			phone_overlay.visible = false
			blue_eye_overlay.visible = true
			await get_tree().create_timer(4.5).timeout
			blue_eye_overlay.visible = false
			set_act(Act.POST_CREDITS)

# ==============================================================================
# --- POST CREDITS SCENE ---
# ==============================================================================
func _start_post_credits() -> void:
	if player:
		player.is_frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	post_credits_overlay.visible = true

# ==============================================================================
# --- DIALOG & CINEMATIC HELPERS ---
# ==============================================================================
func show_dialog(speaker: String, text: String, on_done: Callable = Callable()) -> void:
	show_dialog_sequence([{"speaker": speaker, "text": text}], on_done)

func show_dialog_sequence(lines: Array[Dictionary], on_done: Callable = Callable()) -> void:
	active_dialog_queue = lines.duplicate()
	active_dialog_callback = on_done
	dialog_box.visible = true
	if player:
		player.is_frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_advance_dialog()

func _advance_dialog() -> void:
	if active_dialog_queue.is_empty():
		dialog_box.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if player:
			player.is_frozen = false
		if active_dialog_callback.is_valid():
			active_dialog_callback.call()
		return

	var current: Dictionary = active_dialog_queue.pop_front()
	dialog_speaker.text = str(current.get("speaker", ""))
	dialog_text.text = str(current.get("text", ""))

func _unhandled_input(event: InputEvent) -> void:
	if dialog_box.visible:
		if (event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			get_viewport().set_input_as_handled()
			_advance_dialog()
	elif terminal07_screen.visible:
		if event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			get_viewport().set_input_as_handled()
			_on_terminal07_advance()
	elif receipt_panel.visible:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_F or event.keycode == KEY_SPACE:
				get_viewport().set_input_as_handled()
				_toggle_receipt_flip()
			elif event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
				get_viewport().set_input_as_handled()
				_close_receipt()
	elif phone_overlay.visible:
		if event is InputEventKey and event.pressed and (event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
			get_viewport().set_input_as_handled()
			_on_phone_answer_pressed()

func show_banner_story(msg: String) -> void:
	if player != null and player.has_method("_show_banner"):
		player._show_banner(msg)

func trigger_whiteout(callback: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 1), 0.6)
	tween.tween_interval(0.4)
	tween.tween_callback(callback)
	tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 0), 1.2)

func trigger_fade_black(callback: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(flash_overlay, "color", Color(0, 0, 0, 1), 0.8)
	tween.tween_interval(0.5)
	tween.tween_callback(callback)
	tween.tween_property(flash_overlay, "color", Color(0, 0, 0, 0), 1.0)
