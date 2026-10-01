# Local dev without nix — remaining rollout

Status: **In progress (2026-10-01).** Working notes for finishing
`.docs/local-dev-without-nix-design.md` via infra issues #64, #65, #66.
vn-jun-26 is explicitly out of scope.

## #64 — remove bevy_lint (nearly done)

- [x] Infra #67 merged; all downstream PRs and sync PRs merged.
- [x] **Local cleanup:** deleted `~/.cargo/bin/bevy_lint{,_driver}` (the
      `target/bevy_lint`/`target/ra-*` dirs never existed locally).
- [x] **Follow-up (infra#69, open):** remove the `check-args` input from
      `downstream-pipeline.yml` (done there); delete the org-level
      `QPROJ_CHECK_ARGS_JSON` variable (needs `admin:org` — run
      `gh variable delete QPROJ_CHECK_ARGS_JSON --org cubething-qproj`);
      q_cam's repo-level variables already deleted. vn-jun-26's `ci.yml` still
      passes `check-args`, so its CI calls fail on the undeclared input (ignored).
- [x] Close #64 (after #69 merges and the org variable is gone).

## #65 — pin toolchain to Jackdaw (infra merged, rollout remaining)

- [x] Infra #68 merged (`rust-toolchain.toml` template, flake reads it, coverage
      `RUSTFLAGS` removed, docs).
- [x] **Sync PRs** (rust-toolchain.toml, .cargo/config.toml, flake.lock) merge in the
      7 registered repos. The sync run started at 2026-10-01T22:05Z.
- [x] **Verify a downstream coverage job passes** — dropping the coverage `RUSTFLAGS`
      means coverage builds now pick up `-Zshare-generics`/`-Zthreads`/mold from the
      config; nothing local exercises that path (review P2).
- [x] **Org root** (no remote; local commit): `rust-toolchain.toml`,
      `.cargo/config.toml`, `.docs/plans/quell-jackdaw-spike.md`, the Jackdaw skill,
      plus the #64 org-root files (`justfile`, `Cargo.toml`, `.zed/settings.json`,
      `Cargo.lock`, submodule pointers).
- [x] Close #65 (after the sync PRs merge and a downstream coverage job passes).

## #66 — drop nix from local dev (in progress)

- [x] Infra (branch `chore/local-no-nix`, PR pending): flake (dropped
      `devShells.default`/`rustToolchainDev`/`devPackages`, `toolchain` required in
      `mkShell`, nixGL comment and `FEATURES`/`.env.local` shellHook bits removed),
      `play.py` toolchain libdir on local `LD_LIBRARY_PATH` + tests, template justfile
      (no nixGL), `sync-scripts` pins host Python, README host setup.
- [x] Org root: `.envrc` (no `use flake`, `dotenv_if_exists .env.local`), justfile
      (no nixGL; `warn_du` hint fixed; fixed a `=p` typo in the user's `throttle`),
      Jackdaw `reference.md` nixGL tip dropped. User manually verified `just play`.
- [ ] Downstream justfiles (8 repos, manual — the sync skips justfiles): drop `NIXGL`
      and the nixGL wrapper from `play` (and `dev` in quell).
- [ ] Local machine: `pacman -S --needed cargo-deny act actionlint patchelf`;
      `cargo clean` to reclaim the ~50G of nix-toolchain artifacts; reinstall
      qproj-scripts (`just sync-scripts` now pins the host Python); verify `just ci`,
      `dx serve --hot-patch`, Jackdaw; only then `nix-collect-garbage -d`.
- [ ] Close #66, then close the design doc.
