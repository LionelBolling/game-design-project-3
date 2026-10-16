class_name Blackboard
extends RefCounted
## The one shared object the four systems talk through. See docs/BLACKBOARD.md.
##
## Anyone can read any value. Only the system that owns a value may write it:
## the Director sets `writer` before each system's turn, and a write by anyone
## else is refused with an error, leaving the old value in place.


## `writer` for tests and setup code: may write every value.
const ANY := &"any"
## `writer` between turns: may write nothing.
const NOBODY := &"nobody"

## Which system writes each value. This table is the contract in code form.
const OWNERS: Dictionary[StringName, StringName] = {
	# Hiding From Enemies (Lionel)
	&"player_position": &"hiding",
	&"player_noise": &"hiding",
	&"hide_state": &"hiding",
	&"hide_spot": &"hiding",
	&"hide_time": &"hiding",
	&"location_leaked": &"hiding",
	&"player_at_exit": &"hiding",
	&"fuses_collected": &"hiding",
	&"breaker_on": &"hiding",
	# Enemy Senses (Aiden)
	&"detection": &"senses",
	&"last_known_position": &"senses",
	# Enemy Ruleset (Rickey)
	&"ronald_mode": &"ruleset",
	&"target_position": &"ruleset",
	&"move_speed": &"ruleset",
	&"game_state": &"ruleset",
	# Roaming Enemies (Naomi)
	&"enemy_position": &"roaming",
	&"enemy_velocity": &"roaming",
	&"at_target": &"roaming",
	&"target_unreachable": &"roaming",
}

## Who is writing right now. The Director sets it; tests set it to ANY.
var writer: StringName = ANY

# --- Hiding From Enemies (Lionel) --------------------------------------------

## The player's feet, world space, meters.
var player_position := Vector3.ZERO:
	set(value):
		if _may_write(&"player_position"):
			player_position = value

## How loud the player is this frame: 0 silent, 1 loudest.
var player_noise := 0.0:
	set(value):
		if _may_write(&"player_noise"):
			player_noise = value

## EXPOSED or HIDDEN.
var hide_state: BoardTypes.Hide = BoardTypes.Hide.EXPOSED:
	set(value):
		if _may_write(&"hide_state"):
			hide_state = value

## Id of the hiding spot the player is in, or &"" when exposed.
var hide_spot: StringName = &"":
	set(value):
		if _may_write(&"hide_spot"):
			hide_spot = value

## Seconds the player has stayed in the current spot. 0 when exposed.
var hide_time := 0.0:
	set(value):
		if _may_write(&"hide_time"):
			hide_time = value

## True once the player has hidden past the limit and their spot is given away.
var location_leaked := false:
	set(value):
		if _may_write(&"location_leaked"):
			location_leaked = value

## True while the player stands in the exit zone. Placeholder until the team
## decides how escaping works (docs/GAME_SPEC.md open questions).
var player_at_exit := false:
	set(value):
		if _may_write(&"player_at_exit"):
			player_at_exit = value

## How many fuses the player has picked up, 0 to 3 (D-019).
var fuses_collected := 0:
	set(value):
		if _may_write(&"fuses_collected"):
			fuses_collected = value

## True once the player has restored the breaker (needs all 3 fuses).
var breaker_on := false:
	set(value):
		if _may_write(&"breaker_on"):
			breaker_on = value

# --- Enemy Senses (Aiden) ----------------------------------------------------

## NONE, HEARD or SEEN: what Ronald perceives about the player this frame.
var detection: BoardTypes.Detect = BoardTypes.Detect.NONE:
	set(value):
		if _may_write(&"detection"):
			detection = value

## Where Ronald last saw or heard the player, world space.
var last_known_position := Vector3.ZERO:
	set(value):
		if _may_write(&"last_known_position"):
			last_known_position = value

# --- Enemy Ruleset (Rickey) --------------------------------------------------

## PATROL, INVESTIGATE or CHASE.
var ronald_mode: BoardTypes.Mode = BoardTypes.Mode.PATROL:
	set(value):
		if _may_write(&"ronald_mode"):
			ronald_mode = value

## Where Ronald should go. Roaming ignores it in PATROL.
var target_position := Vector3.ZERO:
	set(value):
		if _may_write(&"target_position"):
			target_position = value

## How fast Ronald should move, meters per second.
var move_speed := 0.0:
	set(value):
		if _may_write(&"move_speed"):
			move_speed = value

## PLAYING, CAUGHT or ESCAPED.
var game_state: BoardTypes.Game = BoardTypes.Game.PLAYING:
	set(value):
		if _may_write(&"game_state"):
			game_state = value

# --- Roaming Enemies (Naomi) -------------------------------------------------

## Ronald's feet, world space, meters.
var enemy_position := Vector3.ZERO:
	set(value):
		if _may_write(&"enemy_position"):
			enemy_position = value

## Ronald's movement this frame, meters per second. Its direction is where he faces.
var enemy_velocity := Vector3.ZERO:
	set(value):
		if _may_write(&"enemy_velocity"):
			enemy_velocity = value

## True when Ronald has reached target_position (in POSE: once he's seated).
var at_target := false:
	set(value):
		if _may_write(&"at_target"):
			at_target = value

## True when Ronald can't reach target_position (the ball pit) and went to
## the nearest reachable point instead.
var target_unreachable := false:
	set(value):
		if _may_write(&"target_unreachable"):
			target_unreachable = value


## Every value, in contract order. Used by the debug overlay.
func snapshot() -> Dictionary[StringName, Variant]:
	var values: Dictionary[StringName, Variant] = {}
	for key: StringName in OWNERS:
		values[key] = get(key)
	return values


func _may_write(key: StringName) -> bool:
	var key_owner: StringName = OWNERS[key]
	if writer == ANY or writer == key_owner:
		return true
	push_error("Blackboard: '%s' tried to write '%s', which only '%s' may write (docs/BLACKBOARD.md)." % [writer, key, key_owner])
	return false
