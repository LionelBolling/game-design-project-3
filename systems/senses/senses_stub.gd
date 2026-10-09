class_name SensesStub
extends SimSystem
## Stand-in for Enemy Senses (Aiden) until the real system replaces it.
## No walls and no level: Ronald sees an exposed player within SIGHT meters and
## hears a noisy one within HEARING meters scaled by how loud they are.


const SIGHT := 6.0 # m
const HEARING := 10.0 # m at full noise


func _init() -> void:
	system_id = &"senses"


func tick(board: Blackboard, _delta: float) -> void:
	var distance := board.enemy_position.distance_to(board.player_position)
	var exposed := board.hide_state == BoardTypes.Hide.EXPOSED
	if exposed and distance <= SIGHT:
		board.detection = BoardTypes.Detect.SEEN
	elif board.player_noise > 0.0 and distance <= HEARING * board.player_noise:
		board.detection = BoardTypes.Detect.HEARD
	else:
		board.detection = BoardTypes.Detect.NONE
	if board.detection != BoardTypes.Detect.NONE:
		board.last_known_position = board.player_position
