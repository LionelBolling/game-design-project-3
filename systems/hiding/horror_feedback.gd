class_name HorrorFeedback
extends Node
## Presentation only: observe the board and the currently integrated F5 actor.
var voice: AudioStreamPlayer
var music: AudioStreamPlayer
var leak_cue_count: int = 0
var chase_started_count: int = 0
var chasing: bool = false
var voice_managed_by_cutscene: bool = false
var _last_leaked: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	voice = AudioStreamPlayer.new()
	voice.stream = load("res://systems/hiding/i_see_you.wav") as AudioStream
	voice.pitch_scale = 0.76
	voice.volume_db = -3.0
	add_child(voice)
	music = AudioStreamPlayer.new()
	var loop: AudioStreamWAV = load("res://systems/hiding/chase_music.wav") as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = loop.data.size() / 2
	music.stream = loop
	music.volume_db = -11.0
	add_child(music)

func _process(_delta: float) -> void:
	var game: Node = get_parent()
	if game.get("phase") != "play":
		stop()
		return
	var director: Director = get_tree().get_first_node_in_group(Director.GROUP) as Director
	var ronald: Node = game.get("stalker") as Node
	if director != null and ronald != null:
		observe(director.board.location_leaked, bool(ronald.get("chasing")) and bool(ronald.get("active")))

func observe(leaked: bool, is_chasing: bool) -> void:
	if leaked and not _last_leaked:
		leak_cue_count += 1
		if not voice_managed_by_cutscene and DisplayServer.get_name() != "headless":
			voice.play()
	_last_leaked = leaked
	if is_chasing and not chasing:
		chase_started_count += 1
		if DisplayServer.get_name() != "headless":
			music.play()
	elif not is_chasing and chasing:
		music.stop()
	chasing = is_chasing

func stop() -> void:
	chasing = false
	_last_leaked = false
	if voice != null:
		voice.stop()
	if music != null:
		music.stop()

func _exit_tree() -> void:
	stop()
