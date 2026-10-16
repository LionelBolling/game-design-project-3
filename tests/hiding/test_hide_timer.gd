extends GutTest

const TimerScript: GDScript = preload("res://systems/hiding/hide_timer.gd")


func test_starts_full_and_exposed() -> void:
	var timer: RefCounted = TimerScript.new()
	assert_eq(timer.remaining, 7.0)
	assert_eq(timer.hide_time, 0.0)
	assert_false(timer.leaked())


func test_leaks_exactly_at_seven_seconds_and_stays_hidden() -> void:
	var timer: RefCounted = TimerScript.new()
	timer.enter(&"table_a")
	timer.advance(6.99)
	assert_false(timer.leaked())
	timer.advance(0.01)
	assert_true(timer.leaked())
	assert_eq(timer.spot_id, &"table_a")
	assert_almost_eq(timer.hide_time, 7.0, 0.00001)
	timer.advance(2.0)
	assert_eq(timer.remaining, 0.0)
	assert_almost_eq(timer.hide_time, 9.0, 0.00001)


func test_leaving_clears_visit_time_and_leak_without_resetting_budget() -> void:
	var timer: RefCounted = TimerScript.new()
	timer.enter(&"table_a")
	timer.advance(7.0)
	timer.leave()
	assert_eq(timer.hide_time, 0.0)
	assert_eq(timer.spot_id, &"")
	assert_false(timer.leaked())
	assert_eq(timer.remaining, 0.0)
	timer.enter(&"table_a")
	assert_true(timer.leaked())


func test_empty_budget_refills_over_fourteen_seconds_outside() -> void:
	var timer: RefCounted = TimerScript.new()
	timer.enter(&"table_a")
	timer.advance(7.0)
	timer.leave()
	timer.advance(7.0)
	assert_eq(timer.remaining, 3.5)
	assert_eq(timer.hide_time, 0.0)
	timer.advance(7.0)
	assert_eq(timer.remaining, 7.0)
	timer.advance(100.0)
	assert_eq(timer.remaining, 7.0)


func test_switching_spots_retains_budget_and_restarts_visit_time() -> void:
	var timer: RefCounted = TimerScript.new()
	timer.enter(&"table_a")
	timer.advance(4.0)
	timer.leave()
	timer.enter(&"booth_b")
	assert_eq(timer.remaining, 3.0)
	assert_eq(timer.hide_time, 0.0)
	timer.advance(3.0)
	assert_true(timer.leaked())


func test_repeated_entry_does_not_reset_current_visit() -> void:
	var timer: RefCounted = TimerScript.new()
	timer.enter(&"table_a")
	timer.advance(2.0)
	timer.enter(&"table_a")
	assert_eq(timer.hide_time, 2.0)
	assert_eq(timer.remaining, 5.0)


func test_negative_delta_cannot_refill_while_hidden_or_drain_outside() -> void:
	var timer: RefCounted = TimerScript.new()
	timer.enter(&"table_a")
	timer.advance(2.0)
	timer.advance(-1.0)
	assert_eq(timer.remaining, 5.0)
	assert_eq(timer.hide_time, 2.0)
	timer.leave()
	timer.advance(-1.0)
	assert_eq(timer.remaining, 5.0)
