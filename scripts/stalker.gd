extends Node3D
const CLOWN_SCENE = preload("res://Blender models/ps1-clown.glb")
const CHASE_DISTANCE := 12.0
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
signal caught

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
	animation.play(animation_name)
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
	if not active or not player.control_enabled:
		return
	clock += delta
	grace = maxf(0, grace - delta)
	var beam_freezing: bool = player.beam_hits(global_position + Vector3(0, 1.25, 0))
	if beam_freezing != frozen:
		frozen = beam_freezing
		if frozen:
			animation.pause()
		else:
			animation.play()
	var player_offset := Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z)
	var chasing := player_offset.length() <= CHASE_DISTANCE
	if frozen or grace > 0:
		return
	if chasing:
		path_timer -= delta
		if path_timer <= 0:
			path_timer = 0.65
			path = world.route(global_position, player.global_position)
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
		position = position.move_toward(waypoint, speed * delta)
		if position.distance_to(waypoint) < 0.08:
			path.remove_at(0)
	if player_offset.length() < 0.85:
		active = false
		caught.emit()

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
