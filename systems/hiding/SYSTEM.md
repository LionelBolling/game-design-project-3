# Hiding From Enemies (Lionel)

> **Agents:** read `AGENTS.md` first, then this whole file. If §6 "Answers" is empty, start with the interview in §5. Don't plan or write code before it's done.

## 1. What the GDD says

- **System:** "Lionel - Hiding From Enemies: whether the player is hidden and where."
- **Scope:** "The system tracks whether the player is hidden, which hiding spot they occupy and how long they have stayed there. There will also be a limit to how long a player can hide until the location is leaked to the enemy."
- **Seam 1:** "The seam occurs where the Hiding from Enemies system and Enemy Senses system exchange the player's visibility and detection states. One system determines how hidden the player is, while the other reads that information to decide how the enemy should react."
- **Camera and framing (Lionel):** "first-person perspective. Everything will appear larger than the character due to being the size of a child. Tight framing inside the play tubes and ball pit limits visibility, while views beneath tables let the player watch roaming mascots from hiding spots."
- **Palette (Lionel):** `#731F24`, `#B39839`, `#C9C1A5`, `#242522`, `#91CBA5` (see `docs/ART.md`).

## 2. What this system covers

- **The player's body:** a `CharacterBody3D` with a child-height first-person camera, walking (plus running and crouching if you choose), and mouse look.
- **Hiding spots:** a reusable `HideSpot` scene (an `Area3D` with an id and a type) that Aiden places in the level; climbing in and out.
- **The hide timer and the leak limit** (GDD scope).
- **How loud the player is** (`player_noise`), which Senses uses for hearing.
- **The exit zone,** until the team decides how escaping works (GAME_SPEC Q1).
- **The view from hiding:** tight framing in tubes and the ball pit, peeking out from under tables.

Not yours: whether Ronald *notices* you (Senses), what he *does* about it (Ruleset), or the level geometry (Senses / Aiden).

## 3. On the board

**You write** (only you):

| Value | Meaning |
|---|---|
| `player_position` | The player's feet, world space |
| `player_noise` | 0 to 1, how loud the player is this frame |
| `hide_state` | `EXPOSED` or `HIDDEN` |
| `hide_spot` | Id of the spot you're in; `&""` when exposed |
| `hide_time` | Seconds in the current spot |
| `location_leaked` | True once you've hidden past the limit |
| `player_at_exit` | The player is in the exit zone (placeholder) |

**You read:** `game_state` (lock the controls when it isn't `PLAYING`). Anything else is fine to read for display, for example `ronald_mode` for a heartbeat sound.

## 4. Your stub (`hiding_stub.gd`)

The player is a point on the floor that starts at `(0,0,4)`. WASD moves at 3 m/s, H hides or comes out (spot `stub_spot`), hold X to stand in the exit zone. The timer counts while hidden, the spot leaks after 10 s, and moving makes 0.5 noise. Tests: `tests/hiding/test_hiding_stub.gd`. **Keep the stub working**: the others build against it.

## 5. Interview: questions for Lionel

One at a time, multiple choice, recommended option first. Recommendations come from the Closing Time draft (`docs/reference/closing-time-gdd.md`) unless noted.

1. **How do you get into a hiding spot?** A. Press E at the spot; climbing in takes 0.5 s and makes noise. B. Walk or crouch into it and you're hidden automatically. C. Hold crouch inside the spot's area.
2. **Which spots are in v1?** (pick several) Ball pit, play tubes, under tables, booths, bathroom stall, under the counter. Recommended for the smaller map: ball pit, tubes, under tables, booths.
3. **How long until your spot leaks?** A. 20 s in one spot. B. 10 s. C. Different per spot (for example, longer in the ball pit). You decide *when* it leaks; Rickey decides what Ronald does next.
4. **Leaving a spot and coming back:** A. The timer is per spot and resets only when you enter a *different* spot, so ducking out and back in doesn't reset it. B. It resets whenever you leave. C. It drains slowly while you're out.
5. **While hidden, can you:** A. Look around but not move (peek). B. Nothing: fixed view. C. Move slowly inside big spots like the ball pit.
6. **The ball pit:** A. Submerged means safe, but your view shrinks to slits between the balls and sound is muffled. B. It's the same as any other spot.
7. **What makes noise?** A. Crouch-walk 0.1, walk 0.3, wading into or out of the ball pit 0.6, bumping a chair 0.8, running 1.0. B. Only running. C. Nothing in v1.
8. **How does the player move?** A. Walk, run and crouch (the kid runs 3.8 m/s; Ronald chases at 4.2). B. Walk and crouch only. C. Like the mock: walk 2.5, run 4.2, jump.
9. **Camera height:** A. 1.0 m standing, 0.55 m crouched, 0.35 m submerged in the pit; about 80° field of view. B. Keep the mock's values.
10. **Does being in a lit area make you easier to see?** A. Not in v1. B. Yes: add `player_in_light` to the board (a contract change, agreed with Aiden).
11. **The mock's flashlight** (team Q4, with Aiden): A. Cut it. B. Keep it, but it makes you easier to see. C. Keep it as in the mock.
12. **Palette roles:** the GDD lists five colors but not which is the accent. A. Use the proposal in `docs/ART.md` (mint `#91CBA5` = exit sign only). B. A different accent or roles.

## 6. Answers

*Filled in during the interview. Tuning numbers live here too.*

| # | Answer | Date |
|---|---|---|
| | | |

## 7. Suggested build steps (starting point for `PLAN.md`)

1. **Test scene:** copy `systems/core/sandbox/sandbox.tscn` to `systems/hiding/test/hiding_test.tscn`. Add a floor, a table and a box for the ball pit (greybox).
2. **Player body:** a `HidingSystem` (`SimSystem`, id `hiding`) with a `CharacterBody3D` child and a child-height camera; movement inside `tick()`; writes `player_position` (and sets its start in `setup()`).
3. **Noise:** a pure function from movement state to `player_noise`, with tests.
4. **Hide timer:** a plain `HideTimer` class (`RefCounted`): enter spot, leave, advance time, leaked. Unit-test the per-spot rule and the limit.
5. **Hiding spots:** a `HideSpot` scene (`Area3D` plus `spot_id` and `spot_type`). Getting in and out writes `hide_state` and `hide_spot`. Test with a fake overlap.
6. **Views:** peeking, tube and ball-pit framing.
7. **Exit zone:** `player_at_exit` (or whatever Q1 becomes).
8. **Swap in:** your real system replaces the stub in your test scene, then in `main.tscn` when it exists.

## 8. Tests to write

- Noise for each movement state.
- The hide timer counts only while hidden, follows your chosen per-spot rule, and leaks exactly at the limit.
- Entering and leaving a spot sets `hide_state` and `hide_spot`.
- Controls are locked when `game_state` isn't `PLAYING`.

## 9. Seams and risks

- **You are the only authority on "hidden."** Senses trusts `hide_state` and never runs its own "is the player hidden?" check. If Aiden finds he needs one, raise it as a contract question.
- **Noise isn't hidden.** Climbing into the ball pit next to Ronald should still make noise.
- **Exploit:** stepping out of a spot and back in to reset the timer. Question 4 decides this.
- **The leak hands off to the Ruleset.** You set `location_leaked`; Rickey decides the reaction ("I see you"). Agree on what happens after a leak, for example whether it stays true until you change spots.

## 10. Reuse from the mock

- `scripts/player.gd`: walking, running and jumping, mouse look with sensitivity, head bob and the reduced-motion option, the wake-up and sit/stand animation tracks (an opening in the ball pit).
- `scripts/world.gd`: the ball-pit collision and the "nearby balls shift" effect.

## 11. Done means

`docs/WORKFLOW.md` "Done means": the tests pass, it works in your test scene with the other three as stubs, it's pushed, and `PROGRESS.md` is updated.
