# Roaming Enemies (Naomi)

> **Agents:** read `AGENTS.md` first, then this whole file. If §6 "Answers" is empty, start with the interview in §5. Don't plan or write code before it's done.

## 1. What the GDD says

- **System:** "Naomi - Roaming Enemies: each mascot's position and patrol state."
- **Seam 2:** "Roaming Enemies must adhere to the Enemy Ruleset. The Enemy Ruleset writes the logic for the central monster, and the Roaming Enemies must read it and decide how to proceed within those constraints."
- **Edge and detail (Naomi):** "Detail exists right in front, but rapidly fades further out, leaving monsters and furniture alike as vague silhouettes, their vagueness utilizing the full extent of the viewer's imagination."
- **Ronald's look (D-007):** a low-poly, PS1-style Ronald McDonald-inspired clown (`docs/ART.md`).

## 2. What this system covers

- **Ronald's body:** the model, animation and facing. Placeholder first, then the PS1-style clown.
- **Moving him** through the level: pathfinding around tables, booths and walls.
- **His patrol route and patrol state:** where he walks when the Ruleset says PATROL. The GDD gives patrol state to you.
- **Staying within the Ruleset's constraints:** going where he's told at the speed he's told, keeping out of no-go areas (the ball pit), and reporting when he arrives or can't get there.
- **The edge-and-detail look** where it touches Ronald: he reads as a vague silhouette in the dark. A whole-game PS1 pass is team question Q5, with Lionel.

Not yours: deciding *what* he wants (Ruleset), noticing the player (Senses), or the level geometry (Senses / Aiden).

## 3. On the board

**You write** (only you):

| Value | Meaning |
|---|---|
| `enemy_position` | Ronald's feet, world space |
| `enemy_velocity` | His movement this frame in m/s; its direction is where he faces |
| `at_target` | He has reached `target_position` |

**You read:** `ronald_mode`, `target_position`, `move_speed` and `game_state` (Ruleset). In PATROL, ignore `target_position` and walk your own route.

## 4. Your stub (`roaming_stub.gd`)

Starts at `(-6,0,-4)`. In PATROL, paces between `(-6,0,-4)` and `(6,0,-4)`. Otherwise walks in a straight line to `target_position` at `move_speed`. No pathfinding or level. `at_target` is true within 0.3 m. Tests: `tests/roaming/test_roaming_stub.gd`. **Keep the stub working.**

## 5. Interview: questions for Naomi

One at a time, multiple choice, recommended option first. Recommendations come from the Closing Time draft unless noted.

1. **Pathfinding:** A. Godot's navigation: a `NavigationRegion3D` baked from Aiden's level, and a `NavigationAgent3D` on Ronald. B. The mock's `AStarGrid2D` grid (`scripts/world.gd`). C. Straight lines with simple avoidance for v1.
2. **Patrol route:** A. A loop of waypoints (dining room, counter, bathroom, PlayPlace rim), pausing 1–3 s at each, with a 30% chance of a side branch so it can't be memorized. B. A fixed loop. C. Random points.
3. **Ronald's body for v1:** A. A placeholder capsule now; the PS1-style model later. B. Model first.
4. **Who makes the model?** A. Naomi. B. Aiden (he made the diner models). C. A free low-poly model; check and record its license.
5. **The cleaver from the reference** (team Q6): A. Yes, visual only. B. No.
6. **How he moves:** A. A walk animation with a turn-speed limit, so he can't spin instantly. B. A smooth glide (creepier, easier).
7. **No-go areas (the ball pit):** A. Cut out of the navmesh, so he can't path into it. B. Check the target and refuse it.
8. **A target he can't reach:** A. Walk to the nearest reachable point and report it with a new `target_unreachable` value (a contract change, with Rickey). B. Stop where he is.
9. **The PS1 look** (team Q5, with Lionel): A. Low-res textures and vertex-snapping on Ronald, plus a light whole-game pixelation pass. B. Only Ronald.

## 6. Answers

*Filled in during the interview. Tuning numbers live here too.*

| # | Answer | Date |
|---|---|---|
| | | |

## 7. Suggested build steps (starting point for `PLAN.md`)

1. **Test scene:** copy the sandbox to `systems/roaming/test/roaming_test.tscn`. Add a few boxes as obstacles (greybox).
2. **Ronald's body:** a placeholder capsule as a child of your `RoamingSystem` (`SimSystem`, id `roaming`); `setup()` writes the start position.
3. **Straight-line movement** to the target at `move_speed`, writing position, velocity and `at_target`. Tests (copy the stub's).
4. **The patrol route** from patrol-point markers, with pauses and branches. A plain `PatrolRoute` class with tests.
5. **Pathfinding** around obstacles, behind `_path_to(point) -> PackedVector3Array` (replaced with a fake in tests).
6. **No-go areas and unreachable targets,** per questions 7 and 8 (a contract change first).
7. **The PS1-style Ronald model** and animation, per `docs/ART.md`.
8. **Swap in:** your real system replaces the stub.

## 8. Tests to write

- He moves toward the target at `move_speed` and reports `at_target` on arrival.
- PATROL ignores `target_position` and follows the route in order (with branches, given a fixed random seed).
- He stops when `game_state` isn't `PLAYING`.
- A target inside a no-go area is never walked into (fake path).

## 9. Seams and risks

- **Seam 2 breaks first** (GDD): the Ruleset may send him into the ball pit ("I see you" while you're in the pit). Decide with Rickey what you report, before either of you builds it.
- **Don't decide.** If you find yourself choosing *whether* to chase, that's the Ruleset's call. You choose *how* to get there.
- **The level is Aiden's.** You need it for navigation and patrol points: agree on marker names, and bake navigation from his scene without editing it.

## 10. Reuse from the mock

`scripts/stalker.gd` (following a path at a fixed speed, a creature built from primitives with simple limb animation) and `scripts/world.gd` `_navigation()` / `route()` (grid pathfinding with clearance around furniture, rerouted at 2 Hz).

## 11. Done means

`docs/WORKFLOW.md` "Done means".
