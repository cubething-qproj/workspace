# fix: explicit ScreenScoped should win over registered persistent types

Repo: `cubething-qproj/q_screens` · Labels: `enhancement` · Follows: #36 · Filed: #37

## Problem

Since #36, a registered persistent type exempts every entity that has it from screen cleanup, even when the entity is explicitly `ScreenScoped`. An app therefore can't scope an individual entity of a registered type to a screen.

The concrete case is pointers. With the `bevy_picking` feature, `PointerId` is registered as `Anywhere`, so app-spawned `PointerId::Custom` pointers (virtual cursors, render-to-texture UI, gamepad-driven cursors) now outlive every screen, with no way to opt them back in. Type-level registration can't tell the engine's `Mouse`/`Touch` pointers apart from custom ones, because they are variants of one component.

## Direction

- Make an explicit `ScreenScoped` override a registered persistent type: the cleanup query exempts registered types only for entities without `ScreenScoped`.
- Engine entities never carry `ScreenScoped`, so the engine seeds are unaffected. Check `HierarchyPropagatePlugin<ScreenScoped>` interactions: propagation only reaches entities under an app hierarchy that opted in.
- Flip the "registered type overrides ScreenScoped" case in `tests/screens/persistent_types.rs`, and update the `persistent` module docs, the README pointer note and design §2.

## Acceptance

- An entity with a registered type and `ScreenScoped` is despawned on screen change; without `ScreenScoped` it survives.
- An app can spawn `(PointerId::Custom(..), ScreenScoped)` and have it cleaned up with the screen.
