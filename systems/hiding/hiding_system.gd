class_name HidingSystem
extends SimSystem

const ENTRY_SECONDS: float = 0.5
@export var keyboard: bool = true
## Reuse the main game's player and camera instead of creating a second body.
var external_body: bool = false
var timer: HideTimer = HideTimer.new()
var interact_requested: bool = false
var body: CharacterBody3D
var camera: Camera3D
var hud: HidingHud
var _spot: HideSpot
var _entering: HideSpot
var _entry_time: float = 0.0
var _return_position: Vector3 = Vector3.ZERO
var _e_down: bool = false
var _playing: bool = true
var _pitch: float = 0.0
var _table_fill: OmniLight3D

func _init() -> void:
	system_id = &"hiding"

func _ready() -> void:
	if external_body:
		hud = HidingHud.new()
		add_child(hud)
		return
	if not keyboard:
		return
	body = CharacterBody3D.new()
	add_child(body)
	body.position = Vector3(0, 0, 4)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.2
	capsule.height = 0.9
	shape.shape = capsule
	shape.position.y = 0.45
	body.add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 0.98
	camera.fov = 76.0
	camera.near = 0.04
	body.add_child(camera)
	camera.current = true
	hud = HidingHud.new()
	add_child(hud)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup(board: Blackboard) -> void:
	board.player_position = body.global_position if body != null else Vector3.ZERO
	board.player_noise = 0.0
	board.hide_state = BoardTypes.Hide.EXPOSED
	board.hide_spot = &""
	board.hide_time = 0.0
	board.location_leaked = false
	board.player_at_exit = false

func tick(board: Blackboard, delta: float) -> void:
	_playing = board.game_state == BoardTypes.Game.PLAYING
	if not _playing:
		interact_requested = false
		board.player_noise = 0.0
		if hud != null:
			hud.refresh(board, timer, false)
		return
	if keyboard:
		_read_interaction()
	var noise: float = 0.0
	if interact_requested:
		if _spot != null:
			noise = 0.6 if _spot.spot_type == HideSpot.Kind.BALL_PIT else 0.3
			timer.leave()
			_spot = null
			if body != null:
				body.global_position = _return_position
				camera.position.y = 0.98
		elif _entering == null:
			_entering = _nearby_spot()
			_entry_time = 0.0
	interact_requested = false
	if _entering != null:
		noise = 0.6 if _entering.spot_type == HideSpot.Kind.BALL_PIT else 0.3
		_entry_time += maxf(delta, 0.0)
		if _entry_time >= ENTRY_SECONDS:
			_spot = _entering
			_entering = null
			timer.enter(_spot.spot_id)
			if body != null:
				_return_position = body.global_position
				if not _spot.keep_position:
					body.global_position = _spot.hiding_position()
				body.velocity = Vector3.ZERO
				camera.position.y = _spot.eye_height
				if _spot.face_outward:
					body.rotation.y = _spot.outward_yaw
			timer.advance(maxf(0.0, _entry_time - ENTRY_SECONDS))
	else:
		timer.advance(delta)
		if _spot == null and body != null and not external_body:
			noise = maxf(noise, _move(delta))
	if _spot != null and _spot.spot_type == HideSpot.Kind.TABLE and camera != null:
		_pitch = 0.0
		camera.rotation.x = 0.0
	if camera != null:
		if _table_fill == null:
			_table_fill = OmniLight3D.new()
			_table_fill.name = "TableViewFill"
			_table_fill.light_color = Color("b9c2cc")
			_table_fill.light_energy = 0.35
			_table_fill.omni_range = 2.5
			_table_fill.shadow_enabled = false
			camera.add_child(_table_fill)
		_table_fill.visible = _spot != null and _spot.spot_type == HideSpot.Kind.TABLE
	if external_body:
		body.set("table_look_level", _spot != null and _spot.spot_type == HideSpot.Kind.TABLE)
		if _spot != null and _spot.spot_type == HideSpot.Kind.TABLE:
			body.set("pitch", 0.0)
		body.set("hiding_locked", _spot != null or _entering != null)
		if _spot != null or _entering != null:
			body.velocity = Vector3.ZERO
		elif Vector2(body.velocity.x, body.velocity.z).length() > 0.3:
			noise = maxf(noise, 0.3)
	board.player_position = body.global_position if body != null else board.player_position
	board.player_noise = noise
	board.hide_state = BoardTypes.Hide.HIDDEN if timer.spot_id != &"" else BoardTypes.Hide.EXPOSED
	board.hide_spot = timer.spot_id
	board.hide_time = timer.hide_time
	board.location_leaked = timer.leaked()
	if hud != null:
		hud.refresh(board, timer, _nearby_spot() != null)

func _nearby_spot() -> HideSpot:
	if body == null or not is_inside_tree():
		return null
	var nearest: HideSpot = null
	var distance: float = INF
	for node: Node in get_tree().get_nodes_in_group(HideSpot.GROUP):
		var candidate: HideSpot = node as HideSpot
		if candidate == null or candidate.spot_id == &"" or not candidate.overlaps_body(body):
			continue
		if not _entry_is_clear(candidate):
			continue
		var candidate_distance: float = body.global_position.distance_squared_to(candidate.global_position)
		if candidate_distance < distance:
			nearest = candidate
			distance = candidate_distance
	return nearest

func _entry_is_clear(spot: HideSpot) -> bool:
	# Standing-height reach avoids rejecting the far side of a table because
	# of its pedestal. Walls and tall solid cabinets still block interaction.
	var eye: Vector3 = spot.hiding_position() + Vector3.UP * 0.98
	var from: Vector3 = body.global_position + Vector3.UP * 0.98
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, eye, 1)
	return body.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _read_interaction() -> void:
	var down: bool = Input.is_physical_key_pressed(KEY_E)
	interact_requested = down and not _e_down and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_e_down = down

func _move(delta: float) -> float:
	var movement: Vector2 = Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		movement = Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	var direction: Vector3 = body.basis * Vector3(movement.x, 0, movement.y)
	body.velocity.x = direction.x * 2.5
	body.velocity.z = direction.z * 2.5
	body.velocity.y = 0.0 if body.is_on_floor() else body.velocity.y - 9.8 * delta
	body.move_and_slide()
	return 0.3 if movement != Vector2.ZERO else 0.0

func _unhandled_input(event: InputEvent) -> void:
	if external_body or not keyboard or camera == null:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and _playing and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		body.rotate_y(-event.relative.x * 0.002)
		_pitch = clampf(_pitch - event.relative.y * 0.002, -1.3, 1.3)
		if _spot != null and _spot.spot_type == HideSpot.Kind.TABLE:
			_pitch = 0.0
		camera.rotation.x = _pitch
