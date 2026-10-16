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
	await create_timer(2.8).timeout
	game.player.position = Vector3(-6, -49, -17)
	game.player.camera.look_at(Vector3(-14.1, -52.6, -17))
	game.player.pitch = game.player.camera.rotation.x
	await capture("act-depth")
	game.depth_loops = 3
	await create_timer(0.1).timeout
	await capture("act-depth-bright")
	game._start_loading("maze")
	await create_timer(1.4).timeout
	await capture("act-maze-loading")
	await create_timer(1.4).timeout
	game.player.position = Vector3(0, 0.15, 28)
	game.player.camera.look_at(Vector3(0, 5, 25))
	game.player.pitch = game.player.camera.rotation.x
	await capture("act-maze-entry")
	quit()
