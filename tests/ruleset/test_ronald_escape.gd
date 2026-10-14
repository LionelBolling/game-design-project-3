extends GutTest
## Escaping: 3 fuses, the breaker, then the exit (D-013).

var board: Blackboard
var rules: RonaldRules


func before_each() -> void:
	board = Blackboard.new()
	rules = RonaldRules.new(RonaldTuning.new())
	board.fuses_collected = 3
	rules.step(board, 0.0) # wakes from DORMANT (one mode change per frame)


func test_the_exit_without_power_does_nothing() -> void:
	board.player_at_exit = true
	rules.step(board, 0.1)
	assert_eq(rules.game_state, BoardTypes.Game.PLAYING)


func test_the_exit_with_the_breaker_on_ends_the_run_escaped() -> void:
	board.breaker_on = true
	board.player_at_exit = true
	rules.step(board, 0.1)
	assert_eq(rules.game_state, BoardTypes.Game.ESCAPED)


func test_escaping_beats_a_catch_in_the_same_frame() -> void: # Review focus 4
	board.detection = BoardTypes.Detect.SEEN
	board.enemy_position = Vector3(5, 0, 0)
	rules.step(board, 0.1)
	board.enemy_position = Vector3(2.9, 0, 0)
	rules.step(board, 0.1)
	rules.step(board, rules.tuning.stare_time)
	board.enemy_position = Vector3(0.5, 0, 0)
	board.breaker_on = true
	board.player_at_exit = true
	rules.step(board, 0.1)
	assert_eq(rules.game_state, BoardTypes.Game.ESCAPED)


func test_escaping_while_he_is_still_dormant_works_too() -> void:
	var fresh := RonaldRules.new(RonaldTuning.new())
	board.breaker_on = true
	board.player_at_exit = true
	fresh.step(board, 0.1)
	assert_eq(fresh.game_state, BoardTypes.Game.ESCAPED)
