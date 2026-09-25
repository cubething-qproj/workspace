# APIs deprecated in 0.19 and removed in 0.20

Source: Bevy commit `075a5ae6f` / PR #25640. A 0.19 project can still compile with these APIs, so an API diff that only compares non-deprecated public items may miss them.

## App non-send resources

- `App::insert_non_send_resource(resource)` → `App::insert_non_send(resource)`
- `App::init_non_send_resource::<R>()` → `App::init_non_send::<R>()`

These are direct renames.

## State methods

- `CommandsStatesExt::set_state_if_neq(state)` → `set_state_if_different(state)`
- reflected-state `set_next_state_if_neq(...)` → `set_next_state_if_different(...)`
- `NextState::set_if_neq(state)` → `set_if_different(state)`

These are direct renames. The current draft also has `migration-guides/next_state_set_if_neq_rename.md`.

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

## Audit instruction

Do not assume this page is the complete removed-deprecation set until the final `v0.20.0` tag is available. To reconcile the final release, enumerate `#[deprecated]` public items at `v0.19.0`, check their presence at `v0.20.0`, and add every removed item with its original deprecation note.
