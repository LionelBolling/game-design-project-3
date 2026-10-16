extends GutTest
## Statue posing (Q9): a 25% roll every 45 s of patrol; seated, he ignores
## sight and sound, and only an exposed player within 1 m wakes him.

var board: Blackboard
var rules: RonaldRules


func before_each() -> void:
	board = Blackboard.new()
	rules = RonaldRules.new(RonaldTuning.new())
	board.fuses_collected = 1
	board.player_position = Vector3(10, 0, 10)
	board.enemy_position = Vector3(0, 0, 0)
	rules.step(board, 0.0) # wakes from DORMANT into PATROL


func _start_pose_seated() -> void:
	rules.roll = func() -> float: return 0.0
	rules.step(board, rules.tuning.pose_check_every)
	board.at_target = true # Roaming seated him on the bench


func test_a_lucky_roll_during_patrol_starts_a_pose() -> void:
	rules.roll = func() -> float: return 0.0
	rules.step(board, rules.tuning.pose_check_every)
	assert_eq(rules.mode, BoardTypes.Mode.POSE)


func test_an_unlucky_roll_keeps_him_patrolling() -> void:
	rules.roll = func() -> float: return 0.99
	rules.step(board, rules.tuning.pose_check_every)
	assert_eq(rules.mode, BoardTypes.Mode.PATROL)


func test_holds_the_pose_then_patrols_again() -> void:
	_start_pose_seated()
	rules.step(board, rules.tuning.pose_time_min)
	assert_eq(rules.mode, BoardTypes.Mode.PATROL)


func test_a_seated_statue_ignores_what_it_sees() -> void:
	_start_pose_seated()
	board.detection = BoardTypes.Detect.SEEN
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.POSE)


func test_an_exposed_player_within_a_meter_wakes_him_into_a_chase() -> void:
	_start_pose_seated()
	board.player_position = Vector3(0.8, 0, 0)
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.POSE, "takes a second to wake")
	rules.step(board, rules.tuning.pose_wake_time)
	assert_eq(rules.mode, BoardTypes.Mode.CHASE)
	assert_has(rules.cues, &"honk")


func test_a_hidden_player_next_to_the_bench_stays_safe() -> void:
	_start_pose_seated()
	board.player_position = Vector3(0.8, 0, 0)
	board.hide_state = BoardTypes.Hide.HIDDEN
	board.hide_spot = &"booth_1"
	rules.step(board, rules.tuning.pose_wake_time + 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.POSE)


func test_seen_on_the_way_to_the_bench_means_a_normal_chase() -> void:
	rules.roll = func() -> float: return 0.0
	rules.step(board, rules.tuning.pose_check_every)
	board.detection = BoardTypes.Detect.SEEN
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.CHASE)


func test_a_very_long_patrol_frame_changes_mode_only_once() -> void:
	board.detection = BoardTypes.Detect.HEARD
	rules.step(board, 0.1) # investigating
	board.detection = BoardTypes.Detect.NONE
	board.at_target = true
	rules.roll = func() -> float: return 0.0
	rules.step(board, 100.0) # search ends: back to patrol, but no pose in the same frame
	assert_eq(rules.mode, BoardTypes.Mode.PATROL)
