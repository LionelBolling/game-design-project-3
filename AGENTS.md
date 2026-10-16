# Agent instructions: McRonald's

This is the **canonical** instruction file for every AI agent on this repo. Codex reads it directly; `CLAUDE.md` and `GEMINI.md` import it. Edit rules **here**, never in those wrappers.

**The project:** a first-person horror game in Godot 4.7.2 (GDScript, Compatibility renderer, web export). A kid left behind after closing in a McRonald's PlayPlace hides from Ronald, a roaming clown mascot, and tries to escape. It's a four-person class project (COMP 440): **four systems, one shared blackboard.**

| System | Owner | Folder |
|---|---|---|
| Hiding From Enemies (+ player body, hiding spots) | Lionel | `systems/hiding/` |
| Enemy Ruleset (+ win/lose, the shared foundation) | Rickey | `systems/ruleset/`, `systems/core/` |
| Roaming Enemies (+ Ronald's body, pathfinding) | Naomi | `systems/roaming/` |
| Enemy Senses (+ the level, lighting) | Aiden | `systems/senses/` |

**Web build:** https://rickeyjohnson.github.io/game-design-project-3/ (GitHub Pages serves `main`, `/docs`).

---

## Rule 1: Read before you act (every session)

1. [`docs/PROGRESS.md`](docs/PROGRESS.md): what's on `main`, each system's status, handoff notes from other agents.
2. [`docs/BLACKBOARD.md`](docs/BLACKBOARD.md): the contract, meaning every shared value, its owner and its readers.
3. Your system's `systems/<system>/SYSTEM.md` and `PLAN.md` (if it exists).
4. The parts of [`docs/GAME_SPEC.md`](docs/GAME_SPEC.md) and [`docs/ART.md`](docs/ART.md) your task touches.

First session, or unsure how systems connect: read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). Process and copy-paste prompts: [`docs/WORKFLOW.md`](docs/WORKFLOW.md). Why things are the way they are: [`docs/DECISIONS.md`](docs/DECISIONS.md). Sources: [`docs/reference/`](docs/reference/).

## Rule 2: Know whose system you're in

- If it isn't clear which teammate you're working for, **ask** before editing.
- Edit only that owner's files: `systems/<system>/`, `tests/<system>/`, and **their own section** of `docs/PROGRESS.md`. Rickey owns both `systems/ruleset/` and `systems/core/`.
- **Shared files are Rickey's:** `systems/core/` (blackboard, Director, sandbox), `project.godot`, `export_presets.cfg`, and the shared docs in `docs/`. Anyone else proposes a change to him.
- **Aiden's mock game** (`scripts/`, `scenes/`, `shaders/`, `tools/`, `tests/smoke.gd`, `tests/visual.gd`) is **reference only**. Copy what you need into your own system folder; don't edit the mock. The assets (`Blender models/`, `audio/`, `Reference photos/`) are Aiden's: instance them, don't change them.

## Rule 3: Talk only through the blackboard

- Systems **never** call each other's methods, connect to each other's signals, or `get_node()` into each other's scenes. The only thing a system knows about another is the values it writes on the board.
- Read any value. Write **only** the values `BLACKBOARD.md` lists for your system. The board refuses any other write and prints an error.
- Need a value that isn't on the board, or a different meaning for one? **Stop and tell the human.** That's a contract change (`BLACKBOARD.md`, "Changing the contract"). Never edit `systems/core/blackboard.gd`, `board_types.gd` or `BLACKBOARD.md` on your own.
- **Build against stubs, never against a teammate's code.** Every system has a stub on `main` that writes believable values. If you need the stub to behave differently, describe it to the human.

## Rule 4: Interview, plan, then build in steps

- **First session on a system:** interview the owner using the questions in their `SYSTEM.md` (§5). **One question at a time**, multiple choice, recommended option first. Record each answer in `SYSTEM.md` §6 as you go.
- Then write `systems/<system>/PLAN.md` from the template in `WORKFLOW.md`. **No system code until the owner approves `PLAN.md`.**
- Build **one plan step at a time**: write the test first, implement, run the full suite, tick the box in `PLAN.md`, commit on your branch, then **stop and report**.
- Don't add features that aren't in the approved plan. Put ideas in `PLAN.md` under "Ideas".

## Rule 5: Test before claiming done

- Write the GUT test first for any rule or number (hide limit, sight range, catch distance, mode changes).
- Run the **full** suite headless before you say a step works:
  ```bash
  godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
  ```
  On macOS, `godot` is `/Applications/Godot.app/Contents/MacOS/Godot`. After pulling new scripts or assets, run `godot --headless --path . --import` once first.
- Report the real result. If tests fail, say so and show the failure. Never claim success you didn't see.
- A test file with a parse error is **skipped**, and GUT can still print "All tests passed". Treat any `SCRIPT ERROR` or `Parse Error` line, or a `Scripts` count lower than the number of `tests/**/test_*.gd` files, as a failure. (`ERROR: Blackboard: ...` lines are expected: some tests trigger a refused write on purpose and assert on it.)
- Put engine queries (raycasts, navmesh paths, `Input`) behind small methods so tests can replace them.
- Feel and visuals need the human. Tell them exactly what to try in their test scene or in `systems/core/sandbox/sandbox.tscn` (F6).

## Rule 6: Git: a branch per change, PRs into `main`

- **`main` is the shared branch, and it must always run:** the full suite passes and Run Project plays. Nobody commits to `main` directly; everything arrives through a pull request (PR).
- **One short-lived branch per change, cut from an up-to-date `main`:**
  ```bash
  git checkout main && git pull
  git checkout -b <system>/<NN>-<slug>
  ```
  `NN` is the `PLAN.md` step number, for example `hiding/02-hide-timer` (the interview and plan go on `<system>/00-plan`). Shared work uses `core/<slug>`, `docs/<slug>` or `web/<slug>`.
- Commit small and often on your branch. Messages: `<system>: <what changed>` (for example `hiding: add hide timer`).
- **Before opening a PR:** bring in what merged since you branched (`git pull origin main`), run the full suite, and run the game or your test scene with your change.
- **One PR per branch, into `main`.** Say what changed, what you tested, and what to try. Merge when those checks pass. A PR that changes the contract or `systems/core/` needs Rickey's approval first.
- **No stacked PRs** (a PR whose base is another unmerged branch), and never branch off a teammate's branch. If you need someone's unmerged work, keep building against their stub.
- **After the merge:** delete the branch, `git checkout main && git pull`, and run the game once.
- **Ask the human before pushing, opening a PR or merging.** Never push to `main` directly, and never force-push.
- A merge conflict in a file you don't own: stop and tell the human. In the shared logs (`PROGRESS.md`, `DECISIONS.md`), keep both sides.

## Rule 7: Web export

These rules came from Aiden's earlier `AGENTS.md`.

- The release web export lives in `docs/index.html`, with its generated files beside it. GitHub Pages serves it from `main`.
- **Don't commit the export on feature branches.** `docs/index.pck` and `docs/index.wasm` are binary, so two branches that both re-export would always conflict.
- After a gameplay or asset change that players should see has merged, whoever merged it re-exports from an up-to-date `main` on a `web/<date>-export` branch and opens a one-commit PR:
  ```bash
  godot --headless --path . --export-release Web docs/index.html
  ```
- Keep `docs/index.pck` under **100 MB** (100,000,000 bytes). Measure it after each export and report the size.
- Keep reference photos, `docs/`, tests, the GUT addon, review files and unused audio out of the web package through `export_presets.cfg`.
- Thread support stays **off**: GitHub Pages can't send the headers a threaded build needs.

## Rule 8: Leave a trail

The other agents don't share your memory. They share the repo.
- At the end of every session (or when asked), update **your owner's section** of `docs/PROGRESS.md`: Status, Updated (date and agent), Done, Next, Needs from others, **Handoff notes**.
- Log decisions others might question in `docs/DECISIONS.md` (append; never rewrite old entries).
- Tuning numbers live in your `SYSTEM.md` §6 ("Answers"). Change them there in the same commit as the code.

## Rule 9: Godot 4.7 and GDScript

- **Godot 4 syntax only:** `@export`, `@onready`, `await`, `CharacterBody3D`, `instantiate()`, `signal.connect(callable)`. No Godot 3 forms. Check unfamiliar APIs against the 4.7 docs (`godot_docs` if godot-mcp is available) and say when docs weren't available.
- **Static typing everywhere:** typed variables, parameters and returns.
- **Web limits:** Compatibility renderer, few dynamic lights, no threads, audio starts only after the first click or key press.
- Tabs for indentation in `.gd` files (`.editorconfig`). Don't name anything `round`.
- **The team is new to Godot.** Briefly explain an engine term the first time you use it in a session. After each step, say what you changed and separate what you checked: code review, Godot import or validation, the test suite, launching the game, playing it.

## Ask first

- Deleting, renaming or moving files
- Installing addons, plugins or packages
- Changing `project.godot`, `export_presets.cfg`, `.gitignore` or anything in `systems/core/`
- Any contract change
- `git push`, opening or merging a PR, rebase or reset
- Reading or editing outside this project

## Never

- Commit `.godot/`, `build/`, credentials or personal editor state
- Edit another owner's files or their section of `PROGRESS.md`
- Make a system depend on another system's code instead of the board
- Commit to `main` directly, stack PRs, or merge anything that breaks `main`
- Skip Rule 5

## Agent-specific notes

- **Codex:** your sandbox may block running Godot. Ask for approval to run the headless GUT command rather than skipping tests. Aiden's agent notes in `memory/` still apply to work for Aiden.
- **Claude Code:** see `CLAUDE.md`.
- **Gemini CLI:** see `GEMINI.md`.
