---
name: jackdaw
description: Reference for Jackdaw, the Bevy 0.19 brush-based level editor (jbuehler23/jackdaw), and for integrating it with Quell. Use when the conversation involves Jackdaw, `jd` commands, `.bsn` scenes, `jackdaw_runtime`, `JackdawPlugin` / `JackdawSceneRoot`, brushes/CSG greyboxing, editor-authorable components (`@EditorCategory`, `EditorOnly`, `@EditorHidden`), play-in-editor, `jd mcp`, or Jackdaw's toolchain/SDK.
---

# Jackdaw reference

Jackdaw is a pre-1.0, fast-moving, **third-party** Bevy editor. It follows the
official Bevy Editor design and uses BSN, but Bevy has not adopted it. Treat this
skill as orientation, not ground truth. Before relying on a detail, verify it
against the sources below and against the installed `jd`: run `jd --help` and
`jd doctor --project <path>`. If they disagree with this file, trust them and
update this file.

Sources, in order of preference (Context7 does not index Jackdaw):

- **Vendored snapshot:** `.docs/reference/jackdaw/`, at the org root. It has
  the book source (`book/`, with `SUMMARY.md` as the table of contents), the
  game template (`templates/game/`) and the example sources (`examples/`).
  Its `README.md` records the upstream commit and how to refresh it. Read
  this first.
- Book: https://jbuehler23.github.io/jackdaw/introduction.html
- Repo: https://github.com/jbuehler23/jackdaw
- API: https://docs.rs/jackdaw. docs.rs and crates.io can lag `main`; see
  "Versions" below.

If the snapshot looks stale for the question at hand, refresh it using its
README instead of fetching pages one at a time.

For syntax, the CLI, config files and gotchas, read `reference.md` in this skill's directory.

For Quell's integration state (branch, decisions, open questions), read
`.docs/plans/quell-jackdaw-spike.md`. Keep project state there, not in this
skill.

## Mental model

- **The game is a normal Bevy crate.** `cargo build` / `cargo run` are untouched.
  Jackdaw never edits `Cargo.toml`, `Cargo.lock`, the toolchain or `target/`.
- **The editor is a separate app.** On project open (or `jd build` / Rebuild
  Project) it runs `cargo build` for the game **with the project's own
  toolchain**, into `<project>/.jackdaw/target/game`. It then runs that binary
  with `--jackdaw-extract-schema` to learn its reflected types. Game code is
  never linked into the editor.
- **Play-in-editor (PIE)** launches that same binary out of process. The editor
  talks to it over IPC and streams frames into the Game panel. A game crash
  can't take down the editor. During Play the **Viewport is not the game**: it
  shows the authored preview with the game's live components copied onto it
  (asset handles arrive empty). Only the Game panel shows the game's frame.
- **Scenes are `.bsn`** text under `assets/`, one scene per file, with
  reflect-based components keyed by full type path. The game loads them through
  `jackdaw_runtime` (`JackdawPlugin` plus `JackdawSceneRoot`). Bevy itself has no
  `.bsn` loader.
- **Brushes** are convex CSG solids stored as face planes plus per-face
  material and UV data. Meshes are rebuilt from the planes at load, so there
  are no mesh files.
- **Extensions** are editor plugins built as dylibs against the "SDK". Only
  they need the pinned nightly; games don't.

## Toolchain (important for this org)

- Jackdaw pins `nightly-2026-03-05` (`misc/jackdaw/rust-toolchain.toml` and
  `jackdaw_env::RUSTUP_TOOLCHAIN`; `jd doctor` shows the installed pin). Only
  the **editor binary and editor extensions** (the SDK/dylib path) require it.
- **The org pins the same nightly on purpose**, in `rust-toolchain.toml`, so
  our builds, the editor and the editor's game build all use one compiler.
  When Jackdaw's pin moves, move ours in the same change. Don't bump ours
  independently. The copies are:
  - the infra project template (the source of truth: CI's nix flake reads it,
    and the sync workflow copies it to the registered repos);
  - the org root;
  - `bin/vn-jun-26`, which isn't in the sync registry.
- The editor builds the game with the **project's** toolchain. It strips an
  inherited `RUSTUP_TOOLCHAIN` so the project's `rust-toolchain.toml` wins
  (`jackdaw_project_build/src/binary.rs`).
- The editor's game build is a second full build in `.jackdaw/target/game`
  (inside the repo, gitignored). The first one takes about 9 minutes. It's
  separate from the org workspace's `target/`, so expect the disk cost.
- Old release bundles (July 2026, `jackdaw-cli`) used a different model: a
  `.jackdaw/shim` crate built against the SDK with the pinned nightly. If you
  see `.jackdaw/shim`, it's stale; the current CLI is `jd` 0.19.x from
  `cargo +nightly-2026-03-05 install --git https://github.com/jbuehler23/jackdaw jackdaw --locked`.
- **Native dependencies** (traced from Jackdaw's `Cargo.lock`, 2026-09-28):
  - **cmake is needed by the editor only.** It builds `manifold-csg-sys`, the
    C++ Manifold CSG kernel (via `jackdaw_csg`), and `aws-lc-sys`, TLS crypto
    (via `ehttp`, `ureq`, `rustls`). Neither reaches `jackdaw_runtime`.
  - **Game side:** `jackdaw_runtime`'s default `render` feature enables
    `bevy/basis-universal`. That builds `basis-universal-sys`, which is C++
    compiled via `cc`, so it needs a C++ compiler but not cmake.
- **The editor's game build can't be configured.** There's no feature or bin
  selection, and Cargo config can't select features. Whatever the editor or
  Play needs, such as `jackdaw_runtime/pie`, must be in the package's default
  build.

## Versions

- Jackdaw's version tracks the Bevy minor: Jackdaw 0.19 means Bevy 0.19.
- **As of 2026-09-28, crates.io only has `jackdaw_runtime` 0.4.1 (Bevy 0.18).**
  The 0.19 runtime exists on git `main`. Until a 0.19 crate is published, a
  Bevy 0.19 game must use a git dependency. Check crates.io before adding one.
- `jackdaw.toml` records `[jackdaw] version` and `bevy` pins. `jd upgrade
  <path> [--apply]` moves them and any `jackdaw_*` crate dependencies.
- **Quell tracks Ada's fork:** `jackdaw_runtime` comes from
  `github.com/ada-x64/jackdaw` `branch = "main"` (upstream `main` plus local
  fixes). Locally, the org-root `[patch]` points that URL at the `misc/jackdaw`
  submodule (`crates/jackdaw_runtime`; `misc` is excluded from the org workspace
  so Jackdaw's crates inherit from their own workspace). Install the editor from
  the same fork branch.

## Working rules

- Prefer `jd` subcommands over reproducing their behavior by hand. `jd import`
  and `jd upgrade` preview by default; show the preview to the user before
  `--apply`.
- To author content through an agent, drive the running editor over its BRP
  (loopback, port in `<project>/.jackdaw/editor.json`). `jd mcp` wraps the same
  methods for MCP clients; plain `curl`/Python JSON-RPC works too. Every edit
  lands on the editor's undo stack, but saves and exports write to disk. See
  `reference.md` §9 and §12.
- For exact geometry (ramps at precise angles, aligned grids), generate
  plane-only brushes and send them with `jackdaw/apply_bsn`; the editor derives
  topology and meshes, and `scene.save` writes the file. Don't hand-edit brush
  topology in `.bsn`. Worked example: `misc/infra/scripts/greybox_stage.py`
  (greybox stage generator; its output is Quell's
  `assets/scenes/greybox_scene.bsn`).
- **Don't verify game behavior by driving Play and screenshotting.** Ask the
  user to playtest. Don't change their editor settings (e.g. Play window mode)
  without asking.
- **Play wipes brush face materials in the open document** (upstream bug, see
  `reference.md` §11). After Play, reload the scene from disk before saving.
- Authorable components: `#[derive(Component, Reflect, Default)]` plus
  `#[reflect(Component, Default)]`. No registration call is needed. The `.bsn`
  type path is the full `module_path!()` path, private modules included (e.g.
  `quell::service::player::data::PlayerSpawn`). Renaming, moving or retyping a
  type or field breaks existing `.bsn` files that use it, so treat such changes
  as asset migrations.
