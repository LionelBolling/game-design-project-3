class_name RoamingStub
extends SimSystem
## Stand-in for Roaming Enemies (Naomi) until the real system replaces it.
## No level and no pathfinding: Ronald walks in a straight line. In PATROL he
## paces between his own patrol points (the patrol route is Roaming's, per the
## GDD); in POSE he walks to his own pose point and sits there; in DORMANT he
## stays still; in the other modes he walks to target_position at move_speed.
## He can reach everywhere, so target_unreachable is always false.


const ARRIVE := 0.3 # m

## Where Ronald starts.
@export var start_position := Vector3(-6, 0, -4)
## The patrol route, visited in order and looped.
@export var patrol_points: Array[Vector3] = [Vector3(-6, 0, -4), Vector3(6, 0, -4)]
## The bench he sits on in POSE.
@export var pose_point := Vector3(6, 0, 4)

var _patrol_index := 0


func _init() -> void:
	system_id = &"roaming"


func setup(board: Blackboard) -> void:
	board.enemy_position = start_position


func tick(board: Blackboard, delta: float) -> void:
	board.target_unreachable = false
	if board.game_state != BoardTypes.Game.PLAYING or board.ronald_mode == BoardTypes.Mode.DORMANT:
		board.enemy_velocity = Vector3.ZERO
		return

	var goal := board.target_position
	if board.ronald_mode == BoardTypes.Mode.PATROL:
		goal = patrol_points[_patrol_index]
	elif board.ronald_mode == BoardTypes.Mode.POSE:
		goal = pose_point
	var to_goal := goal - board.enemy_position
	to_goal.y = 0.0
	var distance := to_goal.length()
	if distance <= ARRIVE:
		board.enemy_velocity = Vector3.ZERO
		if board.ronald_mode == BoardTypes.Mode.PATROL:
			_patrol_index = (_patrol_index + 1) % patrol_points.size()
	else:
		var direction := to_goal / distance
		board.enemy_velocity = direction * board.move_speed
		board.enemy_position += direction * minf(board.move_speed * delta, distance)

	var arrived_at := pose_point if board.ronald_mode == BoardTypes.Mode.POSE else board.target_position
	var to_target := arrived_at - board.enemy_position
	to_target.y = 0.0
	board.at_target = to_target.length() <= ARRIVE
