extends GutTest
## The Director gives each system one turn per frame, in the fixed order.


class Recorder:
	extends SimSystem
	var calls: Array

	func _init(id: StringName, shared_calls: Array) -> void:
		system_id = id
		calls = shared_calls

	func setup(board: Blackboard) -> void:
		calls.append([&"setup", system_id, board.writer])

	func tick(board: Blackboard, _delta: float) -> void:
		calls.append([&"tick", system_id, board.writer])


class Trespasser:
	extends SimSystem
	func _init() -> void:
		system_id = &"hiding"

	func tick(board: Blackboard, _delta: float) -> void:
		board.detection = BoardTypes.Detect.SEEN # belongs to senses


func _director_with(ids: Array[StringName], calls: Array) -> Director:
	var director := Director.new()
	for id in ids:
		director.add_child(Recorder.new(id, calls))
	add_child_autofree(director)
	return director


func test_setup_runs_once_in_order_before_the_first_frame() -> void:
	var calls := []
	_director_with(Director.ORDER, calls)
	assert_eq(calls, [
		[&"setup", &"hiding", &"hiding"],
		[&"setup", &"senses", &"senses"],
		[&"setup", &"ruleset", &"ruleset"],
		[&"setup", &"roaming", &"roaming"],
	])


func test_each_system_gets_one_turn_in_order_as_the_writer() -> void:
	var calls := []
	var director := _director_with(Director.ORDER, calls)
	calls.clear()
	director.step(0.016)
	assert_eq(calls, [
		[&"tick", &"hiding", &"hiding"],
		[&"tick", &"senses", &"senses"],
		[&"tick", &"ruleset", &"ruleset"],
		[&"tick", &"roaming", &"roaming"],
	])


func test_nobody_may_write_between_frames() -> void:
	var director := _director_with(Director.ORDER, [])
	assert_eq(director.board.writer, Blackboard.NOBODY, "after setup")
	director.step(0.016)
	assert_eq(director.board.writer, Blackboard.NOBODY)


func test_wrong_order_is_reported() -> void:
	var calls := []
	_director_with([&"senses", &"hiding", &"ruleset", &"roaming"], calls)
	assert_push_error("must be")


func test_a_system_writing_someone_elses_value_is_refused() -> void:
	var director := Director.new()
	director.add_child(Trespasser.new())
	director.add_child(Recorder.new(&"senses", []))
	director.add_child(Recorder.new(&"ruleset", []))
	director.add_child(Recorder.new(&"roaming", []))
	add_child_autofree(director)
	director.step(0.016)
	assert_push_error("only 'senses' may write")
	assert_eq(director.board.detection, BoardTypes.Detect.NONE)


func test_display_code_can_find_the_director_by_group() -> void:
	var director := _director_with(Director.ORDER, [])
	assert_eq(get_tree().get_first_node_in_group(Director.GROUP), director)
