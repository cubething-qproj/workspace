# refactor: expose Quell as a library for single-level example binaries

Repo: `cubething-qproj/quell` · Labels: `enhancement` · Filed: #25

## Problem

Single-level stages (camera test, the planned greybox movement stage) live as `dev`-feature screens inside the main binary. They are launched with `--screen <name>`, which means building the whole game and its screen flow just to open one level.

`bin/quell/src/lib.rs` already exports `AppPlugin`, `AppSettings` and a prelude, but there is no supported way to compose a subset of Quell into a standalone binary.

## Direction

- Define a library surface that an example can use to build an app with Quell's services (physics, input, player, cameras) and one stage, without the splash/world screen flow.
- Move single-level stages to `examples/` (e.g. `cargo run --example camera_test`), each of which composes that surface.
- Decide what happens to `dev` screens and the `--screen` CLI: keep them, or replace them with examples.
- Keep tests working. Existing fixtures build partial apps from service plugins, and that should get easier, not harder.

## Acceptance

- At least one existing stage (camera test) runs as an example binary.
- The library surface it uses is documented.
- The main binary's behavior is unchanged.
