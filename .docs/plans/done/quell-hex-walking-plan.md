# Quell hex paths: walking the generated trails

Status: proposed, 2026-10-13. Follows PR #49 and the retained
[step 9](quell-hex-terrain-plan.md#9-vertex-to-vertex-movement) of the terrain
plan. The round-11 migration supplies the terrain and layout; this pass makes
that layout walkable in the dev screen.

Each step below is one commit. Review and manually try each working slice
before proceeding. Start a `feat/hex-walking` branch from the PR #49 tip;
while that PR is open, use its branch as the base for the walking PR. Retarget
the walking PR to `main` after #49 merges, rebasing only the walking commits
onto the merged result if #49 is squash-merged.

## Scope and ownership

Keep `Region`, `Terrain`, and `Layout` generation unchanged. Add a small
`walking/` module with components in `data.rs`, event handlers and update
systems in `systems.rs`, and plugin registration in `mod.rs`. Pure route and
movement calculations stay beside their owning types. Use the existing
Dijkstra implementation through a narrow layout method rather than exposing
its internal search representation or writing another pathfinder.

A separate screen-scoped player entity owns `Walk`: its current corner,
active edge/progress, and remaining route. It uses the existing player
billboard and shared facing system. Landmark rebuilds must leave this entity
alone. Walking must not mutate `Board` each frame: that would trigger mesh
and marker rebuilds.

A settings Resource exposes sight radius, simulation speed, and any movement
parameters that need adjustment. Existing terrain and layout constants stay
unchanged. A walking-mode control distinguishes local exploration from the
existing whole-board inspection view.

## 1. Click a trail destination and walk to it

Commit: `feat(hex-paths): walk between trail corners`.

- Enter walking mode at a spawn-pad corner connected to the laid network.
  Keep the spawn landmark and moving player as separate entities.
- Make the terrain surface pickable and attach a primary-pointer observer.
  Filter hits to the preview camera; marker presses retain click-to-focus.
  Convert the hit's world position to the nearest eligible corner in the
  horizontal board plane.
- Route over laid trail edges and pad perimeters. Pad perimeters are needed
  to connect entrances on different sides of the same pad. For physical
  walking they have ordinary traversal costs, unlike the generator's
  nearly free plaza edges. Other terrain edges remain impassable.
- Reuse the existing symmetric terrain weights for path selection. Animate
  the route using directional Tobler speed and true edge lengths, with
  heights interpolated along each edge of the levelled surface. Preview
  exaggeration changes the displayed height, not the travel time. The
  statistics' smoothing correction does not shorten these unsmoothed walks.
- Consume elapsed time across as many edges as necessary. A destination
  selected during an edge takes effect at the next corner. An unreachable
  destination leaves the existing route intact.

Risk: medium. Search paths currently come back in reverse order, pad
perimeters have special generator costs, and frame time can span multiple
legs. Outcome: a visible player can follow the complete inspection network.

Verify route continuity and exclusion of non-network edges on a small
hand-authored graph. Check that splitting the same elapsed time into different
frame sizes produces the same endpoint/progress. Manually check picking,
panel occlusion, height draping, and pace.

## 2. Discover trails and reveal nodes on arrival

Commit: `feat(hex-paths): discover trails and reveal visited nodes`.

- Track visible and previously walked trail edges separately from the
  generated layout. Define local sight in horizontal edge-length units;
  an edge becomes known when any part enters the sight radius. Traversed
  edges remain known after leaving that radius.
- In walking mode, draw and route over currently visible or walked edges.
  A globally nearby corner can belong to a disconnected known fragment;
  it still needs a reachable route before accepting the request.
- Reveal a node when the player actually reaches one of its pad corners.
  Track revealed landmarks by stable node ID, not array position or tile.
  Crossings have no card to reveal. Visiting a Fear reveals its card in
  this slice; automatic regeneration comes in the regeneration follow-up.
- Apply marker images on spawn and through discovery/view events, retaining
  the existing Reveal control as an inspection override. The override
  changes presentation, not what the walker knows or can route through.
- Show distant unvisited landmarks only in the inspection view; in walking
  mode, local sight determines their presence. Terrain visibility and the
  existing sight-line model are unchanged.

Risk: medium. The inspector currently knows the entire layout. Display state
must not accidentally grant route knowledge, and visiting a pad must not
require traversing an arbitrary pad centre. Outcome: exploring reveals trails
and landmarks without granting a complete route map.

Check that hidden edges cannot complete a requested route, arriving reveals
the matching stable ID, and walking an edge preserves its visibility after
moving away. Manually check forks and approaching a landmark from different
pad entrances.

## 3. Follow the player and handle screen/layout changes

Commit: `feat(hex-paths): follow walking state and reset exploration safely`.

- Resolve Player camera focus from the moving player, while Terrain and Node
  focus retain their inspection meanings. Camera follow translates the orbit
  centre without repeatedly resetting zoom or orientation. Orbit and zoom
  use the same moving anchor.
- Keep the player alive through view changes, Reveal updates, and appearance
  rebuilds. Reproject its current position when exaggeration changes.
- Disable full regeneration and layout-replacement controls while walking
  mode is active. Leaving that mode discards the walking session and restores
  the inspection controls; entering again starts at the current layout's
  spawn. This gives the first walking PR an explicit boundary around the
  existing focus-based regeneration tools.
- Remove walking state on screen unload. If the board is absent, movement
  skips safely; invalid indices never carry into a new board or layout.
  External settings edits or layout replacements also discard the walking
  session, even when they bypass disabled panel controls.

Risk: medium. Camera motion and observer-driven presentation share ordering
requirements, and indices belong to a particular mesh/layout. Outcome:
walking can be inspected and restarted without stale routes or accidental
player despawns.

Use the existing small fixture and `q_test_harness` for focused mechanics.
Include a screen-lifecycle integration check for player cleanup and re-entry;
selected Update tests alone do not cover those transitions. Manually verify
orbiting while moving, view/reveal changes mid-route, and screen re-entry.

## Regeneration follow-up

The current `Pins::player` and `Layout::regenerate` accept a tile, whereas the
walker occupies a corner or a point on an edge. Regeneration also currently
uses camera focus as a stand-in for the player. Integrating real walking needs
a separate decision about preserving that exact position, anchoring the new
network there, handling an active leg, and refusing a crossing underfoot.
It must preserve revealed node IDs through partial/Fear regeneration while
clearing knowledge of replaced trails. Plan that change after trying walking;
nearest-tile conversion alone would hide a change in player position.

## Validation and review

Keep tests small and check behaviours rather than exact generated paths or
constant values. Run `just check -p quell` and `just test -p quell` from the
org root before each commit. Document the new type relationships, events,
and pipeline connections in source. Ask the designer to playtest each slice;
do not launch `just play` or a Crit server automatically.

Smoothing, woodland, background generation, and card gameplay remain separate
work. Manual pacing feedback should guide the next change before adding them.
