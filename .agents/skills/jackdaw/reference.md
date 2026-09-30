# Jackdaw detailed reference

Distilled from the Jackdaw book and repo templates as of `main` @ `3cbdd89`
(2026-09-28) and `jd` 0.19.0, plus source reading and hands-on use against
`e3e5772` (2026-09-29). The full source text is vendored at
`.docs/reference/jackdaw/`; check it for anything load-bearing. The pinned git
source is in `~/.cargo/git/checkouts/jackdaw-*/<rev>/` (read it with `terminal`,
not `read_file`).

## Contents

1. Game-side setup
2. `jd` CLI
3. Project files
4. Authorable components
5. BSN syntax
6. Brushes, materials, UVs
7. Physics
8. Play-in-editor
9. Remote control (`jd mcp`)
10. SDK and extensions
11. Gotchas
12. Authoring by script

## 1. Game-side setup

This is the canonical shape, from `templates/game/`.

`Cargo.toml`: nothing editor-related, only the runtime.

```toml
[dependencies]
bevy = "0.19"
# `physics` builds colliders from authored brushes/terrain, `terrain` draws
# authored terrain, `pie` connects the editor's Play button. Drop `pie` for shipping.
jackdaw_runtime = { <version-or-git>, features = ["physics", "terrain", "pie"] }
avian3d = "0.7"
```

For Bevy 0.19 before a crates.io release exists, use
`{ git = "https://github.com/jbuehler23/jackdaw", features = [...] }`. Check that
crates.io still lacks a 0.19 `jackdaw_runtime` first.

`main.rs`: ambient plugins live here, and gameplay lives in the library plugin.

```rust
use bevy::image::{ImageAddressMode, ImagePlugin, ImageSamplerDescriptor};
use bevy::prelude::*;

fn main() -> AppExit {
    // Repeat sampler so tiled brush materials match the editor
    // (Bevy's default ClampToEdge smears brush textures).
    let default_plugins = DefaultPlugins.set(ImagePlugin {
        default_sampler: ImageSamplerDescriptor {
            address_mode_u: ImageAddressMode::Repeat,
            address_mode_v: ImageAddressMode::Repeat,
            address_mode_w: ImageAddressMode::Repeat,
            ..ImageSamplerDescriptor::linear()
        },
    });
    // Editor-embedded play asks for a windowless launch; a no-op otherwise.
    let default_plugins = jackdaw_runtime::maybe_windowless(default_plugins);
    App::new()
        .add_plugins(default_plugins)
        .add_plugins(avian3d::prelude::PhysicsPlugins::default())
        .add_plugins(jackdaw_runtime::JackdawPlugin)
        .add_plugins(my_game::GamePlugin)
        .run()
}
```

Loading a scene:

```rust
use jackdaw_runtime::prelude::*;
commands.spawn(JackdawSceneRoot(asset_server.load("scene.bsn")));
```

The scene's entities spawn as children of that root (`ChildOf`; the rustdoc on
`JackdawSceneMember` says otherwise, the code disagrees). Despawning the root
despawns the scene, so a screen-scoped root is all the lifecycle a screen needs.

- When the `.bsn` changes (hot reload), the runtime despawns the scene's
  members and spawns **new** ones. `On<Add>`/`On<Insert>` observers fire again,
  so guard anything that must happen once (e.g. "skip if a player exists").
- The loader sets `Transform`, `GlobalTransform` and `ChildOf` before inserting
  user components, so observers see the correct world pose.
- Components whose type the game doesn't register are skipped with a warning;
  the scene still loads. (Only retired UI components make it refuse a scene.)
- Play and the schema run launch the binary with `cwd` and `BEVY_ASSET_ROOT` set
  to the project root, and with `CARGO_MANIFEST_DIR` and other cargo variables
  stripped.
- If `main` parses CLI args (e.g. clap), it must accept
  `--jackdaw-extract-schema`, or the schema run fails and the picker stays empty.
  Also without `JackdawPlugin` no schema is produced at all.
- Verify what the editor will see by running the game binary with
  `--jackdaw-extract-schema` and reading the JSON on stdout (on this machine it
  needs `nix run --impure github:nix-community/nixGL#nixVulkanNvidia -- <bin>`).

- `JackdawPlugin` registers the `.bsn` asset loader and answers schema queries.
  It contains no editor UI.
- `jackdaw_runtime::JackdawAssetSourcePlugin` must be added **before**
  `DefaultPlugins`. It's only needed if assets may be exported to binary `.bsb`
  twins. It lets `load("x.bsn")` resolve to `x.bsb`.
- The runtime walks every asset file under `assets/` at startup. It loads those
  whose header type is a registered reflected `Asset`, and skips the rest with a
  warning.

## 2. `jd` CLI

`jackdaw` is the GUI only; `jd` is the command line.

| Command | Notes |
| --- | --- |
| `jd new <name> [--extension] [--path <dir>] [--no-git]` | Scaffold from the template |
| `jd import [path] [--apply] [--package <member>] [--plugin <Type>] [--allow-bevy-mismatch]` | Previews by default. Creates `jackdaw.toml` and `.jackdaw/`, and ensures a library plugin exists. A bin-only `App::new()` main is converted into `GamePlugin`, with a `main.rs.bak`. |
| `jd open [path]` | Open the GUI on a project |
| `jd build [--project <path>]` | Build the game and extract its schema, so the editor sees new components |
| `jd run [--project <path>]` | Build, then run the game standalone |
| `jd upgrade [path] [--apply]` | Rewrite the `[jackdaw]` pins and `jackdaw_*` deps. Leaves path and git deps alone. |
| `jd doctor [--project <path>]` | Checks prerequisites and SDK resolution. With `--project`: package, lib target, plugin, pins, schema built, dependencies resolve. |
| `jd setup` | Build or prepare the extension SDK. About 30 minutes for a cargo install; only needed for extensions. |
| `jd mcp [--project <path>]` | MCP server over stdio that drives a running editor (§9) |
| `jd export-terrain <scene.bsn> --out <dir> [...]` | Export terrain heightmap, channels and placements |
| `jd extension <keygen\|pack\|install\|verify\|list\|enable\|disable\|uninstall>` | Signed `.jdext` bundles |

Workspaces: import at the workspace root, and `package = "<member>"` is written
to `jackdaw.toml`.

## 3. Project files

`jackdaw.toml` is committed; every key has a working default.

```toml
# package = "my-game"      # workspace member that is the game
# plugin = "GamePlugin"    # root plugin type; recorded for doctor. main.rs must add it.

[jackdaw]                  # pins written by setup/import; compared on open
version = "0.19.0"
bevy = "0.19"

[[run]]                    # one Play-dropdown entry each; runs never build anything
name = "Play"
# instances = 2
# env = { SERVER_ADDR = "127.0.0.1:5000" }
# args = []
# cwd = "some/subdir"
```

`.jackdaw/` is gitignored, owned by the editor and safe to delete. It holds:

- `project.json`: layout, `last_open_tabs`, name and description.
- The extracted type schema.
- `target/game`, the editor's game build.
- `editor.json` while the editor is open, which is how `jd mcp` finds it.
- `settings.json`, e.g. `{"remote": {"enabled": false}}`.
- Play Settings env and args, which are private and never committed.

The user config lives in `~/.config/jackdaw/`: recent projects, keybinds,
keymap preset, extension state and trusted publishers.

Scenes: one `.bsn` file per scene, under `assets/`, which is the only folder
the editor watches. On open, the editor restores the last tabs, then falls back
to `assets/scene.bsn`, then to a new untitled scene. The book says sub-scenes and
prefabs aren't built; that's stale. **Prefabs exist**:

- A prefab is an ordinary `.bsn` whose root carries
  `jackdaw::prefab::components::Prefab`; every entity inside has a
  `PrefabEntityId(u32)`.
- A scene instances it with `IsA { source, deleted }` on the instance root
  (`source` relative to the scene's directory) and stores only overrides.
- `jackdaw_runtime` resolves `IsA` before spawning (nested prefabs and cycle
  detection included; only inside the asset root; failures spawn as authored
  with a warning).
- Editor: `prefab.pack`, `prefab.pack_matching`, `prefab.spawn_instance`.
- Unverified: spawning a prefab file directly from code with
  `JackdawSceneRoot`.

## 4. Authorable components

Minimum:

```rust
#[derive(Component, Reflect, Default)]
#[reflect(Component, Default)]
pub struct PlayerSpawn;
```

- There's no registration call; `reflect_auto_register` handles it when the
  schema is extracted.
- A type in a dependency crate that the library never references may be
  stripped by the linker. Register it explicitly if it doesn't show up.
- Doc comments become picker tooltips, via `reflect_documentation`, which
  `jackdaw_runtime` enables.
- After adding a type, run Rebuild Project or `jd build`. Builds are manual by
  default; Toggle Auto Build switches that per project.

Attributes, from `jackdaw_runtime::prelude::*`:

```rust
#[reflect(Component, Default,
    @EditorCategory::new("Actor"),                  // picker group
    @EditorDescription::new("Where the player respawns."), // tooltip override
    @EditorPreview::gltf("models/player.glb"),      // viewport preview for markers
)]
#[reflect(Component, Default, @EditorHidden)]       // hide from picker, still serialized
```

Entity markers:

- `EditorHidden` as a component hides the entity from the outliner.
- `EditorOnly` means the entity is visible while authoring but not saved.
- `NonSerializable` means the entity is never saved.

`EditorOnly` works per entity, so use a parent carrying the gameplay component
with a child carrying `EditorOnly` and the visual.

`@EditorPreview::gltf(path)` takes the file path **without** a `#Scene0` label;
the editor loads `Scene(0)` itself. The path is a string literal, so if the game
also loads that model (e.g. via an asset collection), comment both sites to keep
them in sync. The extracted schema shows it as `"preview": "<path>"`.

To react to loaded scene components, use a plain observer:

```rust
fn spawn_player(trigger: On<Insert, PlayerSpawn>, gts: Query<&GlobalTransform>, mut commands: Commands) {
    let Ok(gt) = gts.get(trigger.entity) else { return };
    // GlobalTransform is already correct: the loader propagates transforms
    // before firing observers. No SceneInstanceReady walk needed.
}
```

Reflected assets are editor-creatable, one value per `.bsn` file:

- Declare them with `#[derive(Asset, Reflect, Default)]` and register with
  `app.init_asset::<T>().register_asset_reflect::<T>()`.
- A reference from one asset to another is a `String` field marked
  `#[reflect(@AssetRef("crate::path::Type"))]`, from
  `jackdaw_scene_types::AssetRef`.
- An enum field becomes a variant menu.

## 5. BSN syntax

```text
// jackdaw 0.19.0 | bevy 0.19            <- version stamp (asset files: 2nd line names type)
#Root                                    <- entity label = Name
bevy_transform::components::transform::Transform          <- bare path = default value
bevy_camera::visibility::Visibility::Visible               <- enum variant
bevy_ecs::hierarchy::Children [
    #"Main Camera"
    bevy_camera::components::Camera3d
    bevy_transform::components::transform::Transform {
        translation: glam::Vec3 { x: 0.0, y: 6.0, z: 12.0 },   <- omitted fields keep defaults
    }
]
my_game::Signpost { board: "materials/slate.bsn" }         <- asset ref = path under assets/
```

- `#Name` inside a file refers to a scene-local inline asset.
- `@Name` is the legacy project-wide name. It still resolves, and the next save
  rewrites it as a path.
- `project.migrate_asset_references` migrates all legacy names at once.
- A missing reference loads as a default handle, for example untextured
  geometry, rather than failing.
- `.bsb` is a binary twin. `project.export_binary` writes a whole tree. Text
  wins when both exist.
- BSN does not contain mesh data (brushes are stored as planes; `.glb` files by
  path), textures (by path), or editor-internal entities.
- `.jsn` is a legacy format. It's import-only and converts to `.bsn` on open,
  keeping a `.jsn.bak`.

## 6. Brushes, materials, UVs

- **Adding brushes:**
  - Hierarchy right-click, then `Add > Cube` or `Sphere`.
  - `B` draws a polygon and extrudes it; `Enter` closes, `Backspace` undoes a
    vertex, `Esc` cancels.
  - `Tab` toggles additive and subtractive drawing; `C` starts subtractive.
- **Edit modes:** `1` vertex, `2` edge, `3` face, `4` clip (`Enter` applies).
  `Esc` returns to object mode.
- **Snapping:**
  - `Ctrl` while dragging snaps to the grid, and `MMB` toggles global snapping.
  - `X`, `Y` and `Z` constrain the axis.
  - The grid step shows in the status bar; change it with `[` and `]`.
- **CSG:** `Ctrl+K` subtracts (selection order picks the minuend),
  `Ctrl+Shift+K` intersects, `J` joins when the union is convex.
- **Per-face material and UVs:** in face mode, the inspector exposes UV offset,
  scale and rotation. In the file, each `BrushFaceData` has
  `material: "materials/<name>.bsn"` (empty = the editor's fallback grid).
- **UV math** (`jackdaw_geometry::compute_face_uvs`): planar projection of the
  face's **local** vertex position onto `uv_u_axis`/`uv_v_axis`, rotated by
  `uv_rotation`, divided by `uv_scale`, plus `uv_offset`. Default axes come from
  `compute_face_tangent_axes(normal)`: reference up is `Z` for mostly-vertical
  normals, else `Y`; `u = n × up`, `v = n × u`. So `uv_scale` is metres per
  texture repeat; a texture with N×N cells gets 1 m cells at `uv_scale = N`.
  Brushes are placed with translation and rotation only, so local units stay
  metres.
- **World-aligned cells:** for an unrotated brush at origin `o`, set
  `uv_offset = ((o·u)/scale mod 1, (o·v)/scale mod 1)`.
- **Material files:** one `StandardMaterial` per `.bsn`, e.g.

  ```text
  // jackdaw 0.19.0 | bevy 0.19
  // jackdaw asset bevy_pbr::pbr_material::StandardMaterial
  #greybox_green_grid
  bevy_pbr::pbr_material::StandardMaterial {
      base_color_texture: "textures/GreyboxTextures/greybox_green_grid.png",
  }
  ```

  After writing material files by hand, run `material.rescan`. Renaming a
  material in the editor rewrites the scene's references.
- **Project window** (over `assets/`):
  - Double-clicking an image applies it to the selection (`material.apply_texture`).
  - Dragging a `.glb` into the viewport spawns a model, and dragging a `.bsn`
    spawns an instance.
- **Material Browser:**
  - PBR sets are auto-detected by filename suffix (`_albedo`, `_normal`,
    `_roughness`, `_metallic`, `_ao`, `_height`, ...).
  - Save Material writes `assets/materials/<name>.bsn` by default. Unsaved
    materials are embedded inline in the scene.
- The game needs a `Repeat` image sampler to match editor tiling (§1). Without
  it, tiled faces show one stretched/clamped texture in game and in Play, while
  the editor viewport looks fine (the editor sets `Repeat` for itself).
- Grid textures without mipmaps sparkle at a distance in the viewport; that's
  minification aliasing, not a bug in the material.

## 7. Physics

Avian 0.7.

- **Collider:** add `AvianCollider`, a wrapper around `ColliderConstructor`,
  under the Avian3d category. It auto-adds `RigidBody`, defaulting to
  **Dynamic**. For level geometry, set it to `Static`.
- **Shapes:** primitives, `TrimeshFromMesh` (static only; best for brushes), or
  `ConvexDecompositionFromMesh` for dynamic props.
- **Don't add a raw `ColliderConstructor`** to an entity without `Mesh3d`; it
  panics. The picker hides it for that reason.
- **Physics Tool** (`Shift+P`) simulates only the selected bodies so you can
  drop them into place. `Space` commits as one undo entry; `Esc` reverts.
- **Game side:** the `physics` feature of `jackdaw_runtime` builds colliders
  from authored data.

## 8. Play-in-editor

- **Build:** the editor builds the plain package (no custom features) into
  `.jackdaw/target/game`. Play just launches that binary; nothing compiles at
  play time.
- **Run configurations:** the Play dropdown lists the `[[run]]` entries.
  Private env and args go in **Play Settings**
  (`play.settings env="A=b" args="--x"`).
- **Window modes:**
  - **Embedded** (the default): the game runs offscreen and streams into the
    Game panel, and input capture works. The game must use `maybe_windowless`.
    Every window-targeting camera is retargeted into one capture image.
  - **Windowed:** the game gets its own OS window. The Game panel only mirrors
    it if the game has a `jackdaw_camera_rig::CameraRig` + `ActiveCameraRig`;
    otherwise it shows "no signal" (Quell has no rig).
  - The mode is a persisted editor setting (`pie.window_mode_toggle`); it
    belongs to the user.
- **Game panel:** open it with `window.open` `window_id: "jackdaw.game"`.
- **Viewport during Play:** shows the authored preview with the running game's
  components projected onto it (authored entities matched by `SceneNodeId`,
  runtime-only entities as ephemeral preview entities). Asset handles are sent
  as `null`, so game-loaded models/materials don't render there; this is not
  the game's frame.
- **Performance:** the editor's game build is an unoptimized debug build, so
  Play fps is low. Judge performance from an optimized standalone build.
- **Input capture:** Play mode captures input when you click the panel.
  `Shift+Esc` releases it; plain `Esc` goes to the game.
- **Select mode** picks objects from the game frame, including runtime-only
  ones. Outliner tabs: **Scene** shows authored entities, **Live** shows the
  running game's.
- **Stop and Reload:** Reload applies a window-mode change.
- **Not done yet:** deep live editing, where edits flow back into the running
  game and into the scene.

## 9. Remote control (`jd mcp`)

- **Protocol:** the editor serves BRP on loopback port 15703 while a project is
  open; the game uses 15702.
- **Second editor:** set `JACKDAW_REMOTE_PORT`. **Disable remote control:**
  `.jackdaw/settings.json` → `{"remote":{"enabled":false}}`.
- **MCP client config:** `{"command": "jd", "args": ["mcp", "--project", "<root>"]}`.
- **Tools:**

  | Tool | Purpose |
  | --- | --- |
  | `status` | Project and scene state |
  | `list_operators` | Discover operators by `prefix` |
  | `call_operator` | Run an operator |
  | `batch` | Several calls as one undo entry |
  | `scene_tree(root, depth)` | Scene hierarchy |
  | `get_entity` | Returns BSN |
  | `apply_bsn` | Apply BSN text |
  | `scene_bsn` | Whole scene as BSN |
  | `open_scene` | Open a scene |
  | `save_scene` | Save the current scene |
  | `select(names, frame)` | Select and frame entities |
  | `screenshot(look_at \| kind: "window")` | Capture the viewport or window |
  | `wait(until_idle \| until: "pie_running" \| "pie_stopped")` | Wait for editor state |
  | `cancel` | Cancel a modal operator |
  | `assets` | List assets |

  Resources: `jackdaw://operators` and `jackdaw://scene`.
- **Calling conventions:**
  - Start with `list_operators`.
  - Params are coerced from the operator's schema.
  - `Entity` params take a name or an id.
  - Calls return the entities they created under `entities`.
- **Useful operators:**
  - Entities: `entity.add.cube`, `entity.set_transform`, `entity.place_gltf`,
    `entity.snap_to_ground`, `terrain.height`.
  - Camera: `view.look_at`, `view.orbit`, `view.dolly`.
  - Play: `pie.play`, `pie.stop`.
  - Prefabs: `prefab.pack`, `prefab.pack_matching`.
- **Modal (pointer) operators** leave the editor held. Use their parametric
  equivalents, or `cancel`.
- **Disk writes:** `save_scene`, `screenshot`, and any save, export or bake
  operator. Undo does not reach the disk.

### Direct BRP (no MCP client)

```bash
curl -s -X POST http://127.0.0.1:15703 -H content-type:application/json \
  -d '{"jsonrpc":"2.0","id":1,"method":"jackdaw/status","params":{}}'
```

- Methods served by the editor (0.19.0): `jackdaw/status`, `operators`,
  `call_operator` (`{"id": ..., "params": {...}}`), `batch`, `scene_tree`,
  `scene_bsn`, `apply_bsn` (`{"source": <bsn>, "parent": <name|id>}`),
  `screenshot` (`{"path": <inside project>, "kind": "window"?}`), `wait`,
  `cancel`, `assets`. `jackdaw/entity_bsn` and `jackdaw/diagnostics` are **not**
  served by the editor; read an entity out of `scene_bsn` instead.
- `scene_tree` returns `{tree: [{name, entity, components, children}]}`.
- **Param quirks seen in practice:**
  - `entity.delete` with an `entities` list was refused ("not an entity id");
    call it once per `entity` id. It deletes `Locked` entities too.
  - `screenshot`'s `look_at` didn't move the camera; call `view.look_at`
    (`eye_x/y/z`, `target_x/y/z`) first.
  - `project.build` and `pie.play` return `finished` immediately while work
    continues. `wait {until: "pie_running"}` works; `wait {until_idle: true}`
    did not wait for the build (the game binary's mtime in
    `.jackdaw/target/game/debug/` shows when it finished).
  - `scene.open` takes `{path: "scenes/x.bsn", reload: true}` to reread from
    disk.
- Useful operators beyond §9: `scene.save`, `scene.open`, `material.rescan`,
  `material.apply`, `entity.add.group` (`name`, `parent`), `entity.delete`,
  `entity.set_transform` (`entity`, `x/y/z`, `yaw/pitch/roll`), `selection.select`,
  `window.open`, `pie.play`/`pie.stop`/`pie.reload`.

## 10. SDK and extensions

- **SDK:** a proxy dylib (`libjackdaw_sdk.so`) plus a compiled Bevy/Jackdaw
  closure, pinned to the editor's nightly. The editor and extensions share one
  TypeId universe through it.
- **Resolution order:**
  1. `JACKDAW_SDK_DIR`
  2. The `target/<triple>/` of a dev checkout
  3. The layout next to the executable (release bundle)
  4. The cache at `~/.jackdaw/sdk/<ver>-<toolchain>/`, or under
     `$XDG_DATA_HOME` (on this machine: `~/.local/share/jackdaw/sdk/...`)
- **Building extensions:**
  - Extensions depend on `jackdaw_api`, implement `JackdawExtension`, and can
    register operators, windows, menus and keybinds.
  - `jackdaw-rustc-wrapper` rewrites `--extern bevy=...` so they link the SDK.
- **Distribution:** as signed `.jdext` bundles. Cargo installs can't load signed
  native extensions; use a release bundle for that.
- **Custom editors:**
  `App::new().add_plugins(EnhancedInputPlugin).add_plugins(JackdawEditorPlugins::default())`,
  from `jackdaw_editor`. `EnhancedInputPlugin` must come first.

## 11. Gotchas

- **Component missing from the picker:** usually a missing `Reflect`, a missing
  `#[reflect(Component)]`, a stray `@EditorHidden`, or no rebuild since adding
  the type.
- **Scene load panics:** usually `panic = "abort"` combined with schema drift,
  i.e. a field was renamed or retyped. Fix the `.bsn` file or the type.
- **Brush vanishes after CSG:** the result was degenerate. Undo.
- **Inside-out faces:** the vertices were drawn clockwise.
- **Collider wireframe missing:** the build failed silently. Check that the
  brush has finite volume.
- **Dynamic body falls through:** the floor lacks `AvianCollider` +
  `RigidBody::Static`.
- **Texture not refreshing:** re-select the face.
- **Brush materials reset after Play (upstream bug, `e3e5772` and `main` as of
  2026-09-29):** after Play/Stop the open document holds `material: ""` on every
  brush face, and the scene isn't marked dirty. The next save writes the empty
  materials. Cause: the Play protocol serializes every `Handle<T>` as `null`
  (`jackdaw_pie_protocol/src/snapshot.rs`), and the projection applies the
  streamed `Brush` onto the authored one; asset sync isn't implemented. Workaround:
  reopen the scene from disk (`scene.open` with `reload: true`) before saving.
  Draft issue: `.docs/issues/jackdaw-pie-clears-brush-materials.md` (not filed).
- **Editor may be saving while you edit:** the user may edit and save in the
  editor between your steps (e.g. renaming materials). Re-read the `.bsn` before
  committing or scripting against it.
- **Material missing in the standalone game:** its `.bsn` material file wasn't
  shipped.
- **Empty viewport:** the camera is inside geometry. Press `F` to reframe.
- **Bevy minor mismatch:** it's reported before any build. Override with
  `--allow-bevy-mismatch` or **Set up anyway**.
- **Viewport navigation:** hold RMB and drag to look, `WASD`/`QE` to move,
  `Shift` for double speed, scroll to dolly, `F` to focus. Transform modes:
  `Esc`/`R`/`T`. `Ctrl+D` duplicates, `Ctrl+Z`/`Ctrl+Shift+Z` undo and redo,
  `Ctrl+S` saves, `Ctrl+O` opens, `Ctrl+T` opens a new tab.

## 12. Authoring by script

For geometry that needs exact numbers, build plane-only brushes and send them to
the running editor. Worked example: `.infra/scripts/greybox_stage.py`, which
built Quell's `assets/scenes/greybox_scene.bsn`.

- **Minimal `apply_bsn` source** (one entity, no hierarchy wrapper):

  ```text
  #"Ramp 30deg"
  bevy_transform::components::transform::Transform {
      translation: glam::Vec3 { x: 0.0, y: 1.0, z: -5.73 },
      rotation: glam::Quat { x: 0.0, y: 0.0, z: 0.0, w: 1.0 },
  }
  jackdaw_scene_types::types::Brush {
      faces: [
          jackdaw_geometry::BrushFaceData {
              plane: jackdaw_geometry::BrushPlane { normal: glam::Vec3 { x: 0.0, y: 1.0, z: 0.0 }, distance: 1.0 },
              material: "materials/greybox_green_grid.bsn",
              uv_offset: glam::Vec2 { x: 0.0, y: 0.0 },
              uv_scale: glam::Vec2 { x: 2.0, y: 2.0 },
              uv_rotation: 0.0,
              uv_u_axis: glam::Vec3 { ... },
              uv_v_axis: glam::Vec3 { ... },
          },
          ...
      ],
  }
  bevy_camera::visibility::Visibility::Inherited
  avian3d::dynamics::rigid_body::RigidBody::Static
  jackdaw_avian_integration::AvianCollider(avian3d::collision::collider::constructor::ColliderConstructor::TrimeshFromMesh)
  ```

- **Planes are in local space:** outward unit `normal`, `distance` from the
  brush origin. A convex brush is the intersection of the half-spaces.
- **Omit `topology`.** The editor derives it from the planes
  (`topology_migration.rs`) and writes it on save, which makes saved scenes
  large (a 31-brush stage is about 14k lines).
- **The editor re-centres a brush on its bounding box.** Put the origin at the
  bbox centre yourself so the planes and UV offsets you send are the ones kept.
- **Leave out `SceneNodeId`**; the editor assigns one.
- **Grouping:** `entity.add.group {name}` then `apply_bsn {source, parent: name}`.
- **Save** with `scene.save`, then check the file (brush count, material paths).
