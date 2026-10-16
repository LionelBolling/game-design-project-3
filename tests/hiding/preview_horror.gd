extends SceneTree
## Deterministic graphical preview of the three requested horror events.
func _initialize() -> void:
	call_deferred("preview")

func preview() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(game)
	game.call("start_game")
	game.call("finish_intro")
	game.set_process(false)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.stalker.set_physics_process(false)
	game.horror_feedback.set_process(false)
	var events: HorrorEvents = game.get("horror_events") as HorrorEvents
	events.set_process(false)
	game.stalker.call("awaken")
	events.ronald_spawned = true
	var camera: Camera3D = game.player.camera
	await create_timer(0.15).timeout
	prime_flash(events)
	events.flash_delay = 0.0
	events.apparition_delay = 100.0
	events.advance(0.01, &"play", camera, false, false)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://reviews")
	root.get_texture().get_image().save_png("res://reviews/random-face-flash.png")
	events.advance(0.4, &"play", camera, false, false)
	game.player.call("set_flashlight", true)
	var found: bool = false
	var chance_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var winning_seed: int = 0
	while true:
		chance_rng.seed = winning_seed
		if chance_rng.randf() < HorrorEvents.APPARITION_CHANCE:
			break
		winning_seed += 1
	for at: Vector3 in [Vector3(13, 0.12, -0.5), Vector3(-25, 0.12, -0.5), Vector3(-9, 0.12, -0.5), Vector3(4, 0.12, 0)]:
		game.player.global_position = at
		game.player.rotation = Vector3.ZERO
		camera.rotation = Vector3.ZERO
		events.clear()
		events.apparition_delay = 0.0
		events._rng.seed = winning_seed
		events.advance(0.01, &"play", camera, true, false)
		assert(not events.entity.visible, "Waiting alone cannot spawn the figure")
		game.player.rotation.y = PI
		events.advance(0.01, &"play", camera, true, false)
		if events.entity.visible:
			found = true
			break
	assert(found, "At least one open diner location must permit the actual apparition clearance query")
	assert(events._visible_to_camera(camera), "Turning around must reveal the apparition")
	events.advance(0.01, &"play", camera, true, false)
	assert(not events.screen.visible, "Apparition no longer triggers warning GUI")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/apparition-triggered-flash.png")
	events.advance(0.3, &"play", camera, true, false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/turn-around-apparition.png")
	var saved_camera: Transform3D = camera.global_transform
	var before_lunge: float = events.entity.global_position.distance_to(camera.global_position)
	events.advance(0.2, &"play", camera, true, false)
	assert(events.entity.global_position.distance_to(camera.global_position) < before_lunge, "Figure jumps toward the screen")
	assert(game.player.control_enabled and camera.current and camera.global_transform == saved_camera, "Lunge leaves player camera and controls alone")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/apparition-lunge-close.png")
	events.advance(0.7, &"play", camera, true, false)
	assert(not events.entity.visible, "Seen apparition must vanish")
	events.set_chase_static(true)
	events.advance(0.1, &"play", camera, false, false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/chase-static.png")
	events.set_chase_static(false)
	game.player.battery = 50.0
	var spares_before: int = game.spare_cells
	game.call("replace_cell")
	assert(game.spare_cells == spares_before - 1 and game.player.battery == 100.0, "R reload consumes one displayed spare")
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/reload-battery-panel.png")
	game.call("finish", false)
	assert(events.scream_count == 1, "Actual catch flow starts one scream")
	assert(not events.screen.visible, "Catch has no warning GUI")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/catch-leap.png")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/catch-face-close.png")
	await create_timer(0.8).timeout
	assert(game.get("phase") == "dead", "3D catch cutscene gives way to the death screen")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/after-jumpscare.png")
	print("HORROR PREVIEW complete: face flash, turn-around reveal/vanish, catch scream, death screen.")
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
