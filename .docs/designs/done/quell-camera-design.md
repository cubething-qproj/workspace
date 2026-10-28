# Quell camera design

Status: **Approved by Ada on 2026-09-24, with the two review clarifications below incorporated. Implementation remains one individually approved slice at a time.**

Review clarifications:

- Assign the player's colliders to `CollisionLayer::Player`; preserve their intended physical interactions while excluding them from camera obstruction queries.
- Deprecate `AppSettings.use_physics`. Do not build the camera architecture around a permanent application-wide physics toggle. Address the setting's migration separately from the initial free-camera slice.

Primary issue: [Quell #15](https://github.com/cubething-qproj/quell/issues/15). WorldScreen setup ([#16](https://github.com/cubething-qproj/quell/issues/16)) follows camera acceptance and is not part of this design's implementation scope.

## Goal

Provide two usable camera modes:

- **Free:** Bevy 0.19's developer free camera.
- **Tracking:** a local third-person orbit camera with an **Unreal-style spring arm**: maintain a desired distance from the target, retract when obstructed, and extend again when clear.

CameraTestScreen must make switching and the current mode obvious. Exactly one **gameplay** camera renders and owns camera input. The existing UI camera remains the unchanged overlay on top.

Use Bevy's maintained implementation for flight. Keep tracking local to Quell, drawing on common patterns and ecosystem implementations without adding `bevy_enhanced_camera` as a dependency. Consider crate extraction only after the local behavior works. Preserve licensing and attribution if source is adapted.

## 1. Entities and authoritative state

Retain two camera entities in CameraTestScreen so each preserves its view when switching. WorldScreen has only its tracking camera. This needs no camera registry, index resource, or generic controller hierarchy.

| Entity | Components / responsibility |
| --- | --- |
| Tracking camera | `Camera3d`, `Camera`, `Transform`, local `SpringArm`, Enhanced Input actions/context, existing render layers, `ScreenScoped` |
| Free camera, `dev` only | `Camera3d`, `Camera`, upstream `FreeCamera` and `FreeCameraState`, existing render layers, `ScreenScoped` |
| Camera controls | Existing cursor-capture context, with capture/release and a test-screen-only switch action; a small capture-reset latch for focus/mode transitions |
| Camera help | Screen-scoped UI text showing the selected camera, switch shortcut, and that mode's controls; rendered by the existing UI camera |

**`Camera::is_active` is the authoritative gameplay selection.** Identify the mode by its controller component (`SpringArm` or `FreeCamera`). Input-enabled flags are derived from selection, focus, and capture; they are not independent mode state. The HUD reads the same selection rather than storing its own mode.

Both gameplay cameras are unparented roots without transform children. The player is referenced as a target, not made the camera's parent. UI is a separate hierarchy; the existing camera light may remain a component on the camera entity. This constraint makes the final camera-transform update small and explicit; parented camera rigs are out of scope.

### Local `SpringArm` data

| Field | Meaning |
| --- | --- |
| `target: Entity` | Entity whose world position the camera follows |
| `target_offset: Vec3` | World-space offset from that entity to the orbit pivot; independent of player yaw |
| `length: f32` | Desired, unobstructed distance from pivot to camera center |
| `probe_radius: f32` | Sphere used to keep the camera away from world geometry |

The camera's `Transform.rotation` owns orbit orientation. Do not duplicate it in a separate yaw/pitch resource. Orbit input reads yaw/pitch, applies the delta and pitch limit, then writes the rotation.

Initial tuning: retain the existing nominal distance of `10.0` and pitch range; start with a `0.3` collision probe and `0.02` surface clearance. The target offset is configured at spawn for the player or test target. These are initial tuning values, not a claim that gameplay feel is already validated.

There is no stored current arm length in the first implementation: recompute the resolved camera position every frame. No lag, physical joint, or simulated spring is needed to get spring-arm collision behavior.

## 2. Tracking and orbit behavior

For each tracking camera:

1. Read the target's current world transform.
2. Compute the pivot `P = target_world_position + target_offset`.
3. Let `D` be the camera rotation's unit **back** direction (`+Z` in camera space), and `L` the nonnegative desired arm length.
4. The unobstructed camera center is `P + D * L`.
5. Resolve obstruction along that arm, as described below.
6. Write the resulting translation while preserving the orbit rotation.

The camera already faces back toward the pivot by construction. Do not call `look_at` at zero arm length, and do not derive next frame's desired distance from a previously shortened arm.

Follow runs regardless of cursor capture. Inactive tracking may continue to follow, but receives no orbit/zoom input. A missing target causes the solver to skip that camera safely; screen lifecycle owns teardown, not an implicit target replacement.

### Tracking input and player integration

Reuse the existing Enhanced Input rotation/zoom actions, with `SpringArm` as the camera input context rather than the obsolete generic `CameraController`.

- Mouse movement adjusts yaw/pitch with a sensitivity multiplier; do **not** multiply mouse delta by frame time.
- Right stick adjusts yaw/pitch with deadzone and a degrees/radians-per-second scale multiplied by frame time.
- Clamp pitch to the configured range. Keep roll at zero.
- Preserve the existing **FOV zoom** behavior and bounds initially. Mouse wheel changes perspective FOV; right stick is for orbit, not simultaneous zoom. Changing wheel behavior to arm-length zoom is a separate decision.
- Orbit/zoom requires selected Tracking mode, window focus, and capture. Action observers recheck those conditions so an already-evaluated action cannot modify a camera after a mode switch.
- Player movement remains camera-relative, using the tracking camera's yaw. Disable player input when Free is selected, and clear pending movement/desired motion at handoff. This does not pause physics or disable gravity. Preserve the current movement-with-cursor-released behavior when Tracking is selected and the window is focused.

## 3. Spring-arm collision

The requested behavior is a **spring arm**, not a requirement to retain a mathematical ray. Use a **sphere sweep** through the existing Avian 0.7 spatial-query API. This gives clearance around the camera, unlike a centerline-only ray.

### Query and result

Use an immediate `SpatialQuery::cast_shape` or `cast_shape_predicate` query:

- Shape: `Collider::sphere(probe_radius)`.
- Origin: pivot `P`.
- Rotation: identity; sphere orientation is irrelevant.
- Direction: unit direction `D`.
- Maximum distance: the **full desired arm length `L`**.
- `ShapeCastConfig::from_max_distance(L).with_target_distance(0.02)`.
- Keep origin-penetration detection enabled (`ignore_origin_penetration = false`).

If there is no accepted hit, use `L`. Otherwise use `hit.distance` clamped to `[0, L]`. The camera center becomes `P + D * resolved_distance`.

**Avian's hit distance is the travel of the sphere center**, not the distance to a surface witness. Do not subtract the probe radius again, shorten the query to `L - radius`, or place the camera at `point1`/`point2`. The probe radius and configured target distance already provide clearance.

Retract and extend immediately in the initial version—equivalent to a spring arm with camera lag disabled. If recovery smoothing is later desired, review it separately; it must never interpolate the camera through a newly encountered obstruction.

### Filtering

- Query intended solid world geometry, not the player or the camera itself.
- Exclude the target entity and the target body's collider entities, using `RigidBodyColliders` where applicable. Avian entity exclusions apply to collider entities, not automatically to an entire body hierarchy.
- Exclude sensors via the query predicate or an explicitly verified sensor-layer policy. Sensors are not automatically omitted by immediate casts.
- Assign `CollisionLayer::Player` membership explicitly to the player's colliders as part of spring-arm filtering, preserving the collision filters needed for player/world interaction. Verify compound/body collider membership rather than assuming root membership covers every collider. Keep target/body exclusions for non-player tracking targets as well.

No `RayCaster`/`RayHits` entity and no physical camera rigid body are needed. The query result is consumed in the same camera update, eliminating the unfinished previous-frame raycaster path.

### Edge behavior and limits

- Zero or negligible arm length: place the camera at the pivot and skip the sweep. Retain rotation; never normalize a zero displacement.
- Initial overlap: conservatively retract to the pivot on a zero-distance blocking hit. This is not depenetration and cannot guarantee a clear view if the pivot itself is embedded in world geometry.
- Physics setup: deprecate `AppSettings.use_physics`; collision-enabled gameplay requires the physics plugins. Until that migration is implemented, guard collision-system registration against absent physics resources as a compatibility constraint, not a permanent camera mode. Test orbit math independently, and install physics explicitly in collision integration tests.
- Validate finite, nonnegative length and a positive probe radius at configuration boundaries.
- A finite sphere is not automatically a guarantee of near-plane clearance for every FOV/aspect ratio. Test corners and wide FOV; tune the probe before considering a more elaborate clearance model.

## 4. Free camera and input ownership

Enable Bevy's `free_camera` feature through Quell's `dev` feature and register `FreeCameraPlugin`. Remove the custom fly movement/rotation code rather than run it alongside Bevy's controller.

Keep upstream controls: WASD, Q/E vertical movement, Shift speed, wheel speed adjustment, **RMB held** or **M toggled** for cursor capture. Add Quell's Escape-release and screen/focus handling. Free flight intentionally ignores collisions; only the tracking camera gets the spring arm.

### Rendering and input are separate

`Camera::is_active = false` stops that camera rendering. It does **not** stop Bevy's `run_freecamera_controller` from reading raw input, moving the transform, or changing the cursor when `FreeCameraState.enabled` is true. Enhanced Input consumption also does not suppress those raw inputs.

A small adapter therefore derives `FreeCameraState.enabled` from selection/focus/capture. A selected, focused free camera can also enable on a fresh upstream capture gesture so the upstream system sees that press. Once capture is released, disable movement and clear residual velocity/snap animation. Do not copy input resources or synthesize mouse/key presses.

The controller's cursor-toggle flags are private system-local state. Let the upstream controller run while disabled so it clears those flags; merely hiding the cursor or skipping its system is insufficient. A newly spawned/re-entered free camera gets a disabled controller tick before accepting capture, preventing stale toggle state across screen lifecycles.

## 5. Switching, cursor lifecycle, and UI

CameraTestScreen starts in Free mode while it is the basic test surface. Once Tracking is implemented, **Tab** switches between the two. Register the toggle as an edge-triggered Enhanced Input action with reset-on-activation, on the test screen's controls rather than a new console command.

The switch operation, completed before Bevy's free-camera update:

1. Release cursor capture and make the cursor visible.
2. Disable outgoing camera input; clear free-camera velocity/snap animation and pending player movement.
3. Set the outgoing gameplay `Camera::is_active` false and incoming one true. Never change the UI camera.
4. Leave input uncaptured in the incoming mode. Require a fresh capture gesture; a held mouse/key across the switch must not recapture automatically.
5. Update the help text from the actual active camera.

Keep the two poses independently. Switching does not teleport Free to Tracking or change the tracking orbit. Despawning inactive cameras remains a possible simplification later, but is not necessary for this two-camera design; it would additionally require capture cleanup and an explicit pose-restoration policy.

The cursor-capture context owns a small reset latch: focus loss, Escape release, or a mode/screen transition disarms capture until the relevant capture controls have been released. High-priority release/switch controls remain available while per-camera input is disabled.

- **Free capture:** upstream RMB/M behavior.
- **Tracking capture:** existing left click.
- **Escape while captured:** release only, not quit on the same action.
- **Escape while already released:** preserve existing quit behavior.
- **Focus loss / screen transition:** release and reset before camera teardown; focus regain does not recapture automatically.

Keep Escape precedence explicit between existing global quit and cursor-release handling; do not rely on unordered observers. Apply mode changes and input gates before the upstream free-camera system; guard tracking action observers against stale events as well.

Example HUD:

> Camera: Free · Tab: switch to Tracking  
> RMB: hold capture · M: toggle capture · Esc: release  
> WASD: move · Q/E: down/up · Shift: faster · Wheel: speed

Tracking shows its own capture, orbit, and FOV-zoom help. The HUD is screen-scoped, not an additional camera or a new persistent global menu. Do not change the existing UI camera's projection, layering, or lifecycle. Verify its existing overlay composition in the smoke test; report any separate compositing defect rather than silently redesigning it.

## 6. System ordering

Do not keep final tracking resolution in `ScreenSchedule::Update`: q_screens currently has no screen-level `PostUpdate`, and ordering labels do not order systems across different schedules.

| Phase | Responsibility |
| --- | --- |
| `PreUpdate`, after Bevy `InputSystems`, before Enhanced Input evaluation | Process focus/reset state and establish initial camera input gates. |
| Enhanced Input `Update` / `Apply` | Evaluate control actions and tracking orbit/zoom. Process switch/release; observers validate current ownership. |
| `RunFixedMainLoop`, before `run_freecamera_controller` | Finalize Free enablement after control actions; admit only a fresh allowed capture gesture or existing capture. |
| Upstream `FreeCameraPlugin` | Run flight/cursor handling and snap rotation in its normal before-fixed-loop placement. |
| Fixed gameplay / Avian physics | Simulate player/world; Avian's default `FixedPostUpdate` performs preparation, simulation, and transform writeback. |
| Main `PostUpdate`, after `TransformSystems::Propagate` | Compute tracking pivot and desired pose, then resolve spring-arm collision using current target globals and the physics query world. |
| Before `VisibilitySystems::UpdateFrusta` | Synchronize the solved root camera's `GlobalTransform` so frustum culling and rendering see this frame's camera pose. |

Use two small local sets for the final work: solve tracking/spring arm, then synchronize the camera transform. Because the camera is an unparented, childless root, targeted `GlobalTransform` synchronization suffices; do not add a second full-world propagation pass. Assert/test that hierarchy constraint rather than silently relying on it.

Share the desired-pose calculation between focused orbit tests and the collision-enabled runtime; do not maintain two orbit implementations. Deprecating `AppSettings.use_physics` also requires reviewing its test-only default and the conditional plugin setup in `src/service/third_party.rs`. Plan that migration explicitly before removing the guard for absent physics resources; it is not part of the first free-camera slice.

**Physics-query freshness:** Avian's immediate queries use its collider positions and spatial trees, not arbitrary render transforms changed later in `Update`. Physical moving obstacles must update in fixed gameplay before physics preparation. Rendering interpolation does not interpolate the query world. Test this boundary rather than claiming that immediate queries make all transforms automatically current.

## 7. Changes to the existing code

Paths below are relative to `bin/quell/`.

| Area | Intended change |
| --- | --- |
| `Cargo.toml` | Enable `bevy/free_camera` under `dev`; no third-party camera dependency. |
| `src/service/input/camera/fly/` | Keep a thin bundle/plugin adapter; remove `FlyCam` and custom flight observers. |
| `src/service/input/camera/tracking/` | Replace unfinished tracking data/math with `SpringArm`, orbit input, and same-frame follow/collision. Keep rewritten functions in their existing files where practical. |
| `src/service/input/camera/controller/`, `camera/data/` | Remove obsolete `CameraController`, kind/insert hooks, `ActiveCamera` index, broken tracking relationships, and fly-only actions. Retain useful render-layer/order definitions and tracking actions. |
| `src/service/input/cursor/`, `input/events.rs` | Replace custom-controller queries with explicit mode/capture handling; preserve deterministic Escape/quit behavior. |
| `src/screen/dev/camera_test/` | Spawn both modes and screen-scoped help/switch controls; make the test target/obstacle colliders match the visible geometry for meaningful collision checks. |
| `src/service/player/` | Spawn the local tracking camera, update its yaw/input integration, and assign/verify `Player` collider membership for spring-arm filtering; no unrelated controller tuning. |
| `src/plugin.rs`, `src/service/third_party.rs` | Separately scope deprecation of `AppSettings.use_physics`, including plugin initialization and test setup. Do not expand the first free-camera slice to include this migration. |
| `src/service/dev/gizmos/` | Update obsolete camera queries to upstream Free / local SpringArm; no new visualization framework. |
| `src/screen/world/screen.rs` | Only necessary API/scheduling call-site updates for the camera replacement. Visibility/context setup remains #16. |
| `src/service/ui/mod.rs` | **Leave unchanged.** Reuse its overlay for the new help text. |

## 8. Tests and implementation slices

Focused tests should cover:

- Exactly one active gameplay camera, with the UI camera still active; HUD selection matches rendering/input selection.
- Inactive cameras ignore input; switching clears pending movement and does not recapture held controls.
- RMB/M capture, tracking click capture, Escape release without simultaneous quit, focus loss/regain, and screen cleanup/re-entry—including upstream private cursor state across camera replacement.
- Following a moving target without cursor capture; pitch limits, frame-independent input scaling, and camera-relative player movement.
- Unobstructed arm length, a blocking wall, corner clearance, player/body-collider and sensor exclusion, zero length, initial overlap, and arm extension after clearing an obstruction. Assert `Player` membership and that player/world collisions still work.
- Same-frame target/camera transforms, frustum-update ordering, and fixed-step moving obstacles. Test desired-pose math without physics and collision behavior with explicit physics plugins; preserve compatibility tests only while the deprecated setting remains supported.
- Default and `dev` builds. Real-window checks remain necessary for actual cursor capture, UI composition, and collision feel.

Implement only the individually approved slice, then stop with its diff, focused validation, and independent reviewer findings:

1. **Free-camera baseline:** upstream controller, capture/reset adapter, and basic help in CameraTestScreen; no working Tracking mode advertised yet.
2. **Local tracking and switching:** orbit/follow data and math, player call sites, Tab selection and mode-specific HUD; collision explicitly incomplete.
3. **Spring-arm obstruction:** sphere sweep, filtering, edge cases, and end-to-end camera acceptance.
4. **Separate #16 work:** WorldScreen visibility and scoped context setup, only after camera acceptance.

Run LSP diagnostics after code changes. Run `just check -p quell` and `just test -p quell` from the organization root with bounded runtimes. Do not automatically apply reviewer suggestions, start the next slice, create branches, or commit.

## Sources and validation status

- [Bevy 0.19.1 free-camera implementation](https://github.com/bevyengine/bevy/blob/v0.19.1/crates/bevy_camera_controller/src/free_camera.rs)
- [Avian 0.7 `SpatialQuery`](https://docs.rs/avian3d/0.7.0/avian3d/spatial_query/struct.SpatialQuery.html)
- [Avian 0.7 `ShapeCastConfig`](https://docs.rs/avian3d/0.7.0/avian3d/spatial_query/struct.ShapeCastConfig.html)
- [Avian 0.7 `ShapeHitData`](https://docs.rs/avian3d/0.7.0/avian3d/spatial_query/struct.ShapeHitData.html)
- [Enhanced Camera reference implementation](https://github.com/jayhwkns/bevy_enhanced_camera/blob/v0.5.0/src/lib.rs), reference only—not a proposed dependency.

The design is based on Quell/q_screens code, installed Bevy 0.19.1 / Enhanced Input 0.26 / Avian 0.7 sources, and upstream free-camera source. No replacement code has been written, compiled, or runtime-validated for this design. Numerical tuning and platform cursor behavior remain to be tested.
