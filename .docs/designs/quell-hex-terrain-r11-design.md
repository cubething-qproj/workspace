# Quell hex terrain, round 11: the generator as it stands

Status: **Round 11, 2026-10-13. Python experiments settled. Next: re-plan the
Rust port against this.**

This document consolidates rounds 1–10 into the current algorithm:
- `quell-hex-terrain-design.md` covers rounds 1–9: the original terrain-first
  generator and the round-9 port changes;
- `quell-hex-layout-design.md` covers round 10: layers, pins, Fear and
  lostness.

Where they disagree, this document wins.

Code: `misc/hex-lab/src/hexlab/` (`terrain.py`, `erosion.py`, `layout.py`).
Every experiment is a tagged hex-lab commit (`exp/NN-name`), with a summary in
`misc/hex-lab/experiments/` and figures in
`.docs/designs/quell-hex-terrain/experiments/NN-name/`. The current algorithm
is the arm `creeks2-trunk` at tag `exp/12-crossings`.

## Goals (unchanged)

- **Terrain first:** trails bend to the terrain, never the reverse.
- **Lost but readable:** no map. The player's device only points to the
  nearest node, and only when they check it. Nodes are landmarks; the way
  between them is uncertain.
- **A Fear regenerates the trails,** not the terrain.
- **Walk every trail in about an hour.**

## Scale and units

- **One hex edge is 33 m.** The playable board is 20 × 20 hexes, about
  1.0 × 1.15 km, with a 6-hex scenery margin.
- **Heights are in metres in the knobs,** and in edge lengths inside the
  generator.
- **Pace:** Tobler's hiking function, 6·e^(−3.5·|slope + 0.05|) km/h, which is
  11.9 min/km on the flat. Times are averaged over both walking directions, on
  smoothed trail length (honeycomb × √3/2).
- **Typical boards:** 4–5.5 km of trail, about 45–65 min to walk it all,
  2–3 min to the nearest node, 10–25 min from spawn to the farthest node.

Exp 06.

## 1. Terrain: regional erosion, northeast-Kansas character

Reference: Atchison County, Kansas. Glacial-drift uplands are finely carved by
dendritic ravines and creeks set 2–5 m into the ground; there are no lakes.

**Simulate a region, then crop the board.**
1. **Region:** 100 × 100 hexes (about 5 km square), one cell per hex edge.
   - It drains off **every side** ("rivers all round"), so there's no global
     direction to read.
   - It starts nearly level: 0.2% regional fall, 4 m rolling rises about
     1.5 km across, and 1 m white-noise roughness. The roughness breaks
     grid-straight channels.
2. **250 erosion passes,** each:
   1. lift the land `uplift_m` against fixed outlets;
   2. priority-flood so every cell drains downhill (pits get a tiny slope, a
      breach, never a pond);
   3. route steepest descent;
   4. cut channels by stream power, erodibility × area^0.5 × slope, where
      drainage passes `channel_ha` (2 ha);
   5. let slopes creep.

   Lifting against fixed outlets grows dendritic networks headward. A tilted
   plane gives parallel gullies instead, and a single outlet only carves
   about 1.5 km inland (exps 07–08).
3. **Choose the window by play features** (exp 09). Score 60 random windows
   (any position far enough from the region's edges, random rotation) on:
   - creek tiles in the playable area;
   - **ford sites:** creek tiles with banks within 3 m, spread 4 hexes apart;
   - **natural tease spots:** a viewer and target 3–6 hexes apart, the target
     at least 12 m lower, with a clear sight line;
   - a penalty for rivers (over 600 ha);
   - a weak bonus for 15–60 m of relief.

   Keep the best. Flat bottomlands aren't punished.
4. **Heights** are sampled cubically into the window raster at 2 cells per
   edge.

Cost: about 20 s per region in Python. Regions are cached per (settings,
seed).

**Creeks** run on the **dual lattice** (tile centre to tile centre). The
region's channels at 40 ha or more are traced tile by tile: each channel cell
maps to its nearest tile, and a creek tile's downstream is the next tile down
the channel. Gaps where a channel skips a tile near a hex corner are filled in,
so every creek link joins neighbouring tiles (exp 11).

**Colours** in figures are absolute height, 0–120 m above the region's
outlets, and deliberately false-colour.

## 2. Layers ("liquid geometry")

The displayed terrain is heightmap + model layer + trail layer:
- **Heightmap:** never edited after generation.
- **Model layer:** pads level their ground (median of the corners, graded
  around). Removing a location restores the heightmap.
- **Trail layer:** a material change, at most a very slight grade. It never
  changes topology, and routing ignores it.
- **No escarpments are raised.** Teases come from natural drops only; 94% of
  placed teases hold (exp 04).

Later, fine detail (smaller noise octaves, deep creek channels) goes in display
layers too, kept small enough not to change routing.

## 3. Nodes (typed at placement)

| Node | Placed by | Notes |
| --- | --- | --- |
| **Spawn** | the board's middle tile, moved off a creek | Becomes the player's tile on regeneration. |
| **Crossing** | first; see §4 | Bridges and fords. Not a POI or bench, no card. **Never moves.** |
| **POI** (6) | suitability^`spread` (2) × up to 2× near water (e^(−hexes/2)) | Deck: key, NPC, Fear on random POIs; the rest are empty. **The deck never changes.** |
| **Bench** (3) | bench score | Not a spur by preference. The "benches together" rule is dropped and kept only as a statistic. |

- **Bench score** = (1 − `view`) · quiet⁴ + `view` · overlook⁴, with quiet and
  overlook ranked **among playable tiles only**.
- **Placement** is weighted farthest-point: 3 hexes minimum spacing, the board
  edge counted as a pad at half distance, nothing on creek tiles.

Exps 03, 10.

## 4. Crossings

Trails cross a creek **only at crossing nodes**. The hex side between two
consecutive creek tiles is closed to trails; a crossing's pad perimeter is the
ford or bridge. `crossings` defaults to 2 and is a slider.

Placement (exp 12):
1. **On creek tiles only.**
2. **First,** any crossings needed to join parts of the board the creeks cut
   off, lowest banks first.
3. **Then** the rest go on the **main creek** (at least half the biggest flow
   on the board), each as far as possible from the others. Two crossings land
   near opposite ends, so the creek is a long way round rather than a wall.
4. **Both banks:** after the trail passes, any bank of a crossing pad without a
   trail gets one to the nearest trail or pad on that bank.

Creeks and crossings are terrain-stable, so they're the fixed landmarks
through a Fear.

## 5. Trails

Unchanged from rounds 5–8, minus escarpments and noise:
- **Tease pairs:** a POI target, the viewer reached first from spawn on foot
  (two-pass), visible and already dropping, ranked as before. Every route is
  guarded so it doesn't break more teases than are already broken.
- **Greedy spanner:** stretch 2, reuse discount 0.6, alongside penalty 2.5.
  Then a connection pass, so there's never a softlock.
- **Loops:** cheap loops (≤ 3× the existing link, ≤ 18 edges), then the
  no-tree pass. Loops rejoin the first trail they meet, keeping clear of
  their own spur.
- **Then both banks** for crossings (§4).
- **Not used:** route noise (it only added wiggle and cost teases, exp 04) and
  forks (exp 05). Forks remain the main candidate for getting lost later.
- **Creeks shape the network more than any knob did.** Trails follow banks and
  funnel to crossings, and spawn → farthest roughly doubles.

## 6. Regeneration

`layout(ground, pins, seed)` is one pure function; the first layout is the
case with nothing pinned.

**Pins:**
- the player's tile (the new spawn);
- the node the player stands on;
- fixed nodes;
- movable nodes (old tile; moved 2–4 hexes, may swap, never onto a creek);
- fixed trail edges.

**Crossings are always fixed.**

**Partial regeneration:** everything within 4 hexes of the player is pinned.
Pinned trails cut by the radius leave **ports**, open ends that must join the
new network. No dead ends were left in any exemplar.

**A Fear:** only the player and the crossings are pinned. Every other node
moves and the trails regenerate.

**Seeds:** the terrain seed gives the region, the window and the first layout.
Each regeneration uses (seed, count). Exps 04, 11, 12.

## Knobs

| Knob | Default | Meaning |
| --- | --- | --- |
| `columns`, `rows` | 20, 20 | Playable board (hexes). |
| Hex edge | 33 m | Scale. |
| Region size | 100 hexes | Simulated area. |
| `uplift_m` | 0.2 | Relief (0.6 gives about 2× the relief). |
| `channel_ha` | 2 | Ravine density. |
| Creek threshold | 40 ha | What counts as a creek. |
| Window candidates | 60 | Windows scored. |
| Window weights | see `WindowWeights` | Creek, fords, teases, river, relief. |
| `pois`, `benches` | 6, 3 | Node counts. |
| `spread` | 2 | POI pull to buildable ground. |
| `view` | 0.7 | Bench preference: quiet (0) to overlook (1). |
| `bench_sharpness` | 4 | Only the extremes score as benches. |
| `water_boost` | 1 | POI pull to water. |
| `crossings` | 2 | Creek crossings (slider). |
| `teases`, `tease_detour` | 2, 3 | As before. |
| Pin radius | 4 hexes | Partial regeneration. |
| Displacement | 2–4 hexes | How far movable nodes move. |

## Effect on the Rust port

**Done on `feat/hex-paths`, and carries over:**
- step 1: strip;
- step 2: 3D viewer with orbit camera, hex mesh, vertex colours, panel and
  sliders;
- step 3: Tobler step costs and the cost view;
- step 4: placement, billboards, reveal, click-to-focus, typed placement.

**Changes in Rust:**
- **Terrain:** replace noise hills with regional erosion plus window ranking.
  It's heavier, about 20 s per region in Python, so in Rust expect around a
  second. Candidates for the background task the design already allows.
- **Creeks, crossings and crossing nodes:** new data on the dual lattice, plus
  a creek view.
- **Pace:** metre units and walk times.
- **Layout as a pure function of pins,** with regeneration and ports, and
  crossings pinned.
- **Not needed:** escarpment raising and route noise.

Re-plan `.docs/plans/quell-hex-terrain-plan.md` from here.

## Open questions

1. **Getting lost:** forks or connectors (the Clinton Lake "ladder"), now on
   creek terrain.
2. **Creek-bed walking** as a stable shortcut corridor.
3. **Finer ravines:** a second erosion pass inside the window, or display-only
   detail.
4. **What stays during a regeneration** (deferred): the pin radius versus "only
   a Fear reshuffles fully".
5. **Very long teases across a creek** (×17 on exp 12, seed 3): fine, or should
   they be capped?
