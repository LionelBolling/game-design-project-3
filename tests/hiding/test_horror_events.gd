extends GutTest

class FakeEvents:
	extends "res://systems/hiding/horror_events.gd"
	var clear_space: bool = true
	var seen: bool = false
	var roll: float = 0.0
	var rolls: int = 0
	var flash_roll: float = 0.0
	func _flash_roll() -> float:
		return flash_roll
	func _apparition_roll() -> float:
		rolls += 1
		return roll
	func _find_spawn_position(camera: Camera3D) -> Vector3:
		return camera.global_position + Vector3(0, -0.98, 4.5) if clear_space else Vector3.INF
	func _visible_to_camera(_camera: Camera3D) -> bool:
		return seen
	func _clear_floor_position(candidate: Vector3, _camera: Camera3D) -> Vector3:
		return candidate if clear_space else Vector3.INF

var events: FakeEvents
var camera: Camera3D

func before_each() -> void:
	events = FakeEvents.new()
	add_child_autofree(events)
	events.set_process(false)
	events.flash_delay = 100.0
	events.apparition_delay = 0.0
	events.ronald_spawned = true
	camera = Camera3D.new()
	add_child_autofree(camera)
	camera.position.y = 0.98

func test_catch_scare_and_scream_fire_once_then_clear() -> void:
	events.start_catch()
	events.start_catch()
	assert_false(events.screen.visible, "Catch never uses the warning GUI")
	assert_eq(events.scream_count, 1)
	assert_not_null(events.scream.stream)
	events.advance(1.3, &"dead", camera, true, false)
	assert_false(events.screen.visible, "Death screen returns after the jumpscare")
	assert_false(events.scream.playing)

func test_random_flash_has_words_static_and_cooldown() -> void:
	events.flash_delay = 0.0
	events.advance(0.01, &"play", camera, false, false)
	assert_eq(events.screen.words, "you better run")
	assert_true(events.screen.visible)
	assert_eq(events.flash_count, 1)
	assert_eq(events.flash_scream_count, 1)
	assert_not_null(events.static_audio.stream)
	assert_eq(events.flash_delay, 13.0)
	events.advance(0.4, &"play", camera, false, false)
	assert_false(events.screen.visible)
	assert_false(events.static_audio.playing)
	assert_eq(events.flash_count, 1)

func test_apparition_waits_behind_then_vanishes_after_turn() -> void:
	turn_around()
	assert_true(events.entity.visible)
	assert_eq(events.apparition_scream_count, 1)
	assert_eq(events.scream.stream.resource_path, "res://systems/hiding/terror_scream.wav")
	assert_eq(events.scream.volume_db, 0.0)
	assert_gt(events.entity.global_position.z, camera.global_position.z)
	assert_false(events.apparition_seen)
	camera.position.x += 3.0
	events.advance(0.01, &"play", camera, true, false)
	assert_almost_eq(events.entity.global_position.x, camera.global_position.x, 0.001, "Figure follows translation without dodging a turn")
	events.seen = true
	events.advance(0.01, &"play", camera, true, false)
	assert_true(events.apparition_seen)
	assert_eq(events.apparition_scream_count, 1, "Observation does not replay the spawn scream")
	assert_true(events.entity.visible)
	assert_false(events.screen.visible, "Warnings are occasional after Ronald spawns, not triggered by the figure")
	assert_eq(events.flash_count, 0)
	var from: Vector3 = events.entity.global_position
	events.advance(0.25, &"play", camera, true, false)
	assert_lt(events.entity.global_position.distance_to(camera.global_position), from.distance_to(camera.global_position), "Seen figure lunges at the live camera")
	events.advance(0.7, &"play", camera, true, false)
	assert_false(events.entity.visible)
	assert_eq(events.apparition_delay, 3.0)

func test_no_spawn_in_blocked_space_or_while_hiding_or_chasing() -> void:
	events.apparition_delay = 0.0
	events.clear_space = false
	turn_around()
	assert_false(events.entity.visible)
	events.clear_space = true
	events.apparition_delay = 0.0
	events.advance(0.01, &"play", camera, false, false)
	assert_false(events.entity.visible)

func test_unseen_apparition_waits_until_observed_but_clears_in_menu() -> void:
	turn_around()
	assert_true(events.entity.visible)
	events.flash_delay = 1000.0
	events.advance(180.0, &"play", camera, true, false)
	assert_true(events.entity.visible, "Unseen apparition has no time limit")
	events.advance(0.01, &"won", camera, true, false)
	assert_false(events.entity.visible)

func test_menus_cancel_events_and_reduced_motion_suppresses_random_flashes() -> void:
	events.flash_delay = 0.0
	events.advance(0.1, &"play", camera, false, true)
	assert_false(events.screen.visible)
	events.advance(0.1, &"play", camera, false, false)
	assert_true(events.screen.visible)
	events.advance(0.1, &"home", camera, true, false)
	assert_false(events.screen.visible)
	assert_false(events.entity.visible)
	assert_false(events.static_audio.playing)

func test_chase_static_stays_until_chase_ends() -> void:
	events.set_chase_static(true)
	events.advance(2.0, &"play", camera, false, false)
	assert_true(events.chase_overlay.visible)
	assert_false(events.screen.visible, "Chase static must not obscure the game with a face")
	events.set_chase_static(false)
	assert_false(events.chase_overlay.visible)

func test_warning_flashes_wait_for_ronald_spawn() -> void:
	events.ronald_spawned = false
	events.flash_delay = 0.0
	events.advance(60.0, &"play", camera, false, false)
	assert_false(events.screen.visible)
	assert_eq(events.flash_count, 0)
	events.ronald_spawned = true
	events.advance(0.01, &"play", camera, false, false)
	assert_true(events.screen.visible)
	assert_eq(events.flash_count, 1)

func turn_around() -> void:
	events.advance(0.01, &"play", camera, true, false)
	camera.rotation.y += PI
	events.advance(0.01, &"play", camera, true, false)

func test_turn_chance_boundary_and_no_idle_or_small_turn_rolls() -> void:
	events.roll = 0.35
	turn_around()
	assert_false(events.entity.visible)
	assert_eq(events.rolls, 1)
	events.advance(3.1, &"play", camera, true, false)
	camera.rotation.y += 0.2
	events.advance(0.01, &"play", camera, true, false)
	assert_eq(events.rolls, 1, "Small turns and waiting cannot roll")
	events.roll = 0.34999
	camera.rotation.y += PI
	events.advance(0.01, &"play", camera, true, false)
	assert_true(events.entity.visible)
	assert_eq(events.rolls, 2)

func test_turn_cooldown_prevents_immediate_rerolls() -> void:
	events.roll = 0.9
	turn_around()
	camera.rotation.y += PI
	events.advance(0.1, &"play", camera, true, false)
	assert_eq(events.rolls, 1)

func test_flash_has_half_chance_each_thirteen_seconds() -> void:
	events.flash_delay = 13.0
	events.flash_roll = 0.5
	events.advance(12.99, &"play", camera, false, false)
	assert_eq(events.flash_count, 0)
	events.advance(0.02, &"play", camera, false, false)
	assert_eq(events.flash_count, 0, "Roll at 50 percent fails")
	assert_eq(events.flash_delay, 13.0)
	events.flash_roll = 0.49999
	events.advance(13.0, &"play", camera, false, false)
	assert_eq(events.flash_count, 1)
	assert_almost_eq(events.entity.scale.y * 3.2, 1.12, 0.001, "Figure matches the player capsule height")
