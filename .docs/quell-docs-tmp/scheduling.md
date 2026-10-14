## Systems, observers, and messages

Bevy offers three ways to run logic. Pick the one that matches how the work is
triggered:

- **Systems** for _pull_ work: anything that happens every frame or on a
  timer. Examples are input handling, movement, physics-driven behaviour and
  polling. Use `FixedUpdate` for simulation that must be framerate-independent
  and `Update` for presentation and input.
- **Observers** for _push_ work: reactions to discrete events, especially
  ones aimed at a particular entity (`EntityEvent`s, component lifecycle
  hooks, `ProcessExited`). They run right away and cost nothing when idle.
- **Messages** for buffered communication between systems, where the
  reader runs at a known point in the schedule and may handle several messages
  per frame.

Don't force everything into one style. A per-frame loop rewritten as
self-triggering observers is harder to follow. A one-off reaction polled every
frame wastes work and hides intent.

### Entity-scoped observers

When only some entities care about an event, prefer an entity observer
(`commands.entity(e).observe(...)`) or an `EntityEvent` targeted at them over a
global observer that filters. Relationships are a good way to model "this
entity listens to that one".

## Scoping

Run conditions for a screen come from **the screen**, not the service. See
[architecture](crate::docs::architecture). A service hands over its systems as
`ServiceSystems`, and the screen adds them to one of its `ScreenSchedule`s,
which only run while that screen is active.

Reach for raw `configure_sets` + `run_if` only for state that isn't a screen.
An example is a gameplay sub-state inside a screen, and in that case the screen
that owns it should set it up.

## Ordering

- Libraries expose public `SystemSet`s for their phases (`ProcessSystems`,
  `TerminalSystems`, `ShellSystems`, ...). Order your systems relative to
  those sets, not to individual library systems.
- Order explicitly when it matters (`.chain()`, `.before()`, `.after()`).
  Don't rely on whatever order the systems happen to run in. Ambiguous order is
  a common source of off-by-one-frame bugs.
- Know your latency. In q_os, input reaches programs one frame late, and
  output written in `PostUpdate` shows up the following frame. See the `q-os`
  skill's frame model before building something timing-sensitive on top of it.
