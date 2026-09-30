# feat: greybox movement playtest stage

Repo: `cubething-qproj/quell` · Labels: `enhancement` · Follows: #13 · Filed: #27

## Problem

The new kinematic player controller (#13) needs a playtest space for measuring physics responses and tuning movement feel. Automated tests cover correctness, not feel.

## Direction

- A single-level stage built from `assets/textures/GreyboxTextures/`. It has static geometry only, plus the normal player and tracking camera.
- **One grid cell = exactly 1 world unit on every face.**
  - Each grid texture holds 2×2 cells per 1024² image, so one texture repeat = 2 m.
  - Bevy's `Cuboid` mesh maps every face to the full 0..1 UV range, so a single `uv_transform` can't be right on all faces of a non-cubic box. Instead, rewrite `ATTRIBUTE_UV_0` from local vertex positions, projected along each face's normal and divided by 2 m. Use a repeating sampler.
  - Place geometry with `Transform` translation and rotation only, never scale, so local units stay metres.
- Course rows:

  | Area | Measures | Geometry |
  | --- | --- | --- |
  | Floor + speed lane | top speed, input ramp, stop distance, turn rate | large grid floor; long straight lane in a contrasting grid |
  | Ramps | slope policy around `max_slope` | 10°, 20°, 30°, 40°, 44°, 46°, 50°, 60°; green grid if ≤ `max_slope`, red if steeper |
  | Steps | capsule step-up limit | ledges 0.05, 0.1, 0.15, 0.2, 0.3, 0.5 m |
  | Drops | ground snap vs. falling | edges dropping 0.1, 0.2, 0.5, 2 m |
  | Walls | sliding and stability | straight wall, V-corner, narrow corridor |

- Live HUD showing horizontal and vertical speed, height, and grounded state. Showing grounded state means adding a `grounded` field to `PlayerMotor`.
- How it's delivered is open: a `dev`-feature screen like `camera_test`, or a single-level example binary once Quell exposes a library (see #25).

## Acceptance

- The stage launches with a single command.
- Every textured surface reads as 1 m cells.
- The HUD shows live speed, height and grounded state.
