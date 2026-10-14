## The workspace

Quell is one crate in the qproj organization, which builds as a **single Cargo
workspace at the org root**. The `lib/` crates (q_screens, q_proc, q_cam, ...)
are separate git repos. Quell depends on them by git URL, and the org
`Cargo.toml` patches them to the local checkouts. This means:

- Run every command **from the org root** so all crates share one target
  directory.
- Cross-crate changes land upstream first: change and merge the library, then
  update quell.
- Before writing something generic, check whether a `lib/` crate already owns
  the concept. Start with the `q-os` skill, which maps the ecosystem and points
  to a deep-dive skill per crate.

## Commands

The org `justfile` is the entry point. Run `just` to list recipes. The ones
used every day:

- `just check -p quell`: lint with Clippy.
- `just test -p quell`: run tests with nextest.

## Features

- `dev`: dev screens, dev tooling (inspector, feathers UI, free camera) and
  command-line arguments. Release builds leave it off.
- `dylib`: dynamic linking for faster incremental builds.
- `jackdaw`: integration with the Jackdaw level editor.

Anything for debugging or development only goes behind `dev`. A release build
shouldn't contain sandboxes or debug panels.

With `dev` enabled, the binary takes command-line arguments. `--help` lists
them. The most useful is `--screen <name>`, which starts directly on a screen,
including dev sandboxes.

## Levels

Levels are authored in [Jackdaw](https://github.com/jbuehler23/jackdaw) and
saved as `.bsn` scenes. Gameplay components that should be placeable in the
editor have to be registered and reflected. See the `jackdaw` skill.

Prefer data authored in the editor over level layout hard-coded in Rust. A
screen should load a scene and let components on its entities set up
behaviour.

## Documentation

These docs describe principles, not inventory. Don't list the current
services, screens or files here. They go stale, and the source tree is a
better listing. Document _why_ something is structured the way it is, and put
_what_ a type does in its doc comment.

Every public item gets a doc comment. So does any function whose
implementation isn't obvious, with a comment that states its intent.
