extends Node3D
## Lightweight Neo-Eden security unit: raycast-damageable, pursues Player 07, and deals contact damage.

@export var max_health: int = 68
@export var move_speed: float = 1.65
@export var contact_damage: int = 8

var health: int = 68
var _player: CharacterBody3D
var _attack_cooldown: float = 0.0
var _visual_root: Node3D

func _ready() -> void:
	add_to_group("simulation_enemy")
	health = max_health
	_player = get_tree().get_first_node_in_group("player_character") as CharacterBody3D
	_make_hit_area()
	_make_visual()

func _make_hit_area() -> void:
	var area := Area3D.new()
	area.name = "DamageTarget"
	area.collision_layer = 4
	area.collision_mask = 0
	add_child(area)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.48
	capsule.height = 1.9
	collision.shape = capsule
	collision.position.y = 0.95
	area.add_child(collision)

func _make_visual() -> void:
	var asset_path := "res://robot/robot_police_unit_animated.glb"
	if ResourceLoader.exists(asset_path):
		var packed := load(asset_path) as PackedScene
		if packed != null:
			_visual_root = packed.instantiate() as Node3D
	if _visual_root == null:
		_visual_root = _make_fallback_character()
	_visual_root.name = "SecurityUnitVisual"
	_visual_root.scale = Vector3.ONE * 0.42
	add_child(_visual_root)
	_play_animation(_visual_root)

func _make_fallback_character() -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var torso := BoxMesh.new()
	torso.size = Vector3(0.72, 1.0, 0.42)
	body.mesh = torso
	body.position.y = 1.05
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color("111522")
	body_mat.metallic = 0.7
	body_mat.emission_enabled = true
	body_mat.emission = Color("7a123d")
	body_mat.emission_energy_multiplier = 1.2
	body.material_override = body_mat
	root.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	head.mesh = head_mesh
	head.position.y = 1.75
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color("20263a")
	head_mat.metallic = 0.75
	head.material_override = head_mat
	root.add_child(head)
	var eye := MeshInstance3D.new()
	var eye_mesh := BoxMesh.new()
	eye_mesh.size = Vector3(0.32, 0.07, 0.06)
	eye.mesh = eye_mesh
	eye.position = Vector3(0, 1.78, -0.27)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color("ff3355")
	eye_mat.emission_enabled = true
	eye_mat.emission = Color("ff0033")
	eye_mat.emission_energy_multiplier = 3.0
	eye.material_override = eye_mat
	root.add_child(eye)
	return root

func _play_animation(node: Node) -> void:
	if node is AnimationPlayer:
		var animator := node as AnimationPlayer
		var clips := animator.get_animation_list()
		for clip in clips:
			if String(clip).to_lower().contains("idle"):
				animator.play(clip)
				return
		if not clips.is_empty():
			animator.play(clips[0])
			return
	for child in node.get_children():
		_play_animation(child)

func take_damage(amount: int) -> void:
	if not is_visible_in_tree():
		return
	health -= amount
	if health <= 0:
		queue_free()
		return
	# Brief hit feedback while keeping the enemy inside the same arena lane.
	var old_y := position.y
	position.y = old_y + 0.08

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player_character") as CharacterBody3D
		if _player == null:
			return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var toward := _player.global_position - global_position
	toward.y = 0.0
	var distance := toward.length()
	if distance > 1.55:
		var direction := toward.normalized()
		global_position += direction * move_speed * delta
		look_at(Vector3(_player.global_position.x, global_position.y, _player.global_position.z), Vector3.UP)
	elif _attack_cooldown <= 0.0:
		if _player.has_method("take_damage"):
			_player.call("take_damage", contact_damage)
		_attack_cooldown = 1.1
