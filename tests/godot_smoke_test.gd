extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_test")

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _run_smoke_test() -> void:
	var failures: Array[String] = []
	var packed := load("res://after-life--session-zero/main.tscn") as PackedScene
	_check(packed != null, "Main scene must load as PackedScene.", failures)
	if packed == null:
		_finish(failures)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var player := scene.get_node_or_null("Player") as CharacterBody3D
	_check(player != null, "Main scene must contain the player CharacterBody3D.", failures)
	var audio := scene.get_node_or_null("AudioManager")
	_check(audio != null, "Main scene must contain AudioManager.", failures)
	var story := scene.get_node_or_null("StoryManager")
	_check(story != null and story.has_method("launch_terminal07"), "Story manager must expose the Terminal 07 interaction.", failures)
	_check(story != null and story.has_method("set_act"), "Story manager must expose story act transitions.", failures)

	if player != null:
		var visual := player.get_node_or_null("PlayerCharacterVisual") as Node3D
		_check(visual != null, "Player GLB visual must be attached.", failures)
		if visual != null:
			_check(not visual.visible, "First-person player mesh must be hidden to prevent camera clipping.", failures)
		if visual != null:
			var animator := _find_animation_player(visual)
			if animator != null and not animator.get_animation_list().is_empty():
				_check(true, "Player animation clips are available.", failures)
			else:
				_check(player.has_method("_update_character_animation"), "Player must provide procedural animation when the GLB has no clips.", failures)
				player.set("_character_anim_time", 0.2)
				var before_y: float = visual.position.y
				player.call("_update_character_animation", true)
				_check(absf(visual.position.y - before_y) > 0.001, "Procedural walking animation must move the player visual.", failures)
		var third_person_camera := player.get_node_or_null("Head/ThirdPersonCamera") as Camera3D
		_check(third_person_camera != null, "Player must have a third-person follow camera.", failures)
		if third_person_camera != null:
			player.call("_set_third_person_view", true)
			_check(visual.visible, "Third-person mode should show the player character.", failures)
			_check(third_person_camera.current, "Third-person mode should activate its camera.", failures)
			player.call("_set_third_person_view", false)
			_check(not visual.visible, "First-person mode should hide the full-body player mesh.", failures)
			_check((player.get_node_or_null("Head/Camera3D") as Camera3D).current, "First-person mode should restore the first-person camera.", failures)
		var player_shape := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
		_check(player_shape != null and player_shape.shape != null, "Player collision shape must be assigned.", failures)

	var floor_shape := scene.get_node_or_null("Floor/StaticBody3D/CollisionShape3D") as CollisionShape3D
	_check(floor_shape != null and floor_shape.shape != null, "Floor collision shape must be assigned.", failures)
	for zone_name in ["TriggerZone_Terminal07", "TriggerZone_NexusStage", "TriggerZone_ExitCafe"]:
		var zone := scene.get_node_or_null(zone_name) as Area3D
		var zone_shape := zone.get_node_or_null("CollisionShape3D") as CollisionShape3D if zone != null else null
		_check(zone_shape != null and zone_shape.shape != null, zone_name + " must have a collision shape.", failures)

	var robot := scene.get_node_or_null("Robot operator")
	_check(robot != null, "Environment must create the robot operator.", failures)
	if robot != null:
		var imported_robot := robot.get_node_or_null("Imported animated robot")
		_check(imported_robot != null, "Animated robot GLB must be attached.", failures)
		if imported_robot != null:
			var robot_animator := _find_animation_player(imported_robot)
			_check(robot_animator != null, "Robot GLB must contain an AnimationPlayer.", failures)
			if robot_animator != null:
				_check(not robot_animator.get_animation_list().is_empty(), "Robot animation list must not be empty.", failures)

	for character_name in ["Cafe guest A", "Cafe guest B", "Cafe guest C"]:
		_check(scene.get_node_or_null(character_name) != null, character_name + " GLB must be attached.", failures)

	if audio != null:
		audio.play_music("suspense")
		var music_player := audio.get_node_or_null("Music") as AudioStreamPlayer
		_check(music_player != null and music_player.stream != null, "Music asset must load into the music player.", failures)
		audio.play_voice_for_speaker("NEXUS-01")
		var dialogue_player := audio.get_node_or_null("Dialogue") as AudioStreamPlayer
		_check(dialogue_player != null and dialogue_player.stream != null, "NEXUS dialogue audio must load.", failures)
		audio.play_sfx("typing")
		var sfx_player := audio.get_node_or_null("SFX") as AudioStreamPlayer
		_check(sfx_player != null and sfx_player.stream != null, "Typing sound effect must load.", failures)

	for path in [
		"res://characters/male3.glb",
		"res://characters/male1.glb",
		"res://characters/female4.glb",
		"res://characters/male4.glb",
		"res://robot/robot_police_unit_animated.glb",
		"res://dialougues/nexus/d1.mp3",
		"res://gameathon music/nastelbom-suspense-suspense-background-623748.mp3"
	]:
		_check(ResourceLoader.exists(path), "Required asset must exist: " + path, failures)

	for _frame in range(5):
		await physics_frame
	if player != null:
		_check(player.is_on_floor(), "Player should settle on the floor collision surface.", failures)

	_finish(failures)

func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("GODOT_SMOKE_TEST: PASS — scene, models, animations, collisions, audio and story hooks verified.")
		quit(0)
	else:
		for failure in failures:
			push_error("GODOT_SMOKE_TEST: " + failure)
		quit(1)
