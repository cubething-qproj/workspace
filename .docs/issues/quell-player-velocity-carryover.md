# feat: carry player velocity between ticks

Repo: `cubething-qproj/quell` · Labels: `enhancement` · Follows: #13 · Filed: #37

## Problem

`move_player` stores only the vertical part of the projected velocity between fixed ticks. Horizontal velocity is overwritten each tick by `PlayerMotor::desired_velocity`. As a result:

- Sliding down a steep slope is a slow crawl that depends on the timestep. Each steep contact scales the carried vertical speed by sin²θ, so it converges to about tan²θ·g·Δt: roughly 0.2 m/s at 50° and 0.9 m/s at 67.5° at 64 Hz. It never accelerates.
- There is no momentum. Leaving a ledge or being deflected by a surface doesn't carry over into the next tick.

## Direction

- Decide which parts of the projected velocity persist: at least the slide tangent while airborne on steep surfaces, possibly horizontal momentum while airborne generally.
- Decide how player intent blends with carried velocity: acceleration and air control. `SmoothNudge` currently does all the ramping.
- Tune on the greybox stage (#27).

## Acceptance

- Steep-slope slides accelerate under gravity, and their speed doesn't depend on the fixed timestep.
- Grounded walking feel is unchanged unless deliberately retuned.
