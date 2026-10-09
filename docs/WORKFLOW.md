# Workflow

How each of us builds our system with an AI agent. It's short on purpose: **interview → plan → build in steps → test → push.** Rules are in [`AGENTS.md`](../AGENTS.md); this file is the how-to, plus prompts you can paste.

## The steps

### 0. Sync (every session)

```bash
git pull --rebase
godot --headless --path . --import
```

Run the import whenever someone has pushed new scripts or assets.

### 1. Read

The agent reads `AGENTS.md` Rule 1: `PROGRESS.md`, `BLACKBOARD.md`, your `SYSTEM.md`, and your `PLAN.md` if you have one.

### 2. Interview (first session only)

The agent asks you the questions in your `SYSTEM.md` §5, **one at a time**, multiple choice, recommended option first. The recommendations mostly come from the Closing Time draft, so you're choosing, not starting from zero. Answers go into `SYSTEM.md` §6 as you go.

If an answer means a board value has to change or be added, the agent stops and writes it up as a contract proposal (`BLACKBOARD.md`, "Changing the contract").

### 3. Plan

The agent writes `systems/<system>/PLAN.md` from the template below, starting from `SYSTEM.md` §7 and adjusted to your answers. **You approve it before any code is written.**

### 4. Build, one step at a time

For each step: write the test first, implement, run the full suite, tick the box in `PLAN.md`, commit locally, then **stop and report** (what changed, what was tested, what to try).

### 5. Check it yourself

- **Rules and numbers:** the GUT suite.
- **Feel and visuals:** your test scene (`systems/<system>/test/`), a copy of the sandbox with your real system in place of your stub. Run it with F6.
- **The whole game:** once `systems/core/main.tscn` exists, Run Project (F5).

### 6. Push (when it works locally)

```bash
git pull --rebase
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
git push
```

If players should see the change on the web, re-export first and commit `docs/` (`AGENTS.md` Rule 7).

### 7. Leave a trail

Update your section of `PROGRESS.md` and add any `DECISIONS.md` entries.

## Prompts to paste

**First session (interview):**
> I'm `<name>` and I own `<system>`. Read `AGENTS.md`, then follow Rule 1. Then interview me using `systems/<system>/SYSTEM.md` §5: one question at a time, multiple choice, recommended option first. Write each answer into §6 as we go. Don't plan or write code yet.

**Plan:**
> Using my answers in `systems/<system>/SYSTEM.md` §6 and the build steps in §7, write `systems/<system>/PLAN.md` from the template in `docs/WORKFLOW.md`. Small steps, each with its test. Don't write code yet; I'll review the plan.

**Build the next step:**
> Read `PROGRESS.md` and my `PLAN.md`. Do the next unchecked step only: test first, implement, run the full GUT suite, tick the box, commit locally. Then stop and tell me what changed, what you tested, and what I should try in my test scene.

**End of session:**
> Update my section of `docs/PROGRESS.md` (Status, Updated, Done, Next, Needs from others, Handoff notes). Add anything others might question to `docs/DECISIONS.md`. Tell me whether it's ready to push.

**Contract change:**
> I need `<value>` on the blackboard because `<reason>`. Write it up as a proposal in `docs/DECISIONS.md` following `docs/BLACKBOARD.md` "Changing the contract". Don't change any code.

## `PLAN.md` template

```markdown
# <System> plan

Owner: <name> · Approved: <date or "not yet">

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
2. It works in your test scene with the other three systems as stubs.
3. Once the main scene exists: it works in Run Project together with everyone's merged work.
4. It's pushed to `main`, and the web build is re-exported if players can see the change.
5. `PROGRESS.md` is updated.
