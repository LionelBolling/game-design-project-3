class_name RonaldRules
extends RefCounted
## Ronald's brain as plain logic: reads the board, decides his mode, target,
## speed and the run's state. No nodes, so tests need no scene.
## RulesetSystem copies the results onto the board each frame.

var tuning: RonaldTuning
var mode: BoardTypes.Mode = BoardTypes.Mode.PATROL
var target := Vector3.ZERO
var speed := 0.0
var game_state: BoardTypes.Game = BoardTypes.Game.PLAYING
## One-off cues raised this frame: &"honk", &"whisper", &"scream".
var cues: Array[StringName] = []

var _unseen_time := 0.0
var _search_time := 0.0


func _init(rules_tuning: RonaldTuning) -> void:
	tuning = rules_tuning
	speed = tuning.patrol_speed


func step(board: Blackboard, delta: float) -> void:
	cues.clear()
	if game_state != BoardTypes.Game.PLAYING:
		return
	_hunt(board, delta)


func _hunt(board: Blackboard, delta: float) -> void:
	if board.detection == BoardTypes.Detect.SEEN:
		_chase(board)
	elif mode == BoardTypes.Mode.CHASE:
		target = board.last_known_position
		_unseen_time += delta
		if _unseen_time >= tuning.lose_track_after:
			_investigate(board.last_known_position)
	elif board.detection == BoardTypes.Detect.HEARD:
		_investigate(board.last_known_position)
	elif mode == BoardTypes.Mode.INVESTIGATE:
		if board.at_target:
			_search_time += delta
			if _search_time >= tuning.search_time:
				_patrol(board)
	else:
		_patrol(board)


func _chase(board: Blackboard) -> void:
	if mode != BoardTypes.Mode.CHASE:
		cues.append(&"honk")
	mode = BoardTypes.Mode.CHASE
	target = board.player_position
	speed = tuning.chase_speed
	_unseen_time = 0.0


func _investigate(at: Vector3) -> void:
	mode = BoardTypes.Mode.INVESTIGATE
	target = at
	speed = tuning.search_speed
	_search_time = 0.0


func _patrol(board: Blackboard) -> void:
	mode = BoardTypes.Mode.PATROL
	target = board.enemy_position # ignored by Roaming in PATROL
	speed = tuning.patrol_speed
