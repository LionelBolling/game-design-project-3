# Game spec: McRonald's

What the game is, merged from every source the team has. Each system's owner settles their own details in their interview (`systems/<system>/SYSTEM.md`); this file holds what's shared and what's still open for the whole team.

**When sources disagree, this order wins:**
1. Team decisions in [`DECISIONS.md`](DECISIONS.md), newest first
2. The submitted GDD: [`reference/gdd-checkpoint.md`](reference/gdd-checkpoint.md) (PDF beside it)
3. The Closing Time draft: [`reference/closing-time-gdd.md`](reference/closing-time-gdd.md). It fills the GDD's gaps, and its rules and numbers are the **recommended starting answers** in the interviews.
4. The pitch notes: [`reference/pitch-notes.md`](reference/pitch-notes.md)

## 1. The game

**Core loop (GDD):** "The player has to avoid monsters while trying to escape McRonald's."

**Premise (pitch notes, Closing Time):** a kid hides in the ball pit during a birthday-party game of hide-and-seek, falls asleep, and wakes up after closing, left behind in a McRonald's PlayPlace. The restaurant is dark and dirty, and the kid's imagination turns the mascots into monsters. Ronald roams the building, and the kid has to hide from him and get out.

**The feel of a run (Closing Time, proposed):** peek from a hiding spot, move while Ronald moves away, hide before he turns back, and leave before you've hidden so long that he finds you. Every hiding spot is safe, but none is safe for long. A run lasts about 6 to 10 minutes.

## 2. Where it happens

**One McRonald's restaurant, and nothing else** (GDD cut: no outdoor areas or other buildings). **The map is smaller than the mock's** and reads more clearly as a McDonald's with a PlayPlace (D-008). It follows the room order in [`Reference photos/Final top down layout.png`](<../Reference photos/Final top down layout.png>), scaled down:

| Area | In v1 | Notes |
|---|---|---|
| PlayPlace (north) | Yes | Ball pit, climbing tubes, slide. The game starts here. |
| Dining room (middle) | Yes | Fewer tables and booths than the mock; the half-wall divider stays |
| Order counter | Yes | |
| Kitchen (south) | Yes, small | Behind the counter |
| Bathroom (south-west) | Yes | |
| Entrance (west) | Yes | Probably the exit (Q1) |
| Walk-in freezer, back hall | **Proposed cut** | Aiden decides in his interview |

Exact size: Aiden decides. The proposal is about 24 × 18 m (Closing Time's 30 × 20 m was already judged too big).

## 3. The player

- **First person, child-sized.** "Everything will appear larger than the character due to being the size of a child" (GDD). The camera height is Lionel's call (Closing Time proposes 1.0 m standing).
- **Survives by hiding and escaping only.** No weapons, no fighting (GDD cut: combat). No item storage, collecting materials or crafting (GDD cut: inventory and crafting).
- **Hiding (GDD scope):** the game tracks whether the player is hidden, which spot they're in and how long they've stayed. Hide past the limit and the spot is leaked to Ronald.
- **Fuses are in** (D-013), even though the GDD cut inventory: the only "inventory" is a count of 3 fuses. The demo's flashlight and battery are still open (Q4); the flashlight never freezes Ronald (D-015).

## 4. Ronald

- **Look (D-007):** a low-poly, PS1-style horror clown inspired by Ronald McDonald: yellow jumpsuit, red-and-white striped sleeves, white collar, red hair, white face paint and a red smile. Details are in [`ART.md`](ART.md).
- **One monster in v1** (D-014).
- **His rules are decided:** see `systems/ruleset/SYSTEM.md` §6 for the full list (eight modes, numbers and timings). They grew from the pitch notes:
  1. He won't go into the ball pit.
  2. If you hide too long, he finds you, and says "I see you" before he comes.
  3. A sound cue plays when he sees you inside his sensing range while you're uncovered.
  4. Getting caught is a pre-death stare, then a jumpscare as he runs at you.
- The Closing Time draft turns these into numbers (20 s hide limit, 7 m sight, 3 m catch range, and so on). Those are each owner's recommended starting answers; Rickey's are now decided.

## 5. Winning and losing

- **Lose:** Ronald catches you: a 2 s stare, then a sprint and a cut to black (`game_state = CAUGHT`). The run restarts.
- **Win (D-013):** collect 3 fuses, restore the breaker, then leave through the exit (`game_state = ESCAPED`). Ronald stays dormant until the first fuse. Escaping plays the intruder reveal (D-016).

## 6. The four systems

| System | Owner | GDD line | Doc |
|---|---|---|---|
| Hiding From Enemies | Lionel | "whether the player is hidden and where" | [`systems/hiding/SYSTEM.md`](../systems/hiding/SYSTEM.md) |
| Enemy Ruleset | Rickey | "each mascot's/monster's rules" | [`systems/ruleset/SYSTEM.md`](../systems/ruleset/SYSTEM.md) |
| Roaming Enemies | Naomi | "each mascot's position and patrol state" | [`systems/roaming/SYSTEM.md`](../systems/roaming/SYSTEM.md) |
| Enemy Senses | Aiden | "what each mascot can see and hear: enemy_position, enemy_movement" | [`systems/senses/SYSTEM.md`](../systems/senses/SYSTEM.md) |

They connect only through the blackboard ([`ARCHITECTURE.md`](ARCHITECTURE.md), [`BLACKBOARD.md`](BLACKBOARD.md)).

## 7. The seams (GDD)

1. **Hiding ↔ Senses:** "One system determines how hidden the player is, while the other reads that information to decide how the enemy should react." On the board: Hiding writes `hide_state`, `hide_spot`, `player_noise` and `location_leaked`; Senses reads them and writes `detection`.
2. **Ruleset → Roaming:** "Roaming Enemies must adhere to the Enemy Ruleset... the Roaming Enemies must read it and decide how to proceed within those constraints." On the board: the Ruleset writes `ronald_mode`, `target_position` and `move_speed`; Roaming reads them and writes `enemy_position`.

**Which seam breaks first:** the GDD points at Seam 2. The Closing Time draft predicts where: at the ball-pit rim, where "never enters the pit" meets "comes to your spot if you hide too long", and Ronald gets a target he can't reach. Rickey and Naomi should test that case first.

## 8. Cuts

From the GDD:
- **Combat:** no weapons or fighting.
- **Inventory and crafting:** no item storage, material collection or crafting.
- **Additional locations:** one McRonald's only.

Also cut in the Closing Time draft: a fear/imagination meter (a fifth system), more roaming mascots, and fighting back.

## 9. Open questions for the whole team

Each owner's own questions are in their `SYSTEM.md`. These cross systems:

| # | Question | Options (recommended first) | Decides |
|---|---|---|---|
| Q1 | How does the player escape? | **Decided (D-013):** the demo's 3 fuses, the breaker, then the exit. | Rickey |
| Q2 | One monster or several? | **Decided (D-014):** Ronald only. | Rickey |
| Q3 | Game title? | The GDD says "McRonald's"; the mock says "Ronald's". | Team |
| Q4 | Keep the mock's flashlight? | A. Cut it: the GDD's light comes from the room. B. Keep it, but it makes you easier to see. C. Keep it as in the mock. | Lionel and Aiden |
| Q5 | Whole-game PS1 look (low resolution, pixelation) like the Ronald reference? | A. Yes, a light pixelation pass (Project 2 had one). B. Only Ronald is low-poly. | Naomi and Lionel (edge and detail, camera) |
| Q6 | Does Ronald carry the cleaver from the reference image? | A. Yes, visual only. B. No. | Naomi, with the team |
| Q7 | Opening and ending? | **Decided (D-016):** the demo's ball-pit opening, and a full intruder reveal when you escape. | Rickey |
