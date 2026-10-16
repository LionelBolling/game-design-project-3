extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const MODEL = preload("res://Blender models/tube maze.glb")
const CIRCULAR_WINDOW = preload("res://Blender models/circular window.glb")
const VENT_MODEL = preload("res://Blender models/vents.glb")
const PUZZLE_MODELS = preload("res://Blender models/keys and levers.glb")
const AbyssFx = preload("res://scripts/maze_abyss.gd")
const PATHS = preload("res://scripts/maze_paths.json")
const BLUE_ROUTE = preload("res://scripts/maze_blue_cells.json")
const COLORS := {"red": Color("e94f48"), "blue": Color("4c91ed"), "yellow": Color("ead24d"), "green": Color("5de087"), "black": Color("c5c0e1")}
const UPPER_ENTRY := Vector3(0.25, 4.42, 25.9)
const SPAWN := UPPER_ENTRY

var keys := {}
var levers := {}
var doors := {}
var door_bodies := {}
var indicators := {}
var key_nodes := {}
var lever_nodes := {}
var lever_arms := {}
var keyhole_nodes := {}
var source_count := 0
var batch_count := 0
var _groups := {}
var final_open := false
var cabinet_unlocked := false
var corridor_cells := {}
var corridor_zones := {}
const GRID := 0.4
const GRID_MIN := Vector2(-42.0, -31.2)
const CORRIDOR_RADIUS := 1.08
const WINDOW_CENTERS := [Vector2(19.8, -10.8), Vector2(29.6, -8.6), Vector2(-14.4, 17.8)]
const WINDOW_NORMALS := [Vector2i.LEFT, Vector2i.UP, Vector2i.UP]
var window_nodes: Array[Node3D] = []
var window_edges: Array[Vector2] = []
var hide_spots: Array[Node3D] = []
var abyss_fx: Node3D

func _ready() -> void:
	name = "TubeMaze"
	var source := MODEL.instantiate()
	add_child(source)
	for node in source.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var title := str(mesh.name)
		source_count += 1
		if title.begins_with("MODULE_") or title == "Cube" or title.begins_with("Text") or title.begins_with("BubbleWindow"):
			mesh.hide()
			continue
		if title.begins_with("Tube_") or title.begins_with("HollowJunction_") or title.begins_with("CompBridge_") or title.begins_with("EndpointBridge_"):
			mesh.hide()
			continue
		if title.begins_with("Cap_"):
			mesh.hide()
			continue
		if title.ends_with("_Key"):
			key_nodes[title.get_slice("_", 0).to_lower()] = mesh
		elif title.ends_with("_Lever"):
			lever_nodes[title.get_slice("_", 0).to_lower()] = mesh
		elif title.ends_with("_Door") and title != "Cabinet_Door" and title != "Final_Exit_Door":
			var color := title.get_slice("_", 0).to_lower()
			doors[color] = mesh
			var bounds := mesh.global_transform * mesh.get_aabb()
			var gate_size: Vector3 = Vector3(3.2, 2.5, 0.64) if color in ["red", "yellow"] else Vector3(0.64, 2.5, 3.2)
			var gate: StaticBody3D = _box_collision(bounds.get_center(), gate_size)
			gate.name = "LockedGate_%s" % color
			door_bodies[color] = gate
		elif title.begins_with("Indicator_"):
			indicators[title.get_slice("_", 1).to_int()] = mesh
		if title in ["Cabinet_Door", "Final_Exit_Door"]:
			var bounds := mesh.global_transform * mesh.get_aabb()
			door_bodies[title] = _box_collision(bounds.get_center(), bounds.size)
		if title in ["PlayPlace_Floor", "CircleRoom_InnerFloor", "CircleRoom_OuterFloor", "Left_Room_Threshold", "South_Room_Threshold"]:
			mesh.hide()
			continue
		if title == "Main_Entrance_Climb" or title.begins_with("RoomWallSeg"):
			_mesh_collision(mesh)
		if not (title.ends_with("_Key") or title.ends_with("_Lever") or title.ends_with("_Door") or title.begins_with("Indicator_") or title.begins_with("Cabinet_") or title.begins_with("Black_Key_Cabinet")):
			_batch(mesh)
			mesh.queue_free()
	for group in _groups.values():
		var instance := MeshInstance3D.new()
		instance.mesh = (group as SurfaceTool).commit()
		instance.name = "MazeBatch_%d" % batch_count
		add_child(instance)
		batch_count += 1
	_groups.clear()
	_build_connected_tubes()
	_build_hide_spots()
	_place_circle_hatch()
	_attach_black_cabinet()
	_build_abyss_windows()
	_raise_puzzle_items()
	_install_puzzle_models()
	_build_keyholes()
	var ground := Geo.material(Color("242c38"))
	Geo.box(self, Vector3(0, -0.12, 27), Vector3(8, 0.24, 8), ground)
	_box_collision(Vector3(0, -0.12, 27), Vector3(8, 0.24, 8))
	for color in COLORS:
		keys[color] = false
		levers[color] = false
		if color != "black":
			var lamp := OmniLight3D.new()
			lamp.position = (doors[color] as Node3D).global_position + Vector3(0, 1.2, 0)
			lamp.light_color = COLORS[color]
			lamp.light_energy = 0
			lamp.omni_range = 5
			add_child(lamp)
			indicators[color] = lamp
	# Additional light makes the two playable levels readable without costly shadows.
	for spot in [Vector3(0, 6, 0), Vector3(0, 5, 27), Vector3(-34, 3, -23), Vector3(34, 3, 23)]:
		var light := OmniLight3D.new()
		light.position = spot
		light.light_color = Color("9da9b7")
		light.light_energy = 0.8
		light.omni_range = 15
		add_child(light)
	print("TUBE MAZE: %d source meshes -> %d batches" % [source_count, batch_count])
	abyss_fx = Node3D.new()
	abyss_fx.set_script(AbyssFx)
	add_child(abyss_fx)
	abyss_fx.setup(window_nodes)

func set_abyss_player(value: CharacterBody3D) -> void:
	abyss_fx.player = value

func _build_abyss_windows() -> void:
	var abyss_material := ShaderMaterial.new()
	abyss_material.shader = preload("res://shaders/abyss_backdrop.gdshader")
	for index in WINDOW_CENTERS.size():
		var normal: Vector2i = WINDOW_NORMALS[index]
		var center: Vector2 = window_edges[index]
		var window := Node3D.new()
		window.name = "AbyssWindow_%d" % index
		window.position = Vector3(center.x, 5.25, center.y)
		window.rotation.y = atan2(float(normal.x), float(normal.y))
		add_child(window)
		window_nodes.append(window)
		var model := CIRCULAR_WINDOW.instantiate() as Node3D
		model.name = "CircularWindowModel"
		model.rotation.x = PI * 0.5
		model.scale = Vector3.ONE * 0.58
		window.add_child(model)
		var backdrop := QuadMesh.new()
		backdrop.size = Vector2(1.08, 1.08)
		var backdrop_node := Geo.mesh(window, backdrop, Vector3(0, 0, 0.12), abyss_material)
		backdrop_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _nearest_wall_edge(near: Vector2, normal: Vector2i) -> Vector2:
	var best := near
	var distance := INF
	var tangent := Vector2i(-normal.y, normal.x)
	for cell in corridor_cells:
		if corridor_cells.has(cell + normal):
			continue
		var flat := true
		for step in range(-2, 3):
			var neighbor: Vector2i = cell + tangent * step
			if not corridor_cells.has(neighbor) or corridor_cells.has(neighbor + normal):
				flat = false
				break
		if not flat:
			continue
		var edge := _grid_point(cell) + Vector2(normal) * GRID * 0.5
		var separation := edge.distance_squared_to(near)
		if separation < distance:
			distance = separation
			best = edge
	return best

func _place_circle_hatch() -> void:
	var old := find_child("Final_Exit_Door", true, false) as MeshInstance3D
	if old:
		old.hide()
		old.name = "Old_Wall_Exit_Door"
	if is_instance_valid(door_bodies["Final_Exit_Door"]):
		(door_bodies["Final_Exit_Door"] as Node).queue_free()
	var hatch := Node3D.new()
	hatch.name = "Final_Exit_Door"
	hatch.position = Vector3(0, 4.31, 0)
	add_child(hatch)
	Geo.cylinder(hatch, Vector3.ZERO, 2.4, 0.10, Geo.material(Color("1b242d"), 0.5, 0.2))
	Geo.cylinder(hatch, Vector3(0, 0.055, 0), 2.0, 0.02, Geo.material(Color("3a4446"), 0.7, 0.1))
	for i in 5:
		var old_indicator := indicators[i] as MeshInstance3D
		old_indicator.hide()
		var light := Geo.box(hatch, Vector3((float(i) - 2.0) * 0.7, 0.075, 0), Vector3(0.48, 0.03, 0.74), Geo.material(Color("182326"), 0.0, 0.1))
		light.name = "HatchLight_%d" % i
		indicators[i] = light
	door_bodies["Final_Exit_Door"] = _box_collision(Vector3(0, 4.36, 0), Vector3(4.8, 0.1, 4.8))

func _attach_black_cabinet() -> void:
	for title in ["Black_Key_Cabinet", "Cabinet_Door", "Cabinet_Black_Lock"]:
		var part := find_child(title, true, false) as Node3D
		if part:
			part.position.z -= 2.15
	if is_instance_valid(door_bodies["Cabinet_Door"]):
		(door_bodies["Cabinet_Door"] as Node3D).position.z -= 2.15

func _build_hide_spots() -> void:
	var beyond := {"green": Vector2.RIGHT, "red": Vector2.UP, "blue": Vector2.RIGHT, "yellow": Vector2.DOWN}
	var wall_normals: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for color in ["green", "red", "blue", "yellow"]:
		var door: Node3D = doors[color]
		var door_point := Vector2(door.global_position.x, door.global_position.z)
		var side: Vector2 = beyond[color]
		var zone := _zone_behind_door(door_point, side)
		for index in 2:
			var target_distance := 7.0 if index == 0 else 17.0
			var best_score := INF
			var best_edge := Vector2.ZERO
			var best_normal := Vector2i.ZERO
			for cell in corridor_cells:
				if int(corridor_zones.get(cell, -1)) != zone:
					continue
				var point := _grid_point(cell)
				for normal in wall_normals:
					if is_open_neighbor(cell, cell + normal) or not corridor_cells.has(cell - normal):
						continue
					var tangent := Vector2i(-normal.y, normal.x)
					var straight := true
					for offset in range(-2, 3):
						var neighbor: Vector2i = cell + tangent * offset
						if int(corridor_zones.get(neighbor, -1)) != zone or is_open_neighbor(neighbor, neighbor + normal):
							straight = false
							break
					if not straight:
						continue
					var edge := point + Vector2(normal) * GRID * 0.5
					var distance := edge.distance_to(door_point)
					if distance < 4.0 or (edge - door_point).dot(side) < 2.0:
						continue
					var near_window := false
					for window_edge in window_edges:
						if edge.distance_to(window_edge) < 2.3:
							near_window = true
							break
					if near_window:
						continue
					var foot := edge - Vector2(normal) * 0.7
					var near_spot := false
					for existing in hide_spots:
						if Vector2(existing.position.x, existing.position.z).distance_to(foot) < 7.0:
							near_spot = true
							break
					if near_spot:
						continue
					var score := absf(distance - target_distance)
					if score < best_score:
						best_score = score
						best_edge = edge
						best_normal = normal
			if best_score == INF:
				push_error("No reachable vent wall behind the %s door" % color)
				continue
			var spot := Node3D.new()
			spot.name = "VentHide_%s_%d" % [color, index + 1]
			spot.set_meta("door_color", color)
			var foot := best_edge - Vector2(best_normal) * 0.7
			spot.position = Vector3(foot.x, 4.24, foot.y)
			add_child(spot)
			var vent := VENT_MODEL.instantiate() as Node3D
			vent.name = "VentModel"
			vent.position = Vector3(float(best_normal.x) * 0.7, 1.01, float(best_normal.y) * 0.7)
			vent.rotation.y = atan2(-float(best_normal.x), -float(best_normal.y))
			vent.scale = Vector3.ONE * 0.72
			spot.add_child(vent)
			hide_spots.append(spot)

func _zone_behind_door(door_point: Vector2, side: Vector2) -> int:
	var target := door_point + side * 4.0
	var best := INF
	var zone := -1
	for cell in corridor_cells:
		var point := _grid_point(cell)
		if (point - door_point).dot(side) < 2.0:
			continue
		var distance := point.distance_squared_to(target)
		if distance < best:
			best = distance
			zone = int(corridor_zones.get(cell, -1))
	return zone

func closest_hide_spot(at: Vector3, maximum: float = 1.7) -> Node3D:
	var closest: Node3D = null
	for spot in hide_spots:
		if at.distance_to(spot.global_position) < maximum:
			maximum = at.distance_to(spot.global_position)
			closest = spot
	return closest

func _raise_puzzle_items() -> void:
	for color in COLORS:
		for suffix in ["Key", "Key_Pedestal", "Key_Ring"]:
			var item := find_child("%s_%s" % [color.capitalize(), suffix], true, false) as Node3D
			if item:
				item.position.y += 4.3
		if color == "black":
			continue
		for suffix in ["Lever", "Lever_Base", "Lever_Stem"]:
			var item := find_child("%s_%s" % [color.capitalize(), suffix], true, false) as Node3D
			if item:
				item.position.y += 4.3

func _install_puzzle_models() -> void:
	var parts := PUZZLE_MODELS.instantiate()
	for color in COLORS:
		var old_key := key_nodes[color] as Node3D
		var key_root := _copy_puzzle_model(parts.find_child("KEY_%s_ROOT" % color.to_upper(), true, false) as Node3D, old_key.global_position, false)
		key_root.name = "%s_Model_Key" % color.capitalize()
		key_nodes[color] = key_root
		old_key.hide()
		var old_ring := find_child("%s_Key_Ring" % color.capitalize(), true, false) as Node3D
		if old_ring:
			old_ring.hide()
		if color == "black":
			var black_root := _copy_puzzle_model(parts.find_child("LEVER_BLACK_ROOT", true, false) as Node3D, Vector3(-4.6, 5.15, 0), true)
			black_root.name = "Black_Model_Lever"
			_mount_on_tube_wall(black_root, Vector2(-4.6, 0))
			lever_nodes.black = black_root
			lever_arms.black = black_root.get_node("HandlePivot")
			continue
		var old_lever := lever_nodes[color] as Node3D
		var lever_root := _copy_puzzle_model(parts.find_child("LEVER_%s_ROOT" % color.to_upper(), true, false) as Node3D, old_lever.global_position - Vector3(0, 0.7, 0), true)
		lever_root.name = "%s_Model_Lever" % color.capitalize()
		_mount_on_tube_wall(lever_root, Vector2(old_lever.global_position.x, old_lever.global_position.z))
		lever_nodes[color] = lever_root
		lever_arms[color] = lever_root.get_node("HandlePivot")
		old_lever.hide()
		for suffix in ["Lever_Base", "Lever_Stem"]:
			var old_part := find_child("%s_%s" % [color.capitalize(), suffix], true, false) as Node3D
			if old_part:
				old_part.hide()
	parts.free()

func _copy_puzzle_model(source_root: Node3D, at: Vector3, is_lever: bool) -> Node3D:
	var root_node := Node3D.new()
	root_node.position = at
	add_child(root_node)
	var arm: Node3D
	if is_lever:
		arm = Node3D.new()
		arm.name = "HandlePivot"
		arm.position = Vector3(0, 0.36, 0.155)
		root_node.add_child(arm)
	for child in source_root.get_children():
		if not child is MeshInstance3D:
			continue
		var original := child as MeshInstance3D
		var piece := original.duplicate() as MeshInstance3D
		var movable := is_lever and (piece.name.ends_with("_Arm") or piece.name.ends_with("_Handle"))
		(arm if movable else root_node).add_child(piece)
		piece.transform = original.transform
		piece.position -= source_root.position
		if movable:
			piece.position -= arm.position
	return root_node

func _mount_on_tube_wall(model: Node3D, near: Vector2) -> void:
	var best_distance := INF
	var outward := Vector2.ZERO
	var mount := near
	for cell in corridor_cells:
		var point := _grid_point(cell)
		if point.distance_squared_to(near) > 6.25:
			continue
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if corridor_cells.has(cell + direction):
				continue
			var normal := Vector2(direction)
			var edge := point + normal * (GRID * 0.5)
			var distance := edge.distance_squared_to(near)
			if distance < best_distance:
				best_distance = distance
				outward = normal
				mount = edge - normal * 0.035
	model.position.x = mount.x
	model.position.z = mount.y
	model.rotation.y = atan2(-outward.x, -outward.y)

func _build_keyholes() -> void:
	for color in ["red", "blue", "yellow", "green"]:
		var door := doors[color] as Node3D
		var sockets := Node3D.new()
		sockets.name = "%s_Wall_Keyholes" % color.capitalize()
		sockets.position = door.global_position
		add_child(sockets)
		var jamb_material := Geo.material(Color("405462"), 0.3, 0.1)
		if color in ["red", "yellow"]:
			Geo.box(sockets, Vector3(1.04, 0, 0), Vector3(0.28, 2.15, 0.9), jamb_material)
		else:
			Geo.box(sockets, Vector3(0, 0, 1.04), Vector3(0.9, 2.15, 0.28), jamb_material)
		for side in [-1.0, 1.0]:
			var plate := Node3D.new()
			plate.name = "WallLock_%s" % str(side)
			if color in ["red", "yellow"]:
				plate.position = Vector3(1.04, 0, side * 0.48)
				plate.rotation.y = PI if side < 0 else 0.0
			else:
				plate.position = Vector3(side * 0.48, 0, 1.04)
				plate.rotation.y = -PI * 0.5 if side < 0 else PI * 0.5
			sockets.add_child(plate)
			_keyhole(plate, Vector3.ZERO, color, 1.0)
		keyhole_nodes[color] = sockets
	var cabinet := find_child("Cabinet_Black_Lock", true, false) as Node3D
	if cabinet:
		var black_socket := Node3D.new()
		black_socket.name = "Black_Circle_Keyhole"
		black_socket.position = cabinet.global_position + Vector3(0, 0, -0.19)
		add_child(black_socket)
		_keyhole(black_socket, Vector3.ZERO, "black", -1.0)
		keyhole_nodes.black = black_socket

func _keyhole(parent: Node3D, at: Vector3, color: String, face: float) -> void:
	var plate := Geo.material(COLORS[color].darkened(0.45), 0.65)
	var trim := Geo.material(COLORS[color], 0.3, 0.4)
	var dark := Geo.material(Color("07090e"), 0.1)
	Geo.box(parent, at, Vector3(0.28, 0.43, 0.075), plate)
	var front := at + Vector3(0, 0, face * 0.045)
	var bezel := Geo.cylinder(parent, front + Vector3(0, 0.05, 0), 0.105, 0.016, trim)
	bezel.rotation.x = PI * 0.5
	var hole := Geo.cylinder(parent, front + Vector3(0, 0.05, face * 0.014), 0.058, 0.019, dark)
	hole.rotation.x = PI * 0.5
	Geo.box(parent, front + Vector3(0, -0.025, face * 0.019), Vector3(0.048, 0.13, 0.019), dark)

func _grid_point(cell: Vector2i) -> Vector2:
	return GRID_MIN + Vector2(cell) * GRID

func _assign_blue_zones() -> void:
	var remaining := {}
	for pair in BLUE_ROUTE.data.cells:
		remaining[Vector2i(int(pair[0]), int(pair[1]))] = true
	var regions: Array = []
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not remaining.is_empty():
		var seed: Vector2i = remaining.keys()[0]
		remaining.erase(seed)
		var component: Array[Vector2i] = [seed]
		var index := 0
		while index < component.size():
			var current: Vector2i = component[index]
			index += 1
			for direction in directions:
				var neighbor: Vector2i = current + direction
				if remaining.erase(neighbor):
					component.append(neighbor)
		if component.size() >= 400:
			regions.append(component)
	var frontier: Array[Vector2i] = []
	for zone in regions.size():
		for cell in regions[zone]:
			if corridor_cells.has(cell) and not corridor_zones.has(cell):
				corridor_zones[cell] = zone
				frontier.append(cell)
	var index := 0
	while index < frontier.size():
		var current: Vector2i = frontier[index]
		index += 1
		for direction in directions:
			var neighbor: Vector2i = current + direction
			if corridor_cells.has(neighbor) and not corridor_zones.has(neighbor):
				corridor_zones[neighbor] = corridor_zones[current]
				frontier.append(neighbor)
	for cell in corridor_cells.keys():
		if not corridor_zones.has(cell):
			corridor_cells.erase(cell)
	print("TUBE MAZE: %d highlighted route zones" % regions.size())

func _add_blue_route() -> void:
	for pair in BLUE_ROUTE.data.cells:
		corridor_cells[Vector2i(int(pair[0]), int(pair[1]))] = true

func is_open_neighbor(cell: Vector2i, neighbor: Vector2i) -> bool:
	if not corridor_cells.has(neighbor):
		return false
	if corridor_zones.get(cell, -1) == corridor_zones.get(neighbor, -1):
		return true
	var center := (_grid_point(cell) + _grid_point(neighbor)) * 0.5
	for color in ["red", "blue", "yellow", "green"]:
		var door := doors[color] as Node3D
		if center.distance_to(Vector2(door.global_position.x, door.global_position.z)) < 2.0:
			return true
	return false

func _mark_disc(center: Vector2, radius: float) -> void:
	var low := Vector2i(floori((center.x - radius - GRID_MIN.x) / GRID), floori((center.y - radius - GRID_MIN.y) / GRID))
	var high := Vector2i(ceili((center.x + radius - GRID_MIN.x) / GRID), ceili((center.y + radius - GRID_MIN.y) / GRID))
	for x in range(low.x, high.x + 1):
		for z in range(low.y, high.y + 1):
			var cell := Vector2i(x, z)
			if _grid_point(cell).distance_squared_to(center) <= radius * radius:
				corridor_cells[cell] = true

func _connect_marker(center: Vector2) -> void:
	var closest := center
	var distance := INF
	for cell in corridor_cells:
		var point := _grid_point(cell)
		var separation := center.distance_squared_to(point)
		if separation < distance:
			distance = separation
			closest = point
	var length := center.distance_to(closest)
	for i in range(ceili(length / 0.2) + 1):
		_mark_disc(center.lerp(closest, minf(1.0, i * 0.2 / maxf(length, 0.001))), 0.85)

func _mark_door_tunnel(color: String) -> void:
	var door := doors[color] as Node3D
	var center := Vector2(door.global_position.x, door.global_position.z)
	var axis := Vector2.DOWN if color in ["red", "yellow"] else Vector2.RIGHT
	var extent := 30 if color == "blue" else 14
	for step in range(-extent, extent + 1):
		_mark_disc(center + axis * float(step) * 0.2, 1.36)

func _build_connected_tubes() -> void:
	var paths: Array = PATHS.data.paths
	for line in paths:
		var a := Vector2(float(line[0][0]), float(line[0][1]))
		var b := Vector2(float(line[1][0]), float(line[1][1]))
		var length := a.distance_to(b)
		for i in range(ceili(length / (GRID * 0.5)) + 1):
			_mark_disc(a.lerp(b, minf(1.0, i * GRID * 0.5 / maxf(length, 0.001))), CORRIDOR_RADIUS)
	for junction in PATHS.data.junctions:
		_mark_disc(Vector2(float(junction[0]), float(junction[1])), 1.15)
	# The centre circle is a room rather than a narrow passage.
	_mark_disc(Vector2.ZERO, 5.15)
	_mark_disc(Vector2(0, 5.7), 1.5)
	_mark_disc(Vector2(-6.3, 0), 1.5)
	# A short connector in the Blender route has a sub-metre gap at this junction.
	_mark_disc(Vector2(-4.0, 22.0), 0.9)
	for color in COLORS:
		var key := key_nodes[color] as Node3D
		_connect_marker(Vector2(key.global_position.x, key.global_position.z))
		if color != "black":
			var lever := lever_nodes[color] as Node3D
			var door := doors[color] as Node3D
			_connect_marker(Vector2(lever.global_position.x, lever.global_position.z))
			_connect_marker(Vector2(door.global_position.x, door.global_position.z))
			_mark_door_tunnel(color)
	_add_blue_route()
	_assign_blue_zones()
	window_edges.clear()
	for index in WINDOW_CENTERS.size():
		window_edges.append(_nearest_wall_edge(WINDOW_CENTERS[index], WINDOW_NORMALS[index]))
	var floor_tool := SurfaceTool.new()
	var wall_tool := SurfaceTool.new()
	var wall_collision_tool := SurfaceTool.new()
	var ceiling_tool := SurfaceTool.new()
	for tool in [floor_tool, wall_tool, wall_collision_tool, ceiling_tool]:
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var floor_material: StandardMaterial3D = Geo.material(Color("344854"), 0.2, 0.55)
	var wall_material: StandardMaterial3D = Geo.material(Color("567385"), 0.2, 0.55)
	var ceiling_material: StandardMaterial3D = Geo.material(Color("30404c"), 0.1, 0.4)
	for material in [floor_material, wall_material, ceiling_material]:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	floor_tool.set_material(floor_material)
	wall_tool.set_material(wall_material)
	wall_collision_tool.set_material(wall_material)
	ceiling_tool.set_material(ceiling_material)
	for cell in corridor_cells:
		var p := _grid_point(cell)
		var x0 := p.x - GRID * 0.5
		var x1 := p.x + GRID * 0.5
		var z0 := p.y - GRID * 0.5
		var z1 := p.y + GRID * 0.5
		_quad(floor_tool, Vector3(x0, 4.22, z1), Vector3(x1, 4.22, z1), Vector3(x1, 4.22, z0), Vector3(x0, 4.22, z0))
		_quad(ceiling_tool, Vector3(x0, 6.28, z0), Vector3(x1, 6.28, z0), Vector3(x1, 6.28, z1), Vector3(x0, 6.28, z1))
		if not is_open_neighbor(cell, cell + Vector2i.LEFT):
			_tube_wall(wall_tool, wall_collision_tool, Vector3(x0, 4.22, z1), Vector3(x0, 4.22, z0), Vector3(x0, 6.28, z0), Vector3(x0, 6.28, z1), Vector2(x0, p.y), Vector2i.LEFT)
		if not is_open_neighbor(cell, cell + Vector2i.RIGHT):
			_tube_wall(wall_tool, wall_collision_tool, Vector3(x1, 4.22, z0), Vector3(x1, 4.22, z1), Vector3(x1, 6.28, z1), Vector3(x1, 6.28, z0), Vector2(x1, p.y), Vector2i.RIGHT)
		if not is_open_neighbor(cell, cell + Vector2i.UP):
			_tube_wall(wall_tool, wall_collision_tool, Vector3(x0, 4.22, z0), Vector3(x1, 4.22, z0), Vector3(x1, 6.28, z0), Vector3(x0, 6.28, z0), Vector2(p.x, z0), Vector2i.UP)
		if not is_open_neighbor(cell, cell + Vector2i.DOWN):
			_tube_wall(wall_tool, wall_collision_tool, Vector3(x1, 4.22, z1), Vector3(x0, 4.22, z1), Vector3(x0, 6.28, z1), Vector3(x1, 6.28, z1), Vector2(p.x, z1), Vector2i.DOWN)
	wall_collision_tool.generate_normals()
	var collision_walls: ArrayMesh = wall_collision_tool.commit()
	for tool in [floor_tool, wall_tool, ceiling_tool]:
		tool.generate_normals()
		var mesh: ArrayMesh = tool.commit()
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		add_child(visual)
		var body := StaticBody3D.new()
		body.name = "ConnectedTubeFloor" if tool == floor_tool else ("ConnectedTubeWalls" if tool == wall_tool else "ConnectedTubeCeiling")
		var shape := CollisionShape3D.new()
		shape.shape = (collision_walls if tool == wall_tool else mesh).create_trimesh_shape()
		(shape.shape as ConcavePolygonShape3D).backface_collision = true
		body.add_child(shape)
		add_child(body)

func _tube_wall(visual: SurfaceTool, collision: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, edge: Vector2, normal: Vector2i) -> void:
	_quad(collision, a, b, c, d)
	var window_index := -1
	for index in WINDOW_CENTERS.size():
		if WINDOW_NORMALS[index] == normal and edge.distance_to(window_edges[index]) <= 0.69:
			window_index = index
			break
	if window_index < 0:
		_quad(visual, a, b, c, d)
		return
	var lower_a := a + Vector3.UP * 0.45
	var lower_b := b + Vector3.UP * 0.45
	var upper_c := c - Vector3.UP * 0.45
	var upper_d := d - Vector3.UP * 0.45
	_quad(visual, a, b, lower_b, lower_a)
	_quad(visual, upper_d, upper_c, c, d)

func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for point in [a, b, c, a, c, d]:
		tool.add_vertex(point)

func _mesh_collision(mesh: MeshInstance3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision_%s" % mesh.name
	body.transform = mesh.global_transform
	var shape := CollisionShape3D.new()
	shape.shape = mesh.mesh.create_trimesh_shape()
	(shape.shape as ConcavePolygonShape3D).backface_collision = true
	body.add_child(shape)
	add_child(body)

func _box_collision(at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions.max(Vector3.ONE * 0.03)
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	return body

func _batch(mesh: MeshInstance3D) -> void:
	for surface in mesh.mesh.get_surface_count():
		var mat := mesh.get_active_material(surface)
		var cell := Vector2i(floori(mesh.global_position.x / 10), floori(mesh.global_position.z / 10))
		var key := "%s_%s" % [mat.get_instance_id() if mat else 0, cell]
		if not _groups.has(key):
			var tool := SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tool.set_material(mat)
			_groups[key] = tool
		(_groups[key] as SurfaceTool).append_from(mesh.mesh, surface, mesh.global_transform)

func interact(kind: String, color: String) -> String:
	if kind == "key":
		if keys[color]:
			return ""
		keys[color] = true
		(key_nodes[color] as Node3D).hide()
		return "%s key found." % color.capitalize()
	if kind == "door":
		if not keys[color]:
			return "The %s door needs its matching key." % color
		if is_instance_valid(door_bodies[color]):
			(door_bodies[color] as Node).queue_free()
		(doors[color] as Node3D).hide()
		return "%s door unlocked." % color.capitalize()
	if kind == "lever":
		if levers[color]:
			return "This circuit is already live."
		if color == "black" and not cabinet_unlocked:
			return "The circle lock must be opened first."
		levers[color] = true
		(lever_arms[color] as Node3D).rotation.x = -0.7
		if color != "black":
			(indicators[color] as OmniLight3D).light_energy = 2.0
		_light_central_indicator(color)
		_open_final_if_ready()
		return "%s light is on." % color.capitalize()
	if kind == "cabinet":
		if not keys.black:
			return "The circle lock needs the black key."
		if not cabinet_unlocked:
			cabinet_unlocked = true
			(door_bodies["Cabinet_Door"] as Node).queue_free()
			var cabinet_door := find_child("Cabinet_Door", true, false) as Node3D
			if cabinet_door:
				cabinet_door.hide()
		return "Circle lock opened. Pull the black lever."
	if kind == "final":
		return "The five circuits must be live." if not final_open else "The tube maze is behind you."
	return ""

func _light_central_indicator(color: String) -> void:
	var order := ["green", "red", "blue", "yellow", "black"]
	var node := indicators[order.find(color)] as MeshInstance3D
	var material := Geo.material(COLORS[color], 0.0, 2.0)
	node.material_override = material

func _open_final_if_ready() -> void:
	for color in COLORS:
		if not levers[color]:
			return
	final_open = true
	(door_bodies["Final_Exit_Door"] as Node).queue_free()
	var exit := find_child("Final_Exit_Door", true, false) as Node3D
	if exit:
		exit.hide()
