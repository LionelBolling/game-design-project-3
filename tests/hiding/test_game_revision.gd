extends GutTest

const StalkerScript: Script = preload("res://scripts/stalker.gd")
const PlayerScript: Script = preload("res://scripts/player.gd")

class FakePlayer:
	extends CharacterBody3D
	var control_enabled: bool = true
	var lit: bool = false
	func beam_hits(_point: Vector3) -> bool:
		return lit

class FakeWorld:
	extends Node3D
	const STALKER_SPAWN: Vector3 = Vector3.ZERO
	func route(from: Vector3, to: Vector3) -> PackedVector2Array:
		return PackedVector2Array([Vector2(from.x, from.z), Vector2(to.x, to.z)])

class FakeRonald:
	extends "res://scripts/stalker.gd"
	var sight: bool = true
	var test_board: Blackboard
	func _can_see_player() -> bool:
		return sight
	func _find_board() -> Blackboard:
		return test_board

func test_dark_speed_is_double_and_beam_stops_ronald() -> void:
	var ronald: Node3D = autofree(Node3D.new())
	ronald.set_script(StalkerScript)
	assert_almost_eq(float(ronald.call("movement_speed", false)), 3.3, 0.001)
	assert_eq(float(ronald.call("movement_speed", true)), 0.0)
	ronald.set("cinematic_sprinting", true)
	assert_almost_eq(float(ronald.call("movement_speed", false)), 6.6, 0.001)
	ronald.set("cinematic_sprinting", false)
	assert_almost_eq(float(ronald.call("movement_speed", false)), 3.3, 0.001)

func test_continuous_beam_triggers_one_pounce_and_hiding_breaks_charge() -> void:
	var ronald: Node3D = autofree(Node3D.new())
	ronald.set_script(StalkerScript)
	assert_false(bool(ronald.call("charge_light_attack", true, false, 5.99)))
	assert_true(bool(ronald.call("charge_light_attack", true, false, 0.01)))
	assert_false(bool(ronald.call("charge_light_attack", true, false, 10.0)), "One pounce per charge")
	ronald.call("reset_light_attack")
	assert_false(bool(ronald.call("charge_light_attack", true, false, 2.0)))
	assert_false(bool(ronald.call("charge_light_attack", true, true, 20.0)), "Hiding flashlight cannot provoke or stop him")
	assert_eq(float(ronald.get("beam_exposure")), 0.0)
	assert_false(bool(ronald.call("charge_light_attack", true, false, 2.0)))
	assert_false(bool(ronald.call("charge_light_attack", false, false, 0.1)))
	assert_eq(float(ronald.get("beam_exposure")), 0.0)

func test_battery_drains_twice_as_fast_and_clamps_at_zero() -> void:
	var player: CharacterBody3D = autofree(CharacterBody3D.new())
	player.set_script(PlayerScript)
	player.set("battery", 100.0)
	player.set("flashlight_on", true)
	player.call("drain_battery", 10.0)
	assert_almost_eq(float(player.get("battery")), 83.2, 0.001)
	player.call("drain_battery", 100.0)
	assert_eq(float(player.get("battery")), 0.0)
	player.set("battery", 50.0)
	player.set("flashlight_on", false)
	player.call("drain_battery", 10.0)
	assert_eq(float(player.get("battery")), 50.0)

func test_hidden_light_cannot_stop_checking_a_revealed_area() -> void:
	var player: FakePlayer = FakePlayer.new()
	add_child_autofree(player)
	player.position = Vector3(0, 0, -8)
	player.lit = true
	var world: FakeWorld = FakeWorld.new()
	add_child_autofree(world)
	var board: Blackboard = Blackboard.new()
	board.writer = Blackboard.ANY
	board.hide_state = BoardTypes.Hide.HIDDEN
	board.location_leaked = true
	var ronald: FakeRonald = FakeRonald.new()
	ronald.player = player
	ronald.world = world
	ronald.test_board = board
	ronald.sight = false
	add_child_autofree(ronald)
	ronald.set_physics_process(false)
	ronald.active = true
	ronald.grace = 0.0
	ronald._physics_process(0.1)
	assert_false(ronald.frozen)
	assert_true(ronald.moving)
	assert_true(ronald.chasing)
	assert_eq(ronald.beam_exposure, 0.0)
	var area: Vector3 = ronald.investigation_target
	var before: float = ronald.position.distance_to(area)
	board.hide_state = BoardTypes.Hide.EXPOSED
	board.location_leaked = false
	player.lit = false
	ronald._physics_process(0.1)
	assert_true(ronald.investigating, "He checks the revealed area after the player leaves sight")
	assert_lt(ronald.position.distance_to(area), before)

func test_original_animation_restored_and_taps_stop_when_stationary() -> void:
	var ronald: Node3D = Node3D.new()
	ronald.set_script(StalkerScript)
	add_child_autofree(ronald)
	var animation: AnimationPlayer = ronald.get("animation") as AnimationPlayer
	assert_false(animation.has_animation(&"run"), "Generated running animation must be absent")
	ronald.call("update_locomotion", 0.25, 0.1)
	assert_true(bool(ronald.get("moving")))
	assert_eq(animation.current_animation, "Armature|mixamo_com|Layer0")
	assert_eq(animation.speed_scale, 1.0)
	assert_almost_eq(animation.get_animation(animation.current_animation).length, 1.5333333, 0.001)
	assert_eq(int(ronald.get("footstep_count")), 1)
	var skeleton: Skeleton3D = ronald.get("skeleton") as Skeleton3D
	var leg: int = skeleton.find_bone("mixamorig_LeftUpLeg")
	animation.advance(0.0)
	var start: Quaternion = skeleton.get_bone_pose_rotation(leg)
	animation.advance(0.16)
	assert_false(skeleton.get_bone_pose_rotation(leg).is_equal_approx(start), "Original clip must animate Ronald's legs")
	ronald.call("update_locomotion", 0.0, 1.0)
	assert_false(bool(ronald.get("moving")))
	assert_false(animation.is_playing())
	assert_eq(int(ronald.get("footstep_count")), 1)

func test_actual_movement_detection_and_light_freeze() -> void:
	var player: FakePlayer = FakePlayer.new()
	add_child_autofree(player)
	player.position = Vector3(0, 0, -8)
	var world: FakeWorld = FakeWorld.new()
	add_child_autofree(world)
	var ronald: FakeRonald = FakeRonald.new()
	ronald.player = player
	ronald.world = world
	add_child_autofree(ronald)
	ronald.set_physics_process(false)
	ronald.active = true
	ronald.grace = 0.0
	ronald._physics_process(0.1)
	assert_almost_eq(ronald.position.length(), 0.33, 0.001, "Actual movement uses 3.3 m/s")
	assert_true(ronald.chasing, "Clear sight starts chase")
	assert_true(ronald.moving)
	var previous_position: Vector3 = ronald.position
	var taps: int = ronald.footstep_count
	player.lit = true
	ronald._physics_process(0.1)
	assert_eq(ronald.position, previous_position, "Flashlight beam still freezes Ronald")
	assert_false(ronald.moving)
	assert_eq(ronald.footstep_count, taps)
	assert_false(ronald.animation.is_playing())
	player.lit = false
	ronald.sight = false
	ronald._physics_process(0.1)
	assert_false(ronald.chasing, "Occluded player must not trigger chase music")
