---
name: pta-atip
description: Classifying an argument with Wagemans' Argument Type Identification Procedure (ATIP v6) into a Periodic Table of Arguments (PTA v3.1) type — the six steps (label elements, canonicalize to "conclusion because premise", form alpha/beta/gamma/delta, substance, lever, name), the lever tables, the 50 type symbols, and the record format the lab uses for comparing model and human labels. Use when labelling the scheme of an inference, assigning a PTA code like "α FF Cau", checking or explaining a PTA classification, or auto-labelling connectors in the PTA lab (misc/labs/nlp).
---

# PTA argument typing (ATIP v6)

Source: Wagemans, J.H.M. (2026). *Argument Type Identification Procedure
(ATIP) – Version 6*, aligned with PTA 3.1. Local copy:
`.docs/reference/Wagemans2026-ArgumentTypeIdentificationProcedureATIP-Version6.pdf`.
Worked examples of all 50 types: <https://www.periodic-table-of-arguments.org/pta-3-1-clickable>.
The full type table is in [types.md](types.md).

The PTA defines a type as a unique combination of three parameters: **form**,
**substance** and **lever**. Don't match the argument against a list of names;
determine the three values in order, then read off the name.

**PTA 3.1 replaced the older labels.** The 2016–2019 papers (and Visser et al.
2021) use `1 pre FV`-style labels with 36 types. ATIP v6 uses forms
alpha/beta/gamma/delta and 50 types. Use the new scheme only.

## Unit of analysis

One argument = one **conclusion**, one **premise** and a **lever**. The lever
is a third statement linking them, almost always implicit. Each statement has
a **subject** (what it is about) and a **predicate** (what is said of it).

In the lab's INCEpTION schema: one `Connector` span, whose links name its
`conclusion`, `premise` and (only if the text states or argues about it)
`lever statement`, all `Statement` spans. Its `form`, `substance` and `lever`
features hold the result, `conclusion subject`, `conclusion predicate`,
`premise subject` and `premise predicate` the canonical form (a, X, b, Y in
the lever templates; for delta q, A/U, q, Z), `transformations` the wording
changes as `kind (statement)` tags, once each and unordered, and `concepts`
the concepts it is about (`concept` or `concept/sense`). ATIP covers single premise–conclusion pairs
only; a premise that works only jointly with another is noted in `notes`
(our convention, not ATIP's).

## Part I. Standardization

### Step 1. Label the textual elements

Mark in the original text: conclusion, premise, and the subject and predicate
of each. Also mark surrounding elements, which help find the essential ones
and get dropped in step 2:

- **coherence marker**: shows premise/conclusion function ("because",
  "therefore", "so", "if").
- **structure marker**: relates the argument to others outside the pair ("in
  addition", "secondly").
- **illocutive marker**: the arguer's attitude to q ("I argue that q", "q is
  true", "I don't believe q").
- **perlocutive marker**: the intended effect of convincing ("you should
  accept that q", "I hope you realize q").

Rhetorical questions and implicit material are labelled "propositional
content" here and resolved in step 2.

### Step 2. Reformulate into canonical form

Target: **"conclusion because premise"**, more precisely
"subject-predicate because subject-predicate". Apply as many of these as
needed:

- transposition (put the conclusion first)
- addition of "because"
- substitution of the original coherence marker by "because"
- omission of structure, illocutive and perlocutive markers
- anaphora resolution (same entity → same, most informative, words)
- explication (add implicit elements to the propositional content)
- illocution substitution (e.g. rhetorical question → assertion)
- passivization/activization (to bring out a shared subject or predicate)

The aim of anaphora resolution and passivization is to make shared elements
*literally* shared, because step 3 depends on it.

Record the result the way the gold labels do: the four canonical terms
(conclusion subject and predicate, premise subject and predicate), and, as
`kind (statement)` tags, only the transformations that changed a term's
wording: `anaphora`, `explication`, `illocution substitution`,
`passivization`, `activization`, `nominalisation` (ours), `same term` (two
different wordings judged one term, ours), each with `(conclusion)` or
`(premise)`. Once each, in any order. Transposition, "because" and omitted
markers aren't recorded: the roles and markers already show them.

## Part II. Characterization

### Step 3. Form

Letters: subjects a, b; predicates X, Y, Z; whole propositions q.

| Form | Abstract form | Shared element |
| ---- | ------------- | -------------- |
| alpha (α) | a is X because a is Y | same subject |
| beta (β) | a is X because b is X | same predicate |
| gamma (γ) | a is X because b is Y | nothing |
| delta (δ) | q is A/U because q is Z | the whole proposition q |

**Delta** is for source-based arguments (expert opinion, personal attack,
threats, popularity…). The subject of the conclusion is a whole proposition q;
its predicate is **A** (acceptable) or **U** (unacceptable), from an
illocutive or perlocutive marker. When acceptability is implicit, which is
usual, write it in brackets: "the economy has grown (q) [is acceptable (A)]
because that (q) was said by Eurostat (Z)".

### Step 4. Substance

The value set depends on the form. Always write **conclusion first, then
premise**.

**Alpha: predicate types** (debate theory's fact/value/policy):

- **F** fact: a claim about reality checkable by observation, measurement or
  evidence. Includes empirical, existential, predictive and fictive
  statements. A false empirical claim is still F.
- **V** value: a judgement against some standard: aesthetic, moral, legal
  qualification, pragmatic, logical ("this is true"), hedonistic, evaluative.
- **P** policy: recommends or prescribes action: advice, incitement,
  imperative, proposal, plan, policy. Often "should"/"ought".

Example: "the minister did a great job (V) because she raised the university
budget (F)" → **VF**.

**Beta: subject types** (from Aristotle's *De interpretatione*):

- **s** singular: one individual or object.
- **p** particular: some, but not all, of a group ("some", "a few").
- **u** universal: all members of a group.

Example: "cycling on the lawn (s) is prohibited because all activities on the
lawn (u) are prohibited" → **su**.

**Gamma: compare the subject relation with the predicate relation.**

- **i** identical: a relates to b as X relates to Y ("peace can be started by
  the truth because war can be started by lies": peace/war ~ truth/lies).
- **d** different. First try to read it as a **condensed** gamma: insert
  "a is Y" between them, giving "a is X because a is Y because b is Y", an
  alpha argument chained to a beta argument. Then restart at step 4 for each
  of the two. If no insertion makes the premise relevant, the substance is
  **d** and the type is non sequitur.

**Delta: perspective of the premise.**

- **I** first person (the arguer as source: "I say so, and I have a
  reputation").
- **II** second person (the addressee: threats, rewards, their commitments,
  their character).
- **III** third person (a third party: an expert, testimony, the public).

### Step 5. Lever

The lever says *how* the premise makes the conclusion acceptable. It is
rarely stated; reconstruct it from form, substance, context and background
knowledge. Explicit cue words ("is a SIGN of", "is ANALOGOUS to", "is the
DEFINITION of") settle it when present.

The substance restricts the candidates. Generate the candidates from the
table for the form and substance, test each against the context, pick the best,
and record the runners-up.

**Alpha**: lever "Y R X" (premise predicate related to conclusion predicate).

| Substance | Levers |
| --------- | ------ |
| FF | Y is a SIGN of X · a CAUSE of X · an EFFECT of X · CORRELATED with X · a MOTIVE for X · Y EXCLUDES X (negative: conclusion denies) |
| VF | Y is a CRITERION for X · the DEFINITION of X · can be SUBSUMED under X |
| VV | Y is a NORM for X · an INSTANTIATION of X · a DISQUALIFIER of X |
| PF | Y is a PRAGMATIC MOTIVATION for X · a PRIOR INVESTMENT in X · the FEASIBILITY of X |
| PV | Y is a PRINCIPLED MOTIVATION for X · an EVALUATIVE MOTIVATION for X |
| PP | Y is a DEONTIC MOTIVATION for X · a TELEOLOGIC MOTIVATION for X |

PTA 3.1 lists no levers for FV, VP or FP. An alpha argument with one of these
substances gets a written-out lever and `type: novel` (see step 6).

**Beta**: lever "a R b" (relation between subjects).

| Substance | Levers |
| --------- | ------ |
| ss, pp, uu | a is ANALOGOUS to b · SIMILAR to b · COMPARABLE to b · EQUAL to b · described METAPHORICALLY as b · COMPOSED of b · a PART of b · RANKS BELOW b · RANKS ABOVE b · OWES RECIPROCITY to b |
| ps, us, up | b is an EXAMPLE of a · a SPECIES of a |
| sp, su, pu | a belongs to the TOTALITY of b · the GENUS of b |

**Gamma**: the subject relation and the predicate relation are the same
relation.

| Substance | Levers |
| --------- | ------ |
| i | b is SYNONYMOUS to a and Y to X · the OPPOSITE · DERIVATIVE · INTEGRATIVE · the CONVERSE (same pattern) |
| d | none (non sequitur) |

**Delta**: lever "Z R A/U". Most rest on a positive property of a source; *ad
ignorantiam* rests on the absence of refutation and *ad consequentiam* on what
would follow if q were true.

| Substance | Levers |
| --------- | ------ |
| I | Z is ETHOTICALLY AUTHORITATIVE for A |
| II | Z is CHARACTERALLY AUTHORITATIVE for U · a NEGATIVE MOTIVATION for A · an OFFERED REWARD for A · Z COMMITS the addressee to A · an UNDESIRABLE IMPLICATION supporting U |
| III | Z is EPISTEMICALLY · MORALLY · TESTIMONIALLY · POPULARLY AUTHORITATIVE for A · a PRESUMPTION in favor of A |

## Part III. Naming

### Step 6. Name the argument

Names follow the lever's KEYWORD (CAUSE → argument from cause). Look it up in
[types.md](types.md). Each type has a **symbol**: the shortest initial part of
the name no other type shares (A, G, H; Su, Sy, Sig, Sim; Cpo vs Cpa, Cce vs
Cse).

The PTA is open. If the reconstructed lever fits none in the table, don't
force one: write the lever out, set `type` to `novel`, and explain it in
`notes`.

## Output record

One record per argument. The `code` line is the compact label compared
against human labels: form letter, substance, symbol, separated by spaces
(`α FF Cau`, `β su G`, `γ i Op`, `δ III Exp`, `γ d Non`). A condensed gamma
yields two records (the alpha and the beta), linked in `notes`.

```yaml
id: <edge or passage id>
original: <text as given>
elements:            # step 1
  conclusion: …
  premise: …
  markers: [{text: "so", kind: coherence}, …]
canonical:           # step 2, the same four fields as the gold labels
  conclusion: {subject: …, predicate: …}
  premise:    {subject: …, predicate: …}
transformations: ["anaphora (premise)"]   # kind (statement), once each, unordered
form: alpha          # step 3
substance: VF        # step 4, conclusion first
lever: Y is the DEFINITION of X   # step 5
lever_instance: <the lever template filled with the canonical terms; rendered, not labelled>
type: argument from definition (Def)   # step 6
code: α VF Def
confidence: high | medium | low
alternatives: [α VF Cr]   # runner-up codes, if any
notes: <implicit material added, ambiguities, joint premises>
```

## Pitfalls

- **Substance order** is conclusion then premise. "VF" ≠ "FV".
- **Form depends on literal sharing.** Two wordings of one subject are only
  "the same subject" after anaphora resolution in step 2. Do it explicitly or
  you'll misread alpha/beta as gamma.
- **Delta's predicate is acceptability, not content.** If the premise is about
  *who said q* or *what follows from q*, it's delta even when it looks like
  alpha.
- **Don't skip condensed gamma.** Try the insertion before settling on d/Non;
  Non is a finding that the premise is irrelevant, not a fallback.
- **Fact ≠ true.** F is about checkability, not truth.
- **Philosophical texts** often state the conclusion far from the premise,
  leave the lever implicit, and argue at the level of concepts. Record
  reconstruction in `notes` and lower `confidence` rather than guessing.

## Data handling

Records quote the source text. lab sources are excerpts of published
books: never commit records containing `original`, `elements` or `canonical`
text to the repo (see the `inception-api` skill).
