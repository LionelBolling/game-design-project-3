extends GutTest

class FakeHiding:
	extends HidingSystem
	var candidate: HideSpot
	func _nearby_spot() -> HideSpot:
		return candidate

var board: Blackboard
var hiding: FakeHiding
var spot: HideSpot

func before_each() -> void:
	board = Blackboard.new()
	hiding = autofree(FakeHiding.new())
	hiding.keyboard = false
	spot = autofree(HideSpot.new())
	spot.spot_id = &"table_a"
	hiding.candidate = spot
	board.writer = &"hiding"
	hiding.setup(board)

func test_entry_requires_half_second_and_publishes_spot() -> void:
	hiding.interact_requested = true
	hiding.tick(board, 0.25)
	assert_eq(board.hide_state, BoardTypes.Hide.EXPOSED)
	assert_gt(board.player_noise, 0.0)
	hiding.tick(board, 0.25)
	assert_eq(board.hide_state, BoardTypes.Hide.HIDDEN)
	assert_eq(board.hide_spot, &"table_a")
	assert_eq(board.hide_time, 0.0)

func test_leak_leave_and_refill() -> void:
	hiding.interact_requested = true
	hiding.tick(board, 0.5)
	hiding.tick(board, 7.0)
	assert_true(board.location_leaked)
	assert_eq(board.hide_state, BoardTypes.Hide.HIDDEN)
	hiding.interact_requested = true
	hiding.tick(board, 0.0)
	assert_eq(board.hide_state, BoardTypes.Hide.EXPOSED)
	assert_eq(board.hide_spot, &"")
	assert_eq(board.hide_time, 0.0)
	assert_false(board.location_leaked)
	hiding.tick(board, 14.0)
	assert_eq(hiding.timer.remaining, 7.0)

func test_no_spot_means_no_entry() -> void:
	hiding.candidate = null
	hiding.interact_requested = true
	hiding.tick(board, 1.0)
	assert_eq(board.hide_state, BoardTypes.Hide.EXPOSED)

func test_controls_and_timer_freeze_when_game_ends() -> void:
	board.writer = Blackboard.ANY
	board.game_state = BoardTypes.Game.CAUGHT
	board.writer = &"hiding"
	hiding.interact_requested = true
	hiding.tick(board, 9.0)
	assert_eq(board.hide_state, BoardTypes.Hide.EXPOSED)
	assert_eq(hiding.timer.remaining, 7.0)

func test_ball_pit_entry_noise() -> void:
	spot.spot_type = HideSpot.Kind.BALL_PIT
	hiding.interact_requested = true
	hiding.tick(board, 0.1)
	assert_eq(board.player_noise, 0.6)

func test_reentry_preserves_budget_and_separates_visit_time() -> void:
	hiding.interact_requested = true
	hiding.tick(board, 0.5)
	hiding.tick(board, 4.0)
	hiding.interact_requested = true
	hiding.tick(board, 0.0)
	hiding.tick(board, 2.0)
	spot.spot_id = &"booth_b"
	hiding.interact_requested = true
	hiding.tick(board, 0.5)
	assert_eq(hiding.timer.remaining, 4.0)
	assert_eq(board.hide_time, 0.0)
	assert_eq(board.hide_spot, &"booth_b")

func test_hidden_time_and_noise_freeze_after_game_ends() -> void:
	hiding.interact_requested = true
	hiding.tick(board, 0.5)
	hiding.tick(board, 1.0)
	board.writer = Blackboard.ANY
	board.game_state = BoardTypes.Game.CAUGHT
	board.writer = &"hiding"
	hiding.interact_requested = true
	hiding.tick(board, 10.0)
	assert_eq(board.hide_state, BoardTypes.Hide.HIDDEN)
	assert_eq(board.hide_time, 1.0)
	assert_eq(hiding.timer.remaining, 6.0)
	assert_eq(board.player_noise, 0.0)

func test_hiding_stops_body_movement() -> void:
	add_child(spot)
	var body: CharacterBody3D = CharacterBody3D.new()
	hiding.add_child(body)
	add_child(hiding)
	hiding.body = body
	hiding.camera = Camera3D.new()
	body.add_child(hiding.camera)
	body.velocity = Vector3(2, 0, 0)
	hiding.interact_requested = true
	hiding.tick(board, 0.5)
	var position: Vector3 = body.global_position
	hiding.tick(board, 1.0)
	assert_eq(body.global_position, position)
	assert_eq(body.velocity, Vector3.ZERO)

func test_table_view_level_and_ball_pit_pitch_preserved() -> void:
	add_child(spot)
	var body: CharacterBody3D = CharacterBody3D.new()
	hiding.add_child(body)
	add_child(hiding)
	hiding.body = body
	hiding.camera = Camera3D.new()
	body.add_child(hiding.camera)
	body.rotation.y = 0.7
	hiding.camera.rotation.x = 0.8
	hiding.interact_requested = true
	hiding.tick(board, 0.5)
	assert_eq(hiding.camera.rotation.x, 0.0)
	assert_almost_eq(body.rotation.y, 0.7, 0.001)
	body.rotation.y = -0.4
	hiding.camera.rotation.x = -0.6
	hiding.tick(board, 0.1)
	assert_eq(hiding.camera.rotation.x, 0.0)
	assert_almost_eq(body.rotation.y, -0.4, 0.001)
	hiding.interact_requested = true
	hiding.tick(board, 0.0)
	hiding.camera.rotation.x = 0.5
	spot.spot_type = HideSpot.Kind.BALL_PIT
	hiding.interact_requested = true
	hiding.tick(board, 0.5)
	assert_almost_eq(hiding.camera.rotation.x, 0.5, 0.001)
