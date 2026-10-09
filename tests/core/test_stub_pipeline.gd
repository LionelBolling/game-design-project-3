extends GutTest
## All four stubs together under a Director, the way the sandbox runs them.


func _stub_director() -> Director:
	var director := Director.new()
	var hiding := HidingStub.new()
	hiding.keyboard = false
	director.add_child(hiding)
	director.add_child(SensesStub.new())
	director.add_child(RulesetStub.new())
	director.add_child(RoamingStub.new())
	add_child_autofree(director)
	return director


func test_player_and_ronald_start_at_their_start_positions() -> void:
	var director := _stub_director()
	assert_eq(director.board.player_position, Vector3(0, 0, 4))
	assert_eq(director.board.enemy_position, Vector3(-6, 0, -4))


func test_ronald_does_not_see_the_player_on_frame_one() -> void:
	# Regression: Senses runs before Roaming, so without setup() Ronald was
	# still at the origin on frame one, 4 m from the player, and saw them.
	var director := _stub_director()
	director.step(1.0 / 60.0)
	assert_eq(director.board.detection, BoardTypes.Detect.NONE)
	assert_eq(director.board.ronald_mode, BoardTypes.Mode.PATROL)


func test_a_quiet_player_who_stays_put_is_never_caught() -> void:
	var director := _stub_director()
	for i in 600: # 10 seconds at 60 fps
		director.step(1.0 / 60.0)
	assert_eq(director.board.game_state, BoardTypes.Game.PLAYING)
