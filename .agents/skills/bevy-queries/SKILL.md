---
name: bevy-queries
description: Reference for Bevy 0.19 ECS queries — Query<D, F> syntax and methods, QueryData (built-ins and derive), QueryFilter, QueryBuilder, and how Query fits into SystemParam, plus performance characteristics (complexity, storage, parallelism) and ergonomics. Use when writing or reviewing systems that access components through Query, building dynamic queries with QueryBuilder, defining custom query data or filters, or debugging query access conflicts and compiler errors.
---

# Bevy Queries (bevy_ecs 0.19)

All APIs verified against `bevy_ecs 0.19.1`, the version pinned in this
workspace. Other Bevy versions differ (e.g. `single()` panics before 0.16).

## Systems are not queries

A **query** is a view over the `World`: "give me this data, for entities
matching these conditions." A **system** is a scheduled function that _uses_
queries (and other params) to do work. Keep the two firmly separate:

- `Query` is one kind of `SystemParam`. Systems take queries as arguments;
  a system is not a query, and a query is not a system.
- A system may have zero queries, one, or many. A query can also exist
  entirely outside systems (`QueryState` + `&mut World`).
- Bevy schedules systems in parallel based on the _access_ their queries
  declare (which components are read/written, plus filters). Two systems
  conflict if and only if their combined param access conflicts.
- When debugging "my system doesn't see X", separate the concerns: matching
  (query semantics) vs. scheduling/ordering (system concerns).

## Anatomy: `Query<D, F>`

```rust
Query<'w, 's, D: QueryData, F: QueryFilter = ()>
```

- `D` (the _data_): what to fetch for each matching entity.
- `F` (the _filter_): which entities match. Defaults to `()` (all). Filters
  never grant component access.
- Items: `D::Item<'w, 's>` is what mutable access yields (`iter_mut`,
  `get_mut`); `D::ReadOnly` is the read-only variant yielded by `iter`/`get`
  (`ROQueryItem<'w, 's, D>`).

Common shapes:

```rust
Query<&Transform>                                   // read
Query<&mut Transform>                               // write
Query<(Entity, &Name)>                              // tuples, up to 15
Query<&Transform, With<Camera>>                      // data + filter
Query<&Transform, (With<Camera>, Without<Disabled>)> // filter tuples are AND
Query<(Option<&Children>, &Name)>                    // optional component
Query<AnyOf<(&A, &B)>>                               // match if any present
```

Iteration:

| Method                                  | Yields                                         |
| --------------------------------------- | ---------------------------------------------- |
| `iter()`                                | read-only items                                |
| `iter_mut()`                            | mutable items                                  |
| `iter_combinations::<K>()` / `_mut`     | all K-sized combinations                       |
| `iter_many(entities)` / `iter_many_mut` | specific entities, skips non-matching          |
| `iter_many_unique[_mut]`                | same, for guaranteed-unique entity sets        |
| `par_iter()` / `par_iter_mut()`         | parallel iteration (`multithread` feature)     |
| `contiguous_iter[_mut]`                 | only for `ContiguousQueryData` (dense storage) |

Point lookups:

| Method                                 | Returns                                                          |
| -------------------------------------- | ---------------------------------------------------------------- |
| `get(e)` / `get_mut(e)`                | `Result<item, QueryEntityError>`                                 |
| `get_many([a, b])` / `get_many_mut`    | array of items, all-or-nothing                                   |
| `single()` / `single_mut()`            | `Result<item, QuerySingleError>` — no panicking variants in 0.19 |
| `is_empty()`, `contains(e)`, `count()` | metadata — complexities differ, see Performance                  |

## QueryData — the `D`

`QueryData` is an unsafe trait; use built-ins or `#[derive(QueryData)]`.

Built-in data:

| Type                                      | Yields                        | Notes                                                                                      |
| ----------------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------ |
| `&T` / `&mut T`                           | `&T` / `&mut T`               | component access                                                                           |
| `Entity`                                  | `Entity`                      | no access                                                                                  |
| `EntityLocation`                          | archetype/table location      |                                                                                            |
| `Option<D>`                               | `Option<item>`                | also matches entities lacking `D`                                                          |
| `Has<C>`                                  | `bool`                        | presence check, no access                                                                  |
| `AnyOf<(A, B, ...)>`                      | `(Option<A>, Option<B>, ...)` | matches if _any_ present                                                                   |
| `Ref<T>` / `Mut<T>`                       | change-detection wrapper      | `is_added()`, `is_changed()`, `last_changed()`; `Mut` adds `set_changed()`, `set_if_neq()` |
| `SpawnDetails`                            | spawn info                    | `is_spawned()`, `spawn_tick()`, `spawned_by()`                                             |
| `EntityRef` / `EntityMut`                 | all components of an entity   |                                                                                            |
| `FilteredEntityRef` / `FilteredEntityMut` | dynamic access                |                                                                                            |
| `PhantomData<T>`                          | `()`                          | generic marker                                                                             |
| tuples                                    | tuple of items                | up to 15                                                                                   |

Marker traits (implemented automatically where possible):
`ReadOnlyQueryData` (makes `Query` `Copy`/`Clone`), `IterQueryData`
(required by most iteration methods), `SingleEntityQueryData` (required by
`transmute_lens`/`join`), `ArchetypeQueryData`, `ContiguousQueryData`
(required by `contiguous_iter`).

### Custom data with `#[derive(QueryData)]`

```rust
#[derive(QueryData)]
struct PlayerKit<'a> {
    weapon: &'a Weapon,
    armor: Option<&'a Armor>,
}
// fn system(kits: Query<PlayerKit>) — items are PlayerKit<'_> with those fields
```

- Mutability is inferred from field types. If hidden behind a generic
  parameter, force it with `#[query_data(mutable)]`.
- A read-only variant (`D::ReadOnly`) is generated automatically.
- `#[query_data(ignore)]` excludes a field from the item type.
- `#[query_data(derive(...))]` and `#[query_data(contiguous(...))]` also exist.

## QueryFilter — the `F`

Filters restrict _which entities match_ — they never grant access:
`Query<&A, With<B>>` cannot read `B`.

| Filter                    | Matches                                                                     |
| ------------------------- | --------------------------------------------------------------------------- |
| `With<C>` / `Without<C>`  | has / lacks `C` (archetypal — cheap)                                        |
| `Added<C>` / `Changed<C>` | `C` added/changed since this system last ran (per-system ticks, not global) |
| `Spawned`                 | entity spawned since this system last ran                                   |
| `Or<(F1, F2, ...)>`       | any sub-filter matches                                                      |
| `Allow<C>`                | bypasses `DefaultQueryFilters` (entity disabling/visibility)                |
| tuples `(F1, F2, ...)`    | all match (AND), up to 15                                                   |

Common confusion — these are **not** filters:

- `Has<C>`, `Option<D>`, `AnyOf<...>` — _data_ types.
- `Populated<D, F>` and `Single<D, F>` — _SystemParams_ (see below).

Custom filters with `#[derive(QueryFilter)]` (fields are ANDed):

```rust
#[derive(QueryFilter)]
struct IsPlayer {
    with_marker: With<PlayerMarker>,
    not_dead: Without<Dead>,
}
// fn system(hp: Query<&Health, IsPlayer>)
```

`With`/`Without` are archetypal (`ArchetypeFilter`): resolved from archetype
membership alone. `Added`/`Changed`/`Spawned` are _not_ — they check
per-entity change ticks (see Performance for what that costs).

## QueryBuilder

For dynamic (runtime-constructed) queries — editor tooling,
plugin-configurable filters. Static queries should just be written as types.

```rust
let mut state = QueryBuilder::<(Entity, &mut Transform)>::new(&mut world)
    .filter::<With<Camera>>()
    .or(|b| {
        b.with::<A>();
        b.and(|b2| {
            b2.with::<B>();
            b2.without::<C>();
        });
    })
    .build(); // QueryState<(Entity, &mut Transform), ...>
for (e, mut t) in state.iter_mut(&mut world) { /* ... */ }
```

- `data::<T>()` — append data.
- `filter::<T>()` — append filter (AND).
- `with::<T>()` / `without::<T>()` — shorthand; `with_id`/`without_id`/
  `ref_id`/`mut_id` take runtime `ComponentId`s.
- `or(|b| ...)` — OR group; `and(|b| ...)` — nested AND group inside `or`.
- `optional(|b| ...)` — optional access.
- `transmute::<NewD>()` / `transmute_filtered::<NewD, NewF>()` — reinterpret.
- `build()` returns `QueryState<D, F>`, **not** a `Query`. `QueryState`
  methods take the world explicitly: `state.iter(&mut world)`,
  `state.get(&mut world, e)`.

Related `World` shortcuts: `world.query::<D>()` and
`world.query_filtered::<D, F>()` return `QueryState`. There is no
`World::query_builder` in 0.19 — use `QueryBuilder::new(&mut world)`.

## SystemParam footnotes

`Query` is one member of the `SystemParam` family. The trait:

```rust
pub unsafe trait SystemParam {
    type State: Send + Sync + 'static;  // initialized once per system
    type Item<'world, 'state>: SystemParam<State = Self::State>; // borrowed each run
}
```

- `Query`'s impl: `State = QueryState<D, F>`, `Item = Query<'w, 's, D, F>`.
- Query-flavored params:
  - `Single<D, F>` — requires exactly one match; the system is _skipped_
    (param validation failure) otherwise. Derefs to the item; use
    `Option<Single<D, F>>` for zero-or-one.
  - `Populated<D, F>` — requires at least one match, else system skipped.
    Derefs to `Query`.
- Other params commonly mixed with queries: `Res`/`ResMut`, `Local`,
  `Commands`, `MessageReader`/`MessageWriter` (0.19: events are _messages_),
  `NonSend`/`NonSendMut`, `World`, `Deferred`, `ParamSet`.
- `ParamSet<(...)>` resolves access conflicts: two queries in one system that
  would conflict (e.g. `&mut T` twice) must go through a `ParamSet`.
- `#[derive(SystemParam)]` groups params into a reusable struct.

Remember: all of these are _inputs to systems_. The system is the scheduled
function; queries and other params are how it sees the world.

## Performance

### Access and parallelism

- Creating a `Query` is a low-cost constant operation; **iteration** is where
  the cost is (fetching data and generating items).
- Request `&mut` only when necessary: two systems cannot run in parallel if
  both access a component and at least one access is mutable — read-only
  access can be parallelized.
- Filters (`With`/`Without`) _improve_ performance: they narrow the kinds of
  entities fetched, so systems access fewer archetypes and are more likely to
  be parallelized.
- `Option<&T>` and `EntityRef` _broaden_ the query: they match more entity
  kinds. A query fetching **only** optional components or `EntityRef` iterates
  every entity in the world. `AnyOf` similarly broadens (union of terms).
- Filter access matters for conflicts: `Added<T>`/`Changed<T>` add **read
  access** to `T` (same as `&T`; inside `Or`, same as `Option<&T>`), so they
  conflict with `&mut T` elsewhere. `Spawned` and `Has<T>` add no access.

### Complexity

From the official `Query` docs (n = matching entities, r = combination size,
k = involved entities, a = archetypes in the world):

| Operation                                                | Complexity                                   |
| -------------------------------------------------------- | -------------------------------------------- |
| `iter` / `iter_mut`                                      | O(n)                                         |
| `for_each` / `par_iter[_mut]`                            | O(n)                                         |
| `iter_many[_mut]`                                        | O(k)                                         |
| `iter_combinations[_mut]`                                | O(nCr) — explodes quickly for r > 2          |
| `single` / `single_mut`                                  | O(a) — not O(1)                              |
| `get` / `get_mut`                                        | O(1)                                         |
| `get_many`                                               | O(k); `get_many_mut` O(k²) (conflict checks) |
| archetypal filtering (`With`/`Without`/`Or`)             | O(a)                                         |
| change-detection filtering (`Added`/`Changed`/`Spawned`) | O(a + n)                                     |
| `is_empty`                                               | O(n) worst case, over _potential_ matches    |
| `contains`                                               | O(1)                                         |
| `count`                                                  | O(n)                                         |

### Storage and iteration speed

- Two component storage types: `Table` (default) — fast iteration, slower
  add/remove; `SparseSet` — fast add/remove, slower iteration. Opt in per
  component with `#[component(storage = "SparseSet")]`.
- Archetype fragmentation (many archetype/table boundaries) slows iteration.
  `iter().for_each(...)` can beat `for` loops on fragmented worlds and may
  autovectorize — but _always benchmark before and after_.
- `contiguous_iter[_mut]` yields per-table **slices** of contiguously stored
  components (SIMD-friendly), but only for `ContiguousQueryData` (dense
  queries); returns `Result<_, QueryNotDenseError>`.
- Archetypal queries (`D::IS_ARCHETYPAL && F::IS_ARCHETYPAL`) get exact
  `size_hint`s, so `collect()` can preallocate; `is_empty` takes an `as_nop`
  fast path. `Added`/`Changed`/`Spawned` make a query non-archetypal.

### State reuse

- `QueryState` construction scans the world's archetypes. When querying a
  `World` directly, **store** the state and reuse it — don't call
  `world.query()` every frame. Inside systems this is handled for you:
  state is initialized once per system.
- `transmute_lens` / `join` reuse an existing query's state instead of
  building a fresh one.

### `Single` and `Populated` costs

- `Single` is **not** a search optimization. It is a validation with _slight
  overhead_ compared to `Query` (per the docs). Reach for it for the
  declarative skip semantics, not speed.
- `Populated` (and `Query::is_empty`) is O(n) worst case over _potential_
  matches — notably expensive with non-archetypal filters (`Added`,
  `Changed`, `Spawned`), which check each candidate. If the system doesn't
  need the query results, prefer run conditions (`any_with_component`,
  `any_match_filter`).

### `par_iter`

- Requires the `multithread` feature; without it, behaves like `for_each`.
- Iterate with `.for_each(...)` (it is not a normal `Iterator`).
- Batching is tunable via `BatchingStrategy` on `QueryParIter`.

## Ergonomics

### Declarative validation params

`Single` and `Populated` (see SystemParam footnotes) double as ergonomic
alternatives to manual checks:

- `Single` needs no `Result` handling: fields and methods are usable directly
  via `Deref`/`DerefMut`, and `into_inner()` destructures tuple items. The
  system simply doesn't run when validation fails.
- Contrast `Query::single()`: you handle the `Result` yourself, and the
  system still runs.

### Passing queries around

- Read-only queries (`D: ReadOnlyQueryData`) are `Copy`/`Clone` — pass them
  freely.
- `reborrow()` lends a short-lived mutable `Query` to a helper while keeping
  the original usable afterwards.
- `as_readonly()` / `into_readonly()` get a read-only view of a mutable query
  (borrow-checker workaround, helper reuse, and it enables parallelism).
- `QueryLens` (`transmute_lens`, `join`) hands helpers a restricted view
  without re-matching the world.

### Data/filter duality

Filters and data types often come in pairs — use the _filter_ to narrow
matches, the _data_ when you need all matching entities but want per-entity
answers:

| Filter                      | Data twin                           |
| --------------------------- | ----------------------------------- |
| `Changed<T>`                | `Ref<T>` + `.is_changed()`          |
| `Added<T>`                  | `Ref<T>` + `.is_added()`            |
| `Spawned`                   | `SpawnDetails` + `.is_spawned()`    |
| `With<C>` (narrows matches) | `Has<C>` (yields `bool`, no access) |

- `Mut::set_if_neq(...)` only flags a change when the value actually differs —
  less spurious downstream `Changed` work.
- `Mut::bypass_change_detection()` skips tick updates entirely — risky escape
  hatch (e.g. avoiding infinite sync loops); downstream systems won't see the
  change.

### Targeted access

- One entity: `get`/`get_mut`. Fixed set: `get_many[_mut]`. Runtime list:
  `iter_many[_mut]` (skips non-matching). See Complexity for costs.
- The `_unique` variants (`iter_many_unique`, `get_many_unique`, ...) skip
  duplicate-entity checks when uniqueness is guaranteed by type
  (`EntitySet`, `UniqueEntityArray`) — use them when you can.

### Named query shapes

- `#[derive(QueryData)]` replaces mystery tuples with named fields and makes
  query shapes reusable across systems (see Custom data, above).

## Gotchas

- `q.iter()` on `Query<&mut T>` yields `&T` — use `iter_mut()` to mutate.
- `Changed<T>` only fires on changes through `Mut`/`&mut` (DerefMut).
  Interior mutation (e.g. a `Mutex` inside a component) is invisible to
  change detection unless you call `set_changed()`.
- Query iteration order is not guaranteed — sort results if order matters.
