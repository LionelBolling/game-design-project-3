class_name LegacySenses
extends SimSystem
## Enemy Senses' stand-in for the F5 game until Aiden's system replaces it.
## The mock's own sight (12 m, walls block, using the mock Ronald's ray) and
## the senses stub's hearing. Ronald senses nothing while he's DORMANT.

const SIGHT := 12.0 # m, the mock's CHASE_DISTANCE
const HEARING := 10.0 # m at full noise, as SensesStub

## The mock's Ronald (scripts/stalker.gd), for his line of sight.
var stalker: Node3D


func _init() -> void:
	system_id = &"senses"


func tick(board: Blackboard, _delta: float) -> void:
	var awake := board.ronald_mode != BoardTypes.Mode.DORMANT
	var distance := board.enemy_position.distance_to(board.player_position)
	var exposed := board.hide_state == BoardTypes.Hide.EXPOSED
	if awake and exposed and distance <= SIGHT and can_see_player():
		board.detection = BoardTypes.Detect.SEEN
	elif awake and board.player_noise > 0.0 and distance <= HEARING * board.player_noise:
		board.detection = BoardTypes.Detect.HEARD
	else:
		board.detection = BoardTypes.Detect.NONE
	if board.detection != BoardTypes.Detect.NONE:
		board.last_known_position = board.player_position


## Nothing solid between Ronald's eyes and the player's. Tests replace it.
func can_see_player() -> bool:
	return stalker != null and bool(stalker.call("_can_see_player"))
