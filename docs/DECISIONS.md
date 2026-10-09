# Decisions log

Why things are the way they are. **Append; never rewrite an old entry.** To reverse one, add a new entry that says it supersedes the old one. Proposals that need sign-off go under "Proposed".

## Decided

**D-001 · 2026-10-09 · Rickey · Engine and web build**
Godot 4.7.2 standard, GDScript, Compatibility renderer. The web export goes to `docs/index.html` with thread support off, and GitHub Pages serves `main`, `/docs`, at https://rickeyjohnson.github.io/game-design-project-3/. `docs/index.pck` stays under 100 MB (Aiden's rule). *Affects:* everyone (`AGENTS.md` Rule 7).

**D-002 · 2026-10-09 · Rickey · Blackboard architecture**
The four systems talk only through one shared `Blackboard`, with one writer per value, and a `Director` that runs them in a fixed order (Hiding → Senses → Ruleset → Roaming). This replaces Project 2's signals and direct method calls so all four can build in parallel against stubs. *Affects:* everyone (`docs/ARCHITECTURE.md`).

**D-003 · 2026-10-09 · Rickey · Ownership is split by the four GDD systems**
Everything belongs to one of the four systems: Hiding (Lionel) gets the player body and hiding spots; Ruleset (Rickey) gets win/lose and the shared foundation in `systems/core/`; Roaming (Naomi) gets Ronald's body and pathfinding; Senses (Aiden) gets the level and lighting. *Affects:* everyone (`AGENTS.md`).

**D-004 · 2026-10-09 · Rickey · No branches; push only what works**
Everyone works on `main`. Pull with rebase before working, commit small, and push only after the full suite passes and the change runs locally. *Affects:* everyone (`AGENTS.md` Rule 6).

**D-005 · 2026-10-09 · Rickey · Aiden's mock game is reference only**
The mock (`scripts/`, `scenes/`, `shaders/`, `tools/`) stays as a playable reference and as the current web build. The real game is built in `systems/`, borrowing the mock's assets, level import and performance tricks. *Affects:* Aiden especially.

**D-006 · 2026-10-09 · Rickey · Sources and precedence**
The submitted GDD, the Closing Time draft and the pitch notes are all source material (`docs/reference/`). Precedence: decisions here > GDD > Closing Time > pitch notes. Closing Time's rules and numbers are the recommended starting answers in each interview. *Affects:* everyone (`docs/GAME_SPEC.md`).

**D-007 · 2026-10-09 · Rickey · Ronald's look: PS1-style McDonald's clown**
Ronald is a low-poly, PS1-era horror version of Ronald McDonald (yellow jumpsuit, red-and-white striped sleeves, red hair, white face paint, red smile), from the reference image Rickey shared. This supersedes Closing Time's flat cardboard cutout. *Affects:* Naomi (Ronald's body), Rickey (rules that depended on the cutout), `docs/ART.md`.

**D-008 · 2026-10-09 · Rickey · A smaller McDonald's + PlayPlace map**
The map is smaller than the mock's and reads more clearly as a McDonald's with a PlayPlace, following the room order of Aiden's final floor plan. The walk-in freezer and back hall are proposed cuts. *Affects:* Aiden (the level), Naomi (patrol routes), Lionel (hiding spots).

**D-009 · 2026-10-09 · Rickey · System docs live with the code**
Each system keeps its docs next to its scripts: `systems/<system>/SYSTEM.md` (context, interview, build steps) and `PLAN.md` (written after the interview). This is lighter than Project 2's per-feature folders. *Affects:* everyone (`docs/WORKFLOW.md`).

**D-010 · 2026-10-09 · Rickey · Tests: GUT 9.7.1**
GUT is copied from Project 2 into `addons/gut/` and run headless (`AGENTS.md` Rule 5). The editor plugin isn't enabled, so `project.godot` is unchanged. It's excluded from the web export. *Affects:* everyone.

**D-011 · 2026-10-09 · Rickey (Claude Code) · Starting values go in `setup()`**
The first sandbox run showed Ronald seeing the player on frame one: Senses read his default position before Roaming had placed him. The Director now runs `setup(board)` for every system, in order, before the first frame. `tests/core/test_stub_pipeline.gd` guards this. *Affects:* everyone writing a system.

## Proposed (need sign-off)

**P-001 · 2026-10-09 · Rickey · Blackboard contract v0.1**
`docs/BLACKBOARD.md` as written. Each owner signs here after reviewing their values. Changes found in interviews come back as their own proposals.
- [ ] Lionel (Hiding)
- [ ] Rickey (Ruleset)
- [ ] Naomi (Roaming)
- [ ] Aiden (Senses)

## Open questions

The team-level ones are in `docs/GAME_SPEC.md` §9 (Q1–Q7). The ones for each system are in that system's `SYSTEM.md` §5.
