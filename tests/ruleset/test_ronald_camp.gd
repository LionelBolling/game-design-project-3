extends GutTest
## The ball pit: he never goes in; he camps at the rim for 10 s (Q3).

var board: Blackboard
var rules: RonaldRules


func before_each() -> void:
	board = Blackboard.new()
	rules = RonaldRules.new(RonaldTuning.new())
	board.fuses_collected = 1
	rules.step(board, 0.0) # wakes from DORMANT (one mode change per frame)
	board.enemy_position = Vector3(8, 0, 0)


func _hide_in(spot: StringName) -> void:
	board.hide_state = BoardTypes.Hide.HIDDEN
	board.hide_spot = spot


func test_a_leak_in_the_pit_whispers_then_camps_instead_of_seeking() -> void:
	_hide_in(&"ball_pit")
	board.location_leaked = true
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.CAMP)
	assert_has(rules.cues, &"whisper")


func test_diving_into_the_pit_mid_chase_turns_the_chase_into_camping() -> void:
	board.detection = BoardTypes.Detect.SEEN
	rules.step(board, 0.1)
	board.detection = BoardTypes.Detect.NONE
	_hide_in(&"ball_pit")
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.CAMP)


func test_camps_ten_seconds_at_the_rim_then_patrols() -> void:
	_hide_in(&"ball_pit")
	board.location_leaked = true
	rules.step(board, 0.1)
	board.target_unreachable = true # Roaming stopped him at the rim
	rules.step(board, rules.tuning.camp_time - 0.5)
	assert_eq(rules.mode, BoardTypes.Mode.CAMP)
	rules.step(board, 0.5)
	assert_eq(rules.mode, BoardTypes.Mode.PATROL)


func test_no_second_whisper_after_camping_while_still_in_the_pit() -> void:
	_hide_in(&"ball_pit")
	board.location_leaked = true
	rules.step(board, 0.1)
	board.target_unreachable = true
	rules.step(board, rules.tuning.camp_time)
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.PATROL)
	assert_does_not_have(rules.cues, &"whisper")


func test_climbing_out_in_his_sight_restarts_the_chase() -> void: # Review focus 2
	_hide_in(&"ball_pit")
	board.location_leaked = true
	rules.step(board, 0.1)
	board.hide_state = BoardTypes.Hide.EXPOSED
	board.hide_spot = &""
	board.detection = BoardTypes.Detect.SEEN
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.CHASE)


func test_moving_into_the_pit_during_a_seek_camps_instead_of_catching() -> void: # Review focus 3
	_hide_in(&"booth_2")
	board.location_leaked = true
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.SEEK)
	board.location_leaked = false
	_hide_in(&"ball_pit")
	board.at_target = true
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.CAMP)
