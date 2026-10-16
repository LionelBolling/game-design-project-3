extends GutTest
## The F5 game (scenes/main.tscn) runs the four systems on the board, and the
## Ruleset is in charge of Ronald: whether he's awake, where he goes, how
## fast, and how the run ends.

var game: Node3D
var board: Blackboard
var ronald: Node3D
var player: CharacterBody3D

## More than 12 m from where Ronald wakes up.
const FAR_AWAY := Vector3(30, 0.12, 15)


func before_each() -> void:
	game = load("res://scenes/main.tscn").instantiate() as Node3D
	add_child_autofree(game)
	game.call("start_game")
	game.call("finish_intro")
	game.set_physics_process(false) # the tests step it
	board = (game.get("hiding_director") as Director).board
	ronald = game.get("stalker") as Node3D
	player = game.get("player") as CharacterBody3D
	player.set_physics_process(false)
	player.global_position = FAR_AWAY # out of Ronald's sight when he wakes
	await wait_physics_frames(3)


func after_each() -> void:
	# The imported diner reports null-material diagnostics (see Lionel's
	# test_main_hiding.gd); count them so they aren't unexpected errors.
	var material_diagnostics: int = 1 if DisplayServer.get_name() == "headless" else 4
	for i in material_diagnostics:
		assert_engine_error('Parameter "material" is null.')
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _frames(count: int, delta := 0.1) -> void:
	for i in count:
		if game.get("phase") != "play":
			return
		game.call("_physics_process", delta)


func test_the_board_runs_the_four_systems_with_the_real_ruleset() -> void:
	var director := game.get("hiding_director") as Director
	assert_true(director.get_child(0) is LegacyHiding)
	assert_true(director.get_child(1) is LegacySenses)
	assert_true(director.get_child(2) is RulesetSystem)
	assert_true(director.get_child(3) is LegacyRoaming)
	var ruleset := director.get_child(2) as RulesetSystem
	assert_null(ruleset.game_flow, "the F5 game draws its own end screens")
	assert_true(bool(ronald.get("driven")), "his own brain is off")


func test_lionels_voice_and_scream_replace_the_rules_placeholders() -> void:
	var ruleset := (game.get("hiding_director") as Director).get_child(2) as RulesetSystem
	assert_null(ruleset.cue_player.sounds[&"whisper"])
	assert_null(ruleset.cue_player.sounds[&"scream"])
	assert_not_null(ruleset.cue_player.sounds[&"honk"], "the chase honk is the rules' own")


func test_ronald_sleeps_until_the_first_fuse() -> void:
	_frames(10)
	assert_eq(board.ronald_mode, BoardTypes.Mode.DORMANT)
	assert_false(bool(ronald.get("active")))
	game.set("fuses", 1)
	_frames(2)
	assert_eq(board.ronald_mode, BoardTypes.Mode.PATROL)
	assert_true(bool(ronald.get("active")), "the rules woke him")
	assert_true(ronald.visible)
	var start := ronald.global_position
	_frames(20)
	assert_gt(ronald.global_position.distance_to(start), 1.0, "and he patrols")


func test_seen_in_the_open_means_the_chase_the_stare_and_caught() -> void:
	game.set("fuses", 1)
	_frames(2)
	ronald.global_position = Vector3(3, 0.12, -1)
	player.global_position = Vector3(3, 0.12, 1.5)
	var modes: Array[BoardTypes.Mode] = []
	var locked_in_the_stare := false
	for i in 80:
		if game.get("phase") != "play":
			break
		game.call("_physics_process", 0.1)
		if modes.is_empty() or modes[-1] != board.ronald_mode:
			modes.append(board.ronald_mode)
		if board.ronald_mode == BoardTypes.Mode.CATCH and not bool(player.get("control_enabled")):
			locked_in_the_stare = true
	assert_has(modes, BoardTypes.Mode.CHASE)
	assert_has(modes, BoardTypes.Mode.CATCH)
	assert_true(locked_in_the_stare, "the stare holds the player")
	assert_eq(board.game_state, BoardTypes.Game.CAUGHT)
	assert_eq(game.get("phase"), "caught", "the rules ended the run")


func test_the_powered_exit_wins() -> void:
	game.set("fuses", 3)
	game.set("power_on", true)
	game.set("at_exit", true)
	_frames(1)
	assert_eq(board.game_state, BoardTypes.Game.ESCAPED)
	assert_eq(game.get("phase"), "won")


func test_the_exit_needs_the_breaker() -> void:
	game.set("fuses", 3)
	game.set("at_exit", true)
	_frames(3)
	assert_eq(game.get("phase"), "play")
