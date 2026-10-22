# Quell reading notes: design

The player reads in-world texts, highlights passages, and writes free-text
notes. NPC dialogue is canned and gated on what the player has engaged with,
so the game needs **concept ids** out of highlights and notes. This design
covers the data format (shared by the lab and, eventually, the game) and the
lab that measures interpreters. Background research: "Local 'System One'
models for reading notes and NPC talk" (2026-10-20).

The texts are philosophical, not lore dumps: one passage carries several
overlapping topics, and structure (arguments, objections, references) matters
as much as topics. Training material is excerpted from real books and is
**never committed or published**.

## Scope

Tiers 0–2 of the research doc only:

| tier | approach | output |
| ---- | --------------------------------------------------- | ------------------------------------- |
| 0 | authored annotations; highlight → concepts by coverage | score per concept, no model |
| 1 | embedding similarity (MiniLM / BGE-small / e5-small class) | cosine score per concept |
| 2 | schema-driven encoders (GLiNER2, GLiNER / GLiClass) | concept, stance, slots with scores |

Few-shot only for now (tier 1 `proto` arm: concept anchored by its dev-split
example notes). **Fine-tuning is deferred** until the designer has finalized
materials; there isn't a big enough corpus yet.

## Data format

A data set is a directory (`misc/note-lab/data/<set>/`; everything except
`data/fixture/` is gitignored):

| path | contents |
| --------------- | ------------------------------------------------------------------------ |
| `texts/*.txt` | Plain text, exactly as the player reads it. |
| `texts/*.json` | Optional W3C annotation page for the same-named text. |
| `concepts.toml` | Concept ids with label and description; the closed stance and slot sets. |
| `notes.jsonl` | One note per line: text, highlighted span, gold labels, `dev`/`holdout`. |

**Offsets** are `[start, end)` in Unicode code points over the text file, read
as UTF-8 with no newline translation. A Rust port must convert to/from byte
offsets.

**Annotations** use a subset of the
[W3C Web Annotation Data Model](https://www.w3.org/TR/annotation-model/)
(Recommendation, 2017): chosen because overlap is free, it gives the Rust side
a stable spec, and it can be replaced later if needed.

```json
{ "type": "AnnotationPage", "items": [
  { "id": "a2", "type": "Annotation", "motivation": "classifying", "layer": "argument",
    "body": [{ "type": "TextualBody", "purpose": "tagging", "value": "slave_morality" }],
    "target": [
      { "source": "genealogy.txt", "selector": [
          { "type": "TextPositionSelector", "start": 118, "end": 260 },
          { "type": "TextQuoteSelector", "exact": "…", "prefix": "…", "suffix": "…" } ] },
      { "source": "genealogy.txt", "selector": { "type": "TextPositionSelector", "start": 530, "end": 610 } } ] } ] }
```

- One tagging body per concept; one target per range (interrupted passages).
- `TextPositionSelector` is required. `TextQuoteSelector` is optional and is
  checked against the text, so offsets that drift after a text edit fail
  loudly. (A whole-file `sha256` was considered and dropped: W3C has no
  standard place for it, and quotes catch drift where it happens.)
- `layer` is our extension: what *kind* of structure an annotation is.
  Free-form for now; no list exists yet.
- W3C allows a single object anywhere an array is shown; both are accepted.
- Bodies with other purposes are ignored, so relations and comments can be
  added without breaking loading.

### Layers and relations

In annotation tools a *layer* is a kind of annotation with its own fields,
relations and overlap rules; values within a layer are labels. The designer
wants both: many overlapping concepts at different scales (one layer, plus a
concept hierarchy in `concepts.toml` if needed) **and** different kinds of
structure (argument structure, cross-references, rhetorical moves), where
**relations matter** (premise *supports* conclusion, passage *answers* Kant).
In W3C, a relation is an annotation whose targets are other annotations
(motivation `linking`). Not read yet; tiers 0–2 don't use them.

Possible later unification: the player's own highlights (`highlighting`) and
notes (`commenting`) fit the same model, so the game could store authored tags
and the notebook in one format.

### Authoring

JSON is **not hand-authored**: it is the output of a labelling pipeline (tool
export → converter → our format). The tool is swappable; the designer is
evaluating:

- **Label Studio**: overlapping spans and relations; simple export
  (`start`/`end`/`text`/`labels`). Reads UTF-8 only, hence
  `scripts/to_utf8.py`.
- **INCEpTION**: built for layered, relation-heavy research annotation and
  concept linking; robust but complex.
- Recogito was ruled out.

Open: notes and their gold labels must also come out of the pipeline;
`notes.jsonl` is hand-written today.

## Tier 0

`Text.concepts_at(start, end, layer=None)` returns, per concept, the share of
the highlight covered by the union of that concept's ranges (optionally one
layer). On the fixture it already shows the limits: a broad `argument`
annotation scores both its concepts 1.0 for any highlight inside it (including
the "nice willows" note that should map to nothing), and an untagged passage
returns nothing. The note text has to do the rest; that's tiers 1–2.

## Lab method (`misc/note-lab`)

Modelled on `misc/hex-lab`.

- **Arms** are model + configuration, in a registry; never deleted, so any
  experiment tag reruns.
- **Records**: one CSV row per (arm, note, concept score), plus per-note
  timing. Every row kept, including failures.
- **Exemplars before stats**: `show` prints a few notes with gold labels and
  each arm's top-3; full statistics only on request.
- **Statistics** (to be designed against real data, see below): bootstrap CIs
  over notes; comparisons are **paired** (every arm sees the same notes), via
  paired bootstrap on score differences and exact McNemar on top-1 as a check.
  Notes on one passage aren't independent; consider resampling by passage.
  Many pairwise comparisons → compare each arm against one baseline.
- **Candidate metrics**: top-1/top-3, multi-label P/R/F1 at a threshold,
  stance accuracy, slot matches, abstention curve (accuracy vs. coverage as
  the confidence threshold rises: the "NPC doesn't get it" fallback),
  calibration.
- **Latency**: each (arm, profile) in its own subprocess; cold load, peak RSS,
  model size on disk, per-note p50/p95/p99 after warm-up over N repeats.
  Text length is swept until real passages exist.
- **Throttle profiles** (CPU only; the GPU is the renderer's):

  | profile | how |
  | --------- | ------------------------------------------------------------ |
  | `host` | all cores, no limits |
  | `mid` | `taskset` to 4 cores, 4 ORT threads |
  | `low` | `systemd-run --user -p CPUQuota=100% -p MemoryMax=2G`, 1–2 threads |
  | `starved` | `CPUQuota=50%`, 1 thread |

  Clock speed can't be lowered without root; quota stands in for slow cores.
  Check `systemd-run --user` cgroup CPU delegation first; fall back to
  `taskset` + thread limits.
- **Runtime**: tier 1 via ONNX Runtime (`fastembed` or `optimum`), the same
  runtime as Rust's `ort`, so latency carries over. GLiNER2 may need torch;
  record the runtime as a column if so.
- **Experiments**: tagged commit `exp/NN-name`, summary in
  `misc/note-lab/experiments/NN-name.md`, figures in
  `.docs/designs/quell-reading-notes/experiments/NN-name/`.

## What depends on real data

Decided only after a pilot export from the labelling tool:

- the scoring rule (what a correct answer is; how many concepts per note,
  nesting, layer- or relation-level labels);
- which statistics are viable (note count, balance, notes per passage);
- whether stance and slots stay in the gold labels at all.

Independent of data: the prediction record, tier 1–2 inference, and the
latency/throttle harness.
