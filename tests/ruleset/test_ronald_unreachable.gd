extends GutTest
## Final review: a target Ronald can't reach must never freeze him or the run.

var board: Blackboard
var rules: RonaldRules


func before_each() -> void:
	board = Blackboard.new()
	rules = RonaldRules.new(RonaldTuning.new())
	board.fuses_collected = 1
	rules.step(board, 0.0) # wakes from DORMANT (one mode change per frame)
	board.enemy_position = Vector3(8, 0, 0)


func test_investigating_a_noise_he_cant_reach_still_ends_in_patrol() -> void:
	board.detection = BoardTypes.Detect.HEARD # the player waded into the pit
	rules.step(board, 0.1)
	board.detection = BoardTypes.Detect.NONE
	board.target_unreachable = true # Roaming stopped him at the rim
	rules.step(board, rules.tuning.search_time)
	assert_eq(rules.mode, BoardTypes.Mode.PATROL)


func test_seeking_a_spot_he_cant_reach_counts_as_arriving() -> void:
	board.hide_state = BoardTypes.Hide.HIDDEN
	board.hide_spot = &"tube_3"
	board.location_leaked = true
	rules.step(board, 0.1)
	board.target_unreachable = true
	rules.step(board, rules.tuning.seek_min_warning) # once the warning has run
	assert_eq(rules.mode, BoardTypes.Mode.CATCH, "still there, as close as he can get")


func test_a_sprint_that_cant_reach_the_player_still_ends_the_run() -> void:
	board.detection = BoardTypes.Detect.SEEN
	board.enemy_position = Vector3(5, 0, 0)
	rules.step(board, 0.1)
	board.enemy_position = Vector3(2.9, 0, 0)
	rules.step(board, 0.1)
	rules.step(board, rules.tuning.stare_time) # sprinting
	board.target_unreachable = true # the player is somewhere he can't get to
	rules.step(board, 0.1)
	assert_eq(rules.game_state, BoardTypes.Game.CAUGHT, "never a softlock with the controls locked")
