# Blackboard contract

**Version:** v0.1 **DRAFT** · **Date:** 2026-10-09

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
| `player_at_exit` | `bool` | The player is in the exit zone. **Placeholder** until the team decides how escaping works (GAME_SPEC Q1). | `false` | True while X is held | Ruleset |

## Enemy Senses (Aiden)

| Value | Type | Meaning | Default | Stub writes | Read by |
|---|---|---|---|---|---|
| `detection` | `BoardTypes.Detect` | `NONE`, `HEARD` or `SEEN`: what Ronald perceives this frame | `NONE` | SEEN if exposed within 6 m; HEARD within 10 m × noise | Ruleset |
| `last_known_position` | `Vector3` | Where Ronald last saw or heard the player | `(0,0,0)` | Player position whenever detected | Ruleset |

## Enemy Ruleset (Rickey)

| Value | Type | Meaning | Default | Stub writes | Read by |
|---|---|---|---|---|---|
| `ronald_mode` | `BoardTypes.Mode` | `PATROL`, `INVESTIGATE` or `CHASE` | `PATROL` | SEEN → CHASE; HEARD or leaked → INVESTIGATE; else PATROL | Roaming, Senses, display |
| `target_position` | `Vector3` | Where Ronald should go. **Ignored in `PATROL`**: the patrol route is Roaming's (GDD: Roaming owns "patrol state"). | `(0,0,0)` | Player or last known position | Roaming |
| `move_speed` | `float` m/s | How fast Ronald should move | `0` | 1.5 / 2.0 / 3.5 by mode | Roaming |
| `game_state` | `BoardTypes.Game` | `PLAYING`, `CAUGHT` or `ESCAPED` | `PLAYING` | CAUGHT within 1 m while chasing; ESCAPED at exit | everyone, display |

## Roaming Enemies (Naomi)

| Value | Type | Meaning | Default | Stub writes | Read by |
|---|---|---|---|---|---|
| `enemy_position` | `Vector3` | Ronald's feet | `(0,0,0)` | Starts at `(-6,0,-4)`, walks straight lines | Senses, Ruleset, display |
| `enemy_velocity` | `Vector3` m/s | Ronald's movement this frame; its direction is where he faces | `(0,0,0)` | Direction × move_speed | Senses, display |
| `at_target` | `bool` | Ronald has reached `target_position` | `false` | Within 0.3 m | Ruleset |

## Enums (`systems/core/board_types.gd`)

```gdscript
enum Hide { EXPOSED, HIDDEN }
enum Detect { NONE, HEARD, SEEN }
enum Mode { PATROL, INVESTIGATE, CHASE }
enum Game { PLAYING, CAUGHT, ESCAPED }
```

## Values we expect to need (not on the board yet)

These came up in the Closing Time draft or the pitch notes. Adding one is a contract change (below).

| Likely value | Writer | Why | Raised in |
|---|---|---|---|
| More `Mode`s: `SEEK` ("I see you"), `CAMP` (waits at the ball-pit rim), `CATCH` (stare, then jumpscare) | Ruleset | Pitch-note rules 1, 2 and 4 | `systems/ruleset/SYSTEM.md` |
| `target_unreachable: bool` | Roaming | Ronald was sent somewhere he can't go, such as into the ball pit | `systems/roaming/SYSTEM.md` |
| `player_in_light: bool` | Hiding | If being lit makes you easier to see | `systems/hiding/SYSTEM.md` |

## Changing the contract

No sign-offs (D-024). Anyone can change the board, in one PR:

1. **Change it all together:** `BLACKBOARD.md`, `blackboard.gd` (property and `OWNERS` entry), `board_types.gd` if an enum changes, the affected stubs, and their tests. Run the full suite. A new value that only you write and only you read doesn't belong on the board.
2. **Log it:** a `DECISIONS.md` entry with the value, its type, its meaning, the writer, the readers, and why.
3. **Tell everyone:** say so in the PR description, and add a line to every affected system's "Needs from others" in `PROGRESS.md`.
