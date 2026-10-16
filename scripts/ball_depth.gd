extends Node3D
const Geo = preload("res://scripts/geometry.gd")
const PLAY_PLACE = preload("res://Blender models/PLay place.glb")
const Threats = preload("res://scripts/act_threats.gd")

# Match the Act 1 pit's 31 by 14.5 metre footprint. Fifty player heights deep.
const LEFT := -15.5
const RIGHT := 15.5
const BACK := -20.5
const FRONT := -6.0
const DEPTH := 56.0
const TUBE := Vector3(-14.1, -52.6, -17.0)
const MOVING_LAYERS := 18
const BALL_COLUMNS := 56
const BALL_ROWS := 28
const BALLS_PER_LAYER := BALL_COLUMNS * BALL_ROWS
const BALL_X_STEP := 0.55
const BALL_Z_STEP := 0.51
const LAYER_SPAN := 5.76

var tube_light: OmniLight3D
var tube_material: StandardMaterial3D
var pulse := 0.0
var shown_loops := -1
var ball_instances: MultiMesh
var scattered_instances: MultiMesh
var moving_colors: Array[Color] = []
var scattered_colors: Array[Color] = []
var ball_origins: Array[Vector3] = []
var ball_positions: Array[Vector3] = []
var layer_heights: Array[float] = []
var active_balls: Dictionary = {}
var threat = Threats.Shark.new()
var shark: Node3D
var shark_angle := 0.0
var sound_clock := 0.0
var shark_sound_clock := 0.0
var bite_clock := 0.0
var bump_attempted_cycle := -1
var last_velocity := Vector3.ZERO

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
	_build_shark()
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
	_update_shark(delta)
	_animate_balls(delta)
	var loops: int = get_parent().get("depth_loops")
	if loops != shown_loops:
		shown_loops = loops
		tube_material.emission_energy_multiplier = minf(2.4, 0.2 + loops * 0.4)
		_fade_balls(loops)
	tube_light.light_energy = minf(2.4, 0.25 + loops * 0.4) + 0.06 * sin(pulse * 3.0)

static func ball_alpha_for_loops(loops: int) -> float:
	return clampf(1.0 - float(loops) * 0.16, 0.36, 1.0)

func _fade_balls(loops: int) -> void:
	var alpha := ball_alpha_for_loops(loops)
	for i in moving_colors.size():
		var color := moving_colors[i]
		ball_instances.set_instance_color(i, Color(color.r, color.g, color.b, alpha))
	for i in scattered_colors.size():
		var color := scattered_colors[i]
		scattered_instances.set_instance_color(i, Color(color.r, color.g, color.b, alpha))

func _build_shark() -> void:
	shark = Node3D.new()
	shark.name = "DarkShark"
	add_child(shark)
	var skin := Geo.material(Color("07131c"), 0.0, 0.0)
	var body := Geo.sphere(shark, Vector3.ZERO, 0.65, skin)
	body.scale = Vector3(2.2, 0.55, 0.7)
	var fin := Geo.sphere(shark, Vector3(0, 0.55, 0), 0.4, skin)
	fin.scale = Vector3(0.7, 1.25, 0.15)
	shark.hide()

func reset_threat() -> void:
	threat = Threats.Shark.new()
	shark_angle = 0.0
	sound_clock = 0.0
	shark_sound_clock = 0.0
	bite_clock = 0.0
	bump_attempted_cycle = -1
	shark.hide()

func _update_shark(delta: float) -> void:
	var game := get_parent()
	if game.get("phase") != "depth":
		return
	var player := game.get("player") as CharacterBody3D
	if player == null:
		return
	shark_angle += delta * (1.4 if player.flashlight_on else 0.7)
	var brief_bump: bool = threat.bumping and fmod(threat.pressure - 20.0, 8.0) < 1.4
	var radius := 1.5 if threat.aggressive else (0.4 if brief_bump else 3.0)
	var target := player.global_position + Vector3(cos(shark_angle) * radius, -0.25, sin(shark_angle) * radius)
	shark.position = shark.position.lerp(target, minf(1.0, delta * 3.0)) if threat.circling else target
	shark.rotation.y = atan2(player.global_position.z - shark.position.z, player.global_position.x - shark.position.x)
	var toward: Vector3 = shark.global_position - player.camera.global_position
	var watching: bool = threat.circling and toward.length() < 4.5 and -player.camera.global_basis.z.dot(toward.normalized()) > 0.92
	threat.advance(delta, player.flashlight_on, watching)
	shark.visible = threat.circling
	# Most of the shape stays below the balls; only brief nearby movement gives it away.
	shark.scale = Vector3.ONE * (0.65 if player.flashlight_on else 0.45)
	sound_clock -= delta
	if sound_clock <= 0.0 and player.velocity.length() > 0.3:
		game.sound("balls_wade", randf_range(0.85, 1.15))
		sound_clock = 0.95
	shark_sound_clock -= delta
	if shark_sound_clock <= 0.0 and threat.circling:
		game.sound("shark_swim", randf_range(0.8, 1.05))
		shark_sound_clock = 3.2
	bite_clock = maxf(0.0, bite_clock - delta)
	var touching: bool = shark.global_position.distance_to(player.global_position) < (2.1 if threat.aggressive else 1.3)
	var bump_cycle: int = floori((threat.pressure - 20.0) / 8.0)
	var should_bite: bool = threat.aggressive and touching and bite_clock <= 0.0
	if brief_bump and touching and bump_cycle != bump_attempted_cycle:
		bump_attempted_cycle = bump_cycle
		should_bite = randf() < 0.4
	if should_bite:
		threat.bite()
		game.sound("shark_bite")
		bite_clock = 7.0
		if threat.dead:
			game.restart_depth()

func _scattered_balls() -> void:
	var source := PLAY_PLACE.instantiate()
	var source_ball := source.find_child("Ball_0000", true, false) as MeshInstance3D
	var mesh := source_ball.mesh.duplicate() as Mesh
	var material := Geo.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color("69717a")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.surface_set_material(0, material)
	var balls := MultiMesh.new()
	balls.transform_format = MultiMesh.TRANSFORM_3D
	balls.use_colors = true
	balls.mesh = mesh
	balls.instance_count = 3600
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
		var color: Color = colors[i % 3]
		scattered_colors.append(color)
		balls.set_instance_color(i, color)
	var instance := MultiMeshInstance3D.new()
	instance.name = "DeepPitBalls"
	instance.multimesh = balls
	scattered_instances = balls
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	source.free()

func _moving_balls() -> void:
	var source := PLAY_PLACE.instantiate()
	var source_ball := source.find_child("Ball_0000", true, false) as MeshInstance3D
	var mesh := source_ball.mesh.duplicate() as Mesh
	var material := Geo.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color("69717a")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.surface_set_material(0, material)
	var balls := MultiMesh.new()
	balls.transform_format = MultiMesh.TRANSFORM_3D
	balls.use_colors = true
	balls.mesh = mesh
	balls.instance_count = MOVING_LAYERS * BALLS_PER_LAYER
	balls.custom_aabb = AABB(Vector3(LEFT, -DEPTH, BACK), Vector3(RIGHT - LEFT, DEPTH, FRONT - BACK))
	var rng := RandomNumberGenerator.new()
	rng.seed = 65412
	var colors := [Color("b64c3e"), Color("c7aa3f"), Color("3364a0")]
	for layer in MOVING_LAYERS:
		var height := -5.4 + layer * 0.32
		layer_heights.append(height)
		for row in BALL_ROWS:
			for column in BALL_COLUMNS:
				var i := layer * BALLS_PER_LAYER + row * BALL_COLUMNS + column
				var stagger := 0.15 if (row + layer) % 2 == 1 else 0.0
				var origin := Vector3(LEFT + 0.34 + column * BALL_X_STEP + stagger + rng.randf_range(-0.035, 0.035), height + rng.randf_range(-0.05, 0.05), BACK + 0.36 + row * BALL_Z_STEP + rng.randf_range(-0.035, 0.035))
				ball_origins.append(origin)
				ball_positions.append(origin)
				balls.set_instance_transform(i, Transform3D(Basis.IDENTITY, origin))
				var color: Color = colors[rng.randi_range(0, 2)]
				moving_colors.append(color)
				balls.set_instance_color(i, color)
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
	for layer in MOVING_LAYERS:
		var shift := 0.0
		while layer_heights[layer] > p.y + 1.0:
			layer_heights[layer] -= LAYER_SPAN
			shift -= LAYER_SPAN
		while layer_heights[layer] < p.y - 4.76:
			layer_heights[layer] += LAYER_SPAN
			shift += LAYER_SPAN
		if shift != 0.0:
			for cell in BALLS_PER_LAYER:
				var index := layer * BALLS_PER_LAYER + cell
				ball_origins[index].y += shift
				ball_positions[index] = ball_origins[index]
				ball_instances.set_instance_transform(index, Transform3D(Basis.IDENTITY, ball_origins[index]))
	var moving := player.velocity.length() > 0.2
	var movers: Array[Vector3] = []
	if moving:
		movers.append(p)
	if threat.circling:
		movers.append(shark.global_position)
	for mover in movers:
		var column := clampi(roundi((mover.x - LEFT - 0.34) / BALL_X_STEP), 0, BALL_COLUMNS - 1)
		var row := clampi(roundi((mover.z - BACK - 0.36) / BALL_Z_STEP), 0, BALL_ROWS - 1)
		for layer in MOVING_LAYERS:
			if absf(layer_heights[layer] - mover.y) > 1.4:
				continue
			for z in range(maxi(0, row - 2), mini(BALL_ROWS - 1, row + 2) + 1):
				for x in range(maxi(0, column - 2), mini(BALL_COLUMNS - 1, column + 2) + 1):
					active_balls[layer * BALLS_PER_LAYER + z * BALL_COLUMNS + x] = true
	var settled: Array[int] = []
	for index in active_balls:
		var i: int = index
		var origin := ball_origins[i]
		var source := p
		if threat.circling and origin.distance_to(shark.global_position) < origin.distance_to(p):
			source = shark.global_position
		var away := origin - source
		var distance := away.length()
		var target := origin
		if (moving or threat.circling) and distance < 1.2 and distance > 0.001:
			target += away / distance * (1.2 - distance) * 0.45
		var next_pos := ball_positions[i].lerp(target, minf(1.0, delta * 10.0))
		ball_positions[i] = next_pos
		ball_instances.set_instance_transform(i, Transform3D(Basis.IDENTITY, next_pos))
		if next_pos.distance_to(origin) < 0.01 and (not moving and not threat.circling or distance >= 1.2):
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
