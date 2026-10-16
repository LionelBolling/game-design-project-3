class_name CuePlayer
extends Node
## Plays the Ruleset's one-off cues: the honk when a chase starts, the
## "I see you" whisper, and the scream at the lunge (SYSTEM.md §6).
## Display only: it never touches the board.

## One sound per cue. All three use the demo's sting until real sounds exist.
@export var sounds: Dictionary[StringName, AudioStream] = {
	&"honk": preload("res://audio/sting.wav"),
	&"whisper": preload("res://audio/sting.wav"),
	&"scream": preload("res://audio/sting.wav"),
}

## The last cue played, for tests and debugging.
var last_played: StringName = &""

var _player := AudioStreamPlayer.new()
var _whisper := AudioStreamPlayer3D.new()


func _ready() -> void:
	add_child(_player)
	add_child(_whisper)


func play(cue: StringName) -> void:
	if not sounds.has(cue):
		push_error("CuePlayer: no sound for cue '%s'." % cue)
		return
	last_played = cue
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cue == &"whisper" and camera != null:
		# Right behind the player's head: the camera looks down -Z, so +Z is behind it.
		_whisper.global_position = camera.global_transform * Vector3(0, 0, 0.3)
		_whisper.stream = sounds[cue]
		_whisper.play()
	else:
		_player.stream = sounds[cue]
		_player.play()
