# Bevy 0.19 → 0.20 migration skill: triage

**Status:** historical. Discovery notes from the rc snapshot; references were reconciled against final `v0.20.0` on 2026-10-31 (see `references/INDEX.md`). Kept for provenance; do not treat open items here as current.  
**Snapshot:** `v0.19.0` (`c6f634ca9f`) → `f3b5346451`, eight commits after `v0.20.0-rc.1` (`1b1f3ec1be`)  
**Goal:** build a Pi skill that can diagnose a Bevy 0.19 project, explain each relevant 0.20 break, apply mechanical migrations where safe, and verify the result.

## Decisions requested

1. **Target boundary:** use `v0.19.0..v0.20.0` once the final tag exists; meanwhile catalogue `v0.19.0..HEAD` and mark post-RC changes as provisional.
2. **Product shape:** a project-independent skill with a compact `SKILL.md`, a structured change catalogue, and optional audit/migration scripts.
3. **Automation policy:** automatically make unambiguous edits; present semantic or behavior-changing migrations for confirmation.
4. **Coverage standard:** do not equate “has a draft migration guide” with complete coverage. Reconcile guides against API diffs, removed deprecations, features, examples, and compiler diagnostics.

## What exists now

The current release-content directory contains **74 draft migration-guide files**, referencing **76 unique PRs** (80 references). The source range contains **795 commits** and changes **1,695 files** (`109,177` insertions, `46,928` deletions), so guide-only ingestion is a strong seed but not a sufficient audit.

Three crates are new relative to 0.19:

- `bevy_curve`
- `bevy_extract` (plus `bevy_extract/macros`)
- `bevy_shape`

The broadest Rust source churn is in `bevy_ecs`, `bevy_reflect`, `bevy_pbr`, `bevy_render`, `bevy_feathers`, `bevy_core_pipeline`, and `bevy_math`. These should receive API-diff review even where guides already exist.

## Authoritative-source ladder

Use sources in this order, retaining provenance for every catalogue entry:

1. **Final 0.20 migration guide** on the Bevy website, when published.
2. **`_release-content/migration-guides/*.md`** in this repository.
3. **The linked implementation PR and merge commit**, including deprecation messages and changed examples.
4. **Public API diff** between published 0.19 and 0.20 rustdoc/API snapshots.
5. **Cargo feature and dependency diff**, shader/asset format changes, and platform requirements.
6. **Compiler diagnostics from a real target project** after changing its Bevy dependency.

Release notes are discovery inputs, not migration authority: they can reveal user-visible behavior or new replacements, but often omit exact old-to-new mappings.

## Initial catalogue by migration domain

This is a triage index, not yet the final user-facing wording. Filenames identify the source draft.

### ECS, app, state, scheduling, and remote protocol

- `access_fields_rename.md` — `Access` field/method terminology.
- `component_ids.md` — type-safe component ID constants.
- `component_info_id.md` — `ComponentInfo` no longer stores its ID.
- `deferredworld_query.md` — deprecate `DeferredWorld::query`.
- `define_label.md` — `define_label!` no longer defines an `Interner`.
- `deprecate_filtered_resources.md` — filtered resource APIs deprecated.
- `entity_placeholder_changed_to_option.md` — sentinel entities replaced by `Option<Entity>`.
- `function_systems.md` — exclusive and regular function systems unified.
- `MainEntity_map_and_set_alias.md` — main-entity map/set aliases.
- `next_state_set_if_neq_rename.md` — `set_if_neq` → `set_if_different`.
- `observer_event_matching.md` — observer bundle generic moved into the event type.
- `query_many_iter_results.md` — many-query iterators now yield `Result`.
- `schedule_build_shuffle_seed_field.md` — new schedule-build setting.
- `schedule-data.md` — BRP `schedule.graph` data shape.
- `type_id_map.md` — explicit ordered/unordered `TypeId` aliases.
- `weak_system_set_ordering.md` — built-in schedule set edges are weak.
- `world_query_no_default_impls.md` — `WorldQuery` implementors must provide formerly defaulted methods.

### Reflection, type data, and pointer APIs

- `bevy_reflect_parameterized_type_data.md` — `FromType` → `CreateTypeData`.
- `custom_attributes.md` — `CustomAttributes` builder migration.
- `name_from_specialization.md` — `Name` conversion requires static `&str`.
- `ptr_as_ptr.md` — `Ptr::as_ptr` returns `*const u8`.
- `reflect_from_ptr_as_reflect_rename.md` — `as_reflect` → `ptr_as_reflect`.
- `reflect_from_ptr_raw_pointer_cast.md` — raw-pointer conversion replacement.
- `to_dynamic_returns_result.md` — dynamic reflection conversion is fallible.

### Rendering, cameras, materials, sprites, and shaders

- `atmosphere_multicam.md` — atmosphere supports multiple cameras.
- `bind_group_builder.md` — `UnpreparedBindGroup` → `BindGroupBuilder`.
- `depth_attachment_changes.md` — depth/stencil attachment API changes.
- `downsample_shader_specialization.md` — downsample shader now represented by a handle.
- `extract-extract.md` — extraction APIs split into `bevy_extract`.
- `material_oit_changes.md` — OIT alpha and opt-out behavior.
- `mesh_aabb_trait_rename.md` — `compute_aabb` → `get_aabb`.
- `mesh_tag_new.md` — tuple construction → `MeshTag::new`.
- `render_app_channels_main_thread_executor.md` — constructor needs a main-thread executor.
- `render_world_window_component.md` — render-world window data moved to ECS.
- `resolved_compositing_space.md` — compositing-space API replacement.
- `shader_buffer_changes.md` — typed aligned shader-buffer storage and explicit size.
- `shader_octahedral_moved.md` — shader utility relocation.
- `shaders_use_wesl.md` — WESL shader migration.
- `sorted_camera_indices_per_target.md` — sorted-camera HDR field removed.
- `sprite_material_rename.md` — sprite material/plugin rename.
- `sprite_mesh_migration.md` — `Sprite` backend replaced by mesh/material architecture.
- `tonemapping_moved_to_bevy_render.md` — tonemapping types relocated.
- `tonemapping_none_passthrough.md` — `Tonemapping::None` semantics changed.
- `transmission_opt_in.md` — screen-space transmission becomes opt-in.
- `wgpu_wrapper.md` — `WgpuWrapper` removed.

### UI, text, interaction, picking, and accessibility-adjacent APIs

- `border_radius.md` — border radius fields become 2D.
- `bsn_syntax_improvements.md` — BSN syntax changes.
- `calculated_clip_rects.md` — transformed clipping rectangles.
- `color_plane_y_axis.md` — color-plane vertical axis reversed.
- `contextual_theming.md` — contextual theming changes.
- `cursor_module_to_bevy_picking.md` — cursor module relocation.
- `default_font_size_is_rem.md` — default text size uses `FontSize::Rem`.
- `deprecate_button_and_interaction.md` — old button/interaction APIs deprecated.
- `editable_text_scrolling.md` — text scrolling represented by editable viewport.
- `escape_in_a_text_input_releases_focus_and_propagates.md` — Escape behavior change.
- `flat_pointer_events.md` — pointer-event shape/dispatch migration.
- `focus_cause_auto.md` — new exhaustive-match variant.
- `font_from_bytes.md` — family-name argument removed.
- `font_source_generic_families.md` and `resolve_font_source.md` — font source and resolution changes.
- `number_input.md` — number-input scrubbing behavior/API.
- `text_input.md` — editable text read-only/display modes.
- `text_reader_inline_box_changes.md` — inline box/image reader changes.
- `val_em_and_rem.md` — `Val::Em`/`Rem` and computed layout values.

### Assets, color, math, geometry, platform, and cross-cutting behavior

- `bevy_color_hdr_clamps.md` — luminance no longer clamps.
- `bevy_curve.md` — curve APIs split from `bevy_math`.
- `bevy_shape.md` — shape APIs split from `bevy_math`.
- `compressed_image_saver.md` — image saver API changes.
- `deprecate_asset_id_invalid.md` — invalid asset sentinel deprecated.
- `large_error_variants_boxed.md` — error enum payloads boxed.
- `macos_app_activation.md` — startup/window focus behavior.
- `meta_transform_deleted.md` — untyped-handle metadata accessor removed.
- `RenderDebugOverlay_optional_keybindings.md` — default-plugin/keybinding behavior.
- `bevy_settings_checks.md` — previously useless settings groups now error.

## Immediate integrity findings

These are catalogue blockers or review items, not necessarily upstream bugs:

- `deferredworld_query.md`, `shaders_use_wesl.md`, and `text_input.md` have empty `pull_requests` arrays, although their introducing commits identify PRs **#25789**, **#25088**, and **#24929** respectively.
- `text_reader_inline_box_changes.md` lists **#27510**, while its introducing commit is **#25710**. Treat this as a likely metadata typo and verify upstream.
- Four PRs intentionally or accidentally appear in more than one guide: **#21926, #24378, #25231, #25754**. The catalogue must support many entries per PR rather than deduplicating by PR number.
- The current source snapshot is eight commits beyond `v0.20.0-rc.1`; all findings after the RC tag need a provisional marker until `v0.20.0` is tagged.
- Git’s nearest-tag description is misleading in this checkout; always use explicit `v0.19.0` and `v0.20.0[-rc.N]` refs rather than `git describe` for boundaries.

## Highest-risk coverage gap: removed deprecations

Commit `075a5ae6f` (“Bevy 0.20: remove deprecated items”, PR #25640) removes APIs that a 0.19 project can still compile against. Some are represented indirectly by current guides, but the skill needs explicit old → new records for at least:

- `App::insert_non_send_resource` → `App::insert_non_send`
- `App::init_non_send_resource` → `App::init_non_send`
- Feathers `*_bundle` constructors → corresponding BSN functions
- `bevy_image::BevyDefault` and its `TextureFormat` fallback
- `ThinSlicePtr::get` → `get_unchecked`
- `ViewTarget::TEXTURE_FORMAT_HDR` → view-specific target/texture format (or explicit `Rgba16Float` only when truly required)
- `CommandsStatesExt::set_state_if_neq` → `set_state_if_different`
- reflected state `set_next_state_if_neq` → `set_next_state_if_different`
- `NextState::set_if_neq` → `set_if_different`

A dedicated scan of all symbols deprecated in 0.19, followed by a 0.20 existence check, is required. This should be a first-class catalogue source, not a one-off note.

## Proposed catalogue schema

Store records in machine-readable YAML or JSON; generate human reference pages from it. One record represents one independently matchable migration.

```yaml
id: app-insert-non-send-resource
area: app
kind: rename                 # rename | move | signature | removal | trait | behavior | format | feature
old_versions: ">=0.19, <0.20"
new_versions: ">=0.20, <0.21"
old_symbols:
  - bevy::app::App::insert_non_send_resource
new_symbols:
  - bevy::app::App::insert_non_send
search_terms: [insert_non_send_resource]
mechanical: true
risk: low
summary: App::insert_non_send_resource was removed.
recipe: Replace calls with App::insert_non_send.
behavior_notes: []
sources:
  - type: commit
    ref: 075a5ae6f
  - type: pr
    ref: 25640
status: verified-source
```

Required fields should distinguish:

- **mechanical compile fixes** from **behavioral review**;
- Rust paths from Cargo features, assets, shaders, and platform configuration;
- exact source provenance and verification status;
- applicability predicates (enabled Bevy features, target OS, API usage);
- one-to-many and many-to-one replacements;
- migrations that require user intent rather than a fixed rewrite.

## Proposed skill workflow

1. **Inventory the target**
   - Locate workspace manifests and lockfiles.
   - Confirm current Bevy version, git dependency/revision, feature flags, and direct use of split Bevy crates.
   - Detect Rust, WGSL/WESL, BSN, assets, examples/tests, and platform-specific code.
2. **Select applicable records**
   - Search exact old symbols/imports and structural patterns.
   - Add domain checks for enabled features and non-Rust files.
   - Compile after bumping in a disposable branch/worktree when permitted; map diagnostics back to records.
3. **Plan in dependency order**
   - Cargo/crate splits and features first.
   - Moves/renames/signatures next.
   - trait and architecture migrations next.
   - behavioral audits last.
4. **Apply conservatively**
   - Use syntax-aware edits where possible.
   - Never perform global text replacement for ambiguous short names.
   - Keep semantic migrations as reviewable, small patches.
5. **Verify**
   - `cargo check --workspace --all-targets` with the project’s actual feature policy.
   - Run tests, examples, shader validation, and platform checks where available.
   - Rescan for old symbols and report unresolved behavioural items.
6. **Report**
   - List applied records, skipped/non-applicable records, unresolved errors, and manual checks with source links.

## Work plan

### Phase 1 — freeze and normalize sources

- Freeze the provisional range at `v0.20.0-rc.1`; maintain a separate post-RC delta.
- Parse all 74 draft guides into records without discarding their prose.
- Correct or annotate metadata anomalies only in the catalogue unless upstream changes are requested.
- Ingest 0.20 release notes as discovery links.

**Exit:** every draft guide maps to one or more records with provenance.

### Phase 2 — coverage audit

- Generate public API snapshots for 0.19 and 0.20 and classify removed/moved/changed items.
- Audit all 0.19 deprecations removed in 0.20.
- Diff root and per-crate Cargo features, defaults, package names, and minimum/toolchain requirements.
- Inspect changed examples to extract canonical rewrites.
- Audit WGSL/WESL, BSN, assets, and platform behavior separately from Rust API changes.

**Exit:** every unexplained public diff is either catalogued, marked internal/non-breaking, or queued for research.

### Phase 3 — build and test the skill

- Write the minimal `SKILL.md` routing workflow.
- Add catalogue query/audit helpers.
- Create representative 0.19 fixtures by domain and migrate them to 0.20.
- Test idempotency, false positives, partial feature sets, split-crate users, and behavior-only reports.

**Exit:** fixtures compile on 0.19 before migration and on 0.20 afterward; rerunning produces no edits.

### Phase 4 — final-release reconciliation

- Replace the provisional target with `v0.20.0`.
- Diff RC1 → final and add/retire provisional records.
- Reconcile against the published migration guide and link stable docs.rs/Bevy URLs.

**Exit:** catalogue version is pinned to final 0.20 and records contain stable sources.

## Triage priorities

1. **P0:** removed 0.19 deprecations; crate splits; feature/default changes; architecture-scale sprite, extraction, observer, and function-system migrations.
2. **P1:** signatures, moves, trait implementation changes, result/option changes, shader language migration.
3. **P2:** behavior changes that compile successfully (tonemapping, transmission, focus, weak ordering, clipping, color-plane orientation, luminance).
4. **P3:** niche internals and platform-specific changes, still retained when publicly reachable.

## Open questions

- Should the skill edit a user’s dependency automatically, or only after presenting the detected Bevy dependency topology?
- Should it support only the umbrella `bevy` crate, or guarantee split-crate users from the first release? The crate splits argue for the latter.
- Is a Rust parser (`syn`-based helper) acceptable as a bundled tool, or must the first version rely only on compiler diagnostics and precise text edits?
- Should behavioral checks be interactive by default, or emitted as a final checklist?
- Do we want to upstream the three missing PR references and likely `27510`/`25710` typo separately?
