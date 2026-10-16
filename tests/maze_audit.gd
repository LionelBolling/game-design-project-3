extends SceneTree

const Maze = preload("res://scripts/tube_maze.gd")

var maze: Node3D
var components := {}

func _initialize() -> void:
	call_deferred("run")

func _cell(at: Vector3) -> Vector2i:
	return Vector2i(roundi((at.x - maze.GRID_MIN.x) / maze.GRID), roundi((at.z - maze.GRID_MIN.y) / maze.GRID))

func run() -> void:
	maze = Node3D.new()
	maze.set_script(Maze)
	root.add_child(maze)
	await physics_frame
	var component := 0
	for start in maze.corridor_cells:
		if components.has(start):
			continue
		component += 1
		var queue: Array[Vector2i] = [start]
		components[start] = component
		var index := 0
		while index < queue.size():
			var current := queue[index]
			index += 1
			for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = current + direction
				if not maze.corridor_cells.has(next) or components.has(next):
					continue
				components[next] = component
				queue.append(next)
	var ok: bool = component == 1 and components.size() == maze.corridor_cells.size()
	for at in [Maze.UPPER_ENTRY, Vector3(0, 4.3, 5.7)]:
		ok = ok and components.get(_cell(at), 0) == 1
	for color in ["red", "blue", "yellow", "green", "black"]:
		var key := maze.key_nodes[color] as Node3D
		ok = ok and components.get(_cell(key.global_position), 0) == 1
		var lever := maze.lever_nodes[color] as Node3D
		ok = ok and components.get(_cell(lever.global_position), 0) == 1
		if color != "black":
			var door := maze.doors[color] as Node3D
			ok = ok and components.get(_cell(door.global_position), 0) == 1
	print(("PASS " if ok else "FAIL ") + "Entire tube floor, keys, doors, levers, and circle form one connected layout")
	quit(0 if ok else 1)
