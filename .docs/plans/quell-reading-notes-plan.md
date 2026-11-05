# Quell reading notes: plan

Implements `.docs/designs/quell-reading-notes-design.md` in note-lab.
note-lab's code is archived at the tag `note-lab-final` in `misc/labs/nlp`,
which is now the debate model lab (2026-11-05). One step per commit; each goes through manual review, then a staged Sonnet
review whose fixes stay unstaged until approved.

## Done

| step | commit | contents |
| ---- | --------- | ------------------------------------------------------------------- |
| 1 | `65f239d` | Scaffold: uv project, README, `.gitignore` (data/ except fixture), made-up fixture. |
| 2 | `a186d82` | Plain texts + W3C standoff annotations, concept registry, notes, `notelab check`, tier 0 coverage, tests. |

## Next (order revised 2026-10-20)

Scoring and stats were moved after a data pilot: they depend on the shape of
real gold labels. The steps below don't.

1. **Prediction record.** One row per (arm, note, concept, score) plus per-note
   timing; arm registry; tier 0 as the first arm (`spans`, all layers and
   per layer). `notelab show <set> --arm …` prints exemplars.
   - Risk: low. Keep the schema minimal; scoring reads it later.
2. **Tier 1 arms.** Embedding models via ONNX Runtime; `label` (label +
   description) and `proto` (mean of dev-split example notes) modes.
   - Risk: `fastembed` model coverage; downloads (tens of MB each) into the
     default HF cache.
3. **Latency/throttle harness.** Subprocess per (arm, profile); cold load,
   peak RSS, disk size, p50/p95/p99; profiles `host`/`mid`/`low`/`starved`;
   length sweep; charts.
   - Risk: `systemd-run --user` CPU delegation may be off; fall back to
     `taskset` + thread limits and say so in the README.
4. **Tier 2 arms.** GLiNER2 and GLiNER/GLiClass.
   - Risk: highest. New package, torch install size, Python version support
     (the machine has 3.14; torch may need 3.12/3.13); ONNX export may fail,
     making latency not directly comparable to tier 1.

## Blocked on the designer

5. **Pilot.** Designer annotates one real excerpt in Label Studio and/or
   INCEpTION (overlaps, a relation or two, ~10 notes with gold labels) and
   exports it.
6. **Converter.** Tool export → our W3C subset (texts) and notes; validated by
   `notelab check`. Settles how notes and gold labels are authored.
7. **Scoring and stats.** Designed against the pilot's shape: metrics, paired
   bootstrap, McNemar, abstention curve, calibration.
8. **`exp/01-baseline`.** Exemplars → designer looks → stats on request.

## Deferred

- Type validation of malformed JSON in `check` (marked `# DEFERRED:` in
  `data.py`); JSON is generated, not hand-written.
- Stray `.json` without a matching `.txt` is ignored silently.
- Fine-tuning (tier 1/2) once materials are final.
- Relations and the game-side notebook format.
