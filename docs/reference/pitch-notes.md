# Pitch notes

> The team's brainstorming notes from before the GDD, as Rickey shared them on 2026-10-07. Source material only: where they conflict with the submitted GDD ([gdd-checkpoint.md](gdd-checkpoint.md)) or a later decision in [`docs/DECISIONS.md`](../DECISIONS.md), those win.

## Four pitches

**Familiar thing**

1. Lionel - Random NPC spawns in and screams and runs at you super fast
2. Rickey - Playplace at McDonald's
3. Naomi - Home alone as a kid
4. Aiden - Insect horror game

**Monster**

1. Lionel - Dark entity with wide human eyes. The familiar part is that you can't really see when it's dark.
2. Rickey - Clown / mascot cardboard cutout.
3. Naomi - Deformed ghost. The familiar part is how your brain runs wild as a kid.
4. Aiden - Large insect that is larger than a human.

**Scariest moment**

1. Lionel - Random whisper behind you when the room is dead silent
2. Rickey - You try to move the cardboard, and it randomly becomes alive.
3. Naomi - Hitting the last monster and it turns into an intruder.
4. Aiden - A large centipede blending in with the environment.

## Pick one

We more or less incorporated all the different things together, instead of picking one.

**Final idea:** A kid who hides in a ball pit and ends up being left behind at a McDonald's PlayPlace. The child wanders around the dirty, derelict environment, imagining mascots and figures around the restaurant.

1. McDonald's PlayPlace (ball pit, tubes, tables)
2. Monsters are mascots around the restaurant
3. Horror is centered around the experience of hiding from roaming mascots

## Systems and owners

1. Lionel - Hiding From Enemies: whether the player is hidden and where.
2. Rickey - Enemy Ruleset: each mascot's/monster's rules.
3. Naomi - Roaming Enemies: each mascot's position and patrol state.
4. Aiden - Enemy Senses: what each mascot can see and hear: enemy_position, enemy_movement.

## Seams

1. The seam occurs where the Hiding from Enemies system and Enemy Senses system exchange the player's visibility and detection states. One system determines how hidden the player is, while the other reads that information to decide how the enemy should react.
2. Roaming Enemies must adhere to the Enemy Ruleset. The Enemy Ruleset writes the logic for the central monster, and the Roaming Enemies must read it and decide how to proceed within those constraints.

## The monster: Ronald McDonald (clown)

1. He does not go into the ball pit, which ties into Roaming Enemies. The player can easily find this by hiding and tracking that the monster doesn't pursue them into the bounds of the pit.
2. When the player hides for too long, Ronald is able to locate you, and before coming towards you, he says "I see you". This ties into Hiding from Enemies. It is discovered via the sound cue playing after the player exceeds the time limit.
3. Sound cue when he sees you; this ties to the Enemy Senses, tracking when the player is within a trigger zone. The player will understand the rule if they're ever within the monster's sensing sphere and uncovered.
4. Pre-death stare where the player is jump-scared by the monster running at them.
