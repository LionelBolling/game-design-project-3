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

- **Status:** not started
- **Updated:** 2026-10-16 (Codex, for Aiden)
- **Done:** stub only (`systems/senses/senses_stub.gd`). The mock game and assets are on `main` as reference.
- **Next:** interview (`systems/senses/SYSTEM.md` §5), including the smaller map
- **Needs from others:** -
- **Handoff notes:** The `ball-pit` branch adds an Act 1.5 deep pit and Act 2 tube maze to Aiden's mock (`scripts/`, `tests/`, and supplied GLBs). The Act 2 routes follow the supplied top-down reference as one connected playable network. Its five keys and five levers use the separate `keys and levers.glb` models at tube height. Visible wall keyholes flank each colored locked gate, and full-width collisions prevent passing around their sides. The black key opens the circle lock; the black lever separately activates the fifth circuit. The 22 marked end caps remain solid. `tests/maze_audit.gd` checks network connectivity, and `tests/maze_traverse.gd` moves a player-sized capsule to every puzzle location and checks the gate edges. Both transitions stay in first person, with a sinking ball view, then shark, leviathan, ball impact, and a direct fall into the maze tubes followed by a getting-up animation. Act 1.5 now has 11,520 moving balls in one MultiMesh and 3,600 scattered balls. Swimming stops without input; Space ascends and Ctrl descends. Both wrap directions brighten the tube light. The Options shortcut still reaches Act 1.5 directly. These mock changes do not change the blackboard contract or Enemy Senses stub and are separate from the planned smaller-map system.
