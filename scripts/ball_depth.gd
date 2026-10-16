extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const PLAY_PLACE = preload("res://Blender models/PLay place.glb")

# Match the Act 1 pit's 31 by 14.5 metre footprint. Fifty player heights deep.
const LEFT := -15.5
const RIGHT := 15.5
const BACK := -20.5
const FRONT := -6.0
const DEPTH := 56.0
const TUBE := Vector3(-14.1, -52.6, -17.0)

var tube_light: OmniLight3D
var tube_material: StandardMaterial3D
var pulse := 0.0
var shown_loops := -1
var ball_instances: MultiMesh
var ball_origins: Array[Vector3] = []
var ball_positions: Array[Vector3] = []
var layer_heights: Array[float] = []
var active_balls: Dictionary = {}

func _ready() -> void:
	name = "BallDepth"
	var wall := Geo.material(Color("293a54"))
	var stripe := Geo.material(Color("aa3b38"), 0.1, 0.3)
	for x in [LEFT, RIGHT]:
		_solid(Vector3(x, -DEPTH * 0.5, (BACK + FRONT) * 0.5), Vector3(0.3, DEPTH, FRONT - BACK), wall)
	for z in [BACK, FRONT]:
		_solid(Vector3(0, -DEPTH * 0.5, z), Vector3(RIGHT - LEFT, DEPTH, 0.3), wall)
	for y in range(0, 50, 5):
		var depth := -float(y) - 3.0
		Geo.box(self, Vector3(0, depth, BACK + 0.17), Vector3(29.5, 0.09, 0.05), stripe)
		Geo.box(self, Vector3(0, depth, FRONT - 0.17), Vector3(29.5, 0.09, 0.05), stripe)
	_scattered_balls()
	_moving_balls()
	# A rim at the lower left reads clearly while the player falls past it.
	_solid(TUBE + Vector3(-0.25, 0, 0), Vector3(0.45, 3.0, 3.0), Geo.material(Color("3a814f"), 0.05, 0.4))
	tube_material = Geo.material(Color("71d882"), 0.0, 0.2)
	Geo.cylinder(self, TUBE + Vector3(0.1, 0, 0), 1.25, 0.26, tube_material).rotation.z = PI / 2
	tube_light = OmniLight3D.new()
	tube_light.position = TUBE + Vector3(0.6, 0.3, 0)
	tube_light.light_color = Color("59ee78")
	tube_light.omni_range = 10
	add_child(tube_light)
	for y in range(0, 56, 7):
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, -float(y), BACK + 0.6)
		lamp.light_color = Color("8397c2")
		lamp.light_energy = 0.35
		lamp.omni_range = 9
		add_child(lamp)

func _process(delta: float) -> void:
	pulse += delta
	_animate_balls(delta)
	var loops: int = get_parent().get("depth_loops")
	if loops != shown_loops:
		shown_loops = loops
		tube_material.emission_energy_multiplier = minf(2.4, 0.2 + loops * 0.4)
	tube_light.light_energy = minf(2.4, 0.25 + loops * 0.4) + 0.06 * sin(pulse * 3.0)

func _scattered_balls() -> void:
	var source := PLAY_PLACE.instantiate()
	var source_ball := source.find_child("Ball_0000", true, false) as MeshInstance3D
	var mesh := source_ball.mesh.duplicate() as Mesh
	var material := Geo.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)
	var balls := MultiMesh.new()
	balls.transform_format = MultiMesh.TRANSFORM_3D
	balls.use_colors = true
	balls.mesh = mesh
	balls.instance_count = 2200
	var rng := RandomNumberGenerator.new()
	rng.seed = 91450
	var colors := [Color("b64c3e"), Color("c7aa3f"), Color("3364a0")]
	for i in balls.instance_count:
		var depth := rng.randf_range(-55.0, -0.2)
		var point := Vector3.ZERO
		match i % 4:
			0: point = Vector3(LEFT + 0.3, depth, rng.randf_range(BACK, FRONT))
			1: point = Vector3(RIGHT - 0.3, depth, rng.randf_range(BACK, FRONT))
			2: point = Vector3(rng.randf_range(LEFT, RIGHT), depth, BACK + 0.3)
			3: point = Vector3(rng.randf_range(LEFT, RIGHT), depth, FRONT - 0.3)
		balls.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.75, 1.05)), point))
		balls.set_instance_color(i, colors[i % 3])
	var instance := MultiMeshInstance3D.new()
	instance.name = "DeepPitBalls"
	instance.multimesh = balls
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	source.free()

func _moving_balls() -> void:
	var source := PLAY_PLACE.instantiate()
	var source_ball := source.find_child("Ball_0000", true, false) as MeshInstance3D
	var mesh := source_ball.mesh.duplicate() as Mesh
	var material := Geo.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	mesh.surface_set_material(0, material)
	var balls := MultiMesh.new()
	balls.transform_format = MultiMesh.TRANSFORM_3D
	balls.use_colors = true
	balls.mesh = mesh
	balls.instance_count = 5 * 40 * 16
	var rng := RandomNumberGenerator.new()
	rng.seed = 65412
	var colors := [Color("b64c3e"), Color("c7aa3f"), Color("3364a0")]
	for layer in 5:
		var height := -2.0 + layer * 0.45
		layer_heights.append(height)
		for row in 16:
			for column in 40:
				var i := layer * 640 + row * 40 + column
				var origin := Vector3(LEFT + 0.4 + column * 0.775 + rng.randf_range(-0.06, 0.06), height + rng.randf_range(-0.05, 0.05), BACK + 0.45 + row * 0.91 + rng.randf_range(-0.06, 0.06))
				ball_origins.append(origin)
				ball_positions.append(origin)
				balls.set_instance_transform(i, Transform3D(Basis.IDENTITY, origin))
				balls.set_instance_color(i, colors[rng.randi_range(0, 2)])
	var instance := MultiMeshInstance3D.new()
	instance.name = "MovingPitBalls"
	instance.multimesh = balls
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	ball_instances = balls
	source.free()

func _animate_balls(delta: float) -> void:
	if ball_instances == null:
		return
	var player := get_parent().get("player") as CharacterBody3D
	if player == null:
		return
	var p := player.global_position
	for layer in 5:
		var shift := 0.0
		while layer_heights[layer] > p.y + 0.7:
			layer_heights[layer] -= 2.25
			shift -= 2.25
		while layer_heights[layer] < p.y - 2.5:
			layer_heights[layer] += 2.25
			shift += 2.25
		if shift != 0.0:
			for cell in 640:
				var index := layer * 640 + cell
				ball_origins[index].y += shift
				ball_positions[index] = ball_origins[index]
				ball_instances.set_instance_transform(index, Transform3D(Basis.IDENTITY, ball_origins[index]))
	var moving := player.velocity.length() > 0.2
	if moving:
		var column := clampi(roundi((p.x - LEFT - 0.4) / 0.775), 0, 39)
		var row := clampi(roundi((p.z - BACK - 0.45) / 0.91), 0, 15)
		for layer in 5:
			if absf(layer_heights[layer] - p.y) > 1.4:
				continue
			for z in range(maxi(0, row - 2), mini(15, row + 2) + 1):
				for x in range(maxi(0, column - 2), mini(39, column + 2) + 1):
					active_balls[layer * 640 + z * 40 + x] = true
	var settled: Array[int] = []
	for index in active_balls:
		var i: int = index
		var origin := ball_origins[i]
		var away := origin - p
		var distance := away.length()
		var target := origin
		if moving and distance < 1.2 and distance > 0.001:
			target += away / distance * (1.2 - distance) * 0.45
		var next_pos := ball_positions[i].lerp(target, minf(1.0, delta * 10.0))
		ball_positions[i] = next_pos
		ball_instances.set_instance_transform(i, Transform3D(Basis.IDENTITY, next_pos))
		if next_pos.distance_to(origin) < 0.01 and (not moving or distance >= 1.2):
			settled.append(i)
	for i in settled:
		active_balls.erase(i)

func _solid(at: Vector3, dimensions: Vector3, material: Material) -> void:
	Geo.box(self, at, dimensions, material)
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	shape.shape = box
	body.add_child(shape)
	add_child(body)
