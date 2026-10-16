extends GutTest

const Threats = preload("res://scripts/act_threats.gd")
const Player = preload("res://scripts/player.gd")
const Depth = preload("res://scripts/ball_depth.gd")

func test_ball_transparency_increases_when_depth_wraps() -> void:
	assert_eq(Depth.ball_alpha_for_loops(0), 1.0)
	assert_eq(Depth.ball_alpha_for_loops(1), 0.84)
	assert_eq(Depth.ball_alpha_for_loops(5), 0.36)

func test_flashlight_halves_swim_speed() -> void:
	var player: CharacterBody3D = Player.new()
	assert_eq(player.swimming_speed(false), 3.2)
	player.flashlight_on = true
	assert_eq(player.swimming_speed(false), 1.6)
	assert_eq(player.swimming_speed(true), 2.1)

func test_act_two_flashlight_needs_no_battery() -> void:
	var player: CharacterBody3D = Player.new()
	add_child(player)
	player.set_battery_system_enabled(false)
	player.battery = 0.0
	player.set_flashlight(true)
	player.update_flashlight_charge(10.0)
	assert_true(player.flashlight_on)
	assert_eq(player.battery, 0.0)
	for light in player.battery_lights:
		assert_false(light.visible)
	player.free()

func test_shark_timing_and_flashlight_pressure() -> void:
	var shark: RefCounted = Threats.Shark.new()
	shark.advance(4.9, false, false)
	assert_false(shark.circling)
	shark.advance(0.1, false, false)
	assert_true(shark.circling)
	shark.advance(7.5, true, false)
	assert_true(shark.bumping)
	shark.advance(20.0, true, false)
	assert_true(shark.aggressive)

func test_shark_stare_and_two_bites() -> void:
	var shark: RefCounted = Threats.Shark.new()
	shark.advance(5.0, false, false)
	shark.advance(3.0, false, true)
	assert_false(shark.aggressive)
	shark.advance(1.0, false, true)
	assert_true(shark.aggressive)
	shark.bite()
	assert_false(shark.dead)
	shark.bite()
	assert_true(shark.dead)

func test_centipede_delay_shortens_after_death() -> void:
	var centipede: RefCounted = Threats.Centipede.new()
	centipede.advance(59.9)
	assert_false(centipede.active)
	centipede.advance(0.1)
	assert_true(centipede.active)
	centipede.reset_after_death()
	centipede.advance(29.9)
	assert_false(centipede.active)
	centipede.advance(0.1)
	assert_true(centipede.active)
