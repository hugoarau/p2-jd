# Corner Cafe & Bookshop (free)
A free 16x16 top-down interior tileset: a cosy cafe and bookshop. 120 sprites, 3 short animations, one 32-colour-family palette.

## What is inside
- `tileset_1x1.png` + `corner_cafe_tiles.tsx`: every 1x1 tile on a 16-column grid (floors, 9-slice rug, walls, side/bottom walls and corners, counters, chairs, props). Tiled tile ids follow registration order and stay stable across updates; new tiles are appended.
- `objects.png` + `atlas.json`: every multi-tile object (windows, doors, bookshelves, sofas, tables, stove) with pixel rectangles. `corner_cafe_objects.tsx` is a Tiled image-collection tileset pointing at `sprites/`.
- `sprites/`: every sprite as its own PNG. Colourways: chairs in teal/red/mustard/blue, sofas in red/teal/plum, armchairs in mustard/plum/teal.
- `anim/`: `mug_steam_4f.png`, `neon_open_4f.png`, `door_swing_2f.png` (horizontal strips, frame size = sprite size).
- `scene.png` (352x224 at 1x) and `preview_scene_x4.png`: a sample room built only from this pack.

## Using it
- Tiled: add both `.tsx` files as tilesets. Overlay tiles (`floor_wall_shadow`, `shade_edge_*`, `wall_side_*`, `wall_bottom`, `wall_corner_*`) are alpha overlays: put them on their own layer above the floor.
- Godot 4 / Unity / GameMaker: use `tileset_1x1.png` as a 16x16 grid; use nearest-neighbour filtering and no mipmaps.
- Draw order for the sample scene: floor, rug, back wall, objects with a 1px soft shadow, then props.

## Not included
No characters or NPCs, no collision shapes, no terrain/autotile data. Walls and the rug have corner and edge pieces you place by hand.

Made with procedural generation code written with AI assistance; all art is drawn by that code.
More: https://hopefulsham.itch.io
