extends GutTest
## The Ruleset stub. Rickey: copy this pattern for the real system's tests.
## Arrange the board as ANY, switch the writer to your system, tick, assert.


var board: Blackboard
var ruleset: RulesetStub


func before_each() -> void:
	board = Blackboard.new()
	ruleset = autofree(RulesetStub.new())
	board.writer = Blackboard.ANY
	board.player_position = Vector3(0, 0, 0)
	board.enemy_position = Vector3(5, 0, 0)


func _tick() -> void:
	board.writer = ruleset.system_id
	ruleset.tick(board, 0.016)


func test_seen_means_chase_the_player() -> void:
	board.detection = BoardTypes.Detect.SEEN
	_tick()
	assert_eq(board.ronald_mode, BoardTypes.Mode.CHASE)
	assert_eq(board.target_position, board.player_position)
	assert_eq(board.move_speed, RulesetStub.SPEEDS[BoardTypes.Mode.CHASE])


func test_leaked_spot_means_investigate_it() -> void:
	board.location_leaked = true
	_tick()
	assert_eq(board.ronald_mode, BoardTypes.Mode.INVESTIGATE)
	assert_eq(board.target_position, board.player_position)


func test_chasing_within_catch_range_ends_the_run_caught() -> void:
	board.detection = BoardTypes.Detect.SEEN
	board.enemy_position = Vector3(0.5, 0, 0)
	_tick()
	assert_eq(board.game_state, BoardTypes.Game.CAUGHT)


func test_reaching_the_exit_ends_the_run_escaped() -> void:
	board.player_at_exit = true
	_tick()
	assert_eq(board.game_state, BoardTypes.Game.ESCAPED)
