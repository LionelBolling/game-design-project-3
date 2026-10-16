extends GutTest
## CuePlayer: one sound per cue, and the Ruleset plays its cues.


func test_plays_the_sound_for_a_known_cue() -> void:
	var cues: CuePlayer = add_child_autofree(CuePlayer.new())
	cues.play(&"honk")
	assert_eq(cues.last_played, &"honk")


func test_an_unknown_cue_is_reported_not_played() -> void:
	var cues: CuePlayer = add_child_autofree(CuePlayer.new())
	cues.play(&"kazoo")
	assert_push_error("no sound for cue")
	assert_eq(cues.last_played, &"")


func test_every_cue_the_rules_raise_has_a_sound() -> void:
	var cues: CuePlayer = add_child_autofree(CuePlayer.new())
	for cue: StringName in [&"honk", &"whisper", &"scream"]:
		assert_true(cues.sounds.has(cue), "no sound for %s" % cue)


func test_the_ruleset_honks_when_a_chase_starts() -> void:
	var board := Blackboard.new()
	var system: RulesetSystem = add_child_autofree(RulesetSystem.new())
	board.writer = system.system_id
	system.setup(board)
	board.writer = Blackboard.ANY
	board.fuses_collected = 1
	board.writer = system.system_id
	system.tick(board, 0.0) # wakes from DORMANT
	board.writer = Blackboard.ANY
	board.detection = BoardTypes.Detect.SEEN
	board.writer = system.system_id
	system.tick(board, 0.1)
	assert_eq(system.cue_player.last_played, &"honk")


func test_a_cue_with_no_sound_is_silent_not_an_error() -> void:
	var cues: CuePlayer = add_child_autofree(CuePlayer.new())
	cues.sounds[&"whisper"] = null # a game that voices the whisper itself
	cues.play(&"whisper")
	assert_eq(cues.last_played, &"whisper")
	assert_false(cues._whisper.playing)
	assert_false(cues._player.playing)


func test_a_silent_whisper_is_fine_with_a_camera_in_the_scene() -> void:
	var camera: Camera3D = add_child_autofree(Camera3D.new())
	camera.make_current()
	var cues: CuePlayer = add_child_autofree(CuePlayer.new())
	cues.sounds[&"whisper"] = null
	cues.play(&"whisper")
	assert_eq(cues.last_played, &"whisper")
	assert_false(cues._whisper.playing)
