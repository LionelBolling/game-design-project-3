extends SceneTree

const Maze = preload("res://scripts/tube_maze.gd")
const Centipede = preload("res://scripts/maze_centipede.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var failures := 0
	var maze := Node3D.new()
	maze.set_script(Maze)
	root.add_child(maze)
	var crawler := Node3D.new()
	crawler.set_script(Centipede)
	root.add_child(crawler)
	crawler.maze = maze
	crawler._build_navigation()
	var unzoned := 0
	for cell in maze.corridor_cells:
		unzoned += int(not maze.corridor_zones.has(cell))
	var labeled: bool = unzoned == 0
	print(("PASS " if labeled else "FAIL ") + "Every walkable cell belongs to a highlighted route zone (unassigned: %d)" % unzoned)
	failures += int(not labeled)
	var beyond := {"green": Vector2.RIGHT, "red": Vector2.UP, "blue": Vector2.RIGHT, "yellow": Vector2.DOWN}
	for color in beyond:
		var door: Node3D = maze.doors[color]
		var door_point := Vector2(door.global_position.x, door.global_position.z)
		var target_zone: int = maze._zone_behind_door(door_point, beyond[color])
		var vents := 0
		for spot in maze.hide_spots:
			if spot.get_meta("door_color", "") != color:
				continue
			var cell := Vector2i(roundi((spot.position.x - maze.GRID_MIN.x) / maze.GRID), roundi((spot.position.z - maze.GRID_MIN.y) / maze.GRID))
			var valid: bool = spot.find_child("VentModel", false, false) != null and int(maze.corridor_zones.get(cell, -1)) == target_zone and Vector2(spot.position.x, spot.position.z).distance_to(door_point) > 4.0
			vents += int(valid)
		var enough := vents >= 2
		print(("PASS " if enough else "FAIL ") + "%s door has at least two reachable vent hide spots behind it (%d)" % [color, vents])
		failures += int(not enough)
	var start: Vector2i = crawler._nearest_open(crawler._cell(maze.SPAWN))
	for color in ["red", "blue", "yellow", "green"]:
		var key: Node3D = maze.key_nodes[color]
		var finish: Vector2i = crawler._nearest_open(crawler._cell(key.global_position))
		var route: Array[Vector2i] = crawler.nav.get_id_path(start, finish)
		var expected: bool = color == "green"
		var ok: bool = (not route.is_empty()) == expected
		print(("PASS " if ok else "FAIL ") + "%s key follows locked doors for centipede navigation" % color)
		failures += int(not ok)
	for color in ["red", "blue", "yellow", "green"]:
		(maze.doors[color] as Node3D).hide()
	crawler._update_gates()
	for color in ["red", "blue", "yellow", "green", "black"]:
		var key: Node3D = maze.key_nodes[color]
		var finish: Vector2i = crawler._nearest_open(crawler._cell(key.global_position))
		var route: Array[Vector2i] = crawler.nav.get_id_path(start, finish)
		var ok: bool = not route.is_empty()
		print(("PASS " if ok else "FAIL ") + "%s key has an open route for the centipede" % color)
		failures += int(not ok)
	print("GATE AUDIT RESULT: ", failures, " failures")
	quit(1 if failures else 0)
