extends GutTest

class FakePlayer:
	extends CharacterBody3D
	var control_enabled: bool = true
	var hiding_locked: bool = false
	var camera: Camera3D
	func _ready() -> void:
		camera = Camera3D.new()
		add_child(camera)
		camera.position.y = 0.5
		camera.make_current()

class FakeRonald:
	extends Node3D
	var active: bool = true
	var cinematic_turning: bool = false
	var cinematic_sprinting: bool = false
	var cinematic_target: Vector3 = Vector3.ZERO
	var path_timer: float = 1.0
	var grace: float = 0.0
	var animation: AnimationPlayer
	func _ready() -> void:
		animation = AnimationPlayer.new()
		add_child(animation)
	func awaken() -> void:
		active = true

class FakeCutscene:
	extends "res://systems/hiding/timeout_cutscene.gd"
	func _choose_camera_position(_toward_player: Vector3) -> Vector3:
		return ronald.global_position + Vector3(1, 1.4, 2.7)

var scene: FakeCutscene
var player: FakePlayer
var ronald: FakeRonald

func before_each() -> void:
	player = FakePlayer.new()
	add_child_autofree(player)
	player.position = Vector3(0, 0, 6)
	ronald = FakeRonald.new()
	add_child_autofree(ronald)
	scene = FakeCutscene.new()
	add_child_autofree(scene)
	scene.configure(player, ronald)

func test_timeout_turn_voice_sprint_then_restores_player() -> void:
	var saved: Transform3D = player.camera.transform
	scene.tick(true, 0.0)
	assert_true(scene.active)
	assert_false(player.control_enabled)
	assert_true(scene.camera.current)
	assert_true(ronald.cinematic_turning)
	assert_false(ronald.cinematic_sprinting)
	scene.tick(true, scene.TURN_SECONDS + 0.01)
	assert_eq(scene.voice_count, 1)
	assert_false(ronald.cinematic_sprinting, "Voice line precedes the sprint")
	scene.tick(true, scene.voice_seconds)
	assert_true(ronald.cinematic_sprinting)
	assert_false(player.control_enabled, "Briefly show the start of the run")
	assert_true(scene.camera.current)
	scene.tick(true, 0.5)
	assert_true(player.control_enabled, "Control returns after half a second of running")
	assert_true(player.camera.current, "Player watches the approach from their own view")
	assert_false(scene.camera_locked)
	scene.tick(true, 2.0)
	assert_true(scene.active, "Sprint continues until the spotted area is reached")
	player.position.x += 4.0
	assert_eq(ronald.cinematic_target, Vector3(0, 0, 6), "Destination is captured rather than following the player")
	ronald.global_position = ronald.cinematic_target
	scene.tick(true, 0.01)
	assert_false(scene.active)
	assert_false(ronald.cinematic_sprinting)
	assert_false(ronald.cinematic_turning)
	assert_true(player.control_enabled)
	assert_true(player.camera.current)
	assert_eq(player.camera.transform, saved)
	assert_eq(ronald.animation.speed_scale, 1.0)
	assert_gte(ronald.grace, 0.6, "Player gets a brief reaction window after the camera returns")
	scene.tick(true, 0.0)
	assert_false(scene.active, "One cutscene per timeout")

func test_cancel_restores_camera_controls_and_temporary_speed() -> void:
	scene.tick(true, 0.0)
	scene.tick(true, scene.TURN_SECONDS + scene.voice_seconds + 0.01)
	assert_true(ronald.cinematic_sprinting)
	scene.cancel()
	assert_true(player.camera.current)
	assert_true(player.control_enabled)
	assert_false(ronald.cinematic_sprinting)
	assert_false(scene.voice.playing)

func test_sprint_completion_preserves_player_look_and_old_voice() -> void:
	scene.tick(true, scene.TURN_SECONDS + scene.voice_seconds + 0.51)
	assert_true(player.control_enabled)
	player.camera.rotation.y = 0.7
	ronald.global_position = ronald.cinematic_target
	scene.tick(true, 0.01)
	assert_almost_eq(player.camera.rotation.y, 0.7, 0.0001)
	assert_eq(scene.voice.stream.resource_path, "res://systems/hiding/i_see_you.wav")
	assert_almost_eq(scene.voice.pitch_scale, 0.76, 0.0001)

func test_half_second_run_view_even_if_ronald_arrives_early() -> void:
	scene.tick(true, scene.TURN_SECONDS + scene.voice_seconds)
	assert_true(ronald.cinematic_sprinting)
	ronald.global_position = ronald.cinematic_target
	scene.tick(true, 0.499)
	assert_true(scene.camera_locked)
	assert_false(player.control_enabled)
	scene.tick(true, 0.002)
	assert_false(scene.camera_locked)
	assert_true(player.control_enabled)
	assert_false(scene.active)
