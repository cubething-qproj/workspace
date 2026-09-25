# Quell camera basics, local tracking, and deferred world setup

Status: **Proposal only — implementation requires approval, one step at a time.**

Issues, in order: [#15](https://github.com/cubething-qproj/quell/issues/15), then [#16](https://github.com/cubething-qproj/quell/issues/16).

## Scope and working agreement

Focus on basic camera behavior first: Bevy's developer free camera, a small local tracking implementation, and clear mode switching. Defer WorldScreen setup (#16) until the camera work (#15) is accepted. Keep this separate from q_os/console integration and PR #19 (#17/#14).

Do not change source, dependencies, branches, or commits until the corresponding step is approved. After each implementation step, show the diff, validation results, and an independent reviewer report, then stop. Do not apply reviewer suggestions or start the next step automatically. Approval of this proposal does not authorize executing the whole sequence.

The initial implementation edits were reverted; Quell's working tree is clean at `b0b2870` when this proposal was written.

## What the investigation established

- WorldScreen spawns the player and world but not the global or cursor-capture contexts used by CameraTestScreen.
- The generated world root is `Visibility::Hidden`. Its mesh child explicitly uses `Visibility::Visible`, which overrides ancestor visibility in Bevy; changing the root alone is not proof that a rendering defect is fixed.
- Player movement bindings already exist. Camera-relative movement currently depends on the custom tracking camera.
- The tracking update requires a `Single` raycaster query, but the raycaster spawn is commented out. Its update therefore cannot run normally.
- CameraTestScreen creates two active camera controllers; ownership and cursor routing are incomplete.
- A persistent UI camera is also active. It remains the overlay rendered on top, unchanged. The single-camera ownership rule applies to the gameplay view, not this UI pass.

## Camera direction after review

| Role | Direction | Reason / boundary |
| --- | --- | --- |
| Developer flight | **Bevy 0.19 `FreeCameraPlugin` / `FreeCamera`**, approved in review | First-party implementation; remove local flight math. Keep upstream RMB-hold / M-toggle capture controls, with Escape release. |
| Third-person follow | **Keep the implementation local to Quell; rewrite as needed** | Use familiar orbit/target-follow and raycast-obstruction patterns. `bevy_enhanced_camera` is useful reference material, not a new runtime dependency. Its small maintainer base is an additional maintenance risk. |
| Later reuse | Possible extraction into a separate crate | Only after the local behavior is working and its boundaries are clear. No crate extraction, published fork, or general camera framework in this change. |

The ecosystem survey remains useful, but compatibility alone does not justify adopting a dependency. Enhanced Camera 0.5 matches Bevy 0.19 / Enhanced Input 0.26 / Avian 0.7; PanOrbit 0.35.1 is a more established orbit option but still needs follow/collision adapters. Neither is proposed as a dependency now. If implementation code is adapted from another project rather than independently written, verify its license and retain required attribution/notices.

### Input, rendering, and UI contract

- Free and tracking modes must be switchable in CameraTestScreen. Propose **Tab** to toggle them, with a persistent-on-that-screen label such as **“Camera: Free · Tab: switch to Tracking”** and mode-specific control help. The label reflects the actual selected camera; a hidden shortcut alone is not sufficient. No new console integration.
- Keep upstream free-camera capture controls: **hold RMB** or **toggle M**. Tracking retains **left-click capture**. **Escape releases capture in both modes**; it must not also quit on that same action. Existing quit behavior can remain available once released.
- Exactly **one gameplay camera** renders and owns movement/rotation input at a time. The existing **UI camera remains the overlay on top, unchanged**, and displays the camera label/help. Do not disable, replace, or repurpose it to enforce the gameplay-camera invariant.
- Losing focus, changing screens, or changing modes releases capture and clears stale controller motion. Inactive cameras do not respond to input, and switching must not replay held input as a fresh action.
- Tracking continues to follow its target while cursor input is released; capture gates input, not target following.

### Clarification: rendering is not controller enablement

`Camera::is_active = false` **does stop that camera rendering**. The earlier wording did not mean that an inactive camera retains the display.

The separate issue is in Bevy's upstream `run_freecamera_controller`: it queries camera entities without testing `Camera::is_active`, reads raw input, and changes transforms/cursor state when `FreeCameraState.enabled` is true. Enhanced Input consumption does not suppress those raw inputs. This is upstream behavior, not Quell's custom controller.

The minimal option is to coordinate rendering with the controller's enabled state. **Despawning the inactive camera is also valid** if that makes switching simpler; release capture before teardown and explicitly handle any pose restoration. Do not invent another ownership framework merely to retain inactive entities. Whichever approach is chosen must pass the same switching/input tests.

## Proposed sequence — stop for approval after every step

### 1. Basic developer free camera — #15

Adopt Bevy's feature-gated free camera in CameraTestScreen and delete the custom fly implementation it replaces. Establish one active gameplay view plus the unchanged UI overlay. Add a small Free-camera control label and verify movement, mouse look, capture/release, and focus/screen cleanup.

This first checkpoint may exercise only Free mode; do not advertise switching to a working tracking camera until step 2 delivers it. Leave tracking internals and WorldScreen visibility/context setup alone. Any shared call-site changes must be limited to keeping this replacement coherent.

**Checkpoint:** show the basic camera diff, focused tests, real-window results or blockers, and reviewer findings. Stop. Do not start tracking automatically.

### 2. Local tracking basics and visible switching — #15

Rewrite the unfinished tracking implementation locally as needed. Keep a clear target/pivot, yaw and pitch, and desired boom distance. Compute the camera pose from those values and the current target transform rather than accumulating position corrections. Keep camera-relative player movement coherent; avoid unrelated player-controller changes.

Enable Free/Tracking selection and the actual-mode label, toggle-key hint, and mode-specific capture help described above. Validate exactly one gameplay renderer/input owner and the unchanged UI overlay. Remove replaced tracking/controller machinery instead of leaving parallel implementations. Update required call sites without doing #16 setup work yet.

Follow must see current target transforms after physics, and the resulting camera transform must reach rendering in the same frame. Verify ordering, including camera children, before introducing any extra propagation pass.

Collision is explicitly not complete at this checkpoint; use an unobstructed test scene to verify following, orbiting, switching, and input isolation first.

**Checkpoint:** show the local follow/switching diff and validation. Stop before adding obstruction handling.

### 3. Raycast-style obstruction handling — #15

Retain the intended raycast-style tracking behavior, not necessarily the old implementation. Use the existing Avian query facilities and common camera-boom patterns:

- Compute the desired unobstructed camera position from the pivot/orbit each frame.
- Cast from the target pivot toward that position over the full desired boom length, excluding the target/player and camera itself.
- Shorten the boom to the nearest obstruction with a small standoff; derive the unobstructed length afresh so the camera returns when the obstruction disappears.
- Define and test zero-length casts, near/embedded starts, target exclusion, and entering/leaving an obstruction. Avoid stale previous-frame hits driving the current camera pose.

A single ray protects the boom's centerline, **not the entire camera near plane**. Document that limit. Only propose extra clearance probes, a volume cast, or recovery smoothing separately if the basic raycast tests or visual checks show a need; do not silently turn this into a larger controller rewrite.

**Checkpoint:** show collision tests and visual results for both retained modes, including switching/cursor regression checks. Stop; #15 acceptance requires all of the camera steps, not only the basic free camera.

### 4. Complete WorldScreen setup — #16, after camera acceptance

Only:

- Make the generated world root visible.
- Spawn global and cursor-capture contexts in WorldScreen's one-shot ready initialization, not its repeating loading loop.
- Mark both context entities `ScreenScoped`, consistent with player/world ownership.
- Test visibility, context creation, and cleanup/re-entry without duplicate contexts.
- Verify actual movement, capture/release, and quit behavior from WorldScreen using the accepted camera implementation.

Do not add another camera replacement, new bindings/dependencies, or unrelated movement/physics repairs here. Default cleanup already removes nonpersistent entities; explicit scope markers document ownership rather than introduce a new cleanup mechanism.

**Checkpoint:** present this separate, small WorldScreen diff and end-to-end validation, then stop.

## Verification for each approved implementation step

- Start with focused tests and LSP diagnostics; include default and `dev` configurations where relevant.
- Run required `just check -p quell` and `just test -p quell` from the **organization root**, with bounded command runtimes. Report blocked or timed-out validation as incomplete.
- Obtain an ad-hoc reviewer report and show its findings before acting on them.
- Use a bounded real-window smoke test for actual visibility, cursor behavior, camera handoff, movement, and collision. Headless tests alone cannot establish OS capture or visual correctness.
- Do not create branches, commit, push, or close issues without instruction. The current branch is still the branch used by PR #19; branch placement needs a decision before any future commit.

## Research references

- [Bevy 0.19.1 free-camera implementation](https://github.com/bevyengine/bevy/blob/v0.19.1/crates/bevy_camera_controller/src/free_camera.rs)
- [Enhanced Camera 0.5 implementation](https://github.com/jayhwkns/bevy_enhanced_camera/blob/v0.5.0/src/lib.rs)
- [Enhanced Camera dependencies](https://crates.io/api/v1/crates/bevy_enhanced_camera/0.5.0/dependencies)
- [PanOrbit Camera](https://github.com/Plonq/bevy_panorbit_camera)
- [Third Person Camera 2](https://github.com/Hattiffnat/bevy_third_person_camera_2)

Compatibility and API behavior were investigated from source and release metadata. No replacement was compiled, tested, or runtime-validated. This document records the revised design direction only; source implementation remains paused pending approval of the next individual step.
