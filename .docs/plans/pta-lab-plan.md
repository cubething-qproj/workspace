# PTA lab: plan

> **Outdated (2026-11-06).** The NLP lab, its INCEpTION labelling and automated classification were dropped; NPC dialogue and arguments are authored by hand. The PTA/ATIP theory is kept. Steps that share work with the reading-notes plan (embeddings, GLiNER2) depend on that plan's still-undecided fate.

Gets the PTA classifier lab running in `misc/labs/nlp`, following
`.docs/designs/pta-atip-algorithm.typ` (the classifier) and
`.docs/designs/pta-document-analysis.typ` (finding arguments). One step per
commit unless marked otherwise.

**Who does it**

- 🧑 **human**: labelling, decisions, downloads, reviewing results.
- 🤖 **agent**: code, scripts, docs, running experiments.
- 🧑🤖 **both**: the agent prepares; the human decides or checks.

Shared with the reading-notes plan (`quell-reading-notes-plan.md`): its
embedding arms (step 2), latency harness (step 3) and GLiNER2 arms (step 4).
Where a step here needs one of those, it says so; do them once, there.

## Done (uncommitted)

- `scripts/pta_schema.py` → `inception/pta-layers.json`,
  `inception/pta-constraints.txt`; `pta-cheatsheet.typ`. Includes the
  `concepts` feature (`concept` / `concept/sense` tags); not yet re-imported
  into INCEpTION.
- INCEpTION project `pta-test`: 10 website examples (key in
  `data/pta-test/key.json`), `kant-easy.txt`, `kant-enlightenment.txt`.
- INCEpTION project `pta-corpus`: 31 excerpts from 29 writers
  (`data/pta-corpus/texts/`, sources in `sources.tsv`, build scripts in
  `data/pta-corpus/build/`).

## Phase 0: schema and pilot labels

1. 🤖 **Commit the schema.** Generator, layers, constraints, cheat sheet.
   - Risk: low.
2. 🧑 **Decide the main schema.** Replace the note-lab project's layers with
   the PTA-only schema, or keep `pta-test` as the PTA project for now. Also
   decide the open gap: how to label conflict and rephrase (a relation layer
   on `Statement`, or nothing yet).
   - Outcome: a short decision; nothing else is blocked except step 3.
3. 🤖 **Update the lab docs** to the decision: `methods.typ` §10,
   `guide.typ` §3, `README.md`.
   - Risk: low; compile the `.typ` files after editing.
4. 🧑 **Label the pilot.** Finish the 10 website examples; annotate the
   `pta-corpus` excerpts. Fill each connector's canonical subject and
   predicate fields and its transformations (see the ATIP design, "Gold
   labels and evaluation").
   - Outcome: roughly 10 + 60–90 connectors. Expect slow going at first; the
     website comparison (step 6) will show where the conventions need work.
   - Risk: the conflict/rephrase gap (step 2) shows up in ¶2 and ¶4.

## Phase 1: data in and out

5. 🤖 **Converter.** INCEpTION CAS JSON → the graph YAML of the
   document-analysis design (statements, connectors, the canonical terms and
   transformations),
   with the D5 checks: cardinalities, dangling links, unused reconstructed
   statements. `notelab pta export` and `notelab pta check`. Tests on a
   made-up fixture only.
   - Risk: the auto-mode permission check may block downloading annotations
     over the API (it blocked reading the library once). Fallback: 🧑 export
     UIMA CAS JSON from the INCEpTION UI into `data/pta-test/annotations/`.
   - Note: INCEpTION holds one reading per document. Alternative readings
     stay in `note` until there is a reason to model them.
6. 🤖 **Website comparison.** Score the labels on the 10 examples against
   `key.json`: form, substance, lever, per example, with the reason for each
   disagreement. 🧑 reviews.
   - Outcome: the first human-vs-website agreement figure, and a list of
     convention problems to fix before more labelling.
7. 🤖 **Type table as data.** Move the PTA 3.1 table out of `pta_schema.py`
   into one JSON file read by the generator, the pipeline and later the Rust
   port.
   - Risk: low.

## Phase 2: the deterministic core

8. 🤖 **Pure pipeline.** Form, substance, lever, naming and composition as
   pure functions over given oracle values (design: "Suggested order" 1).
   Tests with hand-made values, including δ, ⊥, condensed γ and `novel`.
   - Risk: low; this is where the design gets checked for gaps.
9. 🤖 **Stage-wise evaluation harness.** Leave-one-writer-out split; gold
   values substituted upstream of each stage; top-1/top-3 and calibration;
   exemplar output first, statistics on request.
   - Outcome: with gold oracles everywhere, end-to-end should be near
     perfect; anything less is a bug in steps 7–8.

## Phase 3: rule baselines

10. 🧑 **Install the parser.** spaCy and `en_core_web_sm` (tens of MB).
    🤖 adds them to `pyproject.toml`.
11. 🤖 **Rule arms.** O1 (parse split + marker lexicon, following the
    coherence-marker tests in the document-analysis design, D2), O2 (lemma
    match), O3, O4, O5, O6, and O9's rule arm (voice, nominalisation). Run
    through the harness.
    - Risk: philosophical prose breaks the parse split (design: risks). Expect
      O1 and O2 to be the weakest stages.
12. 🧑🤖 **Look at exemplars.** 🤖 prints the worst cases per stage; 🧑
    reviews before any statistics are run.

## Phase 4: model arms

13. 🧑 **Download models.** Each is a separate approval (disk, licences):
    - DeBERTa-v3 NLI, xsmall and base, ONNX (O7, O8, O10);
    - a small instruction-tuned LLM, GGUF, 0.5B and 1.5B, plus llama.cpp
      (O9);
    - embedding models and GLiNER2: via the reading-notes plan.
14. 🤖 **NLI arms.** O7, O8, O10 on ONNX Runtime; thresholds from the dev
    split.
    - Risk: NLI on short, out-of-context hypotheses can be poorly calibrated;
      the harness will show it.
15. 🤖 **O2 and GLiNER2 arms.** Reuse the reading-notes tier 1 and tier 2
    arms once they exist.
    - Blocked on: reading-notes steps 2 and 4.
16. 🤖 **O9 generative arm.** The LLM with 3–8 in-context examples from the
    dev split (needs the canonical forms), gated as in the design. Every
    candidate recorded.
    - Risk: highest. Slow on CPU; may tidy arguments; few pilot examples.
    - Outcome: the first measure of how often O9 proposes the labeller's
      rewording.
17. 🤖 **Latency.** Run every arm through the reading-notes latency harness.
    - Blocked on: reading-notes step 3.
18. 🧑🤖 **Review and choose.** 🤖 summarises per stage and per arm; 🧑 picks
    the arms to keep and what to label next.

## On hold

- **Automation beyond gold connectors.** Running the pipeline on larger texts
  waits until the document-analysis procedure (finding statements,
  connectors and readings) is pinned down as an algorithm. Until then every
  run starts from human-labelled connectors.

## Later

- 🧑 More labelled text (more writers, and longer passages from the same ones), and a second annotator
  on a sample for the agreement ceiling.
- 🤖 Oracles for the document-analysis procedure (D1, D2, D4), so connectors
  can be found automatically.
- 🤖 Distil the reviewed LLM rewrites into the seq2seq arm; Rust port of the
  chosen arms.
