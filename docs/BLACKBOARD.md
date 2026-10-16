# Blackboard contract

**Version:** v0.2 · **Date:** 2026-10-16 · v0.2 adds the Ruleset's values (P-002 in `DECISIONS.md`)

These are the only values that pass between systems. Four people and their agents build against them in parallel, so **nobody changes them casually**. In code, this table is `Blackboard.OWNERS` and the properties in `systems/core/blackboard.gd`; `tests/core/test_blackboard.gd` fails if the two drift apart.

**Status:** in use; no sign-offs needed (D-024). Expect values to change as systems get built: that's what "Changing the contract" below is for.

## Rules

1. **One writer per value.** Only the system in the "Written by" column may write it. The board refuses other writes and prints an error.
2. **Anyone reads anything.** Read freely; never write what you don't own.
3. **Units:** meters, seconds, meters per second. Positions are world space, at floor level (y = 0 at the feet). Ids are `StringName`s.
4. **Turn order:** Hiding → Senses → Ruleset → Roaming, every physics frame. A value written later in the frame is seen by earlier systems on the next frame.
5. **Starting values** are written in `setup()`, not on the first `tick()`.

## Hiding From Enemies (Lionel)

| Value | Type | Meaning | Default | Stub writes | Read by |
|---|---|---|---|---|---|
| `player_position` | `Vector3` | The player's feet | `(0,0,0)` | Starts at `(0,0,4)`, WASD moves 3 m/s | Senses, Ruleset |
| `player_noise` | `float` 0–1 | How loud the player is this frame | `0` | 0.5 while moving, else 0 | Senses |
| `hide_state` | `BoardTypes.Hide` | `EXPOSED` or `HIDDEN` | `EXPOSED` | H toggles | Senses, Ruleset |
| `hide_spot` | `StringName` | Id of the spot the player is in; `&""` when exposed | `&""` | `&"stub_spot"` while hidden | Ruleset, Senses |
| `hide_time` | `float` s | Time in the current spot; 0 when exposed | `0` | Counts while hidden | Ruleset |
| `location_leaked` | `bool` | The player hid past the limit and their spot is given away (GDD scope) | `false` | True after 10 s hidden | Ruleset, Senses |
| `player_at_exit` | `bool` | The player is in the exit zone. Escaping needs this **and** `breaker_on` (D-019). | `false` | True while X is held | Ruleset |
| `fuses_collected` | `int` 0–3 | How many fuses the player has picked up (v0.2) | `0` | F adds one, up to 3 | Ruleset, display |
| `breaker_on` | `bool` | The player restored the breaker; needs all 3 fuses (v0.2) | `false` | B, once 3 fuses are in | Ruleset, display (lights) |

## Enemy Senses (Aiden)

| Value | Type | Meaning | Default | Stub writes | Read by |
|---|---|---|---|---|---|
| `detection` | `BoardTypes.Detect` | `NONE`, `HEARD` or `SEEN`: what Ronald perceives this frame | `NONE` | SEEN if exposed within 6 m; HEARD within 10 m × noise | Ruleset |
| `last_known_position` | `Vector3` | Where Ronald last saw or heard the player | `(0,0,0)` | Player position whenever detected | Ruleset |

## Enemy Ruleset (Rickey)

| Value | Type | Meaning | Default | Stub writes | Read by |
|---|---|---|---|---|---|
| `ronald_mode` | `BoardTypes.Mode` | What Ronald is doing: one of eight modes (below). **Hiding locks the player's controls while it's `CATCH`** (v0.2). | `PATROL` | SEEN → CHASE; HEARD or leaked → INVESTIGATE; else PATROL | Roaming, Senses, Hiding, display |
| `target_position` | `Vector3` | Where Ronald should go. **Ignored in `PATROL`, `DORMANT` and `POSE`**: the patrol route and the benches are Roaming's (GDD: Roaming owns "patrol state"). In `CATCH` with `move_speed` 0, Roaming turns him to face it. | `(0,0,0)` | Player or last known position | Roaming |
| `move_speed` | `float` m/s | How fast Ronald should move | `0` | 1.5 / 2.0 / 3.5 by mode | Roaming |
| `game_state` | `BoardTypes.Game` | `PLAYING`, `CAUGHT` or `ESCAPED` | `PLAYING` | CAUGHT within 1 m while chasing; ESCAPED at exit | everyone, display |

## Roaming Enemies (Naomi)

| Value | Type | Meaning | Default | Stub writes | Read by |
|---|---|---|---|---|---|
| `enemy_position` | `Vector3` | Ronald's feet | `(0,0,0)` | Starts at `(-6,0,-4)`, walks straight lines | Senses, Ruleset, display |
| `enemy_velocity` | `Vector3` m/s | Ronald's movement this frame; its direction is where he faces | `(0,0,0)` | Direction × move_speed | Senses, display |
| `at_target` | `bool` | Ronald has reached `target_position`; in `POSE`, he's seated on his bench | `false` | Within 0.3 m | Ruleset |
| `target_unreachable` | `bool` | Ronald can't reach `target_position` (the ball pit) and went to the nearest reachable point instead (v0.2) | `false` | Always false | Ruleset |

## Enums (`systems/core/board_types.gd`)

```gdscript
enum Hide { EXPOSED, HIDDEN }
enum Detect { NONE, HEARD, SEEN }
enum Mode { PATROL, INVESTIGATE, CHASE, DORMANT, POSE, SEEK, CAMP, CATCH }
enum Game { PLAYING, CAUGHT, ESCAPED }
```

**The modes** (new ones go at the end, so existing numbers never change):

| Mode | Meaning | Roaming does |
|---|---|---|
| `PATROL` | Walking his rounds | Follows its own patrol route |
| `INVESTIGATE` | Checking out a noise or a lost trail | Walks to `target_position` |
| `CHASE` | Running at the player | Walks to `target_position` fast |
| `DORMANT` (v0.2) | Not active yet (before the first fuse) | Keeps his body hidden and still |
| `POSE` (v0.2) | Frozen on a bench like a statue | Picks a bench, walks there, seats him (`at_target` once seated) |
| `SEEK` (v0.2) | Walking to the player's leaked hiding spot ("I see you") | Walks to `target_position` |
| `CAMP` (v0.2) | Waiting at the ball-pit rim | Walks toward `target_position`, stops at the nearest reachable point |
| `CATCH` (v0.2) | The stare, then the sprint | Faces `target_position` at speed 0, then sprints to it |

## Values we expect to need (not on the board yet)

These came up in the Closing Time draft or the pitch notes. Adding one is a contract change (below).

| Likely value | Writer | Why | Raised in |
|---|---|---|---|
| `player_in_light: bool` | Hiding | If being lit makes you easier to see | `systems/hiding/SYSTEM.md` |

## Changing the contract

No sign-offs (D-024). Anyone can change the board, in one PR:

1. **Change it all together:** `BLACKBOARD.md`, `blackboard.gd` (property and `OWNERS` entry), `board_types.gd` if an enum changes, the affected stubs, and their tests. Run the full suite. A new value that only you write and only you read doesn't belong on the board.
2. **Log it:** a `DECISIONS.md` entry with the value, its type, its meaning, the writer, the readers, and why.
3. **Tell everyone:** say so in the PR description, and add a line to every affected system's "Needs from others" in `PROGRESS.md`.
