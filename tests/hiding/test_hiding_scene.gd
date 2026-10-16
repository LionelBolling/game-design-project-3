extends GutTest
## Exercise real physics overlap instead of replacing the interaction query.

func test_table_interaction_in_the_actual_test_scene() -> void:
	var packed: PackedScene = load("res://systems/hiding/test/hiding_test.tscn") as PackedScene
	var scene: Node3D = packed.instantiate() as Node3D
	add_child_autofree(scene)
	var director: Director = scene.get("director") as Director
	var hiding: HidingSystem = scene.get("hiding") as HidingSystem
	director.set_physics_process(false)
	hiding.keyboard = false
	hiding.body.global_position = Vector3(-3, 0, 1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await wait_seconds(0.1)
	assert_not_null(hiding._nearby_spot(), "Actual Area3D must detect the player near the table")
	hiding.interact_requested = true
	director.step(0.5)
	assert_eq(director.board.hide_spot, &"table")
	assert_eq(director.board.hide_state, BoardTypes.Hide.HIDDEN)
	assert_true(hiding.hud.bar.visible)
	director.step(7.0)
	assert_true(director.board.location_leaked)
	assert_eq(director.board.ronald_mode, BoardTypes.Mode.INVESTIGATE)
	assert_eq(director.board.target_position, director.board.player_position)
	hiding.interact_requested = true
	director.step(0.0)
	assert_eq(director.board.hide_state, BoardTypes.Hide.EXPOSED)
	assert_false(hiding.hud.bar.visible)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
