extends GutTest
## Dormant until the first fuse (D-019).

var board: Blackboard
var rules: RonaldRules


func before_each() -> void:
	board = Blackboard.new()
	rules = RonaldRules.new(RonaldTuning.new())


func test_starts_dormant() -> void:
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.DORMANT)


func test_stays_dormant_even_with_the_player_in_plain_sight() -> void:
	board.detection = BoardTypes.Detect.SEEN
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.DORMANT)


func test_the_first_fuse_wakes_him_into_patrol() -> void:
	board.fuses_collected = 1
	rules.step(board, 0.1)
	assert_eq(rules.mode, BoardTypes.Mode.PATROL)
