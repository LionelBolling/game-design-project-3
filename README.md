# game-design-project-3

https://rickeyjohnson.github.io/game-design-project-3/

## Ronald's

A playable first-person horror game for **Godot 4.3 or newer** (tested with 4.7.2). Wake up in the ball pit of an abandoned birthday diner, restore its emergency power, and follow the pit into a deeper tube maze.

### Play

Import `project.godot` in Godot, let the GLB/audio assets import, then press **F5**. The home screen shows Ronald's diner front; choose **Play** to begin the ball pit opening. Space or Enter skips the opening. **Options** includes a **Skip to Act 1.5** button for testing the deep pit directly.

The rebuilt map uses the new Blender diner: a large play place, dining booths, kitchen, cold storage, and a back hall leading to the restrooms. Charcoal and cream dominate the rooms, with red and gold accents, dust particles, and dim overhead fixtures. Walk out through the gap in the ball pit rim. Collect three emergency fuses from a booth, the kitchen, and cold storage, then restore the breaker. The ball pit remains solid until then. After power returns, follow the blinking lights back to the pit to sink into Act 1.5. After the first fuse, the animated clown roams the map and chases you around obstacles when you get close. Keep it in the flashlight beam to stop it.

Act 1.5 keeps the first pit's 31 by 14.5 metre footprint and extends it 56 metres downward, or fifty player heights. Its batched balls shift and settle as the player moves through them. Control returns after a first-person sinking sequence, and the player stays at that depth until they swim. Steer toward the green tube on the lower left. Its light starts dim and brightens whenever swimming above the top returns you to the bottom, or descending below the bottom returns you to the top. At the tube, a shark tries to bite through the opening, retreats upward, and a leviathan breaches 1.5 seconds later. A ball flies into the tube and knocks the player into Act 2. Both transitions remain in the first-person game view with no loading overlay. In Act 2, the elevated maze follows the [supplied top-down tube layout](<Reference photos/tube maze top down layout.png>). Use **E** at the entrance climb to enter the tubes. The keys and levers are inside the connected tube network at their marked locations. Find the red, blue, yellow, and green keys to unlock their matching doors, and pull each colored lever to light its door and central indicator. Find the black key and use it on the lock in the circle room to activate the fifth circuit. All five circuits open the final door.

| Control | Action |
|---|---|
| WASD / Mouse | Walk / look |
| Shift / Space | Run / jump |
| Space / Ctrl in Act 1.5 | Swim up / swim down |
| **F** | Toggle flashlight |
| **R** | Replace battery using a spare cell |
| E | Pick up / operate / open |
| Esc | Pause; the menu has Resume, Options, and Exit game |
| F11 | Fullscreen |
| F1 | Performance overlay |
| F3 | Switch standard / low graphics |

Four charge lights are mounted on the visible flashlight, and a five-node HUD indicator shows the remaining battery; both change color as charge runs low. The flashlight beam has a 16 m range, and its charge drains only while it is on; a full cell lasts about two minutes. You begin with two spares and can collect more from a dining table and the restroom side vanity. The building lights start off and come on when the breaker is restored. The Options screen, accessible from home or the pause menu, has volume, mouse sensitivity, reduced camera motion, and low graphics. Progress resets on restart and returns to the home screen.

### Models and animation

- `Blender models/ronalds.glb`: the diner shell, bathroom, freezer fittings, and play structure.
- `Blender models/appliances.glb`: the placed booths, dining tables, chairs, prep counters, grill, fryers, drink machines, refrigerators, and ice machine. The freezer door frame fits the cold-storage entrance.
- `Blender models/PLay place.glb`: supplies the Blender ball mesh used throughout the playable pit. The main map already includes the play structure, so the standalone room is not overlaid on it.
- `Blender models/tube maze.glb`: the tube routes, 22 marked end caps, four colored doors and keys, levers, central circle lock, and final door. `scripts/maze_paths.json` records the model's tube section paths; the game joins their floors and walls into one traversable network while keeping the marked caps and puzzle props. Static detail becomes 90 draw groups.
- `scripts/world.gd`: map assembly and named gameplay landmarks. The kitchen wall has a service opening; the freezer is moved out of the overlapping bathroom to the right of the kitchen. Export helper volumes and original furniture are omitted. The play-place perimeter and red enclosure use see-through glass, appliance pieces get collision and navigation clearance, the bathroom has an open entrance and stalls, and the upper play modules have supporting floors and a climbable entry. The original GLBs are preserved.
- `Blender models/ps1-clown.glb`: the supplied rigged clown model and looping animation used by the roaming enemy.
- `scripts/player.gd`: editable `AnimationPlayer` tracks for waking, sitting/standing, drawing the flashlight from the pocket, and switching it. The two later loading screens animate a player silhouette in the HUD.
- `audio/background soundtrack/` and `audio/nightmare_loop.wav`: the supplied looping music and quieter, looping nightmare ambience. Remaining pickup, power, and sting effects can be regenerated with `python tools/generate_audio.py` (Python standard library only).

### Furniture and appliance layout

The [supplied final floor plan](<Reference photos/Final top down layout.png>) sets the room order: play place to the north, tables in the middle, kitchen to the south, bathroom at the left, and freezer to the kitchen's right. The [earlier floor plan](<Reference photos/First top down layout.png>) and [play-place photo](<Reference photos/Upper play place area.png>) provide additional context. Public [dining-room photos](https://www.flickr.com/photos/ryanrules/albums/72177720307101321/), a [drink-station photo](https://www.mortarr.com/photo/view/images/project_gallery_images/fast-food-restaurant-drink-station-mcdonalds-tamlyn/52612), and a [kitchen equipment photo](https://vistex.ru/blog/makdonalds/) informed the grouping of furniture and machines. The result is a playable interpretation of the supplied plan.

| Area | Models and placement |
|---|---|
| Dining room | Seven tables with fourteen chairs beside the play place; five booths in a row beside a half-wall divider; an order counter at the kitchen service wall, with a beverage system and post-mix soda fountain near its right end. |
| Kitchen | Two clamshell grills, two deep fryers, the fry station, and a combi oven along the rear cooking line. Three assembly tables, two UHC cabinets, a microwave, coffee urns, a post-mix soda fountain, and a soft-serve machine occupy the prep and service side. |
| Freezer | Two reach-in refrigerators against the rear wall and an ice machine against the side wall, leaving an aisle to the fuse crate. It opens from the right side of the kitchen. |

The placements are editable in `scripts/world.gd` under `_import_appliances()`. Collision and enemy navigation are built from the placed models.

### Performance

The Compatibility renderer keeps the project usable without Vulkan. The diner and placed appliance kit contribute **1,558 source mesh instances**; selected geometry is combined by material and 8 m spatial cell into **200 static batches**. The Act 1 balls use one MultiMesh with shared Blender geometry and individual colors. Act 1.5 adds one batched moving layer and one wall layer; nearby balls shift and settle as the player passes through. The maze's 633 source meshes become 90 static detail batches plus three connected tube surfaces. Only the active act remains loaded. Collisions use boxes fitted to furniture and triangle meshes for climbing ramps and tube interiors. Navigation covers the diner with clearance around obstacles. Only the flashlight casts dynamic shadows; other lights are unshadowed. Interaction checks run at 10 Hz and enemy pathfinding at 2 Hz. The camera clips at 85 m. Low graphics disables flashlight shadows and renders 3D at 75% resolution while keeping the HUD sharp.

Use F1 while playing to inspect performance on your machine. The visual check records a frame sample, but it is not a hardware performance guarantee.

### Web export

Export the playable Web build to `docs/` with `godot --headless --path . --export-release Web docs/index.html`. The preset excludes reference photos, build output, tests, reviews, the GUT addon, and unused audio. Keep `docs/index.pck` below 100,000,000 bytes; this build is **15,413,676 bytes**. The packaged data includes the supplied soundtrack, nightmare ambience, and maze model.

### Checks

With `godot` on PATH:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --fixed-fps 60 --script tests/smoke.gd
godot --headless --path . --script tests/acts.gd
godot --headless --path . --script tests/maze_audit.gd
godot --headless --path . --script tests/maze_traverse.gd
godot --path . --script tests/visual.gd
```

The smoke test exercises the Act 1 opening, battery controls, pause, jumping, ball movement, upper play area, physical routes to pickups, the kitchen breaker, the sealed west exit, clown behavior, and restart. The act test checks both loading transitions, depth wrap, tube collision, all keys, levers, lights, doors, and final completion. The maze audit checks one connected floor, and the traverse test moves a player-sized capsule from the entrance to every puzzle location while checking locked doors and the 22 marked end caps. The visual check saves Act 1 and Act 2 captures under `reviews/`. These generated review files are ignored by Git. No save system is included.

## Team

| # | Name |
|---|------|
| 1 | Rickey |
| 2 | Lionel |
| 3 | Aiden  |
| 4 | Naomi  |
