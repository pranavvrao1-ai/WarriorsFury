@tool
extends Node3D
## AFTER LIFE: SESSION ZERO - MEGA CYBER GAMING CAFE & LIVELY CITY PLAZA
## Cafe Interior: 40 x 40 m (X/Z: -20 to 20, Wall Height: 7.5 m)
## Exterior City: Extends 20+ meters on all sides (X/Z: -42 to 42, Total: 85 x 85 m)

const HALF := 20.0
const WALL_H := 7.5
const CITY_HALF := 42.0

var mats: Dictionary = {}

var left_door: Node3D = null
var right_door: Node3D = null
var door_progress: float = 0.0

var robot_root: Node3D = null
var robot_head: Node3D = null
var robot_base_y: float = 0.0
var robot_time: float = 0.0

var scanning_cams: Array[Dictionary] = []
var cam_time: float = 0.0

var interactables: Array[Dictionary] = []

var _cafe_interior_nodes: Array = []
var _city_exterior_nodes: Array = []
var _interior_lights: Array = []
var _exterior_lights: Array = []
var _needen_nodes: Array = []
var _act4_nodes: Array = []
var _acts_initialized: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		for child in get_children():
			if child.name != "Floor" and child.name != "Player" and child.name != "Camera3D" and not child.name.begins_with("TriggerZone") and not child.name.begins_with("StoryManager"):
				child.queue_free()
	interactables.clear()
	_cafe_interior_nodes.clear()
	_city_exterior_nodes.clear()
	_interior_lights.clear()
	_exterior_lights.clear()
	_needen_nodes.clear()
	_act4_nodes.clear()

	_make_materials()

	# 1. Interior Cafe
	var pre_interior: Array = get_children()
	_make_room()
	_make_roof()
	_make_air_conditioning()
	_make_doors()
	_make_counter()
	_make_robot()
	_attach_robot_asset()
	_make_esports_stage()
	_make_arcade_alley()
	_make_vending_zone()
	_make_cyber_bar()
	_make_vr_pods()
	_make_gaming_rows()
	_make_sign()
	_make_asset_characters()
	for child in get_children():
		if not pre_interior.has(child):
			_cafe_interior_nodes.append(child)

	# 2. Exterior City
	var pre_exterior: Array = get_children()
	_make_exterior_city()
	for child in get_children():
		if not pre_exterior.has(child):
			_city_exterior_nodes.append(child)

	# 3. Surveillance & Lighting
	var pre_cams_lights: Array = get_children()
	_make_security_cameras()
	_make_lighting()
	for child in get_children():
		if not pre_cams_lights.has(child):
			if child is OmniLight3D:
				if (child as OmniLight3D).position.z < HALF:
					_interior_lights.append(child)
				else:
					_exterior_lights.append(child)
			else:
				if child is Node3D and (child as Node3D).position.z < HALF:
					_cafe_interior_nodes.append(child)
				else:
					_city_exterior_nodes.append(child)

	# 4. Hidden Act Environments & Terminal 07 Marker
	_build_needen_environment()
	_build_act4_environment()
	_mark_terminal07()
	_acts_initialized = true
	print("AFTERLIFE ROOM READY! Interior: %d, Exterior: %d, Int Lights: %d, Ext Lights: %d" % [
		_cafe_interior_nodes.size(),
		_city_exterior_nodes.size(),
		_interior_lights.size(),
		_exterior_lights.size()
	])

func _process(delta: float) -> void:
	_animate_doors(delta)
	_animate_robot(delta)
	_animate_security_cameras(delta)

func _animate_doors(delta: float) -> void:
	if left_door == null or right_door == null or not left_door.visible:
		return
	var target_open := 0.0
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		var cam_pos := cam.global_position
		# Proximity check to front entrance at Z = HALF (20.0)
		var dist_to_door := Vector2(cam_pos.x, cam_pos.z - HALF).length()
		if dist_to_door < 7.0:
			target_open = 1.0
	door_progress = lerp(door_progress, target_open, delta * 3.5)
	left_door.position.x = lerp(-2.25, -7.2, door_progress)
	right_door.position.x = lerp(2.25, 7.2, door_progress)

func _animate_robot(delta: float) -> void:
	if robot_root == null or robot_head == null or not robot_root.visible:
		return
	robot_time += delta
	robot_root.position.y = robot_base_y + sin(robot_time * 2.2) * 0.06
	robot_head.rotation.z = sin(robot_time * 1.6) * 0.04
	robot_head.rotation.x = sin(robot_time * 2.0) * 0.03
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		var dir := cam.global_position - robot_root.global_position
		dir.y = 0.0
		if dir.length() > 0.5 and dir.length() < 18.0:
			var target_rot_y := atan2(dir.x, dir.z)
			robot_head.rotation.y = lerp_angle(robot_head.rotation.y, target_rot_y, delta * 2.5)

func _animate_security_cameras(delta: float) -> void:
	cam_time += delta
	for cam_data in scanning_cams:
		var head: Node3D = cam_data.head
		var phase: float = cam_data.phase
		var speed: float = cam_data.speed
		head.rotation.y = cam_data.base_rot_y + sin(cam_time * speed + phase) * 0.35
		head.rotation.x = sin(cam_time * (speed * 0.7) + phase) * 0.06

# --- INTERACTION API ---
func register_interactable(pos: Vector3, radius: float, prompt: String, feedback_lines: Array) -> void:
	interactables.append({
		"pos": pos,
		"radius": radius,
		"prompt": prompt,
		"feedback": feedback_lines,
		"index": 0
	})

func get_nearest_interactable(player_pos: Vector3) -> Dictionary:
	var best_dist := 999999.0
	var best_item := {}
	for item in interactables:
		var d: float = player_pos.distance_to(item.pos)
		if d <= item.radius and d < best_dist:
			best_dist = d
			best_item = item
	return best_item

func trigger_interaction(item: Dictionary) -> String:
	# If a story callback override is present, call it instead of cycling feedback lines
	if item.has("callback"):
		var cb: Callable = item["callback"]
		if cb.is_valid():
			cb.call()
			return ""
	var lines: Array = item.feedback
	var idx: int = item.index
	var res: String = lines[idx % lines.size()]
	item.index = (idx + 1) % lines.size()
	return res

# --- MATERIALS ---
func _make_materials() -> void:
	mats.dark = _mat(Color("0c0f18"), 0.85)
	mats.wall = _mat(Color("181d2a"), 0.8)
	mats.trim = _mat(Color("2a3445"), 0.5)
	mats.metal = _mat(Color("2c3644"), 0.3, 0.7)
	mats.black = _mat(Color("06080e"), 0.3, 0.4)
	mats.cyan = _mat(Color("42eaff"), 0.2, 0.1, Color("1acfea"))
	mats.pink = _mat(Color("ff3eaa"), 0.2, 0.1, Color("ed1687"))
	mats.purple = _mat(Color("9b55ff"), 0.2, 0.1, Color("7838ee"))
	mats.amber = _mat(Color("ffaa33"), 0.25, 0.1, Color("e08811"))
	mats.green = _mat(Color("33ff88"), 0.2, 0.1, Color("11cc55"))
	mats.screen = _mat(Color("1c658f"), 0.15, 0.05, Color("0f4e73"))
	mats.screen_bright = _mat(Color("2da8e0"), 0.1, 0.05, Color("1ea5e0"))
	mats.wood = _mat(Color("3d2e27"), 0.75)
	mats.rug = _mat(Color("131722"), 1.0)
	mats.glass = _mat(Color(0.06, 0.12, 0.18, 0.75), 0.1, 0.2, Color("154261") * 0.4)
	mats.chrome = _mat(Color("d2dde8"), 0.1, 0.95)
	mats.red = _mat(Color("ff2233"), 0.2, 0.1, Color("ff0022") * 1.8)
	mats.gold = _mat(Color("ffd043"), 0.2, 0.8, Color("c99818"))
	# City Materials
	mats.asphalt = _mat(Color("101217"), 0.92, 0.05)
	mats.sidewalk = _mat(Color("1b202c"), 0.85, 0.15)
	mats.curb = _mat(Color("323d4f"), 0.5, 0.5)
	mats.road_stripe = _mat(Color("ffe044"), 0.3, 0.1, Color("dca500") * 1.2)
	mats.window_glow = _mat(Color("142f48"), 0.2, 0.1, Color("102b44") * 1.5)
	mats.lantern = _mat(Color("ff3322"), 0.3, 0.1, Color("ff1100") * 2.2)

func _mat(color: Color, roughness := 0.7, metallic := 0.0, emission := Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 2.0
	return material

func _box(parent: Node3D, label: String, size: Vector3, pos: Vector3, material: Material, with_collision: bool = false) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

	if with_collision:
		var sb := StaticBody3D.new()
		sb.name = label + "_Collision"
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		sb.add_child(col)
		sb.position = pos
		parent.add_child(sb)

	return mesh_instance

# --- 40x40 INTERIOR CAFE ROOM ---
func _make_room() -> void:
	# Perimeter walls of the Cafe building with solid collisions
	_box(self, "Back wall", Vector3(40, WALL_H, 0.4), Vector3(0, WALL_H / 2, -HALF), mats.wall, true)
	_box(self, "Left wall", Vector3(0.4, WALL_H, 40), Vector3(-HALF, WALL_H / 2, 0), mats.wall, true)
	_box(self, "Right wall", Vector3(0.4, WALL_H, 40), Vector3(HALF, WALL_H / 2, 0), mats.wall, true)

	# Front entrance wall (opening from X = -4.5 to +4.5)
	_box(self, "Front left wall", Vector3(15.5, WALL_H, 0.4), Vector3(-12.25, WALL_H / 2, HALF), mats.wall, true)
	_box(self, "Front right wall", Vector3(15.5, WALL_H, 0.4), Vector3(12.25, WALL_H / 2, HALF), mats.wall, true)
	_box(self, "Front lintel", Vector3(9.0, 1.8, 0.4), Vector3(0, WALL_H - 0.9, HALF), mats.wall, true)

	# Interior floor neon baseboards
	_box(self, "Back neon strip", Vector3(38.0, 0.1, 0.1), Vector3(0, 0.15, -HALF + 0.3), mats.cyan)
	_box(self, "Left neon strip", Vector3(0.1, 0.1, 38.0), Vector3(-HALF + 0.3, 0.15, 0), mats.pink)
	_box(self, "Right neon strip", Vector3(0.1, 0.1, 38.0), Vector3(HALF - 0.3, 0.15, 0), mats.cyan)

	# Interior carpet zones
	_box(self, "Gaming arena rug", Vector3(26.0, 0.02, 22.0), Vector3(0, 0.02, 2.0), mats.rug)
	_box(self, "Lobby welcome rug", Vector3(14.0, 0.02, 8.0), Vector3(0, 0.02, 14.5), mats.rug)
	_box(self, "Arcade alley runner", Vector3(5.0, 0.02, 22.0), Vector3(-17.0, 0.02, 2.0), mats.rug)

# --- ROOF & CEILING ---
func _make_roof() -> void:
	_box(self, "Ceiling slab", Vector3(40, 0.4, 40), Vector3(0, WALL_H + 0.2, 0), mats.wall)

	for z in [-14.0, -7.0, 0.0, 7.0, 14.0]:
		_box(self, "Roof girder Z " + str(z), Vector3(40, 0.35, 0.5), Vector3(0, WALL_H - 0.18, z), mats.metal)
	for x in [-14.0, 0.0, 14.0]:
		_box(self, "Roof girder X " + str(x), Vector3(0.5, 0.35, 40), Vector3(x, WALL_H - 0.18, 0), mats.metal)

	_box(self, "Roof neon cyan L", Vector3(0.14, 0.08, 37.0), Vector3(-8.0, WALL_H - 0.04, 0), mats.cyan)
	_box(self, "Roof neon cyan R", Vector3(0.14, 0.08, 37.0), Vector3(8.0, WALL_H - 0.04, 0), mats.cyan)
	_box(self, "Roof neon pink L", Vector3(0.14, 0.08, 34.0), Vector3(-3.5, WALL_H - 0.04, 0), mats.pink)
	_box(self, "Roof neon pink R", Vector3(0.14, 0.08, 34.0), Vector3(3.5, WALL_H - 0.04, 0), mats.pink)

	for z in [-6.0, 6.0]:
		_box(self, "Skylight glow " + str(z), Vector3(10.0, 0.04, 6.0), Vector3(0, WALL_H - 0.02, z), mats.purple)
		_box(self, "Skylight frame " + str(z), Vector3(10.4, 0.14, 6.4), Vector3(0, WALL_H - 0.07, z), mats.black)

# --- AIR CONDITIONING & VENTILATION ---
func _make_air_conditioning() -> void:
	_box(self, "AC duct L", Vector3(1.1, 0.7, 37.0), Vector3(-16.0, WALL_H - 0.6, 0), mats.metal)
	_box(self, "AC duct R", Vector3(1.1, 0.7, 37.0), Vector3(16.0, WALL_H - 0.6, 0), mats.metal)

	for z in [-15.0, -9.0, -3.0, 3.0, 9.0, 15.0]:
		_box(self, "AC bracket L " + str(z), Vector3(1.25, 0.2, 0.25), Vector3(-16.0, WALL_H - 0.2, z), mats.black)
		_box(self, "AC bracket R " + str(z), Vector3(1.25, 0.2, 0.25), Vector3(16.0, WALL_H - 0.2, z), mats.black)

	for z in [-10.0, -2.0, 6.0, 14.0]:
		_box(self, "AC vent duct L " + str(z), Vector3(0.5, 0.4, 0.5), Vector3(-16.0, WALL_H - 1.1, z), mats.black)
		_box(self, "AC vent grill L " + str(z), Vector3(0.46, 0.04, 0.46), Vector3(-16.0, WALL_H - 1.3, z), mats.cyan)
		_box(self, "AC vent duct R " + str(z), Vector3(0.5, 0.4, 0.5), Vector3(16.0, WALL_H - 1.1, z), mats.black)
		_box(self, "AC vent grill R " + str(z), Vector3(0.46, 0.04, 0.46), Vector3(16.0, WALL_H - 1.3, z), mats.cyan)

	_box(self, "AC wall unit", Vector3(4.0, 0.9, 0.6), Vector3(-19.2, 4.5, -12.0), mats.dark)
	_box(self, "AC wall unit face", Vector3(3.8, 0.75, 0.08), Vector3(-19.2, 4.5, -11.68), mats.metal)
	_box(self, "AC vent slit", Vector3(3.5, 0.08, 0.04), Vector3(-19.2, 4.2, -11.64), mats.cyan)

	var ac_lbl := Label3D.new()
	ac_lbl.text = "19°C  •  PURIFY AUTO  •  FLOW MAX"
	ac_lbl.font_size = 32
	ac_lbl.pixel_size = 0.008
	ac_lbl.modulate = Color("42eaff")
	ac_lbl.position = Vector3(-19.2, 4.65, -11.62)
	add_child(ac_lbl)

# --- SLIDING DOUBLE DOORS ---
func _make_doors() -> void:
	_box(self, "Door top track", Vector3(10.0, 0.4, 0.6), Vector3(0, 5.7, HALF), mats.metal)
	_box(self, "Door track neon", Vector3(9.4, 0.08, 0.08), Vector3(0, 5.5, HALF + 0.25), mats.cyan)

	left_door = Node3D.new()
	left_door.name = "Left sliding door"
	left_door.position = Vector3(-2.25, 0, HALF)
	add_child(left_door)

	_box(left_door, "Left door panel", Vector3(4.5, 5.5, 0.15), Vector3(0, 2.75, 0), mats.dark, true)
	_box(left_door, "Left door glass", Vector3(1.4, 3.8, 0.18), Vector3(0.6, 3.0, 0), mats.glass)
	_box(left_door, "Left door edge neon", Vector3(0.1, 5.5, 0.18), Vector3(2.2, 2.75, 0), mats.cyan)
	_box(left_door, "Left door handle", Vector3(0.12, 1.4, 0.25), Vector3(2.0, 2.1, 0), mats.chrome)

	right_door = Node3D.new()
	right_door.name = "Right sliding door"
	right_door.position = Vector3(2.25, 0, HALF)
	add_child(right_door)

	_box(right_door, "Right door panel", Vector3(4.5, 5.5, 0.15), Vector3(0, 2.75, 0), mats.dark, true)
	_box(right_door, "Right door glass", Vector3(1.4, 3.8, 0.18), Vector3(-0.6, 3.0, 0), mats.glass)
	_box(right_door, "Right door edge neon", Vector3(0.1, 5.5, 0.18), Vector3(-2.2, 2.75, 0), mats.pink)
	_box(right_door, "Right door handle", Vector3(0.12, 1.4, 0.25), Vector3(-2.0, 2.1, 0), mats.chrome)

# --- RECEPTION & ROBOT OPERATOR ---
func _make_counter() -> void:
	_box(self, "Reception counter", Vector3(10.0, 1.2, 1.4), Vector3(0, 0.6, -16.0), mats.wood, true)
	_box(self, "Counter front glow", Vector3(9.6, 0.1, 0.08), Vector3(0, 0.65, -15.28), mats.pink)
	_box(self, "Counter top", Vector3(10.4, 0.16, 1.6), Vector3(0, 1.25, -16.0), mats.metal)

	for x in [-3.2, 3.2]:
		_box(self, "Terminal base " + str(x), Vector3(0.7, 0.12, 0.45), Vector3(x, 1.4, -15.9), mats.black)
		_box(self, "Terminal screen " + str(x), Vector3(0.65, 0.5, 0.08), Vector3(x, 1.7, -16.05), mats.screen)
	_box(self, "Counter card reader", Vector3(0.35, 0.15, 0.35), Vector3(-1.4, 1.4, -15.6), mats.black)

func _attach_robot_asset() -> void:
	if robot_root == null:
		return
	var model_path := "res://robot/robot_police_unit_animated.glb"
	if not ResourceLoader.exists(model_path):
		push_warning("Robot character asset missing: " + model_path)
		return
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_warning("Robot asset could not be imported as a scene: " + model_path)
		return
	for child in robot_root.get_children():
		if child is MeshInstance3D or child == robot_head:
			child.visible = false
	var model := packed.instantiate() as Node3D
	if model == null:
		return
	model.name = "Imported animated robot"
	model.scale = Vector3.ONE
	robot_root.add_child(model)
	_play_first_character_animation(model)
	var tag := Label3D.new()
	tag.text = "OPERATOR [NEXUS-01]"
	tag.font_size = 28
	tag.pixel_size = 0.008
	tag.modulate = Color("62f4ff")
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.5, 0)
	model.add_child(tag)

func _make_asset_characters() -> void:
	_spawn_character_asset("res://characters/male1.glb", "Cafe guest A", Vector3(-10.0, 0.0, -5.0))
	_spawn_character_asset("res://characters/female4.glb", "Cafe guest B", Vector3(-6.0, 0.0, -5.0))
	_spawn_character_asset("res://characters/male4.glb", "Cafe guest C", Vector3(9.0, 0.0, -5.0))

func _spawn_character_asset(path: String, node_name: String, spawn_position: Vector3) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Character asset missing: " + path)
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Character asset could not be imported as a scene: " + path)
		return
	var character := packed.instantiate() as Node3D
	if character == null:
		return
	character.name = node_name
	character.position = spawn_position
	add_child(character)
	_play_first_character_animation(character)

func _play_first_character_animation(root: Node) -> void:
	if root is AnimationPlayer:
		var animator := root as AnimationPlayer
		var animations := animator.get_animation_list()
		for animation_name in animations:
			var lower_name := String(animation_name).to_lower()
			if lower_name.contains("idle"):
				animator.play(animation_name)
				return
		if not animations.is_empty():
			animator.play(animations[0])
			return
	for child in root.get_children():
		_play_first_character_animation(child)

func _make_robot() -> void:
	robot_root = Node3D.new()
	robot_root.name = "Robot operator"
	robot_root.position = Vector3(0, 0, -17.2)
	robot_base_y = 0.0
	add_child(robot_root)

	_box(robot_root, "Hover base", Vector3(0.9, 0.2, 0.9), Vector3(0, 0.35, 0), mats.dark)
	_box(robot_root, "Hover ring glow", Vector3(0.76, 0.06, 0.76), Vector3(0, 0.25, 0), mats.cyan)
	_add_point_light_to(robot_root, Vector3(0, 0.2, 0), Color("24dfff"), 1.3, 3.0)

	_box(robot_root, "Lower chassis", Vector3(0.52, 0.38, 0.45), Vector3(0, 0.62, 0), mats.metal)
	_box(robot_root, "Spine column", Vector3(0.26, 0.55, 0.26), Vector3(0, 1.0, 0), mats.metal)
	_box(robot_root, "Chest armor", Vector3(0.88, 0.78, 0.56), Vector3(0, 1.55, 0), mats.dark)
	_box(robot_root, "Chest reactor core", Vector3(0.3, 0.3, 0.08), Vector3(0, 1.6, 0.29), mats.cyan)
	_box(robot_root, "Shoulder L", Vector3(0.3, 0.3, 0.35), Vector3(-0.58, 1.78, 0), mats.purple)
	_box(robot_root, "Shoulder R", Vector3(0.3, 0.3, 0.35), Vector3(0.58, 1.78, 0), mats.purple)

	_box(robot_root, "Upper arm L", Vector3(0.15, 0.45, 0.15), Vector3(-0.58, 1.45, 0.1), mats.metal)
	_box(robot_root, "Forearm L", Vector3(0.13, 0.13, 0.45), Vector3(-0.58, 1.25, 0.4), mats.metal)
	_box(robot_root, "Hand L", Vector3(0.16, 0.09, 0.15), Vector3(-0.58, 1.25, 0.65), mats.cyan)

	_box(robot_root, "Upper arm R", Vector3(0.15, 0.45, 0.15), Vector3(0.58, 1.45, 0.1), mats.metal)
	_box(robot_root, "Forearm R", Vector3(0.13, 0.13, 0.45), Vector3(0.58, 1.25, 0.4), mats.metal)
	_box(robot_root, "Hand R", Vector3(0.16, 0.09, 0.15), Vector3(0.58, 1.25, 0.65), mats.pink)

	robot_head = Node3D.new()
	robot_head.name = "Robot head"
	robot_head.position = Vector3(0, 1.95, 0)
	robot_root.add_child(robot_head)

	_box(robot_head, "Neck joint", Vector3(0.18, 0.2, 0.18), Vector3(0, 0.1, 0), mats.metal)
	_box(robot_head, "Head casing", Vector3(0.65, 0.52, 0.56), Vector3(0, 0.42, 0), mats.dark)
	_box(robot_head, "Face visor", Vector3(0.54, 0.32, 0.07), Vector3(0, 0.42, 0.29), mats.black)

	_box(robot_head, "Eye L", Vector3(0.12, 0.09, 0.04), Vector3(-0.14, 0.44, 0.33), mats.cyan)
	_box(robot_head, "Eye R", Vector3(0.12, 0.09, 0.04), Vector3(0.14, 0.44, 0.33), mats.cyan)

	_box(robot_head, "Antenna pole L", Vector3(0.04, 0.28, 0.04), Vector3(-0.33, 0.72, 0), mats.metal)
	_box(robot_head, "Antenna tip L", Vector3(0.08, 0.08, 0.08), Vector3(-0.33, 0.88, 0), mats.pink)
	_box(robot_head, "Antenna pole R", Vector3(0.04, 0.28, 0.04), Vector3(0.33, 0.72, 0), mats.metal)
	_box(robot_head, "Antenna tip R", Vector3(0.08, 0.08, 0.08), Vector3(0.33, 0.88, 0), mats.cyan)

	var name_tag := Label3D.new()
	name_tag.text = "◈ OPERATOR [NEXUS-01] ◈\n\"SESSION ZERO ONLINE. WELCOME.\""
	name_tag.font_size = 34
	name_tag.pixel_size = 0.007
	name_tag.modulate = Color("62f4ff")
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.position = Vector3(0, 1.15, 0)
	name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	robot_head.add_child(name_tag)

	register_interactable(
		Vector3(0, 1.2, -15.5),
		3.8,
		"Speak with Operator [NEXUS-01]",
		[
			"[NEXUS-01]: 'Greetings, wanderer! Welcome to the Afterlife Gaming Cafe. Time has no limit here.'",
			"[NEXUS-01]: 'Did you check the Esports stage? Team Alpha is leading the championship bracket 2-1.'",
			"[NEXUS-01]: 'All battle stations feature zero-ping quantum fiber. Pick any rig you like!'",
			"[NEXUS-01]: 'If you need refreshments, Barista-Bot has freshly brewed Neo-Espresso at the bar.'",
			"[NEXUS-01]: 'Outside in the plaza, Chef Hiro has fresh ramen, and the Line 7 Maglev is on schedule.'"
		]
	)

# --- ESPORTS VIP TOURNAMENT STAGE ---
func _make_esports_stage() -> void:
	_box(self, "Stage platform", Vector3(14.0, 0.45, 8.5), Vector3(0, 0.22, -9.0), mats.dark)
	_box(self, "Stage front neon", Vector3(13.6, 0.08, 0.08), Vector3(0, 0.35, -4.72), mats.cyan)
	_box(self, "Stage border L", Vector3(0.08, 0.08, 8.2), Vector3(-6.9, 0.35, -9.0), mats.pink)
	_box(self, "Stage border R", Vector3(0.08, 0.08, 8.2), Vector3(6.9, 0.35, -9.0), mats.pink)
	_box(self, "Stage step", Vector3(5.0, 0.22, 1.2), Vector3(0, 0.11, -4.1), mats.metal)

	_make_esports_pod(Vector3(-4.2, 0.45, -9.0), "ALPHA", mats.cyan)
	register_interactable(
		Vector3(-4.2, 1.2, -7.5),
		3.2,
		"Inspect Team Alpha Battle Station",
		[
			"[ALPHA STATION] Warm-up scrimmage active. Ping: 1ms. 360Hz Ultra-Sync Display.",
			"[ALPHA STATION] Leaderboard: Player 'CYPHER' - 32 Kills / 4 Deaths [FIRST PLACE]."
		]
	)

	_make_esports_pod(Vector3(4.2, 0.45, -9.0), "OMEGA", mats.pink)
	register_interactable(
		Vector3(4.2, 1.2, -7.5),
		3.2,
		"Inspect Team Omega Battle Station",
		[
			"[OMEGA STATION] Strategy tactical board loaded. Objective: Capture Terminal C.",
			"[OMEGA STATION] Team Captain 'VALKYRIE': 'Push the middle lane on three!'"
		]
	)

	_box(self, "Jumbotron frame", Vector3(8.5, 2.6, 0.5), Vector3(0, 5.2, -9.0), mats.black)
	_box(self, "Jumbotron screen", Vector3(8.0, 2.2, 0.08), Vector3(0, 5.2, -8.74), mats.screen_bright)

	var score_lbl := Label3D.new()
	score_lbl.text = "◈ GRAND FINALS // LIVE ◈\nTEAM ALPHA  [ 2  -  1 ]  TEAM OMEGA\nROUND 4 • MAP: CYBER CITADEL"
	score_lbl.font_size = 42
	score_lbl.pixel_size = 0.008
	score_lbl.modulate = Color("7bf6ff")
	score_lbl.position = Vector3(0, 5.2, -8.68)
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(score_lbl)

func _make_esports_pod(at: Vector3, team_name: String, accent: Material) -> void:
	var pod := Node3D.new()
	pod.name = "Pod " + team_name
	pod.position = at
	add_child(pod)

	_box(pod, "Pod desk", Vector3(4.8, 0.16, 1.4), Vector3(0, 1.15, 0), mats.metal)
	_box(pod, "Pod banner trim", Vector3(4.6, 0.08, 0.06), Vector3(0, 1.05, 0.68), accent)

	for x in [-1.4, 1.4]:
		_box(pod, "Monitor " + str(x), Vector3(1.7, 0.9, 0.12), Vector3(x, 1.75, -0.2), mats.black)
		_box(pod, "Screen " + str(x), Vector3(1.58, 0.78, 0.02), Vector3(x, 1.75, -0.13), accent)
		_box(pod, "Rig tower " + str(x), Vector3(0.55, 0.95, 0.65), Vector3(x * 1.5, 1.7, 0.1), mats.black)
		_box(pod, "RGB tube " + str(x), Vector3(0.06, 0.7, 0.06), Vector3(x * 1.5 + 0.22, 1.7, 0.1), accent)
		_box(pod, "Chair seat " + str(x), Vector3(0.85, 0.18, 0.85), Vector3(x, 0.75, 1.3), mats.black)
		_box(pod, "Chair back " + str(x), Vector3(0.85, 0.95, 0.2), Vector3(x, 1.25, 1.65), accent)

# --- RETRO ARCADE ALLEY ---
func _make_arcade_alley() -> void:
	var arcades := [
		{"name": "CYBER STRIKER 2099", "color": mats.cyan, "z": 9.0, "lines": ["[ARCADE] *COIN INSERTED* SELECT FIGHTER! Current High Score: 994,200 [PILOT_X]", "[ARCADE] COMBO X15! SUPER MOVE UNLEASHED! YOU WIN!"]},
		{"name": "NEO DRIFT RACER", "color": mats.pink, "z": 5.0, "lines": ["[RACER] *TIRES SCREECHING* LAP 1: 00:48.21! NITROUS READY!", "[RACER] DRIFT BONUS: +5,000 PTS! NEW STAGE RECORD!"]},
		{"name": "VOID INVADERS DX", "color": mats.purple, "z": 1.0, "lines": ["[VOID INVADERS] WAVE 24 INCOMING! BOSS ENCOUNTER: OMEGA DREADNOUGHT!", "[VOID INVADERS] SHIELD DEPLETED! *INSERT 1 TOKEN TO CONTINUE*"]},
		{"name": "STREET MATRIX", "color": mats.gold, "z": -3.0, "lines": ["[STREET MATRIX] ROUND 1... FIGHT! HADOUKEN EFFECT CHARGED!", "[STREET MATRIX] PERFECT VICTORY! CHAMPION OF SESSION ZERO!"]}
	]

	for arc in arcades:
		_make_arcade_cabinet(Vector3(-18.5, 0, arc.z), arc.name, arc.color)
		register_interactable(
			Vector3(-17.2, 1.2, arc.z),
			2.5,
			"Insert Token: " + arc.name,
			arc.lines
		)

func _make_arcade_cabinet(at: Vector3, title: String, accent: Material) -> void:
	var cab := Node3D.new()
	cab.name = "Arcade " + title
	cab.position = at
	cab.rotation_degrees = Vector3(0, 90, 0)
	add_child(cab)

	_box(cab, "Base", Vector3(1.1, 0.8, 1.0), Vector3(0, 0.4, 0), mats.dark)
	_box(cab, "Control slope", Vector3(1.1, 0.4, 0.5), Vector3(0, 1.0, 0.2), mats.metal)
	_box(cab, "Upper body", Vector3(1.1, 1.2, 0.8), Vector3(0, 1.8, -0.1), mats.dark)
	_box(cab, "CRT Bezel", Vector3(0.92, 0.72, 0.15), Vector3(0, 1.75, 0.2), mats.black)
	_box(cab, "CRT Screen", Vector3(0.82, 0.62, 0.04), Vector3(0, 1.75, 0.28), mats.screen_bright)
	_box(cab, "Marquee box", Vector3(1.1, 0.35, 0.35), Vector3(0, 2.45, 0.05), mats.black)
	_box(cab, "Marquee glow", Vector3(0.98, 0.24, 0.06), Vector3(0, 2.45, 0.23), accent)
	_box(cab, "Stick shaft", Vector3(0.04, 0.16, 0.04), Vector3(-0.25, 1.25, 0.25), mats.chrome)
	_box(cab, "Stick ball", Vector3(0.08, 0.08, 0.08), Vector3(-0.25, 1.34, 0.25), mats.red)
	for b in [0.1, 0.22, 0.34]:
		_box(cab, "Button " + str(b), Vector3(0.06, 0.04, 0.06), Vector3(b, 1.2, 0.25), accent)

	var lbl := Label3D.new()
	lbl.text = title
	lbl.font_size = 24
	lbl.pixel_size = 0.005
	lbl.modulate = Color("ffffff")
	lbl.position = Vector3(0, 2.45, 0.27)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cab.add_child(lbl)

# --- VENDING & SNACK ZONE ---
func _make_vending_zone() -> void:
	_make_vending_machine(Vector3(18.5, 0, 15.5), "NEO-COLA", mats.cyan, mats.pink)
	register_interactable(
		Vector3(17.2, 1.2, 15.5),
		2.5,
		"Dispense Neo-Cola ($2.50)",
		[
			"[VENDING] *CLUNK* Dispensed: Neon Cherry Cyber-Fizz! (+100 Energy)",
			"[VENDING] *CLUNK* Dispensed: Ultra Glacier Blue Zero! (Refreshed)",
			"[VENDING] *CLUNK* Dispensed: Quantum Lime Spark! (Tastes like electricity)"
		]
	)

	_make_vending_machine(Vector3(18.5, 0, 12.0), "SNACK-BOT", mats.amber, mats.green)
	register_interactable(
		Vector3(17.2, 1.2, 12.0),
		2.5,
		"Buy Synth-Snack ($1.75)",
		[
			"[SNACK-BOT] Dispensed: Spicy Holographic Nachos! Crunchy!",
			"[SNACK-BOT] Dispensed: Cyber-Protein Bar (Cookies & RAM flavor).",
			"[SNACK-BOT] Dispensed: Pixel Gummies (Level 99 Sweetness)!"
		]
	)

	_make_lounge_sofa(Vector3(-8.0, 0, 14.5), mats.purple)
	_make_lounge_sofa(Vector3(8.0, 0, 14.5), mats.pink)

func _make_vending_machine(at: Vector3, brand: String, primary: Material, secondary: Material) -> void:
	var vend := Node3D.new()
	vend.name = "Vending " + brand
	vend.position = at
	vend.rotation_degrees = Vector3(0, -90, 0)
	add_child(vend)

	_box(vend, "Cabinet", Vector3(1.4, 2.5, 1.1), Vector3(0, 1.25, 0), mats.dark)
	_box(vend, "Glass window", Vector3(0.9, 1.3, 0.1), Vector3(-0.15, 1.45, 0.53), mats.glass)
	_box(vend, "Side trim", Vector3(0.08, 2.4, 0.08), Vector3(0.65, 1.25, 0.54), primary)
	_box(vend, "Dispenser door", Vector3(0.85, 0.35, 0.15), Vector3(-0.15, 0.35, 0.52), mats.black)
	_box(vend, "Keypad box", Vector3(0.3, 0.6, 0.08), Vector3(0.45, 1.45, 0.54), mats.metal)
	_box(vend, "Coin slot", Vector3(0.1, 0.03, 0.02), Vector3(0.45, 1.7, 0.58), secondary)
	_box(vend, "Header glow", Vector3(1.25, 0.32, 0.08), Vector3(0, 2.25, 0.53), primary)

	var lbl := Label3D.new()
	lbl.text = brand
	lbl.font_size = 32
	lbl.pixel_size = 0.006
	lbl.modulate = Color("050912")
	lbl.position = Vector3(0, 2.25, 0.58)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vend.add_child(lbl)

func _make_lounge_sofa(at: Vector3, accent: Material) -> void:
	_box(self, "Lounge seat", Vector3(3.2, 0.65, 1.2), at + Vector3(0, 0.38, 0), mats.black)
	_box(self, "Lounge back", Vector3(3.2, 1.1, 0.3), at + Vector3(0, 0.95, 0.45), accent)
	_box(self, "Glass table", Vector3(2.4, 0.45, 1.1), at + Vector3(0, 0.25, -1.4), mats.glass)

# --- CYBER CAFE BAR & SYNTH-KITCHEN ---
func _make_cyber_bar() -> void:
	_box(self, "Bar counter base", Vector3(1.4, 1.2, 10.0), Vector3(17.5, 0.6, -2.0), mats.dark)
	_box(self, "Bar counter top", Vector3(1.8, 0.15, 10.4), Vector3(17.5, 1.25, -2.0), mats.metal)
	_box(self, "Bar front neon", Vector3(0.08, 0.1, 9.8), Vector3(16.75, 0.7, -2.0), mats.amber)

	_box(self, "Bar back wall unit", Vector3(0.5, 3.5, 9.5), Vector3(19.6, 2.5, -2.0), mats.metal)
	for shelf_y in [1.5, 2.3, 3.1]:
		_box(self, "Bar shelf " + str(shelf_y), Vector3(0.6, 0.08, 9.2), Vector3(19.3, shelf_y, -2.0), mats.glass)
		_box(self, "Shelf glow " + str(shelf_y), Vector3(0.06, 0.04, 9.0), Vector3(19.0, shelf_y, -2.0), mats.cyan)
		for z_offset in [-3.5, -2.0, -0.5, 1.0, 2.5, 3.8]:
			_box(self, "Bottle", Vector3(0.12, 0.38, 0.12), Vector3(19.25, shelf_y + 0.22, -2.0 + z_offset), mats.pink if int(z_offset) % 2 == 0 else mats.cyan)

	for z in [-5.0, -2.5, 0.0, 2.5]:
		_box(self, "Stool leg " + str(z), Vector3(0.1, 0.85, 0.1), Vector3(15.8, 0.42, z), mats.chrome)
		_box(self, "Stool seat " + str(z), Vector3(0.6, 0.12, 0.6), Vector3(15.8, 0.9, z), mats.purple)

	_box(self, "Espresso machine", Vector3(0.7, 0.6, 0.9), Vector3(17.5, 1.55, -5.5), mats.chrome)
	_box(self, "Espresso pipe", Vector3(0.06, 0.35, 0.06), Vector3(17.5, 1.95, -5.5), mats.metal)

	register_interactable(
		Vector3(16.0, 1.2, -2.0),
		3.5,
		"Brew Cyber-Espresso at the Bar",
		[
			"[BARISTA-BOT] *HISS & STEAM* Triple-Shot Dark Roast extracted with Liquid Nitrogen!",
			"[BARISTA-BOT] Poured: Electric Blue Synth-Latte with pixel art foam! (Refreshing)",
			"[BARISTA-BOT] 'Enjoy your beverage, gamer. Free Wi-Fi password is: AFTERLIFE_2099'"
		]
	)

# --- VR SIMULATION CAPSULES ---
func _make_vr_pods() -> void:
	_make_single_vr_pod(Vector3(-16.0, 0, -14.0), "VR POD 01", mats.cyan)
	register_interactable(
		Vector3(-14.5, 1.2, -14.0),
		2.8,
		"Enter VR Neural Pod A",
		[
			"[VR POD A] Neural handshake synchronized... Loading Virtual Metaverse Sector 7!",
			"[VR POD A] Haptic feedback calibrated at 100%. Reality disconnect ready."
		]
	)

	_make_single_vr_pod(Vector3(-16.0, 0, -17.5), "VR POD 02", mats.pink)
	register_interactable(
		Vector3(-14.5, 1.2, -17.5),
		2.8,
		"Enter VR Neural Pod B",
		[
			"[VR POD B] Zero-latency simulation engaged. Welcome to the Neural Grid.",
			"[VR POD B] Loading competitive match replay. 360 holographic immersion active."
		]
	)

func _make_single_vr_pod(at: Vector3, label: String, accent: Material) -> void:
	var pod := Node3D.new()
	pod.name = label
	pod.position = at
	pod.rotation_degrees = Vector3(0, 90, 0)
	add_child(pod)

	_box(pod, "Pod base disk", Vector3(2.2, 0.25, 2.2), Vector3(0, 0.12, 0), mats.dark)
	_box(pod, "Base neon ring", Vector3(2.0, 0.06, 2.0), Vector3(0, 0.24, 0), accent)
	_box(pod, "Capsule shell", Vector3(1.6, 2.2, 1.8), Vector3(0, 1.3, -0.2), mats.metal)
	_box(pod, "Glass cockpit visor", Vector3(1.4, 1.6, 0.3), Vector3(0, 1.4, 0.7), mats.glass)
	_box(pod, "Headset mount", Vector3(0.08, 0.6, 0.08), Vector3(0, 2.5, 0.3), mats.chrome)
	_box(pod, "VR Visor", Vector3(0.4, 0.2, 0.3), Vector3(0, 2.2, 0.3), accent)

# --- MAIN BATTLE STATION PC BANG ROWS ---
func _make_gaming_rows() -> void:
	for z in [2.0, 8.0]:
		for x in [-8.0, 8.0]:
			_make_station_cluster(Vector3(x, 0, z))

	register_interactable(
		Vector3(-6.5, 1.1, 8.0),
		2.8,
		"Log into Battle Station Terminal #01",
		[
			"[TERMINAL #01] User logged in: [SESSION_GUEST]. Steam / Matrix Games ready.",
			"[TERMINAL #01] Running Benchmark: 4K 240FPS Ultra RTX Enabled!"
		]
	)
	register_interactable(
		Vector3(6.5, 1.1, 2.0),
		2.8,
		"Log into Battle Station Terminal #08",
		[
			"[TERMINAL #08] Launching: 'AFTER LIFE: SESSION ZERO' [v1.0.4 - CHAMPIONSHIP EDITION].",
			"[TERMINAL #08] High Score: 1,024,800. Ready Player One!"
		]
	)

func _make_station_cluster(at: Vector3) -> void:
	for z_off in [-1.5, 1.5]:
		for x_off in [-2.4, 2.4]:
			_make_single_pc_station(at + Vector3(x_off, 0, z_off))

func _make_single_pc_station(at: Vector3) -> void:
	var group := Node3D.new()
	group.name = "Gaming station"
	group.position = at
	add_child(group)

	_box(group, "Desk top", Vector3(2.6, 0.14, 1.1), Vector3(0, 1.15, 0), mats.metal)
	for x in [-1.15, 1.15]:
		_box(group, "Desk leg", Vector3(0.12, 1.08, 0.12), Vector3(x, 0.54, 0), mats.black)

	_box(group, "PC tower", Vector3(0.48, 0.85, 0.55), Vector3(-0.95, 1.65, -0.05), mats.black)
	_box(group, "PC light", Vector3(0.04, 0.55, 0.04), Vector3(-0.7, 1.68, 0.12), mats.cyan)

	_box(group, "Main Monitor", Vector3(1.2, 0.75, 0.1), Vector3(0.15, 1.7, -0.25), mats.black)
	_box(group, "Main Glow", Vector3(1.08, 0.62, 0.02), Vector3(0.15, 1.7, -0.19), mats.screen)
	_box(group, "Secondary Monitor", Vector3(0.8, 0.75, 0.1), Vector3(1.15, 1.7, -0.15), mats.black)
	_box(group, "Secondary Glow", Vector3(0.72, 0.62, 0.02), Vector3(1.15, 1.7, -0.09), mats.pink)

	_box(group, "Keyboard", Vector3(0.65, 0.04, 0.22), Vector3(0.25, 1.25, 0.22), mats.pink)
	_box(group, "Mousepad", Vector3(0.85, 0.02, 0.35), Vector3(0.35, 1.23, 0.22), mats.black)

	_box(group, "Chair seat", Vector3(0.75, 0.18, 0.75), Vector3(0.25, 0.75, 1.25), mats.black)
	_box(group, "Chair back", Vector3(0.75, 0.9, 0.18), Vector3(0.25, 1.2, 1.6), mats.purple)

# --- GIANT INTERIOR SIGN ---
func _make_sign() -> void:
	_box(self, "Sign backing", Vector3(14.0, 2.2, 0.25), Vector3(0, 5.2, -HALF + 0.35), mats.black)
	_box(self, "Sign top line", Vector3(13.2, 0.08, 0.08), Vector3(0, 6.2, -HALF + 0.5), mats.cyan)
	_box(self, "Sign bottom line", Vector3(13.2, 0.08, 0.08), Vector3(0, 4.2, -HALF + 0.5), mats.pink)

	var sign := Label3D.new()
	sign.name = "AFTERLIFE SESSION ZERO sign"
	sign.text = "AFTERLIFE // SESSION ZERO\nCYBER GAMING LOUNGE & ESPORTS ARENA"
	sign.font_size = 54
	sign.pixel_size = 0.01
	sign.modulate = Color("74f4ff")
	sign.position = Vector3(0, 5.2, -HALF + 0.52)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(sign)

# ==============================================================================
# --- LIVELY CITY & EXTERIOR (20+ METERS ON ALL SIDES) ---
# ==============================================================================
func _make_exterior_city() -> void:
	_make_city_ground()
	_make_cafe_exterior_facade()
	_make_hovercar()
	_make_courier_bike()
	_make_ramen_cart()
	_make_metro_station()
	_make_elevated_rail()
	_make_west_plaza()
	_make_back_alley()
	_make_streetlights()
	_make_skyline_facades()

func _make_city_ground() -> void:
	# Main outdoor pavement layer (84 x 84 m)
	_box(self, "City pavement slab", Vector3(84, 0.06, 84), Vector3(0, 0.015, 0), mats.sidewalk)

	# Front Street / Asphalt Highway (Z: 26 to 34, width 84m)
	_box(self, "Front road asphalt", Vector3(84, 0.08, 8.5), Vector3(0, 0.025, 30.0), mats.asphalt)

	# Glowing road stripes
	for x in [-36, -26, -16, 16, 26, 36]:
		_box(self, "Road stripe " + str(x), Vector3(5.0, 0.09, 0.25), Vector3(x, 0.035, 30.0), mats.road_stripe)

	# Glowing Cyber Crosswalk right in front of the Cafe entrance
	for x in [-4.5, -3.0, -1.5, 0.0, 1.5, 3.0, 4.5]:
		_box(self, "Crosswalk " + str(x), Vector3(0.85, 0.09, 8.0), Vector3(x, 0.036, 30.0), mats.cyan)

	# Curbs
	_box(self, "Near curb", Vector3(84, 0.18, 0.4), Vector3(0, 0.09, 25.6), mats.curb)
	_box(self, "Far curb", Vector3(84, 0.18, 0.4), Vector3(0, 0.09, 34.4), mats.curb)

	# Outer sidewalk runner
	_box(self, "Far sidewalk tile", Vector3(84, 0.08, 7.5), Vector3(0, 0.04, 38.0), mats.sidewalk)

func _make_cafe_exterior_facade() -> void:
	# Entrance Canopy Awning
	_box(self, "Awning roof", Vector3(13.0, 0.3, 4.0), Vector3(0, 6.0, 22.0), mats.metal)
	_box(self, "Awning front neon", Vector3(12.8, 0.12, 0.08), Vector3(0, 5.95, 24.0), mats.cyan)
	_box(self, "Awning side neon L", Vector3(0.08, 0.12, 3.8), Vector3(-6.45, 5.95, 22.0), mats.pink)
	_box(self, "Awning side neon R", Vector3(0.08, 0.12, 3.8), Vector3(6.45, 5.95, 22.0), mats.pink)

	# Awning support pillars
	for x in [-6.2, 6.2]:
		_box(self, "Awning pillar " + str(x), Vector3(0.35, 6.0, 0.35), Vector3(x, 3.0, 23.8), mats.metal)
		_box(self, "Pillar neon " + str(x), Vector3(0.08, 5.8, 0.08), Vector3(x, 3.0, 24.0), mats.cyan)

	# Giant illuminated exterior billboard above the entrance
	_box(self, "Facade sign box", Vector3(18.0, 2.4, 0.35), Vector3(0, 7.4, 20.3), mats.black)
	_box(self, "Facade sign top neon", Vector3(17.6, 0.1, 0.08), Vector3(0, 8.5, 20.5), mats.cyan)
	_box(self, "Facade sign bottom neon", Vector3(17.6, 0.1, 0.08), Vector3(0, 6.3, 20.5), mats.pink)

	var facade_sign := Label3D.new()
	facade_sign.text = "◈ AFTERLIFE : SESSION ZERO ◈\n24/7 CYBER ESPORTS & GAMING LOUNGE"
	facade_sign.font_size = 52
	facade_sign.pixel_size = 0.011
	facade_sign.modulate = Color("7cf5ff")
	facade_sign.position = Vector3(0, 7.4, 20.52)
	facade_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(facade_sign)

	# Entrance welcoming holographic arrows on floor
	for x in [-2.5, 2.5]:
		_box(self, "Floor neon arrow " + str(x), Vector3(0.12, 0.04, 3.0), Vector3(x, 0.03, 21.5), mats.cyan)

func _make_hovercar() -> void:
	var car := Node3D.new()
	car.name = "Hovercar AERO-GT"
	car.position = Vector3(7.5, 0.35, 30.0)
	car.rotation_degrees = Vector3(0, 180, 0)
	add_child(car)

	# Glowing Cyan Repulsor Thruster Underglow
	_box(car, "Underglow glow", Vector3(2.5, 0.06, 5.2), Vector3(0, 0.06, 0), mats.cyan)
	for x in [-1.0, 1.0]:
		for z in [-1.7, 1.7]:
			_box(car, "Repulsor pad", Vector3(0.55, 0.18, 0.75), Vector3(x, 0.12, z), mats.black)
			_box(car, "Repulsor emitter", Vector3(0.42, 0.06, 0.6), Vector3(x, 0.05, z), mats.cyan)

	# Aerodynamic Chassis
	_box(car, "Lower hull", Vector3(2.4, 0.5, 5.4), Vector3(0, 0.45, 0), mats.dark)
	_box(car, "Upper hood", Vector3(2.2, 0.3, 2.8), Vector3(0, 0.65, 1.1), mats.metal)
	_box(car, "Cockpit canopy", Vector3(1.85, 0.65, 2.4), Vector3(0, 0.95, -0.35), mats.glass)
	_box(car, "Rear aero spoiler", Vector3(2.3, 0.1, 0.55), Vector3(0, 1.25, -2.4), mats.metal)
	_box(car, "Spoiler strut L", Vector3(0.08, 0.45, 0.15), Vector3(-0.9, 0.95, -2.4), mats.black)
	_box(car, "Spoiler strut R", Vector3(0.08, 0.45, 0.15), Vector3(0.9, 0.95, -2.4), mats.black)

	# Neon racing trims
	_box(car, "Side neon L", Vector3(0.06, 0.06, 4.6), Vector3(-1.22, 0.5, 0), mats.pink)
	_box(car, "Side neon R", Vector3(0.06, 0.06, 4.6), Vector3(1.22, 0.5, 0), mats.pink)

	# Headlights & Taillights
	_box(car, "Headlight L", Vector3(0.65, 0.1, 0.05), Vector3(-0.75, 0.5, 2.7), mats.cyan)
	_box(car, "Headlight R", Vector3(0.65, 0.1, 0.05), Vector3(0.75, 0.5, 2.7), mats.cyan)
	_box(car, "Taillight bar", Vector3(2.2, 0.12, 0.05), Vector3(0, 0.55, -2.71), mats.red)

	register_interactable(
		Vector3(7.5, 1.0, 30.0),
		3.6,
		"Inspect Parked Hovercar [AERO-GT 2099]",
		[
			"[HOVERCAR] Biometric handshake: Access Denied. Registered to: VIP_PILOT_09.",
			"[HOVERCAR] Engine status: Twin-Ion Turbines idling. Repulsor field: 100%.",
			"[HOVERCAR] *CHIRP CHIRP* Vehicle alarm temporarily disarmed. Sleek sports machine!"
		]
	)

func _make_courier_bike() -> void:
	var bike := Node3D.new()
	bike.name = "Courier Hover-Bike"
	bike.position = Vector3(-7.5, 0.25, 24.8)
	bike.rotation_degrees = Vector3(0, 35, 0)
	add_child(bike)

	_box(bike, "Frame", Vector3(0.5, 0.65, 2.2), Vector3(0, 0.45, 0), mats.metal)
	_box(bike, "Seat", Vector3(0.4, 0.12, 0.7), Vector3(0, 0.75, -0.2), mats.black)
	_box(bike, "Handlebars", Vector3(0.9, 0.08, 0.08), Vector3(0, 0.95, 0.6), mats.chrome)

	# Wheels / Magnetic Rings
	_box(bike, "Front ring", Vector3(0.2, 0.65, 0.65), Vector3(0, 0.35, 1.0), mats.black)
	_box(bike, "Front ring glow", Vector3(0.22, 0.5, 0.5), Vector3(0, 0.35, 1.0), mats.cyan)
	_box(bike, "Rear ring", Vector3(0.2, 0.65, 0.65), Vector3(0, 0.35, -0.9), mats.black)
	_box(bike, "Rear ring glow", Vector3(0.22, 0.5, 0.5), Vector3(0, 0.35, -0.9), mats.pink)

	# Delivery insulated box
	_box(bike, "Delivery box", Vector3(0.75, 0.75, 0.75), Vector3(0, 0.95, -0.85), mats.amber)
	var lbl := Label3D.new()
	lbl.text = "NEO-EATS"
	lbl.font_size = 20
	lbl.pixel_size = 0.005
	lbl.modulate = Color("0a0f16")
	lbl.position = Vector3(0, 0.95, -0.47)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bike.add_child(lbl)

	register_interactable(
		Vector3(-7.5, 0.9, 24.8),
		2.5,
		"Inspect Cyber Courier Hover-Bike",
		[
			"[COURIER BIKE] Delivery order active: '2x Spicy Dumplings + Quantum Soda' for Table 04.",
			"[COURIER BIKE] GPS Route: Sector 4 North Bypass. Speed rating: Mach 0.4."
		]
	)

func _make_ramen_cart() -> void:
	var cart := Node3D.new()
	cart.name = "Cyber Ramen Cart"
	cart.position = Vector3(14.0, 0, 23.5)
	cart.rotation_degrees = Vector3(0, -90, 0)
	add_child(cart)

	# Wooden body & stainless counter
	_box(cart, "Cart body", Vector3(3.6, 1.1, 2.0), Vector3(0, 0.55, 0), mats.wood)
	_box(cart, "Counter top", Vector3(3.9, 0.14, 2.3), Vector3(0, 1.15, 0), mats.metal)

	# Canopy roof
	_box(cart, "Canopy roof", Vector3(4.0, 0.15, 2.4), Vector3(0, 2.7, 0), mats.dark)
	for x in [-1.8, 1.8]:
		for z in [-1.0, 1.0]:
			_box(cart, "Canopy pole", Vector3(0.08, 1.6, 0.08), Vector3(x, 1.9, z), mats.metal)

	# Glowing Japanese Paper Lanterns
	for x in [-1.2, 0.0, 1.2]:
		_box(cart, "Lantern " + str(x), Vector3(0.3, 0.45, 0.3), Vector3(x, 2.3, 1.05), mats.lantern)

	# Bowls, Soup Pots & Steam Vent
	_box(cart, "Soup pot 1", Vector3(0.65, 0.45, 0.65), Vector3(-0.8, 1.45, -0.3), mats.metal)
	_box(cart, "Soup pot 2", Vector3(0.55, 0.4, 0.55), Vector3(0.0, 1.42, -0.3), mats.metal)
	_box(cart, "Steam exhaust pipe", Vector3(0.12, 1.2, 0.12), Vector3(-1.4, 3.2, -0.6), mats.chrome)

	# Stools
	for x in [-1.0, 1.0]:
		_box(cart, "Stool leg", Vector3(0.08, 0.8, 0.08), Vector3(x, 0.4, 1.6), mats.chrome)
		_box(cart, "Stool seat", Vector3(0.55, 0.1, 0.55), Vector3(x, 0.82, 1.6), mats.wood)

	var ramen_sign := Label3D.new()
	ramen_sign.text = "🍜 ラーメン // CYBER RAMEN SECTOR 4"
	ramen_sign.font_size = 28
	ramen_sign.pixel_size = 0.007
	ramen_sign.modulate = Color("ff6644")
	ramen_sign.position = Vector3(0, 2.55, 1.15)
	ramen_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cart.add_child(ramen_sign)

	register_interactable(
		Vector3(14.0, 1.2, 23.5),
		3.5,
		"Order Cyber-Ramen from Street Cart ($4.50)",
		[
			"[RAMEN CART] *STEAM HISSES* Poured: Tonkotsu Matrix Ramen with Soft-Boiled Cyber-Egg!",
			"[RAMEN CART] Chef Hiro: 'Best noodles in Sector 4. Slurp it while it's hot!'",
			"[RAMEN CART] Added: Extra spicy wasabi paste. Stamina boosted +50%!"
		]
	)

func _make_metro_station() -> void:
	var metro := Node3D.new()
	metro.name = "Metro Transit Hub"
	metro.position = Vector3(-14.0, 0, 23.5)
	add_child(metro)

	# Arched glass canopy
	_box(metro, "Canopy glass", Vector3(5.0, 3.2, 3.8), Vector3(0, 1.6, 0), mats.glass)
	_box(metro, "Canopy frame", Vector3(5.2, 0.2, 4.0), Vector3(0, 3.2, 0), mats.metal)
	for x in [-2.5, 2.5]:
		_box(metro, "Support post", Vector3(0.2, 3.2, 0.2), Vector3(x, 1.6, 1.8), mats.metal)
		_box(metro, "Support post rear", Vector3(0.2, 3.2, 0.2), Vector3(x, 1.6, -1.8), mats.metal)

	# Subway descending stair opening
	_box(metro, "Stairs opening", Vector3(4.2, 0.04, 3.2), Vector3(0, 0.03, 0), mats.black)

	# Illuminated route map kiosk
	_box(metro, "Kiosk post", Vector3(0.25, 2.4, 0.25), Vector3(2.8, 1.2, 1.8), mats.metal)
	_box(metro, "Kiosk screen", Vector3(1.2, 1.5, 0.1), Vector3(2.8, 1.8, 1.8), mats.screen_bright)

	var metro_lbl := Label3D.new()
	metro_lbl.text = "◈ METRO TRANSIT ◈\nLINE 7: NEO-SHINJUKU\n[ARRIVING: 2 MIN]\nSTATUS: ON TIME"
	metro_lbl.font_size = 24
	metro_lbl.pixel_size = 0.005
	metro_lbl.modulate = Color("42eaff")
	metro_lbl.position = Vector3(2.8, 1.8, 1.86)
	metro_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	metro.add_child(metro_lbl)

	register_interactable(
		Vector3(-14.0, 1.2, 23.5),
		3.5,
		"Check Metro Transit Departure Schedule",
		[
			"[METRO] Next Maglev Train: LINE 7 to NEO-SHINJUKU arriving at Platform 1.",
			"[METRO] Metro Card Balance: 140 Neo-Credits. Transfer available to Orbital Spaceport.",
			"[METRO] Notice: Late night express service runs every 5 minutes until dawn."
		]
	)

func _make_elevated_rail() -> void:
	# Maglev Monorail running along the East Highway at X = 32.0, Y = 6.8
	var track_x := 32.0
	var track_y := 6.8

	# Support pillars
	for z in [-32.0, -16.0, 0.0, 16.0, 32.0]:
		_box(self, "Sky-rail pillar", Vector3(1.8, track_y, 1.8), Vector3(track_x, track_y / 2, z), mats.wall)

	# Elevated Track Girder
	_box(self, "Sky-rail girder", Vector3(3.2, 0.9, 84.0), Vector3(track_x, track_y + 0.45, 0), mats.metal)
	_box(self, "Maglev power rail", Vector3(0.18, 0.12, 84.0), Vector3(track_x, track_y + 0.95, 0), mats.cyan)

	# Docked Futuristic Maglev Commuter Train Car
	var train := Node3D.new()
	train.name = "Maglev Train Car"
	train.position = Vector3(track_x, track_y + 2.2, 4.0)
	add_child(train)

	_box(train, "Train hull", Vector3(2.8, 2.5, 18.0), Vector3(0, 0, 0), mats.dark)
	_box(train, "Train window strip L", Vector3(0.06, 0.75, 16.0), Vector3(-1.42, 0.15, 0), mats.screen_bright)
	_box(train, "Train window strip R", Vector3(0.06, 0.75, 16.0), Vector3(1.42, 0.15, 0), mats.screen_bright)
	_box(train, "Train nose headlights", Vector3(2.0, 0.18, 0.1), Vector3(0, -0.4, 9.05), mats.cyan)
	_box(train, "Train roof neon", Vector3(0.1, 0.08, 17.5), Vector3(0, 1.28, 0), mats.pink)

func _make_west_plaza() -> void:
	# West Pedestrian Plaza at X = -31.0, Z = 0
	_box(self, "Plaza stepped terrace", Vector3(16.0, 0.25, 20.0), Vector3(-31.0, 0.12, 0), mats.metal)
	_box(self, "Plaza neon ring", Vector3(15.6, 0.06, 19.6), Vector3(-31.0, 0.26, 0), mats.cyan)

	# Central Holographic Energy Spire
	var spire := Node3D.new()
	spire.name = "Hologram Spire"
	spire.position = Vector3(-31.0, 0.25, 0)
	add_child(spire)

	_box(spire, "Base pedestal", Vector3(2.5, 1.2, 2.5), Vector3(0, 0.6, 0), mats.dark)
	_box(spire, "Emitter glow", Vector3(2.0, 0.1, 2.0), Vector3(0, 1.25, 0), mats.cyan)
	_box(spire, "Antenna mast", Vector3(0.35, 6.5, 0.35), Vector3(0, 4.4, 0), mats.chrome)

	# Floating Hologram Banner
	_box(spire, "Hologram projector ring", Vector3(4.2, 0.6, 4.2), Vector3(0, 4.8, 0), mats.purple)

	var holo_lbl := Label3D.new()
	holo_lbl.text = "◈ SECTOR 4 PUBLIC BEACON ◈\nVOTED #1 ESPORTS VENUE // AFTERLIFE CAFE"
	holo_lbl.font_size = 32
	holo_lbl.pixel_size = 0.008
	holo_lbl.modulate = Color("d466ff")
	holo_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	holo_lbl.position = Vector3(0, 5.8, 0)
	holo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spire.add_child(holo_lbl)

	register_interactable(
		Vector3(-31.0, 1.2, 0),
		4.2,
		"Tune Public Hologram Beacon",
		[
			"[BEACON] Frequency tuned: Playing Sector 4 Synthwave Radio [104.2 FM].",
			"[BEACON] Holographic display: 'AFTERLIFE CAFE VOTED #1 ESPORTS HUB 2099'.",
			"[BEACON] Local weather: 18°C, clear skies with neon precipitation."
		]
	)

func _make_back_alley() -> void:
	# Power Substation behind cafe at Z = -28.0
	var gen := Node3D.new()
	gen.name = "Quantum Power Substation"
	gen.position = Vector3(0, 0, -28.0)
	add_child(gen)

	_box(gen, "Substation casing", Vector3(5.5, 3.2, 3.5), Vector3(0, 1.6, 0), mats.dark)
	_box(gen, "Cooling fan vents", Vector3(4.8, 1.2, 0.15), Vector3(0, 1.6, 1.78), mats.metal)
	_box(gen, "High voltage LED", Vector3(0.15, 0.15, 0.08), Vector3(2.2, 2.5, 1.78), mats.red)

	# Plasma conduits running from generator to back wall of cafe
	for x in [-1.5, 0.0, 1.5]:
		_box(gen, "Plasma conduit " + str(x), Vector3(0.2, 0.2, 7.5), Vector3(x, 2.2, 4.0), mats.cyan)

	register_interactable(
		Vector3(0, 1.2, -28.0),
		4.0,
		"Inspect Quantum Power Substation",
		[
			"[POWER CELL] Sub-station output: 1.21 Gigawatts. Clean fusion reactor online.",
			"[POWER CELL] Powering 16 VIP rigs, Esports stage, and cryogenic AC systems.",
			"[POWER CELL] Warning: High voltage plasma conduit. Do not tamper!"
		]
	)

	# Dumpster recycling units
	_box(self, "Recycler bin 1", Vector3(2.2, 1.4, 1.4), Vector3(-12.0, 0.7, -23.0), mats.metal)
	_box(self, "Recycler bin 2", Vector3(2.2, 1.4, 1.4), Vector3(12.0, 0.7, -23.0), mats.dark)

func _make_streetlights() -> void:
	var light_coords := [
		Vector3(-18.0, 0, 25.4),
		Vector3(0.0, 0, 25.4),
		Vector3(18.0, 0, 25.4),
		Vector3(-18.0, 0, 34.6),
		Vector3(0.0, 0, 34.6),
		Vector3(18.0, 0, 34.6)
	]

	for pos in light_coords:
		_make_single_streetlight(pos)

func _make_single_streetlight(at: Vector3) -> void:
	var pole := Node3D.new()
	pole.name = "Streetlight"
	pole.position = at
	add_child(pole)

	_box(pole, "Base", Vector3(0.45, 0.5, 0.45), Vector3(0, 0.25, 0), mats.metal)
	_box(pole, "Mast", Vector3(0.2, 6.2, 0.2), Vector3(0, 3.35, 0), mats.black)
	_box(pole, "Curved arm", Vector3(0.18, 0.18, 1.8), Vector3(0, 6.4, 0.8), mats.black)
	_box(pole, "Lantern fixture", Vector3(0.4, 0.16, 0.8), Vector3(0, 6.3, 1.6), mats.metal)
	_box(pole, "Lantern bulb", Vector3(0.32, 0.06, 0.7), Vector3(0, 6.2, 1.6), mats.cyan)

	_add_point_light_to(pole, Vector3(0, 6.0, 1.6), Color("42eaff"), 1.8, 11.0)

func _make_skyline_facades() -> void:
	# Tall perimeter building facades forming the cyberpunk city skyline backdrop with solid boundaries
	# Front skyline (Z = 42)
	_box(self, "Front skyline L", Vector3(36, 24, 6), Vector3(-22, 12, 42), mats.wall, true)
	_box(self, "Front skyline R", Vector3(36, 24, 6), Vector3(22, 12, 42), mats.wall, true)
	_box(self, "Front windows L", Vector3(32, 20, 0.1), Vector3(-22, 12, 38.9), mats.window_glow)
	_box(self, "Front windows R", Vector3(32, 20, 0.1), Vector3(22, 12, 38.9), mats.window_glow)

	# Huge Rooftop Hologram Billboard
	_box(self, "Rooftop billboard", Vector3(22.0, 3.8, 0.4), Vector3(0, 20.0, 42.0), mats.black)
	_box(self, "Billboard neon trim", Vector3(21.6, 0.1, 0.1), Vector3(0, 22.0, 42.22), mats.pink)

	var city_billboard := Label3D.new()
	city_billboard.text = "◈ QUANTUM CORP // EVOLVE BEYOND REALITY ◈\nNEO-KOBE SECTOR 4"
	city_billboard.font_size = 46
	city_billboard.pixel_size = 0.012
	city_billboard.modulate = Color("ff42ba")
	city_billboard.position = Vector3(0, 20.0, 42.25)
	city_billboard.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(city_billboard)

	# Back skyline (Z = -42)
	_box(self, "Back skyline", Vector3(84, 22, 6), Vector3(0, 11, -42), mats.wall, true)
	_box(self, "Back windows", Vector3(80, 18, 0.1), Vector3(0, 11, -38.9), mats.window_glow)

	# Left/West skyline (X = -42)
	_box(self, "West skyline", Vector3(6, 26, 84), Vector3(-42, 13, 0), mats.wall, true)
	_box(self, "West windows", Vector3(0.1, 22, 80), Vector3(-38.9, 13, 0), mats.window_glow)

	# Right/East skyline (X = 42)
	_box(self, "East skyline", Vector3(6, 26, 84), Vector3(42, 13, 0), mats.wall, true)
	_box(self, "East windows", Vector3(0.1, 22, 80), Vector3(38.9, 13, 0), mats.window_glow)

# --- 9-CAMERA CCTV SURVEILLANCE SYSTEM ---
func _make_security_cameras() -> void:
	scanning_cams.clear()
	# Interior Cameras
	_make_cctv("CAM-01 [ENTRANCE]", Vector3(-18.5, 6.4, 18.5), Vector3(0.0, 2.0, 16.0))
	_make_cctv("CAM-02 [RECEPTION & ROBOT]", Vector3(18.5, 6.4, -18.5), Vector3(0.0, 1.6, -16.0))
	_make_cctv("CAM-03 [BATTLE STATIONS]", Vector3(-18.5, 6.4, 5.0), Vector3(0.0, 1.2, 5.0))
	_make_cctv("CAM-04 [ARCADE ALLEY]", Vector3(-18.5, 6.4, -8.0), Vector3(-17.0, 1.2, 3.0))
	_make_cctv("CAM-05 [CYBER BAR]", Vector3(18.5, 6.4, 5.0), Vector3(17.0, 1.2, -2.0))
	_make_cctv("CAM-06 [ESPORTS STAGE]", Vector3(18.5, 6.4, -8.0), Vector3(0.0, 1.2, -9.0))
	_make_cctv("CAM-07 [VR CAPSULES]", Vector3(-18.5, 6.4, -18.5), Vector3(-16.0, 1.2, -15.5))
	_make_dome_cctv("CAM-08 [OVERHEAD 360 DOME]", Vector3(0.0, 7.1, 0.0))
	# Exterior City Camera
	_make_cctv("CAM-09 [CITY PLAZA & STREET]", Vector3(0.0, 7.5, 34.5), Vector3(0.0, 2.0, 22.0))

func _make_cctv(cam_name: String, pos: Vector3, look_at_pos: Vector3) -> void:
	var mount := Node3D.new()
	mount.name = cam_name + " Mount"
	mount.position = pos
	add_child(mount)

	_box(mount, "Mount bracket", Vector3(0.4, 0.4, 0.12), Vector3.ZERO, mats.metal)
	mount.look_at(look_at_pos, Vector3.UP)

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, -0.2, -0.4)
	mount.add_child(head)

	_box(head, "Housing", Vector3(0.28, 0.25, 0.55), Vector3.ZERO, mats.dark)
	_box(head, "Top shield", Vector3(0.32, 0.05, 0.6), Vector3(0, 0.15, 0), mats.black)
	_box(head, "Lens ring", Vector3(0.2, 0.2, 0.09), Vector3(0, 0, -0.32), mats.black)
	_box(head, "Lens glass", Vector3(0.14, 0.14, 0.04), Vector3(0, 0, -0.36), mats.cyan)
	_box(head, "REC LED", Vector3(0.05, 0.05, 0.04), Vector3(0.09, 0.08, -0.31), mats.red)

	var cctv_cam := Camera3D.new()
	cctv_cam.name = cam_name
	cctv_cam.fov = 75.0
	cctv_cam.position = Vector3(0, 0, -0.38)
	cctv_cam.add_to_group("cctv_camera")
	head.add_child(cctv_cam)

	scanning_cams.append({
		"head": head,
		"base_rot_y": head.rotation.y,
		"speed": randf_range(0.35, 0.65),
		"phase": randf_range(0.0, 6.28)
	})

func _make_dome_cctv(cam_name: String, pos: Vector3) -> void:
	var mount := Node3D.new()
	mount.name = cam_name + " Mount"
	mount.position = pos
	add_child(mount)

	_box(mount, "Mount disk", Vector3(0.8, 0.08, 0.8), Vector3(0, 0.04, 0), mats.metal)
	_box(mount, "Dome collar", Vector3(0.65, 0.12, 0.65), Vector3(0, -0.06, 0), mats.black)
	_box(mount, "Dome glass", Vector3(0.55, 0.28, 0.55), Vector3(0, -0.2, 0), mats.glass)

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, -0.16, 0)
	head.rotation_degrees = Vector3(-45, 0, 0)
	mount.add_child(head)

	_box(head, "Sensor core", Vector3(0.3, 0.3, 0.3), Vector3.ZERO, mats.dark)
	_box(head, "Lens 1", Vector3(0.1, 0.1, 0.05), Vector3(-0.06, 0, -0.16), mats.cyan)
	_box(head, "Lens 2", Vector3(0.1, 0.1, 0.05), Vector3(0.06, 0, -0.16), mats.cyan)
	_box(head, "REC LED", Vector3(0.05, 0.05, 0.04), Vector3(0, 0.1, -0.15), mats.red)

	var cctv_cam := Camera3D.new()
	cctv_cam.name = cam_name
	cctv_cam.fov = 85.0
	cctv_cam.position = Vector3(0, 0, -0.18)
	cctv_cam.add_to_group("cctv_camera")
	head.add_child(cctv_cam)

	scanning_cams.append({
		"head": head,
		"base_rot_y": head.rotation.y,
		"speed": 0.45,
		"phase": 0.0
	})

# --- LIGHTING & ENVIRONMENT ---
func _make_lighting() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("1e2230")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_bloom = 0.35
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 1.8
	env.ssil_enabled = true
	env.ssil_radius = 4.0
	env.ssil_intensity = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color("141624")
	env.fog_density = 0.002
	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_color = Color("a5b5d8")
	sun.light_energy = 0.5
	sun.shadow_enabled = true
	add_child(sun)

	# Interior atmospheric zone lights
	_add_point_light(Vector3(-10, 5.0, 10), Color("24dfff"), 2.2, 14.0)
	_add_point_light(Vector3(10, 5.0, 10), Color("f42eaa"), 2.2, 14.0)
	_add_point_light(Vector3(-10, 5.0, -6), Color("7848ff"), 2.2, 14.0)
	_add_point_light(Vector3(10, 5.0, -6), Color("24dfff"), 2.2, 14.0)
	_add_point_light(Vector3(0, 5.0, 16), Color("42eaff"), 2.0, 12.0)
	_add_point_light(Vector3(0, 5.0, -16), Color("f42eaa"), 2.2, 14.0)
	_add_point_light(Vector3(-17, 4.0, 3), Color("ffaa33"), 1.8, 10.0)
	_add_point_light(Vector3(17, 4.0, -2), Color("33ff88"), 1.8, 10.0)

	# Exterior city lights
	_add_point_light(Vector3(0, 5.5, 23.0), Color("42eaff"), 2.4, 15.0) # Awning entrance glow
	_add_point_light(Vector3(14, 3.5, 23.5), Color("ff4422"), 2.0, 9.0) # Ramen stall glow
	_add_point_light(Vector3(-14, 3.5, 23.5), Color("22aaff"), 2.0, 9.0) # Metro station glow
	_add_point_light(Vector3(-31, 5.0, 0), Color("9933ff"), 2.5, 16.0) # West plaza beacon glow

func _add_point_light(at: Vector3, tint: Color, energy: float, radius: float) -> void:
	_add_point_light_to(self, at, tint, energy, radius)

func _add_point_light_to(parent: Node3D, at: Vector3, tint: Color, energy: float, radius: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = tint
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = false
	parent.add_child(light)


# =============================================================================
# --- ACT STATE MANAGEMENT ---
# =============================================================================

func apply_story_act(act: int) -> void:
	var floor_node := get_node_or_null("Floor")
	match act:
		0: # ACT1_CAFE_NIGHT
			if floor_node != null and floor_node is Node3D:
				(floor_node as Node3D).visible = true
			_set_nodes_visible(_cafe_interior_nodes, true)
			_set_nodes_visible(_city_exterior_nodes, true)
			_set_nodes_visible(_interior_lights, true)
			_set_nodes_visible(_exterior_lights, true)
			_set_nodes_visible(_needen_nodes, false)
			_set_nodes_visible(_act4_nodes, false)
			_restore_night_lighting()
		1: # ACT2_SIMULATION (Neo-Eden)
			if floor_node != null and floor_node is Node3D:
				(floor_node as Node3D).visible = false
			_set_nodes_visible(_cafe_interior_nodes, false)
			_set_nodes_visible(_city_exterior_nodes, false)
			_set_nodes_visible(_interior_lights, false)
			_set_nodes_visible(_exterior_lights, false)
			_set_nodes_visible(_needen_nodes, true)
			_set_nodes_visible(_act4_nodes, false)
			_apply_needen_lighting()
		2: # ACT3_AWAKENING (Dawn - same cafe, cooler morning)
			if floor_node != null and floor_node is Node3D:
				(floor_node as Node3D).visible = true
			_set_nodes_visible(_cafe_interior_nodes, true)
			_set_nodes_visible(_city_exterior_nodes, true)
			_set_nodes_visible(_interior_lights, true)
			_set_nodes_visible(_exterior_lights, true)
			_set_nodes_visible(_needen_nodes, false)
			_set_nodes_visible(_act4_nodes, false)
			_apply_dawn_lighting()
		3: # ACT4_VANISHING_CAFE (Vacant lot inside, city street outside)
			if floor_node != null and floor_node is Node3D:
				(floor_node as Node3D).visible = true
			_set_nodes_visible(_cafe_interior_nodes, false)
			_set_nodes_visible(_city_exterior_nodes, true)
			_set_nodes_visible(_interior_lights, false)
			_set_nodes_visible(_exterior_lights, true)
			_set_nodes_visible(_needen_nodes, false)
			_set_nodes_visible(_act4_nodes, true)
			_apply_afternoon_lighting()
		4: # POST_CREDITS (dark)
			if floor_node != null and floor_node is Node3D:
				(floor_node as Node3D).visible = false
			_set_nodes_visible(_cafe_interior_nodes, false)
			_set_nodes_visible(_city_exterior_nodes, false)
			_set_nodes_visible(_interior_lights, false)
			_set_nodes_visible(_exterior_lights, false)
			_set_nodes_visible(_needen_nodes, false)
			_set_nodes_visible(_act4_nodes, false)
			_apply_postcredits_lighting()

func _set_nodes_visible(nodes: Array, vis: bool) -> void:
	for n in nodes:
		if is_instance_valid(n) and n is Node3D:
			(n as Node3D).visible = vis

var _world_env: WorldEnvironment = null

func _get_world_env() -> Environment:
	if _world_env == null:
		for child in get_children():
			if child is WorldEnvironment:
				_world_env = child
				break
	if _world_env != null:
		return _world_env.environment
	return null

func _restore_night_lighting() -> void:
	var env := _get_world_env()
	if env == null:
		return
	env.ambient_light_color = Color("1e2230")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_bloom = 0.35
	env.ssao_enabled = true
	env.ssil_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color("141624")
	env.fog_density = 0.002

func _apply_dawn_lighting() -> void:
	var env := _get_world_env()
	if env == null:
		return
	env.ambient_light_color = Color("3a4b60")
	env.ambient_light_energy = 0.8
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1
	env.ssao_enabled = true
	env.ssil_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color("c0d0e4")
	env.fog_density = 0.003

func _apply_afternoon_lighting() -> void:
	var env := _get_world_env()
	if env == null:
		return
	env.ambient_light_color = Color("50545c")
	env.ambient_light_energy = 0.9
	env.glow_intensity = 0.2
	env.glow_bloom = 0.05
	env.ssao_enabled = true
	env.ssil_enabled = true
	env.fog_enabled = false

func _apply_needen_lighting() -> void:
	var env := _get_world_env()
	if env == null:
		return
	env.ambient_light_color = Color("220008")
	env.ambient_light_energy = 0.85
	env.glow_enabled = true
	env.glow_intensity = 1.4
	env.glow_bloom = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssil_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color("440011")
	env.fog_density = 0.006

func _apply_postcredits_lighting() -> void:
	var env := _get_world_env()
	if env == null:
		return
	env.ambient_light_color = Color("000000")
	env.ambient_light_energy = 0.0
	env.glow_enabled = false
	env.fog_enabled = true
	env.fog_density = 0.02

# =============================================================================
# --- NEO-EDEN ENVIRONMENT (ACT II: 2189 DYSTOPIAN SIMULATION) ---
# =============================================================================

func _build_needen_environment() -> void:
	var root := Node3D.new()
	root.name = "NeoEden_Root"
	root.visible = false
	add_child(root)
	_needen_nodes.append(root)

	# --- Ground plane: glitched red-tinted asphalt ---
	var ground := MeshInstance3D.new()
	ground.name = "NE_Ground"
	var gm := PlaneMesh.new()
	gm.size = Vector2(120, 120)
	ground.mesh = gm
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color("0d0008")
	ground_mat.emission_enabled = true
	ground_mat.emission = Color("440011")
	ground_mat.emission_energy_multiplier = 0.3
	ground_mat.roughness = 0.9
	ground.material_override = ground_mat
	root.add_child(ground)

	# Ground collision
	var ground_body := StaticBody3D.new()
	var ground_cs := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(120, 1, 120)
	ground_cs.shape = ground_shape
	ground_cs.position = Vector3(0, -0.5, 0)
	ground_body.add_child(ground_cs)
	ground.add_child(ground_body)

	# --- NEXUS CORE TOWER (center stage at 0, 0, -9) ---
	var tower_root := Node3D.new()
	tower_root.name = "NexusTower"
	tower_root.position = Vector3(0, 0, -12)
	root.add_child(tower_root)

	# Tower base platform
	_ne_box(tower_root, "Base", Vector3(16, 0.5, 16), Vector3(0, 0.25, 0), Color("110022"), Color("8800ff"), 0.8)

	# Central column - tall glowing obelisk
	_ne_box(tower_root, "Column", Vector3(2.5, 22, 2.5), Vector3(0, 11, 0), Color("050010"), Color("cc00ff"), 1.6)

	# Column accent rings
	for i in range(5):
		var ring_y := 3.0 + i * 3.8
		_ne_box(tower_root, "Ring%d" % i, Vector3(4.0, 0.3, 4.0), Vector3(0, ring_y, 0), Color("000000"), Color("ff00aa"), 2.2)

	# NEXUS Eye - glowing red sphere proxy (flat box)
	_ne_box(tower_root, "Eye_H", Vector3(1.8, 0.2, 0.3), Vector3(0, 16, 0), Color("000000"), Color("ff0000"), 3.5)
	_ne_box(tower_root, "Eye_V", Vector3(0.3, 1.8, 0.2), Vector3(0, 16, 0), Color("000000"), Color("ff0000"), 3.5)

	# Platform steps
	_ne_box(tower_root, "Step1", Vector3(10, 0.35, 10), Vector3(0, 0.35, 0), Color("0a0015"), Color("6600cc"), 0.5)
	_ne_box(tower_root, "Step2", Vector3(7, 0.7, 7), Vector3(0, 0.7, 0), Color("0a0015"), Color("8800ff"), 0.6)
	_ne_box(tower_root, "Step3", Vector3(4, 1.05, 4), Vector3(0, 1.05, 0), Color("0a0015"), Color("aa00ff"), 0.7)

	# Floating debris / broken panels around tower
	for i in range(8):
		var angle := i * TAU / 8.0
		var rx := cos(angle) * 9.0
		var rz := sin(angle) * 9.0
		var ry := randf_range(2.0, 10.0)
		var debris_size := Vector3(randf_range(0.5, 2.5), randf_range(0.1, 0.8), randf_range(0.5, 2.5))
		_ne_box(tower_root, "Debris%d" % i, debris_size, Vector3(rx, ry, rz), Color("0a000f"), Color("ff2288"), 0.9)

	# --- ARENA WALLS (cracked neon-lit) ---
	var wall_h := 12.0
	var wall_half := 28.0
	# North wall
	_ne_box(root, "Wall_N", Vector3(wall_half * 2, wall_h, 1.0), Vector3(0, wall_h * 0.5, -wall_half), Color("0a000a"), Color("ff0044"), 0.4)
	# South wall
	_ne_box(root, "Wall_S", Vector3(wall_half * 2, wall_h, 1.0), Vector3(0, wall_h * 0.5, wall_half), Color("0a000a"), Color("ff0044"), 0.4)
	# East wall
	_ne_box(root, "Wall_E", Vector3(1.0, wall_h, wall_half * 2), Vector3(wall_half, wall_h * 0.5, 0), Color("0a000a"), Color("ff0044"), 0.4)
	# West wall
	_ne_box(root, "Wall_W", Vector3(1.0, wall_h, wall_half * 2), Vector3(-wall_half, wall_h * 0.5, 0), Color("0a000a"), Color("ff0044"), 0.4)

	# --- HOLOGRAPHIC GRID ON FLOOR ---
	for xi in range(-5, 6):
		_ne_box(root, "GridX%d" % xi, Vector3(0.06, 0.02, 56), Vector3(xi * 5.0, 0.01, 0), Color("000000"), Color("440066"), 0.8)
	for zi in range(-5, 6):
		_ne_box(root, "GridZ%d" % zi, Vector3(56, 0.02, 0.06), Vector3(0, 0.01, zi * 5.0), Color("000000"), Color("440066"), 0.8)

	# --- FLOATING COMBAT DRONES (static silhouettes) ---
	for i in range(6):
		var angle := i * TAU / 6.0
		var r := 14.0
		var drone_pos := Vector3(cos(angle) * r, 6.0, sin(angle) * r - 5.0)
		_ne_box(root, "Drone%d_Body" % i, Vector3(1.2, 0.3, 1.8), drone_pos, Color("050010"), Color("ff1133"), 1.4)
		_ne_box(root, "Drone%d_Wing1" % i, Vector3(2.5, 0.12, 0.5), drone_pos + Vector3(0, 0, 0), Color("050010"), Color("cc0033"), 0.8)
		_ne_box(root, "Drone%d_Eye" % i, Vector3(0.2, 0.2, 0.1), drone_pos + Vector3(0, 0.2, -0.9), Color("000000"), Color("ff0000"), 3.0)

	# --- NEON BANNERS (text-like strips) ---
	for i in range(4):
		var bx: float = [-18.0, 18.0, -18.0, 18.0][i]
		var bz: float = [-5.0, -5.0, 5.0, 5.0][i]
		_ne_box(root, "Banner%d_Frame" % i, Vector3(8.0, 3.5, 0.18), Vector3(bx, 7.0, bz), Color("0a0005"), Color("ff00cc"), 1.2)
		_ne_box(root, "Banner%d_Text" % i, Vector3(6.5, 2.0, 0.12), Vector3(bx, 7.0, bz + 0.06), Color("000000"), Color("ffffff"), 2.0)

	# --- NEXUS OBELISK LIGHTS ---
	_add_point_light_to(root, Vector3(0, 14, -12), Color("cc00ff"), 4.5, 22.0)
	_add_point_light_to(root, Vector3(0, 4, -12), Color("ff0044"), 3.5, 18.0)
	_add_point_light_to(root, Vector3(-12, 3, -5), Color("ff2200"), 2.5, 14.0)
	_add_point_light_to(root, Vector3(12, 3, -5), Color("8800ff"), 2.5, 14.0)
	_add_point_light_to(root, Vector3(0, 2, 10), Color("ff0066"), 2.0, 12.0)

# Helper: creates a glowing emissive box for Neo-Eden environment
func _ne_box(parent: Node3D, lbl: String, size: Vector3, pos: Vector3, albedo: Color, emission: Color, emit_energy: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = lbl
	mi.position = pos
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = emit_energy
	mat.roughness = 0.6
	mi.material_override = mat
	parent.add_child(mi)
	return mi

# =============================================================================
# --- ACT IV ENVIRONMENT (ABANDONED VACANT LOT) ---
# =============================================================================

func _build_act4_environment() -> void:
	var root := Node3D.new()
	root.name = "Act4_Root"
	root.visible = false
	add_child(root)
	_act4_nodes.append(root)

	# Dusty concrete floor patch where cafe was
	_a4_box(root, "ConcreteFloor", Vector3(42, 0.15, 42), Vector3(0, 0.075, 0), Color("3a3630"))

	# Cracked concrete panels on floor
	for i in range(12):
		var cx := randf_range(-18, 18)
		var cz := randf_range(-18, 18)
		_a4_box(root, "Crack%d" % i, Vector3(randf_range(0.5, 3.0), 0.02, randf_range(0.05, 0.3)), Vector3(cx, 0.16, cz), Color("1a1814"))

	# Dusty bare walls (no neon, no cafe)
	var wh := 5.0
	var wl := 40.0
	_a4_box(root, "VacantWall_N", Vector3(wl, wh, 0.4), Vector3(0, wh * 0.5, -20), Color("2a2824"))
	_a4_box(root, "VacantWall_E", Vector3(0.4, wh, wl), Vector3(20, wh * 0.5, 0), Color("282624"))
	_a4_box(root, "VacantWall_W", Vector3(0.4, wh, wl), Vector3(-20, wh * 0.5, 0), Color("282624"))
	# South facade (open - where glass doors were, now boarded)
	_a4_box(root, "VacantWall_S_L", Vector3(8, wh, 0.4), Vector3(-12, wh * 0.5, 20), Color("282624"))
	_a4_box(root, "VacantWall_S_R", Vector3(8, wh, 0.4), Vector3(12, wh * 0.5, 20), Color("282624"))
	# Boarded door planks (center, where automatic door was)
	for i in range(5):
		var by := 0.5 + i * 1.0
		_a4_box(root, "Board%d" % i, Vector3(8.5, 0.28, 0.25), Vector3(0, by, 20.1), Color("4a3822"))

	# FOR LEASE sign on north wall
	_a4_box(root, "ForLease_BG", Vector3(5.0, 1.4, 0.12), Vector3(0, 4.0, -19.7), Color("f2f0e8"))
	_a4_box(root, "ForLease_Text_L", Vector3(1.0, 0.6, 0.06), Vector3(-1.5, 4.0, -19.64), Color("cc2200"))
	_a4_box(root, "ForLease_Text_R", Vector3(1.0, 0.6, 0.06), Vector3(0.5, 4.0, -19.64), Color("cc2200"))

	# Broken ceiling beams
	_a4_box(root, "Beam1", Vector3(42, 0.3, 0.4), Vector3(0, 7.0, -6), Color("1e1c1a"))
	_a4_box(root, "Beam2", Vector3(42, 0.3, 0.4), Vector3(0, 7.0, 6), Color("1e1c1a"))
	_a4_box(root, "Beam3", Vector3(0.4, 0.3, 42), Vector3(-8, 7.0, 0), Color("1e1c1a"))

	# Broken/fallen beam debris
	_a4_box(root, "FallenBeam1", Vector3(6.5, 0.3, 0.4), Vector3(-5, 0.5, 3), Color("1e1c1a"))
	_a4_box(root, "FallenBeam2", Vector3(4.0, 0.25, 0.35), Vector3(8, 0.4, -5), Color("1e1c1a"))

	# Dusty window (sealed with old boards)
	_a4_box(root, "WinBoard_E", Vector3(4.0, 2.0, 0.22), Vector3(19.9, 3.5, 6), Color("4a3822"))
	_a4_box(root, "WinBoard_W", Vector3(4.0, 2.0, 0.22), Vector3(-19.9, 3.5, -6), Color("4a3822"))

	# Trash/debris pile
	for i in range(8):
		var tx := randf_range(-15, 15)
		var tz := randf_range(-15, 15)
		var ts := Vector3(randf_range(0.1, 0.5), randf_range(0.05, 0.3), randf_range(0.1, 0.5))
		_a4_box(root, "Trash%d" % i, ts, Vector3(tx, ts.y * 0.5, tz), Color("2a2520"))

	# Old paint/stain marks on floor
	for i in range(5):
		var px := randf_range(-10, 10)
		var pz := randf_range(-10, 10)
		_a4_box(root, "Stain%d" % i, Vector3(randf_range(1.0, 3.5), 0.01, randf_range(1.0, 3.5)), Vector3(px, 0.16, pz), Color("1a1510"))

	# The ghost: faded rectangle outline where Terminal 07 USED to be (barely visible)
	_a4_box(root, "GhostDesk_Outline", Vector3(1.4, 0.01, 0.7), Vector3(-6.5, 0.17, 8.0), Color("2e2a26"))

	# Dim single hanging light
	_add_point_light_to(root, Vector3(0, 5.0, 0), Color("a8956a"), 0.6, 12.0)
	_add_point_light_to(root, Vector3(0, 5.0, 0), Color("c8b090"), 0.3, 18.0)

func _a4_box(parent: Node3D, lbl: String, size: Vector3, pos: Vector3, albedo: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.name = lbl
	mi.position = pos
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = 0.95
	mat.metallic = 0.0
	mi.material_override = mat
	parent.add_child(mi)

# =============================================================================
# --- TERMINAL #07 MARKER ---
# =============================================================================

func _mark_terminal07() -> void:
	var t07_pos := Vector3(-6.5, 1.6, 8.0)

	# Amber glow pillar above the desk
	var marker := MeshInstance3D.new()
	marker.name = "Terminal07_Marker"
	marker.position = t07_pos + Vector3(0, 0.8, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.08, 1.6, 0.08)
	marker.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ff8800")
	mat.emission_enabled = true
	mat.emission = Color("ff8800")
	mat.emission_energy_multiplier = 3.0
	marker.material_override = mat
	add_child(marker)
	_cafe_interior_nodes.append(marker)

	# "TERMINAL #07" floating text substitute (thin horizontal bar)
	var label_bar := MeshInstance3D.new()
	label_bar.name = "Terminal07_LabelBar"
	label_bar.position = t07_pos + Vector3(0, 2.2, 0)
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(1.6, 0.22, 0.04)
	label_bar.mesh = bm2
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = Color("ff8800")
	mat2.emission_enabled = true
	mat2.emission = Color("ff8800")
	mat2.emission_energy_multiplier = 2.5
	label_bar.material_override = mat2
	add_child(label_bar)
	_cafe_interior_nodes.append(label_bar)

	# Amber point light
	_add_point_light(t07_pos + Vector3(0, 1.5, 0), Color("ff8800"), 1.8, 5.0)

	# Register Terminal #07 as an interactable using the correct signature
	register_interactable(
		t07_pos,
		3.5,
		"Terminal #07 — [Enter Final Level?]",
		[
			"[TERMINAL #07] WARRIOR'S FURY — Final Level loaded. Press YES to enter the simulation.",
			"[TERMINAL #07] Session status: ACTIVE. Player 07 identified. Awaiting confirmation."
		]
	)

# =============================================================================
# --- INTERACTABLE CALLBACK OVERRIDE ---
# =============================================================================

func override_interactable_callback(label_key: String, callback: Callable) -> void:
	var key_upper := label_key.to_upper()
	for i in range(interactables.size()):
		var entry: Dictionary = interactables[i]
		var prompt_upper: String = str(entry.get("prompt", "")).to_upper()
		var matched := prompt_upper.contains(key_upper)
		if not matched:
			var fb: Array = entry.get("feedback", [])
			for line in fb:
				if str(line).to_upper().contains(key_upper):
					matched = true
					break
		if matched:
			interactables[i]["callback"] = callback
