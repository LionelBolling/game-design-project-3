extends Node3D

const SWIM_VARIANTS := 6
const IDLE_VARIANTS := 3
const PASS_DURATION := 6.5
const IDLE_DURATION := 7.0

var player: CharacterBody3D
var windows: Array[Node3D] = []
var silhouette: MeshInstance3D
var silhouette_material: ShaderMaterial
var active_window := -1
var variant := -1
var animation_time := 0.0
var cooldown := 4.0
var scan_clock := 0.0
var previous_window := -1

func setup(views: Array[Node3D]) -> void:
	windows = views
	var shape := QuadMesh.new()
	shape.size = Vector2(0.62, 0.32)
	silhouette_material = ShaderMaterial.new()
	silhouette_material.shader = preload("res://shaders/abyss_leviathan.gdshader")
	silhouette = MeshInstance3D.new()
	silhouette.name = "DistantLeviathanAnimation"
	silhouette.mesh = shape
	silhouette.material_override = silhouette_material
	silhouette.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(silhouette)
	silhouette.hide()

func _process(delta: float) -> void:
	if player == null:
		return
	if variant >= 0:
		advance(delta)
		return
	cooldown -= delta
	scan_clock -= delta
	if scan_clock > 0.0:
		return
	scan_clock = 0.25
	var candidate := _facing_window()
	if candidate < 0:
		return
	var distance: float = player.camera.global_position.distance_to(windows[candidate].global_position)
	if cooldown <= 0.0:
		var chosen := randi_range(0, SWIM_VARIANTS - 1)
		if candidate != previous_window and distance < 4.3 and randf() < 0.45:
			chosen = SWIM_VARIANTS + randi_range(0, IDLE_VARIANTS - 1)
		start_variant(candidate, chosen)
		previous_window = candidate
	elif candidate != previous_window and distance < 3.3 and randf() < 0.22:
		start_variant(candidate, SWIM_VARIANTS + randi_range(0, IDLE_VARIANTS - 1))
		previous_window = candidate

func _facing_window() -> int:
	var best := 7.0
	var result := -1
	var forward: Vector3 = -player.camera.global_basis.z
	for index in windows.size():
		var to_window: Vector3 = windows[index].global_position - player.camera.global_position
		var distance := to_window.length()
		if distance < best and distance > 0.3 and forward.dot(to_window / distance) > 0.72:
			best = distance
			result = index
	return result

func start_variant(window_index: int, animation_id: int) -> void:
	if window_index < 0 or window_index >= windows.size() or animation_id < 0 or animation_id >= SWIM_VARIANTS + IDLE_VARIANTS:
		return
	active_window = window_index
	variant = animation_id
	animation_time = 0.0
	silhouette.reparent(windows[window_index], false)
	silhouette.show()
	_pose()

func advance(delta: float) -> void:
	if variant < 0:
		return
	animation_time += delta
	var duration := IDLE_DURATION if variant >= SWIM_VARIANTS else PASS_DURATION
	if animation_time >= duration:
		silhouette.hide()
		variant = -1
		active_window = -1
		cooldown = randf_range(12.0, 23.0)
		return
	_pose()

func _pose() -> void:
	var t := animation_time
	var x := 0.0
	var y := 0.0
	var roll := 0.0
	var facing := 1.0
	var opacity := 0.39
	if variant < SWIM_VARIANTS:
		var u := clampf(t / PASS_DURATION, 0.0, 1.0)
		match variant:
			0:
				x = lerpf(-10.0, 10.0, u)
				y = 0.1 + sin(u * PI) * 0.35
			1:
				x = lerpf(10.0, -10.0, u)
				y = -0.25 + sin(u * PI) * 0.28
				facing = -1.0
			2:
				x = lerpf(-10.0, 10.0, u)
				y = lerpf(-2.0, 2.0, u)
				roll = 0.12
			3:
				x = lerpf(10.0, -10.0, u)
				y = lerpf(2.0, -2.0, u)
				roll = -0.12
				facing = -1.0
			4:
				x = lerpf(-10.0, 10.0, u)
				y = 0.7 * sin(u * TAU * 1.5)
				roll = 0.11 * cos(u * TAU * 1.5)
			5:
				x = lerpf(10.0, -10.0, u)
				y = -0.7 + sin(u * PI) * 1.4
				roll = -0.13 * sin(u * PI)
				facing = -1.0
		opacity *= smoothstep(0.0, 0.7, t) * (1.0 - smoothstep(PASS_DURATION - 0.9, PASS_DURATION, t))
	else:
		var idle := variant - SWIM_VARIANTS
		match idle:
			0:
				x = -0.22 + sin(t * 0.42) * 0.055
				y = sin(t * 0.63) * 0.07
			1:
				x = 0.32 + sin(t * 0.25) * 0.08
				y = -0.18 + sin(t * 0.55) * 0.045
				roll = -0.05
				facing = -1.0
			2:
				x = -0.34 + sin(t * 0.31) * 0.06
				y = 0.22 + sin(t * 0.39) * 0.065
				roll = 0.055
		if t > 5.2:
			x += (t - 5.2) * (5.8 if idle == 1 else -5.8)
		opacity *= smoothstep(0.0, 0.6, t) * (1.0 - smoothstep(5.9, IDLE_DURATION, t))
	silhouette.position = Vector3(x * 0.07, y * 0.08 - 0.1, 0.14)
	silhouette.rotation = Vector3(0, 0, roll)
	silhouette.scale = Vector3(facing, 1.0, 1.0)
	silhouette_material.set_shader_parameter("opacity", opacity)
	silhouette_material.set_shader_parameter("tail_phase", t * (0.8 if variant < SWIM_VARIANTS else 0.28))
