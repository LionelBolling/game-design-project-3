# Lionel's hiding and F5 horror changes

Updated 2026-10-15. This records the final behavior of the complete local change since `c04d496` and the requested revisions that led to it. Exact tuning and interview answers are in [SYSTEM.md](SYSTEM.md); implementation and validation history is in [PLAN.md](PLAN.md). Audio sources and regeneration are in [AUDIO.md](AUDIO.md).

Review: [PR #5](https://github.com/rickeyjohnson/game-design-project-3/pull/5), from `LionelBolling:hiding/01-hide-timer` into the team's `main`. Gameplay commit: `f11e916`. Author identity supplied by Lionel. PR creation was explicitly requested; the PR is open, not merged, and no web export was generated.

## Hiding and table coverage

- Added reusable `HideTimer`, `HideSpot`, `HidingSystem`, spot scene and hiding HUD, plus a local integration scene built against the published teammate stubs.
- E starts a 0.5-second entry; E leaves. Hiding locks translation while retaining flashlight use and horizontal mouse look. Leaving returns to the original approach position.
- The shared hide budget is seven seconds, carried between spots. Empty-to-full recovery takes fourteen seconds outside hiding. The HUD shows remaining time and a location-revealed warning.
- Main F5 uses the existing player, camera, flashlight, enemy and level. A hiding Director publishes the existing hiding board values; other slots are idle so duplicate stub actors do not spawn. Game phase and pause gate ticking.
- Ball-pit and elevated-tube hiding are disabled. Their scenery and reusable enum types remain; the current map uses tables and cover behind solid counters.
- All seven standalone dining tables and five booth tables now offer hiding. Three kitchen prep counters provide additional cover behind their bases, for fifteen total spots.
- Dining interaction volumes are 4 x 1.8 x 4 m, booths 4.8 x 1.8 x 4 m, prep cover 5 x 1.8 x 2 m. Overlap chooses the closest usable spot. A standing-height collision ray rejects interaction through walls/cabinets without letting a table pedestal reject its opposite side.
- Gold, depth-tested E / HIDE markers identify the furniture within eight metres. They disappear within 1.5 m, during hiding, menus, pause and the timeout camera lock. The regular E prompt names the nearby furniture.
- Dining hiding feet are offset +0.57 m in Z from the pedestal; eyes are at world height 0.5 m. Booth feet use X +0.25 / Z -0.57 and face the dining aisle. Prep cover uses Z +1.35 from the cabinet and faces the kitchen aisle. Cameras stay level with free horizontal look, outside furniture, with a small hiding-only fill light. Markers do not add dynamic lights.

## Ronald and the flashlight

- Restored the original imported Ronald animation; the generated running animation was removed from active behavior. Positional floor taps follow actual movement and stop with him.
- Battery drain is 1.68 percent per second. An unpowered/empty torch cannot affect Ronald.
- Normal movement outside the beam is 3.3 m/s. An exposed beam freezes him until the continuous-light attack triggers; hidden/entering players cannot freeze or provoke him with their flashlight.
- After a hide timeout, Ronald investigates the leaked area instead of stopping when sight is lost. Investigation persists for five seconds.
- Under-table catch reach is two metres after a leak, with a clear low collision ray; normal catch reach remains 0.85 m. Unleaked hiding protects the player.
- The hiding approach is chosen from four nearby sides with a clear low reach ray and reachable navigation endpoint, then cached for that hiding position. The target uses the actual grid endpoint within grab range, so narrow-aisle projection cannot leave Ronald short of the arrival tolerance. This replaces the fixed +Z assumption so booth pedestals and the divider do not prevent investigation/catch. No new blackboard values are needed.

## Timeout presentation

- A leak cuts to the actual spawned Ronald, turns him over 0.65 s and plays the original I see you once at pitch 0.76.
- After the line finishes, show the first 0.5 s of his run, then restore the player camera, controls and E/R interaction. Player look/movement thereafter are preserved.
- Ronald continues at 6.6 m/s to the captured spotted area, rather than tracking the player's new position or stopping after a fixed short duration. Arrival tolerance is 0.6 m horizontally.
- The approach sprint suppresses catches; normal animation rate/speed and catch behavior return on arrival, with a brief reaction grace. Pause/finish cancellation restores the view, controls, flags and audio.

## Catch and flashlight-overuse attacks

- Catch uses a 3D leap of the existing live actor toward a separate camera, not the random warning GUI. A 0.55 s arc brings his head to 0.34 m from the lens, followed by a 0.75 s hold and the normal death screen. Scream fires once per catch.
- Six uninterrupted seconds of exposed flashlight on Ronald's face trigger a leap and loud scream, followed by a pin/struggle camera. Breaking the beam or hiding resets exposure.
- Twelve distinct Space presses within four seconds push him off. Holding Space or keyboard repeats do not count. Pause freezes the timer and hides the struggle prompt.
- Success plays a 0.7 s shove, restores the source camera, hand visibility, controls and original actor pose/rate, resets light attack state and grants three seconds to escape.
- Success also turns the flashlight back on if charge remains and clears its toggle cooldown. It does not refill the battery; F can turn it off/on normally and R is needed for an empty battery.
- Failure plays a one-second closing-jaw bite with crunch before death. Temporary cameras/audio/UI are cleaned up on finish/cancel.

## Warning flashes, chase static and black figure

- After Ronald is active/visible, each thirteen eligible seconds gives one 50% chance of a 0.28 s face/static flash saying `you better run`, with a scream. Failed rolls also reset the interval. There are no warning portraits during catch or on apparition observation.
- Reduced Motion suppresses random face flashes and holds chase grain steady. Chase shows readable translucent interference and quiet static, stopping when the chase ends.
- A horizontal turn of at least 150 degrees has a 35% chance to spawn the black bloody-smile figure behind the original heading. A three-second cooldown prevents jitter rerolls. Waiting alone cannot spawn it.
- Placement requires clear floor, body space and sight; no new figure spawns while hiding/chased or while one already exists. Menus/cinematic camera changes reset turn tracking.
- The figure matches the player's 1.12 m height. It stays until seen, follows translation while unseen without dodging a turn, then lunges toward the live camera over 0.55 s and disappears. It never takes control, damages the player or becomes another enemy.
- Each successful appearance plays Ronald's current jumpscare scream once at the same level. Failed/blocked spawn attempts and later observation do not replay it.

## Battery GUI and audio

- The existing top-right flashlight panel includes `R / Reload Batteries(amount/maxamount)`, with live spare count. The denominator is all obtainable spares: two starting plus two pickups = four. No carry cap or pickup balance change was introduced.
- The detached bottom reload hint was superseded by this integrated row. Existing R reload behavior consumes one spare, restores charge and turns on the light.
- Added original chase loop, footsteps, static, crunch and scream assets and reproducible local generation scripts. `terror_scream.wav` is the current louder layered shriek: catch/pounce/figure at 0 dB, random flash at -2 dB. Peak sample headroom remains in the asset.
- The original locally synthesized I see you is in use. The requested whisper experiment remains as an unused reproducible alternative. Human listening is needed to judge mix/scare quality.

## Requested revisions that were superseded

1. Started with the approved four reusable hiding types; later restricted main F5 to tables and disabled ball-pit hiding.
2. Fixed black table views by moving the camera away from the pedestal, adding fill and retaining level horizontal look.
3. Added a generated run animation, then restored the original animation on request; sounds and movement tuning remained.
4. Added timeout catching, then expanded the voice/turn/run presentation. The initial 0.75 s sprint became an arrival-based run. A fully locked approach became early control return, finally refined to show 0.5 s of running first.
5. Replaced a GUI catch face with the actual actor's leap. Random text changed from you better hide to you better run and became eligible only after spawn.
6. Removed unseen figure expiry and its observation-triggered GUI flash. Replaced timer spawning with 35% per turnaround, reduced the figure to player height and added a live-camera lunge plus Ronald's spawn scream.
7. Random warning spacing changed from 18–35 s to 45–80 s, then to the current 50% chance each thirteen seconds.
8. Continuous-light attack threshold increased from four to six seconds. Grapple escape initially knocked the light off; it now restores a charged light and usable toggling.
9. The whispered voice replacement was reverted to the original line. Reload text moved from a separate control label into the battery panel with counts.
10. Expanded seven dining zones to all twelve dining/booth tables plus three prep covers, with per-furniture camera framing, reach checks and visible markers.

## Teammate impact and review boundaries

| Area | Effect |
|---|---|
| `systems/hiding/`, `tests/hiding/` | Lionel's implementation, generated assets, tests and preview tools. |
| `scripts/game.gd` | Explicitly requested legacy F5 composition, spot registration, item/pause/input gating, new caught/grapple phases and callbacks. Overlaps legacy win/lose and integration responsibilities. |
| `scripts/player.gd` | Hiding movement lock/level look, hidden-beam immunity and battery drain. |
| `scripts/stalker.gd` | Explicitly requested legacy speed, beam exposure, investigation/approach/catch rules, original animation and footsteps. Overlaps legacy enemy senses/rules/movement responsibilities. |
| `scripts/hud.gd` | Battery panel reload/count row. |
| `docs/PROGRESS.md` | Lionel's section only; historical decisions already record earlier authorized integration requests. |
| Shared/teammate systems | No edits to `systems/core/`, `systems/ruleset/`, `systems/roaming/`, `systems/senses/`, blackboard contract, project/export settings or original assets. |

The integration still uses the legacy game as its composition root. Its existing direct references are not a replacement for the four-system blackboard design. Teammates should review the legacy overlap before replacing their stubs. An unused earlier world tube-metadata hook was removed; no level-code change is needed in the final diff. Pre-existing import/editor metadata and project-setting dirt are excluded from the PR. No web export is included.

## Verification and remaining human checks

- Full headless GUT: 77/77 tests across all 18 test scripts, no skipped/parse/script-error files. Check all `tests/**/test_*.gd` files were counted, not only the green summary.
- Coverage test enters/exits all fifteen spots, checks level eyes outside collision, a clear initial view and a reachable low grab side, and tests both sides of standalone tables.
- Graphical contact sheets review all fifteen approaches and hiding cameras; booth views were corrected to face the aisle after the first review. Sheets are under ignored `reviews/hiding-approaches.png` and `hiding-camera-views.png`.
- Live first-fuse spawn preview verifies real timeout, 0.5 s running view, E exit and actual movement while Ronald continues to the fixed area. Normal table catch/leap/death also verified.
- Live six-second beam preview verifies real trigger, real Space win, pause, movement away, flashlight restoration and off/on input, plus no-input bite/death.
- Graphical scare preview verifies turn reveal/lunge/control preservation/vanish, warning/static/catch paths and actual reload count update from 2/4 to 1/4.
- Initial parse/fixture/preview issues were fixed before final checks: raycast world lookup, fake player property, float precision assertions, image format conversion, booth orientation, grid-projected arrival target, and overlapping game-window focus pauses. Live spawn QA ignores window-focus pause notifications and keeps mouse aim visible; production focus-to-pause behavior is unchanged.
- The imported diner still reports its existing null-material renderer diagnostics (one headless, four graphical). Those are tracked separately from script/test failures.
- Human F5 check: approach marked tables/booths/counters; hide and pan horizontally; check view without the flashlight; leave with E; test timeout pursuit and escape; hold exposed beam six seconds and mash Space; listen to audio balance. Play the local hiding scene separately for stub integration.
- GitHub Pages/web export remains unchanged until the feature is reviewed/merged and a separate export PR is approved.
