extends SceneTree

var game: Node3D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1

func frames(count: int) -> void:
	for i in count:
		await process_frame

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames(3)
	game.hud.show_menu("options_home")
	check(game.hud.options_panel.find_children("*", "Button", true, false).any(func(button: Button) -> bool: return button.text == "SKIP TO ACT 1.5"), "Options offer an Act 1.5 skip")
	game.hud.show_menu("home")
	game.phase = "play"
	game.player.control_enabled = true
	game.player.position = Vector3(0, 0.12, -13)
	await frames(5)
	check(game.phase == "play", "Ball pit cannot sink before Act 1 completion")
	game.power_on = true
	await frames(5)
	check(game.phase == "loading" and game.loading_to == "depth", "Power activates pit transition")
	await create_timer(2.8).timeout
	check(game.phase == "depth" and game.player.control_enabled, "Act 1.5 loads and movement resumes")
	check(is_equal_approx(game.world.RIGHT - game.world.LEFT, 31.0) and is_equal_approx(game.world.FRONT - game.world.BACK, 14.5) and is_equal_approx(game.world.DEPTH, 56.0), "Deep pit matches footprint and fifty player heights")
	var near_ball: Vector3 = game.world.ball_origins[1000]
	var before_ball: Vector3 = game.world.ball_positions[1000]
	game.player.position = near_ball + Vector3(0.15, 0, 0)
	game.player.velocity = Vector3(2, 0, 0)
	game.world._animate_balls(0.2)
	check(game.world.ball_positions[1000].distance_to(before_ball) > 0.01, "Nearby deep-pit balls move when player passes through")
	game.player.position = Vector3(0, -0.8, -13.2)
	game.player.velocity = Vector3.ZERO
	var initial_green_light: float = game.world.tube_light.light_energy
	game.player.position = Vector3(0, -56.3, -13)
	await frames(3)
	check(game.depth_loops == 1 and game.player.position.y > -2, "Deep pit wraps from bottom to top")
	check(game.world.tube_light.light_energy > initial_green_light + 0.3, "Green tube light brightens after each loop")
	game.player.position = Vector3(-13.0, -52.5, -17.0)
	await frames(3)
	check(game.phase == "loading" and game.loading_to == "maze", "Green side tube begins animated maze loading")
	await create_timer(2.8).timeout
	check(game.phase == "maze" and game.player.control_enabled, "Tube maze loads and movement resumes")
	check(game.world.source_count > 600 and game.world.batch_count < 300, "Supplied tube maze is imported and batched")
	var ray := PhysicsRayQueryParameters3D.create(Vector3(30.8, 7.0, -24.0), Vector3(30.8, 3.0, -24.0), 1)
	var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.position.y > 4.0, "Tube interior has supporting collision")
	game.player.position = game.world.CLIMB
	game._interact_maze()
	check(game.player.position.y > 4.0, "Entrance climb reaches elevated tubes")
	game.player.rotation.y = 0.0
	var upper_start: Vector3 = game.player.position
	Input.action_press("move_forward")
	await frames(60)
	Input.action_release("move_forward")
	check(game.player.position.z < upper_start.z - 0.8 and game.player.position.y > 3.8, "Player walks through the elevated entrance tube")
	for color in ["red", "blue", "yellow", "green"]:
		game.player.position = game.world.key_nodes[color].global_position
		game._interact_maze()
		check(game.world.keys[color], "%s key can be collected" % color)
		game.player.position = game.world.doors[color].global_position
		game._interact_maze()
		check(not game.world.doors[color].visible, "%s key opens matching door" % color)
		game.player.position = game.world.lever_nodes[color].global_position
		game._interact_maze()
		check(game.world.levers[color] and game.world.indicators[color].light_energy > 0, "%s lever lights its circuit and door" % color)
	check(not game.world.final_open, "Final door stays closed without black circuit")
	game.player.position = game.world.key_nodes.black.global_position
	game._interact_maze()
	check(game.world.keys.black, "Black key can be collected")
	game.player.position = game.world.find_child("Cabinet_Black_Lock", true, false).global_position
	game._interact_maze()
	check(game.world.levers.black and game.world.final_open, "Circle lock activates fifth circuit and opens final door")
	game.player.position = game.world.find_child("Final_Exit_Door", true, false).global_position
	game._interact_maze()
	check(game.phase == "won", "Opened final door completes Act 2")
	game.restart()
	await frames(5)
	game = current_scene
	game.hud.show_menu("options_home")
	for button in game.hud.options_panel.find_children("*", "Button", true, false):
		if button.text == "SKIP TO ACT 1.5":
			button.pressed.emit()
			break
	check(game.phase == "loading" and game.loading_to == "depth", "Options skip starts the Act 1.5 transition")
	await create_timer(2.8).timeout
	check(game.phase == "depth" and game.player.control_enabled, "Options skip restores player control in Act 1.5")
	print("ACTS RESULT: ", failures, " failures")
	quit(1 if failures else 0)
