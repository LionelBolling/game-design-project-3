# Enemy Ruleset plan

Owner: Rickey · Approved: 2026-10-14 (Rickey: build it in this session, on one branch)

> **Agents:** build one step at a time (`AGENTS.md` Rule 4). Each step gets its own branch from an up-to-date `main` (named in the step), its own PR, and a stop-and-report at the end. The design behind every step is `systems/ruleset/SYSTEM.md` §6; the team-wide parts are `docs/DECISIONS.md` D-019 to D-022 and P-002.

## Goal

Ronald behaves exactly as Rickey's interview describes: dormant until the first fuse, then patrolling, posing, investigating, seeking, camping at the ball pit, chasing and catching, with the run ending CAUGHT or ESCAPED. All of it is tested without a scene, and playable in `systems/ruleset/test/ruleset_test.tscn` with the other three systems as stubs.

## How it's built

- **`RonaldRules`** (`ronald_rules.gd`, a `RefCounted`): Ronald's brain as plain logic. Each frame it reads the board and decides `mode`, `target`, `speed`, `game_state`, and any one-off `cues` (`&"honk"`, `&"whisper"`, `&"scream"`). No nodes, so tests need no scene.
- **`RonaldTuning`** (`ronald_tuning.gd` + `ronald_tuning.tres`, a `Resource`): every number from the interview, editable in the Inspector (Godot's property panel). A second mascot later is a second `.tres` (D-020).
- **`RulesetSystem`** (`ruleset_system.gd`, a `SimSystem` with id `ruleset`): calls `RonaldRules.step()` and copies the results onto the board. Later it owns two display children: `CuePlayer` (sounds) and `GameFlow` (lose and win screens).
- **Borrowed from the demo** (`scripts/`, reference only, never edited): the run phases and `finish()` / `restart()` in `game.gd`, the HUD panels in `hud.gd`, and the catch flow in `stalker.gd`.

**Each frame, `RonaldRules.step()` checks things in this order** (later steps slot into it):

1. The run is over → do nothing.
2. The player is at the exit with the breaker on → ESCAPED (step 9).
3. Then by mode: DORMANT → wait for the first fuse (step 4). CATCH → stare, sprint, caught (step 5). CAMP → wait at the rim (step 7). POSE → hold the pose or wake (step 8). Any other mode → hunt (steps 1, 5, 6, 7).
4. Hunting, in priority order: hidden in the ball pit during a chase or seek → CAMP; within catch range while chasing and seen → CATCH; SEEN → CHASE; a new leak → SEEK; SEEK in progress; HEARD → INVESTIGATE; out of sight while chasing → lose track; searching after arriving; otherwise PATROL (with the pose roll).
5. **At most one mode change per frame,** even on a very long frame.

## File map

| File | Created in | Responsibility |
|---|---|---|
| `systems/ruleset/ronald_tuning.gd` | Step 1 | `RonaldTuning`: every number, grown step by step |
| `systems/ruleset/ronald_tuning.tres` | Step 1 | The default numbers (edit in the Inspector) |
| `systems/ruleset/ronald_rules.gd` | Step 1 | `RonaldRules`: the decisions |
| `systems/ruleset/ruleset_system.gd` | Step 2 | `RulesetSystem`: board in, rules, board out |
| `systems/ruleset/test/ruleset_test.tscn` | Step 2 | The sandbox with `RulesetSystem` in place of the stub |
| `systems/ruleset/cue_player.gd` | Step 10 | `CuePlayer`: honk, whisper, scream |
| `systems/ruleset/game_flow.gd` | Step 11 | `GameFlow`: caught and escaped screens, the reveal, restart |
| `tests/ruleset/test_ronald_rules.gd` | Step 1 | Patrol, investigate, chase, losing track |
| `tests/ruleset/test_ruleset_system.gd` | Step 2 | Board wiring, running under the Director |
| `tests/ruleset/test_ronald_dormant.gd` | Step 4 | Dormant until the first fuse |
| `tests/ruleset/test_ronald_catch.gd` | Step 5 | Stare, sprint, caught, nothing after |
| `tests/ruleset/test_ronald_seek.gd` | Step 6 | "I see you" |
| `tests/ruleset/test_ronald_camp.gd` | Step 7 | The ball pit |
| `tests/ruleset/test_ronald_pose.gd` | Step 8 | Statue posing |
| `tests/ruleset/test_ronald_escape.gd` | Step 9 | Escaping |
| `tests/ruleset/test_cue_player.gd`, `test_game_flow.gd` | Steps 10, 11 | Sounds and screens |

## Global constraints

- Godot 4.7.2, GDScript, static typing everywhere, tabs. Compatibility renderer, no threads, audio only after the first input (`AGENTS.md` Rule 9).
- The Ruleset writes **only** `ronald_mode`, `target_position`, `move_speed` and `game_state`. It never moves Ronald and never writes another system's values (`AGENTS.md` Rule 3).
- Every number lives in `RonaldTuning`, never as a literal in `RonaldRules`.
- Full suite before every commit: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`.
- Tests arrange the board with `writer = Blackboard.ANY` (the default on a new board), then call `rules.step(board, delta)`, then check `rules.*`.

## Review focus

The ways this is most likely to break for a player, each pinned by a test in the step that owns it:

1. **A very long frame** (the browser tab was in the background) skips straight through several states. *Test in step 1.*
2. **Climbing out of the pit in his sight while he camps** should restart the chase, not leave him standing there. *Test in step 7.*
3. **Diving into the pit while he's seeking another spot** should make him camp, not catch you. *Test in step 7.*
4. **Reaching the exit in the same frame as being caught:** escaping wins. *Test in step 9.*
5. **After the run ends,** nothing changes until restart, even if he sees you. *Test in step 5.*

---

## Steps

- [x] **1. Ronald's core rules: patrol, investigate, chase, losing track** · branch `ruleset/01-core-rules`
      Test: `tests/ruleset/test_ronald_rules.gd` (below)
      Done when: the tests pass; no scene needed yet.

  **Interfaces produced:** `RonaldTuning` (fields below) and

  ```gdscript
  class_name RonaldRules
  extends RefCounted
  var tuning: RonaldTuning
  var mode: BoardTypes.Mode
  var target: Vector3
  var speed: float
  var game_state: BoardTypes.Game
  var cues: Array[StringName]          # cleared at the start of every step
  func _init(rules_tuning: RonaldTuning) -> void
  func step(board: Blackboard, delta: float) -> void
  ```

  `systems/ruleset/ronald_tuning.gd`:

  ```gdscript
  class_name RonaldTuning
  extends Resource
  ## Ronald's numbers (systems/ruleset/SYSTEM.md §6). Edit ronald_tuning.tres, not this file.

  @export_group("Speeds (m/s)")
  @export var patrol_speed := 1.4
  @export var search_speed := 2.0 # INVESTIGATE, SEEK, walking to the pit rim
  @export var chase_speed := 4.6 # ~10% over the kid's run (demo run: 4.2). Update when Lionel picks his.
  @export_group("Timing (s)")
  @export var lose_track_after := 2.0
  @export var search_time := 5.0
  ```

  `systems/ruleset/ronald_tuning.tres`:

  ```text
  [gd_resource type="Resource" script_class="RonaldTuning" load_steps=2 format=3]

  [ext_resource type="Script" path="res://systems/ruleset/ronald_tuning.gd" id="1"]

  [resource]
  script = ExtResource("1")
  ```

  Tests first (`tests/ruleset/test_ronald_rules.gd`):

  ```gdscript
  extends GutTest
  ## Ronald's core rules: patrol, investigate, chase, losing track.

  var board: Blackboard
  var rules: RonaldRules


  func before_each() -> void:
  	board = Blackboard.new() # writer is ANY: arrange freely
  	rules = RonaldRules.new(RonaldTuning.new())
  	board.player_position = Vector3(0, 0, 0)
  	board.enemy_position = Vector3(10, 0, 0)


  func test_starts_patrolling_at_patrol_speed() -> void:
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.PATROL)
  	assert_eq(rules.speed, rules.tuning.patrol_speed)


  func test_seen_means_chase_the_player_and_honk() -> void:
  	board.detection = BoardTypes.Detect.SEEN
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.CHASE)
  	assert_eq(rules.target, board.player_position)
  	assert_eq(rules.speed, rules.tuning.chase_speed)
  	assert_has(rules.cues, &"honk")


  func test_honks_once_per_chase_not_every_frame() -> void:
  	board.detection = BoardTypes.Detect.SEEN
  	rules.step(board, 0.1)
  	rules.step(board, 0.1)
  	assert_does_not_have(rules.cues, &"honk")


  func test_heard_means_investigate_the_last_known_position() -> void:
  	board.detection = BoardTypes.Detect.HEARD
  	board.last_known_position = Vector3(4, 0, 2)
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.INVESTIGATE)
  	assert_eq(rules.target, Vector3(4, 0, 2))
  	assert_eq(rules.speed, rules.tuning.search_speed)


  func test_keeps_chasing_through_a_short_loss_of_sight() -> void:
  	board.detection = BoardTypes.Detect.SEEN
  	rules.step(board, 0.1)
  	board.detection = BoardTypes.Detect.NONE
  	rules.step(board, rules.tuning.lose_track_after - 0.5)
  	assert_eq(rules.mode, BoardTypes.Mode.CHASE)


  func test_loses_track_after_two_seconds_and_searches_the_last_known_position() -> void:
  	board.detection = BoardTypes.Detect.SEEN
  	board.last_known_position = Vector3(1, 0, 1)
  	rules.step(board, 0.1)
  	board.detection = BoardTypes.Detect.NONE
  	rules.step(board, rules.tuning.lose_track_after)
  	assert_eq(rules.mode, BoardTypes.Mode.INVESTIGATE)
  	assert_eq(rules.target, Vector3(1, 0, 1))


  func test_searches_for_five_seconds_after_arriving_then_patrols() -> void:
  	board.detection = BoardTypes.Detect.HEARD
  	rules.step(board, 0.1)
  	board.detection = BoardTypes.Detect.NONE
  	board.at_target = true
  	rules.step(board, rules.tuning.search_time - 0.5)
  	assert_eq(rules.mode, BoardTypes.Mode.INVESTIGATE)
  	rules.step(board, 0.5)
  	assert_eq(rules.mode, BoardTypes.Mode.PATROL)


  func test_a_very_long_frame_changes_mode_only_once() -> void: # Review focus 1
  	board.detection = BoardTypes.Detect.SEEN
  	rules.step(board, 0.1)
  	board.detection = BoardTypes.Detect.NONE
  	rules.step(board, 30.0) # the browser tab was in the background
  	assert_eq(rules.mode, BoardTypes.Mode.INVESTIGATE, "loses track, but doesn't skip ahead to patrol")
  ```

  Then the implementation (`systems/ruleset/ronald_rules.gd`):

  ```gdscript
  class_name RonaldRules
  extends RefCounted
  ## Ronald's brain as plain logic: reads the board, decides his mode, target,
  ## speed and the run's state. No nodes, so tests need no scene.
  ## RulesetSystem copies the results onto the board each frame.

  var tuning: RonaldTuning
  var mode: BoardTypes.Mode = BoardTypes.Mode.PATROL
  var target := Vector3.ZERO
  var speed := 0.0
  var game_state: BoardTypes.Game = BoardTypes.Game.PLAYING
  ## One-off cues raised this frame: &"honk", &"whisper", &"scream".
  var cues: Array[StringName] = []

  var _unseen_time := 0.0
  var _search_time := 0.0


  func _init(rules_tuning: RonaldTuning) -> void:
  	tuning = rules_tuning
  	speed = tuning.patrol_speed


  func step(board: Blackboard, delta: float) -> void:
  	cues.clear()
  	if game_state != BoardTypes.Game.PLAYING:
  		return
  	_hunt(board, delta)


  func _hunt(board: Blackboard, delta: float) -> void:
  	if board.detection == BoardTypes.Detect.SEEN:
  		_chase(board)
  	elif mode == BoardTypes.Mode.CHASE:
  		target = board.last_known_position
  		_unseen_time += delta
  		if _unseen_time >= tuning.lose_track_after:
  			_investigate(board.last_known_position)
  	elif board.detection == BoardTypes.Detect.HEARD:
  		_investigate(board.last_known_position)
  	elif mode == BoardTypes.Mode.INVESTIGATE:
  		if board.at_target:
  			_search_time += delta
  			if _search_time >= tuning.search_time:
  				_patrol(board)
  	else:
  		_patrol(board)


  func _chase(board: Blackboard) -> void:
  	if mode != BoardTypes.Mode.CHASE:
  		cues.append(&"honk")
  	mode = BoardTypes.Mode.CHASE
  	target = board.player_position
  	speed = tuning.chase_speed
  	_unseen_time = 0.0


  func _investigate(at: Vector3) -> void:
  	mode = BoardTypes.Mode.INVESTIGATE
  	target = at
  	speed = tuning.search_speed
  	_search_time = 0.0


  func _patrol(board: Blackboard) -> void:
  	mode = BoardTypes.Mode.PATROL
  	target = board.enemy_position # ignored by Roaming in PATROL
  	speed = tuning.patrol_speed
  ```

- [x] **2. Plug the Ruleset into the Director, plus a test scene** · branch `ruleset/02-system`
      Test: `tests/ruleset/test_ruleset_system.gd` (below)
      Done when: in `systems/ruleset/test/ruleset_test.tscn` (F6), walking near Ronald turns him red and he chases; break away and he turns orange and searches, then yellow and patrols. He can't catch you yet (step 5).

  **Interfaces:** consumes `RonaldRules`, `RonaldTuning`. Produces:

  ```gdscript
  class_name RulesetSystem
  extends SimSystem
  @export var tuning: RonaldTuning
  var rules: RonaldRules
  ```

  ```gdscript
  extends GutTest
  ## RulesetSystem: rules in, board out.


  func test_writes_its_decisions_to_the_board_each_turn() -> void:
  	var board := Blackboard.new()
  	var system: RulesetSystem = autofree(RulesetSystem.new())
  	board.writer = system.system_id
  	system.setup(board)
  	board.writer = Blackboard.ANY
  	board.detection = BoardTypes.Detect.SEEN
  	board.player_position = Vector3(2, 0, 3)
  	board.writer = system.system_id
  	system.tick(board, 0.1)
  	assert_eq(board.ronald_mode, BoardTypes.Mode.CHASE)
  	assert_eq(board.target_position, Vector3(2, 0, 3))
  	assert_eq(board.move_speed, system.tuning.chase_speed)


  func test_runs_under_the_director_with_the_other_three_stubs() -> void:
  	var director := Director.new()
  	var hiding := HidingStub.new()
  	hiding.keyboard = false
  	director.add_child(hiding)
  	director.add_child(SensesStub.new())
  	director.add_child(RulesetSystem.new())
  	director.add_child(RoamingStub.new())
  	add_child_autofree(director)
  	for i in 120:
  		director.step(1.0 / 60.0)
  	assert_eq(director.board.game_state, BoardTypes.Game.PLAYING)
  	assert_eq(director.board.ronald_mode, BoardTypes.Mode.PATROL)
  ```

  ```gdscript
  class_name RulesetSystem
  extends SimSystem
  ## Enemy Ruleset (Rickey): decides what Ronald does. See systems/ruleset/SYSTEM.md.

  @export var tuning: RonaldTuning = preload("res://systems/ruleset/ronald_tuning.tres")

  var rules: RonaldRules


  func _init() -> void:
  	system_id = &"ruleset"


  func setup(board: Blackboard) -> void:
  	rules = RonaldRules.new(tuning)
  	_write(board)


  func tick(board: Blackboard, delta: float) -> void:
  	rules.step(board, delta)
  	_write(board)


  func _write(board: Blackboard) -> void:
  	board.ronald_mode = rules.mode
  	board.target_position = rules.target
  	board.move_speed = rules.speed
  	board.game_state = rules.game_state
  ```

  Test scene: copy `systems/core/sandbox/sandbox.tscn` to `systems/ruleset/test/ruleset_test.tscn` and change the `Ruleset` node's script to `res://systems/ruleset/ruleset_system.gd`. Keep the other three stubs.

- [x] **3. Contract v0.2 (P-002)** · branch `core/contract-v0.2` · **only after Lionel, Naomi and Aiden sign P-002 in `docs/DECISIONS.md`**
      Test: additions to `tests/core/test_blackboard.gd`, the stub tests, and a new `tests/core/test_sandbox_colors.gd` (below)
      Done when: the suite passes, the sandbox shows all eight modes, and P-002 moves to "Decided" under the next free D- number.

  Change, all in this one PR (`docs/BLACKBOARD.md`, "Changing the contract"):
  - `board_types.gd`: append to `Mode` so existing numbers don't change: `enum Mode { PATROL, INVESTIGATE, CHASE, DORMANT, POSE, SEEK, CAMP, CATCH }`.
  - `blackboard.gd`: add `fuses_collected: int` and `breaker_on: bool` (owner `hiding`), and `target_unreachable: bool` (owner `roaming`), each with a setter and an `OWNERS` entry, like the existing values.
  - `docs/BLACKBOARD.md`: the new rows and modes; version v0.2. Add these meanings: in DORMANT and POSE, Roaming ignores `target_position`; in POSE, `at_target` is true once he's seated; in CATCH with `move_speed` 0, Roaming turns him to face `target_position`; Hiding locks the player's controls while `ronald_mode == CATCH`.
  - `HidingStub`: F picks up a fuse (up to 3), B restores the breaker (only with 3 fuses); fields `fuses: int`, `breaker: bool` for tests.
  - `RoamingStub`: DORMANT stands still; POSE walks to `@export var pose_point := Vector3(6, 0, 4)` and sets `at_target` there; CATCH turns to `target_position` and moves at `move_speed` (0 means stand); always writes `target_unreachable = false`.
  - `sandbox.gd`: a color for every mode; hide Ronald's marker in DORMANT.

  ```gdscript
  # tests/core/test_blackboard.gd (add)
  func test_contract_v0_2_values_have_the_right_owners() -> void:
  	assert_eq(Blackboard.OWNERS[&"fuses_collected"], &"hiding")
  	assert_eq(Blackboard.OWNERS[&"breaker_on"], &"hiding")
  	assert_eq(Blackboard.OWNERS[&"target_unreachable"], &"roaming")


  func test_existing_modes_keep_their_numbers() -> void:
  	assert_eq(BoardTypes.Mode.PATROL, 0)
  	assert_eq(BoardTypes.Mode.INVESTIGATE, 1)
  	assert_eq(BoardTypes.Mode.CHASE, 2)
  ```

  ```gdscript
  # tests/core/test_sandbox_colors.gd
  extends GutTest
  const Sandbox = preload("res://systems/core/sandbox/sandbox.gd")


  func test_the_sandbox_has_a_color_for_every_mode() -> void:
  	for mode: int in BoardTypes.Mode.values():
  		assert_true(Sandbox.MODE_COLORS.has(mode), "no color for %s" % BoardTypes.Mode.keys()[mode])
  ```

  ```gdscript
  # tests/hiding/test_hiding_stub.gd (add)
  func test_the_breaker_needs_all_three_fuses() -> void:
  	hiding.fuses = 2
  	hiding.breaker = true
  	_tick(0.1)
  	assert_false(board.breaker_on)
  	hiding.fuses = 3
  	_tick(0.1)
  	assert_true(board.breaker_on)
  	assert_eq(board.fuses_collected, 3)
  ```

  ```gdscript
  # tests/roaming/test_roaming_stub.gd (add)
  func test_dormant_ronald_stays_still() -> void:
  	board.writer = Blackboard.ANY
  	board.ronald_mode = BoardTypes.Mode.DORMANT
  	board.move_speed = 2.0
  	_tick(1.0)
  	assert_eq(board.enemy_position, Vector3.ZERO)


  func test_pose_walks_to_the_pose_point_and_reports_seated() -> void:
  	board.writer = Blackboard.ANY
  	board.ronald_mode = BoardTypes.Mode.POSE
  	board.move_speed = 100.0
  	_tick(1.0)
  	assert_true(board.at_target)
  ```

- [x] **4. Dormant until the first fuse** · branch `ruleset/04-dormant`
      Test: `tests/ruleset/test_ronald_dormant.gd`
      Done when: in the test scene Ronald is hidden until you press F once.

  Change `RonaldRules`: start in `DORMANT`; in `step()`, before hunting, `if mode == BoardTypes.Mode.DORMANT: _dormant(board); return`, where `_dormant()` switches to `_patrol(board)` once `board.fuses_collected >= 1`. Waking takes the whole frame (one mode change per frame), so update the earlier tests: in `tests/ruleset/test_ronald_rules.gd`, end `before_each()` with `board.fuses_collected = 1` and `rules.step(board, 0.0)`; in `tests/ruleset/test_ruleset_system.gd`, the Director test now expects `BoardTypes.Mode.DORMANT` (no fuses picked up).

  ```gdscript
  extends GutTest
  ## Dormant until the first fuse (D-019).

  var board: Blackboard
  var rules: RonaldRules


  func before_each() -> void:
  	board = Blackboard.new()
  	rules = RonaldRules.new(RonaldTuning.new())


  func test_starts_dormant() -> void:
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.DORMANT)


  func test_stays_dormant_even_with_the_player_in_plain_sight() -> void:
  	board.detection = BoardTypes.Detect.SEEN
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.DORMANT)


  func test_the_first_fuse_wakes_him_into_patrol() -> void:
  	board.fuses_collected = 1
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.PATROL)
  ```

- [x] **5. Catching: a stare, a sprint, then CAUGHT** · branch `ruleset/05-catch`
      Test: `tests/ruleset/test_ronald_catch.gd`
      Done when: in the test scene, letting him reach 3 m freezes him for 2 s, then he lunges and the run ends CAUGHT.

  Add to `RonaldTuning`: `@export var sprint_speed := 8.0` (Speeds), `@export var stare_time := 2.0` (Timing), and a `Distances (m)` group with `catch_range := 3.0` and `caught_range := 0.8`. In `RonaldRules`: in `_hunt()`, before the SEEN branch, `if mode == CHASE and board.detection == SEEN and distance <= tuning.catch_range: _catch(board); return`. In `step()`, `if mode == CATCH: _catching(board, delta); return`. `_catch()` sets CATCH, `speed = 0.0`, `target = board.player_position` and resets `_stare_time`. `_catching()` keeps `target` on the player; adds `delta` to `_stare_time`; once it reaches `stare_time`, sets `speed = tuning.sprint_speed` and appends `&"scream"` (once); while sprinting, within `caught_range` sets `game_state = CAUGHT`.

  ```gdscript
  extends GutTest
  ## Catching: a 2 s stare, an 8 m/s sprint, then CAUGHT (SYSTEM.md §6 Q6).

  var board: Blackboard
  var rules: RonaldRules


  func before_each() -> void:
  	board = Blackboard.new()
  	rules = RonaldRules.new(RonaldTuning.new())
  	board.fuses_collected = 1
  	rules.step(board, 0.0) # wakes from DORMANT (one mode change per frame)
  	board.detection = BoardTypes.Detect.SEEN
  	board.enemy_position = Vector3(5, 0, 0)
  	rules.step(board, 0.1) # now chasing


  func _close_in() -> void:
  	board.enemy_position = Vector3(2.9, 0, 0)
  	rules.step(board, 0.1)


  func test_chasing_within_three_meters_starts_the_stare() -> void:
  	_close_in()
  	assert_eq(rules.mode, BoardTypes.Mode.CATCH)
  	assert_eq(rules.speed, 0.0, "stands still to stare")
  	assert_eq(rules.target, board.player_position, "faces the player")


  func test_stares_for_two_seconds_then_sprints_screaming() -> void:
  	_close_in()
  	rules.step(board, rules.tuning.stare_time)
  	assert_eq(rules.speed, rules.tuning.sprint_speed)
  	assert_has(rules.cues, &"scream")


  func test_the_sprint_reaching_the_player_ends_the_run_caught() -> void:
  	_close_in()
  	rules.step(board, rules.tuning.stare_time)
  	board.enemy_position = Vector3(0.5, 0, 0)
  	rules.step(board, 0.1)
  	assert_eq(rules.game_state, BoardTypes.Game.CAUGHT)


  func test_nothing_changes_after_the_run_ends() -> void: # Review focus 5
  	_close_in()
  	rules.step(board, rules.tuning.stare_time)
  	board.enemy_position = Vector3(0.5, 0, 0)
  	rules.step(board, 0.1)
  	board.detection = BoardTypes.Detect.HEARD
  	rules.step(board, 5.0)
  	assert_eq(rules.game_state, BoardTypes.Game.CAUGHT)
  	assert_eq(rules.mode, BoardTypes.Mode.CATCH)
  	assert_true(rules.cues.is_empty())
  ```

- [x] **6. "I see you" (SEEK)** · branch `ruleset/06-seek`
      Test: `tests/ruleset/test_ronald_seek.gd`
      Done when: in the test scene, hiding (H) for 10 s (the stub's leak time) makes him walk to you; leave before he arrives and he searches, stay and he catches you.

  Add to `RonaldTuning`: `@export var seek_min_warning := 5.0` (Timing). In `RonaldRules._hunt()`, after the SEEN branch: reset `_seek_fired = false` whenever `board.hide_state == EXPOSED`; if `board.location_leaked and not _seek_fired`, then set `_seek_fired = true`, `_seek_spot = board.hide_spot`, append `&"whisper"`, set SEEK with `target = board.player_position`, and `_seek_wait = maxf(0.0, tuning.seek_min_warning - board.enemy_position.distance_to(target) / tuning.search_speed)`. On the frame SEEK starts, `speed = 0.0` if `_seek_wait > 0.0`, else `tuning.search_speed`. On later SEEK frames, count down first, then decide: `_seek_wait -= delta`, then `speed = 0.0 if _seek_wait > 0.0 else tuning.search_speed`. When `board.at_target`: if still `HIDDEN` in `_seek_spot`, call `_catch(board)`; otherwise `_investigate(target)`.

  ```gdscript
  extends GutTest
  ## "I see you": a whisper, at least 5 s of warning, then he comes to the spot (Q4).

  var board: Blackboard
  var rules: RonaldRules


  func before_each() -> void:
  	board = Blackboard.new()
  	rules = RonaldRules.new(RonaldTuning.new())
  	board.fuses_collected = 1
  	rules.step(board, 0.0) # wakes from DORMANT (one mode change per frame)
  	board.enemy_position = Vector3(20, 0, 0)


  func _hide_and_leak(spot: StringName) -> void:
  	board.hide_state = BoardTypes.Hide.HIDDEN
  	board.hide_spot = spot
  	board.location_leaked = true


  func test_a_leak_whispers_and_seeks_the_spot() -> void:
  	_hide_and_leak(&"booth_2")
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.SEEK)
  	assert_eq(rules.target, board.player_position)
  	assert_has(rules.cues, &"whisper")


  func test_waits_so_the_whisper_comes_at_least_five_seconds_before_he_arrives() -> void:
  	board.enemy_position = Vector3(2, 0, 0) # 1 s away at 2 m/s
  	_hide_and_leak(&"booth_2")
  	rules.step(board, 0.1)
  	assert_eq(rules.speed, 0.0, "waits instead of arriving in 1 s")
  	rules.step(board, 4.0)
  	assert_eq(rules.speed, rules.tuning.search_speed)


  func test_still_in_the_spot_when_he_arrives_means_caught() -> void:
  	_hide_and_leak(&"booth_2")
  	rules.step(board, 0.1)
  	board.at_target = true
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.CATCH)


  func test_an_empty_spot_when_he_arrives_means_he_searches_it() -> void:
  	_hide_and_leak(&"booth_2")
  	rules.step(board, 0.1)
  	board.hide_state = BoardTypes.Hide.EXPOSED
  	board.hide_spot = &""
  	board.location_leaked = false
  	board.at_target = true
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.INVESTIGATE)


  func test_whispers_once_per_visit() -> void:
  	_hide_and_leak(&"booth_2")
  	rules.step(board, 0.1)
  	rules.step(board, 0.1)
  	assert_does_not_have(rules.cues, &"whisper")


  func test_a_new_visit_can_leak_again() -> void:
  	_hide_and_leak(&"booth_2")
  	rules.step(board, 0.1)
  	board.hide_state = BoardTypes.Hide.EXPOSED
  	board.location_leaked = false
  	rules.step(board, 0.1)
  	_hide_and_leak(&"booth_3")
  	rules.step(board, 0.1)
  	assert_has(rules.cues, &"whisper")
  ```

- [x] **7. The ball pit (CAMP)** · branch `ruleset/07-camp`
      Test: `tests/ruleset/test_ronald_camp.gd`
      Done when: needs a pit spot in the test scene; until Lionel's spots exist, set `HidingStub`'s spot id to `ball_pit` in the test scene's Inspector and check he camps, then patrols after 10 s.

  Add to `RonaldTuning`: `@export var camp_time := 10.0` (Timing) and a `Ball pit` group with `@export var pit_spot_ids: Array[StringName] = [&"ball_pit"]` (agree the id with Lionel). In `RonaldRules._hunt()`, first: if `mode` is CHASE or SEEK and the player is HIDDEN in a pit spot, call `_camp(board)`. When a leak fires in a pit spot, whisper then `_camp(board)` instead of SEEK. `_camp()` sets CAMP, `target = board.player_position` (Roaming stops at the rim), `speed = tuning.search_speed`, `_camp_time = 0.0`. In `step()`, `if mode == CAMP: _camping(board, delta); return`: SEEN → `_chase(board)`; once stopped (`board.at_target or board.target_unreachable`) add `delta` to `_camp_time`, and at `camp_time` → `_patrol(board)`.

  ```gdscript
  extends GutTest
  ## The ball pit: he never goes in; he camps at the rim for 10 s (Q3).

  var board: Blackboard
  var rules: RonaldRules


  func before_each() -> void:
  	board = Blackboard.new()
  	rules = RonaldRules.new(RonaldTuning.new())
  	board.fuses_collected = 1
  	rules.step(board, 0.0) # wakes from DORMANT (one mode change per frame)
  	board.enemy_position = Vector3(8, 0, 0)


  func _hide_in(spot: StringName) -> void:
  	board.hide_state = BoardTypes.Hide.HIDDEN
  	board.hide_spot = spot


  func test_a_leak_in_the_pit_whispers_then_camps_instead_of_seeking() -> void:
  	_hide_in(&"ball_pit")
  	board.location_leaked = true
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.CAMP)
  	assert_has(rules.cues, &"whisper")


  func test_diving_into_the_pit_mid_chase_turns_the_chase_into_camping() -> void:
  	board.detection = BoardTypes.Detect.SEEN
  	rules.step(board, 0.1)
  	board.detection = BoardTypes.Detect.NONE
  	_hide_in(&"ball_pit")
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.CAMP)


  func test_camps_ten_seconds_at_the_rim_then_patrols() -> void:
  	_hide_in(&"ball_pit")
  	board.location_leaked = true
  	rules.step(board, 0.1)
  	board.target_unreachable = true # Roaming stopped him at the rim
  	rules.step(board, rules.tuning.camp_time - 0.5)
  	assert_eq(rules.mode, BoardTypes.Mode.CAMP)
  	rules.step(board, 0.5)
  	assert_eq(rules.mode, BoardTypes.Mode.PATROL)


  func test_climbing_out_in_his_sight_restarts_the_chase() -> void: # Review focus 2
  	_hide_in(&"ball_pit")
  	board.location_leaked = true
  	rules.step(board, 0.1)
  	board.hide_state = BoardTypes.Hide.EXPOSED
  	board.hide_spot = &""
  	board.detection = BoardTypes.Detect.SEEN
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.CHASE)


  func test_moving_into_the_pit_during_a_seek_camps_instead_of_catching() -> void: # Review focus 3
  	_hide_in(&"booth_2")
  	board.location_leaked = true
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.SEEK)
  	board.location_leaked = false
  	_hide_in(&"ball_pit")
  	board.at_target = true
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.CAMP)
  ```

- [x] **8. Statue posing (POSE)** · branch `ruleset/08-pose`
      Test: `tests/ruleset/test_ronald_pose.gd`
      Done when: in the test scene he sometimes walks to the stub's pose point and freezes; walking up to him (within 1 m) wakes him into a chase.

  "1 in 4 patrol loops" becomes **a 25% roll every 45 s of patrol**, because the patrol route belongs to Roaming and the board doesn't count loops. While he's still walking to the bench, he reacts normally; once seated he ignores sight and sound, and only a nearby **exposed** player wakes him. (These are interpretations to confirm in review.)

  Add to `RonaldTuning` a `Posing` group: `pose_check_every := 45.0`, `pose_chance := 0.25`, `pose_time_min := 20.0`, `pose_time_max := 40.0`, `pose_wake_range := 1.0`, `pose_wake_time := 1.0`. In `RonaldRules`, add `var roll: Callable = func() -> float: return randf()` (tests replace it). In `_patrol()`, reset `_patrol_time = 0.0` only when `mode` wasn't already PATROL. In `_hunt()`'s last branch, after `_patrol(board)`, call `_maybe_pose(board, delta)`: add `delta` to `_patrol_time`; once it reaches `pose_check_every`, reset it, and if `roll.call() < pose_chance`, start POSE (`speed = tuning.patrol_speed` while walking to the bench, `_pose_length = lerpf(pose_time_min, pose_time_max, roll.call())`, `_pose_time` and `_wake_time` reset to 0). In `step()`, `if mode == POSE: _posing(board, delta); return`: not seated (`not board.at_target`) → SEEN means `_chase()`, otherwise keep walking. Seated → count `_pose_time` and patrol at `_pose_length`; an EXPOSED player within `pose_wake_range` counts `_wake_time`, and at `pose_wake_time` → `_chase(board)` (honk).

  ```gdscript
  extends GutTest
  ## Statue posing (Q9).

  var board: Blackboard
  var rules: RonaldRules


  func before_each() -> void:
  	board = Blackboard.new()
  	rules = RonaldRules.new(RonaldTuning.new())
  	board.fuses_collected = 1
  	board.player_position = Vector3(10, 0, 10)
  	board.enemy_position = Vector3(0, 0, 0)
  	rules.step(board, 0.0) # wakes from DORMANT into PATROL


  func _start_pose_seated() -> void:
  	rules.roll = func() -> float: return 0.0
  	rules.step(board, rules.tuning.pose_check_every)
  	board.at_target = true # Roaming seated him on the bench


  func test_a_lucky_roll_during_patrol_starts_a_pose() -> void:
  	rules.roll = func() -> float: return 0.0
  	rules.step(board, rules.tuning.pose_check_every)
  	assert_eq(rules.mode, BoardTypes.Mode.POSE)


  func test_an_unlucky_roll_keeps_him_patrolling() -> void:
  	rules.roll = func() -> float: return 0.99
  	rules.step(board, rules.tuning.pose_check_every)
  	assert_eq(rules.mode, BoardTypes.Mode.PATROL)


  func test_holds_the_pose_then_patrols_again() -> void:
  	_start_pose_seated()
  	rules.step(board, rules.tuning.pose_time_min)
  	assert_eq(rules.mode, BoardTypes.Mode.PATROL)


  func test_a_seated_statue_ignores_what_it_sees() -> void:
  	_start_pose_seated()
  	board.detection = BoardTypes.Detect.SEEN
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.POSE)


  func test_an_exposed_player_within_a_meter_wakes_him_into_a_chase() -> void:
  	_start_pose_seated()
  	board.player_position = Vector3(0.8, 0, 0)
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.POSE, "takes a second to wake")
  	rules.step(board, rules.tuning.pose_wake_time)
  	assert_eq(rules.mode, BoardTypes.Mode.CHASE)
  	assert_has(rules.cues, &"honk")


  func test_seen_on_the_way_to_the_bench_means_a_normal_chase() -> void:
  	rules.roll = func() -> float: return 0.0
  	rules.step(board, rules.tuning.pose_check_every)
  	board.detection = BoardTypes.Detect.SEEN
  	rules.step(board, 0.1)
  	assert_eq(rules.mode, BoardTypes.Mode.CHASE)
  ```

- [x] **9. Escaping** · branch `ruleset/09-escape`
      Test: `tests/ruleset/test_ronald_escape.gd`
      Done when: in the test scene, F three times, B, then hold X ends the run ESCAPED; X without the breaker does nothing.

  In `RonaldRules.step()`, right after the run-over check: `if board.player_at_exit and board.breaker_on: game_state = BoardTypes.Game.ESCAPED; return`.

  ```gdscript
  extends GutTest
  ## Escaping: 3 fuses, the breaker, then the exit (D-019).

  var board: Blackboard
  var rules: RonaldRules


  func before_each() -> void:
  	board = Blackboard.new()
  	rules = RonaldRules.new(RonaldTuning.new())
  	board.fuses_collected = 3
  	rules.step(board, 0.0) # wakes from DORMANT (one mode change per frame)


  func test_the_exit_without_power_does_nothing() -> void:
  	board.player_at_exit = true
  	rules.step(board, 0.1)
  	assert_eq(rules.game_state, BoardTypes.Game.PLAYING)


  func test_the_exit_with_the_breaker_on_ends_the_run_escaped() -> void:
  	board.breaker_on = true
  	board.player_at_exit = true
  	rules.step(board, 0.1)
  	assert_eq(rules.game_state, BoardTypes.Game.ESCAPED)


  func test_escaping_beats_a_catch_in_the_same_frame() -> void: # Review focus 4
  	board.detection = BoardTypes.Detect.SEEN
  	board.enemy_position = Vector3(5, 0, 0)
  	rules.step(board, 0.1)
  	board.enemy_position = Vector3(2.9, 0, 0)
  	rules.step(board, 0.1)
  	rules.step(board, rules.tuning.stare_time)
  	board.enemy_position = Vector3(0.5, 0, 0)
  	board.breaker_on = true
  	board.player_at_exit = true
  	rules.step(board, 0.1)
  	assert_eq(rules.game_state, BoardTypes.Game.ESCAPED)
  ```

- [x] **10. Cue sounds: honk, whisper, scream** · branch `ruleset/10-cues`
      Test: `tests/ruleset/test_cue_player.gd`
      Done when: in the test scene you hear the honk when a chase starts, the whisper when your spot leaks, and the scream at the lunge.

  `CuePlayer` (`cue_player.gd`, extends `Node`) is a child of `RulesetSystem`. `RulesetSystem.tick()` calls `$CuePlayer.play(cue)` for each cue in `rules.cues`. `play()` uses an exported `Dictionary[StringName, AudioStream]` (until real sounds exist, all three use `res://audio/sting.wav`) and records `last_played`. The whisper plays from an `AudioStreamPlayer3D` placed 0.3 m behind the active camera (`get_viewport().get_camera_3d()`), so it sounds like it's right behind your head without touching another system's nodes. When there's no camera (tests), it falls back to a plain `AudioStreamPlayer`.

  ```gdscript
  extends GutTest
  ## CuePlayer: one sound per cue.


  func test_plays_the_sound_for_a_known_cue() -> void:
  	var cues: CuePlayer = add_child_autofree(CuePlayer.new())
  	cues.play(&"honk")
  	assert_eq(cues.last_played, &"honk")


  func test_an_unknown_cue_is_reported_not_played() -> void:
  	var cues: CuePlayer = add_child_autofree(CuePlayer.new())
  	cues.play(&"kazoo")
  	assert_push_error("no sound for cue")
  	assert_eq(cues.last_played, &"")
  ```

- [x] **11. Caught and escaped screens, the reveal, restart** · branch `ruleset/11-game-flow`
      Test: `tests/ruleset/test_game_flow.gd`
      Done when: CAUGHT cuts to black with "Caught. Press R."; ESCAPED shows the reveal (a placeholder figure where Ronald stood, lights up) then "You escaped. Press R."; R restarts. Borrow the panels and the restart from the demo's `hud.gd` and `game.gd`.

  `GameFlow` (`game_flow.gd`, extends `Node`) is a child of `RulesetSystem`, with its own `CanvasLayer` for the screens and a `Node3D` for the reveal. It's display code: it finds the board with `get_tree().get_first_node_in_group(Director.GROUP)` and only reads it. A static `screen_for(game_state) -> StringName` returns `&""`, `&"caught"` or `&"escaped"`; `place_reveal(at: Vector3) -> Node3D` puts the reveal figure at the board's `enemy_position` and uses a placeholder until the intruder model exists (D-022).

  ```gdscript
  extends GutTest
  ## GameFlow: which screen, and where the reveal goes.


  func test_picks_the_screen_from_the_game_state() -> void:
  	assert_eq(GameFlow.screen_for(BoardTypes.Game.PLAYING), &"")
  	assert_eq(GameFlow.screen_for(BoardTypes.Game.CAUGHT), &"caught")
  	assert_eq(GameFlow.screen_for(BoardTypes.Game.ESCAPED), &"escaped")


  func test_the_reveal_stands_where_ronald_was() -> void:
  	var flow: GameFlow = add_child_autofree(GameFlow.new())
  	var reveal := flow.place_reveal(Vector3(3, 0, -2))
  	assert_eq(reveal.global_position, Vector3(3, 0, -2))
  ```

- [x] **12. Into the main game** · branch `ruleset/enemy-ruleset` · **changed 2026-10-16 (D-023):** instead of a new `systems/core/main.tscn`, the F5 game (`scenes/main.tscn`) runs the board, with the real Ruleset and stand-ins for Senses and Roaming (`scripts/legacy_*.gd`). Rickey chose this so the rules drive Ronald in F5 and on the web now. `project.godot` is unchanged.
      Test: `tests/core/test_f5_ruleset.gd` (the four systems in order, Ronald asleep until the first fuse, seen → chase → stare → CAUGHT, the powered exit wins, the exit needs the breaker), plus `test_legacy_hiding.gd`, `test_legacy_senses.gd`, `test_legacy_roaming.gd` and `test_stalker_driven.gd`.
      Done when: F5 plays with Ronald following the rules; full suite green.

## Needs from others

- **Lionel, Naomi, Aiden:** sign P-002 in `docs/DECISIONS.md` before step 3.
- **Lionel:** the kid's run speed (sets `chase_speed`, step 1); the ball pit's hiding-spot id (`ball_pit`, step 7); lock controls while `ronald_mode == CATCH`; write `fuses_collected` and `breaker_on`; the demo's ball-pit wake-up opening (D-022) is the player's, so it's his to port (Ronald is dormant during it anyway).
- **Naomi:** `target_unreachable` (step 7); DORMANT hides his body; POSE picks a bench and seats him (`at_target` when seated); CATCH faces the player at speed 0, then sprints; the CATCH sprint at 8 m/s.
- **Aiden:** the "seen" honk is the Ruleset's (his Senses Q6); bench pose spots, fuses, breaker and exit in the level; the lights come on when `breaker_on` is true.
- **Team:** real honk, whisper and scream sounds (step 10 uses `sting.wav` until then); who makes the intruder model (step 11, D-022).

## Ideas (not in this plan)

- A 4 s grace after waking, like the demo's clown.
- Posing next to a real decoy statue (needs Aiden's art).
- A second mascot as a second `RonaldTuning` (D-020).
- A "the exit is locked" hint when you reach the exit without power.
