# A Typst knowledge base, with documents as sources

**Status:** initial PCG pilot committed as wiki `7d02c7a`; source-layout cleanup,
blog-style visual presentation, galleries and per-page counter resets approved
and committed as wiki `25bddf0`. Design discussion began 2026-11-03.

**Confirmed direction:** Quell-focused articles; external references rather than
an encyclopaedia; simple emoji callouts; relevant documents listed newest-edited
first. Separate wiki/document interfaces are part of the agreed pilot.

## The change in purpose

The current migration answers “where do we keep the documents?” It does not
answer “what do we know?” Converting a proposal to Typst and giving it links,
search and an editor preserves a document library. It does not make an article.

The proposed knowledge base is **topic-first, not document-first**. Its main
pages explain concepts, mechanisms, constraints and established decisions. They
are revised in place as our understanding changes. Dated proposals, experiments
and implementation stories are supporting sources, not the default entry point.

This is an editorial change first and a template change second. A table of
contents alone will not turn a design proposal into reference material. Equally,
static HTML is not the obstacle: Typst files, git, the existing Vite server and
editor can support this without introducing a database or replacing the stack.

## Scope: Quell, not an encyclopaedia

The wiki is about **Quell and things relevant to its development**. Its purpose
is general-purpose project documentation at a glance: what things are, how they
fit together, and what a reader needs to understand them. Detailed implementation
instructions and development proceedings belong elsewhere.

Research belongs when it explains a Quell-relevant question or finding. An
article might explain why a particular argumentation framework matters to the
game; it need not reproduce a general account of that framework. Wikipedia,
Wolfram Alpha, papers and other useful websites can be linked through references,
external links and a bibliography. We are not building a general research wiki.
Dated exploratory research notes, when worth retaining, are documents.

## Two reading interfaces, with explicit connections

| Kind         | Reader's question                                           | How it changes                                       |
| ------------ | ----------------------------------------------------------- | ---------------------------------------------------- |
| **Article**  | What is this? How does it work? What is known or undecided? | Maintained synthesis, revised in place.              |
| **Document** | What was proposed, observed or decided at this point?       | Preserved record, with its date, context and status. |

Recommendation: **separate the wiki from the document library in the reading
interface**, rather than put proceedings behind a filter in the wiki. Merely
adding page-kind badges would not establish the boundary we want.

- **Wiki:** topic articles, portals, contents, references and article search.
- **Documents:** designs, plans, issues, reports and historical records, using
  the existing simple presentation, its own index and its own search.
- **Connections:** explicit article citations and related-document links. A
  labelled link can switch between the two interfaces; neither interface's
  navigation or search silently includes the other.

These can be two separately built sections served by the same local server
(for example, `/wiki/` and `/docs/`). They need not mean two applications,
repositories, databases or deployments. Shared rendering helpers and the Typst
editor are fine; shared navigation and search inventories are not required.
Exact routes and source layout remain to be decided. Retain Markdown procedural
files where they belong; separation does not require converting or relocating
all of `.docs/`.

Use area directories as each article's home portal. Keep stable IDs for articles
and documents, resolving cross-interface links explicitly rather than assuming
they share one flat page namespace. Existing document URLs need preservation or
redirects if routes change. Do not move or delete files as part of this design
revision.

The document library needs a **document type** (design, plan, issue, report,
research note, etc.) separately from its lifecycle status. Its existing simple
style is sufficient. Wiki articles should not inherit that procedural metadata.

Existing draft/current/superseded/done badges describe document lifecycle. They
must not imply that a proposal is implemented. Articles need clear statements
about the subject instead: implemented, proposed, experimentally observed, or
unknown, where that distinction matters. A single article may discuss all four.
Do not replace that nuance with one green “current” badge.

## What an article looks like

A page should begin with a short answer, not its creation history. For example,
**Terrain generation** would explain the landscape pipeline and its important
relationships, with links to **Trail layout**, **Creeks and crossings**, and
**World streaming** where those topics justify separate articles.

This is an example of topic structure, not a claim that those mechanisms are
all currently implemented. Writing the articles requires checking the code,
experiment records and decisions; the legacy designs alone are not sufficient.

A useful article anatomy is:

1. **Lead:** what the subject is, why it matters, and its scope.
2. **Contents:** generated from the article's headings.
3. **Explanation:** appropriate sections, diagrams, examples and constraints.
4. **Undecided matters:** relevant gaps marked with an Undecided callout, not a
   plan or task list embedded in the article.
5. **See also:** editorially chosen neighbouring articles, not every backlink.
6. **Notes, references and external links:** qualifications, supporting sources
   and useful further reading; these have distinct purposes.
7. **Related documents:** an automatically ordered list at the bottom, linking
   out to relevant records in the document interface.

These are conventions, not seven compulsory empty headings. A short article
may need only a lead, two sections and references. Do not split every noun into
a stub; split when a topic has a useful explanation of its own.

An optional infobox can summarise a few useful facts, such as the owning crate,
related systems or units. This is secondary to the explanation, not an excuse
to turn the article into an API reference.

### Callouts

Callouts are simple blocks with an emoji icon, a header naming the type, and
text content. The confirmed type for unresolved matters is **Undecided**, with
**🤔** as its icon. For example:

```typst
#undecided[How should regeneration interact with saved player state?]
```

This is illustrative article text, not a claim that this particular question is
currently unresolved. The proposed helper is a wrapper around a general form:

```typst
#callout(kind: "undecided", icon: "🤔")[Text content.]
```

The general helper provides the common structure; named helpers supply the type
and icon. Other types can be added when needed, without bespoke rendering for
each one. Keep type text visible rather than communicating meaning through
emoji or colour alone. The existing `explain`, `decide` and `open` helpers should
be reconciled with this vocabulary during implementation, not retained as a
second competing callout system. A factual infobox and a message callout have
different content roles, even if they share some visual treatment.

## The reading interface

Borrow the useful structure from MediaWiki, not its accounts, advertising or
administrative complexity:

- **Site header:** home, portals and search.
- **Page header:** home-portal link, title, and Read / Edit actions. Document
  type, original date and lifecycle status belong in the separate document UI.
  A source-file modification date is not an article verification date.
- **Contents rail:** sticky, nested heading links on wide screens; collapsible
  inline contents on narrow screens. Small pages should not need a rail.
- **Article column:** readable width, with heading permalinks, figures, tables
  and notes. Optional infoboxes should not squeeze the prose on small screens.
- **Page footer:** see also, references, related documents and a secondary
  “What links here” section. The home portal remains easy to reach.

Keep the existing Typst source editor, Vim bindings, preview and diagnostics.
The initial Edit action edits the whole article. Section editing and a browser
history viewer are later conveniences, not prerequisites. Git history already
exists, but do not show a History tab until there is a working reading UI for it.

TOC generation needs a small technical check: whether Typst's HTML outline and
heading links give the desired output within a bundle. Use heading data/IDs
already emitted by Typst rather than authoring a second outline by hand. Bundle
label collisions and standalone tinymist compilation must both remain covered.

## Portals and discovery

A portal should orient the reader, not just list files by modification date.
For example, the PCG portal might offer:

- a short introduction to this part of Quell;
- a curated “start here” route through terrain, layout and regeneration;
- grouped topic links with one-line descriptions;
- a secondary link to supporting documents and historical material.

Use **an authored introduction and reading map plus a generated article
inventory**. Supporting documents are reached through an explicitly labelled
link to the document library, not mixed into the portal's topic list. This gives
portals meaning without making their inventories manual.
Each page initially has one home area; ordinary links handle cross-area topics.
Additional categories can wait until there is an actual navigation need.

Wiki search indexes articles; document-library search indexes records. Build
separate Pagefind indexes so a search for a topic does not primarily return its
old proposals. Offer an explicit link to search the other collection if useful.
A combined search is not needed initially. Document results show their type
and status, especially when superseded.

## Notes, sources and authority

Keep three different relationships legible:

- **Topic links:** another article helps explain this concept.
- **References:** this source supports this particular claim.
- **Related documents:** this record provides context or development history.

A source listed at the bottom does not substantiate every sentence on the page.
Use local notes/footnotes at important claims, with links to the relevant source
section when available. Explicitly distinguish experimental findings, design
intent and actual code behaviour. Conflicting records should not be silently
merged into a statement of fact.

**References** identify supporting evidence; **External links** offer useful
background or tools without implying they support a particular claim. A
bibliography can collect frequently used resources. Linking out is preferred
to reproducing general-purpose explanations that are already maintained well
elsewhere.

Start with Typst links, footnotes and small shared presentation helpers. A
shared bibliography/source registry can follow if repeated citations make it
useful; we do not need a general knowledge graph or claim database to begin.

### Related documents

Each article explicitly selects relevant document IDs. Do not infer relevance
from every record in the same area or from incidental mentions. The library's
metadata supplies title, document type, lifecycle status, URL and last-edited
date; do not duplicate dates in article source.

Generate a list at the bottom of the article, sorted **last-edited descending**
(newest first), with a stable title/ID tiebreaker. Show enough metadata to tell a
design from a report and a superseded proposal from an active one. Use the
record's actual edit/commit date, not the site rebuild time; editing a record
changes its position, but does not mean that its proposal has been approved.

This needs only a small read-only document catalogue available to the wiki
build, not incorporation of document bodies into wiki navigation or search.
Cross-interface references should be checked against that catalogue. Procedural
records can remain in their original formats and repositories; a working link
or document-viewing route is required before listing them in the article.

Crate developer docs stay with their code. The knowledge base summarises and
links to them, rather than maintaining a competing copy of their API guidance.
Papers and book extracts remain local-only; this design does not change the
existing prohibition on publishing the wiki output.

## What happens to the legacy documents?

Stop treating complete migration as the goal. Triage each document:

| Disposition              | When it fits                                                          |
| ------------------------ | --------------------------------------------------------------------- |
| **Synthesize**           | It contains useful knowledge that belongs in an article.              |
| **Retain as a source**   | Its experiment evidence, rationale or decisions are worth consulting. |
| **Leave in git history** | It is redundant, obsolete or mostly session logistics.                |
| **Defer**                | Its value or accuracy is unclear; no deletion yet.                    |

Synthesis and source retention are independent: an article may cite a retained
proposal, while another proposal may contribute nothing worth keeping live.
Do not turn all historical documents into articles, and do not delete sources
merely because a summary now exists. Useful figures can survive even if their
original containing document is retired.

Removal needs an explicit disposition and a link check. Keep stable document
URLs or redirects where existing articles cite them. Git preserves deleted
content, but a broken citation is not an acceptable archive interface. Published
references to a deleted record need a retained snapshot or a usable history link.

## A small pilot, not another bulk migration

Proposed next step, subject to agreement:

1. Pause the remaining migration. Leave the uncommitted PCG conversion and its
   originals in place; do not discard or commit it as part of this discussion.
2. Pick one portal and write one overview plus one deeper article. PCG is a
   useful candidate because its overlapping rounds expose the distinction
   between an explanation and a development record.
3. Add only what those pages need: separate article/document reading surfaces
   and search inventories, portal presentation, TOC, emoji callouts and
   source/related-document presentation. Reuse the editor and document styling.
4. Read the pilot as someone trying to learn the system. Can they find the
   answer without reading the proposal chronology? Can they tell what is
   implemented and what evidence supports it?
5. Triage that area's old records explicitly, then decide whether to extend
   the model to other areas. No automatic deletion or global rewrite.

The pilot is successful if the site becomes useful to consult, not if another
six documents have changed format.

## Current source layout

The approved cleanup is wiki commit `25bddf0`. `src/wiki/<area>/` holds articles,
with `index.typ` as the area's portal; `src/documents/` and `src/reference/` hold
supporting records. Shared Typst code is `src/template.typ`; frontend code is in
`web/`, assets in `static/`, and build tooling in `scripts/`. Consult the nested
wiki's `README.md` for current authoring examples rather than the earlier paths
in the historical checkpoint below.

The last build succeeded with 43 catalogue entries. Terrain generation's notes
are 1–3 and Trail layout's notes are 1–4; page counters no longer leak across the
bundle. Eight Python checks passed during cleanup. The optional Chromium smoke
check remains unfinished, with further test work explicitly deferred by Ada.

## Initial implementation checkpoint

The first pass was approved and committed as wiki `7d02c7a`:

- `/wiki/` is the article UI; `/documents/` is the independently searched record
  library. Legacy record URLs redirect, preserving query strings and fragments.
- `articles/pcg/terrain-generation.typ` and `trail-layout.typ` are the first two
  articles; `portals/pcg.typ` is the authored portal with generated topic links.
- `contents()` generates native Typst outlines scoped to the current article.
  Place it after the lead. It is a rail on wide screens and collapsible inline
  contents on narrow ones.
- `callout` and `undecided` provide the shared emoji/type/body format. Supporting
  records appear newest-edited first with independent document type and status.
- The existing editor serves both collections. No procedural directories are
  automatically imported, and no additional originals have been removed.

Seven automated tests cover catalogue discovery, timestamp semantics, duplicate
IDs/URLs, links and fragments, outline scope, related-document ordering and
legacy routes. Full builds and all three standalone pilot pages compile.
Chromium checks passed against the running server for separate real search
results, desktop/narrow layouts, callouts, notes placement, editor previews,
stale-save rejection, live rebuild/recovery, removed pages, and legacy section
redirects. Search also initializes with the diagram CDN deliberately blocked.
Existing tinymist HTML-feature and Node type-definition diagnostics remain;
Python tests and editor code have no LSP diagnostics.

Review focus: whether the articles feel like useful explanations of Quell,
whether the document boundary is clear, and whether PCG is the right level of
conceptual detail. Legacy-document triage remains a separate decision.
