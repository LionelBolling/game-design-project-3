# Workflow

How each of us builds with an AI agent. It's short on purpose: **branch → build in steps → test → PR → merge.** Interviewing and planning first are optional. Rules are in [`AGENTS.md`](../AGENTS.md); this file is the how-to, plus prompts you can paste.

## The steps

### 0. Sync and branch (every new change)

```bash
git checkout main && git pull
git checkout -b <system>/<slug>
godot --headless --path . --import
```

- **Branch names:** `<system>/<slug>`, for example `hiding/hide-timer`. Shared work uses `core/<slug>`, `docs/<slug>` or `web/<slug>`.
- **One branch per change.** Short branches merge cleanly.
- **Coming back to a branch?** Run `git pull origin main` first, so you're building on what's merged.
- Run the import whenever new scripts or assets have arrived.

### 1. Read

The agent reads `AGENTS.md` Rule 1: `PROGRESS.md`, `BLACKBOARD.md`, your `SYSTEM.md`, and your `PLAN.md` if you have one.

### 2. Interview and plan (optional)

If you want help deciding: the agent asks you the questions in your `SYSTEM.md` §5, one at a time, and writes the answers into §6. It can then write `systems/<system>/PLAN.md` from the template below. Skip both if you already know what you're building.

If a change needs a new or different board value, change the board in the same PR (`BLACKBOARD.md`, "Changing the contract").

### 3. Build in small steps

For each step: write the test first, implement, run the full suite, commit on your branch, and report what changed, what was tested, and what to try.

### 4. Check it yourself

- **Rules and numbers:** the GUT suite.
- **Feel and visuals:** your test scene (`systems/<system>/test/`), a copy of the sandbox with your real system in place of your stub. Run it with F6.
- **The whole game:** Run Project (F5).

### 5. Leave a trail (on the branch)

Update the section of `PROGRESS.md` for your system and add any `DECISIONS.md` entries, so they arrive in the same PR as the code.

### 6. Open a PR (when it works locally)

```bash
git pull origin main
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
git push -u origin <branch>
gh pr create --base main --title "<system>: <what changed>"
```

The PR description says what changed, what you tested (the suite result, your test scene), and what a teammate should try. Don't include a web export (`AGENTS.md` Rule 7).

### 7. Merge

- Merge when the suite passes and the game or your test scene runs on the branch.
- Then delete the branch, `git checkout main && git pull`, and run the game once.
- If players should see the change, re-export from `main` on a `web/<date>-export` branch and open a one-commit PR (`AGENTS.md` Rule 7).

## Prompts to paste

**Build something:**
> I'm `<name>` and I'm working on `<system>`. Read `AGENTS.md`, then follow Rule 1. Create a branch from an up-to-date `main` (`<system>/<slug>`) and build `<what>`: test first, implement, run the full GUT suite, commit on the branch. Then tell me what changed, what you tested, and what I should try.

**Interview (optional):**
> Interview me using `systems/<system>/SYSTEM.md` §5: one question at a time, multiple choice, recommended option first. Write each answer into §6 as we go.

**Plan (optional):**
> Using my answers in `systems/<system>/SYSTEM.md` §6, write `systems/<system>/PLAN.md` from the template in `docs/WORKFLOW.md`. Small steps, each with its test.

**Open the PR:**
> Update my system's section of `docs/PROGRESS.md` and add anything others might question to `docs/DECISIONS.md`. Then run `git pull origin main`, run the full GUT suite, and tell me the result. If it passes, ask me before pushing the branch and opening a PR into `main` that says what changed, what was tested, and what to try.

**End of session (not ready for a PR yet):**
> Update my section of `docs/PROGRESS.md` (Status, Updated, Done, Next, Needs from others, Handoff notes) and commit it on this branch. Tell me what's left before this branch is ready for a PR.

**Board change:**
> I need `<value>` on the blackboard because `<reason>`. Change the board following `docs/BLACKBOARD.md` "Changing the contract", in this branch, with tests.

## `PLAN.md` template

```markdown
# <System> plan

Owner: <name>

## Goal
One or two sentences: what this system does when the plan is done.

## Steps
- [ ] 1. <small, testable step>
      Test: <the test file and what it checks>
      Done when: <what you can see or run>
- [ ] 2. ...

## Needs from others
- <value or behavior, from whom, by when; "none" if building against stubs is enough>

## Ideas (not in this plan)
- <things to maybe do later>
```

## Done means

1. Its tests pass in the full suite, with no `SCRIPT ERROR` lines.
2. It works in your test scene with the other three systems as stubs, or in Run Project (F5).
3. It's merged into `main` through a PR, and the web build is re-exported if players can see the change.
4. `PROGRESS.md` is updated.
