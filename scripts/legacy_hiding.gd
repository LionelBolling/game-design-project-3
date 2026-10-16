class_name LegacyHiding
extends HidingSystem
## Lionel's HidingSystem in the F5 game, plus the Hiding values only the F5
## game knows (contract v0.2): fuses picked up, the breaker, and the player
## at the exit. Also Hiding's rule from P-002: during Ronald's stare (CATCH)
## the player can't move and turns to face him. Lionel's file is untouched.

const STARE_TURN := 6.0 # how fast the player turns to face Ronald (1/s)
const STARE_PITCH := 0.12 # rad: looking up at his face

## The F5 game (scripts/game.gd): fuses, power_on and at_exit.
var game: Node


func setup(board: Blackboard) -> void:
	super.setup(board)
	_write_progress(board)


func tick(board: Blackboard, delta: float) -> void:
	super.tick(board, delta)
	_write_progress(board)
	if board.ronald_mode == BoardTypes.Mode.CATCH and board.game_state == BoardTypes.Game.PLAYING:
		_hold_for_the_stare(board, delta)


func _write_progress(board: Blackboard) -> void:
	board.fuses_collected = int(game.get("fuses"))
	board.breaker_on = bool(game.get("power_on"))
	board.player_at_exit = bool(game.get("at_exit"))


func _hold_for_the_stare(board: Blackboard, delta: float) -> void:
	body.set("control_enabled", false)
	body.velocity = Vector3.ZERO
	var turn := minf(1.0, STARE_TURN * delta)
	var to := board.enemy_position - body.global_position
	to.y = 0.0
	if to.length_squared() > 0.0001:
		body.rotation.y = lerp_angle(body.rotation.y, atan2(-to.x, -to.z), turn)
	var pitch := lerpf(float(body.get("pitch")), STARE_PITCH, turn)
	body.set("pitch", pitch)
	var eyes := body.get("camera") as Camera3D
	if eyes != null:
		eyes.rotation.x = pitch
