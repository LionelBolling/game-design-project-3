class_name RonaldRules
extends RefCounted
## Ronald's brain as plain logic: reads the board, decides his mode, target,
## speed and the run's state. No nodes, so tests need no scene.
## RulesetSystem copies the results onto the board each frame.

var tuning: RonaldTuning
var mode: BoardTypes.Mode = BoardTypes.Mode.DORMANT
var target := Vector3.ZERO
var speed := 0.0
var game_state: BoardTypes.Game = BoardTypes.Game.PLAYING
## One-off cues raised this frame: &"honk", &"whisper", &"scream".
var cues: Array[StringName] = []

var _unseen_time := 0.0
var _search_time := 0.0
var _stare_time := 0.0
var _sprinting := false


func _init(rules_tuning: RonaldTuning) -> void:
	tuning = rules_tuning


func step(board: Blackboard, delta: float) -> void:
	cues.clear()
	if game_state != BoardTypes.Game.PLAYING:
		return
	if mode == BoardTypes.Mode.DORMANT:
		_dormant(board)
		return
	if mode == BoardTypes.Mode.CATCH:
		_catching(board, delta)
		return
	_hunt(board, delta)


## Asleep until the player picks up the first fuse (D-013).
func _dormant(board: Blackboard) -> void:
	if board.fuses_collected >= 1:
		_patrol(board)


## The stare, then the sprint (SYSTEM.md §6 Q6). Nothing interrupts it.
func _catching(board: Blackboard, delta: float) -> void:
	target = board.player_position
	if not _sprinting:
		_stare_time += delta
		if _stare_time >= tuning.stare_time:
			_sprinting = true
			speed = tuning.sprint_speed
			cues.append(&"scream")
	elif _distance_to_player(board) <= tuning.caught_range:
		game_state = BoardTypes.Game.CAUGHT


func _hunt(board: Blackboard, delta: float) -> void:
	var seen := board.detection == BoardTypes.Detect.SEEN
	if mode == BoardTypes.Mode.CHASE and seen and _distance_to_player(board) <= tuning.catch_range:
		_catch(board)
	elif seen:
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


func _catch(board: Blackboard) -> void:
	mode = BoardTypes.Mode.CATCH
	target = board.player_position
	speed = 0.0
	_stare_time = 0.0
	_sprinting = false


func _investigate(at: Vector3) -> void:
	mode = BoardTypes.Mode.INVESTIGATE
	target = at
	speed = tuning.search_speed
	_search_time = 0.0


func _patrol(board: Blackboard) -> void:
	mode = BoardTypes.Mode.PATROL
	target = board.enemy_position # ignored by Roaming in PATROL
	speed = tuning.patrol_speed


func _distance_to_player(board: Blackboard) -> float:
	return board.enemy_position.distance_to(board.player_position)
