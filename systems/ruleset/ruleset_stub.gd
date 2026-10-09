class_name RulesetStub
extends SimSystem
## Stand-in for the Enemy Ruleset (Rickey) until the real system replaces it.
## The simplest Ronald that still exercises every value:
##   SEEN -> CHASE the player. HEARD or spot leaked -> INVESTIGATE there.
##   Lost sight while chasing -> INVESTIGATE the last known position.
##   Otherwise PATROL (Roaming picks the route).
## Catches the player within CATCH_RANGE while chasing. The run ends ESCAPED
## when the player stands in the exit zone.


const CATCH_RANGE := 1.0 # m
const SPEEDS: Dictionary[BoardTypes.Mode, float] = {
	BoardTypes.Mode.PATROL: 1.5,
	BoardTypes.Mode.INVESTIGATE: 2.0,
	BoardTypes.Mode.CHASE: 3.5,
}


func _init() -> void:
	system_id = &"ruleset"


func tick(board: Blackboard, _delta: float) -> void:
	if board.game_state != BoardTypes.Game.PLAYING:
		return
	if board.player_at_exit:
		board.game_state = BoardTypes.Game.ESCAPED
		return

	if board.detection == BoardTypes.Detect.SEEN:
		_go(board, BoardTypes.Mode.CHASE, board.player_position)
	elif board.detection == BoardTypes.Detect.HEARD:
		_go(board, BoardTypes.Mode.INVESTIGATE, board.last_known_position)
	elif board.location_leaked:
		_go(board, BoardTypes.Mode.INVESTIGATE, board.player_position)
	elif board.ronald_mode == BoardTypes.Mode.CHASE:
		_go(board, BoardTypes.Mode.INVESTIGATE, board.last_known_position)
	elif board.ronald_mode == BoardTypes.Mode.INVESTIGATE and not board.at_target:
		pass # keep going to the spot
	else:
		_go(board, BoardTypes.Mode.PATROL, board.enemy_position)

	var close := board.enemy_position.distance_to(board.player_position) <= CATCH_RANGE
	if board.ronald_mode == BoardTypes.Mode.CHASE and close:
		board.game_state = BoardTypes.Game.CAUGHT


func _go(board: Blackboard, mode: BoardTypes.Mode, target: Vector3) -> void:
	board.ronald_mode = mode
	board.target_position = target
	board.move_speed = SPEEDS[mode]
