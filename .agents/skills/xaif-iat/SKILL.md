---
name: xaif-iat
description: Building and critiquing IAT argument maps in xAIF for the lab's editor (misc/labs/xAIF) — the dialogue-first graph (L/TA/YA/I/RA/CA/MA), where ATIP canonicalization lives (on the YA), the PTA data stored per node (`pta` fields), how the editor derives form and substance (α/β/γ/δ rules, second-order statements, δ from reported locutions), perspective and A/U, the file format extensions, a checklist of common annotation mistakes, and the scripted workflow for writing example files and verifying them. Use when writing or reviewing an xAIF example, annotating a passage for the editor, changing the editor's model, or explaining why an RA types the way it does.
---

# IAT + PTA argument maps in xAIF

The editor is `misc/labs/xAIF` (Svelte + Svelte Flow; `pnpm dev`, `pnpm test`,
`pnpm check`; README there). PTA typing itself (steps, lever tables, 50 types)
is the `pta-atip` skill; IAT is `.docs/reference/IAT_guidelines_and_tutorials-2023-10.pdf`.
This skill is the model that joins them, and the lessons from annotating.

## The graph (IAT, dialogue first)

Three columns: **logic** (I, RA, CA, MA) | **links** (YA) | **locutions** (L, TA).

| Node | Is | Edges |
| ---- | -- | ----- |
| L | exactly what was said, by whom (`Forename Surname: words`, never edited) | L → YA, L → TA → L, L → RA (δ premise), CA → L |
| I | what was asserted: the **canonical** proposition | I → RA/CA/MA, YA → I |
| YA | illocutionary force anchoring content in a locution or TA | L/TA → YA → I / L / RA / CA / MA |
| TA | "this locution responds to that one" (Wittgenstein test); one successor L | L → TA → L, TA → YA |
| RA | **one argument**: one premise, one conclusion, optional lever port | premise → RA → conclusion |
| CA | incompatibility (can't commit to both); never PTA-typed | I → CA → I / RA (undercut) / L |
| MA | rephrasing **by the speakers themselves** (not ours) | I → MA → I |

Anchoring: **Arguing → RA, Disagreeing → CA, Restating → MA**, each YA hanging
off the TA between the two locutions (or off one locution if the argument is
inside it). Agreeing anchors in the TA only when answering a question. A
reported speech is **L(reporter) → Asserting → L(reported speaker) → Asserting → I**.

## Where things live

- **Canonicalization is the L → YA → I hop.** Tick ATIP step-2 transformations on
  the YA (`pta.transformations`: anaphora, explication, illocution substitution,
  passivization, activization, nominalisation, same term). One locution may
  anchor several YAs → several I-nodes (different readings, or a universal and
  a particular claim in one sentence).
- **I-node `pta`** (Analysis): `subject`, `predicate`, `kind` F/V/P, `scope` s/p/u,
  `note`; second-order adds `subjectNode` (ID of the I-node it is about),
  `perspective` I/II/III, `acceptability` A/U (replaces the predicate with
  `[is acceptable]` / `[is unacceptable]`). Type and scope stay on second-order
  statements (they can be in α or β arguments).
- **L-node `pta`**: optional manual `perspective` (δ premise).
- **RA `pta`** (Connector): `lever` (INCEpTION keyword, e.g. `CRITERION`, or
  `novel`), `concepts` (lowercase tags), `note`. Form/substance are **derived,
  never stored**; the RA's `text` is written as the full code (`α VF Cr`).
- Lever statement: edge into the RA's side port with `role: "lever"`.
- File: `participants`, `locutions[]` (`personID`, `start`, `end` char offsets into
  plain `text`), OVA positions (drop the `OVA` block to let auto layout place
  everything).

## How an RA types (editor's `deriveCode`)

Terms compare literally (case, spacing, final punctuation ignored), so make
shared terms *identical* on the YAs first; proposition subjects compare by node.

1. **δ**: the premise is about proposition q — its `subjectNode` is q, or it is a
   **locution that says q** (anchors q via a YA) — and the conclusion is **q
   itself** (implicit A) or a second-order statement about q with **A/U**.
   Substance = premise perspective; a locution's is read off the anchoring TA's
   speakers (arguer I, addressee II, else III) unless set manually. Levers are
   filtered by A/U.
2. **α**: any other shared subject (including a shared proposition without A/U:
   "⟨q⟩ is false because ⟨q⟩ is self-contradictory" is α VV). Substance = F/V/P pair.
3. **β**: shared predicate. Substance = s/p/u pair (conclusion first).
4. **γ**: nothing shared; i/d follows from the chosen lever (Non → d).

Both shared → no form (premise restates conclusion). Anything "against" a
claim is an RA into a statement of the opposite (often second-order with U),
plus a CA from it to the original if the clash should be recorded.

## Judgement calls

Interpretive decisions (which perspective, which form, how to segment) are
recorded with their rationale and the example that raised them in
`misc/labs/xAIF/judgement-calls.md`. Read it before annotating; add to it
whenever a choice could reasonably have gone another way. The general
principles so far:

- **Perspective is the source's dialectical role, not grammatical person.**
  II is the opposing party in the dispute, however they are referred to; III
  is a source outside the disagreement (expert, witness, the public).
- **Generalising from a case is β (Exa/Sp)** and needs the *same predicate* in
  both statements; if one sentence carries both the general claim and the
  case, anchor two I-nodes from it. Reasons for the case come in serially.
- **Lever names are literal.** SYNONYMOUS needs both pairs synonymous;
  a reason is not a synonym of its conclusion. Check the lever template
  against the canonical terms before accepting it.
- **Attributing a view to discredit its holders is ad hominem** (δ II H on a
  second-order "⟨q⟩ is held by…" → "⟨q⟩ [U]"), not an argument from authority.
- **Keep what was asserted.** A thesis the locution serves is its own I-node
  (often implicit), not a rewrite of the locution's content.

## Review checklist (mistakes seen so far)

1. RA direction: the reason is the premise; check against the TA's direction.
2. Every RA/CA/MA anchored by a YA of the right force (Arguing/Disagreeing/Restating);
   no Disagreeing pointed at an RA; no YA anchoring nothing.
3. I-node keeps what the locution asserted (IAT: minimal reconstruction); the
   essay's thesis is a separate I-node, not a replacement.
4. Transformation tags match what changed (no "activization" without a voice change).
5. Reported speech and "X thinks that p": whole span + reported part; not Challenging.
6. TAs mirror argument relations (IAT 1.2.4), not sentence order; narrative
   frames are regulation (drop) or reporting frames.
7. Lever fits the derived form/substance; γ Sy only for true synonymy.
8. Speaker names spelled right; spans match the text (the editor warns).

## Writing an example file

Script it (Python `json`), then verify with a throwaway vitest file inside the
editor, and delete it afterwards:

```ts
// misc/labs/xAIF/src/lib/check.test.ts — temporary
import { expect, it } from 'vitest';
import { Doc, argumentType, lint } from './xaif';
import file from '../../examples/NAME.json';
it('lints clean and types as intended', () => {
  const doc = Doc.load(structuredClone(file));
  expect(lint(doc.nodes, doc.edges, doc.text)).toEqual([]);
  expect(argumentType('RA_ID', doc.nodes, doc.edges)).toMatchObject({ form: 'β', substance: 'up', symbol: 'Exa' });
});
```

Run `pnpm exec vitest run src/lib/check.test.ts` from `misc/labs/xAIF`. Compute
spans from the text (`text.index(words)`), keep IDs numeric, put new IDs above
the file's maximum, and drop `OVA` so the layout is fresh. For visual checks,
headless Chromium over CDP with the profile in a local `.scratch/` (never
`/tmp`), killing processes by PID (never `pkill -f` with a pattern that matches
your own shell) and deleting `.scratch/` after. `examples/downloading.json`
(undercut, two speakers), `einstein.json` (reported speech δ III Exp) and
`engels-alt.json` (generalising β, serial α, ad hominem δ II H) are the
reference examples.

Data handling: lab corpora are excerpts of published books; don't commit
example files containing them (`misc/` is untracked; keep it that way).
