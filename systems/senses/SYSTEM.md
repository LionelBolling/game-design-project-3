# Enemy Senses (Aiden)

> **Agents:** read `AGENTS.md` first, then this whole file. If §6 "Answers" is empty, start with the interview in §5. Don't plan or write code before it's done.

## 1. What the GDD says

- **System:** "Aiden - Enemy Senses: what each mascot can see and hear: enemy_position, enemy_movement."
- **Seam 1:** "One system determines how hidden the player is, while the other reads that information to decide how the enemy should react."
- **Light (Aiden):** "Dark and cold, with bright white or orange lights towards or on the ceiling to lighten areas that aren't dark. A mixture of both hard and soft lighting and no filling in of shadows."
- **Mood (Aiden):** "Grim, Anxiety, Hysteria."
- **Pitch notes:** "Sound cue when he sees you... The player will understand the rule if they're ever within the monster's sensing sphere and uncovered."

## 2. What this system covers

- **Sight:** range, shape, line of sight through the level's walls, and the hidden rule.
- **Hearing:** player noise against distance.
- **Detection:** `NONE`, `HEARD` or `SEEN`, plus where Ronald last noticed the player.
- **The level (D-003, D-008):** the smaller McDonald's + PlayPlace map with its collision, built from the mock's models. Others' markers go in it: Lionel's `HideSpot` scenes and Naomi's patrol points. You place them; their behavior stays theirs.
- **Lighting:** the GDD's light section. The mood comes mostly from your lighting and the ambient audio.

Not yours: whether the player counts as hidden (Hiding), what Ronald does once he notices (Ruleset), or how he moves (Roaming).

## 3. On the board

**You write** (only you):

| Value | Meaning |
|---|---|
| `detection` | `NONE`, `HEARD` or `SEEN` this frame |
| `last_known_position` | Where Ronald last saw or heard the player |

**You read:** `player_position`, `hide_state`, `hide_spot`, `player_noise`, `location_leaked` (Hiding); `enemy_position` and `enemy_velocity` (his facing) from Roaming; `ronald_mode` (for example, sharper senses while chasing).

## 4. Your stub (`senses_stub.gd`)

No walls and no level. SEEN if the player is exposed within 6 m; HEARD within 10 m × `player_noise`; otherwise NONE. `last_known_position` becomes the player's position whenever they're detected. Tests: `tests/senses/test_senses_stub.gd`. **Keep the stub working.**

## 5. Interview: questions for Aiden

One at a time, multiple choice, recommended option first. Recommendations come from the Closing Time draft unless noted.

1. **Sight shape:** A. A sensing sphere around Ronald that needs clear line of sight (pitch notes: "sensing sphere"). B. A cone in front of him, facing his movement. C. A small sphere (he always notices you up close) plus a longer cone.
2. **Sight range:** A. 7 m. B. 5 m. C. 10 m. And does light matter? (If yes, add a `player_in_light` value with Lionel.)
3. **Do walls block sight?** A. Yes: raycast against the level. B. No (simpler, but feels unfair).
4. **Can he ever see a HIDDEN player?** A. Only if he saw you hide (within 1.5 s before you got in). B. Never. C. Always when you're within 1 m.
5. **Hearing:** A. Range = noise × 10 m, through walls, halved while he's moving ("move when he moves"). B. Range = noise × 10 m, no halving. C. No hearing in v1.
6. **The "he saw you" cue (pitch notes):** A. You play it, the moment `detection` turns SEEN. B. Rickey plays it when Ronald starts chasing (Closing Time's two honks). Agree with Rickey.
7. **Rooms in the smaller map** (D-008): A. PlayPlace, dining, counter, small kitchen, bathroom, entrance; cut the walk-in freezer and back hall. B. Keep everything in the mock. C. Something else.
8. **Map size:** A. About 24 × 18 m. B. Keep the mock's footprint, with fewer rooms. C. You choose after a greybox.
9. **How to build the level:** A. Reuse the mock's Blender models and collision code, rebuilt as a scene in `systems/senses/level/`. B. Greybox first, then dress it with the models.
10. **Lighting:** A. The GDD as written: dark and cold, pools of white or orange ceiling light, no fill. B. Add Closing Time's warm parking-lot light through the PlayPlace windows.
11. **The mock's flashlight** (team Q4, with Lionel): A. Cut it. B. Keep it, but it makes you easier to see. C. Keep it as in the mock.

## 6. Answers

*Filled in during the interview. Tuning numbers live here too.*

| # | Answer | Date |
|---|---|---|
| | | |

## 7. Suggested build steps (starting point for `PLAN.md`)

1. **Level v1:** the smaller McDonald's + PlayPlace as `systems/senses/level/level.tscn`, with collision. Mark hiding spots, patrol points and the exit with `Marker3D`s named by convention until Lionel's and Naomi's scenes exist.
2. **Test scene:** copy the sandbox to `systems/senses/test/senses_test.tscn` and put the level in it.
3. **Sight without walls:** a `SensesSystem` (`SimSystem`, id `senses`) applying range plus the hidden rule, giving SEEN. Tests.
4. **Line of sight:** a raycast inside `_can_see(from, to) -> bool`, replaced with a fake in tests. Tests for "behind a wall" and "in the open".
5. **Hearing:** HEARD plus `last_known_position`. Tests.
6. **"Saw you hide":** if he saw you within 1.5 s before you hid, he keeps seeing you. Tests.
7. **Lighting pass** per `docs/ART.md`, within the web budget.
8. **Swap in:** your real system replaces the stub.

## 8. Tests to write

- In range, exposed and in line of sight gives SEEN; behind a wall gives NONE (fake raycast); hidden gives NONE.
- Hearing range scales with noise (and is halved while he moves, if you choose that).
- `last_known_position` updates only when he detects the player.

## 9. Seams and risks

- **Two authorities on "hidden" (Seam 1):** under a table, a ray from Ronald's eyes can still hit the player's head. Trust `hide_state`; don't override HIDDEN with your own raycast.
- **One frame of lag:** you read `enemy_position` before Roaming moves him this frame. That's fine at 60 fps.
- **The level is shared ground.** Others need markers in it (spots, patrol points, the exit). Agree on names early, and put them in `PROGRESS.md` handoff notes.
- **Web budget:** keep lights and draw calls low (`docs/ART.md`).

## 10. Reuse from the mock

`scripts/world.gd`: `_import_diner()` and `_import_appliances()` (placing and batching the GLBs), the collision boxes, the ball-pit MultiMesh, the play tubes, lights, and `_navigation()` / `route()` (an `AStarGrid2D` that Naomi may want). The mock's README has performance numbers and the room layout.

## 11. Done means

`docs/WORKFLOW.md` "Done means".
