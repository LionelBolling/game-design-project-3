extends GutTest
## GameFlow: which screen, the reveal, and reading the board (D-022).


func test_picks_the_screen_from_the_game_state() -> void:
	assert_eq(GameFlow.screen_for(BoardTypes.Game.PLAYING), &"")
	assert_eq(GameFlow.screen_for(BoardTypes.Game.CAUGHT), &"caught")
	assert_eq(GameFlow.screen_for(BoardTypes.Game.ESCAPED), &"escaped")


func test_the_reveal_stands_where_ronald_was() -> void:
	var flow: GameFlow = add_child_autofree(GameFlow.new())
	var reveal := flow.place_reveal(Vector3(3, 0, -2))
	assert_eq(reveal.global_position, Vector3(3, 0, -2))


func test_caught_shows_the_caught_screen() -> void:
	var flow: GameFlow = add_child_autofree(GameFlow.new())
	assert_false(flow.is_screen_visible(), "nothing shows while playing")
	flow.show_for(BoardTypes.Game.CAUGHT, Vector3.ZERO)
	assert_eq(flow.screen, &"caught")
	assert_true(flow.is_screen_visible())


func test_escaping_plays_the_reveal_before_the_escaped_screen() -> void:
	var flow: GameFlow = add_child_autofree(GameFlow.new())
	flow.show_for(BoardTypes.Game.ESCAPED, Vector3(1, 0, 1))
	assert_eq(flow.screen, &"reveal")
	assert_false(flow.is_screen_visible(), "the reveal plays in the world first")
	flow.advance(GameFlow.REVEAL_TIME - 0.1)
	assert_eq(flow.screen, &"reveal")
	flow.advance(0.2)
	assert_eq(flow.screen, &"escaped")
	assert_true(flow.is_screen_visible())


func test_reads_the_end_of_the_run_from_the_board() -> void:
	var director := Director.new()
	var hiding := HidingStub.new()
	hiding.keyboard = false
	hiding.fuses = 3
	hiding.breaker = true
	hiding.at_exit = true
	director.add_child(hiding)
	director.add_child(SensesStub.new())
	var ruleset := RulesetSystem.new()
	director.add_child(ruleset)
	director.add_child(RoamingStub.new())
	add_child_autofree(director)
	director.step(1.0 / 60.0)
	ruleset.game_flow._process(1.0 / 60.0)
	assert_eq(director.board.game_state, BoardTypes.Game.ESCAPED)
	assert_eq(ruleset.game_flow.screen, &"reveal")


func test_the_end_screen_covers_the_whole_view() -> void:
	var flow: GameFlow = add_child_autofree(GameFlow.new())
	flow.show_for(BoardTypes.Game.CAUGHT, Vector3.ZERO)
	await wait_process_frames(1)
	assert_eq(flow.screen_rect().size, get_viewport().get_visible_rect().size)
