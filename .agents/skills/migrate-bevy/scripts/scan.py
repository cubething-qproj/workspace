#!/usr/bin/env python3
"""Conservative source scanner for Bevy 0.19 APIs changed in 0.20.

This reports candidates; it never edits files. It intentionally favors false
negatives over noisy substring matches. Compiler diagnostics and the bundled
migration guides remain authoritative.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import sys
from typing import NamedTuple


class Rule(NamedTuple):
    id: str
    pattern: re.Pattern[str]
    guide: str
    action: str
    mechanical: bool = False


def rule(
    id: str, pattern: str, guide: str, action: str, mechanical: bool = False
) -> Rule:
    return Rule(id, re.compile(pattern), guide, action, mechanical)


RULES = [
    rule("app-insert-non-send-resource", r"\binsert_non_send_resource\b", "removed-deprecations.md", "Replace with `insert_non_send`.", True),
    rule("app-init-non-send-resource", r"\binit_non_send_resource\b", "removed-deprecations.md", "Replace with `init_non_send`.", True),
    rule("state-set-if-neq", r"\bset_(?:next_state_)?if_neq\b", "next_state_set_if_neq_rename.md", "Use the corresponding `*_if_different` method.", True),
    rule("access-reads-and-writes", r"\breads_and_writes\b", "access_fields_rename.md", "Use `reads`; review whether the code expects reads only or the union of reads and writes.", True),
    rule("mesh-aabb-compute", r"\bcompute_aabb\b", "mesh_aabb_trait_rename.md", "Rename `MeshAabb::compute_aabb` to `get_aabb`.", True),
    rule("unprepared-bind-group", r"\bUnpreparedBindGroup\b", "bind_group_builder.md", "Migrate to `BindGroupBuilder` and its new preparation flow."),
    rule("wgpu-wrapper", r"\bWgpuWrapper\b", "wgpu_wrapper.md", "Remove `WgpuWrapper`; implement the documented conversion/trait path."),
    rule("invalid-asset-id", r"\bAssetId\s*::\s*(?:invalid|INVALID_UUID)\b", "deprecate_asset_id_invalid.md", "Replace sentinel invalid IDs with an explicit optional/error representation."),
    rule("filtered-resources", r"\bFilteredResources(?:Mut|Builder)?\b", "deprecate_filtered_resources.md", "Migrate to the replacement resource query/access APIs."),
    rule("from-type", r"\bFromType\b", "bevy_reflect_parameterized_type_data.md", "Replace reflection type-data construction with `CreateTypeData`."),
    rule("reflect-from-ptr-as-reflect", r"\bReflectFromPtr\s*::\s*as_reflect\b|\.as_reflect\s*\(", "reflect_from_ptr_as_reflect_rename.md", "Use `ptr_as_reflect`."),
    rule("reflect-from-ptr-from-ptr", r"\bReflectFromPtr\s*::\s*from_ptr(?:_mut)?\b|\.from_ptr(?:_mut)?\s*\(", "reflect_from_ptr_raw_pointer_cast.md", "Use `raw_pointer_cast`; preserve pointer mutability and safety invariants."),
    rule("ptr-as-ptr", r"\.as_ptr\s*\(", "ptr_as_ptr.md", "If this is Bevy `Ptr::as_ptr`, account for its new `*const u8` return type."),
    rule("partial-reflect-to-dynamic", r"\.to_dynamic\s*\(", "to_dynamic_returns_result.md", "Handle the new `Result` from `PartialReflect::to_dynamic` and helpers."),
    rule("entity-placeholder", r"\bEntity\s*::\s*PLACEHOLDER\b", "entity_placeholder_changed_to_option.md", "Check whether this field/API is now `Option<Entity>` and use `None` where appropriate."),
    rule("many-query-iterator", r"\biter_many(?:_mut)?\b|\bget_many(?:_mut)?\b", "query_many_iter_results.md", "Many-query iteration may now yield `Result`; handle missing/nonmatching entities."),
    rule("world-query-impl", r"\bimpl(?:<[^>]*>)?\s+(?:unsafe\s+)?WorldQuery\b", "world_query_no_default_impls.md", "Implement methods that no longer have trait defaults."),
    rule("exclusive-system", r"\bExclusiveSystemParam\b|\bExclusiveFunctionSystem\b", "function_systems.md", "Migrate custom exclusive-system machinery to unified function systems."),
    rule("sprite-material", r"\bSpriteMaterial(?:Plugin)?\b", "sprite_material_rename.md", "Apply the sprite material rename before the broader sprite mesh migration."),
    rule("sprite-component", r"\bSprite\b", "sprite_mesh_migration.md", "Review for the 0.20 `Sprite` → mesh/material architecture migration."),
    rule("mesh-tag-tuple", r"\bMeshTag\s*\(", "mesh_tag_new.md", "Construct with `MeshTag::new(...)`.", True),
    rule("tonemapping-import", r"bevy_(?:core_pipeline|pbr)::[^\n;]*(?:Tonemapping|DebandDither)", "tonemapping_moved_to_bevy_render.md", "Import tonemapping types from `bevy_render::view` (or the matching Bevy re-export)."),
    rule("tonemapping-none", r"\bTonemapping\s*::\s*None\b", "tonemapping_none_passthrough.md", "Audit intent: `None` is now a full passthrough; `Linear` may match the old result."),
    rule("screen-space-transmission", r"\bScreenSpaceTransmission\b", "transmission_opt_in.md", "Explicitly opt cameras/materials into screen-space transmission where needed."),
    rule("mesh-aabb-shader-utils", r"\b(?:octahedral_encode|octahedral_decode|octahedral_decode_signed)\b", "shader_octahedral_moved.md", "Update the shader utility import path."),
    rule("wgsl-import", r"#import\s+[^\n]+", "shaders_use_wesl.md", "Audit shader imports and module structure for WESL."),
    rule("text-scroll", r"\bTextScroll\b", "editable_text_scrolling.md", "Use `EditableText::viewport`."),
    rule("ui-interaction", r"\bInteraction\b|bevy_ui::widget::Button", "deprecate_button_and_interaction.md", "Migrate old UI interaction/button usage to picking and `bevy_ui_widgets`."),
    rule("font-from-bytes", r"\bFont\s*::\s*from_bytes\b", "font_from_bytes.md", "Remove the family-name argument and configure family information through the new font source flow."),
    rule("view-target-hdr-format", r"\bViewTarget\s*::\s*TEXTURE_FORMAT_HDR\b", "removed-deprecations.md", "Prefer the actual extracted view target format; use explicit `Rgba16Float` only when required."),
    rule("bevy-default", r"\bBevyDefault\b|\.bevy_default\s*\(", "removed-deprecations.md", "Remove `bevy_image::BevyDefault`; use the actual view format or an explicit texture format."),
    rule("thin-slice-get", r"\bThinSlicePtr\b", "removed-deprecations.md", "Check calls on `ThinSlicePtr`: removed `get` must become unsafe `get_unchecked` with the bounds proof retained."),
    rule("feathers-bundle", r"\b(?:button|checkbox|color_plane|color_slider|color_swatch|radio|slider|toggle_switch|virtual_keyboard)_bundle\b", "removed-deprecations.md", "Use the corresponding Feathers BSN function."),
]

TEXT_SUFFIXES = {
    ".rs", ".wgsl", ".wesl", ".bsn", ".ron", ".toml",
}
SKIP_DIRS = {".git", "target", "node_modules", ".direnv", ".venv", "vendor"}


def files_under(root: Path):
    if root.is_file():
        yield root
        return
    for current, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        base = Path(current)
        for name in files:
            path = base / name
            if path.suffix.lower() in TEXT_SUFFIXES or name in {"Cargo.lock", "Cargo.toml"}:
                yield path


def scan(root: Path):
    findings = []
    for path in files_under(root):
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        relative = path.relative_to(root) if root.is_dir() else path
        for number, line in enumerate(text.splitlines(), 1):
            for item in RULES:
                if item.pattern.search(line):
                    findings.append({
                        "id": item.id,
                        "path": str(relative),
                        "line": number,
                        "guide": item.guide,
                        "mechanical": item.mechanical,
                        "action": item.action,
                        "text": line.strip()[:240],
                    })
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default=".", type=Path)
    parser.add_argument("--json", action="store_true", help="emit JSON")
    args = parser.parse_args()
    root = args.path.resolve()
    if not root.exists():
        parser.error(f"path does not exist: {root}")
    findings = scan(root)
    if args.json:
        json.dump(findings, sys.stdout, indent=2)
        print()
    else:
        for finding in findings:
            marker = "mechanical" if finding["mechanical"] else "review"
            print(f'{finding["path"]}:{finding["line"]}: [{marker}] {finding["id"]}')
            print(f'  {finding["action"]} ({finding["guide"]})')
            print(f'  > {finding["text"]}')
        print(f"\n{len(findings)} candidate(s). Confirm against compiler diagnostics and bundled guides.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
