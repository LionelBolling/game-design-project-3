extends GutTest
## LegacyHiding: Lionel's HidingSystem in the F5 game, plus the values Hiding
## owns that only the F5 game knows (fuses, breaker, exit), and the stare
## hold from P-002.


class FakePlayer:
	extends CharacterBody3D
	var control_enabled := true
	var hiding_locked := false
	var table_look_level := false
	var pitch := -0.8 # looking at the floor


class FakeGame:
	extends Node
	var fuses := 0
	var power_on := false
	var at_exit := false


var board: Blackboard
var player: FakePlayer
var game: FakeGame
var hiding: LegacyHiding


func before_each() -> void:
	board = Blackboard.new()
	player = add_child_autofree(FakePlayer.new())
	game = autofree(FakeGame.new())
	hiding = LegacyHiding.new()
	hiding.external_body = true
	hiding.keyboard = false
	hiding.body = player
	hiding.game = game
	add_child_autofree(hiding)
	board.writer = hiding.system_id
	hiding.setup(board)
	board.writer = Blackboard.ANY


func _tick(delta := 0.1) -> void:
	board.writer = hiding.system_id
	hiding.tick(board, delta)
	board.writer = Blackboard.ANY


func test_writes_the_games_fuses_breaker_and_exit() -> void:
	assert_eq(board.fuses_collected, 0)
	game.fuses = 3
	game.power_on = true
	game.at_exit = true
	_tick()
	assert_eq(board.fuses_collected, 3)
	assert_true(board.breaker_on)
	assert_true(board.player_at_exit)


func test_still_does_lionels_hiding() -> void:
	player.global_position = Vector3(2, 0, 5)
	_tick()
	assert_eq(board.player_position, Vector3(2, 0, 5))
	assert_eq(board.hide_state, BoardTypes.Hide.EXPOSED)


func test_the_stare_holds_the_player_facing_ronald() -> void:
	board.ronald_mode = BoardTypes.Mode.CATCH
	board.enemy_position = Vector3(3, 0, 0) # to the player's right
	player.velocity = Vector3(4, 0, 0)
	for i in 30:
		_tick(0.1)
	assert_false(player.control_enabled)
	assert_eq(player.velocity, Vector3.ZERO)
	var facing := -player.global_basis.z
	assert_almost_eq(facing.x, 1.0, 0.05, "turned to face him")
	assert_almost_eq(player.pitch, LegacyHiding.STARE_PITCH, 0.05, "looking up at him, not at the floor")


func test_outside_the_stare_the_controls_are_left_alone() -> void:
	board.ronald_mode = BoardTypes.Mode.CHASE
	_tick()
	assert_true(player.control_enabled)
