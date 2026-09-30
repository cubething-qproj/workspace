# feat: plain third-person follow camera

Repo: `cubething-qproj/quell` · Labels: `enhancement` · Filed: #35

## Problem

The spring-arm camera snaps hard toward the player whenever anything is in the line of sight. q_cam's `SpringArm` sphere-casts from the pivot every frame and puts the camera exactly at the hit distance, with no smoothing (`lib/q_cam/src/tracking.rs`). Near walls, ramps and corridors this makes the camera jump in and out constantly, which is very noticeable in the greybox stage (#27).

## Direction

- Replace the spring arm with a plain third-person camera: orbit around the player at a fixed distance, keeping the existing orbit and zoom input. Nothing pulls it in.
- Geometry between the camera and the player is handled by dithering it (#36), not by moving the camera.
- Distance, pivot offset and any follow smoothing are tweakable through a `Resource`.
- Decide where it lives: a new camera in `q_cam` next to `SpringArm`, or Quell-local. `SpringArm` can stay in `q_cam` for other users.
- Out of scope: collision avoidance, auto-framing, lock-on.

## Acceptance

- Walking along walls, up ramps and through the 1.2 m corridor in the greybox stage never moves the camera toward the player.
- Orbit and zoom behave as they do now.
