---
name: q-os
description: Map of the qproj library ecosystem in lib/ — q_os (q_proc, q_term, q_shell, plus q_query_lang) and the utility crates q_screens, q_test_harness, q_cam. Covers how the crates layer, the shared frame/schedule model, workspace and repo-in-repo mechanics, cross-crate gotchas, and which deep-dive skill to load next. Use whenever work touches more than one lib/ crate, wires q_os into a game (quell, vn-jun-26), or you need to know which crate owns a concept.
---

# q_os ecosystem

q_os is an OS-kernel metaphor built on bevy_ecs 0.19: **processes** (q_proc)
do multi-frame work and talk over typed **I/O lanes**; a **terminal emulator**
(q_term) renders bytes; a **shell** (q_shell) joins them with job control and a
command language. q_query_lang is a string query language over the World that
shells can expose. Utility crates (q_screens, q_test_harness, q_cam) stand
alone.

> **Maintenance:** this skill is the index of `lib/`. When a crate is added,
> removed, or renamed, update the table and layering diagram below, and give
> the crate a deep dive at `lib/<crate>/.agents/skills/<skill>/SKILL.md`
> symlinked from `.agents/skills/<skill>`.

Deep dives (load the one you need):

| crate            | skill            | one-liner                                                    |
| ---------------- | ---------------- | ------------------------------------------------------------ |
| `q_proc`         | `q-proc`         | `Process` entities, `ProgramLabel`, fd tables, I/O routing   |
| `q_term`         | `q-term`         | VT parser + bevy_ui terminal widget (`Terminal`, `VtUi`)     |
| `q_shell`        | `q-shell`        | Shell process, job/foreground control, keyboard, languages   |
| `q_query_lang`   | `q-query-lang`   | `#Floor \| Children[..] \| Name` → reflected snapshot rows   |
| `q_screens`      | `q-screens`      | Screen lifecycle, screen-scoped entity cleanup               |
| `q_test_harness` | `q-test-harness` | `TestRunnerPlugin`, `add_step`, `InputTestPlugin`, `step`    |
| `q_cam`          | `q-cam`          | Spring-arm follow camera (avian3d), free-camera input gate   |

## Layering

```text
q_shell ──► q_proc        (process model, no rendering)
   │
   └──────► q_term        (terminal; knows nothing about processes)
q_shell (dev-dep) ──► q_query_lang   (query_shell example only)
everything (dev-dep) ──► q_test_harness
```

- q_term is process-agnostic: its only hook is the opaque
  `VtForegroundProcess` relationship and `VtWriteMsg.from`.
- q_proc is endpoint-agnostic: it routes `ProcessWriteMsg<T>` to whatever
  `IoComponent` an fd points at and emits `EndpointWriteMsg<T>`.
- q_shell is the adapter: `TerminalIoEndpoint` (an `IoComponent` on the
  terminal entity) translates `EndpointWriteMsg<Vec<u8>>` → `VtWriteMsg`, and
  line-discipline/VT replies → `ProcessInputMsg<TerminalInputPayload>`.
- Planned but not yet present: `q_shell_lang` (qscript), `q_coreutils`.
  Designs: `.docs/designs/q_os design.md`, `q_shell_lang-design.md`.

## Frame model (defaults)

Full diagrams: `.docs/designs/q_os-schedule-ordering.md` (one detail is stale:
q_term's `refresh_ui` now runs in `TerminalSystems::Render` in `Update`, not
`PostUpdate`).

- `First`: `ProcessSystems::QueueInput` demuxes `ProcessInputMsg<T>` into each
  process's `ProcessInputBuffer<T>`, then `ProcessSystems::Cleanup`.
- Every std update schedule (`PreUpdate`, `Fixed*Update`, `Update`,
  `PostUpdate`): `RunPrograms → ApplyDeferred → RouteWrites → Cleanup`.
- `Update` with a shell: `TerminalSystems::Input → ShellSystems::Spawn →
  ShellSystems::Foreground → ShellIoSystems::SyncForeground → RunPrograms →
  … → ShellIoSystems::ProcessOutput → TerminalSystems::Process →
  ShellIoSystems::TerminalReplies → TerminalSystems::Render`.

Consequences you will hit:

- **Input is one frame late.** Keyboard → stdin emitted in `Update` is visible
  to programs only after the next frame's `First`.
- **Output is same-frame** in `Update`; output written in `PostUpdate` reaches
  the terminal on the following `Update`.
- Writes from a process that exits this frame still route (descriptors are
  cached in `ClosingProcessIo` until the next routing pass).

## Cross-crate gotchas

- **Register before spawn.** A `Process` gets its program marker only if the
  program was registered (`app.program::<T>()`) when `Process` was inserted.
  Likewise add `ShellPlugin` before spawning `Shell`s.
- **q_screens will eat your terminal.** Screen cleanup despawns every entity
  not marked `Persistent` (or a registered persistent type). A `Terminal`,
  `VtUi`, `Shell` or process spawned at `Startup` dies on the first screen
  change unless you mark it (`Persistent`, or `Propagate(Persistent)` for
  hierarchies) — or spawn it inside the screen intentionally.
- **Signals are declared, not handled.** `Sig`/`SignalMsg` exist and q_shell
  writes `Sig::Hup` on terminal hang-up, but nothing consumes them yet;
  `Process::signal_overrides` is unused. Don't build on signal delivery
  without implementing it.
- **quell's dev console is stale.** `bin/quell/src/service/dev/console/` uses a
  removed q_term API (`ConsolePlugin`, `add_console_command`, `CommandMsg`).
  Do not copy it as a pattern; the current path is q_shell programs.

## Workspace & repo mechanics

- Each `lib/<crate>` is its **own git repo** (repo-in-repo; untracked by the
  org repo). Commit/branch/PR inside the crate directory, never stage `lib/`
  at the org root.
- Crates depend on each other by **git URL**; the org `Cargo.toml` has
  `[patch."https://github.com/cubething-qproj/<crate>"]` entries pointing at
  `lib/<crate>`. Locally you build against your working copies; CI for a
  standalone crate builds against the dependency's `main`. Cross-crate changes
  must land upstream-first (q_proc/q_term → q_shell → games).
- Verify from the **org root** only: `just check -p <crate>` and
  `just test -p <crate>` (nextest). Never build in `/tmp`.
- Every crate has a default `dylib` feature (`bevy/dynamic_linking`).
- Conventions shared by all crates: `prelude` re-exports `bevy::prelude::*`
  and `tiny_bail::prelude::*` (`r!`, `rq!`, `c!`, `cq!` early-return/continue
  macros); `data/` holds types, `systems/` holds systems, `plugins.rs` wires
  them; integration tests live in `tests/`.
