# Quell hex terrain, round 10: terrain and layout layers

Status: **Round 10, superseded by round 11 (`quell-hex-terrain-r11-design.md`), 2026-10-13.** Kept for the experiment record.

Builds on `quell-hex-terrain-design.md` (rounds 1–9). It changes three things:
- the terrain is never edited;
- a Fear regenerates the trails;
- walks should leave you lost.

Everything not mentioned here stays as it is.

## Why

1. **Fear regenerates the trails.** Reaching a Fear disorients the player, and
   the trails change while the terrain stays put. So the terrain and the layout
   (nodes and trails) need separate generation, and the layout must be able to
   rerun on the same ground.
2. **Walks should get you lost.** Rounds 5–8 optimised for a tidy network: the
   spanner only adds a trail when the detour is over 2×, there are no trees,
   and loops are added when cheap. Seed 7 of the typing experiment is where
   that leads: one big clean ring, efficient and easy to read. That's the
   opposite of the intent.

   The goal is **lost but readable**: nodes act as landmarks, but the way
   between them is uncertain. You get surprised by what's at the end of a
   trail, and you sense the world changing behind you, perhaps literally,
   later. The player has **no map**. Their device only points to the general
   location of the nearest node, and only when they check it.

## Layers: liquid geometry

The displayed ground is a stack:

```text
displayed terrain = heightmap   (terrain seed; never edited)
                  + model layer (locations: pads, benches, … dig in or flatten out)
                  + trail layer (trails settle into the ground)
```

- **Heightmap.** Generated once from the terrain seed. Nothing writes to it.
- **Model layer.** Each location (POI, bench, spawn) carries a model that digs
  into or flattens the land around it, like today's levelling. Removing the
  location removes its model, and the ground returns to the heightmap.
- **Trail layer.** Trails change the ground's material, with at most a very
  slight grade that never changes the topology. Regenerating the trails
  replaces this layer.

What this changes from round 9:
- **Escarpments are no longer raised.** Teases come only from drops the
  heightmap already has. The tease search already prefers "already visible,
  already drops", and the round-5 table showed teases hold almost as well
  without raising (20 of 23 at `tease_height = (0, 0)` against 21 of 23).
  Terrain generation should be varied enough for teases to appear naturally.
  "Teases found per board" becomes a tracked statistic.
- **Pad levelling becomes a model layer.** Same grading rule, but it's applied
  when drawing, not baked into the heightmap.
- **Routing.** Costs come from the heightmap plus the model layer, so trails
  see flat pads. The trail layer doesn't feed back into routing.

## Seeds

- **The terrain seed** generates the heightmap. The same seed also generates
  the **initial layout**, so one number reproduces a whole board. That helps
  debugging and maybe speedrunning.
- **Each regeneration** uses a layout seed derived from (seed, regeneration
  count), so a run replays exactly.

## Fear regeneration

When the player reaches a Fear, the layout regenerates:

| | After a Fear |
| --- | --- |
| Terrain (heightmap) | Unchanged. |
| Trails | Regenerated from scratch. The player has to find their way again. |
| Nodes | Kept, each displaced randomly within 3–5 tiles so it stays in the same general area. Visited nodes move too, and nodes may swap places. Model layers move with them. |
| Visited nodes | Still revealed. |
| Deck | Unchanged: cards stay with their nodes. |
| Player | Stays where they are. Their corner becomes the new layout's spawn, so teases and walking order follow from it. |

Timing doesn't matter: the event isn't instantaneous, and the player keeps
doing things while the layout regenerates. Generation can run in the
background, or be spread over frames.

## Pinned regeneration: the shape of the layout step

Regeneration must work with **some nodes and trails pinned**. For example,
everything within a radius of the player stays put while the rest changes, and
a Fear pins almost nothing. So the layout step is one function, and the first
layout is just the case with nothing pinned:

```text
layout(terrain, pins, seed) -> nodes, trails, teases
pins = {
  player:  the corner the player stands on (the new spawn),
  nodes:   fixed nodes (tile, type, card),
  movable: nodes to re-place near their previous tile (type, card, old tile, radius),
  trails:  fixed trail edges,
}
```

What each stage has to do with pins:
- **Placement.**
  - Pinned nodes count as already placed: farthest-point sampling already
    takes a `taken` list.
  - Movable nodes are re-placed within their radius of their old tile,
    respecting spacing. Swaps fall out of this when two movable nodes land on
    each other's areas.
  - Type and card travel with the node: the deck never changes.
- **Pinned trails** are laid before anything else, and the spanner and loop
  passes build around them. The greedy passes are already incremental: they
  measure detours over the existing network and reuse it at a discount. So a
  pinned network is just a non-empty start.
- **Cut ends.** Where a pinned trail is cut off by the pin radius, its open
  end is a **port** that must join the new network, like a node that needs
  connecting. Otherwise pinning leaves dead ends at the radius boundary. Ports
  go through the same join and loop passes as nodes, with no type.
- **Rules** (bench spacing, benches never together, the tease guard) count
  pinned nodes and trails like any others. A pin can't be undone, so a rule
  the pins already break is only counted, never fixed.
- **Teases** are recomputed from the new spawn (the player). A pinned tease
  pair stays a tease only if it still holds.
- **Model layers** move with their nodes. Pinned nodes keep theirs.

This mostly constrains the Rust structure. Generation is a pure function of
(terrain, pins, seed), with no state kept between runs. The Python
experiment should be built the same way, so partial regeneration can be tested
too.

## Lost but readable

**Bring back route noise.** The original design had it, and it got dropped on
the way to terrain-first routing.
- Each layout seed gets a smooth noise field: a low-frequency multiplier on
  step costs, so trails meander in coherent sweeps rather than jittering.
- `wander` sets its amplitude. With noise, rerunning the layout on the same
  terrain gives genuinely different trails, which a Fear needs.

**Measures**, tracked like the others:
1. **Detour:** walk ÷ crow-fly between node pairs, and between random pairs of
   trail corners. Higher means more winding. Report the median and the spread.
2. **Branch count:** how many genuinely different ways connect two places.
   Two candidate definitions, to be compared in the experiment:
   - the number of routes between node pairs within 1.5× of the shortest walk,
     counting only routes that don't share the same trail;
   - junctions passed per walk between neighbouring nodes.

   "One big ring" scores low on both: few junctions, two ways round.

**Knobs to try:**
- `wander` (route-noise amplitude);
- spanner stretch below 2, for more redundant links;
- **forks:** unmarked side trails that rejoin elsewhere;
- loops that close locally instead of across the board.

## Placement (from round 9, adjusted)

- POIs placed by suitability ^ `spread`, with `spread` defaulting to 2.
- Benches then placed by bench score, **spaced from each other** by more than
  the general spacing. The typing experiment showed that benches cluster on
  the same ridge, and the spanner then joins them directly on 82% of boards.
- Teases need a POI target, from natural drops only.

## Python experiment (before Rust)

Rework `misc/hex-lab` to the layer model, then compare arms over 1000 seeds
with figures in the design-doc style:
- **Baseline:** round 9, typed placement, no raising.
- **Bench spacing:** benches kept apart from each other (6 hexes).
- **Route noise:** several values of `wander`.
- **Mazier networks:** lower stretch, forks.

**Statistics:**
- bench site quality and benches together;
- spurs;
- teases found and held;
- connection pass use;
- trail length;
- detour;
- branch count.

**Figures:**
- one seed per arm;
- a **regeneration sequence**: one terrain with its initial layout, then a
  partial regeneration (everything within a radius of the player pinned),
  then a Fear (nodes displaced, trails regenerated, terrain identical).

Partial-regeneration statistics: ports that fail to join, dead ends at the
pin boundary, and how much of the network outside the radius actually
changed.

## Results: first run (1000 seeds, 20 × 20)

Code: `misc/hex-lab/src/hexlab/layout.py`, tag `exp/04-layers`. CSV:
`misc/hex-lab/results/terrain/layout-1000.csv`. Every layout is
`layout(ground, arm, seed, pins)`: there is no escarpment raising, and pads
are a model layer only.

Arms (all typed placement with 6 POIs and 3 benches, `spread` 2):
- `base`: round 9 rules;
- `bench6`: benches kept 6 hexes from each other;
- `wander0.5` and `wander1`: `bench6` plus route noise;
- `wander1-stretch1.5`: `wander1` with spanner stretch 1.5.

`regen` uses `wander1` and runs three stages per seed:
1. **fresh:** a first layout;
2. **partial:** the player at the first POI reached, with everything within 4
   hexes pinned;
3. **fear:** the player at the Fear, with only the player pinned and every node
   moved 2–4 hexes.

| | base | bench6 | wander0.5 | wander1 | wander1 stretch1.5 | regen partial | regen fear |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Benches together (boards) | 79% | 64% | 68% | 74% | 76% | 88% | 85% |
| Bench spur (boards) | 0.6% | 0.5% | 1.4% | 2.6% | 2.1% | 3.9% | 3.6% |
| Connection pass used (boards) | 27% | 28% | 35% | 52% | 52% | 52% | 50% |
| Teases held / placed | 1.84 / 1.96 | 1.84 / 1.96 | 1.77 / 1.96 | 1.60 / 1.96 | 1.60 / 1.96 | 1.36 / 1.86 | 1.51 / 1.85 |
| Trail edges | 151 | 153 | 159 | 168 | 169 | 175 | 160 |
| **Detour**, node pairs (median) | 1.51 | 1.51 | 1.55 | 1.62 | 1.61 | 1.63 | 1.64 |
| **Detour**, trail corners (median) | 1.44 | 1.43 | 1.47 | 1.50 | 1.53 | 1.61 | 1.51 |
| **Branches** (routes within 1.5×) | 1.17 | 1.17 | 1.17 | 1.15 | 1.16 | 1.17 | 1.16 |
| **Junctions per walk** to nearest pad | 0.51 | 0.50 | 0.58 | 0.70 | 0.73 | 0.93 | 0.69 |

Every arm: 100% connected, spawn on a loop on at least 98.9% of boards, no
dead ends, no errors. Pads move the playable ground by 0.02 edge lengths on
average.

**Regeneration** works as designed:
- partial regeneration joins about 4 ports per board, with no dead ends left at
  the pin boundary;
- 89% of the network outside the pin radius changes;
- nodes move 2.4–2.7 hexes on average.

Figures: `quell-hex-terrain/experiments/04-layers/arms-seed-{2,3,7}.png` and
`regen-seed-{2,3,7}.png`. Grey trails are pinned, and orange trails join
ports.

**Findings.**
1. **Natural teases are enough.** With no raising, 94% of placed teases hold
   at `base`.
2. **Lostness hardly moves.** Route noise adds wiggle (detour 1.51 → 1.62,
   junctions per walk 0.51 → 0.70). The structure stays efficient, though:
   between any two nodes there's essentially one good route (branches ≈ 1.15
   in every arm). The spanner and loop passes are built to avoid redundancy,
   so lostness needs a structural change, not just noise.
3. **Noise costs teases and pushes routes into the connection pass.** Noisy
   routes fail the tease guard more often, so the connection pass is used on
   52% of boards against 27%, and fewer teases hold (1.60 against 1.84).
4. **Bench spacing helps only a little** (79% → 64% of boards with benches
   together). The network is dense enough to join benches through junctions
   wherever they are. The rule needs a guard, or relaxing.

**Next candidates:**
- **forks:** unmarked side trails that leave and rejoin the network, giving
  real alternative routes;
- local loops in place of the spanner's efficiency rule;
- a softer bench rule.

## Results: forks (1000 seeds, 20 × 20)

Route noise is removed (designer, 2026-10-12). The bench-together rule is
dropped as a rule and kept as a statistic. Typed placement may make it
unnecessary.

**Forks** are unmarked side trails:
- each leaves the network at a plain trail corner (not a junction or pad) and
  rejoins it at another plain corner;
- both ends keep 3 edges from any junction or pad, so a fork reads as a fork,
  not clutter;
- `fork_reach` is the distance between the ends walking the existing network:
  10–30 edges makes a local loop, 30 or more a real alternative route;
- forks are laid after the loop passes and must pass the tease guard.

Tag `exp/05-forks`. CSV: `misc/hex-lab/results/terrain/layout-forks-1000.csv`. Figures:
`quell-hex-terrain/experiments/05-forks/`, now with tease arrows: red if the tease holds, grey with the
reason if not, labelled with walk ÷ crow-fly. Fork trails are green.

| | base | 4 local | 8 local | 4 far | 4 local + 4 far | regen partial | regen fear |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Forks laid | 0 | 2.5 | 3.0 | 4.0 | 8.0 | 2.8 | 2.8 |
| Trail edges | 151 | 177 | 182 | 208 | 248 | 188 | 172 |
| Independent loops | 5.3 | 7.8 | 8.4 | 9.4 | 13.5 | 10.4 | 7.8 |
| **Junctions per walk** to nearest pad | 0.51 | 0.61 | 0.63 | 0.88 | 1.07 | 0.87 | 0.63 |
| **Detour**, trail corners (median) | 1.44 | 1.45 | 1.45 | 1.97 | 1.94 | 1.54 | 1.45 |
| **Branches** (routes within 1.5×) | 1.17 | 1.18 | 1.18 | 1.21 | 1.22 | 1.19 | 1.18 |
| Teases held / placed | 1.84 / 1.96 | 1.85 / 1.96 | 1.85 / 1.96 | 1.84 / 1.96 | 1.84 / 1.96 | 1.52 / 1.82 | 1.73 / 1.86 |
| Connection pass used (boards) | 27% | 27% | 27% | 27% | 27% | 33% | 28% |
| Benches together (boards) | 79% | 80% | 80% | 96% | 98% | 91% | 90% |

The regeneration stages use 4 local forks.

**Findings.**
1. **Forks cost nothing in teases or connections.** The guard keeps teases
   intact, and connection-pass use is unchanged.
2. **Local forks are scarce.** Only 2.5–3 of 4–8 fit. A 10–30 edge reach with
   3 edges of clearance at both ends leaves few candidates on a 20 × 20 board.
3. **Far forks make the walk confusing.** Unmarked choices between
   neighbouring nodes double, from 0.51 to 1.07 per walk with 4 + 4. Walking
   between random trail points gets much longer (detour 1.44 → 1.94), because
   far forks are long side routes.
4. **"Branches" barely moves, and is the wrong measure for this.** It counts
   whole routes between node pairs that share no trail. A fork usually
   rejoins the same corridor, so it adds a choice, not a disjoint route.
   **Junctions per walk** is the better measure of "an unmarked fork in the
   path".
5. **Forks densify.** 4 + 4 forks bring the network to 248 trail edges for
   400 tiles, up 64%. Fewer spanner trails (a higher stretch) could make room
   for forks at similar density.

## Effect on the Rust port

Steps 1–4 stand. The rest of `quell-hex-terrain-plan.md` gets re-planned once
the experiment settles:
- the model and trail layers, plus routing over them, replace "teases and
  levelling";
- route noise and the lostness measures join the trails step;
- Fear regeneration becomes its own step after movement, since it needs the
  player's position.

## Decisions (2026-10-12)

1. **During a regeneration:** deferred. The leaning is that trails within a
   certain radius of the player stay fixed, nodes stay fixed, and only a Fear
   reshuffles fully.
2. **Displacement:** visited nodes move too, and nodes may swap places. Radius
   3–5 tiles for now, to tune later.
3. **The deck never changes.** Cards stay with their nodes.
4. **The trail layer** changes the ground's material, and grades it very
   slightly at most, never enough to change the topology. So routing can
   ignore it.
