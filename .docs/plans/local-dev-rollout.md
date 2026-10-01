# Local dev without nix — remaining rollout

Status: **In progress (2026-10-01).** Working notes for finishing
`.docs/local-dev-without-nix-design.md` via infra issues #64, #65, #66.
vn-jun-26 is explicitly out of scope.

## #64 — remove bevy_lint (nearly done)

- [x] Infra #67 merged; all downstream PRs and sync PRs merged.
- [x] **Local cleanup:** deleted `~/.cargo/bin/bevy_lint{,_driver}` (the
      `target/bevy_lint`/`target/ra-*` dirs never existed locally).
- [ ] **Follow-up (infra#69, open):** remove the `check-args` input from
      `downstream-pipeline.yml` (done there); delete the org-level
      `QPROJ_CHECK_ARGS_JSON` variable (needs `admin:org` — run
      `gh variable delete QPROJ_CHECK_ARGS_JSON --org cubething-qproj`);
      q_cam's repo-level variables already deleted. vn-jun-26's `ci.yml` still
      passes `check-args`, so its CI calls fail on the undeclared input (ignored).
- [ ] Close #64 (after #69 merges and the org variable is gone).

## #65 — pin toolchain to Jackdaw (infra merged, rollout remaining)

- [x] Infra #68 merged (`rust-toolchain.toml` template, flake reads it, coverage
      `RUSTFLAGS` removed, docs).
- [ ] **Sync PRs** (rust-toolchain.toml, .cargo/config.toml, flake.lock) merge in the
      7 registered repos. The sync run started at 2026-10-01T22:05Z.
- [ ] **Verify a downstream coverage job passes** — dropping the coverage `RUSTFLAGS`
      means coverage builds now pick up `-Zshare-generics`/`-Zthreads`/mold from the
      config; nothing local exercises that path (review P2).
- [x] **Org root** (no remote; local commit): `rust-toolchain.toml`,
      `.cargo/config.toml`, `.docs/plans/quell-jackdaw-spike.md`, the Jackdaw skill,
      plus the #64 org-root files (`justfile`, `Cargo.toml`, `.zed/settings.json`,
      `Cargo.lock`, submodule pointers).
- [ ] Close #65 (after the sync PRs merge and a downstream coverage job passes).

## #66 — drop nix from local dev (not started)

Implement per issue #66, then do the local machine switch:

- [ ] Infra: flake (drop `devShells.default`/`rustToolchainDev`/`devPackages`, make
      `toolchain` required in `mkShell`, drop nixGL comment, `FEATURES` and `.env.local`
      shellHook bits), `play.py` libstd path + tests, template justfile, README
      requirements, reference.md nixGL tip.
- [ ] Org root: `.envrc` (drop `use flake`/`NIXPKGS_ALLOW_UNFREE`, add
      `dotenv_if_exists .env.local`), justfile `play`.
- [ ] Downstream justfiles (8 repos, manual): drop `NIXGL` and the nixGL wrapper.
- [ ] Local machine: `pacman -S --needed cargo-deny act actionlint patchelf`;
      `cargo clean` **before** the first rustup build; `direnv allow`; reinstall
      qproj-scripts against host Python; verify `just check/test/play` (incl. `-F dylib`),
      `cargo run`, `dx serve --hot-patch`, Zed, Jackdaw; only then `nix-collect-garbage -d`.
- [ ] Close #66, then close the design doc.
