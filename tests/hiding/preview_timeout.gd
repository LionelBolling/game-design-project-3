extends SceneTree
## Actual F5 leak/camera/turn/voice/sprint/return, captured in real time.
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
	game.horror_events.set_process(false)
	game.horror_feedback.set_process(false)
	game.player.global_position = Vector3(13, 0.12, -2.5)
	game.player.rotation = Vector3.ZERO
	game.player.call("set_flashlight", false)
	game.stalker.global_position = Vector3(13, 0.12, 0.5)
	game.stalker.active = true
	game.stalker.visible = true
	game.stalker.grace = 0.0
	await create_timer(0.15).timeout
	game.hiding.interact_requested = true
	game.hiding_director.step(0.5)
	var saved: Transform3D = game.player.camera.transform
	game.hiding_director.step(7.0)
	game.call("_physics_process", 0.0)
	var scene: TimeoutCutscene = game.get("timeout_scene") as TimeoutCutscene
	assert(scene.active and scene.camera.current)
	DirAccess.make_dir_recursive_absolute("res://reviews")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/timeout-turn-start.png")
	var got_voice: bool = false
	var got_sprint: bool = false
	for frame: int in 200:
		await create_timer(0.03).timeout
		game.call("_physics_process", 0.03)
		game.stalker.call("_physics_process", 0.03)
		if not got_voice and scene.stage == &"voice":
			got_voice = true
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reviews/timeout-i-see-you.png")
		if not got_sprint and scene.stage == &"sprint":
			got_sprint = true
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reviews/timeout-sprint.png")
		if not scene.active:
			break
	assert(got_voice and got_sprint and not scene.active)
	assert(game.player.camera.current and game.player.control_enabled)
	assert(game.player.camera.transform == saved)
	assert(not game.stalker.cinematic_sprinting)
	assert(is_equal_approx(game.stalker.movement_speed(false), 3.3))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/timeout-player-view-restored.png")
	print("TIMEOUT PREVIEW complete: turn, one voice, temporary sprint, player camera/control and normal speed restored.")
	game.free()
	quit()
