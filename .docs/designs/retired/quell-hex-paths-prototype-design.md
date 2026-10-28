> Superseded by [`quell-hex-terrain-r11-design.md`](../quell-hex-terrain-r11-design.md) (generators, via `quell-hex-terrain-design.md`). The screen and walking shipped in quell #49 and #51.

# Quell hex paths prototype design

Status: **Approved by Ada on 2026-10-09. Implementation proceeds one step at a time.**

Before pushing: rebase and sign the unsigned step 1 commit `b094306`.

Source: handwritten notes 27-Sept-26 c.i, 7.Oct.26.a.i, 7.Oct.26.b (exploration /
traversal / overworld — "hiking in the woods").

## Goal

A dev screen in Quell that visualizes the hex path generation and lets a player
token walk it. Board generation settings and play-time view toggles are tweakable
Resources, edited from an in-screen `bevy_ui` / feathers debug panel.

In scope:

- Flat-top hex grid, configurable size (default 10 columns × 8 rows, i.e. the IRL
  "8×10").
- A spawn tile (its own tile, not a node; centered by default) and N **nodes**
  placed ahead of time with configurable minimum spacing.
- A node trait **deck** dealt onto the nodes at generation: guarantees one key
  location, one NPC, one Fear; remaining nodes are empty encounters. Counts configurable.
- Path tiles with 2 or 3 **spokes** (edge connections). Generation guarantees that
  spawn and every node are in one connected network, so the player can never
  softlock.
- Node locations are always visible, face-down, so the player has something to
  strive toward. Reaching a node flips its trait.
- Click-to-walk: the player walks tile by tile along spokes. Entering a tile
  reveals it.
- Play-time toggles to show all paths and to show face-down node traits.

Out of scope (later): Fear reshuffle, path reset on reaching a node, the sub-games,
any win condition, art.

## 1. Board model

Tiles are entities. Generation produces plain data (§3); a system spawns it.

| Type | Kind | Responsibility |
| --- | --- | --- |
| `HexPos(Hex)` | Component | Grid position of a tile or the player. |
| `Spokes` | Component | `bitflags` u8, one bit per hex edge (6 directions). |
| `TileKind` | Component | `Spawn \| Node(NodeTrait) \| Path`. |
| `NodeTrait` | enum | `KeyLocation \| Npc \| Fear \| Empty`. |
| `Revealed` | Component (marker) | Tile has been entered. Spawn starts revealed. A revealed node is flipped — no separate state. |
| `Board` | Resource | `HashMap<Hex, Entity>` index for neighbor lookup, grid bounds, `HexLayout`. Empty cells are absent. |
| `Player` | Component | Player token; carries `HexPos` and `Walk` (§5). |

Tile entities are `ScreenScoped` and despawned on regenerate.

**Crossing rule:** moving from `a` to neighbor `b` in direction `d` is legal iff
`a` has spoke `d` **and** `b` has spoke `-d`. A spoke with no partner is a dead end
(the ✕ in the sketch) or points off-map (the arrows). Backtracking is always
possible, so softlock ⇔ spawn and nodes are not in one connected component. The
generator guarantees they are.

Coordinates and geometry come from `hexx` 0.25 (glam 0.32, matches Bevy 0.19):
`Hex`, `EdgeDirection`, `HexLayout` for world positions and cursor → hex, hex
distance, and `algorithms::a_star` for click-to-walk routing. The grid is a
rectangle in offset coordinates.

## 2. Settings and view toggles

Two Resources, both `Reflect`:

`HexPathsSettings` — board generation. Changing it regenerates the board
(`resource_changed::<HexPathsSettings>`).

| Field | Default | Meaning |
| --- | --- | --- |
| `columns`, `rows` | 10, 8 | Grid size. |
| `seed` | `None` | `None`: fresh random seed every generation. `Some(n)`: pinned, same seed + settings ⇒ same board. |
| `spawn` | `Center` | `Center \| Random \| Fixed(Hex)`. |
| `deck` | key 1, NPC 1, Fear 1, empty 3 | Trait counts. Node count = deck size. |
| `min_node_distance` | 2 | Hex distance between any two nodes. |
| `min_spawn_distance` | 3 | Hex distance from spawn to any node. |
| `spawn_spokes` | 2..=3 | Spoke count range for the spawn tile. |
| `noise` | 2.0 | Amplitude of per-cell random cost in A*. 0 = shortest paths. |
| `shape_weights` | sharp 1, wide 1, straight 1 | Relative preference for 2-spoke shapes: 60°, 120°, 180°. |
| `junction_chance` | 0.25 | Chance a 2-spoke path tile is upgraded to 3 spokes (≈ the 3:1 deck). |
| `branch_length` | 1..=4 | Length range of side branches spawned by junctions. |
| `branch_join_chance` | 0.3 | Chance a branch connects into an adjacent path tile (loop) instead of ending in a dead end. |

`HexPathsView` — play-time. Changing it never regenerates.

| Field | Default | Meaning |
| --- | --- | --- |
| `show_paths` | false | Draw unrevealed tiles' spokes. |
| `show_node_traits` | false | Draw face-down nodes' traits. |
| `step_duration` | 0.5 s | Time to walk one tile (§5). |

Neither toggle affects routing: the player only plans with what they know.

A `BoardStats` Resource reports what generation actually produced: the seed used
(copy it into `seed` to pin a board you like), 2- vs 3-spoke counts, shape
counts, attempts, and any `GenError`. Shape weights and junction chance are
biases, not exact ratios — the stats make the real distribution visible.

## 3. Generation

`generate(&HexPathsSettings, &mut impl Rng) -> Result<BoardLayout, GenError>`
works on plain data — `BoardLayout` is a `HashMap<Hex, (TileKind, Spokes)>` plus
spawn — so the algorithm can be unit tested without an `App`. A
`spawn_board` system turns the layout into the components in §1. The ECS
representation is the source of truth at play time; `BoardLayout` is only the
generator's output.

### 3.1 Place spawn and nodes

Place spawn per `spawn`. Rejection-sample node cells uniformly from the grid,
rejecting any closer than `min_spawn_distance` to spawn or `min_node_distance` to
a placed node. Bounded retries; on failure return `GenError::Placement` (shown in
the debug panel) — settings that cannot fit are a user error, not something to
silently relax.

Shuffle the deck and deal one trait per node. Traits are fixed from here.

### 3.2 Backbone: noisy A*

Sample a cost field once per generation: each cell gets `1 + noise × rand()`.
Fixed per-cell costs (rather than per-step) give paths that share "easy ground",
which reads more like trails than per-step jitter.

Network = {spawn}. For each node in shuffled order, A* from the node to the nearest
**joinable** network cell:

- May step only through empty cells.
- May end at a `Path` tile with fewer than 3 spokes, at spawn if under
  `spawn_spokes.max`, or at a node (nodes have no spoke cap).
- Search state is `(Hex, incoming EdgeDirection)` so each step adds a turn cost
  derived from `shape_weights` (higher weight ⇒ cheaper bend). This is why the
  generator carries its own small A* (`BinaryHeap`, ~40 lines) instead of
  `hexx::algorithms::a_star`, whose cost callback only sees `(from, to)`.
- Heuristic: hex distance to the nearest network cell (admissible with min cost 1).

Commit the path: add mutual spokes along it. Interior cells get exactly 2 spokes;
the join cell gains one. Every tile stays within its cap by construction.

If a node has no route (walled in by capped tiles), retry the whole generation with
the next RNG draw, up to a bound, then `GenError::Unreachable`.

### 3.3 Spawn minimum

If spawn has fewer than `spawn_spokes.min` spokes, grow branches from spawn
(§3.4) until it does.

### 3.4 Decorate: junctions and branches

For each 2-spoke `Path` tile, with `junction_chance`, add a third spoke toward an
empty neighbor and grow a branch from it: a random walk of `branch_length` steps
through empty cells, choosing each turn by `shape_weights`. The branch ends:

- in a `Path` tile adjacent to its head with < 3 spokes, with
  `branch_join_chance` (makes a loop), or
- in a dangling spoke (dead end / off-map).

3-spoke shapes (Y, T, claw) fall out of the junction's neighbor choice; they have
no weights of their own.

Decoration only adds connections, so it cannot break the §3.2 guarantee.

Cells not touched by any of this stay empty.

## 4. Screen

New `HexPathsScreen` in `bin/quell/src/screen/dev/hex_paths/`, following
`camera_test`'s layout (`mod.rs`, `data.rs`, `screen.rs`). Its own `Camera2d`,
`ScreenScoped`.

Board rendering uses gizmos — the board is small and this is a visualization:

- every grid cell: hex outline;
- revealed (or `show_paths`) tiles: spokes as lines from center to edge midpoint,
  ✕ on spokes without a partner;
- nodes: always drawn; neutral when face-down, colored by trait when flipped (or
  `show_node_traits`);
- spawn and player: distinct markers;
- the player's current route: highlighted.

Debug panel: a `bevy_ui` side panel built from feathers controls (requires
enabling Bevy's `bevy_feathers` feature for quell):

- number inputs / sliders for `HexPathsSettings` fields;
- checkboxes for `HexPathsView` toggles, slider for `step_duration`;
- "Regenerate" button (re-runs generation with the current settings; with
  `seed: None` that is a new board);
- `BoardStats` as text.

The existing world inspector is unchanged.

## 5. Movement

Click a tile to walk there. A system maps the cursor to a hex via
`HexLayout::world_pos_to_hex` and sends a `WalkTo(Hex)` message. Clicks on the
debug panel are not forwarded.

**Routing** uses `hexx::algorithms::a_star` without noise. Cost of `a → b` is
`Some(1)` iff the crossing rule holds and the player knows `b` is reachable:

- `b` is revealed, or
- `b` is the destination and is entered across a connected spoke from a revealed
  tile (one step into the unknown).

So a route passes only through revealed tiles and may end one tile into the
frontier. No route ⇒ the click is ignored.

**Walking:** `Walk { route: VecDeque<Hex>, t: f32 }` on the player. The token
eases (ease-in-out) between tile centers, one tile per `step_duration`. On arrival
at each tile: update `HexPos`, insert `Revealed`. A new click during a walk
replaces the remaining route, replanned from the tile being entered, so the token
never stops mid-edge.

## 6. Testing

Unit tests in `src/` against `generate`, over a range of seeds:

- spawn and every node are connected under the crossing rule (BFS);
- `Path` tiles have 2–3 spokes; spawn within `spawn_spokes`;
- spacing constraints hold;
- dealt traits match the deck exactly;
- impossible settings return an error rather than panicking or looping.

Unit tests for routing: passes only through revealed tiles, may end one tile into
the frontier, refuses to cross a dangling spoke.

One fixture integration test in `tests/`, driven from `WalkTo` with explicit
schedule stepping via `q_test_harness`: a walk reveals each tile on arrival and
ends at the destination; an unreachable `WalkTo` leaves the player in place.
`q_test_harness` has mouse buttons but no cursor position, so the click → hex
mapping is not covered here; adding cursor input to the harness is a separate
change.

## 7. Dependencies

- `hexx = "0.25"` (default features).
- `rand` (version already in the lockfile) for seeded RNG.
- Bevy `bevy_feathers` feature.
- `bitflags` is already a dependency.

## 8. Implementation steps

1. Board model, settings, `generate` + unit tests.
2. Screen, board spawn, gizmo rendering, feathers debug panel, view toggles.
3. Click-to-walk: routing, eased walking, reveal, route highlight + tests.
