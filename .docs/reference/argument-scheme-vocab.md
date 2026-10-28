# Argument scheme vocabulary

Research notes for a `scheme` label on `ArgumentRelation` inference edges:
what *kind* of move an inference is. Candidates only; nothing here is in
`layers.json` yet. See also `aif-node-types.md` (in AIF terms, a scheme is the
F-node an RA node fulfils).

## The standard typologies

Two scheme typologies are in current use in argument annotation. Visser et al.
(2021) annotated the same corpus (US 2016 election debates, IAT-annotated) with
both. It is the closest precedent for what we would do.

| Typology | Built how | Shape | Notes |
| -------- | --------- | ----- | ----- |
| Walton, Reed & Macagno (2008) | Empirical: patterns observed in practice | ~96 named schemes, each with critical questions | The de facto standard. Grouped below. Refined into a classification tree by Walton & Macagno (2016). |
| Wagemans, Periodic Table of Arguments (PTA, 2016–2019) | Factorial: a few theoretical dimensions crossed | 2 × 2 × 9 = 36 types | Labels like `1 pre VF`. More systematic, less intuitive. |
| Pragma-dialectics (van Eemeren & Grootendorst) | Theoretical: three relations between premise and standpoint | 3 types: *symptomatic*, *comparison*, *causal* | Very coarse; a useful top level. Fallacies = violations of the ten rules of a critical discussion. |

### Walton's groups (as used by Visser et al. 2021)

| Group | Subgroup | Example schemes |
| ----- | -------- | --------------- |
| Reasoning | deductive, inductive, practical, abductive | practical reasoning, argument from cause to effect, argument from sign, argument from consequences, abduction (inference to the best explanation) |
| Source-based | position to know, commitment, attacking personal credibility, popular acceptance | argument from expert opinion (the legitimate "appeal to authority"), argument from position to know, argument from commitment, ad hominem, argument from popular opinion |
| Applying rules to cases | based on cases, defeasible rule-based, verbal classification, chained | argument from example, argument from analogy, argument from verbal classification, argument from precedent, slippery slope |

Most frequent in Visser et al.'s debate corpus: argument from example (81),
cause to effect (48), practical reasoning (45), consequences (40), sign (38),
plus 14 left as "default inference" (no scheme fits). The top handful cover
most of the data; a long tag list mostly goes unused.

### PTA dimensions

> **Outdated.** This describes the pre-3.1 PTA (36 types, labels like `1 pre FF`).
> PTA 3.1 / ATIP v6 uses forms α/β/γ/δ and 50 types: see the `pta-atip` skill
> and `.docs/designs/pta-atip-algorithm.typ`.

- **Order:** first-order (premise bears on the standpoint directly) or
  second-order (bears on the acceptability of another statement, e.g. via a
  source).
- **Subject/predicate:** which element stays fixed (the *fulcrum*) and which
  changes (the *lever*) between premise and conclusion.
- **Substance:** premise and conclusion are each **F**act, **V**alue or
  **P**olicy (9 combinations).
- Example: `1 pre FF` = first-order predicate argument, fact → fact. Its
  traditional names are argument from sign, from cause, from effect.

## Formal (deductive) moves

Standard propositional and syllogistic forms, from intro logic texts (forall x,
etc.). Pairs with our existing `strength: deductive`.

| Move | Form |
| ---- | ---- |
| modus ponens | P → Q, P ⊢ Q |
| modus tollens | P → Q, ¬Q ⊢ ¬P |
| hypothetical syllogism | P → Q, Q → R ⊢ P → R |
| disjunctive syllogism | P ∨ Q, ¬P ⊢ Q |
| constructive dilemma | P → Q, R → S, P ∨ R ⊢ Q ∨ S |
| reductio ad absurdum | assume P, derive contradiction ⊢ ¬P |
| categorical syllogism | All M are P, all S are M ⊢ all S are P (and the other valid moods) |

Formal fallacies (affirming the consequent, denying the antecedent) are these
forms misapplied.

## Rhetorical moves

- **Aristotle's three *pisteis***: *ethos* (the speaker's character), *pathos*
  (the hearer's emotions), *logos* (the argument itself). This is a separate
  axis from the scheme: one inference can be argument from expert opinion
  *and* lean on ethos.
- **Enthymeme** (rhetorical deduction from accepted opinions, premises left
  implicit) and **example** (*paradeigma*, rhetorical induction). These map
  onto `reconstructed` premises and argument from example.
- **Topoi**: general headings that generate arguments, e.g. from opposites,
  from genus to species, from more and less. Many Walton schemes descend from
  them.

**Appeal to authority is not itself a fallacy.** Most appeals to authority are
legitimate. One is fallacious when the source lacks expertise, can't be
trusted, disagrees with other experts or is misquoted (IEP). Walton models this
as a scheme with critical questions. So: label the *scheme*, and record
fallaciousness separately (a flag or `note`) rather than keeping a parallel
fallacy taxonomy.

## Philosophy-specific moves

Not covered well by Walton or the PTA, which come from everyday and legal
argument. These are the moves our corpus actually makes.

| Move | Gloss | Source |
| ---- | ----- | ------ |
| transcendental argument | From an undeniable fact about thought or experience to a substantive condition it presupposes (Kant, Strawson). | SEP "Transcendental Arguments" |
| thought experiment (destructive / constructive) | An imagined scenario run to refute a theory (internal contradiction, clash with other beliefs, undermining a premise, counter-thought-experiment) or to support or illustrate one. | SEP "Thought Experiments" (Brown's taxonomy) |
| reductio | As above; in philosophy often informal (shows a view leads to absurdity). | logic texts |
| counterexample | A single case refutes a universal claim. | general |
| regress | A view requires an infinite (vicious) series. | general; not yet sourced |
| dialectical sublation (*Aufhebung*) | A determination shows its one-sidedness, passes into its opposite, and is cancelled-and-preserved in a higher unity. Thesis–antithesis–synthesis is the textbook gloss, not Hegel's own method. | SEP "Hegel's Dialectics" |
| genealogy, deconstruction | Nietzsche/Foucault, Derrida. | not yet sourced |

## Concept-level moves (for a concept-relation layer)

From SEP "Analysis", which distinguishes four conceptions of analysis. These
act on *concepts*, not propositions, so they belong on concept-to-concept edges
rather than on `ArgumentRelation`.

| Move | Gloss |
| ---- | ----- |
| decompositional analysis | Breaks a concept into simpler components. |
| regressive analysis | Works back from a concept to the more basic principles it rests on. |
| transformative analysis | Restates the concept in a privileged framework (e.g. logical form) first: Frege, Russell, Carnap. |
| connective analysis | Clarifies a concept by its relations to the wider whole it belongs to. |
| synthesis | The converse of analysis: builds a concept up from principles or parts. |
| sublation | Hegel's move, as above; n-ary like synthesis. |

## Open questions

- One `scheme` feature with a grouped tagset, or two features (`scheme` +
  `appeal` for ethos/pathos/logos)?
- How coarse? Agreement on fine Walton schemes is hard; a top level
  (pragma-dialectics' three, or Walton's three groups plus *formal* and
  *philosophical*) with optional fine labels may be the practical compromise.
- Inter-annotator agreement for the Walton vs PTA annotations is in Visser et
  al. §5; not yet checked.

## Sources

- Visser, Lawrence, Reed, Wagemans, Walton. "Annotating Argument Schemes."
  *Argumentation* 35, 2021. <https://pmc.ncbi.nlm.nih.gov/articles/PMC7888437/>
- Walton, Reed, Macagno. *Argumentation Schemes.* Cambridge UP, 2008.
- Walton, Macagno. "A classification system for argumentation schemes."
  *Argument & Computation* 6(3), 2016. doi:10.1080/19462166.2015.1123772
- Wagemans. "Four Basic Argument Forms." *Research in Language* 17(1), 2019.
  doi:10.2478/rela-2019-0005
- Pragma-dialectics overview: <https://en.wikipedia.org/wiki/Pragma-dialectics>
- Dowden. "Fallacies." *Internet Encyclopedia of Philosophy.* <https://iep.utm.edu/fallacy/>
- SEP: "Aristotle's Rhetoric" <https://plato.stanford.edu/entries/aristotle-rhetoric/>,
  "Analysis" <https://plato.stanford.edu/entries/analysis/>,
  "Transcendental Arguments" <https://plato.stanford.edu/entries/transcendental-arguments/>,
  "Thought Experiments" <https://plato.stanford.edu/entries/thought-experiment/>,
  "Hegel's Dialectics" <https://plato.stanford.edu/entries/hegel-dialectics/>
- forall x (Open Logic Project): <https://forallx.openlogicproject.org/>
