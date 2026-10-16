extends SceneTree

const Maze = preload("res://scripts/tube_maze.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var maze := Node3D.new()
	maze.set_script(Maze)
	root.add_child(maze)
	await physics_frame
	var fx: Node3D = maze.abyss_fx
	var ok: bool = maze.window_nodes.size() == 3
	for index in maze.window_nodes.size():
		var window: Node3D = maze.window_nodes[index]
		var inside: Vector3 = window.global_position - window.global_basis.z * 1.0
		var outside: Vector3 = window.global_position + window.global_basis.z * 1.0
		var query := PhysicsRayQueryParameters3D.create(inside, outside)
		var hit: Dictionary = root.world_3d.direct_space_state.intersect_ray(query)
		ok = ok and not hit.is_empty()
		ok = ok and (hit.get("collider") as Node).name == "ConnectedTubeWalls"
	for animation_id in range(6):
		fx.start_variant(animation_id % 3, animation_id)
		ok = ok and fx.silhouette.visible and absf(fx.silhouette.position.x) > 1.0
		fx.advance(fx.PASS_DURATION * 0.5)
		ok = ok and fx.silhouette.visible and absf(fx.silhouette.position.x) < 0.2
		fx.advance(fx.PASS_DURATION * 0.51)
		ok = ok and not fx.silhouette.visible and fx.variant == -1
	for animation_id in range(6, 9):
		fx.start_variant(animation_id % 3, animation_id)
		fx.advance(1.0)
		var start_x: float = fx.silhouette.position.x
		fx.advance(3.0)
		ok = ok and fx.silhouette.visible and absf(fx.silhouette.position.x - start_x) < 0.05
		fx.advance(fx.IDLE_DURATION)
		ok = ok and not fx.silhouette.visible and fx.variant == -1
	print(("PASS " if ok else "FAIL ") + "Three sealed abyss windows and nine lightweight leviathan animations")
	quit(0 if ok else 1)
