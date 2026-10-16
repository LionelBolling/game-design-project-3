extends SceneTree

var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reviews/" + name + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reviews"))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.4).timeout
	game.hud.show_menu("options_home")
	await capture("act-options")
	game.skip_to_depth()
	await create_timer(0.4).timeout
	await capture("act-depth-start")
	await create_timer(0.5).timeout
	await capture("act-depth-sinking")
	await create_timer(0.5).timeout
	await capture("act-depth-swap")
	await create_timer(2.8).timeout
	game.player.position = Vector3(-6, -49, -17)
	game.player.camera.look_at(Vector3(-14.1, -52.6, -17))
	game.player.pitch = game.player.camera.rotation.x
	await create_timer(0.2).timeout
	await capture("act-depth")
	game.depth_loops = 3
	await create_timer(0.1).timeout
	await capture("act-depth-bright")
	game.player.position = Vector3(-13.0, -52.5, -17.0)
	game._start_loading("maze")
	await create_timer(1.0).timeout
	await capture("act-maze-shark")
	await create_timer(3.6).timeout
	await capture("act-maze-leviathan")
	await create_timer(0.85).timeout
	await capture("act-maze-ball")
	await create_timer(1.05).timeout
	await capture("act-maze-getup")
	await create_timer(1.35).timeout
	await capture("act-maze-entry")
	game.player.position = game.world.UPPER_ENTRY
	game.player.rotation.y = 0.0
	game.player.pitch = 0.0
	game.player.camera.rotation = Vector3.ZERO
	await capture("act-maze-tube")
	var red_key := game.world.key_nodes.red as Node3D
	game.player.position = red_key.global_position + Vector3(0, -0.98, 1.5)
	game.player.camera.look_at(red_key.global_position)
	await capture("act-maze-key-model")
	var red_lever := game.world.lever_nodes.red as Node3D
	game.player.position = red_lever.global_position + red_lever.global_basis.z * 1.25 + Vector3(0, -0.6, 0)
	game.player.camera.look_at(red_lever.global_position + Vector3(0, 0.4, 0))
	await capture("act-maze-lever-model")
	var red_door := game.world.doors.red as Node3D
	game.player.position = red_door.global_position + Vector3(0, -0.98, 2.3)
	game.player.camera.look_at(red_door.global_position)
	await capture("act-maze-wall-keyhole")
	var overhead := Camera3D.new()
	overhead.projection = Camera3D.PROJECTION_ORTHOGONAL
	overhead.size = 105.0
	overhead.far = 150.0
	overhead.position = Vector3(0, 75, 0)
	game.add_child(overhead)
	overhead.look_at(Vector3.ZERO, Vector3(0, 0, -1))
	overhead.current = true
	await capture("act-maze-overhead")
	quit()
