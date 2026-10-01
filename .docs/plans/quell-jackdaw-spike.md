# Quell × Jackdaw spike

Status: **in progress**. Branch `feat/jackdaw-spike` in `bin/quell`, based on
`origin/main` at #28. Goal: evaluate Jackdaw for greyboxing (quell#27). The
alternative, `bevy_skein`, is parked on `feat/bevy-skein` (local commit
`bb59268`, not pushed).

Reference: `.agents/skills/jackdaw/` (skill) and `.docs/reference/jackdaw/`
(vendored docs).

## Setup so far

- `jd` 0.19.0 installed via `cargo +nightly-2026-03-05 install --git ... jackdaw --locked`.
- `bin/quell` was imported directly, which produced:
  - `jackdaw.toml` with `plugin = "AppPlugin"`
  - `.jackdaw/`, gitignored through `.gitignore`
  - an empty `assets/scenes/`

  None of this is committed yet.
- `jd doctor --project bin/quell` passes. Ada ran the first editor build
  (`jd build`), and it works. Before `dev` was dropped, it lacked the dev
  features, which confirmed that the editor builds only default features.
- `bin/quell/.jackdaw/shim/` is left over from an earlier release-bundle
  Jackdaw, whose model differed. The current `jd` doesn't use it, and it's safe
  to delete.

## Decisions

- **The `dev` feature is dropped; dev tooling is unconditional.** The editor
  builds the plain package with no feature selection, so everything the editor
  or Play should see is in the default build. That later includes
  `jackdaw_runtime/pie`.
  - The argument parser (`clap`), `q_term`, `bevy-inspector-egui`, `built`,
    `q_cam/free_camera`, and the dev screens and services now always compile.
  - Because the parser runs before the app is built, it now accepts
    `--jackdaw-extract-schema` as a hidden, ignored flag, so the editor's
    schema run isn't rejected.
- **Scenes are spawned by screens.** A `JackdawSceneRoot` spawned in a
  screen's setup is scoped to that screen, like everything else; the screen
  owns its lifecycle. This is not a conflict.
- **Accept the editor's game build.** The editor runs its own `cargo build` of
  the plain package into `bin/quell/.jackdaw/target/game`. That's a second
  full build (disk and time), inside the repo, not `/tmp`. The docs say runs
  never build and there's no feature or bin selection
  (`book/reference/configuration.md`, `book/user-guide/play-in-editor.md`).
  Cargo config can't select features either. So the only lever is what's in
  the default build.

## Findings

### Toolchain

The org pins the same nightly as Jackdaw, `nightly-2026-03-05`, in
`rust-toolchain.toml`. The editor builds the game with the project's own
toolchain (it strips an inherited `RUSTUP_TOOLCHAIN`), so both use one
compiler. Only the editor binary and in-process editor extensions require
that nightly. `jackdaw_runtime` uses no `#![feature]`.

### Native (C/C++) dependencies

This was traced from Jackdaw's `Cargo.lock` at `068303b`.

- **cmake is needed by the editor only.**
  - `manifold-csg-sys`: the C++ Manifold mesh-boolean kernel behind brush CSG
    (`jackdaw -> jackdaw_csg -> manifold-csg-sys`).
  - `aws-lc-sys`: AWS-LC crypto for TLS
    (`jackdaw -> ehttp -> ureq -> rustls -> aws-lc-rs -> aws-lc-sys`), used by
    the editor's HTTP client.

  Neither reaches `jackdaw_runtime`.
- **New native code on the game side:** `basis-universal-sys`, a C++ library
  built with `cc`, so it needs a C++ compiler but not cmake. It comes from
  `jackdaw_runtime`'s default `render` feature enabling `bevy/basis-universal`,
  which is used for textures imported through Bevy's `CompressedImageSaver`.
  Quell doesn't have it today. The runtime's other native dependencies
  (`blake3`, `tikv-jemalloc-sys`, `wayland-backend`) are already in the org
  lockfile.

### Wiring differences from the game template

These live in `main.rs` and haven't been done yet.

1. Wrap `DefaultPlugins` with `jackdaw_runtime::maybe_windowless`. Without it,
   only Windowed Play works.
2. Add `jackdaw_runtime::JackdawPlugin` in `main.rs`, not in `AppPlugin`. It
   needs the render and asset plugins, and `MinimalPlugins` test fixtures
   don't have them.
3. Decide on the image sampler. The template sets a global `Repeat` sampler so
   tiled brush textures don't smear. Quell uses Bevy's default,
   `ClampToEdge`.
4. Keep `PhysicsPlugins` in exactly one place. It's currently inside
   `AppPlugin` (`service/third_party.rs`), while the template adds it in
   `main.rs`. Either works; adding it in both panics.
5. `jackdaw.toml`'s `plugin` key is informational (it's what `jd doctor`
   checks). Play runs Quell's own binary.

### Integration work

- **Player spawn:** an authored `PlayerSpawn` marker plus an `On<Insert,
  PlayerSpawn>` observer, instead of a hard-coded spawn at the origin at
  resting height.
- **Floor:** the worldgen half-space floor would coexist with authored
  geometry, or be replaced by it.
- **Colliders:**
  - Authored brushes use `AvianCollider` + `RigidBody::Static` (the runtime's
    `physics` feature).
  - The default `CollisionLayers` puts them on `CollisionLayer::Default`, so
    they collide with the player and block the spring arm, same as today's
    floor.
  - Watch for trimesh internal-edge snags with the kinematic controller.
- **Dependency:** `jackdaw_runtime` 0.19 is on git only. crates.io has 0.4.1,
  which targets Bevy 0.18. Pin a revision.
- **Bevy features:** the runtime turns on, for every build including tests:
  - `reflect_functions`, `reflect_documentation`, `serialize`
  - with default features: `basis-universal`, `compressed_image_saver`, and
    `experimental_pbr_pcss` (through `soft_shadows`)
  - with `pie`: `mesh_picking`

### Checked: not conflicts

- **Windowless Play:** it spawns a virtual `PrimaryWindow` with
  `CursorOptions`. The editor forwards focus into `Window::focused` and mirrors
  `grab_mode` back, so Quell's window, focus and cursor-lock gates keep
  working.
- **Cameras:** Quell's persistent `IsDefaultUiCamera` is respected, and
  window-targeted cameras are retargeted to the capture image.
- **Avian features:** Jackdaw's (`3d`, `parry-f32`, `collider-from-mesh`) are
  a subset of Quell's defaults.
- **Behaviour note, Esc:** in embedded Play, plain Esc is forwarded to the
  game. Quell's second Esc exits the app, which ends the Play session.
  `Shift+Esc` releases input capture instead.

## Next steps

1. ~~Wire `main.rs` and add the pinned `jackdaw_runtime` git dependency.~~
   Done:
   - `jackdaw_runtime` is pinned to `rev = e3e5772`, the installed editor's
     commit, with the `physics` and `pie` features.
   - `main.rs` adds `maybe_windowless(DefaultPlugins)`, `AppPlugin`, then
     `JackdawPlugin`.
   - `PlayerMotor` and `PlayerController` are reflected components.
   - Verified: `quell --jackdaw-extract-schema`, run under nixGL (bare, it
     panics with "Unable to find a GPU"), exits 0 with a schema listing
     Quell's components and `AvianCollider`. There's no duplicate
     Bevy/Avian.
2. Author a minimal brush level. Load it in `WorldScreen`, and walk on it with
   the kinematic player.
