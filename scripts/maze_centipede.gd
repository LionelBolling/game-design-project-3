extends Node3D

const Geo = preload("res://scripts/geometry.gd")
const Threats = preload("res://scripts/act_threats.gd")
const PATHS = preload("res://scripts/maze_paths.json")

var maze: Node3D
var player: CharacterBody3D
var game: Node3D
var state = Threats.Centipede.new()
var nav := AStarGrid2D.new()
var route: Array[Vector2i] = []
var patrol_index := 0
var path_clock := 0.0
var sound_clock := 0.0
var climb_clock := 0.0
var hunting_player := false
var body: Node3D
var legs_audio: AudioStreamPlayer3D

func setup(level: Node3D, target: CharacterBody3D, owner: Node3D, after_death: bool) -> void:
	maze = level
	player = target
	game = owner
	if after_death:
		state.reset_after_death()
	position = Vector3(8.0, 4.42, 24.7)
	_build_navigation()
	_build_body()
	legs_audio = AudioStreamPlayer3D.new()
	legs_audio.stream = preload("res://audio/centipede_legs.wav")
	legs_audio.unit_size = 3.0
	legs_audio.max_distance = 14.0
	body.add_child(legs_audio)
	hide()

func _build_navigation() -> void:
	var low := Vector2i(100000, 100000)
	var high := Vector2i(-100000, -100000)
	for cell in maze.corridor_cells:
		low = low.min(cell)
		high = high.max(cell)
	nav.region = Rect2i(low, high - low + Vector2i.ONE)
	nav.cell_size = Vector2.ONE * maze.GRID
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav.update()
	for x in range(low.x, high.x + 1):
		for z in range(low.y, high.y + 1):
			var cell := Vector2i(x, z)
			if not maze.corridor_cells.has(cell):
				nav.set_point_solid(cell)
	for cell in maze.corridor_cells:
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + direction
			if maze.corridor_cells.has(neighbor) and not maze.is_open_neighbor(cell, neighbor) and int(maze.corridor_zones.get(cell, -1)) > int(maze.corridor_zones.get(neighbor, -1)):
				nav.set_point_solid(cell)
	_update_gates()

func _update_gates() -> void:
	for color in ["red", "blue", "yellow", "green"]:
		var door := maze.doors[color] as Node3D
		var horizontal: bool = color in ["red", "yellow"]
		var center := Vector2(door.global_position.x, door.global_position.z)
		var low := _cell(Vector3(center.x - 2.0, 0, center.y - 2.0))
		var high := _cell(Vector3(center.x + 2.0, 0, center.y + 2.0))
		for x in range(low.x, high.x + 1):
			for z in range(low.y, high.y + 1):
				var cell := Vector2i(x, z)
				if not nav.is_in_boundsv(cell) or not maze.corridor_cells.has(cell):
					continue
				var point: Vector2 = maze._grid_point(cell)
				var within := absf(point.y - center.y) < 0.48 and absf(point.x - center.x) < 1.65 if horizontal else absf(point.x - center.x) < 0.48 and absf(point.y - center.y) < 1.65
				if within:
					nav.set_point_solid(cell, door.visible)

func _cell(at: Vector3) -> Vector2i:
	return Vector2i(roundi((at.x - maze.GRID_MIN.x) / maze.GRID), roundi((at.z - maze.GRID_MIN.y) / maze.GRID))

func _point(cell: Vector2i) -> Vector3:
	var at: Vector2 = maze._grid_point(cell)
	return Vector3(at.x, 4.42, at.y)

func _nearest_open(from: Vector2i) -> Vector2i:
	for radius in 7:
		for x in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				var cell := from + Vector2i(x, z)
				if nav.is_in_boundsv(cell) and not nav.is_point_solid(cell):
					return cell
	return from

func _path_to(destination: Vector3) -> void:
	_update_gates()
	var start := _nearest_open(_cell(global_position))
	var finish := _nearest_open(_cell(destination))
	route.clear()
	if nav.is_in_boundsv(start) and nav.is_in_boundsv(finish):
		route = nav.get_id_path(start, finish)
	if route.size() > 1:
		route.pop_front()

func _build_body() -> void:
	body = Node3D.new()
	body.name = "ClimbingBody"
	add_child(body)
	var shell := Geo.material(Color("241b1b"), 0.05, 0.05)
	var ridge := Geo.material(Color("69362c"), 0.1, 0.05)
	var leg_color := Geo.material(Color("211b1d"), 0.0, 0.0)
	for i in 12:
		var z := float(i) * 0.19
		var segment := Geo.sphere(body, Vector3(0, 0.38, z), 0.22, shell if i % 2 else ridge)
		segment.scale = Vector3(1.0, 0.68, 0.9)
		for side in [-1.0, 1.0]:
			var leg := Geo.cylinder(body, Vector3(side * 0.31, 0.21, z), 0.025, 0.55, leg_color)
			leg.rotation.z = side * 0.75
	Geo.sphere(body, Vector3(0, 0.42, -0.25), 0.27, ridge)
	for side in [-1.0, 1.0]:
		Geo.sphere(body, Vector3(side * 0.17, 0.51, -0.44), 0.04, Geo.material(Color("e24736"), 0.0, 1.4))

func _process(delta: float) -> void:
	if maze == null or player == null or game.get("phase") != "maze":
		return
	if game.get("maze_dying"):
		global_position = global_position.lerp(player.global_position + Vector3.UP * 0.45, minf(1.0, delta * 12.0))
		body.scale = body.scale.lerp(Vector3.ONE * 1.8, minf(1.0, delta * 8.0))
		return
	state.advance(delta)
	if not state.active:
		return
	show()
	var separation := global_position.distance_to(player.global_position)
	var hidden: bool = game.get("maze_hidden")
	var can_see := separation < 9.0 and _can_see_player()
	if hidden:
		if player.flashlight_on and can_see:
			state.stare_time += delta
			if state.stare_time >= 3.0:
				_attack()
		else:
			state.stare_time = 0.0
	else:
		state.stare_time = 0.0
		if separation < 1.15 and can_see:
			_attack()
	path_clock -= delta
	if path_clock <= 0.0:
		var hunting: bool = not hidden and (player.flashlight_on or (separation < 8.0 and player.velocity.length() > 0.45))
		if hidden and player.flashlight_on and can_see:
			hunting = true
		hunting_player = hunting
		if hunting:
			_path_to(player.global_position)
		else:
			var cap: Array = PATHS.data.caps[patrol_index % PATHS.data.caps.size()]
			_path_to(Vector3(float(cap[0]), 4.42, float(cap[1])))
			if route.is_empty():
				patrol_index += 1
		path_clock = 0.65
	if not route.is_empty() and state.stare_time <= 0.0:
		var destination := _point(route[0])
		var motion := destination - global_position
		if motion.length() < 0.14:
			route.pop_front()
			if route.is_empty() and not hunting_player:
				patrol_index += 1
				climb_clock = 1.1
		else:
			global_position += motion.normalized() * minf(motion.length(), delta * (3.0 if player.flashlight_on else 2.1))
			rotation.y = lerp_angle(rotation.y, atan2(-motion.x, -motion.z), minf(1.0, delta * 5.0))
	if climb_clock > 0.0:
		climb_clock = maxf(0.0, climb_clock - delta)
		var climb := sin((1.1 - climb_clock) / 1.1 * PI)
		body.position.y = climb * 1.0
		body.rotation.z = climb * PI * 0.65
	else:
		body.position.y = 0.0
		body.rotation.z = 0.0
	if separation < 12.0 and not legs_audio.playing:
		legs_audio.play()

func _can_see_player() -> bool:
	var from := global_position + Vector3.UP * 0.45
	var to: Vector3 = player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return maze.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _attack() -> void:
	game.begin_maze_jumpscare()
