extends GutTest
## The Roaming stub. Naomi: copy this pattern for the real system's tests.
## Arrange the board as ANY, switch the writer to your system, tick, assert.


var board: Blackboard
var roaming: RoamingStub


func before_each() -> void:
	board = Blackboard.new()
	roaming = autofree(RoamingStub.new())
	roaming.start_position = Vector3.ZERO


func _tick(delta: float) -> void:
	board.writer = roaming.system_id
	roaming.tick(board, delta)


func test_walks_toward_the_target_at_move_speed() -> void:
	board.writer = Blackboard.ANY
	board.ronald_mode = BoardTypes.Mode.CHASE
	board.target_position = Vector3(10, 0, 0)
	board.move_speed = 2.0
	_tick(1.0)
	assert_almost_eq(board.enemy_position.x, 2.0, 0.001)
	assert_eq(board.enemy_velocity, Vector3(2, 0, 0))
	assert_false(board.at_target)


func test_reports_arrival_at_the_target() -> void:
	board.writer = Blackboard.ANY
	board.ronald_mode = BoardTypes.Mode.INVESTIGATE
	board.target_position = Vector3(1, 0, 0)
	board.move_speed = 2.0
	_tick(1.0)
	assert_true(board.at_target)


func test_patrol_ignores_the_target_and_walks_its_own_route() -> void:
	board.writer = Blackboard.ANY
	board.ronald_mode = BoardTypes.Mode.PATROL
	board.target_position = Vector3(-50, 0, 0)
	board.move_speed = 1.0
	_tick(1.0)
	var first_point := roaming.patrol_points[0]
	assert_lt(board.enemy_position.distance_to(first_point), first_point.length())
