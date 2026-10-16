# Architecture: the blackboard

The four systems never talk to each other. They each read and write one shared object, the **blackboard**, and take turns in a fixed order every frame. That's the whole architecture. The exact values on the board are the contract in [`BLACKBOARD.md`](BLACKBOARD.md).

## The idea in plain terms

Picture a whiteboard on the wall with four columns, one per person:

| Lionel's column (Hiding) | Aiden's column (Senses) | Rickey's column (Ruleset) | Naomi's column (Roaming) |
|---|---|---|---|
| player hidden: **yes** | Ronald sees player: **no** | Ronald's mode: **investigate** | Ronald is at: **the counter** |
| hiding spot: **under table 3** | heard a noise at: **the booths** | go to: **the booths** | moving: **yes** |
| hidden for: **12 seconds** | | speed: **2 m/s** | |

1. **Anyone can read the whole board.**
2. **You only write in your own column.**
3. **Every frame, everyone takes one turn in the same order:** Hiding → Senses → Ruleset → Roaming.

If Lionel's code isn't finished, a **stub** writes fake but believable values in his column, for example "hidden: yes" while you hold H. Aiden's code can't tell the difference. When Lionel's real system is ready, it replaces the stub and nothing else changes.

**What's different from Project 2:** there, systems called each other directly ("Cart, steal this item") and listened to each other's signals. Here nobody calls anybody. That's what lets four people build at the same time.

## One frame

```text
Director._physics_process(delta)
  writer = hiding   -> Hiding.tick(board, delta)    writes player_position, hide_state, hide_time ...
  writer = senses   -> Senses.tick(board, delta)    reads those + enemy_position, writes detection ...
  writer = ruleset  -> Ruleset.tick(board, delta)   reads detection, location_leaked ..., writes ronald_mode, target_position ...
  writer = roaming  -> Roaming.tick(board, delta)   reads ronald_mode, target_position ..., writes enemy_position ...
  writer = nobody
Display code (_process): reads the board and draws, plays sounds, shows UI. Never writes.
```

Before the first frame, the Director runs the same order once with `setup(board)`, so each system writes its starting values, such as where the player and Ronald start. Without that, Senses would read Ronald's default position (the origin) on frame one. (That bug happened while building the stubs; `tests/core/test_stub_pipeline.gd` guards it.)

**One frame of lag is normal.** Roaming moves Ronald last, so Senses sees his new position on the next frame, 1/60 of a second later. Don't fight it.

## The parts (all in `systems/core/`, owned by Rickey)

| File | What it is |
|---|---|
| `blackboard.gd` | `Blackboard`: one typed property per shared value, plus the `OWNERS` table saying which system writes each. A write by anyone else is **refused**: the old value stays and an error is printed. |
| `board_types.gd` | `BoardTypes`: the shared enums (`Hide`, `Detect`, `Mode`, `Game`). |
| `sim_system.gd` | `SimSystem`: the base class for every system and stub. Has `system_id`, `setup(board)` and `tick(board, delta)`. |
| `director.gd` | `Director`: owns the board, runs `setup` once, then gives each child system one turn per physics frame in `ORDER`. Joins the `director` group. |
| `board_overlay.gd` | `BoardOverlay`: press **F2** to see every board value live, grouped by owner. |
| `sandbox/sandbox.tscn` | A top-down test scene: Director plus all four stubs, drawn as markers. Blue = player (gray when hidden); Ronald is colored by mode (yellow patrol, orange investigate, red chase, and so on). WASD move, H hide, F fuse, B breaker, hold X exit, R restart. |

Each system's stub lives in its own folder: `systems/hiding/hiding_stub.gd`, `systems/senses/senses_stub.gd`, `systems/ruleset/ruleset_stub.gd`, `systems/roaming/roaming_stub.gd`. **Keep your stub working on `main`** even after your real system exists: tests and teammates still use it.

## Writing your system

Your real system is a `SimSystem` with the same `system_id` as your stub:

```gdscript
class_name HidingSystem
extends SimSystem
## Hiding From Enemies (Lionel). See systems/hiding/SYSTEM.md.

@onready var _body: CharacterBody3D = $PlayerBody


func _init() -> void:
	system_id = &"hiding"


func setup(board: Blackboard) -> void:
	board.player_position = _body.global_position


func tick(board: Blackboard, delta: float) -> void:
	_move_body(delta)                          # your own node work, inside your turn
	board.player_position = _body.global_position
	board.hide_time = _timer.advance(delta)    # rules in a plain class you can test
	board.location_leaked = _timer.leaked()
```

- **Your system can own nodes.** The player body, cameras, Area3Ds, Ronald's mesh and navigation agent are children of your system node. Do their per-frame work **inside `tick()`**, not in their own `_physics_process`, so the order stays fixed.
- **Put rules in plain classes.** A `HideTimer`, `SightRules` or `RonaldRules` class that extends `RefCounted` can be tested without a scene. Keep `tick()` thin: read the board, call the rules, write the board.
- **Put engine queries behind small methods** (`_can_see(from, to) -> bool`, `_path_to(point) -> PackedVector3Array`) so a test can swap in a fake.
- **One-off moments** (the "I see you" whisper, a cue sound, a jumpscare) aren't board values. Spot them by comparing with last frame: keep `_last_detection` and act when it changes from `NONE` to `SEEN`.
- **Display code** that isn't a system (UI, music, Ronald's mesh following his position) finds the board with `get_tree().get_first_node_in_group(Director.GROUP)` and only reads.

## Swapping a stub for the real system

The Director's children **are** the four systems, in order: `Hiding`, `Senses`, `Ruleset`, `Roaming`. To try yours:

1. Copy `systems/core/sandbox/sandbox.tscn` to your folder, for example `systems/hiding/test/hiding_test.tscn`.
2. In your copy, replace your stub child under `Director` with your real system (same name, same position in the order).
3. Run it with F6. The other three are still stubs, so you only depend on yourself.

The Director prints an error if the children aren't exactly `hiding, senses, ruleset, roaming`.

## Testing pattern

Every test follows the same three steps: arrange the board as `ANY`, switch the writer to your system, tick, assert.

```gdscript
extends GutTest

func test_sees_an_exposed_player_in_range() -> void:
	var board := Blackboard.new()
	var senses: SensesStub = autofree(SensesStub.new())
	board.writer = Blackboard.ANY                  # arrange: anyone may write
	board.player_position = Vector3(0, 0, 0)
	board.enemy_position = Vector3(3, 0, 0)
	board.writer = senses.system_id                # act as the Director would
	senses.tick(board, 0.016)
	assert_eq(board.detection, BoardTypes.Detect.SEEN)
```

The stub tests in `tests/<system>/` are working examples to copy. Board and Director tests are in `tests/core/`.

## Folder layout

```text
AGENTS.md  CLAUDE.md  GEMINI.md  README.md
project.godot  export_presets.cfg  .gutconfig.json  .editorconfig
addons/gut/                  test framework (GUT 9.7.1)
docs/                        shared docs + the web build (GitHub Pages serves this folder)
  reference/                 the GDD, the Closing Time draft, pitch notes
systems/
  core/                      Rickey: blackboard, Director, overlay, sandbox, later main.tscn
  hiding/                    Lionel: SYSTEM.md, PLAN.md, hiding_stub.gd, the real system, test/
  ruleset/                   Rickey
  roaming/                   Naomi
  senses/                    Aiden
tests/
  core/  hiding/  ruleset/  roaming/  senses/
scripts/ scenes/ shaders/ tools/      Aiden's mock: the F5 game, running the board (D-023)
Blender models/  audio/  Reference photos/   assets (Aiden's)
```

**The game that Run Project (F5) starts** is Aiden's mock (`scenes/main.tscn`), and it runs the board (D-023). `scripts/game.gd` holds a Director whose four children are:

| Slot | In the F5 game | Replaced by |
|---|---|---|
| hiding | `LegacyHiding` (`scripts/legacy_hiding.gd`): Lionel's `HidingSystem`, plus the game's fuses, breaker and exit, and the stare hold | Lionel's system writing those values itself |
| senses | `LegacySenses` (`scripts/legacy_senses.gd`): the mock's sight (12 m, walls block) and the stub's hearing | Aiden's system |
| ruleset | `RulesetSystem`, the real one (end screens off: the F5 game draws its own) | — |
| roaming | `LegacyRoaming` (`scripts/legacy_roaming.gd`): walks the mock Ronald (`scripts/stalker.gd`, `driven = true`) on the mock's navigation grid | Naomi's system |

`game.gd` steps the Director each physics frame and ends the run when `game_state` turns CAUGHT or ESCAPED. To swap in a real system, replace that one child and keep its place. The sandbox and each owner's test scene still run the stubs.
