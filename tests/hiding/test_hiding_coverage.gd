extends GutTest

func test_every_furniture_spot_can_enter_with_clear_camera_and_exit() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate() as Node3D
	add_child_autofree(game)
	game.call("start_game")
	game.call("finish_intro")
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.stalker.set_physics_process(false)
	var spots: Array[Node] = get_tree().get_nodes_in_group(HideSpot.GROUP)
	assert_eq(spots.size(), 15)
	for node: Node in spots:
		var spot: HideSpot = node as HideSpot
		var reach: float = 1.0 if spot.display_name == "prep counter" else 1.4
		var outward: Vector3 = Vector3.FORWARD if spot.display_name == "booth table" else Vector3.BACK
		var approach: Vector3 = spot.hiding_position() + outward * reach
		game.player.global_position = approach
		await wait_seconds(0.06)
		assert_eq(game.hiding._nearby_spot(), spot, "Spot reachable from its open side: %s" % spot.spot_id)
		game.hiding.interact_requested = true
		game.hiding_director.step(0.5)
		assert_eq(game.hiding.timer.spot_id, spot.spot_id)
		assert_not_null(spot.marker)
		assert_eq(game.player.camera.rotation.x, 0.0)
		var eye: Vector3 = game.player.camera.global_position
		for bounds: AABB in game.world.obstacles:
			assert_false(bounds.grow(0.025).has_point(eye), "%s camera clear of %s" % [spot.spot_id, bounds])
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(eye, eye + outward * 1.5, 1)
		assert_true(game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "%s faces a clear view" % spot.spot_id)
		var target: Vector3 = game.stalker.table_approach_target()
		var route: PackedVector2Array = game.world.route(game.stalker.global_position, target)
		assert_false(route.is_empty(), "%s has a navigation path" % spot.spot_id)
		if not route.is_empty():
			assert_lte(route[-1].distance_to(Vector2(target.x, target.z)), 0.6, "%s approach is on reachable floor" % spot.spot_id)
		var reach_ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(target + Vector3.UP * 0.28, game.player.global_position + Vector3.UP * 0.28, 1)
		assert_true(game.get_world_3d().direct_space_state.intersect_ray(reach_ray).is_empty(), "%s has a reachable grab side" % spot.spot_id)
		game.hiding.interact_requested = true
		game.hiding_director.step(0.0)
		assert_eq(game.player.global_position, approach, "Exit returns to the approach position")
		game.hiding_director.step(14.0)
		if spot.display_name == "dining table":
			game.player.global_position = spot.global_position + Vector3(0, 0, -1.9)
			await wait_seconds(0.06)
			assert_eq(game.hiding._nearby_spot(), spot, "The opposite side must work despite the central pedestal: %s" % spot.spot_id)
			game.hiding.interact_requested = true
			game.hiding_director.step(0.5)
			assert_eq(game.hiding.timer.spot_id, spot.spot_id)
			game.hiding.interact_requested = true
			game.hiding_director.step(0.0)
			game.hiding_director.step(14.0)
	var diagnostics: int = 1 if DisplayServer.get_name() == "headless" else 4
	for index: int in diagnostics:
		assert_engine_error('Parameter "material" is null.')
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
