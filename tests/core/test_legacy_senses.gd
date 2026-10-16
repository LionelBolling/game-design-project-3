extends GutTest
## LegacySenses: Enemy Senses' stand-in for the F5 game. The mock's sight
## (12 m, walls block) and the stub's hearing, written to the board.


class FakeSight:
	extends LegacySenses
	var sight := true
	func can_see_player() -> bool:
		return sight


var board: Blackboard
var senses: FakeSight


func before_each() -> void:
	board = Blackboard.new()
	senses = autofree(FakeSight.new())
	board.writer = Blackboard.ANY
	board.ronald_mode = BoardTypes.Mode.PATROL
	board.enemy_position = Vector3.ZERO
	board.player_position = Vector3(5, 0, 0)


func _tick() -> void:
	board.writer = senses.system_id
	senses.tick(board, 0.1)
	board.writer = Blackboard.ANY


func test_sees_an_exposed_player_in_line_of_sight() -> void:
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.SEEN)
	assert_eq(board.last_known_position, Vector3(5, 0, 0))


func test_a_wall_blocks_sight() -> void:
	senses.sight = false
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.NONE)


func test_too_far_to_see() -> void:
	board.player_position = Vector3(LegacySenses.SIGHT + 1.0, 0, 0)
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.NONE)


func test_never_sees_a_hidden_player() -> void:
	board.hide_state = BoardTypes.Hide.HIDDEN
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.NONE)


func test_hears_a_noisy_player_through_a_wall() -> void:
	senses.sight = false
	board.player_noise = 0.6 # hears up to 6 m
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.HEARD)
	assert_eq(board.last_known_position, Vector3(5, 0, 0))


func test_a_quiet_player_out_of_sight_is_not_heard() -> void:
	senses.sight = false
	board.player_noise = 0.3 # hears up to 3 m, the player is 5 m away
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.NONE)


func test_senses_nothing_while_ronald_is_dormant() -> void:
	board.ronald_mode = BoardTypes.Mode.DORMANT
	board.player_noise = 1.0
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.NONE)
