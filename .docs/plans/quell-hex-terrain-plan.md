# Quell hex terrain: implementation plan

Ports the terrain-first generator from
[the design](../designs/quell-hex-terrain-design.md) into
`bin/quell/src/screen/dev/hex_paths/` on `feat/hex-paths`. History stays
linear and each step below is one commit. The reference implementation is
`misc/hex-lab/src/hexlab/terrain.py`; Rust follows its names and order so the
two can be read side by side.

## Shape of the code

```text
hex_paths/
  mod.rs        # plugin, resource registration (as now)
  screen.rs     # screen schedule (as now)
  data.rs       # components, resources: settings, tuning, view, appearance
  systems.rs    # spawn board, camera, views, walking
  panel.rs      # debug panel: terrain section, network section, view picker
  test.rs       # fixture tests (walking, regeneration)
  terrain/      # pure generation, no ECS; replaces generate.rs + generate/
    mod.rs      # Terrain::generate, the pipeline (generate() in Python)
    mesh.rs     # Mesh: tiles, corners, edges, playable, margin
    height.rs   # Raster, noise, blur, ridges, sampling
    route.rs    # step costs, Dijkstra, routes
    sites.rs    # suitability, viewsheds, bench score, farthest-point sampling
    teases.rs   # tease pairs, escarpments, levelling, broken_teases
    network.rs  # spanner, loop closure (loop/tree/rejoin), on_loop
    types.rs    # assign_types, deck
    smooth.rs   # chains, Laplacian, Chaikin
```

Resources (tweakables as Resources, never statics):

- `HexPathsSettings`: the design's knobs (columns, rows, seed, scale, relief,
  roughness, ridges, nodes, spread, view, teases, tease_height range,
  tease_detour). Changing it regenerates.
- `HexTerrainTuning`: the prototype's internal constants (AVERSION, REUSE,
  ALONGSIDE, GRADE, MAX_CONNECTOR, CHEAP_LOOP, MIN_LOOP, SCARP_*, REJOIN, ...),
  with the same values. Changing it also regenerates. It goes in a collapsed
  panel section.
- `HexPathsView`: which view is shown, plus walking and sight. Changing it never
  regenerates.

## Steps

### 1. Strip the old generators and tile-centre movement

Delete:
- `generate.rs` and `generate/grow.rs`;
- `examples/hex_paths_measure.rs`;
- `docs/hex-path-counts*`;
- `Spokes`, `PathShape`, `ShapeWeights`, `TileKind`, `GeneratorKind`,
  `SpawnPlacement`, `Walk`, `WalkTo`, `BoardStats` and their panel rows,
  systems and tests.

The screen keeps the camera, the panel shell (regenerate, seed, columns, rows)
and draws the bare hex grid outline.

- **Risk: low.** It's almost all deletion. The test fixture loses its walking
  tests until step 9; regeneration tests stay.
- **Likely outcome:** a large negative diff that's easy to review. The screen
  is a grid with a panel.

### 2. Mesh, heightmap and 3D view

- `terrain/mesh.rs` and `terrain/height.rs`: corners deduplicated, the
  6-hex margin, `playable` and `playable_edges`.
- Raster noise: 4 octaves of Gaussian-blurred white noise, the ridged blend,
  the VALLEYS power and relief, with bilinear sampling at corners.
- The board becomes a `Mesh3d` built from corners and centres, with
  `ATTRIBUTE_COLOR` set from the height ramp.
- A new static `Camera3d` replaces `Camera2d`. It has no free movement and no
  orbit, only a **tilt** (pitch, set in the panel) for inspecting geometry.
  - **Centre on terrain** fits the whole board, for a bird's-eye view.
  - **Centre on player** sits closer and follows the player, for a
    player's-eye view. Until step 9 it centres on spawn.

  The camera lives in the screen module, not q_cam, because it's
  prototype-only.
- The panel gets its Terrain section, the camera controls, and the view
  picker's first view: Heightmap.

Risks:
- **Corner deduplication.** hexx's `GridVertex` has no canonical hashable form
  (`==` isn't `equivalent`), so I'd keep the prototype's rounded-position key.
  The unit test checks corner and edge counts and that each tile has 6 corners.
- **Even-q offset vs hexx layout origin with a margin.** Off-by-one errors here
  would shift the playable area. A unit test checks that playable corners lie
  inside the board.
- **Camera and lighting.** Vertex colours need a `StandardMaterial` that
  doesn't wash them out. This is a visual check for you.

Likely outcome: you can tilt over a coloured heightmap. It won't match the Python
pictures seed-for-seed, because the RNGs differ.

### 3. Ease of travel

- `terrain/route.rs`: the Tobler step cost, a binary-heap Dijkstra over corners
  (`routes` with targets), and `inf` off the board.
- New view: Cost (vertex colours by mean incident edge cost).

Risk: low. The old `generate.rs` already had a heap search, and this is the
same idea. Tests: cost is symmetric and finite on the board, and a route exists
between any two playable corners.

### 4. Node sites

- `terrain/sites.rs`: suitability, viewsheds (eye 0.5, radius 6), the
  quiet/overlook rank blend, and weighted farthest-point sampling with the
  border pad term.
- Node markers are **billboards** from `assets/textures/hex-prototype/`:
  - textured quads that turn each frame to face the camera;
  - alpha-blended and unlit;
  - spawn uses `spawn-billboard.png`, and nodes start as
    `unknown-billboard.png`.
- New views: Suitability, Bench score.

Risks:
- **Viewshed cost.** This is the heaviest loop (corners × rays × steps). I'll
  time generation; anything above ~200 ms on default knobs I'll report rather
  than optimise blindly.
- **Rank blending ties.** Ties are ordered differently from numpy. That's
  harmless, but outputs won't match Python exactly.

Tests: nodes are on playable tiles and at least MIN_SPACING apart.

### 5. Teases and levelling

- `terrain/teases.rs`: tease pairs ranked by visible, then existing drop, then
  closest.
- `raise_scarps`: shortfall only, sigmoid front, back cap, reach cap, and a
  wandering edge.
- `level` (pads to median, graded falloff) and the landmark visibility check.
- The two-pass walking order (generate without teases, learn order, then again)
  lives in `Terrain::generate`.
- New view: Teases (gizmo lines viewer → target, red if hidden). Heightmap now
  shows the altered terrain, and Cost and the other views follow it.

Risks:
- **Medium.** This is the most geometric step, and the wandering escarpment
  edge is easy to get subtly wrong. Bugs show up as hidden teases rather than
  crashes, so step 8's stats are the real check.

Tests: a levelled pad is flat, and terrain outside reach is unchanged.

### 6. Trails

- `terrain/network.rs`: the greedy spanner (STRETCH, two passes, reuse
  discount, alongside penalty, tease pairs never joined directly).
- The `lay` guard (`broken_teases` must not increase), with the unguarded
  fallback.
- `on_loop` via local node connectivity in the contracted graph. That's
  biconnected components (Tarjan) by hand rather than a new dependency.
- `close_loops`: the loop pass, then the tree pass sparing tease targets, plus
  REJOIN with 2-corner spur clearance and MIN_LOOP.
- New views: Graph (spanner lines between nodes) and Trails (honeycomb edges
  coloured by kind: span/loop/tree/forced).

Risks:
- **High. This is the largest and most rule-dense step.**
  - The connectivity test for "on a loop" must use node-disjoint paths, not
    bridges. Using bridges was the "fake loops" bug in the prototype.
  - Rejoin's `back` distance and label lookup are subtle.
- I may split this commit into 6a (spanner and guard) and 6b (loops) if the
  diff passes about 600 lines.

Tests (properties over a handful of seeds, not exact layouts):
- the network is always connected;
- spawn is on a loop;
- no trail joins a tease pair directly.

### 7. Typing and smoothing

- `terrain/types.rs`: spurs and tease targets become POIs; benches greedily by
  score under `benches_apart == 0` while holding POIs back for the deck; cards
  dealt to POIs, with structure winning over counts.
- `terrain/smooth.rs`: chains between junctions and pads, then Laplacian ×4,
  then Chaikin ×3.
- New views:
  - Types: every node billboard shows its type (bench, key, npc, fear,
    empty). In play, a node shows `unknown` until reached.
  - Final: trails as splines draped on the mesh. Height is resampled per
    spline point (Catmull-Rom on corners) so trails don't cut through the
    ground.

Risks:
- **Medium.** Draping is the new part. A spline sampled between corners can
  dip below the triangle surface, so it needs a small lift.

Tests:
- every spur is a POI;
- no two benches are adjacent along a trail without a node between;
- the deck's key, NPC and Fear are dealt whenever there are at least 3 POIs.

### 8. Measure example and parity check

`examples/hex_terrain_measure.rs` (same `#[path]` trick as the old one) writes
the same CSV columns as `terrain_stats.py`. I run 1000 seeds and compare with
`stats-1000-rejoin.csv`. The comparison table goes in the commit message and
the PR, not a new doc.

- **Risk: the distributions won't match exactly** (different RNG and float
  order). I'll flag anything off by more than roughly 10% relative on the
  headline rows (teases held, spawn on loop, spurs, benches, long loop trails)
  and fix it before moving on.
- **Likely outcome:** one or two porting bugs surface here. They get fixed in
  this commit or as fixups to the step they belong to (your call).

### 9. Vertex-to-vertex movement

- The player stands on a corner.
- Clicking the terrain (mesh picking) picks the nearest trail corner.
- `Walk::plan` becomes Dijkstra over known trail edges.
- `walk` eases corner to corner along edges, at terrain height.
- The player is `player-billboard.png`.
- Reaching any pad corner reveals that node's card.
- Sight shows trails within `sight_radius` edge lengths.
- The fixture tests come back: reveal on arrival, and unreachable targets
  ignored.

Risks:
- **Picking.** Mesh picking on a large vertex-coloured mesh needs
  `MeshPickingPlugin`, which isn't on yet. Clicks also need to ignore the
  panel, as now.
- **Pacing.** Edges are short and corner-to-corner motion may feel twitchy.
  Easing along the smoothed spline is a possible follow-up, not this step.

### 10. PR

Scan existing issues and PRs first, then push and open the PR.

## Cross-cutting risks

- **No seed parity with Python.** Validation is statistical (step 8) plus your
  eye on the views. It isn't image diffs.
- **Generation time.** Generation is synchronous on regenerate. If it's
  noticeably slow at the default size, moving it to `AsyncComputeTaskPool` is a
  separate small commit.
- **Dead code between steps.** Each step wires its new functions into a view
  right away, so nothing sits unused. That's the reason for the
  vertical-slice order.
- **Size.** About 1500 lines of Rust are expected, with step 6 the largest.

## Decisions

1. **Commits:** the prototype (`terrain.py`, `terrain_stats.py`) is committed
   in `misc/hex-lab`. The CSVs are gitignored under `results/`, so they stay
   local. The design doc, PNGs and this plan are committed in the org repo.
2. **Camera:** a new static camera with tilt only, centred on terrain or on
   the player (step 2). Player, spawn and node indicators are billboards.
3. **Sight:** trails within `sight_radius` edge lengths of the player, plus
   every trail already walked. Later, trees and other cover will hide trails
   instead.
4. **Movement:** corner to corner along honeycomb edges. The prototype won't
   follow smoothed trails. Later work reshapes the heightmap, adds trail
   materials and puts a player controller on top.

## Progress and changes (2026-10-12)

Done:
1. **Strip** (`67dad3c`).
2. **Heightmap and 3D view** (`803d94f`). The camera is a bevy_editor_cam
   orbit camera (right-drag, wheel zoom, no pan), not the static tilt camera
   planned here.
3. **Step costs and the cost view** (`f76fd2a`). Route search moved to the
   step that first uses it.
4. **Lifecycle refactor** (`78935c8`), then **node sites** (`36baf46`).
   Follow-ups (sliders, typed placement, bench score fixes, reveal toggle,
   click-to-focus) are committed separately.

Changes to later steps, from typed placement (design doc, "Rust port
changes"):
- **Step 5 (teases):** pick pairs with a POI target.
- **Step 6 (trails):** best-effort bench rules. Bench spurs always get a loop
  attempt; spanner routes avoid going bench to bench. Breaks are counted.
- **Step 7:** typing becomes dealing the deck to POIs, plus smoothing.

The cross-cutting source layout cleanup waits for after this PR
(`.docs/handoffs/quell-src-layout-handoff.md`).

## Re-plan needed (2026-10-13)

Steps 5 onward are superseded by round 11
(`.docs/designs/quell-hex-terrain-r11-design.md`):
- regional erosion terrain with a ranked window;
- creeks on the dual lattice, with crossing nodes;
- metre units and pace;
- layout as a pure function of pins (regeneration);
- no escarpment raising or route noise.

Re-plan the remaining Rust steps from that document before continuing.
