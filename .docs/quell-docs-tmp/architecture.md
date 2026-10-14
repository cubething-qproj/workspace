## Overview

Quell is built from four kinds of module. Each answers a different question:

| module      | question it answers                      | has systems? |
| ----------- | ---------------------------------------- | ------------ |
| `screens/`  | _When_ does something run?               | yes          |
| `services/` | _What_ does the game do?                 | yes          |
| `config/`   | _How_ is the app and its crates set up?  | no           |
| `shared/`   | _What_ do several modules need in common? | no           |

```text
src/
├── screens/   # compose services
├── services/  # systems that screens switch on and off
├── config/    # app-wide configuration: themes, external crate setup
├── shared/    # reusable code with no systems: components, widgets, helpers
├── plugin.rs  # AppPlugin: wires the four together
├── lib.rs     # exports and docs only
└── main.rs    # builds the App
```

The rule of thumb: **services provide behaviour, screens decide when it
runs.** A service shouldn't know which screens use it, and a screen shouldn't
reimplement what a service does.

## Screens

A screen is a scope of the game, like a scene or a room in other engines. This
isn't Bevy's `Scene`, which is a serialized world. Screens come from
[q_screens](https://github.com/cubething-qproj/q_screens); see the `q-screens`
skill for the full API.

A screen owns:

- **Composition.** It picks which services run, and in which of its schedules
  (`ScreenSchedule::Update`, `FixedUpdate`, `OnReady`, ...).
- **Loading.** Asset readiness is gated in the screen's `Loading` schedule by
  calling `finish_loading()`. Don't build separate loading states. q_screens
  already has a load/unload state machine.
- **Lifetime of its entities.** When a screen unloads, every entity that isn't
  `Persistent` is despawned. Spawn screen content freely and let cleanup handle
  it. Anything that must survive a screen change (a camera, a UI root, a
  terminal) needs to be marked deliberately. Use `Propagate(Persistent)` for
  hierarchies.

Screens shouldn't contain gameplay logic beyond setup and teardown. If a
screen's systems start growing, that's a service waiting to be extracted.

Dev screens live under `screens/dev/` and are gated behind the `dev` feature.
They work as sandboxes: one feature, isolated, with whatever debug tooling it
needs.

## Services

A service is a plugin that exposes systems. It provides the data types,
resources, observers and systems for one area of the game.

Services expose their scheduled systems as `ServiceSystems` rather than adding
them to a global schedule:

```rust
// services/my_service/systems.rs
pub fn my_service_systems() -> ServiceSystems {
    ServiceSystems::new((tick, apply).chain())
}

// screens/my_screen/screen.rs
builder.add_systems(ScreenSchedule::Update, my_service_systems().take());
```

This keeps the service reusable. The same service can run in the game and in a
dev sandbox without knowing about either.

Guidelines:

- **Services should be stateless where possible.** Prefer data on entities
  over global state machines. When a flow really needs states, the screen
  that owns the flow should drive them.
- **Services don't scope themselves.** They don't call `configure_sets` with
  `run_if` conditions tied to a particular screen. Scoping belongs to whoever
  composes them.
- **Expose settings as resources.** Anything tweakable (speeds, distances,
  timings) goes in a `Resource` with a sensible `Default`, never a static or a
  hard-coded constant buried in a system. That way values can be changed at
  runtime and through the inspector.
- **Multi-frame work will become programs.** Long-term, services compose
  [q_proc](https://github.com/cubething-qproj/q_proc) programs: process
  entities that do work across many frames and talk over typed I/O. See the
  `q-os` and `q-proc` skills. When a service starts growing ad-hoc
  "in-progress" components and timers, consider whether it's a program.

### Third-party plugins

Plugins from other crates add global systems that can't be switched off per
screen. They stay global, and **their components act as the switch**. For
example, a camera controller only acts on entities with its component, so
only screens that want it spawn one.

Long-term, q_screens should be able to configure any system set from the
screen side
([q_screens#45](https://github.com/cubething-qproj/q_screens/issues/45)).
Until then, don't fight a global plugin with run conditions. Control it by
what you spawn.

## Config

Config is app-wide setup that isn't systems:

- registering and configuring external crates (physics, input, editor runtime,
  ...);
- the UI theme.

It's called `config/` rather than `settings/` so it isn't confused with
player-facing game settings (graphics, audio, controls). Those are a
_service_, because the player changes them at runtime.

### Themes

There are two themes: one for dev tools and one for game UI. Feathers has a
single global `UiTheme`, but its tokens are named strings, so both sets live
in the same `UiTheme`:

- **Dev tools** use feathers' own tokens. Feathers is designed for editor and
  tool UI.
- **Game UI** uses our own namespaced tokens, such as `game.panel.bg`.

Never hard-code colours in a widget. Look them up by token so the theme can
change in one place.

## Shared

Shared is reusable code with no systems: helper types like `ServiceSystems`,
common components, and reusable UI widgets (`shared/ui/`).

If something in `shared/` needs a system to work, it has become a service.

## The prelude

Each module exposes a `prelude` with its public types and its submodules'
preludes. The crate prelude collects them, along with re-exports of the
external crates used everywhere. Most files only need:

```rust
use crate::prelude::*;
```

Keep module internals private. Export only what other modules actually use.

## Module layout

Inside a screen or service, separate the ontology (types) from the semantics
(systems):

```text
my_module/
├── mod.rs      # exports and prelude
├── plugin.rs   # scheduling, type registration, resources
├── data.rs     # components, resources, assets, other types
├── systems.rs  # systems and observers
└── test.rs     # unit tests
```

A screen uses `screen.rs` for its `Screen` impl instead of `plugin.rs`. Split
any of these into a directory once it gets large. As a rule of thumb, if it
doesn't _do_ anything it belongs in `data.rs`.

Within a file, read top to bottom: module docs, imports, prelude, types (consts,
then plain types, then types with impls), free functions, plugin, tests.
Prefer associated functions and trait impls over free functions, so behaviour
stays next to the type it belongs to.

## Where does this go?

- It runs every frame or reacts to events, and it's game behaviour → a
  **service**.
- It decides what's active, loads assets, or spawns a level → a **screen**.
- It configures an external crate or the look of the UI → **config**.
- It's a type or widget several modules use, with no systems → **shared**.
- It's useful outside quell → probably a crate in `lib/`. See the `q-os`
  skill for what already exists.
