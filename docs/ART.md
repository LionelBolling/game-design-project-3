# Art direction

The submitted GDD's art direction is canonical (palette, camera, light, edge and detail, mood). Ronald's look comes from the team's reference image (D-007), and the map from the smaller-map decision (D-008). The Closing Time draft's art section is superseded; its ideas are listed only where they're useful proposals.

## World

**GDD:** "A regular McDonald's that has a play place ball pit in a normal world."

The restaurant is McRonald's, a McDonald's stand-in: red and yellow branding, a PlayPlace with a ball pit, tubes and a slide, booths, an order counter and a kitchen. It's after closing, dark and dirty, seen through a scared kid's imagination.

## Ronald

**Decided (D-007):** a low-poly, **PS1-era horror** take on Ronald McDonald, based on the reference image Rickey shared on 2026-10-09:

- Yellow jumpsuit with a red center stripe and red pocket trims
- Red-and-white striped sleeves, white collar
- Curly red hair, white face paint, a wide red smile, yellow gloves
- Low-poly body, low-resolution textures, flat shading; he reads as a silhouette in the dark
- He's an adult-sized figure towering over a child-height camera (GDD: everything looks larger)
- The reference shows him holding a bloody cleaver in a dark, foggy, slightly pixelated scene. Whether he carries it is open (GAME_SPEC Q6).

> **To do (Rickey):** save the reference image as `Reference photos/ronald-reference.png` so every agent can see it. Images pasted into chat don't reach the repo.

The model doesn't exist yet. The mock's creature is primitive shapes, and `Blender models/ronalds.glb` is the **diner**, not the character. Naomi owns Ronald's body (`systems/roaming/SYSTEM.md`); who models him is in her interview.

## Palette (GDD, by Lionel)

| Hex | Swatch description | Proposed role (Lionel confirms) |
|---|---|---|
| `#242522` | Near-black olive | Base: shadows and most of each frame |
| `#731F24` | Dark ketchup red | McRonald's red: booths, signage, Ronald's stripes in the dark |
| `#B39839` | Old mustard gold | McRonald's yellow: arches, trim, Ronald's suit in the dark |
| `#C9C1A5` | Dusty bone | Light surfaces: tile, counters, Ronald's face paint |
| `#91CBA5` | Pale mint green | **Accent, in almost nothing.** Proposal: the exit sign (the way out) |

The GDD names five colors and says one is the accent, but not which. The roles above are a proposal for Lionel's interview.

## Camera and framing (GDD, by Lionel)

"The angle will be viewed from a first-person perspective. Everything will appear larger than the character due to being the size of a child. Tight framing inside the play tubes and ball pit limits visibility, while views beneath tables let the player watch roaming mascots from hiding spots."

Closing Time numbers, as proposals for Lionel: eye height 1.0 m standing, 0.55 m crouched, 0.35 m submerged in the ball pit; about 80° horizontal field of view; no HUD.

## Light (GDD, by Aiden)

"Dark and cold, with bright white or orange lights towards or on the ceiling to lighten areas that aren't dark. A mixture of both hard and soft lighting and no filling in of shadows."

## Edge and detail (GDD, by Naomi)

"The player character is the central subject, with the small amount of lighting coalescing in front of them. The rest of the environment is warped and stretched in the darkness, making the subject (and the viewer, by extension) feel small and confused. Detail exists right in front, but rapidly fades further out, leaving monsters and furniture alike as vague silhouettes, their vagueness utilizing the full extent of the viewer's imagination."

This pairs naturally with the PS1 reference: low-resolution rendering and distance fog make far-off things vague by default (GAME_SPEC Q5).

## Mood (GDD, by Aiden)

**Grim. Anxiety. Hysteria.**

## The map (D-008)

Smaller than the mock's map, and more clearly a McDonald's with a PlayPlace. It follows the room order of Aiden's [final floor plan](<../Reference photos/Final top down layout.png>), scaled down: PlayPlace and ball pit to the north, dining in the middle, the order counter and a small kitchen to the south, the bathroom in the south-west corner, and the entrance on the west wall. The walk-in freezer and back hall are proposed cuts. The [PlayPlace photo](<../Reference photos/Upper play place area.png>) sets the look of the tubes and slide. See `GAME_SPEC.md` §2. The level belongs to Aiden (`systems/senses/SYSTEM.md`).

## Assets on hand

| Path | What it is |
|---|---|
| `Blender models/ronalds.glb` | The diner: shell, bathroom, freezer fittings, play structure |
| `Blender models/appliances.glb` | Booths, tables, chairs, counters, grill, fryers, drink machines, fridges, ice machine |
| `Blender models/PLay place.glb` | The ball mesh used for the ball pit |
| `audio/*.wav` | Generated effects (breath, step, land, click, pickup, power, sting, room). Regenerate with `tools/generate_audio.py`. |
| `audio/background soundtrack/` | Looping background track (MP3) |
| `Reference photos/` | Floor plans and the PlayPlace photo |

The mock's README has the details of how these were placed and batched (`scripts/world.gd`).

## Web performance budget

From the mock's README and Aiden's export rules:
- Compatibility renderer. Few dynamic lights, and only one shadow-casting light.
- Batch static meshes. Draw the ball pit as one MultiMesh, not thousands of nodes or physics bodies.
- Simple box collision where possible.
- Keep `docs/index.pck` under 100 MB. The current export is about 9.3 MB.
