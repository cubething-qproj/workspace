# Quell world generation: from hex editor to playable levels

Status: **draft, 2026-10-16. For review.**

Follows the hex terrain work (`quell-hex-terrain-design.md`) and the async
generation issue (`.docs/issues/quell-worldgen-0-async.md`). The
`hex_paths` screen becomes the level **editor**; `WorldScreen` becomes the
place where levels are **played**. The greybox scene stays with its own
screen for controller work.

## Terms

- **Preset**: the generation inputs authored in the editor, which are the
  existing `HexPathsSettings` and `HexTerrainTuning` RON assets. A preset is
  everything except the seed.
- **Level**: one terrain exploration loop. A preset plus a fresh seed. A
  playthrough runs several levels in sequence.
- **Skeleton**: a level's coarse, whole-level generation output: the eroded
  `Region`, the chosen window (`Terrain`), and the `Layout` (trail graph,
  nodes, pads, levelled heights). It is today's `Board` without presentation.
- **Chunk**: a fixed square of the playable world. Its detail is generated
  on demand from the skeleton.
- **Detail**: everything derived per chunk: the fine ground mesh, path
  carving and texturing, vegetation, node props, and colliders. It exists at
  several LODs.

## Idea

Erosion is global (`Region::simulate` evolves the whole region at once), so
the skeleton cannot be chunked. Everything finer than the skeleton can be
chunked. The pipeline has two stages:

1. **Skeleton, once per level, async.** This is existing code, unchanged in
   behaviour. Loading a level waits for it.
2. **Detail, per chunk, async, on demand.** This is a deterministic function of
   `(skeleton, seed, chunk coordinate, LOD)`. Chunks near the player
   stream in and out; LODs swap with distance.

Since detail is a pure function of the skeleton and seed, the world never
needs to be stored. A save holds the inputs and the player's state, and
loading regenerates everything else.

**Layout regeneration is a game mechanic.** "Regenerate here" and Fear
(`Layout::regenerate`) rewrite the layout around the player during a level.
The terrain is fixed per level, but the layout is not. So:

- The skeleton is the region and window (fixed) plus the current layout
  (mutable). A regeneration replaces the layout, as `relayout` does in the
  editor.
- Detail that depends on the layout (path carving, the path splat, node props,
  and vegetation exclusion around paths and pads) is invalidated for every chunk
  whose trails or pads changed. Those chunks regenerate. The pinned radius
  around the player is unchanged, so the visible change happens outside it.
  Ground and vegetation that don't depend on the layout survive.
- Saves record the regeneration history (see Saves).

## Editor → play

- The editor's Save button already writes the preset. The preset is the
  editor's only output; there is no separate export.
- Starting a level picks a preset and draws a seed. The editor's seed field
  is for inspection and reproducing bugs; play ignores it.
- The editor can launch the world screen with its current preset and seed
  ("play this level") for testing. It is a dev-only convenience.

## Moving reusable code to services

`screen/dev/hex_paths` is compiled only with the `dev` feature, but play
needs the generator in release builds. Everything reusable moves to non-dev
services:

- `service/worldgen/`: `terrain/`, `layout/`, the pure parts of `Board`
  (measurement, not the surface mesh or markers), the settings assets and
  `HexSettingsCollection`, and the async generation task from the async issue.
- `Billboards` and the billboard spawning helpers go to a billboard service
  next to `common::billboard`. The editor uses them for markers; the
  vegetation preview and the play screen's impostors reuse them.

The editor keeps its panel, preview mesh, markers, and camera. This move is
a pure refactor and should be its own PR, with no behaviour change.

## Vegetation preview in the editor

Vegetation algorithms need the same iterate-and-look loop as pathing, before
any 3D detail or final assets exist. The editor gets a top-down vegetation
view:

- **Three layers**: ground cover, understorey, and canopy. Each layer has its
  own density drivers, spacing, and clearance, and they interact: canopy
  shades out understorey, and understorey thins ground cover.
- **Settings as assets.** A `VegetationSettings` RON asset (per-layer density
  curves, spacing, path and pad clearance, the squircle boundary)
  joins `HexSettingsCollection`. It is edited through the advanced editor
  and saved and loaded with the other settings, and hot reload applies.
- **Raster overlay.** Placement runs over the whole playable window and
  produces points per layer. The points are rasterised into a texture laid
  over the terrain mesh, coloured by layer, alongside the
  existing `TerrainView` measures. The raster is the cheap, dense view for
  tuning distributions.
- **Billboards.** A toggle spawns billboards at the placed points instead,
  for a sense of scale and occlusion before the real models exist.
- **Placement is the same code play uses.** It is a pure function of the
  skeleton, the seed, and `VegetationSettings` in `service/worldgen`, with
  per-chunk evaluation so play can call it for one chunk at a time. The editor
  just evaluates every chunk.
- Changing vegetation settings re-runs placement only, not terrain or layout
  generation. Layout changes re-run it too, because of path clearance.

## Detail per chunk

All randomness comes from `hash(seed, chunk, layer)` so that chunks are
independent of load order.

- **Ground.** Sample the region heightfield (`Region::sample_cubic`) at the
  chunk's LOD resolution, using the layout's levelled heights near pads, plus
  small-scale detail noise. At LOD 0 the resolution should be about 1 m
  (versus 33 m hex edges today).
- **Paths.** Trail edges become polylines on the ground. A distance field to
  them does two jobs:
  - It carves and flattens the ground within a path half-width, blending
    out, like `Layout::level` does around pads.
  - It drives a splat weight for the path texture.
- **Vegetation.** The placement from the editor's vegetation preview, evaluated
  for this chunk: blue noise (Poisson disk) with density driven by existing
  measures (suitability, steepness, creek proximity) and by the boundary. It
  excludes paths and pads.
- **Node props.** Each `NodeKind` maps to a Jackdaw `.bsn` scene (bench,
  POI, crossing/bridge, spawn), spawned at the pad centre on levelled
  ground. Props belong to the chunk that contains their pad.
- **Colliders.** Each chunk gets an avian3d heightfield collider at a fixed
  resolution regardless of visual LOD. Otherwise, graphics settings would change
  where the player can stand, and an LOD swap underfoot would pop the player.
  Ground colliders exist only in LOD 0 chunks, so the fixed resolution is
  cheap. Vegetation is passable (see Passability); trunks get capsules in LOD 0
  chunks so the player walks round them, not through them.

## Boundaries

Each level is bounded. The playable window sits inside the terrain margin
(`HexTerrainTuning::margin`), which today is scenery:

- The margin becomes **dense forest**: vegetation at maximum density with no
  paths. A rectangular edge would make corners feel artificial, so the
  boundary is a **squircle** (a superellipse fitted to the playable
  rectangle) with low-frequency noise on its radius. The same curve drives
  both:
  - the forest density ramp: density rises towards the boundary and is
    maximal outside it;
  - an invisible collider wall just inside the dense forest, so the player
    never reaches the end of the generated mesh.

  The superellipse exponent and the noise are vegetation settings.
- **Creeks**: dry banks for now, with no water. See Passability.

## Passability

The player roams freely, off-path included. Movement is restricted by
**large features** that cannot be crossed, not by the trails:

- **Steep drops**: slopes beyond the controller's walkable limit. The
  controller already refuses them, so the terrain does this work. Escarpments
  (`quell-hex-terrain-design.md` §4) are the deliberate case.
- **Creek banks**: steep everywhere except at shallow sections. Crossings
  sit at those sections; `trunk_sites` already prefers low-bank sites.
  So creeks are largely impassable, except where it would be natural to
  cross them.
- **Boulders**: placed lines or clusters that close gaps where terrain
  alone would let the player shortcut a tease or bypass a crossing.
- **Vegetation** is passable. Only the outer forest boundary blocks.

This keeps teases meaningful, but changes what the generator must check.
Today `tease_detour` and the pace statistics measure walks along trails. Under
free roaming, a tease holds only if the **passability graph** (terrain edges
minus barriers) forces the detour. So the generator gains:

- a passability mask on the corner graph: steep edges, creek edges other
  than at crossings, and boulder edges;
- boulder placement that closes shortcuts which would break a tease or
  bypass a crossing;
- tease validation and pace measured over passable ground as well as trails.

The editor shows the mask as a `TerrainView`, so barriers can be tuned like
paths and vegetation. Barrier thresholds and boulder placement are settings
assets. Play builds colliders and boulder props from the same mask, so the
editor's preview of passable ground matches what the player can actually
reach.

## Streaming and LOD

- Chunk size: to tune; start at about 64 m. The default board is about 1 km
  across plus the margin, so roughly 16×16 playable chunks.
- Use rings around the player: LOD 0 (full detail and colliders) nearby,
  coarser ground and billboard impostors for vegetation further out,
  ground only at the horizon. The existing marker billboards are prior art
  for the impostors.
- Use Bevy's `VisibilityRange` for distance cutoffs and crossfades between
  LOD meshes.
- Generation runs as async tasks with a small budget per frame. A chunk the
  player is about to enter has priority.
- Chunk and LOD distances are a settings `Resource`, so they can be tuned for
  weaker GPUs.

## Saves

A save is a RON asset written with `RonAssetSaver`, like the presets:

- `generator_version`: guards against loading a save with a generator that
  would produce different terrain.
- `preset`: an inline copy of the settings and tuning, not a handle. Editing
  the preset files must not change existing saves.
- `seed` and the level index within the playthrough.
- Regeneration history: each regeneration's player tile and whether it was
  Fear, in order. Replaying it from the seed reproduces the current layout,
  since `regeneration_seed` derives each regeneration's seed from the
  level seed and the layout count.
- Player state: transform and inventory.
- Node state: items per node, keyed by tile index. Node positions are
  stable for a given seed, generator version, and regeneration history.

Geometry never changes during play, so nothing about the terrain is saved.
If regenerating the skeleton on load proves too slow, cache it as a binary
asset keyed by a hash of `(generator_version, preset, seed)`. The cache is an
optimisation; the save stays authoritative.

**Determinism** is load-bearing:

- every RNG is seeded from the level seed;
- no iteration over hash maps whose order affects output;
- same build and platform only. Cross-platform float determinism is not a
  goal; `generator_version` makes mismatches explicit rather than silent.

## Screens

- **WorldScreen** (`Loading`): start the skeleton task, show progress, and
  finish loading when the skeleton and the spawn chunk's LOD 0 detail are
  ready. Then spawn the player at the spawn pad. `Update` streams chunks.
- **Greybox**: the `greybox_arena` dev screen already loads
  `greybox_scene.bsn`; WorldScreen stops loading it.
- **hex_paths**: unchanged apart from depending on `service/worldgen`, plus
  the dev-only "play this level" button.

## Out of scope

- Inventory and item design, beyond reserving room in the save.
- Level-to-level transitions and what ends a level.
- Art: textures, tree models, and the prop scenes themselves. This design
  only fixes where they plug in.

## Proposed issues

Each one is a PR and follows the async generation issue.

1. Move reusable code to services: the generator to `service/worldgen`, and
   billboards to their own service (refactor, no behaviour change).
2. Editor vegetation preview: `VegetationSettings` asset, placement,
   squircle boundary, raster overlay, billboard toggle.
3. Editor passability: barrier mask, boulder placement, tease and pace
   validation over passable ground.
4. WorldScreen drops the greybox scene (`greybox_arena` keeps it) and loads a generated level
   skeleton and spawns the player on a single LOD 0 ground mesh with a
   collider. Not chunked yet.
5. Chunked ground, streaming, and LOD distances.
6. Path carving and path splat, including chunk invalidation on
   regeneration.
7. Vegetation in play: per-chunk placement, boundary collider, impostors.
8. Node props and boulders from Jackdaw scenes; dry creek banks and
   crossings.
9. Save and load: the save asset, regeneration history, and the generator
   version.

## Open questions

1. **Chunk size and LOD distances**: tune on your GPU after issue 5.
2. **What drives each vegetation layer**: decided while playing with the
   preview.
3. **Water in creeks**: deferred; dry banks for now.
