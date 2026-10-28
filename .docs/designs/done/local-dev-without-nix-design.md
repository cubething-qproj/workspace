# Local development without nix; no bevy_lint

Status: **Draft (2026-09-30).** Awaiting review.

Scope: the org workspace, `.infra` (qproj-scripts, template, flake) and the 8 downstream repos. CI keeps nix.

## Summary

Local development stops using nix. The toolchain comes from rustup via a pinned `rust-toolchain.toml`, system libraries and tools come from the host, and the game runs on the host's GPU drivers without nixGL. CI keeps its nix shells, but reads the same toolchain file so local and CI can't drift. Separately, `bevy_lint` is removed everywhere: `check` becomes clippy only, and `just ra-check` becomes a plain clippy JSON run for rust-analyzer.

## 1. Why

- **GPU work fights nix.** Every `play`/`dev` recipe wraps the game in `nix run --impure github:nix-community/nixGL#nixVulkanNvidia`, and the binary is unrunnable from a plain shell ("Unable to find a GPU"). The host already has working Vulkan, ALSA, udev, Wayland and xkbcommon libraries.
- **Disk:** the nix store is ~120 GB on a nearly full disk.
- **bevy_lint isn't pulling its weight.** It's the only reason for the pinned nightly (`nightly-2026-04-16`, which must match `bevy_lint_driver`), for `#![feature(register_tool)]`, and for a second full compile in `check`. In practice it enforces one lint (`panicking_methods`, Quell only).

## 2. Current state (inventory, 2026-09-30)

| Area | Today |
| --- | --- |
| Entry | `.envrc:5` `use flake path:.infra` (direnv) → `.infra/flake.nix` `devShells.default` |
| Toolchain | nix rust-overlay `nightly."2026-04-16"` (`flake.nix:47–71`), pinned to bevy_cli's toolchain. rustup is installed but shadowed. No `rust-toolchain.toml` anywhere in the workspace. |
| bevy_lint | flake input `bevy_cli` (`flake.nix:18–23`); `qproj-scripts check` = clippy + `bevy lint` (`check.py:44–52`); `bevy_lint.py`; `ra_check.py` runs clippy and `bevy_lint`; `init.py:221–226` verification |
| Code | `#![feature(register_tool)] #![register_tool(bevy)] #![allow(bevy::panicking_methods)]` in `bin/quell/src/lib.rs`, `bin/quell/tests/player_movement.rs`, `lib/q_screens/src/lib.rs`; `[package.metadata.bevy_lint]` in `bin/quell/Cargo.toml`; `check-cfg = ["cfg(bevy_lint)"]` in every crate's `[lints]` and the root `[workspace.lints]` (never used in code) |
| Other nightly use | `[unstable] codegen-backend` + `codegen-backend = "llvm"` (a no-op; llvm is the default); per-repo `-Zshare-generics=y -Zthreads=0` rustflags; `RUSTFLAGS=-Zcodegen-backend=llvm` in coverage |
| System libs | flake `linuxDeps` (alsa-lib, udev, wayland, libxkbcommon, vulkan-loader) + pkg-config, exposed via `LD_LIBRARY_PATH` |
| Tools | flake `ciPackages`/`devPackages`: sccache, mold, clang, cargo-nextest, uv, python314, patchelf, cargo-deny, cargo-llvm-cov, act, actionlint, just. The host already has all of these except `act`, `cargo-deny`, `actionlint`, `patchelf`. |
| GPU | nixGL in every `play` recipe (root and all 8 repos) and quell/vn-jun-26 `dev` |
| qproj-scripts | a uv tool whose venv points at a `/nix/store` Python (`pyvenv.cfg`), so it breaks on nix GC |
| Editor | `.zed/settings.json` `check.overrideCommand = ["just", "ra-check"]`; the **org-root justfile has no `ra-check` recipe**, so this fails at the root today |

## 3. Decisions

### 3.1 Toolchain: one `rust-toolchain.toml`, read by rustup and by CI

- **Add `rust-toolchain.toml`** at the org root and in the project template (so every downstream repo gets one):

  ```toml
  [toolchain]
  channel = "nightly-YYYY-MM-DD"
  components = ["clippy", "rust-analyzer", "rust-src", "llvm-tools-preview"]
  ```

  Locally, rustup reads it. In CI, `.infra/flake.nix` builds the toolchain with rust-overlay's `fromRustupToolchainFile`, so the file is the single source of truth and local/CI can't drift.
- **Stay on nightly** (a fresh, pinned date, no longer tied to bevy_cli) for the per-repo `-Zshare-generics`/`-Zthreads=0` build-speed flags and `dx serve --hot-patch`. See §6 Q1 for going stable instead.
- **Remove the no-op `[unstable] codegen-backend` / `codegen-backend = "llvm"` blocks** from root and template `.cargo/config.toml`, and the `RUSTFLAGS=-Zcodegen-backend=llvm` in coverage.
- **Jackdaw is unaffected.** The editor builds Quell with the project's toolchain, which becomes this pinned file. The skill's rule still holds: never pin *Jackdaw's* nightly in our repos.

### 3.2 bevy_lint: removed everywhere

- **Code:** delete the three `register_tool` attribute blocks, `[package.metadata.bevy_lint]` and every `cfg(bevy_lint)` check-cfg entry.
- **qproj-scripts:**
  - `check` runs clippy only;
  - delete `bevy_lint.py` and the `bevy-lint` verb;
  - `init.py` verifies with clippy and nextest;
  - update `tests/test_ci_commands.py`.
- **`ra-check`:** `qproj-scripts ra-check` runs only `cargo clippy --all-targets --all-features --message-format=json-diagnostic-rendered-ansi` (own target dir, as now). Add the missing `ra-check` recipe to the org-root justfile. Alternatively, drop the override and use rust-analyzer's built-in `check.command = "clippy"` (§6 Q2).
- **Justfiles:** remove `bevy-lint` recipes (template plus 8 repos), and remove `bevy lint` from the org-root `check` recipe.
- **Flake:** drop the `bevy_cli` input from all shells.
- **Lost:** `panicking_methods`. Replacement is optional: `clippy::unwrap_used`/`expect_used` at warn in Quell (§6 Q3).

### 3.3 Nix out of local development

- **`.envrc`:** drop `use flake` and `NIXPKGS_ALLOW_UNFREE`. Keep `GH_TOKEN`. Same for `bin/vn-jun-26/.envrc`.
- **Recipes:** remove the nixGL wrapper and the `NIXGL` variable from every `play`/`dev` recipe (root, template, 8 repos). The game runs directly on host drivers.
- **Host packages** (Manjaro/Arch names):
  - libraries and build tools: `alsa-lib systemd-libs wayland libxkbcommon vulkan-icd-loader pkgconf clang mold`;
  - tools: `sccache just uv python cargo-nextest cargo-llvm-cov cargo-deny act actionlint patchelf`.
  - Document them in `.infra/README.md` in place of "direnv + nix".
- **`LD_LIBRARY_PATH`:** no longer needed for system libraries. For `-F dylib` builds, `play.py` must also add the toolchain's `lib` dir (`rustc --print target-libdir`) so `libstd-*.so` resolves; nix's wrapped rustc covered this implicitly. Verify during rollout.
- **qproj-scripts:** reinstall with the host Python (`uv tool install --reinstall …`).
- **Remote play** (`play.py` patchelf path): keep, with host `patchelf`. Its interpreter rewrite exists because of nix-store binaries and may become unnecessary (§6 Q4).
- **Cleanup:** after the switch, run `nix-collect-garbage -d` to reclaim the store.

### 3.4 Nix stays in CI

- Keep `devShells.ci` and `devShells.ci-coverage`, minus bevy_cli, with the toolchain from `rust-toolchain.toml` (§3.1). Keep the setup action, cache-nix-action, `infra-lint.yml` and `infra-sync-downstream.yml`.
- **`devShells.default`:** reduce it to an alias of `ci`, for anyone who still wants a nix shell. It's no longer part of the documented workflow.
- **Downstream `flake.nix`/`flake.lock`** stay (CI uses `.#ci`). Add the missing `flake.lock` to q_cam and q_shell.

## 4. Rollout

1. **Infra PR:**
   - `rust-toolchain.toml` (template + infra);
   - the flake: `fromRustupToolchainFile`, no bevy_cli, `default` = `ci`;
   - qproj-scripts: no bevy_lint, clippy-only `ra-check`, `play.py` libstd path;
   - template justfile, `.cargo/config.toml`, `.zed/settings.json`;
   - docs.
2. **Sync:** the sync workflow copies the template `flake.nix`, `.cargo/config.toml`, `rust-toolchain.toml` and `ci.yml` into downstreams. It does **not** copy `justfile` or `.zed/settings.json`, so those 8 repos need manual edits.
3. **Downstream PRs** (8 repos): drop bevy_lint attributes and check-cfg entries, nixGL in justfiles, and `bevy-lint` recipes. Quell and q_screens have the attributes.
4. **Org root:** `rust-toolchain.toml`, root justfile (`check`, `ra-check`, `play`), `.envrc`, `.zed/settings.json`.
5. **Local machine:** install host packages, `rustup` picks up the toolchain file, reinstall qproj-scripts, verify `just check`/`test`/`play` for Quell (including `-F dylib`), then GC the nix store.

## 5. Risks

- **Local/CI drift:** mitigated by the shared toolchain file. System library versions still differ (host vs nixpkgs), which only matters for link or runtime issues CI doesn't exercise (CI doesn't run the game).
- **dylib `libstd` resolution** under rustup (§3.3). Test before GC-ing nix.
- **Losing `panicking_methods`:** minor; clippy has equivalents.
- **Sync gaps:** manual justfile and Zed edits in 8 repos are easy to miss. Rollout step 3 lists them explicitly.

## 6. Open questions

1. **Nightly or stable?** Stable would drop the `-Z` build-speed flags, and `dx serve --hot-patch` needs checking on stable. Recommendation: pinned nightly for now.
2. **`ra-check`:** keep the `just ra-check` override (clippy only), or use rust-analyzer's `check.command = "clippy"` and delete the recipe and script?
3. **Replace `panicking_methods`** with `clippy::unwrap_used`/`expect_used` (warn) in Quell, or drop it?
4. **Remote play:** is the patchelf interpreter rewrite still needed once binaries aren't built by nix?
5. **Keep `devShells.default`** as an alias of `ci`, or remove it?

## 7. Found along the way (fix during rollout)

- The org-root justfile lacks `ra-check`, which Zed's override calls.
- The quell/vn-jun-26 `dev` recipe's `RUST_LOG=…` sits on its own line, so it has no effect; quell's copy also names `vn-june-26`.
- The flake's `FEATURES=dylib` shellHook variable is never read.
- The root `[workspace.lints]` isn't inherited (no member uses `lints.workspace = true`), and member `[profile.*]` sections are ignored under the root workspace.
- Stale docs: `.infra/README.md` (nix/direnv), `workspace-conventions.md` (wrong nightly, nonexistent `rust-toolchain.toml`), `.infra/docs/CI.md` (apt steps), `bin/quell/docs/cli.md` (mise).
