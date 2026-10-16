class_name TimeoutCutscene
extends Node3D
## Current F5 composition: a short, reversible camera/actor presentation.
const TURN_SECONDS: float = 0.65
const RUN_VIEW_SECONDS: float = 0.5
const ARRIVAL_DISTANCE: float = 0.6
const RETURN_GRACE_SECONDS: float = 0.6
var player: CharacterBody3D
var ronald: Node3D
var camera: Camera3D
var voice: AudioStreamPlayer
var voice_seconds: float = 2.6
var voice_count: int = 0
var active: bool = false
var camera_locked: bool = false
var stage: StringName = &""
var _elapsed: float = 0.0
var _last_leaked: bool = false
var _said_line: bool = false
var _saved_controls: bool = true
var _start_yaw: float = 0.0
var _target_yaw: float = 0.0
var _light: OmniLight3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.near = 0.04
	add_child(camera)
	_light = OmniLight3D.new()
	_light.light_energy = 1.1
	_light.omni_range = 6.0
	_light.light_color = Color("c8c3bc")
	_light.hide()
	camera.add_child(_light)
	voice = AudioStreamPlayer.new()
	voice.stream = load("res://systems/hiding/i_see_you.wav") as AudioStream
	voice.pitch_scale = 0.76
	voice.volume_db = -3.0
	voice_seconds = voice.stream.get_length() / voice.pitch_scale
	add_child(voice)

func configure(body: CharacterBody3D, actor: Node3D) -> void:
	player = body
	ronald = actor

func tick(leaked: bool, delta: float) -> void:
	if leaked and not _last_leaked:
		_start()
	_last_leaked = leaked
	if active:
		_advance(maxf(delta, 0.0))

func _start() -> void:
	if active or player == null or ronald == null:
		return
	if not bool(ronald.get("active")):
		ronald.call("awaken")
	active = true
	camera_locked = true
	_elapsed = 0.0
	_said_line = false
	stage = &"turn"
	_saved_controls = bool(player.get("control_enabled"))
	player.set("control_enabled", false)
	player.velocity = Vector3.ZERO
	var destination: Vector3 = player.global_position
	if bool(player.get("hiding_locked")):
		destination = ronald.call("table_approach_target") as Vector3
	ronald.set("cinematic_target", destination)
	var direction: Vector3 = player.global_position - ronald.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		direction = Vector3.FORWARD
	direction = direction.normalized()
	_target_yaw = atan2(-direction.x, -direction.z)
	_start_yaw = _target_yaw + PI
	ronald.rotation.y = _start_yaw
	ronald.set("cinematic_turning", true)
	ronald.set("cinematic_sprinting", false)
	camera.global_position = _choose_camera_position(direction)
	camera.look_at(ronald.global_position + Vector3.UP * 1.2)
	camera.make_current()
	_light.show()

func _advance(delta: float) -> void:
	_elapsed += delta
	var sprint_start: float = TURN_SECONDS + voice_seconds
	var target: Vector3 = ronald.get("cinematic_target") as Vector3
	var remaining: Vector2 = Vector2(target.x - ronald.global_position.x, target.z - ronald.global_position.z)
	if _elapsed >= sprint_start + RUN_VIEW_SECONDS and stage == &"sprint" and remaining.length() <= ARRIVAL_DISTANCE:
		cancel()
		return
	if _elapsed < TURN_SECONDS:
		stage = &"turn"
		ronald.rotation.y = lerp_angle(_start_yaw, _target_yaw, smoothstep(0.0, TURN_SECONDS, _elapsed))
	else:
		ronald.rotation.y = _target_yaw if _elapsed < sprint_start else ronald.rotation.y
		if not _said_line:
			_said_line = true
			voice_count += 1
			if DisplayServer.get_name() != "headless":
				voice.play()
		stage = &"sprint" if _elapsed >= sprint_start else &"voice"
	var sprinting: bool = stage == &"sprint"
	var was_sprinting: bool = bool(ronald.get("cinematic_sprinting"))
	ronald.set("cinematic_turning", not sprinting)
	ronald.set("cinematic_sprinting", sprinting)
	if sprinting and not was_sprinting:
		ronald.set("path_timer", 0.0)
	if sprinting and camera_locked and _elapsed >= sprint_start + RUN_VIEW_SECONDS:
		_return_player_view(true)
		ronald.set("grace", maxf(float(ronald.get("grace")), RETURN_GRACE_SECONDS))
	if camera_locked:
		camera.look_at(ronald.global_position + Vector3.UP * 1.2)

func cancel(restore_controls: bool = true) -> void:
	if not active:
		return
	active = false
	stage = &""
	voice.stop()
	_light.hide()
	if is_instance_valid(ronald):
		ronald.set("cinematic_turning", false)
		ronald.set("cinematic_sprinting", false)
		ronald.set("path_timer", 0.0)
		if restore_controls:
			ronald.set("grace", maxf(float(ronald.get("grace")), RETURN_GRACE_SECONDS))
		var animation: AnimationPlayer = ronald.get("animation") as AnimationPlayer
		if animation != null:
			animation.speed_scale = 1.0
	_return_player_view(restore_controls)

func _return_player_view(restore_controls: bool) -> void:
	if not camera_locked:
		return
	camera_locked = false
	_light.hide()
	if is_instance_valid(player):
		if restore_controls:
			player.set("control_enabled", _saved_controls)
		var original: Camera3D = player.get("camera") as Camera3D
		if is_instance_valid(original) and original.is_inside_tree():
			original.make_current()

func _choose_camera_position(toward_player: Vector3) -> Vector3:
	var target: Vector3 = ronald.global_position + Vector3.UP * 1.2
	var side: Vector3 = toward_player.cross(Vector3.UP)
	var ideal: Vector3 = ronald.global_position + toward_player * 2.8 + side * 0.9 + Vector3.UP * 1.4
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(target, ideal, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return ideal if hit.is_empty() else (hit.position as Vector3) + (hit.normal as Vector3) * 0.15

func _exit_tree() -> void:
	cancel(false)
