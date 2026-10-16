extends SceneTree

func _initialize() -> void:
	call_deferred("preview")

func capture_sheet(sheet: Image, index: int) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	shot.convert(Image.FORMAT_RGB8)
	shot.resize(384, 216)
	sheet.blit_rect(shot, Rect2i(0, 0, 384, 216), Vector2i((index % 3) * 384, (index / 3) * 216))

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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var label: Label = Label.new()
	label.position = Vector2(460, 145)
	label.add_theme_font_size_override("font_size", 24)
	game.hud.add_child(label)
	var approaches: Image = Image.create(1152, 1080, false, Image.FORMAT_RGB8)
	var hidden: Image = Image.create(1152, 1080, false, Image.FORMAT_RGB8)
	var index: int = 0
	for node: Node in get_nodes_in_group(HideSpot.GROUP):
		var spot: HideSpot = node as HideSpot
		var outward: Vector3 = Vector3.FORWARD if spot.display_name == "booth table" else Vector3.BACK
		label.text = "%02d / %s" % [index + 1, spot.display_name]
		game.player.global_position = spot.hiding_position() + outward * 2.3
		game.player.rotation = Vector3.ZERO
		game.player.camera.rotation = Vector3.ZERO
		game.player.camera.look_at(spot.hiding_position() + Vector3.UP * 0.8)
		await create_timer(0.08).timeout
		game.call("_physics_process", 0.0)
		spot.markers_enabled = true
		await capture_sheet(approaches, index)
		game.player.global_position = spot.hiding_position() + outward
		game.player.rotation = Vector3.ZERO
		game.player.camera.rotation = Vector3.ZERO
		if spot.display_name == "booth table":
			game.player.rotation.y = PI
		await create_timer(0.07).timeout
		assert(game.hiding._nearby_spot() == spot, "Every actual zone must be reachable")
		game.hiding.interact_requested = true
		game.hiding_director.step(0.5)
		assert(game.hiding.timer.spot_id == spot.spot_id)
		game.call("_physics_process", 0.0)
		await capture_sheet(hidden, index)
		game.hiding.interact_requested = true
		game.hiding_director.step(0.0)
		game.hiding_director.step(14.0)
		index += 1
	DirAccess.make_dir_recursive_absolute("res://reviews")
	approaches.save_png("res://reviews/hiding-approaches.png")
	hidden.save_png("res://reviews/hiding-camera-views.png")
	print("HIDING COVERAGE PREVIEW PASSED: ", index, " marked spots, enter/exit and camera views captured.")
	game.free()
	quit()
