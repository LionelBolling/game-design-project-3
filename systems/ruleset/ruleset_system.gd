class_name RulesetSystem
extends SimSystem
## Enemy Ruleset (Rickey): decides what Ronald does. See systems/ruleset/SYSTEM.md.

@export var tuning: RonaldTuning = preload("res://systems/ruleset/ronald_tuning.tres")

var rules: RonaldRules


func _init() -> void:
	system_id = &"ruleset"


func setup(board: Blackboard) -> void:
	rules = RonaldRules.new(tuning)
	_write(board)


func tick(board: Blackboard, delta: float) -> void:
	rules.step(board, delta)
	_write(board)


func _write(board: Blackboard) -> void:
	board.ronald_mode = rules.mode
	board.target_position = rules.target
	board.move_speed = rules.speed
	board.game_state = rules.game_state
