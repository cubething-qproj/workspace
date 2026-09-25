# Bevy 0.19 → 0.20 migration reference index

These are snapshots of Bevy's draft 0.20 migration guides at source commit
`f3b53464513111374089cfcc724ab448e8479dd1`, eight commits after
`v0.20.0-rc.1`. Search this directory by compiler symbol or concept, then read
only the matching guide files. Treat the material as provisional until the
final `v0.20.0` guide is reconciled.

Known source-metadata anomalies:

- `deferredworld_query.md`, `shaders_use_wesl.md`, and `text_input.md` omit PR
  numbers; their introducing commits identify #25789, #25088, and #24929.
- `text_reader_inline_box_changes.md` says #27510, but its introducing commit
  says #25710. Verify before citing.
- A PR can correctly feed multiple guides; do not deduplicate records by PR.

| Guide | Change | PRs in draft |
|---|---|---|
| [`MainEntity_map_and_set_alias.md`](migration-guides/MainEntity_map_and_set_alias.md) | MainEntityHashMap/MainEntityHashSet alias update | `[18408]` |
| [`RenderDebugOverlay_optional_keybindings.md`](migration-guides/RenderDebugOverlay_optional_keybindings.md) | RenderDebugOverlay added to default plugins and now has optional keybindings | `[24891]` |
| [`access_fields_rename.md`](migration-guides/access_fields_rename.md) | Access::reads_and_writes has been renamed to reads. | `[24778]` |
| [`atmosphere_multicam.md`](migration-guides/atmosphere_multicam.md) | Atmosphere now supports multiple cameras | `[23113]` |
| [`bevy_color_hdr_clamps.md`](migration-guides/bevy_color_hdr_clamps.md) | `with_luminance` no longer clamps in `bevy_color` | `[25394]` |
| [`bevy_curve.md`](migration-guides/bevy_curve.md) | split out `bevy_curve` from `bevy_math` | `[25380]` |
| [`bevy_reflect_parameterized_type_data.md`](migration-guides/bevy_reflect_parameterized_type_data.md) | `FromType` replaced by `CreateTypeData` | `[13723]` |
| [`bevy_settings_checks.md`](migration-guides/bevy_settings_checks.md) | bevy-settings errors on useless `SettingsGroup`s | `[25548]` |
| [`bevy_shape.md`](migration-guides/bevy_shape.md) | split out `bevy_shape` from `bevy_math` | `[25302]` |
| [`bind_group_builder.md`](migration-guides/bind_group_builder.md) | `UnpreparedBindGroup` is now `BindGroupBuilder` | `[25058]` |
| [`border_radius.md`](migration-guides/border_radius.md) | BorderRadius_and_ResolvedBorderRadius_fields_are_now_2d | `[24779]` |
| [`bsn_syntax_improvements.md`](migration-guides/bsn_syntax_improvements.md) | BSN Syntax Improvements. | `[25318]` |
| [`calculated_clip_rects.md`](migration-guides/calculated_clip_rects.md) | `CalculatedClip` now stores transformed clip rectangles | `[24148]` |
| [`color_plane_y_axis.md`](migration-guides/color_plane_y_axis.md) | `FeathersColorPlane`'s vertical axis now increases upward | `[25446]` |
| [`component_ids.md`](migration-guides/component_ids.md) | Component ID constants are more type safe | `[25779]` |
| [`component_info_id.md`](migration-guides/component_info_id.md) | ComponentInfo no longer stores the component ID | `[25774]` |
| [`compressed_image_saver.md`](migration-guides/compressed_image_saver.md) | `CompressedImageSaver` improvements | `[24223, 24904]` |
| [`contextual_theming.md`](migration-guides/contextual_theming.md) | Contextual theming | `[24969]` |
| [`cursor_module_to_bevy_picking.md`](migration-guides/cursor_module_to_bevy_picking.md) | `cursor` module moved from `bevy_feathers` to `bevy_picking` | `[25294]` |
| [`custom_attributes.md`](migration-guides/custom_attributes.md) | `CustomAttributes::with_attribute` has been replaced by a builder | `[24171]` |
| [`default_font_size_is_rem.md`](migration-guides/default_font_size_is_rem.md) | `TextFont::default()` font size is now `FontSize::Rem(1.)` | `[25231]` |
| [`deferredworld_query.md`](migration-guides/deferredworld_query.md) | Deprecate `DeferredWorld::query` | `[]` |
| [`define_label.md`](migration-guides/define_label.md) | `define_label!` no longer defines an `Interner` | `[24445]` |
| [`deprecate_asset_id_invalid.md`](migration-guides/deprecate_asset_id_invalid.md) | `AssetId::invalid()` and `AssetId::INVALID_UUID` have been deprecated | `[24392]` |
| [`deprecate_button_and_interaction.md`](migration-guides/deprecate_button_and_interaction.md) | `ui::widgets::Button` and `ui::Interaction` are Deprecated | `[25197]` |
| [`deprecate_filtered_resources.md`](migration-guides/deprecate_filtered_resources.md) | `FilteredResources` and similar structs have been deprecated | `[25331]` |
| [`depth_attachment_changes.md`](migration-guides/depth_attachment_changes.md) | Changes have been made to `DepthAttachment`, `ViewDepthTexture` and `ViewPrepassTextures::depth` to accommodate stencil support | `[24725]` |
| [`downsample_shader_specialization.md`](migration-guides/downsample_shader_specialization.md) | `DownsampleShaders::general` is now a `Handle<Shader>` | `[25744]` |
| [`editable_text_scrolling.md`](migration-guides/editable_text_scrolling.md) | `bevy_ui::widget::TextScroll` has been replaced by `EditableText::viewport` | `[24634]` |
| [`entity_placeholder_changed_to_option.md`](migration-guides/entity_placeholder_changed_to_option.md) | Some `Entity::PLACEHOLDER` have been replaced with `Option<Entity>` | `[25119]` |
| [`escape_in_a_text_input_releases_focus_and_propagates.md`](migration-guides/escape_in_a_text_input_releases_focus_and_propagates.md) | `Escape` in a text input releases focus and propagates | `[25105]` |
| [`extract-extract.md`](migration-guides/extract-extract.md) | Extract Extract | `[24419, 24420, 24423, 22852]` |
| [`flat_pointer_events.md`](migration-guides/flat_pointer_events.md) | Flat Pointer Events | `[25337]` |
| [`focus_cause_auto.md`](migration-guides/focus_cause_auto.md) | FocusCause has a new Auto variant | `[25059]` |
| [`font_from_bytes.md`](migration-guides/font_from_bytes.md) | `Font::from_bytes` no longer takes a family name | `[24362]` |
| [`font_source_generic_families.md`](migration-guides/font_source_generic_families.md) | `FontSource` generic family variants | `[24378]` |
| [`function_systems.md`](migration-guides/function_systems.md) | Exclusive function systems have been unified with regular function systems | `[25507]` |
| [`large_error_variants_boxed.md`](migration-guides/large_error_variants_boxed.md) | Some large error variants are boxed | `[24206, 24624]` |
| [`macos_app_activation.md`](migration-guides/macos_app_activation.md) | macOS app activation now follows `Window::focused` on startup and window creation | `[24702]` |
| [`material_oit_changes.md`](migration-guides/material_oit_changes.md) | Order independent transparency changes to support premultiplied alpha modes and per-material opt-out | `[22821, 24856]` |
| [`mesh_aabb_trait_rename.md`](migration-guides/mesh_aabb_trait_rename.md) | `MeshAabb::compute_aabb` renamed to `get_aabb` | `[21926]` |
| [`mesh_tag_new.md`](migration-guides/mesh_tag_new.md) | `MeshTag(x)` is now `MeshTag::new(x)` | `[24922]` |
| [`meta_transform_deleted.md`](migration-guides/meta_transform_deleted.md) | meta_transform accessor on `UntypedHandle` has been deleted. | `[25509]` |
| [`name_from_specialization.md`](migration-guides/name_from_specialization.md) | `&str`s must now have a static lifetime to be converted to `Name` | `[24544]` |
| [`next_state_set_if_neq_rename.md`](migration-guides/next_state_set_if_neq_rename.md) | `NextState::set_if_neq` renamed to `set_if_different` | `[24676]` |
| [`number_input.md`](migration-guides/number_input.md) | Add scrubbing / dragging to number_input widget | `[24636, 24701]` |
| [`observer_event_matching.md`](migration-guides/observer_event_matching.md) | Moved Observer events `B` Bundle generic into the event type | `[24013]` |
| [`ptr_as_ptr.md`](migration-guides/ptr_as_ptr.md) | Ptr::as_ptr now returns a *const u8. | `[25745]` |
| [`query_many_iter_results.md`](migration-guides/query_many_iter_results.md) | Query iterators from "many" entities now iterate over `Result` instead of `QueryData::Item`. | `[25200]` |
| [`reflect_from_ptr_as_reflect_rename.md`](migration-guides/reflect_from_ptr_as_reflect_rename.md) | ReflectFromPtr::as_reflect is renamed to ptr_as_reflect | `[25754]` |
| [`reflect_from_ptr_raw_pointer_cast.md`](migration-guides/reflect_from_ptr_raw_pointer_cast.md) | ReflectFromPtr::from_ptr and ReflectFromPtr::from_ptr_mut replaced with ReflectFromPtr::raw_pointer_cast | `[25754]` |
| [`render_app_channels_main_thread_executor.md`](migration-guides/render_app_channels_main_thread_executor.md) | `RenderAppChannels::new` requires a `MainThreadExecutor` | `[25722]` |
| [`render_world_window_component.md`](migration-guides/render_world_window_component.md) | Use ECS for render world window data | `[25005]` |
| [`resolve_font_source.md`](migration-guides/resolve_font_source.md) | `resolve_font_source` | `[24378]` |
| [`resolved_compositing_space.md`](migration-guides/resolved_compositing_space.md) | `ViewTarget::compositing_space` is replaced by `ResolvedCompositingSpace` | `[25481]` |
| [`schedule-data.md`](migration-guides/schedule-data.md) | Expose system accesses and filters in BRP `schedule.graph` | `[24743]` |
| [`schedule_build_shuffle_seed_field.md`](migration-guides/schedule_build_shuffle_seed_field.md) | ScheduleBuildSettings now includes a shuffle_seed field. | `[25094]` |
| [`shader_buffer_changes.md`](migration-guides/shader_buffer_changes.md) | `ShaderBuffer` stores typed data in an `AlignedVec` with an explicit buffer size | `[24938, 25426]` |
| [`shader_octahedral_moved.md`](migration-guides/shader_octahedral_moved.md) | Shader `bevy_pbr::utils::{octahedral_encode, octahedral_decode, octahedral_decode_signed}` are moved | `[21926]` |
| [`shaders_use_wesl.md`](migration-guides/shaders_use_wesl.md) | WESL Shaders | `[]` |
| [`sorted_camera_indices_per_target.md`](migration-guides/sorted_camera_indices_per_target.md) | `SortedCamera::hdr` removed: camera indices count per render target | `[25479]` |
| [`sprite_material_rename.md`](migration-guides/sprite_material_rename.md) | `SpriteMaterial` and `SpriteMaterialPlugin` rename | `[25415]` |
| [`sprite_mesh_migration.md`](migration-guides/sprite_mesh_migration.md) | Migrate Sprite to use Mesh2d + SpriteMaterial | `[25432]` |
| [`text_input.md`](migration-guides/text_input.md) | EditableText readonly and display-only modes | `[]` |
| [`text_reader_inline_box_changes.md`](migration-guides/text_reader_inline_box_changes.md) | TextReader changes to support inline boxes | `[27510]` |
| [`to_dynamic_returns_result.md`](migration-guides/to_dynamic_returns_result.md) | `PartialReflect::to_dynamic` and its helpers now return a `Result` | `[24748]` |
| [`tonemapping_moved_to_bevy_render.md`](migration-guides/tonemapping_moved_to_bevy_render.md) | `Tonemapping` and `DebandDither` moved to `bevy_render::view` | `[25480]` |
| [`tonemapping_none_passthrough.md`](migration-guides/tonemapping_none_passthrough.md) | `Tonemapping::None` is now a full passthrough | `[25499, 25685]` |
| [`transmission_opt_in.md`](migration-guides/transmission_opt_in.md) | Opt-in `ScreenSpaceTransmission` | `[25201]` |
| [`type_id_map.md`](migration-guides/type_id_map.md) | Explicit TypeId map aliases | `[25053]` |
| [`val_em_and_rem.md`](migration-guides/val_em_and_rem.md) | Val::Em and Val::Rem | `[25231]` |
| [`weak_system_set_ordering.md`](migration-guides/weak_system_set_ordering.md) | Several built-in schedules now order their system sets weakly | `[25128]` |
| [`wgpu_wrapper.md`](migration-guides/wgpu_wrapper.md) | WgpuWrapper has been removed | `[25512]` |
| [`world_query_no_default_impls.md`](migration-guides/world_query_no_default_impls.md) | WorldQuery trait no longer contains default implementations. | `[25175]` |
