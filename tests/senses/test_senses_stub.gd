extends GutTest
## The Senses stub. Aiden: copy this pattern for the real system's tests.
## Arrange the board as ANY, switch the writer to your system, tick, assert.


var board: Blackboard
var senses: SensesStub


func before_each() -> void:
	board = Blackboard.new()
	senses = autofree(SensesStub.new())


func _arrange(player: Vector3, enemy: Vector3, hide: BoardTypes.Hide, noise: float) -> void:
	board.writer = Blackboard.ANY
	board.player_position = player
	board.enemy_position = enemy
	board.hide_state = hide
	board.player_noise = noise


func _tick() -> void:
	board.writer = senses.system_id
	senses.tick(board, 0.016)


func test_sees_an_exposed_player_in_range() -> void:
	_arrange(Vector3(0, 0, 0), Vector3(3, 0, 0), BoardTypes.Hide.EXPOSED, 0.0)
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.SEEN)
	assert_eq(board.last_known_position, Vector3(0, 0, 0))


func test_does_not_see_a_hidden_player() -> void:
	_arrange(Vector3(0, 0, 0), Vector3(3, 0, 0), BoardTypes.Hide.HIDDEN, 0.0)
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.NONE)


func test_hears_a_noisy_player_out_of_sight_range() -> void:
	_arrange(Vector3(0, 0, 0), Vector3(8, 0, 0), BoardTypes.Hide.EXPOSED, 1.0)
	_tick()
	assert_eq(board.detection, BoardTypes.Detect.HEARD)
