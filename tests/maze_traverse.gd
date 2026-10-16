extends SceneTree

const Maze = preload("res://scripts/tube_maze.gd")

var maze: Node3D
var walker: CharacterBody3D
var safe := {}
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func _cell(at: Vector3) -> Vector2i:
	return Vector2i(roundi((at.x - maze.GRID_MIN.x) / maze.GRID), roundi((at.z - maze.GRID_MIN.y) / maze.GRID))

func _point(cell: Vector2i) -> Vector3:
	var point: Vector2 = maze._grid_point(cell)
	return Vector3(point.x, 4.26, point.y)

func _nearest_safe(at: Vector3) -> Vector2i:
	var best := INF
	var result := Vector2i(-999, -999)
	for cell in safe:
		var distance := _point(cell).distance_squared_to(Vector3(at.x, 4.26, at.z))
		if distance < best:
			best = distance
			result = cell
	return result

func _route(start: Vector2i, target: Vector3) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var parent := {start: start}
	var index := 0
	var goal := Vector2i(-999, -999)
	while index < queue.size():
		var cell := queue[index]
		index += 1
		if _point(cell).distance_to(Vector3(target.x, 4.26, target.z)) < 2.2:
			goal = cell
			break
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if not safe.has(next) or parent.has(next):
				continue
			var offset := Vector3(0, 0, 0.26) if direction.x != 0 else Vector3(0.26, 0, 0)
			var blocked := false
			for side in [-1.0, 0.0, 1.0]:
				var ray := PhysicsRayQueryParameters3D.create(_point(cell) + Vector3.UP * 0.8 + offset * side, _point(next) + Vector3.UP * 0.8 + offset * side, 1)
				if not maze.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
					blocked = true
					break
			if blocked:
				continue
			parent[next] = cell
			queue.append(next)
	if goal.x == -999:
		return []
	var route: Array[Vector2i] = [goal]
	while route[-1] != start:
		route.append(parent[route[-1]])
	route.reverse()
	return route

func run() -> void:
	maze = Node3D.new()
	maze.set_script(Maze)
	root.add_child(maze)
	# Check the tube shell using the player's actual capsule size.
	for cell in maze.corridor_cells:
		var clear := true
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				if not maze.corridor_cells.has(cell + Vector2i(dx, dz)):
					clear = false
		if clear:
			safe[cell] = true
	walker = CharacterBody3D.new()
	walker.collision_layer = 2
	walker.collision_mask = 1
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.24
	capsule.height = 1.12
	collider.shape = capsule
	collider.position.y = 0.56
	walker.add_child(collider)
	root.add_child(walker)
	await physics_frame
	var locked_entry := _nearest_safe(Maze.UPPER_ENTRY)
	for color in ["red", "blue", "yellow", "green"]:
		check(not _route(locked_entry, maze.key_nodes[color].global_position).is_empty(), "%s key can be reached with colored doors locked" % color)
		var door := maze.doors[color] as Node3D
		var normal := Vector3.FORWARD if color in ["red", "yellow"] else Vector3.RIGHT
		var ray := PhysicsRayQueryParameters3D.create(door.global_position - normal * 1.5, door.global_position + normal * 1.5, 1)
		var hit := maze.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and hit.collider == maze.door_bodies[color], "%s door blocks its passage" % color)
		var across := Vector3.RIGHT if color in ["red", "yellow"] else Vector3.FORWARD
		for side in [-0.65, 0.65]:
			var sidestep: Vector3 = across * float(side)
			var edge_ray := PhysicsRayQueryParameters3D.create(door.global_position - normal * 1.5 + sidestep, door.global_position + normal * 1.5 + sidestep, 1)
			var edge_hit := maze.get_world_3d().direct_space_state.intersect_ray(edge_ray)
			check(not edge_hit.is_empty() and edge_hit.collider == maze.door_bodies[color], "%s gate cannot be passed at side %.2f" % [color, side])
	var caps := maze.find_children("Collision_Cap_*", "StaticBody3D", false, false)
	check(caps.size() == 22, "Only the 22 marked endpoints have cap collisions")
	for body in maze.door_bodies.values():
		(body as Node).queue_free()
	await physics_frame
	await physics_frame
	var entry := _nearest_safe(Maze.UPPER_ENTRY)
	check(_point(entry).distance_to(Vector3(Maze.UPPER_ENTRY.x, 4.26, Maze.UPPER_ENTRY.z)) < 1.0, "Player-sized entry clearance")
	var destinations: Array[Node3D] = []
	for color in ["red", "blue", "yellow", "green", "black"]:
		destinations.append(maze.key_nodes[color])
		destinations.append(maze.lever_nodes[color])
	destinations.append(maze.find_child("Cabinet_Black_Lock", true, false))
	destinations.append(maze.find_child("Final_Exit_Door", true, false))
	for target in destinations:
		var route := _route(entry, target.global_position)
		var reached := not route.is_empty()
		if reached:
			walker.position = _point(entry)
			for cell in route.slice(1):
				var motion := _point(cell) - walker.position
				var collision := walker.move_and_collide(motion)
				if walker.position.distance_to(_point(cell)) > 0.12:
					print("BLOCKED ", target.name, " at ", walker.position, " toward ", _point(cell), " collider ", collision.get_collider().name if collision else "none")
					reached = false
					break
		if route.is_empty():
			print("NO ROUTE ", target.name)
		check(reached, "Capsule traverses from entrance to %s" % target.name)
	print("MAZE TRAVERSE RESULT: ", failures, " failures")
	quit(1 if failures else 0)
