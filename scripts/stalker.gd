extends Node3D
const CLOWN_SCENE = preload("res://Blender models/ps1-clown.glb")
const CHASE_DISTANCE := 12.0
const TABLE_REACH_DISTANCE: float = 2.0
const TABLE_APPROACH_OFFSET: Vector3 = Vector3(0, 0, 1.5)
const LIGHT_ATTACK_SECONDS: float = 6.0
const INVESTIGATION_SECONDS: float = 5.0
var beam_exposure: float = 0.0
var light_attack_requested: bool = false
var investigating: bool = false
var investigation_target: Vector3 = Vector3.ZERO
var _investigation_left: float = 0.0
var active := false
var player: CharacterBody3D
var world: Node3D
var clown: Node3D
var animation: AnimationPlayer
var path := PackedVector2Array()
var path_timer := 0.0
var clock := 0.0
var frozen := false
var grace := 4.0
var speed := 1.65
var patrol_target := Vector3.ZERO
var patrol_target_valid := false
var rng := RandomNumberGenerator.new()
var _was_protected: bool = false
var chasing: bool = false
var moving: bool = false
var cinematic_turning: bool = false
var cinematic_sprinting: bool = false
var cinematic_target: Vector3 = Vector3.ZERO
var _table_target_for: Vector3 = Vector3.INF
var _table_target: Vector3 = Vector3.ZERO
var _movement_animation: StringName = &""
var skeleton: Skeleton3D
var footsteps: AudioStreamPlayer3D
var footstep_count: int = 0
var _stride_distance: float = 0.0
var _has_stepped: bool = false
signal caught
signal light_attack

func _ready() -> void:
	rng.randomize()
	clown = CLOWN_SCENE.instantiate() as Node3D
	if clown == null:
		push_error("The PS1 clown scene could not be instantiated.")
		return
	clown.scale = Vector3.ONE * 0.4
	clown.rotation.y = PI
	add_child(clown)
	animation = clown.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation == null or animation.get_animation_list().is_empty():
		push_error("The PS1 clown scene has no imported animation.")
		return
	var animation_name := animation.get_animation_list()[0]
	animation.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	_movement_animation = StringName(animation_name)
	animation.play(_movement_animation)
	skeleton = clown.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		var skeletons: Array[Node] = clown.find_children("*", "Skeleton3D", true, false)
		if not skeletons.is_empty():
			skeleton = skeletons[0] as Skeleton3D
	animation.pause()
	footsteps = AudioStreamPlayer3D.new()
	footsteps.stream = load("res://systems/hiding/floor_tap.wav") as AudioStream
	footsteps.position.y = 0.15
	footsteps.unit_size = 5.0
	footsteps.max_distance = 28.0
	footsteps.volume_db = -3.0
	add_child(footsteps)
	visible = false

func awaken() -> void:
	if active:
		return
	position = world.STALKER_SPAWN
	active = true
	visible = true
	grace = 4.0
	path.clear()
	patrol_target_valid = false
	path_timer = 0.0

func _physics_process(delta: float) -> void:
	if not active or (not player.control_enabled and not cinematic_sprinting):
		chasing = false
		update_locomotion(0.0, delta)
		return
	clock += delta
	grace = maxf(0, grace - delta)
	var player_offset := Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z)
	var board: Blackboard = _find_board()
	var protected: bool = false
	var leaked: bool = false
	var hidden: bool = false
	if board != null:
		hidden = board.hide_state == BoardTypes.Hide.HIDDEN
		protected = hidden and not board.location_leaked
		leaked = board.location_leaked
	var beam_freezing: bool = player.beam_hits(global_position + Vector3(0, 1.55, 0))
	frozen = beam_freezing and not hidden and not cinematic_sprinting
	if grace <= 0.0 and not cinematic_sprinting and not cinematic_turning:
		if charge_light_attack(beam_freezing, hidden, delta):
			frozen = false
			update_locomotion(0.0, delta)
			light_attack.emit()
			return
	else:
		beam_exposure = 0.0
	if leaked:
		investigation_target = table_approach_target() if hidden else player.global_position
		_investigation_left = INVESTIGATION_SECONDS
	else:
		_investigation_left = maxf(0.0, _investigation_left - delta)
	if protected != _was_protected:
		path.clear()
		patrol_target_valid = false
		path_timer = 0.0
	_was_protected = protected
	chasing = not protected and (leaked or (player_offset.length() <= CHASE_DISTANCE and _can_see_player()))
	investigating = not chasing and _investigation_left > 0.0 and global_position.distance_to(investigation_target) > 0.45
	if cinematic_turning or frozen or (grace > 0 and not cinematic_sprinting):
		update_locomotion(0.0, delta)
		return
	var previous_position: Vector3 = global_position
	if chasing or investigating or cinematic_sprinting:
		path_timer -= delta
		if path_timer <= 0:
			path_timer = 0.65
			# Tabletop collision excludes the hidden feet from the navigation
			# grid. Approach the open +Z side used by the table hiding view.
			var destination: Vector3 = player.global_position if chasing else investigation_target
			if chasing and hidden and leaked:
				destination = table_approach_target()
			if cinematic_sprinting:
				destination = cinematic_target
			path = world.route(global_position, destination)
			if path.size() > 1:
				path.remove_at(0)
			else:
				path.clear()
	elif not patrol_target_valid or global_position.distance_to(patrol_target) < 0.7:
		path_timer -= delta
		if path_timer <= 0:
			path_timer = 1.0
			_choose_patrol_target()
	elif path.is_empty():
		patrol_target_valid = false
		path_timer = 0.0
	if not path.is_empty():
		var waypoint := Vector3(path[0].x, world.STALKER_SPAWN.y, path[0].y)
		var facing := waypoint - global_position
		facing.y = 0
		if facing.length_squared() > 0.01:
			look_at(global_position + facing, Vector3.UP)
		position = position.move_toward(waypoint, movement_speed(frozen) * delta)
		if position.distance_to(waypoint) < 0.08:
			path.remove_at(0)
	update_locomotion(global_position.distance_to(previous_position), delta)
	var catch_distance: float = TABLE_REACH_DISTANCE if hidden and leaked else 0.85
	var distance_to_player: float = Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z).length()
	if not cinematic_sprinting and not cinematic_turning and grace <= 0.0 and not protected and distance_to_player < catch_distance and (not hidden or _can_reach_under_table()):
		active = false
		chasing = false
		update_locomotion(0.0, delta)
		caught.emit()

func movement_speed(in_beam: bool) -> float:
	return 0.0 if in_beam else speed * (4.0 if cinematic_sprinting else 2.0)

func table_approach_target() -> Vector3:
	if player.global_position == _table_target_for:
		return _table_target
	_table_target_for = player.global_position
	_table_target = player.global_position + TABLE_APPROACH_OFFSET
	# Find the open side without requiring a new shared board value. Booth
	# pedestals and the dining divider can block the former fixed +Z approach.
	for offset: Vector3 in [TABLE_APPROACH_OFFSET, -TABLE_APPROACH_OFFSET, Vector3(1.5, 0, 0), Vector3(-1.5, 0, 0)]:
		var at: Vector3 = player.global_position + offset
		var route_to_area: PackedVector2Array = world.route(global_position, at)
		if route_to_area.is_empty():
			continue
		# The navigation grid can project a nominal point away from a counter.
		# Capture the actual reachable endpoint so sprint arrival can complete.
		at = Vector3(route_to_area[-1].x, player.global_position.y, route_to_area[-1].y)
		var distance: float = Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length()
		if distance > 1.8 or distance < 0.6:
			continue
		var reach: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 0.28, at + Vector3.UP * 0.28, 1)
		if not get_world_3d().direct_space_state.intersect_ray(reach).is_empty():
			continue
		_table_target = at
		break
	return _table_target

func charge_light_attack(lit: bool, hidden: bool, delta: float) -> bool:
	if not lit or hidden:
		beam_exposure = 0.0
		return false
	if light_attack_requested:
		return false
	beam_exposure += maxf(0.0, delta)
	if beam_exposure >= LIGHT_ATTACK_SECONDS:
		light_attack_requested = true
		return true
	return false

func reset_light_attack() -> void:
	beam_exposure = 0.0
	light_attack_requested = false

func _find_board() -> Blackboard:
	var director: Director = get_tree().get_first_node_in_group(Director.GROUP) as Director
	return director.board if director != null else null

func _can_see_player() -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.25, 0), player.camera.global_position, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _can_reach_under_table() -> bool:
	# Reach below the tabletop, while walls and furniture still block a grab.
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.4, 0), player.camera.global_position, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func update_locomotion(distance: float, delta: float) -> void:
	moving = distance > 0.0001 and delta > 0.0
	if animation == null:
		return
	if not moving:
		animation.pause()
		_stride_distance = 0.0
		_has_stepped = false
		if footsteps != null:
			footsteps.stop()
		return
	if animation.current_animation != _movement_animation or not animation.is_playing():
		animation.play(_movement_animation)
	animation.speed_scale = 2.0 if cinematic_sprinting else 1.0
	_stride_distance += distance
	if not _has_stepped or _stride_distance >= 0.9:
		_has_stepped = true
		_stride_distance = fmod(_stride_distance, 0.9)
		footstep_count += 1
		if footsteps != null and DisplayServer.get_name() != "headless":
			footsteps.pitch_scale = rng.randf_range(0.9, 1.08)
			footsteps.play()

func _choose_patrol_target() -> void:
	for attempt in 16:
		var candidate := Vector3(rng.randf_range(-33.0, 33.0), world.STALKER_SPAWN.y, rng.randf_range(-22.0, 22.0))
		var candidate_path: PackedVector2Array = world.route(global_position, candidate)
		if candidate_path.size() < 2:
			continue
		var destination := Vector3(candidate_path[-1].x, world.STALKER_SPAWN.y, candidate_path[-1].y)
		if global_position.distance_to(destination) < 5.0:
			continue
		path = candidate_path
		path.remove_at(0)
		patrol_target = destination
		patrol_target_valid = true
		return
	patrol_target_valid = false
