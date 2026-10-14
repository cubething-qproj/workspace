# Hex paths: from terrain to a regenerating trail network

This story covers `feat/hex-paths` relative to `5d3fc8f`, including the staged first implementation and the unstaged review adjustments. The earlier commits establish the dev screen, orbit camera, height and cost views, typed node placement, billboards, and controls. The pending staged round replaces the noise terrain with regional erosion and brings in the round-11 layout algorithm. The unstaged round makes specific state and presentation corrections, identified by inline comments prefixed **Review delta**.

The design authority is `.docs/designs/quell-hex-terrain-r11-design.md`, including its post-round-11 fixes. The migration plan narrows this implementation to open ground; woodland density and player walking remain outside this pass. I searched the supplied Zed database read-only. It contains no thread titled “Heightmap pathfinding for hex paths,” or title containing “hex” or “height”; its newest record is October 7. I could not recover that thread's last message.

1. **Read the architecture as region → terrain → layout → preview.**

   `Region` is the large simulated landscape: a square raster of metre heights, a downhill receiver for each cell, and the area draining through each cell. `Terrain` is the selected board within that landscape: a hex mesh, immutable corner heights, traced creeks, suitability, and bench scores. `Layout` is a particular arrangement over that terrain: spawn, typed nodes, cards, levelled corner heights, blocked edges, trails, and tease pairs. `Board` is the Bevy resource that holds terrain and layout together with measurements and preview state.

   The geometry and layout routines operate on ordinary Rust data. They receive borrowed settings through `Context`, construct a result, and return it without spawning entities. `systems.rs` bridges that data into Bevy resources, meshes, billboards, and gizmos. This separation makes regeneration possible: it replaces `Layout` while retaining `Terrain`. It also lets the generator be tested without rendering.

   There are two height arrays with different meanings. `Terrain::heights` is the unmodified ground. Each layout clones it into `Layout::heights`, then levels pads and grades their surroundings. The preview draws the layout heights. Moving a location on regeneration begins again from the original terrain, so its former pad does not leave a permanent flattened scar. No pass raises an escarpment to manufacture a tease.

2. **Erode a region before choosing the playable board.**

   The default simulated region has 150 × 150 square cells, each 33 m across: `region_hexes = 100` is converted using the 1.5-edge spacing of hex columns. The initial surface combines a weak regional tilt, broad blurred rolls, and small roughness. Every boundary cell is an outlet held at zero; the interior rises by the uplift amount on each of 250 default passes. Uplift supplies relief against fixed outlets, allowing branching channels to develop inland.

   A pass first applies a **priority flood**. Imagine exploring inward from the lowest available boundary, always taking the lowest frontier cell next. A newly reached cell receives at least its original height and at least its predecessor's height plus a tiny epsilon. Consequently it has a strictly descending route back toward an outlet. In the actual code this raises depressions enough to drain; the “breach” wording describes the intended no-pond result rather than a separate channel-cutting operation.

   D8 routing then chooses the steepest descent among the eight neighbouring raster cells, accounting for the longer diagonal distance. Every cell starts with its own area, `33²` square metres. Processing cells from highest to lowest adds each accumulated area to its receiver. Because receivers are lower, upstream contributions arrive before a downstream cell forwards its total. A large area identifies a channel fed by many cells, rather than merely a low point.

   Stream power cuts cells above the channel-area threshold in proportion to the square root of drainage area and local slope. A floor above the receiver prevents the cut from reversing downhill flow. Four-neighbour slope creep smooths the resulting surface, and boundary outlets are reset. A final flood and routing pass produce consistent heights, receivers, and drainage areas for window selection.

   `RegionCache` retains the last simulation under a `RegionKey` containing its seed and physical settings. Reusing the same key avoids redoing erosion. Window selection uses a separate RNG stream seeded from `seed + 1`, so a cache hit does not change which random windows are examined. The cache holds one region and is cleared on screen unload. Generation is synchronous in this implementation; the cache does not make a first simulation asynchronous.

3. **Choose a board for play features, then translate water onto hexes.**

   `Window::choose` samples 60 default candidate positions and rotations that fit inside the region. Each candidate is scored for creek tiles, low-bank ford opportunities, natural views down to lower ground, a weak relief preference, and a penalty for river-sized flow. Candidate fords are on the same traced main creek that the board will display. Candidate tease spots are landscape opportunities; they do not guarantee that the eventual placed nodes will form usable teases.

   After selecting the highest score, the code samples the region bicubically into a finer board raster, with two samples per edge length. Raster sampling then supplies hex-corner heights. Region heights and candidate scoring use metres; board and layout heights use edge lengths. Dividing by 33 converts between them. The preview's vertical exaggeration is applied only when drawing and aiming; it does not steepen the routing terrain or lengthen the measured walk.

   Keep the two lattices distinct. **Trails use the honeycomb:** shared hex corners are vertices, and hex sides are possible trail edges. **Creeks use the dual lattice:** tile centres are vertices, and a creek links a tile to its downstream tile. A centre-to-centre creek link crosses their shared hex side. Closing that side removes the corresponding honeycomb trail edge. Water geometry therefore becomes a concrete routing constraint.

   Creek tracing follows regional channel cells whose drainage reaches the creek threshold. Cells are mapped into hex tiles, and downstream links follow the regional receiver chain until it enters another tile. Gap filling inserts intervening tiles when a channel passes near a hex corner. One tracing function supplies both candidate ranking and the chosen board, so the two agree on where water lies.

   The unstaged documentation records a margin exception: lookup skips points outside the jagged outer boundary instead of snapping them to the nearest available tile. A remaining link there can lack a shared side. The code's `shared_side` lookup then closes no trail edge. This is documented as an outer-scenery limitation; the review change adds explanation, not new tracing behaviour.

4. **Place landmarks where the network can reach them.**

   Spawn starts near the board's middle and moves onto nearby dry ground if necessary. Crossings are selected before other nodes because they determine which parts of the board can communicate. A union-find partitions playable corners under the currently closed creek edges: each edge that remains traversable joins its endpoint sets. The representative set of spawn provides a cheap reachability label for candidate node tiles.

   Crossing selection first joins substantial parts separated by the main creek, preferring lower banks. Additional crossings spread along viable main-creek sites, tending toward opposite ends. The port also filters spread candidates for at least two banks that open onto room for a node. After placement, a crossing is dropped if fewer than two banks lead to nodes, or if all useful banks collectively lead to only one other node. Dropping is iterative because one crossing can provide another crossing's route around a barrier. Required connectivity crossings can precede the requested count; the slider is not simply an exact output count. Setting crossings to zero is an explicit debug mode that ignores creek barriers.

   POIs prefer buildable ground: suitability decays exponentially with local height range, and `spread` sharpens that preference. A water factor pulls them toward creeks. Benches use a blend of quiet and overlook ranks computed among playable tiles. Raising each rank to the fourth power makes exceptional hollows and overlooks score much more strongly than middling sites.

   Placement is a weighted farthest-point choice: separation from existing pads, capped by a border-distance term, multiplies the site score and small seeded jitter. It attempts spacing and, during regeneration, the displacement annulus first. If no site fits, the code relaxes spacing and eventually displacement while retaining hard exclusions and avoiding occupied pads. Thus three-hex spacing and a two-to-four-hex move are preferences with fallback behaviour in this port.

   Nodes receive stable IDs and kinds at placement. A shuffled POI list receives Key, NPC, and Fear cards where there are enough POIs. Regeneration moves the existing `Node` values, preserving their IDs and cards. A completely fresh “New layout” calls placement without pins and deals its own deck; it differs from regenerating the current arrangement.

5. **Build useful routes while preserving the experience of a tease.**

   Dijkstra searches the corner graph. Each edge has a symmetric terrain cost `exp(aversion × |rise|)`; off-board and closed-creek edges have infinite cost. Starting the search from all six corners of a pad treats any entrance as usable. The existing trail network exposes only laid edges and gives pad perimeters an almost-zero plaza cost. This distinguishes the cheapest available terrain route from the walk imposed by the current trails.

   The greedy spanner sorts node pairs by direct terrain cost. It lays a connection when the existing trail walk exceeds twice the direct cost. Reusing a trail receives a 0.6 multiplier; running beside one without joining gets a 2.5 penalty. These weights encourage merging. A second scan revisits pairs rejected early, after other connections may have changed their context. A connection pass subsequently joins any nodes still unreachable from spawn, returning an error if no terrain route exists.

   A **tease** means “I can see that POI, but reaching it takes a substantial detour.” The first complete layout contains no teases and establishes walking order from spawn. A second build with the same seed uses that order to choose viewer/target pairs: the target is a POI reached later; visible pairs rank first, then larger natural drops up to 24 m, then shorter sight distance. Visibility samples the levelled triangular surface between a 1.5 m eye and a 4 m landmark. This port ranks visibility rather than making it a hard placement exclusion; `Board::held` separately reports pairs that both remain detours and are visible.

   Every candidate route passes through `lay`. It inserts only previously absent edges, recomputes broken teases, and rolls those new edges back if the guarded route increases their number. Existing edges remain intact. A tease breaks when its detour becomes too short or its target becomes reachable before its viewer. Direct tease-pair connections are also excluded from the spanner.

   Connectivity, banks, and ports may require an unguarded fallback. Such a route records the newly broken pairs in `broke`. The outer generator then disqualifies those pairs and rebuilds with the same seed, allowing replacement pairs to be selected. After the bounded retry count, remaining recorded broken pairs are removed from the advertised tease list. The review removes the separate chronological `laid` log; it keeps `broke` for retries and `breaking` for colouring the responsible edges.

6. **A useful loop must offer two independent ways onward.**

   The network contracts each pad's six corners into one graph vertex. Otherwise the perimeter of the pad itself could look like a meaningful loop. Tarjan's algorithm finds biconnected blocks in that graph. A pad qualifies as on a loop when it shares a block of at least three vertices with another pad. Within that block, two paths can connect the pads without sharing an intermediate vertex. Two exits that merge immediately into a single chokepoint do not qualify.

   The first loop pass attempts cheap connectors, normally no more than 18 edges and three times an existing link's cost. Spawn gets a special unlimited cost budget within that capped pass. The later no-tree pass removes length and cost limits while sparing tease targets. These are attempts under the tease guard, not unconditional promises that every node receives a loop.

   A loop connector cannot reuse trail edges and avoids the node's own spur plus a two-corner clearance. Candidate paths run from a pad toward trail corners or other pads; existing trail edges are impassable, encouraging a connector to rejoin rather than follow the trail. The return distance in the contracted graph plus the connector length must meet the minimum-loop size. These restrictions prevent a tiny finger beside a spur from masquerading as a useful alternate route.

   Finally, missing crossing-bank trails are joined to the nearest reachable trail or pad. The crossing's own perimeter is closed for this search so a proposed bank connection cannot just go around the pad to the opposite bank and claim success.

7. **Regeneration uses pins and repairs the seams.**

   A partial regeneration pins the player's tile, the node under the player, crossings, nearby nodes, and trail edges whose endpoints both lie within the radius. Movable nodes are placed again near their former locations. A Fear retains the player, the node underfoot, and crossings, while moving the other nodes and rebuilding trails. Standing on a crossing returns an error before regeneration proceeds.

   The same `Layout::generate` handles both cases. Pinned trails are installed first. Their degree-one ends away from pads become **ports**: seams where the preserved network was cut. `join_ports` routes each surviving seam to another trail or pad while excluding its own stub. It runs around the loop/bank passes so open ends can be connected to the completed network. Terrain remains unchanged throughout; pads are reconstructed from its original heights.

   Layout seeds combine the terrain seed with a monotonically increasing count. The UI increments that count only after successful layout replacement; failed regeneration reports an error and retains the previous layout. The unstaged `Board::regenerated` flag distinguishes a player-centred regeneration from a fresh layout even though both increment the count.

8. **The preview explains the result, and tests cover particular properties.**

   Screen loading creates the orbit camera, billboard assets, and settings panel. On readiness it requests generation. Chained screen-update systems build the board, rebuild its rendered surface and markers, paint revealed cards, fit the viewport beside the panel, handle focus and camera motion, and draw overlays. Surface triangles use a centre at the mean of each tile's corner heights. Trails retain their honeycomb geometry in the display; colours identify the pass that laid an edge. Crossings and creeks are blue, and Reveal also exposes tease lines.

   Height colours use absolute metre heights up to 120 m. Default height exaggeration is fourfold. The unstaged camera cache now includes that scale because changing it changes the world-space focus. `keep_focus` also validates a tile-based node focus after a new board or layout; if no node still occupies that tile, focus falls back to the player. This is tile membership validation, not stable-ID tracking of a moved node.

   Pace reporting uses the full Tobler speed curve in both directions, averages travel times, and applies a √3/2 length correction for the shorter trail that smoothing is expected to produce. That is a measurement approximation; this pass does not actually smooth the drawn trails. “Walk all” sums each trail edge once, whereas “farthest” searches the current network from spawn. Neither statistic proves a real player can traverse all trails in that time without retracing.

   Existing tests exercise downhill outlet drainage, growing downstream area, mesh sharing, creek adjacency, node reachability, two-sided crossings, absence of non-pad dead ends, regeneration preservation of crossings and cards, crossing refusal, invalid-setting board replacement, and UI camera restoration. Layout properties use a few small seeded worlds. The Bevy fixture steps selected schedules and calls unload directly, so it is not coverage of the complete rendered screen lifecycle. The unstaged fixture adds `HexPathsView` because `spawn_board` now requires it. This story authoring run adds explanatory artifacts and Crit comments; it does not change source, alter staging, or claim a fresh test run.
