# Quell kinematic player controller design

Status: **Approved by Ada on 2026-09-27.** Implementation proceeds one approved slice at a time (§7). Round-1 answers are incorporated: §0 is confirmed, the §2 tuning placeholders and the §3 SmoothNudge-only acceleration are accepted, physics gating is removed (§4), and test 2 is kept (§6). In round 2, the playtest stage moved to a follow-up PR. In round 3, the follow-up issue drafts moved to `.docs/issues/` (§8).

Primary issue: [Quell #13](https://github.com/cubething-qproj/quell/issues/13) — replace Tnua with Avian move-and-slide.

## Summary

Replace `bevy-tnua` + `bevy-tnua-avian3d` with a **small local kinematic controller built directly on Avian 0.7's `MoveAndSlide` system parameter**. Do **not** adopt `bevy_ahoy`. Add no new dependencies. Keep the existing `PAMove` input mapping, the camera-yaw-relative intent code, and the focus/camera-selection clearing semantics; change only what they write into.

## 0. Finding: the current Tnua controller never runs

Before choosing what to "preserve", note what the current controller actually does. The following is verified against the `bevy-tnua 0.32.0` source, and **Ada confirmed in-game that nothing moves the character today.**

- `apply_controller_system` queries `&TnuaConfig<S>` (`bevy-tnua-0.32.0/src/controller.rs:609`). Quell never inserts a `TnuaConfig`, and `git log --all -S TnuaConfig` finds nothing. **Tnua skips the player entirely.**
- So the player today is a dynamic capsule that falls, rests on the ground, and never moves. The inputs flow through `PlayerTnuaController.basis`, but nothing reads them.
- If Tnua *had* run, it would not have behaved as intended:
  - `desired_motion` is scaled by `config.speed` (`builtins/walk.rs:315`, default `20`). Quell already bakes `default_speed = 10` into it, so the target speed would have been 200 m/s.
  - `float_height` defaults to `0`, so the ground sensor (cast range `float_height + cling_distance = 1.0` from the capsule's center, which is 2.0 above its bottom) would never have reached the ground.

**Implication:** there is no tuned movement feel to preserve. The only existing movement constant is `PlayerSettings::default_speed = 10`. Under this design it becomes the literal target ground speed in m/s. No existing constant values change.

## 1. Decision: local controller vs. `bevy_ahoy`

| | Local on `MoveAndSlide` | `bevy_ahoy 0.2` |
| --- | --- | --- |
| New deps | none (Avian already present) | `bevy_ahoy` (`default-features = false` to drop `avian_pickup`) |
| Movement model | whatever Quell needs; start trivial | Quake/Source friction and air acceleration, **always on**. The README's non-goals exclude disabling air strafing. |
| Input | reuse `PAMove` magnitude (analog stick, `SmoothNudge` ramp) | normalizes the wish direction and multiplies by `cfg.speed` (`kcc.rs:1529-1548`), so analog magnitude is lost unless `speed` is rewritten every tick |
| Facing | we own it (Tnua's `desired_forward` equivalent) | never rotates the body. We'd write facing anyway. |
| Camera | ours (`q_cam` spring arm) | optional first-person camera plugin, to be disabled |
| Collider | keep capsule | README recommends a cylinder. All examples use one. |
| Config surface | a few `PlayerSettings` fields | ~50 `CharacterController` fields |
| Code in play | ~150 lines | ~1,638-line `kcc.rs`. About half is crane, mantle, tac, water and crouch, which we'd never trigger. |

Ahoy is a good *reference* but a poor *dependency* for a third-person, non-FPS game: we would fight its movement model, input normalization and camera assumptions, and still write facing ourselves. If Quell later needs Source-style stair stepping, port `step_move` / `snap_to_ground` from Ahoy (MIT/Apache-2.0) with attribution rather than taking the dependency.

## 2. Components and data

### Player entity (changes to `spawn_player_root`)

| Remove | Add / keep |
| --- | --- |
| `RigidBody::Dynamic` | `RigidBody::Kinematic` (via `PlayerMotor`'s `#[require]`) |
| `LockedAxes::ROTATION_LOCKED.unlock_rotation_y()` | `CustomPositionIntegration` (required): only move-and-slide moves the body |
| `Friction::ZERO` | `SpeculativeMargin(0.)` (required): no speculative contact impulses from the kinematic body, as in Avian's example |
| `PlayerTnuaController` | `TransformInterpolation` (required). Movement is now fixed-rate `Transform` writes that the tracking camera follows. |
| `TnuaAvian3dSensorShape(...)` | `PlayerMotor::default()` |
| | keep the `Collider::capsule(...)` and `CollisionLayers::new(CollisionLayer::Player, LayerMask::ALL)`, and all input components/actions unchanged |

`LockedAxes` and `Friction` only affect dynamic bodies, so they become dead weight.

### `PlayerMotor` (replaces `PlayerTnuaController`)

```rust
/// Movement intent consumed by the fixed-step controller.
#[derive(Component, Default)]
#[require(RigidBody::Kinematic, CustomPositionIntegration, SpeculativeMargin(0.), TransformInterpolation)]
pub struct PlayerMotor {
    /// World-space horizontal velocity to walk at, m/s.
    pub desired_velocity: Vec3,
    /// Facing to turn toward; `None` keeps the current facing.
    pub desired_forward: Option<Dir3>,
}
```

This is a 1:1 replacement for the two `basis` fields Quell uses today (`desired_motion`, `desired_forward`). The call sites change mechanically:

- `update_controller` (`service/player/systems.rs`)
- `sync_contexts` (`service/input/cursor/events.rs`)
- two tests (`service/player/events.rs`, `screen/dev/camera_test/screen.rs`)

**Velocity state lives in Avian's `LinearVelocity`.** This follows Avian's examples and is valid with `CustomPositionIntegration`. It lets vertical (falling) velocity persist across ticks without extra state, and keeps the existing `LinearVelocity.y` resting assertion meaningful.

Grounding state is *not* stored on a component in this pass, because nothing outside the controller reads it. If animation or jump needs it later, add a `Grounded` marker then.

### New `PlayerSettings` fields

These are new tuning values, not changes to existing ones. Ada accepted the initial values as placeholders to tune:

| Field | Initial | Meaning |
| --- | --- | --- |
| `max_slope: f32` | `45°` (radians) | Steepest walkable surface. Avian's example uses 30°, Ahoy 40°. |
| `ground_snap: f32` | `0.2` | Distance of the downward ground probe and snap after each move |
| `turn_speed: f32` | `10.` rad/s | Facing slew rate; the same as Tnua's `turning_angvel` default |

Gravity comes from Avian's existing `Gravity` resource, so there is no new constant. Kinematic bodies don't receive gravity from Avian, so the controller applies it itself.

## 3. Movement semantics (explicit decisions)

One system, `move_player`, runs per fixed tick for each `PlayerMotor`:

1. **Horizontal velocity** = `desired_velocity`, assigned directly with no separate acceleration model. BEI's existing `SmoothNudge` on `PAMove` already ramps the input, so adding an acceleration curve now would stack two smoothers. Clearing intent (focus loss, camera switch) stops the player immediately, matching what the existing tests assert.
2. **Vertical velocity:** if grounded, `0`. Otherwise it accumulates `Gravity * dt`. There is no terminal velocity in this pass (deferred).
3. **Move:** `MoveAndSlide::move_and_slide` with the player's collider, `LinearVelocity`, and `Time::delta()`.
   - Filter: `SpatialQueryFilter::from_mask(layers.filters).with_excluded_entities([entity])`. `MoveAndSlide` already skips `Sensor` colliders.
   - When grounded, seed `MoveAndSlideConfig::planes` with the ground normal. Avian's docs recommend this, and it stops walking from pushing into the floor.
4. **Ground probe and snap:** `MoveAndSlide::cast_move` down by `ground_snap`.
   - A hit whose normal is within `max_slope` of up means **grounded**. Translate down to the hit, which snaps onto downslopes and small step-downs.
   - Anything else means airborne.
5. Write `Transform.translation` and `LinearVelocity` (the projected velocity; vertical part zeroed when grounded).
6. **Facing:** slew `Transform.rotation` toward `desired_forward` about Y at `turn_speed`. Keep the current `-velocity` forward convention from `update_controller`.

| Topic | Decision |
| --- | --- |
| **Grounding** | Downward shape cast of the player collider by `ground_snap` after each move; walkable if the normal is within `max_slope`. |
| **Slopes** | Walkable (≤ `max_slope`): walk up and down, snapped, with no sliding while idle, because vertical velocity is zeroed when grounded. Steep (> `max_slope`): in the `on_hit` callback, while grounded, flatten a steep upward-facing hit normal to horizontal so it acts as a wall and can't be climbed by pushing into it. While airborne, accept hits unmodified, so the player slides off steep slopes under gravity. |
| **Steps** | **No explicit step-up in this pass.** The capsule's rounded base rides over ledges up to roughly `r·(1 − cos max_slope)`, about 0.15 m at r = 0.5 and 45°. Step-down up to `ground_snap` via the snap. Quell's worlds are currently half-spaces and cuboids, so no content needs stairs yet. Revisit with a ported Ahoy `step_move` when it does. |
| **Moving surfaces** | **Not supported.** Nothing in Quell moves. There is no platform-velocity inheritance; a moving platform would slide out from under the player. |
| **Dynamic bodies** | Out of scope. The kinematic player isn't pushed by dynamic bodies. Any push the player gives them is incidental Avian contact response, not tuned. No `apply_forces_to_dynamic_bodies`. |

## 4. Scheduling

- **Input (unchanged):** the `on_move` observer and `update_controller` in the screen's `Update` (`player_systems()`). `update_controller` now writes `PlayerMotor` instead of the Tnua basis. It runs in the same place as today, so intent reaches the next fixed tick exactly as it did with Tnua.
- **Movement:** `move_player` in `FixedUpdate`, in the existing (currently unused) `PlayerSystems` set. Tnua ran in `FixedUpdate`, and Avian's examples put move-and-slide there. Avian's physics step runs afterwards in `FixedPostUpdate`.
- **Physics is always enabled; the gate is removed.**
  - Delete `AppSettings.use_physics` (`plugin.rs`). It is only `false` under `cfg(test)`, and no `src/` test builds `AppPlugin`.
  - `third_party::plugin` always adds `PhysicsPlugins`.
  - `player::plugin` registers `move_player` unconditionally.
  - A "dev mode" freeze, if wanted later, pauses `Time` rather than omitting physics. That is not built here.
  - The one fixture that adds `player::plugin` without physics is the input fixture in `service/player/events.rs`. It gains `TransformPlugin`, `Assets<Mesh>`, `AssetEvent<Mesh>` and `PhysicsPlugins`, the same boilerplate the existing physics tests use, because `MoveAndSlide` requires Avian's spatial-query resources.
  - **Scope note:** this goes slightly beyond #13. It is the prerequisite for registering `move_player` without a gate, so it lands as its own first commit (slice 0) to keep the diff reviewable.

## 5. Dependencies and documentation

- **Remove** `bevy-tnua` and `bevy-tnua-avian3d` from `bin/quell/Cargo.toml`, `bevy_tnua::prelude::*` from `third_party.rs`, both Tnua plugins, `PlayerControlScheme`, and `PlayerTnuaController`.
- **Add nothing.** `MoveAndSlide` is gated on avian3d's `default-collider` + `parry-f32` (`avian3d-0.7.0/src/lib.rs:508-512`), which Quell's default `avian3d = "0.7"` already enables.
- **Avian feature trimming is out of scope.** Quell uses avian3d's default features. Trimming them (debug-plugin, picking, scene, …) is a separate `chore/` if wanted.
- **Documentation:** a module doc comment on the new movement module records the decision table in §3 and the "why not Ahoy" line. A one-line comment in `Cargo.toml` notes that the controller needs avian3d's `parry-f32`/`default-collider`. There is no separate doc file.

## 6. Tests

Scope is kept minimal. There are no tests on tuning constants.

- **Update:** `spawned_player_keeps_world_contacts_with_player_membership` (`service/player/events.rs`). Drop the `TnuaAvian3dSensorShape` assertion. The fall-and-rest-on-half-space assertion (height ≈ resting height, `LinearVelocity.y ≈ 0`) is exactly the new grounding and gravity behavior, so keep it.
- **Update mechanically:** `desired_motion()` in the events fixture, and the camera-test handoff test, move to `PlayerMotor` fields.
- **New integration test** `bin/quell/tests/player_movement.rs`, with a small local `Fixture` (`service::player` is made `pub` so the test can install `player::plugin`): `App` with `MinimalPlugins`, `TransformPlugin`, `PhysicsPlugins` and the player plugin, manual fixed timestep, `player: Entity`. Behaviors:
  1. **Walks and is stopped by a wall.** On a half-space floor, set `PlayerMotor.desired_velocity` toward a static cuboid. The player advances, stops short of the wall (never overlaps it), and stays at resting height.
  2. **Slope policy** (kept per review; playtesting in §8 is the real feel check). From rest, pushing into a gentle ramp (well under `max_slope`) climbs it. Pushing into a steep ramp (well over) does not gain height. Ramp angles are chosen relative to `max_slope` rather than hard-coded, so the test isn't a constant detector.
- Physics tests step with `app.update()` and manual time, as the existing physics test does. They don't use a partial schedule, since the controller's correctness depends on `FixedUpdate` → `FixedPostUpdate` ordering.

## 7. Implementation slices

0. **Remove physics gating:** delete `AppSettings.use_physics` and always add `PhysicsPlugins` (§4). This is independent of the controller.
1. **Kinematic walk, Tnua removed:**
   - Add `PlayerMotor`, the settings fields and `move_player` with gravity, move-and-slide, ground snap and facing.
   - Update the spawn, `update_controller`, `sync_contexts` and existing tests.
   - Remove the Tnua deps.
   - Add test 1.
   
   This must be one slice, because the Tnua types are referenced across modules and tests.
2. **Slope policy:** the steep-normal flattening and ground-plane seeding, plus test 2.

Each slice goes through a crit story review, then a subagent review, then a commit.

## 8. Phase 2: greybox playtest stage (follow-up PR)

**Out of this PR.** Per review, the greybox playtest stage ships as a **follow-up PR** tracked by its own issue. This PR delivers slices 0–2 and the automated tests in §6, which satisfy #13's "focused test" acceptance item.

## Follow-up issue drafts

Drafts live in `.docs/issues/` and are filed on `cubething-qproj/quell`:

- [`quell-greybox-movement-stage.md`](issues/quell-greybox-movement-stage.md) → #27: the playtest stage, 1 m grid UVs, live HUD with grounded state
- [`quell-bevy-ui-tuning-panel.md`](issues/quell-bevy-ui-tuning-panel.md) → #26: a hover-aware `bevy_ui` settings panel
- [`quell-library-examples.md`](issues/quell-library-examples.md) → #25: expose Quell as a library so single-level stages can be example binaries
