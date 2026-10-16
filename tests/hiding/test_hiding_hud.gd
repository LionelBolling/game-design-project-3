extends GutTest

func test_bar_only_visible_hidden_and_shows_remaining_budget() -> void:
	var hud: HidingHud = autofree(HidingHud.new())
	var board: Blackboard = Blackboard.new()
	var timer: HideTimer = HideTimer.new()
	add_child(hud)
	hud.refresh(board, timer, false)
	assert_false(hud.bar.visible)
	board.writer = Blackboard.ANY
	board.hide_state = BoardTypes.Hide.HIDDEN
	timer.enter(&"table")
	timer.advance(3.0)
	hud.refresh(board, timer, false)
	assert_true(hud.bar.visible)
	assert_eq(hud.bar.value, 4.0)
	timer.advance(4.0)
	board.location_leaked = true
	hud.refresh(board, timer, false)
	assert_eq(hud.bar.value, 0.0)
	assert_string_contains(hud.message.text, "revealed")
