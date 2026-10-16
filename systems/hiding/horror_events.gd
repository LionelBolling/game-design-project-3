class_name HorrorEvents
extends Node3D
## Presentation events only. No damage, board writes, or enemy movement.
const FLASH_INTERVAL: float = 13.0
const FLASH_CHANCE: float = 0.5
const APPARITION_CHANCE: float = 0.35
const TURN_COOLDOWN: float = 3.0
const TURN_DOT: float = -0.8660254 # 150 degrees of horizontal rotation.
const SEEN_SECONDS: float = 0.55
var chase_overlay: ChaseStatic
var chase_active: bool = false
var ronald_spawned: bool = false
var screen: ScareScreen
var entity: ShadowApparition
var scream: AudioStreamPlayer
var static_audio: AudioStreamPlayer
var scream_count: int = 0
var flash_count: int = 0
var flash_scream_count: int = 0
var attack_scream_count: int = 0
var apparition_scream_count: int = 0
var flash_delay: float = 22.0
var apparition_delay: float = 0.0
var _turn_heading: Vector3 = Vector3.ZERO
var _spawn_behind: Vector3 = Vector3.ZERO
var apparition_seen: bool = false
var _apparition_time: float = 0.0
var _lunge_start: Vector3 = Vector3.ZERO
var _caught_once: bool = false
var _entity_offset: Vector3 = Vector3.ZERO
var _last_camera_position: Vector3 = Vector3.ZERO
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	flash_delay = FLASH_INTERVAL
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	chase_overlay = ChaseStatic.new()
	layer.add_child(chase_overlay)
	screen = ScareScreen.new()
	layer.add_child(screen)
	entity = ShadowApparition.new()
	add_child(entity)
	scream = AudioStreamPlayer.new()
	scream.stream = load("res://systems/hiding/terror_scream.wav") as AudioStream
	scream.volume_db = 0.0
	add_child(scream)
	static_audio = AudioStreamPlayer.new()
	var noise: AudioStreamWAV = load("res://systems/hiding/screen_static.wav") as AudioStreamWAV
	noise.loop_mode = AudioStreamWAV.LOOP_FORWARD
	noise.loop_end = noise.data.size() / 2
	static_audio.stream = noise
	static_audio.volume_db = -17.0
	add_child(static_audio)

func _process(delta: float) -> void:
	var game: Node = get_parent()
	var player: Node3D = game.get("player") as Node3D
	var ronald: Node = game.get("stalker") as Node
	if player == null or ronald == null:
		return
	ronald_spawned = bool(ronald.get("active")) and bool(ronald.get("visible"))
	var allow_entity: bool = not bool(player.get("hiding_locked")) and not bool(ronald.get("chasing"))
	set_chase_static(game.get("phase") == "play" and bool(ronald.get("chasing")))
	var cutscene: TimeoutCutscene = game.get("timeout_scene") as TimeoutCutscene
	if cutscene != null and cutscene.camera_locked:
		_turn_heading = Vector3.ZERO
		screen.hide()
		chase_overlay.advance(delta)
		return
	advance(delta, StringName(game.get("phase")), player.get("camera") as Camera3D, allow_entity, bool(player.get("reduce_motion")))

func advance(delta: float, phase: StringName, camera: Camera3D, allow_entity: bool, reduced: bool) -> void:
	var elapsed: float = maxf(delta, 0.0)
	if (phase == &"caught" and _caught_once) or phase == &"grapple":
		_turn_heading = Vector3.ZERO
		screen.hide()
		set_chase_static(false)
		return
	if phase != &"play":
		clear()
		return
	screen.advance(elapsed)
	chase_overlay.reduced_motion = reduced
	chase_overlay.advance(elapsed)
	if not screen.visible and not chase_active:
		static_audio.stop()
	if not reduced and ronald_spawned:
		flash_delay -= elapsed
		if flash_delay <= 0.0 and not screen.visible:
			flash_delay = FLASH_INTERVAL
			if _flash_roll() < FLASH_CHANCE:
				flash_count += 1
				screen.begin(false)
				_play(static_audio)
				flash_scream_count += 1
				scream.volume_db = -2.0
				_play(scream)
	if not allow_entity:
		_turn_heading = Vector3.ZERO
		if not entity.visible:
			return
	if entity.visible:
		_turn_heading = Vector3.ZERO
		if not apparition_seen and camera.global_position.distance_squared_to(_last_camera_position) > 0.0001:
			var follow: Vector3 = _clear_floor_position(camera.global_position + _entity_offset, camera)
			if follow.is_finite():
				entity.global_position = follow
				entity.look_at(Vector3(camera.global_position.x, follow.y, camera.global_position.z))
		_last_camera_position = camera.global_position
		if apparition_seen:
			_apparition_time -= elapsed
			var progress: float = clampf(1.0 - _apparition_time / SEEN_SECONDS, 0.0, 1.0)
			# Keep normal player look/movement; only the hallucination moves.
			var head_offset: Vector3 = Vector3.UP * 2.85 * entity.scale.y
			var destination: Vector3 = camera.global_position - camera.global_basis.z * 0.18 - head_offset
			entity.global_position = _lunge_start.lerp(destination, progress * progress) + Vector3.UP * sin(progress * PI) * 0.4
		if not apparition_seen and _visible_to_camera(camera):
			apparition_seen = true
			_apparition_time = SEEN_SECONDS
			_lunge_start = entity.global_position
		if apparition_seen and _apparition_time <= 0.0:
			_vanish()
	else:
		if _turned_around(camera, elapsed) and not screen.visible and _apparition_roll() < APPARITION_CHANCE:
			var at: Vector3 = _find_spawn_position(camera)
			if at.is_finite():
				entity.global_position = at
				_entity_offset = at - camera.global_position
				_last_camera_position = camera.global_position
				entity.look_at(Vector3(camera.global_position.x, at.y, camera.global_position.z))
				entity.show()
				apparition_scream_count += 1
				scream.volume_db = 0.0
				_play(scream)
				apparition_seen = false
				_apparition_time = 0.0

func _turned_around(camera: Camera3D, elapsed: float) -> bool:
	var heading: Vector3 = -camera.global_basis.z
	heading.y = 0.0
	if heading.length_squared() < 0.01:
		return false
	heading = heading.normalized()
	if apparition_delay > 0.0:
		apparition_delay = maxf(0.0, apparition_delay - elapsed)
		_turn_heading = heading
		return false
	if _turn_heading == Vector3.ZERO:
		_turn_heading = heading
		return false
	if heading.dot(_turn_heading) > TURN_DOT:
		return false
	_spawn_behind = -_turn_heading
	_turn_heading = heading
	apparition_delay = TURN_COOLDOWN
	return true

func _apparition_roll() -> float:
	return _rng.randf()

func _flash_roll() -> float:
	return _rng.randf()

func start_catch() -> void:
	if _caught_once:
		return
	_caught_once = true
	clear()
	_vanish()
	scream_count += 1
	scream.volume_db = 0.0
	_play(scream)

func play_attack_scream() -> void:
	clear()
	attack_scream_count += 1
	scream.volume_db = 0.0
	_play(scream)

func clear() -> void:
	_turn_heading = Vector3.ZERO
	set_chase_static(false)
	if screen != null:
		screen.hide()
	if entity != null:
		if entity.visible:
			_vanish()
	if scream != null:
		scream.stop()
	if static_audio != null:
		static_audio.stop()

func set_chase_static(enabled: bool) -> void:
	chase_active = enabled
	if chase_overlay != null:
		chase_overlay.visible = enabled
	if enabled and static_audio != null:
		static_audio.volume_db = -25.0
		if not static_audio.playing:
			_play(static_audio)
	elif static_audio != null and (screen == null or not screen.visible):
		static_audio.stop()

func _vanish() -> void:
	entity.hide()
	apparition_seen = false
	apparition_delay = TURN_COOLDOWN

func _play(audio: AudioStreamPlayer) -> void:
	if audio == static_audio and screen.visible:
		audio.volume_db = -17.0
	if DisplayServer.get_name() != "headless":
		audio.play()

func _find_spawn_position(camera: Camera3D) -> Vector3:
	var behind: Vector3 = _spawn_behind
	behind.y = 0.0
	if behind.length_squared() < 0.01:
		return Vector3.INF
	var at: Vector3 = camera.global_position + behind.normalized() * 4.5
	return _clear_floor_position(at, camera)

func _clear_floor_position(candidate: Vector3, camera: Camera3D) -> Vector3:
	var at: Vector3 = candidate
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var floor_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(at + Vector3.UP, at + Vector3.DOWN * 3.0, 1)
	var floor_hit: Dictionary = space.intersect_ray(floor_query)
	if floor_hit.is_empty() or (floor_hit.normal as Vector3).dot(Vector3.UP) < 0.8:
		return Vector3.INF
	at.y = (floor_hit.position as Vector3).y + 0.05
	if absf(at.y - (camera.global_position.y - 0.98)) > 0.8:
		return Vector3.INF
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.2
	capsule.height = ShadowApparition.PLAYER_HEIGHT
	var clearance: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	clearance.shape = capsule
	clearance.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * capsule.height * 0.5)
	clearance.collision_mask = 1
	if not space.intersect_shape(clearance, 1).is_empty():
		return Vector3.INF
	var sight: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(camera.global_position, at + Vector3.UP * 0.85, 1)
	return at if space.intersect_ray(sight).is_empty() else Vector3.INF

func _visible_to_camera(camera: Camera3D) -> bool:
	var chest: Vector3 = entity.global_position + Vector3.UP * 2.85 * entity.scale.y
	if not camera.is_position_in_frustum(chest):
		return false
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(camera.global_position, chest, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _exit_tree() -> void:
	clear()
