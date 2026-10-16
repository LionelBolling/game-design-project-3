extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const MODEL = preload("res://Blender models/tube maze.glb")
const PATHS = preload("res://scripts/maze_paths.json")
const COLORS := {"red": Color("e94f48"), "blue": Color("4c91ed"), "yellow": Color("ead24d"), "green": Color("5de087"), "black": Color("c5c0e1")}
const SPAWN := Vector3(0, 0.15, 28.0)
const CLIMB := Vector3(0.3, 0.15, 27.4)
const UPPER_ENTRY := Vector3(0.25, 4.42, 25.9)

var keys := {}
var levers := {}
var doors := {}
var door_bodies := {}
var indicators := {}
var key_nodes := {}
var lever_nodes := {}
var source_count := 0
var batch_count := 0
var _groups := {}
var final_open := false
var corridor_cells := {}
const GRID := 0.4
const GRID_MIN := Vector2(-42.0, -31.2)
const CORRIDOR_RADIUS := 1.08

func _ready() -> void:
	name = "TubeMaze"
	var source := MODEL.instantiate()
	add_child(source)
	for node in source.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var title := str(mesh.name)
		source_count += 1
		if title.begins_with("MODULE_") or title == "Cube" or title.begins_with("Text"):
			mesh.hide()
			continue
		if title.begins_with("Tube_") or title.begins_with("HollowJunction_") or title.begins_with("CompBridge_") or title.begins_with("EndpointBridge_"):
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
			door_bodies[color] = _box_collision(bounds.get_center(), bounds.size)
		elif title.begins_with("Indicator_"):
			indicators[title.get_slice("_", 1).to_int()] = mesh
		if title in ["Cabinet_Door", "Final_Exit_Door"]:
			var bounds := mesh.global_transform * mesh.get_aabb()
			door_bodies[title] = _box_collision(bounds.get_center(), bounds.size)
		if title in ["PlayPlace_Floor", "CircleRoom_InnerFloor", "CircleRoom_OuterFloor", "Left_Room_Threshold", "South_Room_Threshold"]:
			mesh.hide()
			continue
		if title == "Main_Entrance_Climb" or title.begins_with("RoomWallSeg") or title.begins_with("Cap_"):
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
	_raise_puzzle_items()
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

func _grid_point(cell: Vector2i) -> Vector2:
	return GRID_MIN + Vector2(cell) * GRID

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

func _build_connected_tubes() -> void:
	var paths: Array = PATHS.data.paths
	for line in paths:
		var a := Vector2(float(line[0][0]), float(line[0][1]))
		var b := Vector2(float(line[1][0]), float(line[1][1]))
		var length := a.distance_to(b)
		for i in range(ceili(length / (GRID * 0.5)) + 1):
			_mark_disc(a.lerp(b, minf(1.0, i * GRID * 0.5 / maxf(length, 0.001))), CORRIDOR_RADIUS)
	for junction in PATHS.data.junctions:
		_mark_disc(Vector2(float(junction[0]), float(junction[1])), 1.65)
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
	var floor_tool := SurfaceTool.new()
	var wall_tool := SurfaceTool.new()
	var ceiling_tool := SurfaceTool.new()
	for tool in [floor_tool, wall_tool, ceiling_tool]:
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var floor_material: StandardMaterial3D = Geo.material(Color("344854"), 0.2, 0.55)
	var wall_material: StandardMaterial3D = Geo.material(Color("567385"), 0.2, 0.55)
	var ceiling_material: StandardMaterial3D = Geo.material(Color("30404c"), 0.1, 0.4)
	for material in [floor_material, wall_material, ceiling_material]:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	floor_tool.set_material(floor_material)
	wall_tool.set_material(wall_material)
	ceiling_tool.set_material(ceiling_material)
	for cell in corridor_cells:
		var p := _grid_point(cell)
		var x0 := p.x - GRID * 0.5
		var x1 := p.x + GRID * 0.5
		var z0 := p.y - GRID * 0.5
		var z1 := p.y + GRID * 0.5
		_quad(floor_tool, Vector3(x0, 4.22, z1), Vector3(x1, 4.22, z1), Vector3(x1, 4.22, z0), Vector3(x0, 4.22, z0))
		_quad(ceiling_tool, Vector3(x0, 6.28, z0), Vector3(x1, 6.28, z0), Vector3(x1, 6.28, z1), Vector3(x0, 6.28, z1))
		if not corridor_cells.has(cell + Vector2i.LEFT):
			_quad(wall_tool, Vector3(x0, 4.22, z1), Vector3(x0, 4.22, z0), Vector3(x0, 6.28, z0), Vector3(x0, 6.28, z1))
		if not corridor_cells.has(cell + Vector2i.RIGHT):
			_quad(wall_tool, Vector3(x1, 4.22, z0), Vector3(x1, 4.22, z1), Vector3(x1, 6.28, z1), Vector3(x1, 6.28, z0))
		if not corridor_cells.has(cell + Vector2i.UP):
			_quad(wall_tool, Vector3(x0, 4.22, z0), Vector3(x1, 4.22, z0), Vector3(x1, 6.28, z0), Vector3(x0, 6.28, z0))
		if not corridor_cells.has(cell + Vector2i.DOWN):
			_quad(wall_tool, Vector3(x1, 4.22, z1), Vector3(x0, 4.22, z1), Vector3(x0, 6.28, z1), Vector3(x1, 6.28, z1))
	for tool in [floor_tool, wall_tool, ceiling_tool]:
		tool.generate_normals()
		var mesh: ArrayMesh = tool.commit()
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		add_child(visual)
		var body := StaticBody3D.new()
		body.name = "ConnectedTubeFloor" if tool == floor_tool else ("ConnectedTubeWalls" if tool == wall_tool else "ConnectedTubeCeiling")
		var shape := CollisionShape3D.new()
		shape.shape = mesh.create_trimesh_shape()
		(shape.shape as ConcavePolygonShape3D).backface_collision = true
		body.add_child(shape)
		add_child(body)

func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for point in [a, b, c, a, c, d]:
		tool.add_vertex(point)

func _mesh_collision(mesh: MeshInstance3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision_%s" % mesh.name
	body.transform = mesh.global_transform
	var shape := CollisionShape3D.new()
	shape.shape = mesh.mesh.create_trimesh_shape()
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
		levers[color] = true
		(lever_nodes[color] as Node3D).rotation.z = -0.7
		(indicators[color] as OmniLight3D).light_energy = 2.0
		_light_central_indicator(color)
		_open_final_if_ready()
		return "%s light is on." % color.capitalize()
	if kind == "cabinet":
		if not keys.black:
			return "The circle lock needs the black key."
		if not levers.black:
			levers.black = true
			(door_bodies["Cabinet_Door"] as Node).queue_free()
			var cabinet_door := find_child("Cabinet_Door", true, false) as Node3D
			if cabinet_door:
				cabinet_door.hide()
			_light_central_indicator("black")
			_open_final_if_ready()
		return "Black circuit is on."
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
