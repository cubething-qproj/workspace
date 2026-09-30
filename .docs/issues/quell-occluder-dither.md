# feat: dither geometry between the camera and the player

Repo: `cubething-qproj/quell` · Labels: `enhancement` · Depends on: #35 · Filed: #36

## Problem

With a fixed-distance third-person camera, walls and other geometry can come between the camera and the player, or clip the camera's near plane. The player needs to stay visible without the camera moving.

## Direction

- Fade occluding geometry with an ordered (Bayer) screen-door dither in the fragment shader: discard pixels below a threshold instead of alpha blending. This avoids transparency sorting and keeps depth and shadows intact.
- The dither applies to fragments that are closer to the camera than the player and fall within a screen-space radius around the player. Where it's strongest (radius, falloff, minimum opacity) is tweakable through a `Resource`.
- Open questions:
  - Level geometry uses plain `StandardMaterial` (Jackdaw brushes, glTF). The dither needs either an `ExtendedMaterial<StandardMaterial, _>` swapped in when the level spawns, or a global shader hook. Pick the approach that doesn't require authoring a special material in the editor.
  - Whether the player model itself should dither when the camera gets very close.

## Acceptance

- In the greybox stage, the player stays visible behind walls, ramps and the V-corner, with no camera movement.
- Geometry that isn't between the camera and the player renders normally.
- Shadows and depth-based effects are unaffected.
