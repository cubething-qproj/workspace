# Bevy 0.20 migration — handoff

Status as of 2026-11-02. The code is done and verified; committing, pushing and
opening PRs are blocked on SSH signing.

## Blocker

`git commit` signs with `~/.ssh/id_rsa` (`gpg.format = ssh`). The key has a
passphrase and the ssh-agent has no identities, so signing fails ("incorrect
passphrase supplied") and SSH pushes fail too. **Run `ssh-add ~/.ssh/id_rsa`
before continuing.** Per AGENTS.md, don't sign or commit any other way.

## Where things are

Every repo is on branch `chore/bevy-0.20`, cut from the latest main. The
superrepo branch is cut from *local* main, so it includes 3 commits not yet on
origin: rm jackdaw, xaif skill, nlp notes. The superrepo is private.

- **Staged** = original migration work (Sonnet agents + me).
- **Unstaged** = Opus reviewer fixes, plus the infra/YarnSpinner follow-ups.
  The user wants these in a **separate commit**.

| repo | staged | unstaged (review commit) |
|---|---|---|
| `.` superrepo | skill update, root `Cargo.toml` (jackdaw `[patch]` removed), `Cargo.lock`, `rust-toolchain.toml` | `.agents/skills/migrate-bevy/scripts/scan.py` |
| lib/q_cam | migration | — |
| lib/q_proc | migration | — |
| lib/q_query_lang | migration | — |
| lib/q_screens | migration | `src/data.rs` (`ScreenIdFor` now declares its `ScreenRegistry` read) |
| lib/q_shell | migration | — |
| lib/q_term | migration | `src/systems/term.rs` (doc only) |
| lib/q_test_harness | migration (`InputTestPlugin` inits `MouseScrollPixelsPerLine`) | — |
| bin/quell | migration | `Cargo.toml` (comment), `hex_paths/panel.rs` (don't overwrite focused number inputs), `player/events.rs` (indent) |
| bin/vn-jun-26 | migration + submodule pointer → `84629174` | `.gitmodules` (`branch = feat/bevy-0.20`), `src/main.rs` (`ImagePlugin::default_nearest()`) |
| misc/infra | `.bevy-version`, toolchain template, conventions doc | `flake.nix` (stable toolchain lookup), `flake.lock` (rust-overlay updated so 1.99.0 resolves), `README.md` |

**Do not commit** the superrepo's unstaged `.gitignore` and `.zed/settings.json`
changes. They are the user's own editor/ignore tweaks, unrelated to this work.
Commit the review fixes with explicit paths, not `git add -u`.

Verification on the combined tree (staged + unstaged):
- `just check --workspace --all-targets`: no errors; only warnings that already existed on 0.19.
- `just test --workspace`: 514 passed, 2 skipped.

Re-run both after committing to be safe.

## Remaining steps

1. `ssh-add ~/.ssh/id_rsa`.
2. YarnSpinner: from `bin/vn-jun-26/third_party/YarnSpinner-Rust` (HEAD `84629174`,
   upstream PR YarnSpinnerTool/YarnSpinner-Rust#289), run
   `git push origin HEAD:refs/heads/feat/bevy-0.20`. vn's `.gitmodules` already
   names this branch.
3. Commit in every repo. Signed with default `git commit`; no co-authored-by or
   generated-by lines.
   - `chore: migrate to Bevy 0.20`: the staged work.
   - `chore: apply review fixes`: the unstaged files listed above, only in repos
     that have them.
4. Push `chore/bevy-0.20` in every repo and open the PRs. Before opening, scan
   for existing issues/PRs (none related as of 2026-10-31). Cross-link all PRs
   and state the merge order in each.
5. After the PRs are merged:
   - rebase quell's `fix/restore-hex-walking` onto the new main;
   - restore the stashed `.ron` edit: `git -C bin/quell stash list` shows
     "hex.paths.ron WIP (pre bevy-0.20 branch)";
   - delete `./tmp/bevy-src` (sparse Bevy checkout, v0.19.0/v0.20.0 tags).

## Merge order and CI caveats

1. **infra** first. Merging to main triggers `infra-sync-downstream`, which
   opens `automation/sync-infra` PRs in each downstream repo (`nix flake update`
   + template sync). Those PRs move downstream CI onto toolchain 1.99.0. Until
   they land, downstream CI still uses nightly-2026-03-05 (rustc 1.96), which
   can't build Bevy 0.20 (needs ≥ 1.97.1).
2. **libs**:
   - q_test_harness
   - q_proc and q_term
   - q_shell, which depends on q_proc and q_term by git
   - q_cam, q_screens and q_query_lang
3. **games**: quell and vn-jun-26.

Lib PRs resolve sibling libs from GitHub `main` (the root `[patch]` only
applies locally), so q_shell, quell and vn CI will fail until their deps merge.

## Decisions made (for PR descriptions)

- **bevy_editor_cam dropped.** Replaced by Bevy 0.20's built-in `PanOrbitCamera`
  in the hex_paths dev screen (`pan_orbit_camera` feature). It's a near-verbatim
  upstreaming. Differences: it uses `Time<Real>` and doesn't send `RequestRedraw`.
- **hexx 0.25 kept (glam 0.32).** `to_bevy`/`from_bevy` convert at the boundary
  in `terrain/mesh.rs`. Remove them once ManevilleF/hexx#246 ships.
- **jackdaw from crates.io.** `jackdaw_runtime` 0.20 plus
  `jackdaw_avian_integration` 0.20; the old `physics` feature moved into the
  latter (`AvianColliderBridgePlugin`). The root `[patch]` pointed at a path
  that no longer existed, so it was removed. The fork's `window.name` patch is
  in an upstream PR.
- **Toolchain: nightly-2026-03-05 → stable 1.99.0.** Bevy 0.20 needs ≥ 1.97.1,
  Jackdaw 0.20 pins 1.99.0, and the conventions doc says to follow Jackdaw's
  pin. Changed in the org root, every repo's `rust-toolchain.toml`, the infra
  template, the conventions doc and `flake.nix`.
- **YarnSpinner.** Our fork's own 0.19 port was superseded by upstream's, so the
  submodule tracks upstream PR #289 instead.
- **bevy_enhanced_input 0.27.** `actions!`/`bindings!` became `bsn!`. Bindings
  and modifiers were verified identical by the reviewer. `sync_contexts` now
  runs `.after(EnhancedInputSystems::Trigger)`.
- **Skill.** `.agents/skills/migrate-bevy` was reconciled with the official
  `v0.20.0` guides. `removed-deprecations.md` was expanded from about 15 APIs
  to about 75, and scanner rules were added.

## Issues opened for existing bugs

- cubething-qproj/q_screens#46: `SystemParam` impls under-declare access (`ScreenData`).
- cubething-qproj/vn-jun-26#2: `UiCoord::new_from_vals` uses the wrong window axes.
- cubething-qproj/quell#64: the bin doesn't build with `--no-default-features` (`maybe_windowless`).
- cubething-qproj/quell#65: tracking camera `Negate::x()` on right-stick Y is a no-op.

Not filed: scan.py's `many-query-iterator` rule still flags lines that already
call `.matched()`. Fold that into the skill generalization below.

## Manual playtest checklist

- **quell movement:** WASD and left stick directions; smoothing.
- **quell cursor:** click to capture; Esc releases, then quits.
- **quell camera:** mouse and right-stick orbit; wheel zoom speed.
- **camera_test:** Tab switch; a held click doesn't re-capture.
- **greybox_arena / world:** authored brushes and models still collide.
- **hex_paths camera:** right-drag orbit and wheel zoom (`PanOrbitCamera` feel); marker click moves focus.
- **hex_paths panel:**
  - sliders show the current values when the panel opens;
  - typing in a number field while releasing a slider doesn't wipe the text;
  - Load updates the fields.
- **q_term console:** trackpad and wheel scroll; line height.
- **vn:** nearest sampling; speaker and textbox sizes; typewriter pagination; character placement and moves.

## Follow-up after merge

Make `migrate-bevy` a general, version-agnostic Bevy migration skill before 0.21
(about April 2027). Plan: auto-memory `bevy-migration-skill-generalize`.
