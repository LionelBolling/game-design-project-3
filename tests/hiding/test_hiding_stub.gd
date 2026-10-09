extends GutTest
## The Hiding stub. Lionel: copy this pattern for the real system's tests.
## Arrange the board as ANY, switch the writer to your system, tick, assert.


var board: Blackboard
var hiding: HidingStub


func before_each() -> void:
	board = Blackboard.new()
	hiding = autofree(HidingStub.new())
	hiding.keyboard = false


func _tick(delta: float) -> void:
	board.writer = hiding.system_id
	hiding.tick(board, delta)


func test_setup_puts_the_player_at_the_start_position() -> void:
	board.writer = hiding.system_id
	hiding.setup(board)
	assert_eq(board.player_position, hiding.start_position)


func test_starts_exposed_with_no_hide_time() -> void:
	_tick(0.1)
	assert_eq(board.hide_state, BoardTypes.Hide.EXPOSED)
	assert_eq(board.hide_time, 0.0)


func test_hide_time_counts_while_hidden() -> void:
	hiding.hidden = true
	for i in 5:
		_tick(0.5)
	assert_eq(board.hide_state, BoardTypes.Hide.HIDDEN)
	assert_almost_eq(board.hide_time, 2.5, 0.001)
	assert_false(board.location_leaked)


func test_location_leaks_after_the_limit() -> void:
	hiding.hidden = true
	_tick(HidingStub.LEAK_AFTER)
	assert_true(board.location_leaked)


func test_moving_makes_noise_and_coming_out_resets_the_timer() -> void:
	hiding.hidden = true
	_tick(3.0)
	hiding.hidden = false
	hiding.move_input = Vector2(1, 0)
	_tick(0.5)
	assert_eq(board.hide_time, 0.0)
	assert_gt(board.player_noise, 0.0)
	assert_almost_eq(board.player_position.x, HidingStub.SPEED * 0.5, 0.001)
