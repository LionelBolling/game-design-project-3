extends GutTest
const ActorScript: Script = preload("res://scripts/stalker.gd")
var completions: int = 0

func test_spawned_actor_leaps_into_lens_without_warning_overlay() -> void:
	var body: CharacterBody3D = CharacterBody3D.new()
	add_child_autofree(body)
	var original_camera: Camera3D = Camera3D.new()
	body.add_child(original_camera)
	original_camera.position = Vector3(0, 1.0, 3)
	original_camera.make_current()
	var actor: Node3D = Node3D.new()
	actor.set_script(ActorScript)
	add_child_autofree(actor)
	actor.set_physics_process(false)
	var original_model: Node3D = actor.get("clown") as Node3D
	var scene: CatchCutscene = CatchCutscene.new()
	add_child_autofree(scene)
	scene.start(original_camera, actor, func() -> void: completions += 1)
	assert_true(scene.active)
	assert_true(scene.camera.current)
	var start: Vector3 = actor.global_position
	scene.advance(0.25)
	assert_gt(actor.global_position.distance_to(start), 0.1, "Actual actor moves during the leap")
	assert_gt(actor.global_position.y, start.y, "Leap has an upward arc")
	scene.advance(0.35)
	assert_lt(scene.head_position().distance_to(scene.camera.global_position), 0.5, "Ronald's actual head fills the lens")
	assert_eq(actor.get("clown"), original_model, "Use the spawned Ronald, not a face GUI")
	scene.advance(1.0)
	assert_false(scene.active)
	assert_eq(completions, 1)
	assert_true(original_camera.current)
	scene.advance(1.0)
	assert_eq(completions, 1)
