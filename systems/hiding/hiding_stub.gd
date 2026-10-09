class_name HidingStub
extends SimSystem
## Stand-in for Hiding From Enemies (Lionel) until the real system replaces it.
## Writes believable values for every Hiding value so the other systems can be
## built without it. No level and no body: the player is a point on the floor.
##
## Sandbox keys: WASD or arrows move, H hides or comes out, hold X to stand in
## the exit zone.


const SPEED := 3.0 # m/s
const LEAK_AFTER := 10.0 # seconds hidden before the spot leaks (placeholder)

## Where the player starts.
@export var start_position := Vector3(0, 0, 4)
## Read the keyboard each turn. Tests turn this off and set the inputs below.
@export var keyboard := true

var move_input := Vector2.ZERO
var hidden := false
var at_exit := false

var _h_was_down := false


func _init() -> void:
	system_id = &"hiding"


func setup(board: Blackboard) -> void:
	board.player_position = start_position


func tick(board: Blackboard, delta: float) -> void:
	if keyboard:
		_read_keys()
	var moving := not hidden and move_input != Vector2.ZERO
	if moving:
		var direction := Vector3(move_input.x, 0, move_input.y).normalized()
		board.player_position += direction * SPEED * delta
	board.player_noise = 0.5 if moving else 0.0
	board.hide_state = BoardTypes.Hide.HIDDEN if hidden else BoardTypes.Hide.EXPOSED
	board.hide_spot = &"stub_spot" if hidden else &""
	board.hide_time = board.hide_time + delta if hidden else 0.0
	board.location_leaked = hidden and board.hide_time >= LEAK_AFTER
	board.player_at_exit = at_exit


func _read_keys() -> void:
	move_input = Vector2(
		_axis(KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT),
		_axis(KEY_W, KEY_UP, KEY_S, KEY_DOWN))
	var h_down := Input.is_physical_key_pressed(KEY_H)
	if h_down and not _h_was_down:
		hidden = not hidden
	_h_was_down = h_down
	at_exit = Input.is_physical_key_pressed(KEY_X)


func _axis(neg_a: Key, neg_b: Key, pos_a: Key, pos_b: Key) -> float:
	var value := 0.0
	if Input.is_physical_key_pressed(neg_a) or Input.is_physical_key_pressed(neg_b):
		value -= 1.0
	if Input.is_physical_key_pressed(pos_a) or Input.is_physical_key_pressed(pos_b):
		value += 1.0
	return value
