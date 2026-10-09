extends GutTest
## The blackboard's one rule: read anything, write only your own values.


var board: Blackboard


func before_each() -> void:
	board = Blackboard.new()


func test_owner_can_write_its_value() -> void:
	board.writer = &"hiding"
	board.hide_time = 3.0
	assert_eq(board.hide_time, 3.0)


func test_another_system_cannot_write_a_value_it_does_not_own() -> void:
	board.writer = &"senses"
	board.hide_time = 3.0
	assert_push_error("only 'hiding' may write")
	assert_eq(board.hide_time, 0.0, "the refused write leaves the old value")


func test_nobody_can_write_between_turns() -> void:
	board.writer = Blackboard.NOBODY
	board.detection = BoardTypes.Detect.SEEN
	assert_push_error("only 'senses' may write")
	assert_eq(board.detection, BoardTypes.Detect.NONE)


func test_any_can_write_every_value_for_test_setup() -> void:
	board.writer = Blackboard.ANY
	board.player_position = Vector3(1, 0, 2)
	board.ronald_mode = BoardTypes.Mode.CHASE
	board.enemy_position = Vector3(3, 0, 4)
	assert_eq(board.player_position, Vector3(1, 0, 2))
	assert_eq(board.ronald_mode, BoardTypes.Mode.CHASE)
	assert_eq(board.enemy_position, Vector3(3, 0, 4))


func test_every_value_in_owners_exists_on_the_board() -> void:
	for key: StringName in Blackboard.OWNERS:
		assert_true(key in board, "%s is in OWNERS but the board has no such value" % key)


func test_every_board_value_is_listed_in_owners() -> void:
	for property in board.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE or property.name == "writer":
			continue
		assert_true(Blackboard.OWNERS.has(StringName(property.name)),
			"%s is on the board but not in OWNERS, so nobody owns it" % property.name)


func test_every_owner_is_one_of_the_four_systems() -> void:
	for key: StringName in Blackboard.OWNERS:
		assert_has(Director.ORDER, Blackboard.OWNERS[key], "%s has an unknown owner" % key)


func test_snapshot_lists_every_value_in_contract_order() -> void:
	assert_eq(board.snapshot().keys(), Blackboard.OWNERS.keys())
