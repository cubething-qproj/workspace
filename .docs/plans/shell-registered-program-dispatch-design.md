# Registered program dispatch for q_shell

Date: 2026-09-22
Issue: [q_shell #9](https://github.com/cubething-qproj/q_shell/issues/9)
Tracking issue: [q_shell #10](https://github.com/cubething-qproj/q_shell/issues/10)

## Goal

Make every q_proc program registered with an application executable by name from the standard process-backed terminal shell.

An application should register a program and its systems once:

```rust
app.program::<ScreenProgram>()
    .add_system(Update, run_screen);
```

The standard shell should then resolve and launch `screen ...` without an application-maintained command map or a manual string match.

## Scope

This pass provides:

- a name index over registered q_proc programs;
- unique, validated command names stored directly on program labels;
- a configurable shell-language boundary;
- a bundled simple language with quoted and escaped arguments;
- a standard process-backed interpreter/evaluator for that language;
- registered-program spawning, waiting, errors, and prompt redraw;
- an updated echo-shell example that demonstrates automatic discovery.

This pass does not provide:

- history or line editing beyond the current canonical input support;
- environment interpolation or inheritance changes;
- pipelines, redirection, aliases, built-ins, globbing, or scripting syntax;
- raw terminal input;
- program completion or a `help` command.

Those remain separate q_shell #10 sub-issues.

## Current gap

q_proc already associates every `ProgramLabel` with a command-oriented name, but wraps the `&'static str` in a separate `ProgramName` value and indexes `Programs` only by the interned label. q_shell therefore cannot perform a direct name lookup.

The echo example works around this by implementing an application-specific shell program that:

1. reads terminal input;
2. calls `split_whitespace`;
3. manually matches the string `"echo"`;
4. emits `ShellSpawnMsg` itself.

This duplicates dispatch policy in every application and cannot handle quoting.

The default q_shell process uses `DefaultShellProgram`, but q_shell does not register a system for it, so the default shell process is intentionally inert today.

## Proposed ownership

### q_proc owns program identity and lookup

`Programs` remains the single source of truth for executable program registration. The runtime program label itself owns its command name as `&'static str`; there is no separately owned `ProgramName` key.

Conceptually:

```rust
pub trait ProgramLabel {
    fn name(&self) -> &'static str;
    // existing label identity methods
}

pub struct Programs {
    programs: HashMap<InternedProgramLabel, ProgramData>,
    names: HashMap<&'static str, InternedProgramLabel>,
}

impl Programs {
    pub fn get_by_name(&self, name: &str) -> Option<InternedProgramLabel>;
    pub fn names(&self) -> impl Iterator<Item = &'static str> + '_;
}
```

The implementation may retain Bevy's interned-label machinery, but each label's static name is authoritative for command lookup. The current `ProgramName` wrapper becomes unnecessary.

Registration is the moment at which name uniqueness is enforced:

- registering the same label again remains idempotent and preserves its systems;
- registering a different label with the same name is an application-configuration error and panics immediately;
- an empty name or any name containing whitespace is invalid.

Failing at registration is preferable to allowing the same command line to resolve differently according to hash-map order. q_proc owns this invariant because every consumer—not only q_shell—must observe the same program identity.

The catalogue remains live. A program registered after shell plugins are installed is visible without rebuilding a q_shell cache. The name-to-label boundary is also independent of q_proc's current `ProgramData` implementation, so a future move from registered `SystemId`s to ordinary program systems/factories does not change shell lookup.

### q_shell owns command interpretation

The public default is one top-level `ShellPlugin`, not a list of individually required plugins:

```rust
app.add_plugins(ShellPlugin::default());
```

Internally, the top-level plugin composes ordered concern-specific subplugins:

```text
ShellPlugin<SimpleShellLanguage>
|
|-- process and terminal dependencies
|-- shell core: lifetime, descriptors, jobs, foreground state
|-- terminal host input adapter
|-- line editor and submitted-line boundary
|-- configured language parser and evaluator
`-- prompt/output policy
```

The subplugins keep implementation concerns separate, but are private initially because none is independently useful yet. If concrete configuration or replacement needs appear, they can become public without forcing every user to assemble the default shell by hand.

`ShellPlugin::default()` installs the terminal-backed shell with the bundled `SimpleShellLanguage`. A generic constructor or builder accepts another language implementation. The existing lower-level `ShellIo` and custom-process capabilities remain available as advanced primitives, but the exact compatibility surface will be settled during implementation rather than exposed as another required plugin list.

## Target architecture through q_shell #10

This issue is the first thin slice of a larger shell engine. The intended end state is:

```text
q_term host input
    |
    v
line editor -------------------- history
    |
    | submitted source
    v
configured ShellLanguage
    |
    | side-effect-free IR
    v
shell evaluator ---------------- environment
    |
    | launch / wait / resume
    v
job and process entities ------- program catalogue
    |
    v
typed descriptor I/O ---------- q_term host output
```

The boundaries are:

- **Line editor:** owns editable input state and emits complete source. q_shell #5 and #7 expand it without changing the language/evaluator boundary.
- **Shell language:** parses source into typed, side-effect-free IR. The language is selected when building the app.
- **Evaluator:** advances IR until it launches work, waits, exits, or reaches a future instruction budget. Waiting is ECS state, never a blocked Bevy thread.
- **Environment:** is shell/session state supplied to parsing/evaluation and inherited by children. q_shell #8 fills this boundary.
- **Program catalogue:** resolves runtime names to q_proc identities; it does not parse command-specific arguments.
- **Jobs/processes:** own execution, descriptors, foreground routing, and completion.

The bundled simple language initially has one IR form:

```rust
pub enum SimpleShellIr {
    Empty,
    Command {
        program: String,
        arguments: Vec<String>,
    },
}
```

A language trait keeps this default replaceable:

```rust
pub trait ShellLanguage: Send + Sync + 'static {
    type Ir: Send + Sync + 'static;

    fn parse(&self, source: &str) -> Result<Self::Ir, ShellParseError>;
}
```

This signature is schematic. Earlier q_shell design work allows parsers to be Bevy systems when they need read-only world context for selectors or completion. The invariant is the parse/evaluate split: parsing yields IR and does not launch programs or mutate shell state.

Future richer languages can add pipelines, selectors, typed values, or scripting without changing q_proc, terminal transport, or line editing. `SimpleShellLanguage` is the sane bundled default, not the permanent or only shell language.

## Thin-slice data flow for q_shell #9

```text
host keyboard
    |
    v
private terminal-input subplugin
    |
    v
TerminalInputPayload::Bytes
    |
    v
ProcessInputBuffer on DefaultShellProgram process
    |
    v
SimpleShellLanguage::parse
    |
    v
SimpleShellIr::Command
    |-- Programs::get_by_name(program)
    |-- write parse/lookup errors to fd2
    |
    v
ShellSpawnMsg { program, shell, arguments }
    |
    v
shell spawn phase on the next update
    |
    v
child Process + inherited terminal descriptors
    |
    v
registered q_proc program systems
```

The existing schedule order places shell spawning before program execution. A command emitted by the evaluator is therefore spawned on the next update. This is accepted: it preserves the public `ShellSpawnMsg` path and avoids a second direct-spawn implementation.

This slice may store its one-command continuation directly on the shell entity. The representation must still describe evaluator state—ready, waiting for a job, or exited—rather than combine parser, prompt, and child-lifetime booleans into an opaque loop. A later pipeline or script may promote the continuation to a dedicated shell-execution entity without changing the language IR boundary.

## Default evaluator behavior

The standard interpreter follows the lifecycle already demonstrated by the echo example:

1. Print the prompt when the shell first runs.
2. If a foreground child exists, wait without reading another command.
3. When the child exits, print the next prompt.
4. Read one queued canonical input payload.
5. On an empty line, print another prompt without spawning.
6. On bytes, validate UTF-8 and tokenize the command line.
7. Resolve the first token through `Programs`.
8. Emit `ShellSpawnMsg` with the remaining tokens as arguments.
9. On EOF, remove `Process` from the shell and use existing shell cleanup.

A small private per-shell component records initial-prompt and waiting state. It is added lazily by the default interpreter, so shells created before plugin setup do not require a separate backfill pass.

### Arguments

This design preserves the current q_shell convention: `Process::argv` contains arguments after the command name. It does not introduce an `argv[0]` migration as part of name lookup.

For example:

```text
echo "hello world" tail
```

launches `EchoProgram` with:

```rust
process.argv == ["hello world", "tail"]
```

q_proc and the shell language transport argument tokens; they do not choose a command-specific argument parser. A program may consume raw strings or use any frontend appropriate to it. Future q_shell work may provide multiple argument-parser adapters, including a Bevy-reflection-driven default; a consumer could provide a clap adapter without making clap a q_proc or q_shell dependency.

Standardizing q_proc on POSIX-style `argv[0]` can be considered separately if consumers need it.

### Bundled simple language

`SimpleShellLanguage` is a small example-quality language shipped as the default so `ShellPlugin` works by itself. It is not a claim that q_shell has one permanent grammar.

The first implementation adds the small `shlex` dependency and supports:

- one command invocation;
- whitespace-separated words;
- single and double quotes;
- escaped characters as implemented by shlex.

It does not interpret:

- pipes or redirection operators;
- variable interpolation;
- command substitution;
- multiple commands separated by punctuation.

Tokens such as `|`, `>`, and `;` are ordinary arguments in this deliberately small language. Later q_shell #10 slices may evolve the bundled language while preserving the `ShellLanguage` and IR boundary. Advanced consumers can supply a different language over the same line-editor, evaluator, program, job, and I/O primitives.

### Errors

Errors are written through the shell process descriptors so normal terminal routing applies.

Proposed messages:

```text
shell: input is not valid UTF-8
shell: unmatched quote
missing: command not found
```

Parse and lookup failures do not spawn a process and immediately redraw the prompt.

## Exposure contract

Registration means shell exposure. Any program added through `register_program::<T>()` or `program::<T>()` is discoverable and executable by the static name on its label when the bundled language is installed.

There is deliberately no second “shell command” registration API and no opt-in allowlist in this pass. If applications later need internal-only programs, that should be represented explicitly in q_proc program metadata rather than by creating a parallel q_shell registry.

## Public API sketch

q_proc:

```rust
pub trait ProgramLabel {
    fn name(&self) -> &'static str;
}

impl Programs {
    pub fn get_by_name(&self, name: &str) -> Option<InternedProgramLabel>;
    pub fn names(&self) -> impl Iterator<Item = &'static str> + '_;
}
```

q_shell, schematically:

```rust
pub struct ShellPlugin<L = SimpleShellLanguage> {
    language: L,
    // schedule configuration
}

pub trait ShellLanguage {
    type Ir;
    fn parse(&self, source: &str) -> Result<Self::Ir, ShellParseError>;
}
```

`ShellPlugin::default()` provides the complete terminal-backed default. `DefaultShellProgram` remains the process identity of its evaluator. Custom languages configure the top-level plugin; lower-level shell primitives remain available for applications that intentionally replace the default engine.

## Implementation slices

### Slice 1: q_proc catalogue invariant

- Reshape `Programs` to maintain label and name indexes.
- Store and validate each program's `&'static str` name on its label; remove the separate `ProgramName` wrapper if it no longer adds an invariant.
- Add name lookup and name iteration.
- Preserve idempotent registration and existing systems.
- Add duplicate-name and late-registration tests.

### Slice 2: q_shell language and evaluator seam

- Add the `ShellLanguage` parse/IR boundary.
- Add `SimpleShellLanguage` using `shlex`.
- Refactor `ShellPlugin` into the single public default that installs its private ordered subplugins.
- Register the `DefaultShellProgram` evaluator through the top-level plugin.
- Implement prompt, wait, EOF, parse, lookup, and spawn behavior as explicit evaluator state.
- Replace the echo example’s manual command match with automatic registered-program dispatch.
- Add focused integration tests.

Each slice receives its own focused validation and Crit review before the issue is closed.

## Test plan

q_proc:

- every registered label resolves by its declared name;
- a program registered after other plugins remains visible;
- repeated registration of the same label is idempotent;
- different labels cannot register the same name;
- empty and whitespace-containing names are rejected;
- name iteration yields each registered program once.

q_shell:

- a registered program launches without a manual dispatch map;
- quoted and escaped arguments arrive intact and exclude the command token;
- an unknown command writes to stderr and redraws the prompt;
- malformed quoting writes a parse error and redraws the prompt;
- an empty line spawns nothing;
- the interpreter waits for a child before redrawing the prompt;
- EOF terminates the shell through existing lifecycle behavior;
- a custom language can replace `SimpleShellLanguage` without replacing process/job/I/O primitives;
- a custom process/backend path remains available for advanced consumers;
- a program registered after `ShellPlugin` installation is discoverable.

## Documentation and example

The echo-shell example becomes the executable demonstration:

- q_shell supplies the interpreter;
- the example registers only `EchoProgram` and its implementation;
- typing `echo hello` proves that registration alone exposes the command.

The q_shell README should document the one-plugin default, the language/evaluator extension boundary, the registration-means-exposure contract, arguments-only `Process::argv`, and the intentionally limited bundled grammar.
