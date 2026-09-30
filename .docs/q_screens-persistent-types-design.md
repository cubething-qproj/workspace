# q_screens persistent entity types design

Status: **Approved by Ada on 2026-09-29.** Round-1 answers are incorporated: `PersistentTypeScope` API (§3), all seed types registered through the API (§3–4), a Bevy feature per crate (§4), tests against real Bevy types (§6), and a survey with no crate skip list (§7). Round 2: the survey is a Python script run from the `q_screens` justfile (§7). Ships as `q_screens` 0.2.0.

Repo: `cubething-qproj/q_screens` (`lib/q_screens`).

## Summary

Screen cleanup despawns every entity that isn't `Persistent`. Some entities are spawned by Bevy itself, and cleanup currently kills the ones it doesn't know about. Replace the hard-coded exemptions in `clean_up_scoped_entities` with a **registered list of exempt component types**: a type-level opt-out from screen scoping.

- `q_screens` registers the Bevy types it knows about, with one Cargo feature per Bevy crate that spawns them.
- Apps and plugins register the rest with the same call: `app.register_persistent_type::<T>(scope)`.
- Cleanup builds its query at runtime with `QueryBuilder`, so exemptions are filtered per archetype, like a static `Without<T>`.

## 1. Problem

`clean_up_scoped_entities` (`src/scope.rs`) despawns everything matching `Or<(With<ScreenScoped>, Without<Persistent>)>`, minus resource entities (`IsResource`) and top-level `Observer`, `Window` and `SystemIdMarker` entities. Its own comment: "there are probably others i'm missing". There are:

- **`Monitor`** (`bevy_winit`). The first screen change despawns the monitor entity, but `bevy_winit` keeps it in its monitor map. Every window change then re-inserts `OnMonitor(<dead entity>)`, which Bevy removes with a warning. This produces Quell's repeating `OnMonitor ... relates to an entity that does not exist` log spam.
- **`PointerId`** (`bevy_picking`). The mouse pointer entity is spawned at `Startup`, so the first screen change despawns it. Mouse hover and click on UI and meshes stop working after that. (Inferred from the source; this blocks a bevy_ui tuning panel.)
- **`Gamepad`** (`bevy_gilrs` spawns an empty entity, then `bevy_input` adds `Gamepad`). This has the same stale-map failure as monitors.
- **Other engine features:** `bevy_gizmos_render` and `bevy_dev_tools` also spawn main-world entities (§4).
- **Third-party plugins** have the same problem. For example, Jackdaw's Play frame stream spawns a `Readback` entity when streaming starts, and a screen change kills the stream.

## 2. Decision

**Cleanup rule:** on a screen change, despawn every entity that is `ScreenScoped` or not `Persistent`, unless it has a registered persistent type in the matching scope.

- Nothing is inserted into typed engine entities, and there is no snapshot of "entities that existed before the first screen". The only rule is `Persistent`, plus the type list. The one exception is untyped engine entities (§4a).
- **Two scopes** (`PersistentTypeScope`):
  - **`TopLevel`:** ECS internals whose child instances belong to their parent. An `Observer` parented to a screen entity (`ChildOf`) must die with the screen; top-level observers are global by intent. (Entity observers from `.observe(...)` are unparented; Bevy despawns them along with the entity they watch.)
  - **`Anywhere`:** device, pointer and engine-overlay entities, including their children.
- **Cleanup is per entity.** An exempt entity's children survive only if they are exempt themselves (or `Persistent`). A type list must therefore cover every entity in an engine-spawned hierarchy, e.g. the transform gizmo's child meshes.
- An exempt type overrides `ScreenScoped`. `ScreenScoped` exists to opt a child out of a propagated `Persistent`, and it's meaningless on an engine type.

### Rejected alternatives

- **Snapshot entities at the first screen load and mark them `Persistent`.** This special-cases `Startup`, and it still misses entities spawned lazily later: hot-plugged monitors, gamepads, touch pointers.
- **`register_required_components::<T, Persistent>()` on engine types.** It panics if `T` was ever added to an entity before registration. The primary window, resource entities and observers from earlier plugins all exist before `ScreenPlugin::build`.
- **Reflection or an entity-by-entity loop.** Neither is needed. `ComponentId`s come from the generic registration call, and `QueryBuilder` filters by archetype.

## 3. API

```rust
/// Where a persistent type exempts its entities from screen cleanup.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PersistentTypeScope {
    /// Only entities without a parent (`ChildOf`) are exempt.
    TopLevel,
    /// Every entity with the type is exempt, parented or not.
    Anywhere,
}

/// Component types whose entities survive screen cleanup: a type-level opt-out
/// from the screen-scoped-by-default rule (see [`ScreenScoped`], [`Persistent`]
/// and [`ScreenScopeBuilder`] for how scoping works).
///
/// [`ScreenPlugin`] registers Bevy's engine-internal types here, per enabled
/// feature: resource entities, top-level observers and one-shot systems,
/// windows, monitors, gamepads, pointers, gizmo and dev-tools overlays. See
/// the crate docs for the full list and the Bevy version it was audited against.
#[derive(Resource, Default)]
pub struct PersistentTypes { /* ComponentId lists per scope */ }

pub trait RegisterPersistentType {
    /// Entities with `T` survive screen cleanup within `scope`.
    fn register_persistent_type<T: Component>(&mut self, scope: PersistentTypeScope) -> &mut Self;
}
```

- Registration calls `world.register_component::<T>()` and records the id under `scope`. That works before, during or after any entity with `T` exists, so there's no ordering constraint. Registering the same type and scope twice is a no-op.
- **Every seed type goes through this API, including `IsResource`**, so the static filter is reduced to `Or<(With<ScreenScoped>, Without<Persistent>)>`.
- The crate docs (`lib.rs` and the `ScreenScoped`/`Persistent` docs) gain a section on persistent types, listing the seed types, their scopes and features, and the audited Bevy version.

## 4. Seed list (audited against Bevy 0.19.1)

Sourced by surveying main-world spawns outside tests in **every** Bevy 0.19.1 crate (§7). Each seed type is registered only when its Cargo feature is enabled. Each feature is named after the Bevy crate it needs and enables that crate on `bevy` (e.g. `bevy_picking = ["bevy/bevy_picking"]`).

| Type | Spawned by | Scope | `q_screens` feature |
| --- | --- | --- | --- |
| `IsResource` | `bevy_ecs` resource entities | Anywhere | always |
| `Observer` | `bevy_ecs` `add_observer` | TopLevel | always |
| `SystemIdMarker` | `bevy_ecs` `register_system` | TopLevel | always |
| `Window` | `bevy_window` primary window | TopLevel | `bevy_window` (already enabled today) |
| `Monitor` | `bevy_winit` `create_monitors` (startup and hotplug) | Anywhere | `bevy_window` (the type lives there) |
| `Gamepad` | `bevy_gilrs` + `bevy_input` (startup and connect) | Anywhere | `bevy_input` |
| `PointerId` | `bevy_picking` (mouse at `Startup`, touch on touch start) | Anywhere | `bevy_picking` |
| `TransformGizmoRoot`, `TransformGizmoMeshMarker`, `GizmoOverlayCamera` | `bevy_gizmos_render` `spawn_gizmo_meshes` (`Startup`, only with `TransformGizmoSettings`) | Anywhere | `bevy_gizmos_render` |
| `DiagnosticsOverlayPlane`, `FpsText` (+ the FPS frame-time graph marker) | `bevy_dev_tools` overlays (`Startup`) | Anywhere | `bevy_dev_tools` |

Confirm during implementation:
- whether `bevy_input` is already pulled in by `default_app`;
- the exact name of the FPS graph marker (`fps_overlay.rs:176`);
- whether each of these types is public (a private type can't be registered from `q_screens` and falls under §4a).

### Out of scope (from the survey)

- **User-driven spawns:** scene and world instantiation (`bevy_scene`, `bevy_world_serialization`, `bevy_gltf`); hierarchy, relationship and clone helpers (`bevy_ecs`); BRP spawn requests (`bevy_remote`). BRP-spawned observers are `Observer`s and are covered above. Entity observers (`bevy_camera_controller`) die with their entity, as intended.
- **Render-world entities:** `TemporaryRenderEntity` (UI, text, sprites), light views (`bevy_pbr`), `sync_world`, and the gizmo uniform extraction. Screen cleanup never sees the render world.
- **`Screenshot`** (`bevy_render`): spawned by the user or by `bevy_dev_tools`, and despawned after capture. A screen change mid-capture drops that one screenshot, which is acceptable; not seeded.

## 4a. Untyped engine entities

Two engine sites spawn main-world entities with no distinguishing component, so a type list can't match them:

- `bevy_gizmos_render`: `LineGizmoEntities::from_world` spawns three entities with only `Name` ("LineGizmoRenderer" etc.) and stores them in the `LineGizmoEntities` resource (main world, extracted to the render world).
- `bevy_dev_tools`: the FPS overlay's root is a plain `Node` (`fps_overlay.rs:192`); only its children carry markers.

Under the same crate features, `q_screens` inserts `Persistent` on exactly these entities once they exist:
- `LineGizmoEntities`: read the resource and mark its three entities.
- FPS overlay root: mark the parent of `FpsText`.

This is the only automatic insertion, and it's limited to engine internals that can't be matched any other way. Also file upstream Bevy issues asking for marker components on both, and drop this code once they land.

**Impact today is unverified.** These entities are only used as phase-item IDs and a UI root, so gizmo lines may keep rendering after they're despawned. The tests in §6 should show whether anything visibly breaks.

## 5. Implementation

`clean_up_scoped_entities::<S>` becomes an exclusive system, because `QueryBuilder::new` needs `&mut World`:

```rust
fn clean_up_scoped_entities<S: Screen>(world: &mut World) {
    let (anywhere, top_level) = world.resource::<PersistentTypes>().ids();

    let mut builder = QueryBuilder::<Entity>::new(world);
    builder.filter::<Or<(With<ScreenScoped>, Without<Persistent>)>>();
    for id in anywhere {
        builder.without_id(id);
    }
    for id in top_level {
        // "not (T and top-level)" == "without T, or has a parent"
        builder.or(|b| {
            b.without_id(id);
            b.with::<ChildOf>();
        });
    }
    let doomed: Vec<Entity> = builder.build().iter(world).collect();

    for entity in doomed {
        if let Ok(mut e) = world.get_entity_mut(entity) {
            e.clear(); // removes relationship components, as today
            e.despawn();
        }
    }
    // then mark cleanup finished, as today (ScreenInfoMut::finish_cleanup)
}
```

- Rebuild the query on each cleanup rather than caching it. It runs once per screen change; caching would add state and invalidation for no measurable gain.
- `finish_cleanup` currently goes through the `ScreenInfoMut<S>` system param. From an exclusive system, run it through a cached `SystemState` or `world.run_system_cached`. The implementation should pick whichever keeps the diff smallest.
- Update the doc comments on `ScreenScoped`, `Persistent` and `ScreenScopeBuilder`, which currently say "all entities except top-level Observer and Window are screen-scoped", and link them to the new crate-docs section.

## 5a. Quell changes

- Enable `q_screens`' `bevy_picking` feature, plus `bevy_input` if it isn't already covered.
- Register Jackdaw's `bevy::render::gpu_readback::Readback` with `Anywhere`, so a screen change doesn't kill the Play frame stream.
- Nothing else. Quell's only `Startup` spawn is the UI camera, which is already `Persistent`.

## 6. Tests (`lib/q_screens/tests/screens/`)

**Behavior of the mechanism**, with test-local marker components:

1. A type registered as `Anywhere`, spawned mid-screen **as a child**, survives a screen change.
2. A type registered as `TopLevel` survives when top-level, and is despawned with the screen **when parented**.
3. A top-level global `Observer` survives. An `Observer` parented to a screen entity is despawned with the screen, and an entity observer (`.observe(...)`, despawned by Bevy) goes with its entity.
4. A plain entity spawned in `Startup` without `Persistent` is despawned on the first screen change. This guards against snapshot semantics creeping back in.
5. Existing `entity_scope.rs` cases (`Propagate(Persistent)`, `ScreenScoped` opt-out) still pass unchanged.

**The seed list itself**, with the real Bevy types. The list is engine-internal and may behave unexpectedly, so assert that it works:

6. For each seed type (per enabled feature), spawn an entity with it mid-screen, both top-level and parented, and assert survival matches its scope. For §4a, spawn through the real code path (e.g. `LineGizmoEntities` via its `FromWorld`) and assert the entities survive.
7. Where possible, a regression test for the original symptom: after a screen change, the `Monitor` entity referenced by the window's `OnMonitor` still exists.

These seed tests are updated mechanically with each Bevy release, alongside the audit in §7. Run them under `--all-features` in CI so every feature-gated seed is covered.

## 7. Maintenance: re-audit per Bevy release

**As implemented** (supersedes the script sketch below): all registrations, including the feature-gated ones, and their tests are hand-written in `src/persistent.rs`. `just audit-bevy-spawns <old> <new>` scans both Bevy versions' `bevy_*` crates in the cargo registry (test code and async-task spawns excluded, line numbers dropped) and prints only the main-world spawn sites added or removed between them. Crates missing from one version are listed separately for full review. A new site that spawns an engine-internal entity means a new registration and test. Considered and dropped along the way: generating the registrations from a TOML seed list (no gain once classification was manual), classifying every site in a TOML with per-rule counts (the version diff gives the same change detection with nothing stored), and fully scraping types (gamepads are spawned blank, pointers from variables, some types are private, and scraping would pick up lights and UI nodes).

On each Bevy minor bump, re-run the survey over **all** new `bevy_*` registry sources and classify each hit against §4:
- main-world typed → seed it;
- main-world untyped → §4a;
- user-driven → out of scope;
- render world → out of scope.

Record the Cargo feature each seed needs.

The survey is a standalone script, committed with the implementation at `lib/q_screens/scripts/audit_bevy_spawns.py` and run from the crate's justfile: `just audit-bevy-spawns 0.19.1`.

```python
#!/usr/bin/env python3
"""List main-world entity spawns in Bevy's crates, for auditing q_screens'
persistent-type seed list. See the q_screens persistent-types design.

Usage: audit_bevy_spawns.py <bevy-version> [--registry <cargo registry src dir>]

Every `bevy_*-<version>` crate in the cargo registry is scanned. Only test code
and async-task spawns are excluded; every other hit must be classified by hand
(seed type, untyped engine entity, user-driven, or render world).
"""

import argparse
import re
from collections import defaultdict
from pathlib import Path

SPAWN = re.compile(r"\.\s*spawn(?:_empty)?\s*\(")
# `.spawn(...)` on a task pool or executor spawns a future, not an entity.
TASK = re.compile(r"\.\s*spawn\s*\(\s*(async|move|\{|future|f\)|task|AssertUnwind|fut)")


def default_registry() -> Path:
    return next((Path.home() / ".cargo/registry/src").glob("index.crates.io-*"))


def non_test_source(path: Path) -> str:
    src = path.read_text(encoding="utf-8", errors="ignore")
    return src.split("#[cfg(test)]")[0]


def spawns(body: str):
    for m in SPAWN.finditer(body):
        start = body.rfind("\n", 0, m.start()) + 1
        line = body[start : body.find("\n", m.start())].strip()
        if line.startswith(("//", "#")):
            continue
        context = " ".join(body[m.start() : m.start() + 70].split())
        if TASK.match(context):
            continue
        yield body.count("\n", 0, m.start()) + 1, context


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("version", help="Bevy crate version, e.g. 0.19.1")
    parser.add_argument("--registry", type=Path, default=None)
    args = parser.parse_args()
    registry = args.registry or default_registry()

    hits = defaultdict(list)
    for path in sorted(registry.glob(f"bevy_*-{args.version}/src/**/*.rs")):
        relative = path.relative_to(registry)
        crate, file = relative.parts[0], Path(*relative.parts[1:])
        if "tests" in file.parts or file.name.endswith("tests.rs"):
            continue
        for line, context in spawns(non_test_source(path)):
            hits[crate].append(f"{file}:{line}: {context}")

    if not hits:
        raise SystemExit(f"no bevy_*-{args.version} crates under {registry}")
    for crate, lines in hits.items():
        print(f"== {crate} ({len(lines)})", *lines, sep="\n    ")


if __name__ == "__main__":
    main()
```

- The only exclusions are test code and async-task spawns; every crate is listed and classified by hand.
- Record the audited Bevy version in the crate docs next to the seed list, and update the §6 seed tests in the same change.

## 8. Resolved in round 1

- **Features:** one `q_screens` feature per Bevy crate that needs persistent entities (§4).
- **API:** `register_persistent_type::<T>(PersistentTypeScope::{TopLevel, Anywhere})` (§3).
- **Seed tests:** assert the real Bevy types, updated per release (§6).
- **Survey:** no crate skip list (§7).
