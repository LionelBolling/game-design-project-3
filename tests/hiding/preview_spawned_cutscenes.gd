extends SceneTree
## Live F5 integration: first fuse spawns Ronald, real timers/callbacks run
## timeout and catch cutscenes. Only actor/player placement and timer budget
## are arranged; no direct cutscene start, finish(), or manual advance calls.
var game: Node3D

class FocusIndependentGame:
	extends "res://scripts/game.gd"
	func _notification(_what: int) -> void:
		# Keep automated QA running when the user works in another window.
		pass

func _initialize() -> void:
	call_deferred("preview")

func require(condition: bool, label: String) -> bool:
	if condition:
		print("PASS: ", label)
		return true
	push_error("LIVE CUTSCENE CHECK FAILED: " + label)
	game.free()
	quit(1)
	return false

func capture(title: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reviews/" + title + ".png")

func preview() -> void:
	game = load("res://scenes/main.tscn").instantiate() as Node3D
	game.set_script(FocusIndependentGame)
	root.add_child(game)
	current_scene = game
	game.call("start_game")
	game.call("finish_intro")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.player.set_physics_process(false)
	game.player.global_position = Vector3(-16, 0.12, -0.3)
	game.player.camera.look_at(game.world.FUSE_POSITIONS[0])
	await create_timer(0.15).timeout
	prime_flash(game.horror_events)
	game.horror_events.flash_delay = 0.0
	await create_timer(0.05).timeout
	if not require(game.horror_events.flash_count == 0, "No warning GUI before Ronald spawns"):
		return
	var press: InputEventKey = InputEventKey.new()
	press.keycode = KEY_E
	press.physical_keycode = KEY_E
	press.pressed = true
	game.call("_unhandled_input", press)
	if not require(game.fuses == 1 and game.stalker.active and game.stalker.visible, "First-fuse E interaction spawns live Ronald"):
		return
	var spawned_id: int = game.stalker.get_instance_id()
	await create_timer(0.05).timeout
	if not require(game.horror_events.flash_count == 1 and game.horror_events.screen.words == "you better run", "Warning becomes eligible after normal spawn"):
		return
	DirAccess.make_dir_recursive_absolute("res://reviews")
	await capture("live-spawn-warning")
	await create_timer(0.35).timeout
	game.player.global_position = Vector3(13, 0.12, -2.5)
	game.player.rotation = Vector3.ZERO
	game.player.camera.rotation = Vector3.ZERO
	game.player.call("set_flashlight", true)
	await create_timer(0.15).timeout
	game.call("_unhandled_input", press)
	await create_timer(0.6).timeout
	if not require(game.hiding.timer.spot_id != &"", "Real E interaction enters a table"):
		return
	# Accelerate only the test wait; actual HidingSystem expires the budget.
	game.hiding.timer.remaining = 0.15
	game.stalker.global_position = Vector3(13, 0.12, 6.0)
	game.stalker.grace = 0.0
	game.stalker.path.clear()
	game.stalker.path_timer = 0.0
	for frame: int in 80:
		await create_timer(0.025).timeout
		if game.timeout_scene.active:
			break
	if not require(game.timeout_scene.active and game.timeout_scene.camera.current, "Live hide timeout starts its camera cutaway after spawn"):
		return
	await capture("live-timeout-turn")
	var saw_voice: bool = false
	var saw_sprint: bool = false
	var saw_return: bool = false
	var escaped: bool = false
	var escape_mode: bool = OS.get_cmdline_user_args().has("--escape")
	for frame: int in 220:
		await create_timer(0.025).timeout
		if game.timeout_scene.stage == &"voice" and not saw_voice:
			saw_voice = true
			await capture("live-timeout-voice")
		if game.timeout_scene.stage == &"sprint" and not saw_sprint:
			if not require(game.timeout_scene.camera_locked and game.timeout_scene.camera.current and not game.player.control_enabled, "Camera briefly shows Ronald starting his run"):
				return
			saw_sprint = true
		if game.timeout_scene.stage == &"sprint" and not game.timeout_scene.camera_locked and not saw_return:
			if not require(game.player.control_enabled and game.player.camera.current and not game.timeout_scene.camera_locked, "Player view and control return while Ronald is still running"):
				return
			saw_return = true
			if escape_mode and not escaped:
				escaped = true
				var original_target: Vector3 = game.stalker.cinematic_target
				game.call("_unhandled_input", press)
				await create_timer(0.08).timeout
				if not require(not game.player.hiding_locked, "E can leave the table during Ronald's approach"):
					return
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				game.player.rotation = Vector3.ZERO
				game.player.camera.rotation = Vector3.ZERO
				var before: Vector3 = game.player.global_position
				game.player.set_physics_process(true)
				Input.action_press("move_forward")
				await create_timer(0.25).timeout
				Input.action_release("move_forward")
				game.player.set_physics_process(false)
				if not require(game.player.global_position.distance_to(before) > 0.1 and game.timeout_scene.active and game.stalker.cinematic_sprinting, "Player can actually move away while Ronald continues running"):
					return
				if not require(game.stalker.cinematic_target == original_target, "Ronald keeps running to the original spotted area"):
					return
		if not game.timeout_scene.active:
			break
	if not require(saw_voice and saw_sprint and game.player.camera.current and game.player.control_enabled, "Live turn/voice/sprint returns player camera and control"):
		return
	var target: Vector3 = game.stalker.cinematic_target
	var remaining: Vector2 = Vector2(target.x - game.stalker.global_position.x, target.z - game.stalker.global_position.z)
	if remaining.length() > TimeoutCutscene.ARRIVAL_DISTANCE:
		print("SPRINT DEBUG phase=", game.phase, " paused=", paused, " active=", game.timeout_scene.active, " stage=", game.timeout_scene.stage, " target=", target, " actor=", game.stalker.global_position, " remaining=", remaining.length())
	if not require(remaining.length() <= TimeoutCutscene.ARRIVAL_DISTANCE, "Sprint reaches the actual spotted table area before returning control"):
		return
	if not require(not game.stalker.cinematic_sprinting and is_equal_approx(game.stalker.movement_speed(false), 3.3), "Sprint boost ends with the cutaway"):
		return
	await capture("live-player-view-returned")
	if escape_mode:
		if not require(escaped and game.phase == "play", "Escape remains playable after Ronald reaches the area"):
			return
		print("LIVE TIMEOUT ESCAPE PASSED: old voice, early camera/control return, real E exit, real movement during approach, original destination reached.")
		game.free()
		quit()
		return
	for frame: int in 140:
		await create_timer(0.02).timeout
		if game.phase == "caught":
			break
	if not require(game.phase == "caught" and game.catch_scene.active, "Live spawned Ronald catches timed-out table player and starts leap"):
		return
	if not require(game.catch_scene.actor.get_instance_id() == spawned_id and not game.horror_events.screen.visible, "Catch uses the spawned actor with no warning GUI"):
		return
	await create_timer(0.2).timeout
	await capture("live-catch-leap")
	await create_timer(0.4).timeout
	if not require(game.catch_scene.head_position().distance_to(game.catch_scene.camera.global_position) < 0.5, "Live Ronald head reaches the lens"):
		return
	await capture("live-catch-face")
	await create_timer(0.85).timeout
	if not require(game.phase == "dead" and not game.catch_scene.active, "Death screen appears after live leap completes"):
		return
	await capture("live-after-catch")
	print("LIVE SPAWNED CUTSCENES PASSED: first-fuse spawn, timed warning, timeout turn/voice/sprint/return, actual catch leap, face close-up, death screen.")
	game.free()
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
