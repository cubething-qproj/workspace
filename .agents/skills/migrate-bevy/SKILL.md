---
name: bevy-0-19-to-0-20-migration
description: Migrates Rust games, plugins, examples, shaders, and workspaces from Bevy 0.19 to 0.20. Use when upgrading a Bevy 0.19 dependency, resolving 0.20 compiler errors, auditing behavioral changes that still compile, or explaining an old-to-new Bevy API mapping. Covers umbrella and split-crate users, removed 0.19 deprecations, crate splits, ECS, reflection, rendering, sprites, UI, text, shaders, assets, and platform changes.
compatibility: Requires Python 3 for the optional scanner and a Rust/Cargo toolchain to compile target projects. The bundled catalogue snapshots Bevy shortly after v0.20.0-rc.1 and must be reconciled when the final v0.20.0 guide is available.
---

# Migrate Bevy 0.19 to 0.20

Migrate from evidence, not from memory. First establish the dependency topology and feature set, then combine the bundled migration references with compiler diagnostics. Treat successful compilation as necessary but insufficient: several 0.20 changes alter behavior without producing errors.

Resolve every relative path in this file against this skill's directory.

## References and helper

- `references/INDEX.md` indexes 74 bundled draft migration guides and known metadata anomalies.
- `references/migration-guides/` contains the full guide snapshots. Search this directory for the exact symbol or diagnostic, then read only relevant files.
- `references/removed-deprecations.md` covers APIs that compiled in 0.19 but were removed in 0.20.
- `scripts/scan.py` conservatively reports likely old APIs and behavioral review sites. It never edits files and its findings are candidates, not proof.
- `TRIAGE.md` records catalogue scope, risks, and follow-up work. Read it only when maintaining or extending this skill.

## Safety and editing policy

- Inspect `git status` before editing. Preserve user changes and do not rewrite unrelated code.
- Ask before changing dependency versions unless the user already requested the upgrade.
- Do not use a broad global replacement for short or ambiguous names such as `Sprite`, `Interaction`, `Name`, `get`, or `as_ptr`.
- Make direct renames automatically only when symbol identity and replacement are unambiguous.
- Present architecture, unsafe-code, rendering, scheduling, and behavior changes explicitly; do not conceal them in a large patch.
- Never erase an `unsafe` invariant. When migrating pointer APIs, restate and preserve the safety proof.
- Respect the project's actual feature policy. `--all-features` is not a substitute for checking the configurations it ships.
- Do not claim complete migration solely because `cargo check` succeeds.

## 1. Establish scope

From the target project root:

1. Read `Cargo.toml`, workspace manifests, `.cargo/config*`, and relevant `Cargo.lock` entries.
2. Find all Bevy dependencies, including aliases and split crates:

   ```bash
   rg -n 'bevy(_[a-z0-9_]+)?\s*=|package\s*=\s*"bevy' --glob 'Cargo.toml'
   cargo metadata --no-deps --format-version 1
   ```

3. Record for each package:
   - crates.io version, git URL/revision, path override, or workspace inheritance;
   - umbrella `bevy` versus direct `bevy_*` crates;
   - `default-features` and explicit features;
   - target-specific dependencies and examples/tools outside the default workspace.
4. Locate migration-sensitive non-Rust inputs:

   ```bash
   find . -type f \( -name '*.wgsl' -o -name '*.wesl' -o -name '*.bsn' -o -name '*.ron' \) \
     -not -path './target/*' -not -path './.git/*'
   ```

5. Confirm the source is actually 0.19. For git dependencies, compare the pinned revision to Bevy tags rather than trusting a manifest version string.

6. In qproj, the org-wide target Bevy version lives in `misc/infra/.bevy-version` (e.g. `0.19`). `init` substitutes it as `{{bevy_version}}` into new crates' `Cargo.toml` and `deny.toml`. Bump it to `0.20` as part of the upgrade, and never hardcode a Bevy version in the project template.

If dependencies mix Bevy generations, stop and explain the graph before editing. A type from Bevy 0.19 is not interchangeable with the same-named type from 0.20.

## 2. Build an initial findings list

Run the scanner from the target root:

```bash
python /absolute/path/to/this-skill/scripts/scan.py .
# For machine-readable output:
python /absolute/path/to/this-skill/scripts/scan.py . --json
```

Then search references with terms from source and diagnostics:

```bash
rg -n -i 'ExactType|method_name|diagnostic phrase' /absolute/path/to/this-skill/references
```

For each finding, record:

- file and symbol;
- matching guide(s);
- whether it is a compile fix or behavioral audit;
- whether it is mechanical, semantic, or architecture-scale;
- enabled feature/target conditions;
- source PR/commit from the guide metadata.

Dismiss scanner false positives explicitly. Do not edit merely because a textual pattern matched.

## 3. Upgrade in dependency order

Unless the project demands another order:

1. Create a clean checkpoint or verify that one already exists.
2. Change all Bevy packages to one coherent 0.20 release/revision.
3. Update split crates and features. Pay special attention to new `bevy_curve`, `bevy_extract`, and `bevy_shape` crate boundaries.
4. Refresh the lockfile with the narrowest appropriate Cargo command. Do not indiscriminately upgrade unrelated dependencies.
5. Run the fastest representative check and save the complete diagnostics:

   ```bash
   cargo check --workspace --all-targets
   ```

If the project cannot update immediately, perform a report-only audit and give exact proposed dependency edits.

## 4. Apply migrations in layers

After each layer, rerun a targeted `cargo check` so one error does not create misleading downstream errors.

### A. Imports, crate splits, and direct renames

Handle module moves, new crates, renamed types/methods, constructor changes, and removed deprecations first. Read the exact matching guide before editing. Common examples include:

- `bevy_math` curve/shape APIs moving to `bevy_curve`/`bevy_shape`;
- extraction APIs moving to `bevy_extract`;
- `NextState::set_if_neq` → `set_if_different`;
- `MeshAabb::compute_aabb` → `get_aabb`;
- `UnpreparedBindGroup` → `BindGroupBuilder`;
- tonemapping types moving to `bevy_render::view`;
- APIs listed in `references/removed-deprecations.md`.

Resolve re-export paths according to the project's dependency style. Do not force an umbrella-crate import into a split-crate project or vice versa.

### B. Signatures, return types, enum variants, and trait implementations

Address changes that require local reasoning:

- many-query iterators yielding `Result`;
- `PartialReflect::to_dynamic` becoming fallible;
- new enum variants such as `FocusCause::Auto`;
- `WorldQuery` methods losing default implementations;
- observer event generics moving into event types;
- pointer conversion and `ReflectFromPtr` changes;
- boxed error payloads and changed constructor arguments.

Prefer propagating errors when the enclosing API supports it. Otherwise choose handling based on application intent; never add `unwrap()` just to silence a migration error without justification.

### C. Architecture changes

Treat these as small, independently reviewed patches:

- `Sprite` → `SpriteMesh` / `Mesh2d` + sprite material architecture;
- unified exclusive and regular function systems;
- extraction split and render-world window entities;
- old UI `Button`/`Interaction` → picking and `bevy_ui_widgets`;
- Feathers constructors → BSN functions;
- WGSL/WESL module migration;
- transformed UI clipping and inline text boxes.

Use the bundled old/new examples as templates, but adapt them to the target's ownership, scheduling, rendering, and feature constraints.

### D. Behavioral changes that may still compile

Search and report these even after compilation succeeds:

- `Tonemapping::None` is now full passthrough; `Linear` may match old intent.
- screen-space transmission is opt-in;
- built-in schedule set ordering may now be weak;
- Escape in text input releases focus and propagates;
- pointer events are flatter and observer matching changed;
- atmosphere and compositing are resolved per camera/camera stack;
- color-plane Y orientation changed;
- `with_luminance` no longer clamps;
- font defaults and `Em`/`Rem` layout semantics changed;
- macOS startup activation follows window focus;
- clipping rectangles are transformed rather than axis-aligned in the old representation.

For each applicable item, either add/update a regression test or give the user a concrete manual check.

## 5. Diagnose unmapped errors

When no bundled guide matches:

1. Confirm the error is caused by the Bevy upgrade rather than an unrelated lockfile update.
2. Search old and new source/rustdoc for the exact item.
3. Inspect `v0.19.0..v0.20.0` history or the pinned 0.20 revision when a Bevy checkout is available:

   ```bash
   git log --oneline v0.19.0..v0.20.0 -- path/to/relevant/crate
   git diff v0.19.0..v0.20.0 -- path/to/relevant/module
   ```

4. Look for changed Bevy examples that use the replacement.
5. Classify the result as public migration, removed deprecation, upstream regression, ecosystem incompatibility, or project-local issue.
6. Explain the evidence and source before implementing an inferred migration.

If the final 0.20 tag is unavailable, say which RC/commit was used and mark inferred mappings provisional.

## 6. Verify comprehensively

Use commands appropriate to the project; a strong default sequence is:

```bash
cargo fmt --all -- --check
cargo check --workspace --all-targets
cargo test --workspace
```

Also:

- check each shipped feature combination, especially `default-features = false` users;
- compile examples, benches, build scripts, proc-macro consumers, and platform-gated modules as CI does;
- validate WGSL/WESL and load representative assets/scenes;
- rerun `scripts/scan.py` and investigate remaining candidates;
- use `cargo tree -d` or metadata to ensure no accidental mixed Bevy versions remain;
- run project-specific lint/test commands from its contributor documentation;
- review behavior-only items and unsafe changes manually.

Do not “fix” warnings by suppressing them unless the warning is understood and the suppression is part of the intended 0.20 design.

## 7. Report the migration

Summarize:

1. dependency and feature changes;
2. files changed, grouped by migration concept rather than compiler-error order;
3. behavioral decisions and tests added;
4. validation commands and their outcomes;
5. unresolved failures, skipped targets/features, and manual checks;
6. provisional assumptions caused by an RC/git target;
7. matching guide filenames and PR numbers for non-obvious changes.

If asked only for diagnosis, do not edit. Return an ordered migration plan with exact symbols, likely replacements, and source references.

## Maintaining this skill

When `v0.20.0` is tagged:

1. compare `v0.20.0-rc.1..v0.20.0`;
2. reconcile every bundled draft against the published final guide;
3. enumerate all public items deprecated at `v0.19.0` and absent at `v0.20.0`;
4. update scanner rules only for patterns precise enough to be useful;
5. pin the reference snapshot and compatibility note to final `v0.20.0`;
6. test fixtures for umbrella and split-crate projects, minimal/default/all feature sets, shaders, UI, sprites, reflection, and custom ECS traits;
7. verify idempotency: a second migration run must produce no edits.
