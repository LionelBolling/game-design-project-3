@AGENTS.md

## Claude Code notes

All project rules are in `AGENTS.md` (imported above). Edit rules there, not here.

- **godot-mcp** (if its tools are available and the editor is open with the addon enabled): use `godot_docs` to check Godot 4.7 APIs before writing engine code, and run scenes and read runtime state to check your changes yourself instead of asking the human to look.
- **Skills:** the superpowers `brainstorming`, `writing-plans` and `test-driven-development` skills fit the interview, plan and build steps in `docs/WORKFLOW.md`. Where a skill's default file location differs, **`WORKFLOW.md` wins**: interview answers go in `systems/<system>/SYSTEM.md` §6 and plans in `systems/<system>/PLAN.md`, not `docs/superpowers/`.
- **Seeing the game:** `godot --path . --write-movie <dir>/f.png --fixed-fps 30 --quit-after 150 <scene>` saves frames you can open, for example `res://systems/core/sandbox/sandbox.tscn`.
- **Personal preferences** (explanation style, verbosity) go in `CLAUDE.local.md`, which isn't committed, not in this file.
