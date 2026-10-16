extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const MODEL = preload("res://Blender models/tube maze.glb")
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
		if title == "PlayPlace_Floor":
			mesh.hide()
			continue
		if title.begins_with("Tube_") or title.begins_with("HollowJunction_") or title.begins_with("CompBridge_") or title.begins_with("EndpointBridge_") or title in ["Main_Entrance_Climb", "CircleRoom_InnerFloor", "CircleRoom_OuterFloor", "Left_Room_Threshold", "South_Room_Threshold"]:
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
	var ground := Geo.material(Color("242c38"))
	Geo.box(self, Vector3(0, -0.12, 0), Vector3(96, 0.24, 62), ground)
	_box_collision(Vector3(0, -0.12, 0), Vector3(96, 0.24, 62))
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

func _mesh_collision(mesh: MeshInstance3D) -> void:
	var body := StaticBody3D.new()
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
