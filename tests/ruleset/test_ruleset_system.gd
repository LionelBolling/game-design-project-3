extends GutTest
## RulesetSystem: rules in, board out.


func test_writes_its_decisions_to_the_board_each_turn() -> void:
	var board := Blackboard.new()
	var system: RulesetSystem = autofree(RulesetSystem.new())
	board.writer = system.system_id
	system.setup(board)
	board.writer = Blackboard.ANY
	board.fuses_collected = 1
	board.writer = system.system_id
	system.tick(board, 0.0) # wakes from DORMANT
	board.writer = Blackboard.ANY
	board.detection = BoardTypes.Detect.SEEN
	board.player_position = Vector3(2, 0, 3)
	board.writer = system.system_id
	system.tick(board, 0.1)
	assert_eq(board.ronald_mode, BoardTypes.Mode.CHASE)
	assert_eq(board.target_position, Vector3(2, 0, 3))
	assert_eq(board.move_speed, system.tuning.chase_speed)


func test_runs_under_the_director_with_the_other_three_stubs() -> void:
	var director := Director.new()
	var hiding := HidingStub.new()
	hiding.keyboard = false
	director.add_child(hiding)
	director.add_child(SensesStub.new())
	director.add_child(RulesetSystem.new())
	director.add_child(RoamingStub.new())
	add_child_autofree(director)
	for i in 120:
		director.step(1.0 / 60.0)
	assert_eq(director.board.game_state, BoardTypes.Game.PLAYING)
	assert_eq(director.board.ronald_mode, BoardTypes.Mode.DORMANT, "no fuses picked up yet")


func test_end_screens_can_be_left_to_the_game() -> void:
	var system := RulesetSystem.new()
	system.end_screens = false
	add_child_autofree(system)
	assert_null(system.game_flow, "a game with its own end screens gets no GameFlow")
	assert_not_null(system.cue_player)


func test_end_screens_are_on_by_default() -> void:
	var system: RulesetSystem = add_child_autofree(RulesetSystem.new())
	assert_not_null(system.game_flow)
