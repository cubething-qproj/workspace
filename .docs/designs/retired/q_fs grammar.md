> Superseded by [`q_query_lang design.md`](../done/q_query_lang%20design.md).

# q_fs grammar semantics (v0)

Status: **normative companion** to [`grammar.ebnf`](grammar.ebnf). The ABNF
file is the sole syntax definition; this file defines the meaning of its
productions and holds the parser-validation corpus.

Validated with [declaresub/abnf](https://github.com/declaresub/abnf)
(`Rule.load_grammar` + `parse_all`). Re-run
`tmp/grammar-validation/validate.py` whenever either file changes.

## Lexical conventions

- `IDENT` matches `[A-Za-z_][A-Za-z0-9_]*`. v0 resolves short names only.
- The language is whitespace-free except inside predicates and quoted names.
- Keywords are contextual, not reserved: a component named `optional` remains
  addressable as `optional` unless followed by `(` in fetch position.
- Unknown component or relationship names are loud query errors. A typo never
  becomes an empty result.

## Query and path

`|` is **sequence union** with duplicate nodes removed. It is not `AnyOf`:
an entity carrying components from both branches contributes both nodes.

`single(query)` asserts exactly one result; zero or many is an error.

Steps compose left to right. Each step flat-maps over the current sequence.
Absence drops a value; a type-invalid step is an error.

An omitted prefix is `//`, the world scan. `/` selects root entities. `//`
is descendant-or-self traversal and is also valid between steps. Scan order
is an implementation detail and must not be relied upon.

## Node steps and relationship axes

A node step selects entities:

- `#Name` selects entities by `Name`. At the beginning of an unprefixed query,
  it scans the world. After an entity, it uses the default `Children`
  relationship.
- `*` selects every entity on the same default relationship.
- `..` is sugar for `ChildOf::*`.
- `R::test` follows relationship component `R`, then applies `#Name` or `*` to
  the related entities. `R` must implement Bevy's `Relationship` or
  `RelationshipTarget`; arbitrary Entity-valued fields do not qualify.

Examples:

```text
#Floor/#"Floor West"        ≡ #Floor/Children::#"Floor West"
#Floor/*                    ≡ #Floor/Children::*
#Floor/Children::#West      explicit relationship traversal
#Floor/..                   ≡ #Floor/ChildOf::*
```

A relationship is still a component. Fetching it and following it are distinct:

```text
#Floor/Children             fetch Query<&Children>
#Floor/Children::*          follow Children to all child entities
```

This is why bare component fetches and `R::test` are not ambiguous: `::`
selects relationship traversal; without it, the identifier is query data.

## Fetch steps (`QueryData`)

A bare type fetches a component. `@` is reserved exclusively for `Entity`:

| syntax       | verbose            | `QueryData`      | behavior                              |
| ------------ | ------------------ | ---------------- | ------------------------------------- |
| `T`          | —                  | `&T`             | required; absent skips the entity     |
| `@`          | `Entity`           | `Entity`         | entity id                             |
| `?T`         | `optional(T)`      | `Option<&T>`     | entity retained; `None` if absent     |
| `^T`         | `mut(T)`           | `&mut T`         | required; records a write claim       |
| `?^T`        | `optional(mut(T))` | `Option<&mut T>` | retained; records a write claim       |
| `boolean(T)` | —                  | `Has<T>`         | component presence as data; no access |
| `ref(T)`     | —                  | `Ref<T>`         | read plus change ticks                |

`@T`, `?@`, and `^@` are syntax errors. `@` is sugar for the builtin
`Entity`; `Entity` is reserved and is never resolved as a component. `?Entity`
and `^Entity` are semantic errors. Omission never means `Entity`.

Resources are out of scope. Tuple `QueryData` and `AnyOf` are deferred.

## Predicates (`QueryFilter`)

Predicates attach to the step they follow. A bare predicate is invalid because
a query must state its data explicitly:

```text
Brush[+Visible -Hidden]
@[+Brush]
```

Presence filters:

| syntax | verbose      | Bevy filter  |
| ------ | ------------ | ------------ |
| `+T`   | `with(T)`    | `With<T>`    |
| `-T`   | `without(T)` | `Without<T>` |

Space and `and` are AND; `or` is OR; `not(...)` negates; parentheses group.
The filters test the source entity even when attached to a component fetch:
`Foo[+Bar]` is `Query<&Foo, With<Bar>>`.

`changed(T)`, `added(T)`, and `spawned()` mirror Bevy's tick filters. Dynamic
`QueryBuilder` has no ComponentId form for them, so the runtime evaluates their
ticks itself. `changed(T)` and `added(T)` record read claims; `spawned()` does
not. `^T[changed(T)]` is an access-conflict error. The window is the querying
program's previous run, and interior-mutability changes remain invisible.

`[n]` and `[last()]` are 1-based positional predicates. A predicate attached
to a step indexes that step's complete result sequence. In a field chain it
indexes each source value's field sequence, so `Brush.faces[1].material`
selects the first face per brush.

Value comparisons are deferred.

## Fields and re-entry

`.field` and `[n]` project reflected component values. Tuple fields use
reflect's zero-based names (`.0`); bracket positions are one-based.

An Entity-valued field result can **re-enter** the entity domain: access an
Entity value and use it as a node. For example, `Terminal/shell.0/Process`
follows an Entity stored in `Shell` and fetches `Process` from it. This is for
ordinary stored references. Bevy relationships should use `R::test`, which
uses the relationship traits rather than assuming a reflected `.0` layout.

`/` after a non-Entity value is a type error.

## Ordering

`Children` traversal preserves the persisted relationship-target collection's
order; this is semantic data. World-scan order is unspecified across
executions and runs. Positional predicates over scans are debugging/sampling
operations, not stable script selections.

## Validation corpus

Positive — every v0 syntax form must parse:

```
#Floor/Children::*/Brush
#Floor/Children::*/Brush.faces[1].material
#Floor/Children::#"Floor West"/Brush
#Floor/Children::*[1]/Brush
#Floor/Children
#Floor/ChildOf::*
#Floor/..
Name[+Enemy -Dead]
Name[+Enemy][-Dead]
Name[+Enemy and -Dead]
Name[with(Enemy)]
Name[not(without(Dead))]
Name[(+Enemy or -Dead)]
^Transform[changed(Velocity)]
Shell[+TerminalA or +TerminalB]
Health[added(Enemy)]
Transform[spawned()]
@[+Brush]
#enemy/Health
#enemy/?Health
#enemy/?^Health
#enemy/@
#enemy
@
Entity
#enemy/Health.hp
Health|Armor
#Terminal/shell.0/Process
#a/a.0/b.0/c
//*[+Brush][1]
//Foo[+Bar]
/#Floor
#Floor//*
..
Foo
optional(mut(Health))
boolean(Player)
ref(Health)
single(#Floor)
single(Name[+Enemy])
#enemy/@/Health
Brush.faces
Brush.faces[last()]
#Ramps/Children::#Floor
```

Negative syntax — each must be rejected by the parser:

```
[+Brush]
@Brush
Foo.
#
?@
^@
//
#Floor//
Foo[+Bar
+Enemy
Children::
Children::Brush
```

Syntactically valid but rejected by semantic/type validation:

```text
#foo/Children/#bar       Children is data, not an Entity; use Children::#bar
Foo/bar                  Foo is not Entity-valued; `/` cannot re-enter
^T[changed(T)]           conflicting write/read access in one query
?Entity                  Entity cannot be optional
^Entity                  Entity cannot be mutable
UnknownType              unknown type name
UnknownRelationship::*   unknown or non-relationship axis
```
