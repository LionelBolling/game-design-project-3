# Progress

Every agent reads this first and updates **only its owner's section** at the end of a session. Put anything another system's agent must know in **Handoff notes**.

## On `main` (2026-10-09)

- **Web build:** Aiden's mock game, playable at https://rickeyjohnson.github.io/game-design-project-3/. Run Project (F5) still starts the mock (`scenes/main.tscn`).
- **Foundation (v0.1):** the blackboard, Director, board overlay, and all four stubs in `systems/`. The top-down sandbox is `systems/core/sandbox/sandbox.tscn`.
- **Tests:** GUT 9.7.1 in `addons/gut/`. 7 test files, 32 tests, all passing.
- **Docs:** `AGENTS.md`, `docs/` (spec, architecture, contract, art, workflow, decisions), and one `SYSTEM.md` per system.

---

## Core / foundation (Rickey)

- **Status:** v0.1 done
- **Updated:** 2026-10-09 (Claude Code, for Rickey)
- **Done:** blackboard with ownership enforcement, Director with `setup()` and turn order, `BoardOverlay` (F2), four stubs, sandbox scene, tests for the board, the Director and the stub pipeline.
- **Next:** get P-001 signed by all four owners. Add `systems/core/main.tscn` once a level and a real system exist. Apply contract changes as owners propose them.
- **Needs from others:** each owner reviews `docs/BLACKBOARD.md` for their values.
- **Handoff notes:**
  - Write starting values in `setup()`, not on the first `tick()` (see `docs/ARCHITECTURE.md`, "One frame").
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

- **Status:** not started
- **Updated:** -
- **Done:** stub only (`systems/ruleset/ruleset_stub.gd`)
- **Next:** interview (`systems/ruleset/SYSTEM.md` §5), including team question Q1 (how you escape)
- **Needs from others:** -
- **Handoff notes:** -

## Roaming Enemies (Naomi)

- **Status:** not started
- **Updated:** -
- **Done:** stub only (`systems/roaming/roaming_stub.gd`)
- **Next:** interview (`systems/roaming/SYSTEM.md` §5)
- **Needs from others:** -
- **Handoff notes:** -

## Enemy Senses (Aiden)

- **Status:** mock Acts 1.5 and 2 revisions implemented on `ball-pit`; Enemy Senses system not started
- **Updated:** 2026-10-16 (Codex, for Aiden)
- **Done:** stub only in `systems/senses/`. On `ball-pit`, the mock now has 28,224 staggered moving balls, shark timing and bite behavior, ball and creature sounds, and balls that fade on the same depth loops that brighten the green light. Act 1.5 hides the flashlight until F and slows swimming while it is out. Act 2 starts and restarts with a lit flashlight, hides its battery indicators, and has unlimited flashlight charge. The updated blue layout is baked into corridor cells and five route zones; walls separate zones except at the colored doors. Imported caps that blocked the revised route are hidden, while generated tube walls close the 39 marked ends. Act 2 also has the floor hatch and five lights, wall-mounted locks and cabinet, circular wall windows, hiding spots, a distant leviathan, and a centipede with delayed activation and a one-hit jumpscare. Music stops at Act 1.5 and stays off in Act 2. Godot import passed; the full GUT suite has 8 scripts and 38 passing tests; mock Act, traversal, gate, and enemy checks report zero failures.
- **Next:** have Aiden play Acts 1.5 and 2 for horror feel, visibility, audio balance, and puzzle route clarity. Separately interview Aiden using section 5 of systems/senses/SYSTEM.md before building the smaller-map system.
- **Needs from others:** play feedback on the mock scenes; no blackboard contract change is needed for this work.
- **Handoff notes:** `tools/build_blue_maze_mask.py` regenerates the baked blue route and yellow endpoint data from the updated reference picture. Run it if that picture changes again, then rerun `tests/maze_traverse.gd` and `tests/maze_gate_audit.gd`. The mock work is separate from the blackboard contract and Enemy Senses system. Act 1.5 now displays the swim objective without a depth count; the rendered `reviews/act-depth.png` confirms it. Act 1 emergency fuses have a subtle green emissive material and a local green light that disappears when each fuse is collected; `reviews/act-fuse-glow.png` captures the first fuse. Act 2 hide spots now instance `Blender models/vents.glb` on tube walls: two reachable vents beyond each of the green, red, blue, and yellow doors. `reviews/act-maze-vent.png` shows the wall-mounted model; vent placement, capsule traversal, and E hide/unhide checks pass. At the user's request, the current `ball-pit` working tree was exported locally to `docs/index.html` on 2026-10-16; `docs/index.pck` is 16,106,204 bytes, under the 100,000,000-byte limit.
