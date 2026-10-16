extends GutTest
## Catching: a 2 s stare, an 8 m/s sprint, then CAUGHT (SYSTEM.md §6 Q6).

var board: Blackboard
var rules: RonaldRules


func before_each() -> void:
	board = Blackboard.new()
	rules = RonaldRules.new(RonaldTuning.new())
	board.fuses_collected = 1
	rules.step(board, 0.0) # wakes from DORMANT (one mode change per frame)
	board.detection = BoardTypes.Detect.SEEN
	board.enemy_position = Vector3(5, 0, 0)
	rules.step(board, 0.1) # now chasing


func _close_in() -> void:
	board.enemy_position = Vector3(2.9, 0, 0)
	rules.step(board, 0.1)


func test_chasing_within_three_meters_starts_the_stare() -> void:
	_close_in()
	assert_eq(rules.mode, BoardTypes.Mode.CATCH)
	assert_eq(rules.speed, 0.0, "stands still to stare")
	assert_eq(rules.target, board.player_position, "faces the player")


func test_stares_for_two_seconds_then_sprints_screaming() -> void:
	_close_in()
	rules.step(board, rules.tuning.stare_time)
	assert_eq(rules.speed, rules.tuning.sprint_speed)
	assert_has(rules.cues, &"scream")


func test_the_sprint_reaching_the_player_ends_the_run_caught() -> void:
	_close_in()
	rules.step(board, rules.tuning.stare_time)
	board.enemy_position = Vector3(0.5, 0, 0)
	rules.step(board, 0.1)
	assert_eq(rules.game_state, BoardTypes.Game.CAUGHT)


func test_nothing_changes_after_the_run_ends() -> void: # Review focus 5
	_close_in()
	rules.step(board, rules.tuning.stare_time)
	board.enemy_position = Vector3(0.5, 0, 0)
	rules.step(board, 0.1)
	board.detection = BoardTypes.Detect.HEARD
	rules.step(board, 5.0)
	assert_eq(rules.game_state, BoardTypes.Game.CAUGHT)
	assert_eq(rules.mode, BoardTypes.Mode.CATCH)
	assert_true(rules.cues.is_empty())
