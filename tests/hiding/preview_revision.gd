extends SceneTree
## Deterministic graphical QA: render the actual F5 hiding view and moving actor.
func _initialize() -> void:
	call_deferred("preview")

func preview() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(game)
	game.call("start_game")
	game.call("finish_intro")
	game.set_process(false)
	game.set_physics_process(false)
	var player: CharacterBody3D = game.get("player") as CharacterBody3D
	player.set_physics_process(false)
	var ronald: Node3D = game.get("stalker") as Node3D
	ronald.set_physics_process(false)
	player.global_position = Vector3(13, 0.12, -2.5)
	player.rotation = Vector3.ZERO
	await create_timer(0.15).timeout
	var hiding: HidingSystem = game.get("hiding") as HidingSystem
	hiding.interact_requested = true
	var director: Director = game.get("hiding_director") as Director
	director.step(0.5)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var mouse: InputEventMouseMotion = InputEventMouseMotion.new()
	mouse.relative = Vector2(100, 80)
	player.call("_unhandled_input", mouse)
	assert(not is_equal_approx(player.rotation.y, PI), "Real mouse input must turn while hiding")
	assert(player.camera.rotation.x == 0.0, "Real mouse input must keep table pitch level")
	player.rotation.y = PI
	game.hud.lens_material.set_shader_parameter("danger", 0.0)
	game.hiding.hud.show()
	DirAccess.make_dir_recursive_absolute("res://reviews")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/table-view.png")
	player.call("set_flashlight", false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/table-view-no-flashlight.png")
	player.call("set_flashlight", true)
	ronald.global_position = player.global_position + Vector3(0, 0, 4.0)
	ronald.look_at(player.global_position)
	ronald.visible = true
	ronald.call("update_locomotion", 0.33, 0.1)
	var animation: AnimationPlayer = ronald.get("animation") as AnimationPlayer
	animation.advance(0.16)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/table-ronald-running.png")
	var feedback: HorrorFeedback = game.get("horror_feedback") as HorrorFeedback
	feedback.observe(true, true)
	await create_timer(2.0).timeout
	feedback.stop()
	player.call("set_flashlight", false)
	director.step(7.0)
	ronald.global_position = Vector3(13, 0.12, -0.5)
	ronald.set("active", true)
	ronald.set("grace", 0.0)
	for frame: int in 100:
		ronald.call("_physics_process", 0.1)
		if game.get("phase") == "caught":
			break
	assert(game.get("phase") == "caught", "Ronald must catch a timed-out table player via actual navigation")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/table-timeout-caught.png")
	print("REVISION PREVIEW complete; screenshots in reviews/; camera ", player.camera.global_position)
	game.free()
	quit()
