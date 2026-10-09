class_name SimSystem
extends Node
## Base class for the four systems and their stubs.
##
## The Director calls tick() once per physics frame, in a fixed order, after
## setting board.writer to this system's id. Read anything on the board; write
## only your own values (docs/BLACKBOARD.md).


## Which system this is: &"hiding", &"senses", &"ruleset" or &"roaming".
## A stub uses the same id as the real system it stands in for.
var system_id: StringName = &""


## Called once before the first frame, in the same order and under the same
## write rule as tick(). Write your starting values here (where the player or
## Ronald starts), so no system sees a default value on frame one.
func setup(_board: Blackboard) -> void:
	pass


## One turn. Override this. Don't keep the board around between turns.
func tick(_board: Blackboard, _delta: float) -> void:
	pass
