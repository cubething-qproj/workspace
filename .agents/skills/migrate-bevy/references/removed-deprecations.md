# APIs deprecated in 0.19 and removed in 0.20

Source: every `#[deprecated]` public item at `v0.19.0` that is absent at
`v0.20.0` (reconciled 2026-10-31 by enumerating deprecations at the 0.19 tag
and checking each for presence at the 0.20 tag). A 0.19 project can still
compile with these APIs (with warnings), so an API diff that only compares
non-deprecated public items will miss them. Fix all deprecation warnings
**before** bumping to 0.20; the warning text names the replacement.

Most entries are direct renames. Exceptions are called out.

## Non-send resources (`*_non_send_resource*` → `*_non_send*`)

- `App::insert_non_send_resource` → `App::insert_non_send`
- `App::init_non_send_resource` → `App::init_non_send`
- `World::{insert,init,remove}_non_send_resource` → `World::{insert,init,remove}_non_send`
- `World::{non_send_resource, non_send_resource_mut}` → `World::{non_send, non_send_mut}`
- `World::{get_non_send_resource, get_non_send_resource_mut}` → `World::{get_non_send, get_non_send_mut}`
- `DeferredWorld::{non_send_resource_mut, get_non_send_resource_mut}` → `{non_send_mut, get_non_send_mut}`
- `UnsafeWorldCell::get_non_send_resource{,_mut}{,_by_id}` → `get_non_send{,_mut}{,_by_id}`

## Resources as components

Resources are components in 0.19+, so the resource-specific ID/registration
APIs were removed:

- `World::register_resource::<R>()`, `ComponentsRegistrator::register_resource` → `register_component::<R>()`
- `ComponentsQueuedRegistrator::queue_register_resource` → `queue_register_component`
- `World::resource_id::<R>()`, `Components::resource_id` → `component_id::<R>()`
- `Components::valid_resource_id` → `valid_component_id`
- `Components::{get_resource_id, get_valid_resource_id}` → `{get_id, get_valid_id}`
- `ComponentDescriptor::new_resource` → `ComponentDescriptor::new()`

## Access (custom `SystemParam` / `WorldQuery` impls)

See also `migration-guides/access_fields_rename.md`.

- `Access::{has_component_read, has_resource_read}` → `has_read`
- `Access::has_component_write` → `has_write`
- `Access::{has_any_component_read, has_any_component_write}` → `{has_any_read, has_any_write}`
- `Access::{has_read_all_components, has_write_all_components}` → `{has_read_all, has_write_all}`
- `Access::{remove_component_read, remove_component_write}` → `{remove_read, remove_write}`
- `Access::{is_components_compatible, is_subset_components}` → `{is_compatible, is_subset}`
- `Access::try_iter_component_access` → `try_iter_access`
- `FilteredAccess::{add_component_read, add_component_write}` → `{add_read, add_write}`
- `FilteredAccess::{read_all_components, write_all_components}` → `{read_all, write_all}`
- `FilteredAccess::{add_resource_read, add_resource_write}` (the deprecated
  `FilteredAccess` versions) and `add_unfiltered_resource_{read,write}` →
  `FilteredAccessSet::add_resource_{read,write}`

## Run-condition combinators

`SystemCondition::{and, or, nand, nor}` were removed:

- `.and(c)` → `.and_then(c)`
- `.or(c)` → `.or_else(c)`
- `.nand(c)` → `.nand_then(c)`
- `.nor(c)` → `.nor_else(c)`

**Search carefully.** `.and(` / `.or(` are common on `Option`/`bool`-likes;
only rewrite calls on run conditions (typically inside `.run_if(...)`).

## Hierarchy commands

On both `EntityCommands` and `EntityWorldMut`:

- `clear_children()` → `detach_all_children()`
- `remove_children(&[..])` → `detach_children(&[..])`
- `remove_child(e)` → `detach_child(e)`

## Errors and systems

- `DefaultErrorHandler` → `FallbackErrorHandler`
- `System::type_id()` → `System::system_type()`. **Silent behavior change:**
  `system.type_id()` still compiles in 0.20 because it resolves to
  `Any::type_id`, which returns the `TypeId` of the system *object* rather
  than the underlying system type. Grep for `.type_id()` on systems.

## Asset loading (`AssetServer` / `DirectAssetAccessExt`)

The settings/guard/override `load_*` variants were folded into the builder:

- `load_with_settings(path, s)` → `load_builder().with_settings(s).load(path)`
- `load_with_settings_override(path, s)` → `load_builder().with_settings(s).override_unapproved().load(path)`
- `load_override(path)` → `load_builder().override_unapproved().load(path)`
- `load_acquire(path, g)` → `load_builder().with_guard(g).load(path)`
- `load_acquire_override` / `load_acquire_with_settings` /
  `load_acquire_with_settings_override` → the matching
  `with_guard(..)`/`with_settings(..)`/`override_unapproved()` chain
- `AssetServer::load_untyped(path)` → `load_builder().load_untyped(path)`
- `AssetServer::load_untyped_async(path)` → `load_builder().load_untyped_async(path)`
- `AssetServer::load_erased(type_id, path)` → `load_builder().load_erased(type_id, path)`
- `World::load_asset_with_settings` (`DirectAssetAccessExt`) → `world.load_builder()...`

## State derive attribute

`#[states(scoped_entities)]` on `derive(States)` / `derive(SubStates)` is now a
compile error (PR #25805, after rc.1). State-scoped entities have been
unconditional since 0.17; delete the attribute.

## Feathers constructors

The deprecated Feathers constructors below were removed:

- `button_bundle`
- `checkbox_bundle`
- `color_plane_bundle`
- `color_slider_bundle`
- `color_swatch_bundle`
- `radio_bundle`
- `slider_bundle`
- `toggle_switch_bundle`
- `virtual_keyboard_bundle`

Use each control's corresponding BSN function. This is not a blind rename: imports, arguments, overrides, and child syntax may need to move into a `bsn!` expression. Read `migration-guides/bsn_syntax_improvements.md` and inspect current Bevy examples for the specific control.

`ButtonBundleProps` was removed with the old button constructor. Express its `variant` and `corners` configuration through the replacement button/BSN API.

## Texture formats

`bevy_image::BevyDefault`, including its `TextureFormat` implementation and `.bevy_default()`, was removed. Prefer the texture format from the actual extracted view (`ExtractedView::texture_format` where applicable). If code truly requires a fixed fallback, choose an explicit `TextureFormat` based on that code's contract rather than recreating a universal default.

`ViewTarget::TEXTURE_FORMAT_HDR` was removed. Prefer `ExtractedView::target_format` / the actual view target format. Use `TextureFormat::Rgba16Float` only where a fixed HDR format is genuinely part of the caller's contract.

## Pointer API

Deprecated `ThinSlicePtr::get(index)` was removed. Use `get_unchecked(index)` in an unsafe block and preserve/document the caller's in-bounds proof.

## Method of reconciliation

Enumerated with `git grep -A6 '#\[deprecated' v0.19.0 -- 'crates/*.rs'`,
keyed by (file, item name), and checked each key at `v0.20.0`; candidates
whose name still existed in the same crate were inspected by hand (e.g.
`load_untyped` survives on the load builder, not on `AssetServer`). Items
deprecated through non-`#[deprecated]` means (derive attributes, docs-only)
were found from the `v0.20.0-rc.1..v0.20.0` commit log.
