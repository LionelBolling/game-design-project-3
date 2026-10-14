class_name RonaldTuning
extends Resource
## Ronald's numbers (systems/ruleset/SYSTEM.md §6). Edit ronald_tuning.tres, not this file.

@export_group("Speeds (m/s)")
@export var patrol_speed := 1.4
@export var search_speed := 2.0 # INVESTIGATE, SEEK, walking to the pit rim
@export var chase_speed := 4.6 # ~10% over the kid's run (demo run: 4.2). Update when Lionel picks his.
@export_group("Timing (s)")
@export var lose_track_after := 2.0
@export var search_time := 5.0
