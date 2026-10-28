> Superseded by [q_term #33](https://github.com/cubething-qproj/q_term/issues/33). Line editing moved to the q_term line discipline; q_shell #7 was closed as not planned.

# Canonical line editing for q_shell

Date: 2026-09-22
Issue: [q_shell #7](https://github.com/cubething-qproj/q_shell/issues/7)
Tracking issue: [q_shell #10](https://github.com/cubething-qproj/q_shell/issues/10)

## Goal

Turn canonical terminal input from append/erase into a small interactive line editor:

- editable cursor: Left, Right, Home, End, Delete;
- Ctrl+Backspace word delete;
- Ctrl+C: discard the line and interrupt whoever owns the terminal;
- Ctrl+L: clear the screen and redraw the prompt and line;
- correct redraw;
- per-terminal state.

## Current state

- q_term owns the vocabulary: `LineDiscipline::Canonical { buffer }` and `TermInput::{Text, Submit, Erase, Eof}` (`#[non_exhaustive]`).
- q_shell owns the behavior: `keyboard_input` maps keys to `TermInput`, and `process_line_input` edits the buffer, echoes bytes, and delivers lines to the foreground stdin.
- Echo is direct `VtWriteMsg` writes. Erase echoes `BS SP BS`.
- q_term supports the CSI sequences needed for redraw: CUB/CUF, EL, ED, CUP. CUB does not wrap to the previous row, like xterm.
- q_proc defines `SignalMsg`/`Sig`, but **nothing consumes signals yet**. `hang_up_terminal` already emits `Sig::Hup`, which is also ignored.
- The prompt (`$ `) is a private constant in q_shell's interpreter.
- Only q_shell matches on `LineDiscipline` or `TermInput`. Quell and vn-jun-26 do not.

## Ownership

Keep the existing split.

**q_term: vocabulary.** The data changes are additive except for one new field:

```rust
pub enum LineDiscipline {
    /// `cursor` is a char index into `buffer`, `0..=buffer.chars().count()`.
    Canonical { buffer: String, cursor: usize },
    Raw,
}

#[non_exhaustive]
pub enum TermInput {
    Text(String),
    Submit,
    Erase,
    Eof,
    /// Forward delete.
    Delete,
    /// Erase the word before the cursor.
    EraseWord,
    CursorLeft,
    CursorRight,
    CursorHome,
    CursorEnd,
    /// Discard the line and interrupt the terminal owner (^C).
    Interrupt,
    /// Clear the screen and redraw the line (^L).
    Clear,
}
```

**q_shell: behavior.** q_shell maps keys to these variants, performs the edits, echoes them, and routes signals and delivery.

This is two PRs: a small q_term PR first, then q_shell. During development q_shell uses a path dependency on q_term. The Git dependency is restored before commit.

## Editing model

A pure function does the edit, so tests can check buffer, cursor, and echo bytes without an app:

```rust
fn edit(buffer: &mut String, cursor: &mut usize, input: &TermInput) -> LineEdit;

struct LineEdit {
    echo: Vec<u8>,
    outcome: Option<LineOutcome>,
}

enum LineOutcome {
    Deliver(TerminalInputPayload),
    Interrupt,
    Clear,
}
```

The system keeps its current shape. It reads each `TermInputMsg`, calls `edit`, writes `echo` as `VtWriteMsg`, and handles `outcome`.

### Redraw

Redraw is cursor-relative. Every in-line mutation uses one helper:

```text
redraw(from, removed):
    CUB (cursor_before - from)   # move to the edit point, if nonzero
    write buffer[from..]         # rewrite the tail
    EL 0                         # erase leftovers when the line shrank
    CUB (len - cursor)           # return to the cursor, if nonzero
```

CUB and CUF with a parameter of 0 move one cell, so they are never emitted with 0.

| input | buffer effect | echo |
| --- | --- | --- |
| `Text(t)` | insert at cursor | `t` + tail + `CUB len(tail)` |
| `Erase` | remove char before cursor | redraw from `cursor - 1` |
| `Delete` | remove char at cursor | redraw from `cursor` |
| `EraseWord` | remove trailing whitespace, then non-whitespace, before cursor | redraw from word start |
| `CursorLeft` / `CursorRight` | move by one, clamped | `CUB 1` / `CUF 1`, or nothing at the bounds |
| `CursorHome` / `CursorEnd` | jump | `CUB cursor` / `CUF (len - cursor)` |
| `Submit` | take the whole buffer | `CUF` to end, then `\r\n`; deliver `buffer + "\n"` |
| `Eof` | unchanged behavior | flush the whole buffer if nonempty, else EOF |
| `Interrupt` | clear the buffer | `^C\r\n` |
| `Clear` | none | see Ctrl+L |

Positions count `char`s. q_term renders one cell per `char`.

Word boundaries are whitespace, like the Unix `werase`/Ctrl+W behavior. Readline's alphanumeric boundaries are left to a follow-up if needed.

### Keyboard mapping

```text
Ctrl+D          -> Eof        (existing)
Ctrl+C          -> Interrupt
Ctrl+L          -> Clear
Ctrl+Backspace  -> EraseWord
Backspace       -> Erase
Delete          -> Delete
ArrowLeft/Right -> CursorLeft / CursorRight
Home / End      -> CursorHome / CursorEnd
Enter           -> Submit
```

Other Ctrl chords are ignored rather than inserted as text. Today, `Ctrl+X` inserts `x`.

## Ctrl+C

Linux `n_tty` with `ISIG` flushes pending input, echoes `^C`, and signals the foreground process group. We mirror that:

1. The editor clears the buffer and echoes `^C\r\n`.
2. The system resolves the terminal to its `Shell` through `ShellTarget`.
3. If the shell's `ForegroundProcessGroup` is nonempty, it writes `SignalMsg { term, target, signal: Sig::Int }` for each process in the group.
4. Otherwise the shell owns the terminal, and the signal targets the shell itself.
5. The interpreter reads `SignalMsg` and, for a `Sig::Int` that targets a `Ready` shell, prints a fresh prompt. That matches bash. In `Waiting` it ignores the signal, because the job handles it.

The editor writes in `TerminalSystems::Input` and the interpreter reads in `ProcessSystems::RunPrograms`, later in the same frame, so the new prompt appears without a frame of latency.

**Gap:** q_proc has no signal delivery. With only this change, Ctrl+C on a running job echoes `^C` and emits the signal, but the job keeps running. **Decision needed:**

- **A (recommended):** Emit and test `SignalMsg` only in #7. File a q_proc issue for signal delivery and default dispositions: Int, Term, Hup, and Kill remove the `Process` unless `signal_overrides` catches the signal. That also makes the existing Hup meaningful. When it lands, the shell template must catch `Int` so Ctrl+C at the prompt does not kill the shell.
- **B:** Add a minimal default disposition to q_proc as part of this work. That widens the scope to three crates.

## Ctrl+L

The editor does not know what the prompt looks like.

- **Shell owns the terminal** (empty foreground group): echo `ESC[2J ESC[H` + prompt + buffer + `CUB (len - cursor)`. The prompt constant moves from `interpreter.rs` to a `pub(crate)` constant shared by both. When #8 makes the prompt configurable (PS1), this becomes shell state that both read.
- **A job owns the terminal**: echo `ESC[2J ESC[H` + buffer + cursor restore. The program's own prompt is not reprinted. This is `n_tty` reprint behavior without readline.

Rejected alternative: track the bytes each process writes since its last newline and replay them as the "prompt". This is more general but heuristic, and it adds output-path state for a Ctrl+L nicety.

## Known limitation: wrapped lines

Cursor-relative redraw assumes that the prompt and line fit in one terminal row. CUB does not cross row boundaries, so editing a line that wraps puts the cursor in the wrong place.

**Decision needed:**

- **A (recommended):** Document this and file a follow-up issue. A fix needs the start column and terminal width (`VtSize`) to turn char offsets into row/column moves.
- **B:** Handle it now with that computation.

## Out of scope

- history and prefix navigation (#5); it builds on this editor;
- raw mode (#6);
- Ctrl+W, Ctrl+U, Alt/Meta word motion, and kill-ring yank;
- wide or combining characters;
- q_proc signal delivery (see Ctrl+C);
- configurable prompts (#8).

## Test plan

q_term:

- the default `LineDiscipline` is an empty canonical buffer with cursor 0.

q_shell, pure `edit` tests:

- insertion at the start, middle, and end gives the right buffer, cursor, and echo;
- Erase and Delete at both bounds are no-ops with no echo;
- EraseWord skips trailing spaces and stops at the previous word;
- Home/End and Left/Right clamp and never emit a zero-count CUB or CUF;
- Submit with the cursor mid-line delivers the whole line and moves to the end before `\r\n`;
- Interrupt clears the line and echoes `^C\r\n`.

q_shell, app tests:

- keys map to the new variants, and unknown Ctrl chords are ignored;
- Ctrl+C with an empty foreground group signals the shell, and the shell reprompts in the same frame;
- Ctrl+C with a foreground job signals each group member and not the shell;
- Ctrl+L at the prompt echoes clear + prompt + buffer;
- existing canonical submit/EOF tests still pass once the `cursor` field is added.

Manual:

- in `echo_shell`, edit mid-line, word-delete, Ctrl+C at the prompt, and Ctrl+L.

## Implementation slices

1. **q_term PR:** add the `cursor` field and new `TermInput` variants, with docs.
2. **q_shell PR:** add the `edit` function, key mapping, Ctrl+C routing, the interpreter reprompt, and Ctrl+L, with tests and the echo_shell check.
3. **Issues:** q_proc signal delivery if Ctrl+C option A is chosen, and wrapped-line editing if that option A is chosen.
