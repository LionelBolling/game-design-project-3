class_name RulesetSystem
extends SimSystem
## Enemy Ruleset (Rickey): decides what Ronald does. See systems/ruleset/SYSTEM.md.

@export var tuning: RonaldTuning = preload("res://systems/ruleset/ronald_tuning.tres")

var rules: RonaldRules
## Plays the honk, whisper and scream. Created in _ready(), so it's null in
## tests that never add the system to the tree.
var cue_player: CuePlayer


func _init() -> void:
	system_id = &"ruleset"


func _ready() -> void:
	cue_player = CuePlayer.new()
	add_child(cue_player)


func setup(board: Blackboard) -> void:
	rules = RonaldRules.new(tuning)
	_write(board)


func tick(board: Blackboard, delta: float) -> void:
	rules.step(board, delta)
	_write(board)
	if cue_player != null:
		for cue in rules.cues:
			cue_player.play(cue)


func _write(board: Blackboard) -> void:
	board.ronald_mode = rules.mode
	board.target_position = rules.target
	board.move_speed = rules.speed
	board.game_state = rules.game_state
