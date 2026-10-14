# Progress

Every agent reads this first and updates **only its owner's section** at the end of a session. Put anything another system's agent must know in **Handoff notes**.

## On `main` (2026-10-09)

- **Web build:** Aiden's mock game, playable at https://rickeyjohnson.github.io/game-design-project-3/. Run Project (F5) still starts the mock (`scenes/main.tscn`).
- **Foundation (v0.1):** the blackboard, Director, board overlay, and all four stubs in `systems/`. The top-down sandbox is `systems/core/sandbox/sandbox.tscn`.
- **Tests:** GUT 9.7.1 in `addons/gut/`. 7 test files, 32 tests, all passing.
- **Docs:** `AGENTS.md`, `docs/` (spec, architecture, contract, art, workflow, decisions), and one `SYSTEM.md` per system.

---

## Core / foundation (Rickey)

- **Status:** v0.2 built on `ruleset/build`, waiting for P-002 sign-off
- **Updated:** 2026-10-14 (Claude Code, for Rickey)
- **Done:** blackboard with ownership enforcement, Director with `setup()` and turn order, `BoardOverlay` (F2), four stubs, sandbox scene, tests for the board, the Director and the stub pipeline. **Contract v0.2** (on `ruleset/build`): five new modes (DORMANT, POSE, SEEK, CAMP, CATCH), `fuses_collected` and `breaker_on` (Hiding), `target_unreachable` (Roaming); `HidingStub` gains F (fuse), B (breaker) and a `spot_id` export; `RoamingStub` handles DORMANT and POSE; the sandbox draws all eight modes.
- **Next:** P-001 and P-002 signed by all four owners, then merge. Add `systems/core/main.tscn` once Aiden's level and Lionel's player exist (Ruleset plan step 12).
- **Needs from others:** each owner reviews `docs/BLACKBOARD.md` for their values and signs P-001 and P-002 in `docs/DECISIONS.md`.
- **Handoff notes:**
  - Write starting values in `setup()`, not on the first `tick()` (see `docs/ARCHITECTURE.md`, "One frame").
  - Recording frames on macOS needs `--always-on-top`, or the recording freezes (`CLAUDE.md`).
  - `ERROR: Blackboard: ...` lines in the test output are expected: those tests trigger a refused write on purpose.
  - Display code finds the board through `get_tree().get_first_node_in_group(Director.GROUP)`.

## Hiding From Enemies (Lionel)

- **Status:** not started
- **Updated:** -
- **Done:** stub only (`systems/hiding/hiding_stub.gd`)
- **Next:** interview (`systems/hiding/SYSTEM.md` §5)
- **Needs from others:** -
- **Handoff notes:** -

## Enemy Ruleset (Rickey)

- **Status:** plan steps 1–11 built on `ruleset/build` (95 tests passing); step 12 waits for the level and the player. Interview, decisions and plan are in PR #4.
- **Updated:** 2026-10-14 (Claude Code, for Rickey)
- **Done:** `RonaldRules` (all eight modes: dormant until the first fuse, patrol, statue posing, investigate, "I see you" SEEK, ball-pit CAMP, chase, catch), `RonaldTuning` + `ronald_tuning.tres` (every number), `RulesetSystem`, `CuePlayer` (honk, whisper, scream; placeholder `sting.wav`), `GameFlow` (caught and escaped screens, the intruder reveal placeholder, R to restart), and the test scene `systems/ruleset/test/ruleset_test.tscn`.
- **Next:** merge PR #4 and pull it into `ruleset/build`; tick `PLAN.md`; open the build PR once P-002 is signed; step 12 (main scene).
- **Needs from others:** Lionel: the kid's run speed (sets `chase_speed`, now 4.6), the ball pit's spot id (`ball_pit`), locking controls while `ronald_mode == CATCH`, writing `fuses_collected` and `breaker_on`. Naomi: `target_unreachable`, DORMANT (hidden body), POSE (bench, seated), CATCH (face at speed 0, then sprint). Aiden: bench spots, fuses, breaker and exit in the level; lights on with `breaker_on`. Team: real honk, whisper and scream sounds; the intruder model.
- **Handoff notes:**
  - **Unreachable counts as arrived.** If Roaming can't reach `target_position`, set `target_unreachable`: INVESTIGATE, SEEK, CAMP and the CATCH sprint all treat it as arriving. Without it, Ronald waits for `at_target` forever.
  - In POSE, `at_target` means "seated". The pose timer and the wake check only start once it's true.
  - One-off cues are on `RonaldRules.cues` for a single frame; `CuePlayer` plays them. The whisper comes from 0.3 m behind the active camera.

## Roaming Enemies (Naomi)

- **Status:** not started
- **Updated:** -
- **Done:** stub only (`systems/roaming/roaming_stub.gd`)
- **Next:** interview (`systems/roaming/SYSTEM.md` §5)
- **Needs from others:** -
- **Handoff notes:** -

## Enemy Senses (Aiden)

- **Status:** not started
- **Updated:** -
- **Done:** stub only (`systems/senses/senses_stub.gd`). The mock game and assets are on `main` as reference.
- **Next:** interview (`systems/senses/SYSTEM.md` §5), including the smaller map
- **Needs from others:** -
- **Handoff notes:** -
