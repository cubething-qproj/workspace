# Plan: move all design docs into the wiki

**Date:** 2026-11-03. **Status:** approved; steps 1–3 committed; step 4 NLP migration
approved, PCG next. Draft 3 moves the server to Vite and the wiki into its own repo.

## Goal

Every design doc and reference doc lives in `.docs/wiki`, written in Typst and
sorted by area, with these features:

- **Links and backlinks:** links by page name, broken links fail the build,
  and every page lists "what links here".
- **Auto indexes:** each page has metadata (area, status, date). Area pages,
  status views and recent changes are generated.
- **Search:** client-side, Pagefind.
- **Inline editor:** edit a page's Typst source in the browser. Saving
  overwrites the file, and git is the safety net.

**Out of scope:**

- `plans/`, `handoffs/` and `issues/` are procedural. They stay as working
  files.
- Crate developer docs (`bin/quell/docs`, `lib/q_proc/docs`,
  `misc/infra/docs`) stay with their code, because rustdoc includes them. The
  wiki can link to them.

## Decided

- **Tool:** our Typst bundle, extended (option A in draft 1).
- **Format:** everything is Typst. Markdown docs are converted once with
  `pandoc -f gfm-gfm_auto_identifiers -t typst` (pandoc 3.11 is installed, and
  Mermaid blocks come through intact), then cleaned up by hand.
- **Areas:** as below, including `engine` and `tooling`.
- **Reference PDFs:** they move into the wiki. The papers are local only:
  never publish the wiki output.
- **`hex-paths-overview.md`:** kept, as a pcg page.
- **Old docs:** they keep a status badge and are listed under each area's
  "history" heading.

## Wiki.js?

Wiki.js has many features: an editor, search, permissions, git sync and
community MCP servers. Against it, for us:

- It needs Node and a database, and the database is the real store. Git sync
  mirrors pages to Markdown files, but the files aren't the source of truth.
- It has no Typst, so we'd lose maths, our helpers and the PTA designs' layout.
- Its MCP server gives agents little that they don't already get by editing
  files in the repo.

**Recommendation:** don't adopt it. Every feature we want is small on top of
what exists. If the home-grown wiki starts to need permissions, multiple users
or comments, look at Wiki.js again.

## The server and the inline editor

**Repo.** `.docs/wiki` is its own git repo, nested in the org repo like
`bin/`, `lib/` and `misc/`. Everything that runs the wiki lives in it. It may
move to the top level later.

**Server: Vite, following the blog's setup** (`~/repos/ada-x64/blog/vite.config.mts`).
`just serve` runs `bun run vite`. A plugin:

- watches the page sources, including added, removed and renamed pages;
- on any change, reruns the manifest script and recompiles the whole bundle.
  It takes tens of milliseconds, so it doesn't need the blog's per-post
  incremental builds;
- re-indexes search through Pagefind's Node API;
- sends a custom `wiki:built` event instead of Vite's full reload, so the
  editor doesn't reload itself. Ordinary pages reload on that event. The
  editor only reloads its preview.

It replaces `typst watch` and the Python save server from draft 2. The Python
manifest script stays, and the plugin runs it.

**Saving: Vite middleware.**

- `GET /api/src?page=<name>` returns a page's source.
- `POST /api/src?page=<name>` overwrites it.
- It only touches files listed in the manifest.
- It refuses the save if the file changed on disk since the editor loaded it,
  compared by modification time. That stops the editor overwriting an agent's
  edits, or the other way round.
- Vite binds to `localhost` only.

**The editor UI:** an "edit" link on every page opens a split view, with the
source on the left and the live page on the right.

- **Editor: CodeMirror 6 with `@replit/codemirror-vim`,** installed as npm
  dependencies and bundled by Vite.
  - Vim mode is on by default, and `:w` saves.
  - Its Vim emulation is more complete than `monaco-vim`, and CodeMirror is
    much lighter than Monaco.
- **Live preview, close to typst.app:**
  - after a pause in typing (about 300 ms), the editor saves;
  - the plugin rebuilds;
  - the preview frame reloads at the same scroll position.

  Expect under a second from typing to seeing the change, with Mermaid
  diagrams a little slower. Autosave can be switched off, and then the preview
  updates on `:w`.

- **Not like typst.app:** typst.app updates in place, by recompiling in the
  browser and patching only what changed. Getting that here would mean
  compiling Typst to WASM in the page (typst.ts) or using tinymist's preview,
  and both render paged output, not our HTML. Not worth it now.
- **Typst highlighting and tinymist (in step 3, at Ada's request):**
  - Highlighting: a CodeMirror Typst language mode.
  - tinymist (installed) gives diagnostics, completions and hover through LSP.
    The plugin starts `tinymist lsp` and bridges its stdio to a WebSocket on
    Vite's server. A CodeMirror LSP client connects to that socket.
  - Which packages to use is checked at implementation time.

**Build errors:** if a save breaks the build, the last good HTML stays. The
plugin sends the error to the editor, which shows it.

## How the pages work

- **Discovery.** Typst can't list a directory, so `scripts/manifest.py` runs
  before every build. It writes a gitignored `manifest.json` with each page's
  name, area (its directory) and date (last commit, or the file's modification
  time if it has uncommitted changes).
- **Metadata.** Each page starts with
  `#show: wiki-page.with(title: [...], status: "current", summary: [...])`.
- **Links.** Use `#l("page-name")`, or `#l("page-name")[label]` with a
  label. `l` records a link from this page to that one, and the build fails if
  the page doesn't exist. Backlinks come from the same records (cross-page
  `query` in a bundle was tested and works).
- **Generated pages:**
  - the home page, with areas and recent changes;
  - one page per area, with current pages first, then history;
  - a status view.

  The explainers are an area like any other.

- **Search:** Pagefind re-indexes `out/` after each build.

## Areas and where each doc goes

Each area is a directory under `.docs/wiki/`. The wiki is a separate repo, so
moved docs start fresh history there. That's fine: the old history stays in
the org repo.

| area                                            | docs (current path under `.docs/`)                                                                                                                                                                                                                                                                                 |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **nlp** (argumentation, NLP, debate)            | the current debate pages; `designs/capna-based-flow.md`, `pta-atip-algorithm.typ`, `pta-document-analysis.typ`, `quell-reading-notes-design.md`; retired: `designs/retired/pta-atip.typ`                                                                                                                           |
| **pcg** (world generation)                      | `quell-world-generation-design.md`, `quell-hex-terrain-r11-design.md` with `quell-hex-terrain/` (48 MB of PNGs), `quell-docs-tmp/hex-paths-overview.md` (marked "as of `feat/hex-paths`, 2026-10-13"); retired: `quell-hex-layout-design.md`, `quell-hex-paths-prototype-design.md`, `quell-hex-terrain-design.md` |
| **gameplay-3d** (physics, 3D world interaction) | done: `quell-camera-design.md`, `quell-kinematic-controller-design.md`                                                                                                                                                                                                                                             |
| **gameplay-vn** (visual novel)                  | none yet                                                                                                                                                                                                                                                                                                           |
| **narrative** (narrative and writing)           | none yet                                                                                                                                                                                                                                                                                                           |
| **graphics**                                    | none yet                                                                                                                                                                                                                                                                                                           |
| **engine** (q_os and the lib crates)            | `q_os design.md`, `q_os-schedule-ordering.md`, `q_shell_lang-design.md`; done: `q_query_lang design.md`, `q_screens-persistent-types-design.md`, `handoffs/done/ordinary-system-job-model-design.md`; retired: `q_fs grammar.md`; wont-do: `q_fs design.md`                                                        |
| **tooling**                                     | done: `local-dev-without-nix-design.md`                                                                                                                                                                                                                                                                            |
| **reference**                                   | `reference/*.md` converted to pages; PDFs moved to `wiki/reference/pdf/` and listed with a one-line summary each                                                                                                                                                                                                   |

The explainers stay one shared pool, not tied to an area.

## `quell-docs-tmp`

- **`architecture.md`, `development.md`, `scheduling.md`, `testing.md`,
  `mod.rs`:** the rewritten `bin/quell/docs` for the Quell source-layout chore
  (`handoffs/quell-src-layout-handoff.md`). They go into that chore's PR, and
  stay here until then.
- **The crit files** (`crit-comments.json`, `crit-story.json`,
  `crit-story-prep.txt`): delete them.
- **`hex-paths-overview.md`:** moves to pcg, as above.

## Steps (one commit each, in the wiki repo unless noted)

0. ~~Pagefind~~: installed.
1. **Wiki core** (done): the manifest script, `wiki-page` metadata,
   `l()` links, backlinks, a build error on unknown pages, and generated home,
   area and status pages. The debate pages moved to `nlp/`. `just serve` uses
   `typst watch` for now.
2. **Vite server and search** (done, `f86840a`):
   - `package.json`, `vite.config.mts` and the watcher plugin, with
     `node_modules/` gitignored;
   - Pagefind through its Node API, and a search box in the header;
   - `just serve` switches to Vite.
   - _Risk:_ the custom reload event must also cover pages opened outside the
     editor. Inject a small client script into every page.
3. **Inline editor** (done, `4c3cf98`):
   - the save middleware, with the stale-file check;
   - the split view: CodeMirror with Vim mode, and the live preview with
     autosave;
   - Typst highlighting, and tinymist over a WebSocket bridge.
   - _Risk:_ reloading the preview may flicker, or Mermaid may re-render
     slowly. If so, switch autosave off by default, so the preview only
     updates on `:w`.
4. **Migrate one area per commit,** in this order: nlp, pcg, engine,
   gameplay-3d, tooling, reference. Each commit:
   - copy, then convert with pandoc;
   - add metadata, and turn internal links into `l()`;
   - fix what pandoc got wrong;
   - build clean and look at the pages.

   Each wiki commit is paired with an org commit that removes the originals.

   **NLP review checkpoint (2026-11-03):** the five remaining pages are converted
   in `wiki/nlp/`: `capna-based-flow`, `pta-atip-algorithm`,
   `pta-document-analysis`, `quell-reading-notes-design`, and the superseded
   `pta-atip`. Manual review approved; automated review skipped at Ada's request.
   The five original sources and three generated PDFs are removed in the paired
   org commit. The `.bak` and old debate roadmap remain reserved for the explicit
   cleanup decision in step 6.

   The PTA pages use document-prefixed labels because labels are shared across
   the whole bundle. PDF-only layout and diagram wrappers have been removed;
   the shared template renders Mermaid in the browser. Two malformed Markdown
   tables in CAPNA were restored as tables, and its numbered Mermaid labels
   were adapted to avoid Mermaid interpreting them as Markdown lists.

   Verified: full `just --justfile .docs/wiki/justfile build` (34 pages plus
   Pagefind), standalone HTML compilation of all five pages, local links and
   section anchors, preserved code blocks (ignoring trailing whitespace), and
   headless Chromium rendering of all 12 Mermaid diagrams. The bundle build
   emits only Typst's experimental-bundle warning. LSP still reports errors in
   the unchanged `_template.typ` (`html` unavailable to its configuration) and
   `vite.config.mts`; no new page diagnostics were reported.

   Next: migrate PCG, then stop for area review. External path updates remain
   grouped in step 5.

5. **Fix paths outside the wiki** (org repo, plus the skills). About 20
   references point at `.docs/designs` or `.docs/reference`:
   - the skills `pta-atip`, `xaif-iat`, `q-os` and `jackdaw`;
   - the plans;
   - four memory files.

   Also update `AGENTS.md`: § Design should say "create a page in
   `.docs/wiki/<area>/`", and mention the nested wiki repo.

6. **Clean up** (org repo). Remove the empty `designs/` and `reference/` trees
   and the crit files. Two files need your OK to delete:
   - `pta-atip-algorithm.typ.bak`;
   - draft 1 of the debate roadmap.

Steps 2 and 3 are independent of step 4. Doing them first means migration
happens with the editor and search already available to check the results.
