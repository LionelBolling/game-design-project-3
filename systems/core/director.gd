class_name Director
extends Node
## Runs the four systems in a fixed order every physics frame:
## Hiding -> Senses -> Ruleset -> Roaming.
##
## Its children are those four systems, real or stub, in that order. To swap a
## stub for the real system, replace that one child and keep its place.


const ORDER: Array[StringName] = [&"hiding", &"senses", &"ruleset", &"roaming"]
## Group the Director joins, so display code (sounds, UI, Ronald's mesh) can
## find the board: get_tree().get_first_node_in_group(Director.GROUP).
const GROUP := &"director"

## The shared blackboard. Anything outside the four systems only reads it.
var board := Blackboard.new()

var _systems: Array[SimSystem] = []


func _ready() -> void:
	add_to_group(GROUP)
	for child in get_children():
		if child is SimSystem:
			_systems.append(child)
	_check_order()
	for system in _systems:
		board.writer = system.system_id
		system.setup(board)
	board.writer = Blackboard.NOBODY


func _physics_process(delta: float) -> void:
	step(delta)


## One frame: each system gets one turn, in order. Tests call this directly.
func step(delta: float) -> void:
	for system in _systems:
		board.writer = system.system_id
		system.tick(board, delta)
	board.writer = Blackboard.NOBODY


func _check_order() -> void:
	var ids: Array[StringName] = []
	for system in _systems:
		ids.append(system.system_id)
	if ids != ORDER:
		push_error("Director: systems must be %s, in that order; found %s." % [ORDER, ids])
