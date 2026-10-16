extends SceneTree
## Live first-fuse spawn -> actual continuous beam -> pounce -> Space QTE.
## Runs a real input success and a no-input failure without directly starting
## or advancing grapple cutscenes.
var game: Node3D

func _initialize() -> void:
	call_deferred("preview")

func require(condition: bool, label: String) -> bool:
	if condition:
		print("PASS: ", label)
		return true
	push_error("GRAPPLE PREVIEW FAILED: " + label)
	game.free()
	quit(1)
	return false

func capture(title: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reviews/" + title + ".png")

func press_space() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func scenario(success: bool) -> bool:
	game = load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(game)
	current_scene = game
	game.call("start_game")
	game.call("finish_intro")
	game.player.set_physics_process(false)
	game.player.global_position = Vector3(-16, 0.12, -0.3)
	game.player.camera.look_at(game.world.FUSE_POSITIONS[0])
	await create_timer(0.15).timeout
	game.call("interact")
	if not require(game.fuses == 1 and game.stalker.active, "First fuse spawns Ronald"):
		return false
	game.player.global_position = Vector3(13, 0.12, -0.5)
	game.player.rotation = Vector3.ZERO
	game.stalker.global_position = Vector3(13, 0.12, -6.0)
	game.stalker.grace = 0.0
	game.stalker.reset_light_attack()
	game.player.camera.look_at(game.stalker.global_position + Vector3.UP * 1.55)
	game.player.call("set_flashlight", true)
	# Keep the QA aim fixed against operating-system mouse motion. Gameplay
	# still uses the real beam query and a real six-second physics charge.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not require(game.player.beam_hits(game.stalker.global_position + Vector3.UP * 1.55), "Actual flashlight ray reaches Ronald's face"):
		return false
	if success:
		prime_flash(game.horror_events)
		game.horror_events.flash_delay = 0.0
		await create_timer(0.1).timeout
		if not require(game.horror_events.flash_scream_count == 1 and game.horror_events.flash_delay > 12.0, "Successful flash roll screams and resets the 13-second interval"):
			return false
		await capture("rare-warning-scream")
	for frame: int in 480:
		await physics_frame
		if game.phase == "play":
			game.player.camera.look_at(game.stalker.global_position + Vector3.UP * 1.55)
		if game.phase == "grapple":
			break
	if game.phase != "grapple":
		print("BEAM DEBUG phase=", game.phase, " paused=", paused, " active=", game.stalker.active, " frozen=", game.stalker.frozen, " exposure=", game.stalker.beam_exposure, " hidden=", game.player.hiding_locked, " control=", game.player.control_enabled, " query=", game.player.beam_hits(game.stalker.global_position + Vector3.UP * 1.55), " grace=", game.stalker.grace, " player=", game.player.global_position, " actor=", game.stalker.global_position)
	if not require(game.phase == "grapple" and game.horror_events.attack_scream_count == 1, "Six-second continuous face beam triggers live pounce and scream"):
		return false
	await create_timer(0.2).timeout
	await capture("grapple-leap-win" if success else "grapple-leap-fail")
	for frame: int in 100:
		await create_timer(0.02).timeout
		if game.grapple_scene.stage == &"struggle":
			break
	if not require(game.grapple_scene.stage == &"struggle" and not game.player.control_enabled, "Ronald pins the player with a Space prompt"):
		return false
	await capture("grapple-pinned-win" if success else "grapple-pinned-fail")
	if success:
		var paused_time: float = game.grapple_scene.time_left
		game.call("pause_game", true)
		await create_timer(0.2).timeout
		if not require(is_equal_approx(game.grapple_scene.time_left, paused_time) and not game.grapple_scene.hud.visible, "Pause freezes struggle time and keeps pause menu clear"):
			return false
		game.call("pause_game", false)
		for index: int in 12:
			await press_space()
		if not require(game.grapple_scene.stage == &"push", "Twelve real Space press/release inputs win the QTE"):
			return false
		await capture("grapple-push-off")
		for frame: int in 90:
			await create_timer(0.02).timeout
			if game.phase == "play":
				break
		if not require(game.phase == "play" and game.player.control_enabled and game.player.camera.current and game.stalker.grace > 2.5, "Win restores control/view and three-second escape window"):
			return false
		if not require(game.player.flashlight_on and game.player.lamp.visible and game.player.spill.visible, "Escaping restores the charged flashlight and both lights"):
			return false
		game.player.set_physics_process(true)
		var toggle: InputEventAction = InputEventAction.new()
		toggle.action = &"flashlight"
		toggle.pressed = true
		game.player.call("_unhandled_input", toggle)
		if not require(not game.player.flashlight_on, "Flashlight input can toggle off after escape"):
			return false
		await create_timer(0.35).timeout
		game.player.call("_unhandled_input", toggle)
		if not require(game.player.flashlight_on and game.player.lamp.visible, "Flashlight input can turn it back on after escape"):
			return false
		var from: Vector3 = game.player.global_position
		game.player.set_physics_process(true)
		Input.action_press("move_back")
		await create_timer(0.2).timeout
		Input.action_release("move_back")
		if not require(game.player.global_position.distance_to(from) > 0.1 and game.phase == "play", "Player can actually move away after pushing him off"):
			return false
		await capture("grapple-escaped")
	else:
		for frame: int in 240:
			await create_timer(0.02).timeout
			if game.grapple_scene.stage == &"bite":
				break
		if game.grapple_scene.stage != &"bite":
			print("QTE DEBUG phase=", game.phase, " stage=", game.grapple_scene.stage, " paused=", paused, " time=", game.grapple_scene.time_left, " presses=", game.grapple_scene.presses)
		if not require(game.grapple_scene.stage == &"bite" and game.phase == "grapple", "No mashing starts the bite cutscene before death"):
			return false
		await create_timer(0.45).timeout
		await capture("grapple-bite")
		await create_timer(0.8).timeout
		if not require(game.phase == "dead" and not game.player.control_enabled, "Bite ends in death"):
			return false
		await capture("grapple-bite-death")
	current_scene = null
	game.free()
	return true

func preview() -> void:
	DirAccess.make_dir_recursive_absolute("res://reviews")
	if not await scenario(true):
		return
	if not await scenario(false):
		return
	print("LIVE GRAPPLE PASSED: normal spawn, actual face beam, pounce, pin, pause, real Space win/escape, no-input bite/death.")
	quit()


func prime_flash(events: HorrorEvents) -> void:
	var trial: RandomNumberGenerator = RandomNumberGenerator.new()
	var seed_value: int = 0
	while true:
		trial.seed = seed_value
		if trial.randf() < HorrorEvents.FLASH_CHANCE:
			events._rng.seed = seed_value
			return
		seed_value += 1
