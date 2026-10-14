## Where tests go

- **Unit tests** go in `src/`, in a `test.rs` next to the code they test. They
  cover pure logic and single systems.
- **Integration tests** go in `tests/`. If a test needs a fixture, an app
  running across several frames, or more than one module, it's probably an
  integration test.

## Use the harness

Use [q_test_harness](https://github.com/cubething-qproj/q_test_harness) rather
than hand-rolled app setup. We dogfood it, so if something is missing, add it
there instead of working around it locally. Keep game types out of the
harness. See the `q-test-harness` skill.

- **Full-app tests** (`TestRunnerPlugin`, `add_step`) cover lifecycle and
  scheduling: screen transitions, loading, entity cleanup, ordering across
  plugins.
- **Selected-schedule tests** (`InputTestPlugin`, `AppExt::step`) cover precise
  mechanics: feed input, step the schedules you name, and check the result.

Choose deliberately. A passing selected-schedule test says nothing about the
phases it skipped.

## Fixtures

When several tests share setup, write a small fixture local to the test. It
owns a normal `App` and the `Entity` IDs it cares about, and has methods for
scenario setup, actions and assertions. Each test should then read as a
sequence of behaviours.

Keep fixtures local and simple. Don't build a generic fixture framework.
Machinery that's worth reusing belongs in q_test_harness.

## What to test

- Test behaviour and edge cases, not implementation details.
- Avoid change-detector tests: don't assert on tuning constants, screen order,
  or anything else that just _happens_ to be true.
- If a test really checks a library's behaviour, it belongs in that library.
  Open an issue upstream instead of testing it here.
- Game feel isn't something automated tests can check. Playtest it.
