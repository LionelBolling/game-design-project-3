class_name BoardTypes
extends RefCounted
## Shared enums for the blackboard. They are part of the contract in
## docs/BLACKBOARD.md: change them only through its change protocol.


## Is the player in a hiding spot? Written by Hiding.
enum Hide { EXPOSED, HIDDEN }

## What Ronald perceives about the player this frame. Written by Senses.
enum Detect { NONE, HEARD, SEEN }

## What Ronald is trying to do. Written by the Ruleset. New modes go at the
## end so the numbers of existing ones never change.
## PATROL: Roaming walks its own patrol route and ignores target_position.
## INVESTIGATE: go to target_position and check it out.
## CHASE: go to target_position (the player) fast.
## DORMANT: not active yet; Roaming keeps his body hidden and still.
## POSE: Roaming walks him to a bench of its choosing and seats him like a
##   statue (target_position ignored; at_target true once seated).
## SEEK: walk to the player's leaked hiding spot ("I see you").
## CAMP: wait at the ball-pit rim (Roaming stops at the nearest reachable point).
## CATCH: stare, then sprint. With move_speed 0 Roaming turns him to face
##   target_position; Hiding locks the player's controls.
enum Mode { PATROL, INVESTIGATE, CHASE, DORMANT, POSE, SEEK, CAMP, CATCH }

## Is the run still going? Written by the Ruleset.
enum Game { PLAYING, CAUGHT, ESCAPED }
