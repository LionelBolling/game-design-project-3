# Closing Time: Game Design Document (draft)

> An expanded design draft Rickey wrote with Claude on 2026-10-07, exported from the Claude Doc. It is **source material**, not the submitted GDD. Precedence (see [`docs/GAME_SPEC.md`](../GAME_SPEC.md)): decisions in [`docs/DECISIONS.md`](../DECISIONS.md) first, then the submitted GDD ([gdd-checkpoint.md](gdd-checkpoint.md)), then this draft, then the [pitch notes](pitch-notes.md).
>
> **Already superseded:**
> - Ronald is **not** a flat cardboard cutout. He is a low-poly, PS1-style clown inspired by Ronald McDonald (D-007, [`docs/ART.md`](../ART.md)). The decoy-cutout idea (R5) and "only his eyes are white" no longer apply as written.
> - The palette, light and mood below are replaced by the submitted GDD's (`docs/ART.md`).
> - The level is **smaller** than the 30 × 20 m below (D-008).
> - The value names in this draft (`ronald_state`, `goal_pos`, ...) are not the real ones. The real names are in [`docs/BLACKBOARD.md`](../BLACKBOARD.md).
>
> The rules, numbers and ideas that aren't superseded are the **recommended starting answers** in each system's interview (`systems/<system>/SYSTEM.md`).

COMP440 Game Design · Project 3 Checkpoint · Oct 7, 2026 · Rickey

## Concept

A seven-year-old hides in the ball pit during a birthday-party game of hide-and-seek, falls asleep, and wakes up after closing, locked inside a McDonald's PlayPlace. To get home they have to find their shoes and reach the emergency exit while a cardboard Ronald McDonald cutout hunts them through the dark restaurant. It is hide-and-seek where the seeker always wins eventually: every hiding spot is safe, but none is safe for long.

We didn't pick one pitch; each one became a piece of this game.

| Pitch owner | Pitch (familiar thing / monster / scariest moment) | Where it lives in Closing Time |
| --- | --- | --- |
| Lionel | NPC that screams and sprints at you; dark entity with wide human eyes; a whisper behind you in dead silence | Ronald's eyes are the only real, human part of him. "I see you" is whispered from right behind the player's head. Getting caught ends in a silent stare, then a screaming sprint. |
| Rickey | McDonald's PlayPlace; clown/mascot cardboard cutout; the cutout comes alive when you touch it | The setting. Ronald is a flat cardboard standee, and sometimes he stands still among identical decoy cutouts until you get too close. |
| Naomi | Home alone as a kid; a ghost your brain invents; the last monster turns out to be an intruder | The kid's-eye framing, and the ending: the exit alarm turns the lights on, the cutout falls flat, and a real man is standing where it stood. |
| Aiden | Insect bigger than a human; a centipede that blends into the environment | Ronald towers over a kid-height camera, and he hides in plain sight among the decoys. Only his eyes give him away. |

## 1. Core Loop

**Sneak from hiding spot to hiding spot through the closed restaurant to find your shoes, staying hidden while Ronald passes but moving on before you've hidden so long that he finds you.**

One turn of the loop takes 20 to 40 seconds:

1. **Peek** from your spot to find where Ronald is.
2. **Move** toward the next spot, or toward a shoe, while he's moving away. Running is fast but loud.
3. **Hide** before he turns back. Hidden, he walks right past you.
4. **Leave in time.** Stay in one spot for 20 seconds and he whispers "I see you" and comes for it.

Win: find both shoes (each spawns in one of about 8 spots per run), then push the emergency-exit bar. Lose: he catches you, the run restarts, and the shoes reshuffle. A full run is 6 to 10 minutes.

## 2. The Systems

We have four systems, one per team member. Hiding and Senses decide what Ronald can know about the player. Ruleset and Roaming decide what Ronald does about it. Each value has exactly one system that writes it; everyone else only reads it.

| System | Owner | Question it answers | Values only it writes |
| --- | --- | --- | --- |
| Hiding From Enemies | Lionel | Is the player hidden, where, and for how long? | `hide_state`, `hide_spot`, `hide_time`, `in_light`, `player_noise` |
| Enemy Senses | Aiden | What can Ronald see and hear right now? | `detection`, `last_known_pos` |
| Enemy Ruleset | Rickey | What is Ronald allowed to do, and what does he want next? | `ronald_state`, `goal_pos`, `move_speed`, `forbidden_zones` |
| Roaming Enemies | Naomi | Where is Ronald, and how does he get to his goal? | `enemy_position`, `enemy_movement`, `patrol_index`, `goal_reached`, `goal_unreachable` |

### Hiding From Enemies (Lionel)

- **Spots.** Hiding spots are marked volumes with a type: ball pit, tube, under table, booth, restroom stall, under counter. Press interact to climb in (0.5 s, and it makes noise). Hidden, you can't move, only peek.
- **`hide_state`**: EXPOSED (standing or walking), CROUCHED (quieter, still visible), HIDDEN (inside a spot).
- **`hide_time`** counts up per spot and resets only when you enter a *different* spot, so ducking out of a table and back in doesn't reset it.
- **`in_light`** is true while the player stands in a light pool (window light, the drink cooler's glow).
- **`player_noise`** (0 to 1): crouch-walk 0.1, walk 0.3, wading into or out of the ball pit 0.6, bumping a chair 0.8, running 1.0.
- **The ball pit** is the one spot with a cost: submerged, your view shrinks to slits between the balls and sound is muffled. You're safe, but nearly blind.

### Enemy Senses (Aiden)

- **Sight** is a sensing sphere around Ronald: 7 m, or 14 m if `in_light`. Player inside the sphere, in clear line of sight, and not HIDDEN → `detection = SEEN`.
- **Hearing** reaches `player_noise × 10 m`, through walls → `detection = HEARD`, and writes `last_known_pos`. While Ronald is moving (`enemy_movement`), his hearing range is halved: his own cardboard scrape covers you. Move when he moves.
- **Saw you hide.** If he SAW the player within 1.5 s before they became HIDDEN, Senses keeps reporting SEEN. Diving under a table in front of him doesn't work.
- **Hiding is the only authority on "hidden."** Senses never runs its own visibility test on a HIDDEN player.

### Enemy Ruleset (Rickey)

The Ruleset owns Ronald's state machine and his rules, stored as data: one ruleset per mascot, so a second mascot would be new data, not new code. Its seven states are PATROL, POSE, INVESTIGATE, SEEK, CAMP, CHASE and CATCH. These are the rules a player can discover:

| Rule | Trigger | What the player sees and hears | How they learn it |
| --- | --- | --- | --- |
| R1. He never enters the ball pit | Always: the pit is a forbidden zone | He walks the rim and stops at the edge | The game opens with you in the pit, watching his first patrol circle it without stepping in |
| R2. Hide too long and he finds you | `hide_time` passes 20 s in one spot | "I see you," whispered from right behind your head, then he walks straight to your spot | The whisper always comes at least 5 s before he arrives, so a quick player survives the first one and learns from it |
| R3. Seen in the open means a chase | Senses reports SEEN | Two honks of a clown horn, then he runs | The first time you're caught exposed inside his sphere |
| R4. Caught means a stare, then a sprint | He gets within 3 m in a chase, or reaches your spot while you're still in it | Controls lock. He stands still and stares with wide human eyes through 2 s of total silence, then sprints at you screaming | On your first death |
| R5. Some cutouts aren't cutouts | 1 in 4 patrol loops, he stops at a decoy marker and poses for 20 to 40 s | He's flat and still among the decoys; only his eyes are white, and they follow you. Get within 1 m and he wakes (1 s), then chases | The decoys are visible from the pit at the start, so players have already seen what a dead cutout's eyes look like |

**Ronald's state machine (diagram in the Claude Doc, described here).** Ronald escalates left to right; the ball pit is the off-ramp.

- PATROL → POSE: 1 in 4 loops; back to PATROL after 20 to 40 s.
- POSE → CHASE: touched while posing (1 s wake-up).
- PATROL → INVESTIGATE: heard.
- PATROL or INVESTIGATE → CHASE: seen (honk honk).
- PATROL → SEEK: hid 20 s ("I see you").
- SEEK → CAMP: the player is in the pit. CHASE → CAMP: the player dives into the pit.
- CHASE → CATCH: within 3 m. SEEK → CATCH: the player is still in the spot when he arrives.
- Not drawn: every state falls back a step when he loses you. Out of sight for 2 s (CHASE → INVESTIGATE), nothing found (INVESTIGATE → PATROL), spot empty when he arrives (SEEK → INVESTIGATE), camp over (CAMP → PATROL).

### Roaming Enemies (Naomi)

- **Patrol.** Ronald walks a loop of waypoints: dining room, counter, restroom hall, PlayPlace rim. At each waypoint he pauses 1 to 3 s and has a 30% chance to take a side branch, so the loop isn't memorizable.
- **Executes, never decides.** Roaming reads `ronald_state`, `goal_pos` and `move_speed` from the Ruleset and paths there on the navmesh. It never changes his state.
- **Forbidden zones** from the Ruleset are carved out of the navmesh. If a goal is inside one, Roaming walks to the nearest reachable point and reports `goal_unreachable`.
- **Movement.** Cardboard doesn't walk; he slides with a soft scrape across the tile. Turned edge-on, he nearly disappears.

### Starting tuning values

These are first guesses to playtest from, not final numbers.

| Value | Start at | Set by |
| --- | --- | --- |
| Hide limit (R2) | 20 s in one spot | Ruleset |
| Minimum warning after "I see you" | 5 s | Ruleset |
| Sight sphere | 7 m, or 14 m when the player is lit | Senses |
| Hearing range | `player_noise × 10 m`, halved while he moves | Senses |
| Speeds | Patrol 1.4 m/s, seek 2.0 m/s, chase 4.2 m/s (player runs 3.8 m/s) | Ruleset |
| Lose track | 2 s out of sight, then INVESTIGATE | Ruleset |
| Camp at the pit rim | 10 s | Ruleset |
| Catch range and stare | 3 m, 2 s | Ruleset |

## 3. The Seams

Our two named seams are halves of one loop: Hiding → Senses → Ruleset → Roaming → back into Senses. Every arrow is a one-way handoff, and a value only flows away from the system that owns it.

(Diagram in the Claude Doc: Hiding → Senses is Seam 1, carrying `hide_state`, `in_light` and noise. Senses → Ruleset carries `detection` and `last_known_pos`. Ruleset → Roaming is Seam 2, carrying state, goal, speed and no-go zones. Roaming → Ruleset carries `goal_reached` and `goal_unreachable`. Roaming → Senses carries `enemy_position` and `enemy_movement`. Hiding → Ruleset carries `hide_time` for R2.)

Ronald only knows what the arrows carry: if a value never reaches Senses or the Ruleset, he can't react to it.

| Seam | Writer → reader | What crosses, every frame | Rule at the seam |
| --- | --- | --- | --- |
| Seam 1 (named) | Hiding → Senses | `hide_state`, `in_light`, `player_noise`, player position | Senses never overrides HIDDEN, except "saw you hide." Noise is never hidden: wading into the pit next to him is still HEARD. |
| Seam 2 (named) | Ruleset → Roaming | `ronald_state`, `goal_pos`, `move_speed`, `forbidden_zones` | Roaming never changes his state, and the Ruleset never moves him. A goal inside a forbidden zone is never sent. |
| Detection | Senses → Ruleset | `detection`, `last_known_pos` | The Ruleset reacts only when `detection` changes, so the honk plays once per sighting, not every frame. |
| Hide timer | Hiding → Ruleset | `hide_time`, `hide_spot` | Hiding only counts. The 20 s limit belongs to the Ruleset, which fires SEEK once per visit to a spot. |
| Position | Roaming → Senses and Ruleset | `enemy_position`, `enemy_movement`, `goal_reached`, `goal_unreachable` | Senses centers its sphere on him. The Ruleset uses reached or unreachable to pick his next state. |

Our pitch named only Seams 1 and 2. The other three handoffs join them into a loop: without Detection, being seen wouldn't change what Ronald does, and without the Hide timer, R2 has no trigger.

### Seam 1: Hiding → Senses

This seam decides how the player gets found, and there are exactly three ways. Each has its own cue, so the player always knows which rule caught them:

| Found by | Decided by | Cue |
| --- | --- | --- |
| Seen in the open | Sight sphere + `hide_state` | Two honks of a clown horn |
| Heard | `player_noise` vs. hearing range | His scrape stops: he's listening |
| Out-waited | `hide_time` vs. the 20 s limit | "I see you," whispered behind your head |

The risk here is two authorities on "hidden." Under a table, a ray from Ronald's eyes can still hit the player's head, so he'd see someone the Hiding system says is hidden. The contract: Senses trusts `hide_state`.

### Seam 2: Ruleset → Roaming

Each time Ronald's state changes, the Ruleset sends Roaming a new goal and speed. Roaming walks it and answers `goal_reached` or `goal_unreachable`. R1 (no ball pit) is declared in the Ruleset but enforced by Roaming's navmesh. That split is where we expect the first break; see section 6.

## 4. Art Direction

### 4.1 The world

A strip-mall McDonald's PlayPlace an hour after closing: chairs up on the tables, floors mopped but not clean, its 1990s primary colors bleached to chalk by thirty years of sun through the glass and grease from the fryers, and dark because the last shift killed the lights without checking the ball pit.

### 4.2 Palette

| Role | Name | Hex | Where it appears |
| --- | --- | --- | --- |
| Base | Closed | #0B0F1A | Most of every frame: anything outside a light pool |
| Cool mid | Mop Water | #2E4650 | Floor tile, the tubes, ball-pit balls in shadow, exit-sign spill |
| Warm mid | Bleached Mustard | #8E7B52 | Faded yellow plastic, booths, cardboard (Ronald and the decoys) |
| Light | Sodium Lot | #D08A45 | Parking-lot light through the windows, and every faded red it falls on |
| **Accent** | **Eye White** | **#F3EEE2** | **Ronald's eyes. Nothing else.** |

Two rules make the palette a mechanic. First, nothing else in the game comes close to white: no white tile, no white light, no white UI text. If the player sees white in the dark, it's him. Second, there is no true red. Ronald's red has faded into Sodium Lot like everything else, so his body blends in and only his eyes give him away.

### 4.3 Camera and framing

First person at a seven-year-old's eye height: 1.0 m standing, 0.55 m crouched, 0.35 m submerged in the pit, in a building built for adults.

- Tabletops are at chin height, the front counter is above eye level, and the exit's push bar is at your shoulder.
- Ronald's cutout is 1.9 m tall. Up close, his face is out of frame until you tilt the camera up about 30 degrees.
- A slightly narrow field of view (about 80 degrees horizontal) keeps the room's edges and anything behind you out of frame.
- No HUD. To check which shoes you've found, look down at your feet: socks or shoes.

### 4.4 Light

- **Direction:** the key light comes from outside. Sodium-vapor parking-lot poles shine through the PlayPlace's west windows, low and raking, laying long window-frame shadows across the floor and up the tubes.
- **Hardness:** hard. Distant point sources give crisp-edged pools, and those edges are the same lines the Hiding system's `in_light` volumes trace.
- **Temperature:** warm outside (sodium orange, about 2000 K), cold inside. The only interior sources are two green-white exit signs and the drink cooler's flicker. The warm light is the outside world: you can see home's color but can't reach it.
- **Fill:** none. Shadows fall all the way to Closed (#0B0F1A). Lit versus unlit is a gameplay fact, so a pool's edge must always read.

### 4.5 Edge and detail

- **Edges are lost in the dark.** Objects outside a light pool have no outline and dissolve into Closed. Only edges the sodium light hits get a hard, bright rim, and silhouettes only read against the lit windows.
- **Ronald has no edge at all.** He's 3 mm of cardboard: turned sideways he's a line, and he never catches a rim light. His only depth is his eyes, which are wet, specular and moving.
- **Detail lives below the tabletop line (0 to 1.1 m).** Gum under the tables, crayon on the tube walls, a lost sock in the pit, sticky drink rings. Above the kid's eye line the adult world is flat and blank: smooth panels and signs too high and dark to read.

### 4.6 Mood

**Uncounted. Sticky. Ready-or-not.**

- **Uncounted:** nobody did a headcount. You weren't lost; you were left.
- **Sticky:** everything a kid touches is grimy: syrup, gum, damp plastic balls.
- **Ready-or-not:** the seeker's warning in hide-and-seek. He's coming whether you're ready or not.

## 5. Scope

We're building one restaurant, one monster and one 6-to-10-minute run, with enough systemic variation (shoe spawns, patrol branches, posing) that a second run plays differently.

### What is in

| Area | In scope |
| --- | --- |
| Level | One restaurant, about 30 × 20 m: PlayPlace (ball pit, two-level tubes, slide, shoe cubbies), dining room, front counter and kitchen, restroom hall, side emergency exit |
| Monster | Ronald only: 7 states, rules R1 to R5, plus 3 decoy cutouts (same flat mesh, printed eyes) |
| Hiding spots | 6 types: ball pit, tube, under table, booth, restroom stall, under counter |
| Objective | 2 shoes, each spawning in one of about 8 marked spots per run, then the emergency exit |
| Audio | "I see you" whisper, double honk, cardboard scrape, ice-machine hum and cooler buzz (the silence floor), exit alarm, catch scream |
| Story | A 30 s opening (birthday hide-and-seek, fade out, wake up in the pit) and the ending stinger (alarm, lights on, the cutout falls flat, a man standing where it stood) |
| Failure | Full restart on catch; shoes reshuffle |

### Three cuts

1. **The Fear / Imagination system (it would be our fifth system).** A meter that rises the longer you're in the dark and warps the world: more cutouts come alive, hallways stretch, Ronald speeds up. Cut because it would write into every other system (Senses range, Roaming speed, Ruleset thresholds, the art) and no one owns it. The kid's imagination lives in the art direction and the ending instead.
2. **More roaming mascots.** The other mascots appear only as set dressing: wall murals, the bench statue, menu art. The Ruleset stays data-driven, so a second mascot later is new data, not new code.
3. **Fighting back.** No throwing, hitting or distracting. Naomi's "hit the last monster and it turns into an intruder" survives as the non-interactive ending, not a combat mechanic.

**Next cut if we fall behind:** R5 and the POSE state. The decoy cutouts stay as props, and Ronald just patrols.

## 6. Which Seam Breaks First

**Seam 2 (Ruleset → Roaming) breaks first, at the rim of the ball pit, within the first minute of the first playtest.**

The ball pit is where two of Ronald's rules collide. R1 says he never enters the pit; R2 says that if you hide too long, he comes to your spot. Both rules live in the Ruleset, but R1 is enforced by Roaming's navmesh and R2 is triggered by Hiding's timer, so nobody owns the moment they meet. It's also the first thing every player will do: the game starts in the pit, and it's the most obvious hiding spot. Twenty seconds in, the Ruleset fires SEEK with a goal Roaming isn't allowed to reach.

### What we expect to see

| Symptom | Cause |
| --- | --- |
| Ronald walks into the pit | The goal isn't clamped, or the pit isn't carved out of the navmesh |
| Ronald freezes or jitters at the rim forever | Roaming can't reach the goal and nothing handles `goal_unreachable` |
| "I see you" plays again every frame | SEEK keeps re-firing because nothing marks it as already fired for this visit |
| Players wait in the pit forever | CAMP never ends, so the pit becomes a permanent safe room |

### The fix we're writing into the contract now

1. The Ruleset never sends a goal inside a forbidden zone. It asks Roaming for the nearest reachable point first.
2. When Roaming has to clamp a goal, it reports `goal_unreachable`, and the Ruleset switches SEEK to CAMP: Ronald stands at the rim facing the player for 10 s, then goes back to PATROL.
3. SEEK fires once per visit to a spot. The Ruleset remembers the visit; it never writes Hiding's timer.
4. No shoe ever spawns in or next to the pit, so waiting there never wins.

### How we'll catch it early

Before any art goes in, we build a graybox "pit test" scene with the pit, one table and one Ronald, and run these checks after every change to either system:

- [ ] Hide in the pit for 20 s: the whisper plays once, Ronald walks to the rim and stops.
- [ ] Stay in: he camps for 10 s, then patrols. No second whisper until you leave and come back.
- [ ] Get chased, then dive into the pit: the chase ends at the rim (CAMP).
- [ ] Climb out on the far side in his sight: CHASE. Out of his sight: he finishes camping.

**Runner-up: Seam 1, two authorities on "hidden."** If Senses runs its own line-of-sight check, a player under a table gets seen because the ray hits their head. We'll test it in the same scene with the table.
