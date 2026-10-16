extends GutTest
const ActorScript: Script = preload("res://scripts/stalker.gd")
var scene: GrappleCutscene
var source: Camera3D
var actor: Node3D
var wins: int = 0
var losses: int = 0

func before_each() -> void:
	wins = 0
	losses = 0
	var body: CharacterBody3D = CharacterBody3D.new()
	add_child_autofree(body)
	source = Camera3D.new()
	body.add_child(source)
	source.position = Vector3(0, 0.98, 3)
	source.make_current()
	actor = Node3D.new()
	actor.set_script(ActorScript)
	add_child_autofree(actor)
	actor.set_physics_process(false)
	scene = GrappleCutscene.new()
	add_child_autofree(scene)
	scene.set_process(false)
	scene.start(source, actor, func() -> void: wins += 1, func() -> void: losses += 1)

func space(pressed: bool, echo: bool = false) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = pressed
	event.echo = echo
	scene.handle_input(event)

func test_distinct_space_mashes_win_and_restore_view() -> void:
	scene.advance(0.7)
	assert_eq(scene.stage, &"struggle")
	space(true)
	space(true, true)
	space(true)
	assert_eq(scene.presses, 1, "Holding/repeat does not count as mashing")
	space(false)
	for index: int in 11:
		space(true)
		space(false)
	assert_eq(scene.stage, &"push")
	scene.advance(0.8)
	assert_false(scene.active)
	assert_eq(wins, 1)
	assert_eq(losses, 0)
	assert_true(source.current)
	assert_false(scene.hud.visible)

func test_failure_bites_before_death_callback() -> void:
	scene.advance(0.7)
	scene.advance(4.01)
	assert_eq(scene.stage, &"bite")
	assert_true(scene.upper_jaw.visible)
	assert_eq(losses, 0, "Bite cutscene must finish before death")
	scene.advance(1.1)
	assert_false(scene.active)
	assert_eq(wins, 0)
	assert_eq(losses, 1)

func test_pause_hides_prompt_and_blocks_space() -> void:
	scene.advance(0.7)
	scene.set_paused(true)
	space(true)
	assert_eq(scene.presses, 0)
	assert_false(scene.hud.visible)
	scene.set_paused(false)
	assert_true(scene.hud.visible)
