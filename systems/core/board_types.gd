class_name BoardTypes
extends RefCounted
## Shared enums for the blackboard. They are part of the contract in
## docs/BLACKBOARD.md: change them only through its change protocol.


## Is the player in a hiding spot? Written by Hiding.
enum Hide { EXPOSED, HIDDEN }

## What Ronald perceives about the player this frame. Written by Senses.
enum Detect { NONE, HEARD, SEEN }

## What Ronald is trying to do. Written by the Ruleset.
## PATROL: Roaming walks its own patrol route and ignores target_position.
## INVESTIGATE: go to target_position and check it out.
## CHASE: go to target_position (the player) fast.
enum Mode { PATROL, INVESTIGATE, CHASE }

## Is the run still going? Written by the Ruleset.
enum Game { PLAYING, CAUGHT, ESCAPED }
