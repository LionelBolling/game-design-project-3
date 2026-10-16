extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.phase = "depth"
	game._start_loading("maze")
	game._swap_to_maze()
	game._finish_loading()
	await physics_frame
	check(game.player.flashlight_on and game.player.hand.visible, "Act 2 starts with the flashlight out and lit")
	check(not game.player.flashlight_uses_battery and not game.player.battery_lights[0].visible, "Act 2 hides and disables flashlight batteries")
	check(game.centipede.position.x > game.world.doors.green.global_position.x, "Centipede starts behind the green door")
	check(game.centipede.state.activation_delay == 60.0 and not game.centipede.state.active, "Centipede waits one minute on first entry")
	var gate_cell: Vector2i = game.centipede._cell(game.world.doors.green.global_position)
	check(game.centipede.nav.is_point_solid(gate_cell), "Centipede navigation blocks the green door")
	var spot: Node3D = game.world.hide_spots[0]
	game.player.position = spot.global_position + Vector3.UP * 0.19
	game._interact_maze()
	check(game.maze_hidden and game.player.movement_locked, "E enters a hiding spot")
	game._interact_maze()
	check(not game.maze_hidden and not game.player.movement_locked, "E leaves a hiding spot")
	game.begin_maze_jumpscare()
	check(game.maze_dying and not game.player.control_enabled, "One centipede hit starts the jumpscare")
	await create_timer(1.1).timeout
	check(Vector2(game.player.position.x, game.player.position.z).distance_to(Vector2(game.world.SPAWN.x, game.world.SPAWN.z)) < 0.01 and game.player.position.y > 4.2 and game.centipede.state.activation_delay == 30.0, "Death restarts Act 2 with a 30 second delay")
	check(game.player.flashlight_on and game.player.hand.visible, "Act 2 restart restores the flashlight")
	check(not game.player.flashlight_uses_battery, "Act 2 restart keeps unlimited flashlight charge")
	print("ACT ENEMY RESULT: ", failures, " failures")
	quit(1 if failures else 0)
