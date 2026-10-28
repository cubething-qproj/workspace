#set heading(numbering: "1.")
#set page(numbering: "1")
#import "@preview/merman:0.3.0": show-mermaid-blocks

#show raw.where(block: true): set block(breakable: false)
#show raw.where(lang: "mermaid"): show-mermaid-blocks(typography: (font: ("Libertinus Serif",), size: "13px"), width: 100%)
#show raw.where(lang: "python"): it => block(fill: luma(246), inset: 8pt, radius: 3pt, width: 100%, it)
#show raw.where(lang: "yaml"): it => block(fill: luma(246), inset: 8pt, radius: 3pt, width: 100%, it)

#let fig(width, body) = align(center, block(width: width, body))
#let decide(body) = block(fill: luma(235), inset: 8pt, radius: 3pt, width: 100%)[*Decision needed:* #body]

= ATIP as an algorithm: design note

This note turns a published procedure for classifying arguments into a
program. It labels arguments with their type, first against human labels in
the note-lab annotation project, later in-game against the player's own
arguments.

== Background: the PTA and ATIP <background>

The _Periodic Table of Arguments_ (PTA, version 3.1) classifies arguments into
50 types (Wagemans; see @references). In the PTA an argument consists of three statements:

- a *conclusion*, the claim being argued for;
- a *premise*, the reason given for it;
- a *lever*, the usually unstated statement that says _how_ the premise makes
  the conclusion acceptable ("rising prices are a CAUSE of strikes").

Each statement has a *subject*, what it is about, and a *predicate*, what it
says of the subject. An argument's type is the unique combination of three
parameters:

- *form*: which elements the conclusion and premise share. There are four
  forms, written α, β, γ, δ (@form).
- *substance*: what kind of statements or terms are involved (@substance).
- *lever*: the relation the lever statement asserts, named by a keyword in
  capitals such as CAUSE or ANALOGOUS (@lever).

The _Argument Type Identification Procedure_ (ATIP, version 6) determines these
in six steps (Wagemans 2026): (1) label the textual elements, (2) reformulate the argument
as "conclusion because premise", (3) determine the form, (4) the substance, (5)
the lever, and (6) name the type. This note follows the same six steps.

Each type has a name and a symbol: "argument from cause", `Cau`. We write a
classified argument as a *code* of form, substance and symbol: `α FF Cau` is an
alpha argument whose conclusion and premise are both statements of fact, of
the type argument from cause. @types lists all 50 types.

== Scope <scope>

In scope:
- Typing one argument, a single premise → conclusion pair, with a code, plus a
  confidence and the runner-up codes, and the canonical terms and
  transformations it was typed from. These fields are the *output record*;
  it has the same shape as the gold labels (@gold).
- Measuring each part of the procedure against human labels.
- The shape of the output that the game consumes.

This automates the Initial Analysis of CAPNA, the Comprehensive Assessment
Procedure for Natural Argumentation (Hinton and Wagemans 2023, @references):
find an argument and type it with ATIP. Its later stages (process, reasoning,
language) evaluate the typed argument, with questions that depend on the type
("is a SIMILAR to b?").

Out of scope:
- Judging whether an argument is _good_. That is a later step that reads this
  one's output: CAPNA's process, reasoning and language stages.
- How the game uses the output: deciding which of its keys an argument unlocks
  (sketched in @in-game only as an interface).
- Explication of missing premises in free text (see @risks). In the lab,
  reconstructed premises come from the human labels.

== Principle: a deductive program with statistical oracles

ATIP is mostly a decision table. Steps 3 and 6 are lookups; steps 4 and 5 pick
from small closed sets. So the program is deterministic, and every judgement it
can't make by rule is an *oracle*: a named function from an argument $a$ and its
surrounding text $"ctx"$ (both defined in @input) to a probability distribution
over a small closed set:#footnote[$V_i$
is the oracle's set of possible answers; $Delta(V_i)$ is the set of probability
distributions over it: one probability per answer, summing to 1.]

$ O_i : (a, "ctx") -> Delta(V_i), quad |V_i| <= 10 $

A rule is an oracle that returns a point mass.#footnote[A distribution with all
its probability on one answer: 1 for its answer, 0 for the rest.] Rules and
models are therefore interchangeable per oracle, so each oracle has its own
arms#footnote[An arm is one way of answering an oracle, e.g. a rule baseline or
a particular model with a particular configuration.] in the lab (rule baseline,
embedding model, NLI model, …). Every statistical
judgement is localised, named and testable on its own.

There are ten oracles, $O_1$ to $O_10$. Each is introduced at the step that
uses it, and @oracles summarises them. $O_9$ is the exception to the closed-set
rule: it generates candidate rewordings (@rewriting). The whole pipeline, with deterministic
steps as
#text(fill: blue.darken(20%))[*blue rectangles*] and oracles as
#text(fill: orange.darken(20%))[*yellow hexagons*]:

#fig(70%)[
```mermaid
flowchart TD
  in(["argument a"]) --> s1["1 · elements"] --> s2["2 · canonical form"] --> s3["3 · form"]
  s3 --> s4["4 · substance"] --> s5["5 · lever"] --> s6["6 · name"] --> out(["code distribution"])
  O1{{"O1 spans"}} -.-> s1
  O2{{"O2 sameness<br/>(used again in 3)"}} -.-> s2
  O9{{"O9 · O10 rewrites"}} -.-> s2
  O5{{"O5 delta?"}} -.-> s3
  O3{{"O3 · O4 · O6 · O7"}} -.-> s4
  O8{{"O8 lever"}} -.-> s5
  classDef det fill:#dbeafe,stroke:#1d4ed8
  classDef oracle fill:#fde68a,stroke:#b45309
  classDef io fill:#e5e7eb,stroke:#374151
  class s1,s2,s3,s4,s5,s6 det
  class O1,O2,O9,O5,O3,O8 oracle
  class in,out io
```
]

== Input <input>

=== The argument graph <graph>

A text is a graph with two kinds of node:

- *statements* $S$: anything that can be a conclusion, a premise or a lever;
- *connectors* $K$: one per PTA argument (one triad).

A connector $k in K$ is defined by three role relations from statements to
connectors:

$ C, P, L subset.eq S times K $

$(s, k) in C$ reads "$s$ is the conclusion of $k$", and likewise $P$ for
premise and $L$ for lever. Each connector has *exactly one* conclusion and
*exactly one* premise, and *at most one* lever statement:

$ |C^(-1)(k)| = |P^(-1)(k)| = 1, quad |L^(-1)(k)| <= 1 quad "for every" k in K $

A statement has no role of its own: its roles are the edges it takes part in,
and it can take part in any number of them. The same statement can be the
premise of one connector and the conclusion of another, which is what lets
arguments nest.

Formally, a connector stands for an entailment relation: what goes into it
entails its conclusion. When a conclusion $C$ rests on two premises $A$ and
$B$ jointly, the fair reading is $A and B models C$: one entailment, "$C$
because $A$ and $B$", by lever $L$. It is not two entailments, $A models C$
and $B models C$, since neither premise does the work alone. The cardinality
above, exactly one premise, can't express this: two connectors would assert
the two separate entailments, which is a different claim. How joint premises
fit the graph is open.

#fig(60%)[
```mermaid
flowchart BT
  p1["premise"] -- P --> k1((k₁)) -- C --> c1["conclusion"]
  l1["lever"] -- L --> k1
  p2["premise"] -- P --> k2((k₂)) -- C --> p1
  classDef stmt fill:#e5e7eb,stroke:#374151
  classDef conn fill:#fde68a,stroke:#b45309
  class p1,c1,l1,p2 stmt
  class k1,k2 conn
```
]

This is the shape of the Argument Interchange Format (AIF; see @references): statements are its information nodes and
connectors its inference nodes. The PTA adds the lever as a third kind of
input.

The lever is usually implicit. A connector then has no lever statement, and
its lever is only the keyword chosen in step 5. A lever gets a statement node
when the text states it or argues about it; an attack on an inference is then
an attack on its lever statement.

An argument, the unit the pipeline types, is one connector read off the graph:
$a = (c, rho, "ctx")$ with $c$ the conclusion of $k$, $rho$ (rho, for
"reason") its premise and $"ctx"$ the surrounding text. $c$ and $rho$ are
spans of text.

=== Sources

- *Lab:* the graph is labelled in INCEpTION, the annotation tool, on two span
  layers. `Statement` spans are the statements. A `Connector` span is a
  connector, anchored on the coherence marker ("because", "so") where there
  is one; it has three link features, `conclusion`, `premise` and `lever
  statement`, each pointing at `Statement` spans. A statement that is implicit
  in the text is a zero-width span with its wording in `note`. INCEpTION can't
  enforce the cardinalities above, so the converter checks them.
- *Game:* $c$ and $rho$ come from an extra oracle over the player's line and the
  dialogue so far (@in-game).

== Pipeline

Throughout, subscript $c$ marks the conclusion and $rho$ the premise, and the
conclusion always comes first.

*Running example* (made up, like all examples here):

#quote[I'd say the minister did a great job, since she raised the university
budget.]

Probabilities in the examples are illustrative, not measured.

=== Step 1: elements

Split each statement into subject and predicate, and mark the surrounding
elements. *O1* finds these spans.

$ E(c) = (s_c, p_c), quad E(rho) = (s_rho, p_rho), quad M subset "ctx" $

$s$ is a subject and $p$ a predicate. Write $"Su"$ for the set of subject terms
and $"Pr"$ for the set of predicate terms, so $s_c, s_rho in "Su"$ and
$p_c, p_rho in "Pr"$. $M$ is the set of *surrounding elements*, which ATIP sorts
into four kinds of marker:
- *coherence*: marks which statement is premise and which conclusion ("because",
  "since", "so");
- *structure*: relates the argument to others ("in addition", "secondly");
- *illocutive*: the arguer's stance towards the claim ("I'd say", "I don't
  believe");
- *perlocutive*: the effect the arguer intends ("you should accept that").

Gold has no subject/predicate spans: the labeller writes the canonical
subjects and predicates, step 2's output, as text (@gold). So this is
automated even in the lab, and scored through step 2's fields. Rule baseline: dependency parse,#footnote[A parse that links each word to
the word it grammatically depends on and labels the link: `nsubj` is a nominal
subject, `nsubj:pass` the subject of a passive verb.] subject = the
`nsubj`/`nsubj:pass` subtree, predicate = the rest of the clause;
copulas#footnote[Linking verbs such as "is", "are", "seems".] kept with the
predicate.
Markers come from a lexicon of the four kinds.

Step 1 also records $q_rho$: the whole proposition the premise speaks of, if
any ("Eurostat said _that the economy grew_"). Step 3 uses it to detect delta
arguments. Rule baseline: the clausal complement of a reporting verb
("Eurostat said _that the economy grew_") or an anaphoric "so"/"that"/"this"
("Eurostat said _so_"), resolved to the clause it stands for. Otherwise
$q_rho$ is empty.

Example. The human-labelled ("gold") spans give the conclusion "the minister did a great job" and
the premise "she raised the university budget". Their parses, with
#text(fill: green.darken(30%))[*subject*] and
#text(fill: blue.darken(20%))[*predicate*] words coloured:

#fig(80%)[
```mermaid
flowchart TD
  did["did"] -- nsubj --> minister["minister"]
  minister -- det --> the1["the"]
  did -- obj --> job["job"]
  job -- det --> a1["a"]
  job -- amod --> great["great"]
  raised["raised"] -- nsubj --> she["she"]
  raised -- obj --> budget["budget"]
  budget -- det --> the2["the"]
  budget -- compound --> uni["university"]
  classDef subj fill:#bbf7d0,stroke:#15803d
  classDef pred fill:#dbeafe,stroke:#1d4ed8
  class minister,the1,she subj
  class did,job,a1,great,raised,budget,the2,uni pred
```
]

```yaml
conclusion: {s_c: "the minister", p_c: "did a great job"}
premise:    {s_ρ: "she",          p_ρ: "raised the university budget"}
markers:
  - {text: "I'd say", kind: illocutive}
  - {text: "since",   kind: coherence}
```

=== Step 2: canonical form

ATIP's step 2 rewrites the argument into the canonical sentence "conclusion
because premise". Its transformations include moving the conclusion first,
replacing the coherence marker by "because", dropping the other markers,
resolving anaphora (replacing "she" by "the minister"), making implicit
content explicit and switching between active and passive voice. Their purpose
is to make shared subjects and predicates _literally_ shared, because step 3
decides the form from what is shared.

Here the canonical form $kappa(a)$ is not a rewritten string. It is the tuple
from step 1 plus an equivalence relation $equiv$ on terms:

$ kappa(a) = ((s_c, p_c), (s_rho, p_rho), equiv) $

$t_1 equiv t_2$ means "$t_1$ and $t_2$ are the same subject or predicate after
anaphora resolution, passivization and paraphrase"; $equiv.not$ is its
negation. Oracle *O2* judges it. Making $equiv$ explicit means it doesn't
matter whether two terms happen to share their wording. The canonical
sentence in the output record is flattened from the tuple, using one
representative wording per equivalence class.

Example. O2 compares the subjects and the predicates pairwise:

#fig(75%)[
```mermaid
flowchart LR
  sc["s_c: the minister"] === eq{{"O2: ≡ same<br/>(coreference)"}} === sr["s_ρ: she"]
  pc["p_c: did a great job"] -.- ne{{"O2: ≢ different"}} -.- pr["p_ρ: raised the university budget"]
  classDef subj fill:#bbf7d0,stroke:#15803d
  classDef pred fill:#dbeafe,stroke:#1d4ed8
  classDef oracle fill:#fde68a,stroke:#b45309
  class sc,sr subj
  class pc,pr pred
  class eq,ne oracle
```
]

Flattening writes the same fields gold has (@gold): the four canonical terms,
and the transformations that changed a term's wording, each tagged with the
statement it applied to. Each appears once, in any order. Transposition, the
"because" substitution and omitted markers aren't listed: the conclusion and
premise roles and the markers already record them. An $equiv$ judgement
between two different wordings is tagged `same term`, so O2's decisions show
next to the rewrites. The canonical sentence "conclusion because premise"
and the lever written out are rendered from these fields, not stored.

```yaml
canonical:
  conclusion: {subject: "the minister", predicate: "did a great job"}
  premise:    {subject: "the minister", predicate: "raised the university budget"}
transformations: ["anaphora (premise)"]
```

*Delta reading.* Some arguments rest on who said something or what would
follow from it, not on its content: "the economy has grown, because Eurostat
said so". For these the PTA splits both statements differently: the subject is
the whole proposition. When $q_rho$ is non-empty, $kappa$ also produces this
second split:

$ kappa^delta (a) = ((c, zeta), (q_rho, Z)), quad zeta in AA = {A, U} $

In the conclusion, $c$ as a whole is the subject and its predicate $zeta$ is $A$
(_acceptable_) or $U$ (_unacceptable_); $AA$ is the set of the two. In the
premise, $q_rho$ is the subject and $Z$ is what the premise says of it ("was
said by Eurostat"). $zeta$ is usually implicit, so flattening writes it in
brackets, as ATIP does: "the economy has grown [is acceptable (A)] because that
was said by Eurostat". Step 3 decides which split is used.

Passivization works on the parse. In "the budget was raised by the minister",
the subject is `nsubj:pass` = "the budget"; when there is an agent
(`obl:agent` = "the minister"), the rule baseline also tries the active
reading (subject "the minister"), so a shared subject isn't missed.

=== Rewriting: making shared terms visible <rewriting>

$equiv$ can only judge terms that are already there. Some arguments share a
term only after a rewording that creates new text. Kant writes "I need not
think, if only I can pay: others will readily undertake the irksome work for
me". As written the subjects differ ("I", "others"), which would make it γ.
Reworded as "I will have others undertake the work for me", the premise shares
the subject "I", and the argument is α. No judgement of sameness between the
existing terms finds that: the shared term has to be produced.

ATIP's transformations therefore come in two kinds:

#table(
  columns: (auto, 1fr, auto),
  table.header([kind], [transformations], [handled by]),
  [selective], [moving the conclusion first; replacing or dropping markers; resolving anaphora; recognising that two existing terms mean the same], [rules, O1, O2],
  [generative], [making implicit content explicit; turning a rhetorical question into an assertion; switching voice beyond what the parse gives; nominalising ("being immature"); paraphrasing a term so it matches another], [*O9*, checked by *O10*],
)

Selective transformations only rearrange or compare what is in the text.
Generative ones write new wording, so they need a proposer and a check.

*O9: rewrite proposer.* Given the argument and its context, a generative model
proposes up to $n$ candidate canonical pairs $(c', rho')$. Each candidate
lists the transformations it used, from ATIP's list plus nominalisation, and
the source span each new phrase rewrites. O9 is not an oracle in the sense of
@oracles: its output is text, not a choice from a closed set. Its candidates
_become_ the closed set the rest of the pipeline chooses from.

*O10: rewrite check.* A candidate is valid if it says the same as the original
in context. For a rewording, an NLI model#footnote[Natural language inference:
given a text and a hypothesis, the model scores whether the text entails the
hypothesis.] checks entailment both ways; for explication, which adds content,
only that the original and the context entail the rewrite:

$ P("valid"(c')) = min("entail"(c, c'), "entail"(c', c)) $

*Preference.* ATIP switches voice "for highlighting a common subject or
predicate", which implies preferring the reading that shares a term. So among
valid candidates, γ is reported only when no candidate with
$P("valid") >= theta$ shares a subject or predicate. Otherwise each candidate
is one more branch of the composition (@composition), weighted by
$P("valid")$.

*Example.* The Kant sentence, with illustrative numbers:

#table(
  columns: (auto, 1fr, auto, auto, auto),
  table.header([candidate], [premise as reworded], [transformation], [$P("valid")$], [form]),
  [as written], [others will undertake the irksome work for me], [—], [1.00], [γ],
  [$c'_1$], [I will have others undertake the irksome work for me], [activization], [0.83], [α],
  [$c'_2$], [my thinking will be done by others], [passivization, nominalisation], [0.61], [γ],
)

$c'_1$ is valid and shares "I", so γ isn't reported; the code comes from the
α branch (here α PF Pra). Compare "it is so easy to be immature … I need not
exert myself", where the predicates "is easy" and "need not exert myself" may
already be the same: that is an $equiv$ judgement (O2), not a rewrite.

*Visibility.* Every candidate goes into the output record with its text,
transformations, source spans and $P("valid")$, and the chosen one is marked:

```yaml
rewrites:
  - premise: I will have others undertake the irksome work for me
    transformations: ["activization (premise)"]
    rewrites_span: "others will readily undertake the irksome work for me"
    p_valid: 0.83
    chosen: true
```

A reviewer can reject a rewrite and rerun from step 3. Gold records the
labeller's own rewording in the same fields (@gold), so the lab can measure
whether O9's candidates include it.

*Limits.* A generated rewrite can tidy an argument into one the author didn't
make. That is why O9 is restricted to ATIP's transformations, each tied to a
source span, and why its candidates are kept and scored rather than taken as
given. A generative model is also the most expensive part of the pipeline;
in-game use may need a smaller model or no generative step.

*Arms and cost.* Estimates for a laptop CPU, to be measured in the lab:

#table(
  columns: (auto, 1fr, auto),
  table.header([arm], [what it is], [per candidate]),
  [O9 rules], [voice switches from the parse, nominalisation from a morphology table], [~1 ms],
  [O9 seq2seq], [Flan-T5-small or -base (80–250M parameters), fine-tuned to rewrite a premise to share a term with its conclusion; ONNX, quantised], [~50–150 ms],
  [O9 LLM], [a 0.5–1.5B instruction-tuned model, 4-bit, via llama.cpp; the only arm that handles real paraphrase and explication], [~0.3–2 s],
  [O10], [DeBERTa-v3 NLI, xsmall to base, both directions], [~10–120 ms],
)

O9 is the bottleneck, so it runs only when needed:

+ Run steps 1–3 with O2 alone. If a subject or predicate is already shared,
  or the argument is δ, skip O9.
+ Otherwise propose candidates with the rule arm and check them with O10.
+ Only if none passes, call a generative arm.

Cost then grows with the number of γ-leaning arguments, not with document
length. Canonical forms are cached per statement, so a growing document or
dialogue only pays for its new arguments.

=== Step 3: form <form>

ATIP distinguishes four forms by what the conclusion and premise share. It
writes them with schematic letters: $a$ and $b$ are subjects, $X$ and $Y$
predicates ($X$ the conclusion's, $Y$ the premise's), $q$ a whole proposition
and $Z$ the premise's predicate in a delta argument. In our terms
$a = s_c$, $b = s_rho$, $X = p_c$, $Y = p_rho$.

#table(
  columns: (auto, auto, auto, auto),
  table.header([form], [ATIP schema], [shared], [test here]),
  [α alpha], [a is X because a is Y], [subject], [$s_c equiv s_rho$, $p_c equiv.not p_rho$],
  [β beta], [a is X because b is X], [predicate], [$p_c equiv p_rho$, $s_c equiv.not s_rho$],
  [γ gamma], [a is X because b is Y], [nothing], [$s_c equiv.not s_rho$, $p_c equiv.not p_rho$],
  [δ delta], [q is A/U because q is Z], [the whole proposition], [$c equiv q_rho$ (below)],
)

Delta covers the source-based arguments: appeals to an expert, to popularity,
threats, personal attacks. Delta is structural: it is the alpha pattern, a shared subject, where the
shared subject is a whole proposition and the conclusion's predicate is
acceptability. Under the delta reading of step 2:

$ delta quad "iff" quad q_rho != emptyset and c equiv q_rho and zeta in AA $

($emptyset$: step 1 found no such proposition.) Two judgements decide it:
*O5*, whether the premise really predicates
something of $q_rho$ as a whole, and with which $zeta$ (values $A$, $U$, none);
and *O2*, whether $q_rho$ is the conclusion. Delta is checked first because
its reading re-splits both statements; if it holds, the ordinary split isn't
used. The form function $f$ maps an argument to its form:

$
  f(a) = cases(
    delta & "if" O_5(a) in AA and c equiv q_rho,
    alpha & "if" s_c equiv s_rho and p_c equiv.not p_rho,
    beta & "if" p_c equiv p_rho and s_c equiv.not s_rho,
    gamma & "if" s_c equiv.not s_rho and p_c equiv.not p_rho,
    bot & "if" s_c equiv s_rho and p_c equiv p_rho,
  )
$

$bot$ (both shared) is a rephrase or begging the question; ATIP has no form
for it, so we flag it and stop. As a decision tree, with oracles as
#text(fill: orange.darken(20%))[*hexagons*] and each form in its own colour:

#fig(65%)[
```mermaid
flowchart TD
  start(["canonical a"]) --> d{{"O5: does the premise predicate<br/>something of a whole q_ρ (A/U)?"}}
  d -- none --> s{{"O2: s_c ≡ s_ρ ?"}}
  d -- "A / U" --> dq{{"O2: c ≡ q_ρ ?"}}
  dq -- yes --> D["δ"]
  dq -- no --> s
  s -- yes --> p1{{"O2: p_c ≡ p_ρ ?"}}
  s -- no --> p2{{"O2: p_c ≡ p_ρ ?"}}
  p1 -- no --> A["α"]
  p1 -- yes --> X["⊥ flag"]
  p2 -- yes --> B["β"]
  p2 -- no --> G["γ"]
  classDef oracle fill:#fde68a,stroke:#b45309
  classDef alpha fill:#bfdbfe,stroke:#1d4ed8
  classDef beta fill:#bbf7d0,stroke:#15803d
  classDef gamma fill:#e9d5ff,stroke:#7e22ce
  classDef delta fill:#fed7aa,stroke:#c2410c
  classDef bot fill:#e5e7eb,stroke:#4b5563
  class d,dq,s,p1,p2 oracle
  class A alpha
  class B beta
  class G gamma
  class D delta
  class X bot
```
]

The oracles return probabilities, so $equiv$ holds with some probability
rather than outright. Treating the sameness judgements as independent, each
leaf's probability is the product along its path. In the sketch, `O2(t1, t2)`
is $P(t_1 equiv t_2)$:

```python
def form(a):
    zeta = O5(a)              # distribution over {"A", "U", "none"}
    d  = (1 - zeta["none"]) * (O2(a.c, a.q_ρ) if a.q_ρ else 0)  # P(δ)
    ss = O2(a.s_c, a.s_ρ)     # P(subjects are the same)
    pp = O2(a.p_c, a.p_ρ)     # P(predicates are the same)
    return {
        "δ": d,
        "α": (1 - d) * ss       * (1 - pp),
        "β": (1 - d) * (1 - ss) * pp,
        "γ": (1 - d) * (1 - ss) * (1 - pp),
        "⊥": (1 - d) * ss       * pp,
    }
```

Examples, one per outcome:

#table(
  columns: (auto, auto, auto),
  table.header([argument], [shared], [form]),
  [the minister did a great job because _she_ raised the university budget],
  [subject (she ≡ the minister)], [α],
  [cycling on the lawn is prohibited because all activities on the lawn are prohibited],
  [predicate (is prohibited)], [β],
  [peace can be started by the truth because war can be started by lies],
  [nothing], [γ],
  [the economy has grown, because Eurostat said so],
  [the proposition: $q_rho$ = "so" = "the economy has grown" $equiv c$; $zeta = A$], [δ],
  [the minister did well because the minister did a good job],
  [both], [⊥],
)

Running example: $P(delta) = 0.03$, $P(s equiv) = 0.95$,
$P(p equiv) = 0.04$, so $P(alpha) approx 0.88$, $P(bot) approx 0.04$,
$P(gamma) approx 0.05$.

=== Step 4: substance <substance>

The values the substance can take depend on the form:

- *α*: the type of each predicate. *F* (fact): a claim checkable by
  observation or evidence, whether or not it is true. *V* (value): a
  judgement against some standard (aesthetic, moral, legal, …). *P* (policy):
  a recommendation to act, often with "should". Oracle *O3*.
- *β*: the quantity of each subject. *s* (singular): one individual. *p*
  (particular): some members of a group. *u* (universal): all of them. Oracle
  *O4*. (This $p$ is unrelated to the predicates $p_c$, $p_rho$.)
- *γ*: *i* (identical) if the subjects relate to each other as the predicates
  do, otherwise *d* (different). Oracle *O7*.
- *δ*: the perspective of the premise's source. *I*: first person, the arguer.
  *II*: second person, the addressee (threats, rewards, their commitments).
  *III*: third person (an expert, a witness, the public). Oracle *O6*.

For α and β the substance is a pair, written conclusion first: *VF* is a value
conclusion from a factual premise. The substance function $S$:

$
  S(a) = cases(
    (O_3(p_c), O_3(p_rho)) in {F, V, P}^2 & "if" alpha,
    (O_4(s_c), O_4(s_rho)) in {s, p, u}^2 & "if" beta,
    O_7(R_s, R_p) in {i, d} & "if" gamma,
    O_6(Z) in {"I", "II", "III"} & "if" delta,
  )
$

For gamma, $R_s$ is the relation between the subjects ($s_rho$ to $s_c$) and
$R_p$ the relation between the predicates ($p_rho$ to $p_c$); the substance is
$i$ iff $R_s = R_p$. O7 judges that comparison, so its input is the pair of
relations, not the whole argument. For delta, the perspective is read off the
premise's predicate $Z$ (who says, threatens, commits, …).

Rule baselines:

```python
def O3(p):  # predicate type: F / V / P
    if p.modal in {"should", "ought", "must"} or p.is_imperative:
        return "P"
    if p.head in EVALUATIVE or any(m in EVALUATIVE for m in p.modifiers):
        return "V"
    return "F"

def O4(s):  # subject quantity: s / p / u
    if s.det in {"all", "every", "each"} or s.is_generic_plural:
        return "u"
    if s.det in {"some", "a few", "many", "most"}:
        return "p"
    return "s"  # proper noun, "the X", pronoun, activity

def O6(Z):  # perspective of the source in Z: I / II / III
    match Z.source.person:
        case 1: return "I"
        case 2: return "II"
        case _: return "III"
```

Examples:

#table(
  columns: (auto, auto, auto, auto),
  table.header([form], [input], [oracle says], [substance]),
  [α], [`p_c` "did a great job" \ `p_ρ` "raised the university budget"],
  [V ("great" is evaluative) \ F], [*VF*],
  [β], [`s_c` "cycling on the lawn" \ `s_ρ` "all activities on the lawn"],
  [s \ u ("all")], [*su*],
  [γ], [$R_s$: war → peace \ $R_p$: lies → truth], [both are OPPOSITE, so $R_s = R_p$], [*i*],
  [δ], [$Z$ "was said by Eurostat"], [third person], [*III*],
)

*Condensed gamma.* A gamma argument with substance $d$ is usually an argument
with a missing middle step. ATIP says to try inserting it before concluding
that the premise is irrelevant, which is the type _non sequitur_ (`Non`). Build
the middle statement $m = (s_c, p_rho)$ ("a is Y"), then type $a_1 = (c, m)$ as
$alpha$ and $a_2 = (m, rho)$ as $beta$. Depth one; no further recursion. The
open problem is scoring whether the insertion makes the premise relevant
(@risks). The result is two output records, linked.

Example: "Socrates will die because all humans are mortal". Nothing is shared
(Socrates ≠ all humans, will die ≠ are mortal), so γ, and the two relations
aren't the same, so $O_7$ says d. Insert $m$ = "Socrates is mortal":

#fig(70%)[
```mermaid
flowchart TD
  g["Socrates will die<br/>because all humans are mortal<br/><b>γ d</b>"] --> m(["insert m = (s_c, p_ρ)<br/>Socrates is mortal"])
  m --> a1["a₁: Socrates will die<br/>because Socrates is mortal<br/><b>α FF</b> → step 5"]
  m --> a2["a₂: Socrates is mortal<br/>because all humans are mortal<br/><b>β su</b> → step 5 (G)"]
  classDef alpha fill:#bfdbfe,stroke:#1d4ed8
  classDef beta fill:#bbf7d0,stroke:#15803d
  classDef gamma fill:#e9d5ff,stroke:#7e22ce
  classDef op fill:#fde68a,stroke:#b45309
  class g gamma
  class a1 alpha
  class a2 beta
  class m op
```
]

=== Step 5: lever <lever>

The lever is the argument's third statement (@background), so step 5 chooses a
statement, not just a keyword. Write $F$ for the form and $t$ for the
substance. $K(F, t)$ is the set of keywords the PTA lists for that form and
substance (@types); for example $K(alpha, "VF") = {"CRITERION",
"DEFINITION", "SUBSUMED"}$. Each keyword $k$ names a relation, and the
candidate levers are its instances $ell_k$ on the argument's own terms:

$ L(F, t) = { ell_k : k in K(F, t) } $

The terms a lever relates are fixed by the form:

#table(
  columns: (auto, auto, auto),
  table.header([form], [$ell_k$], [relates]),
  [α], [$k(Y, X)$], [premise predicate, conclusion predicate: $("Pr", "Pr")$],
  [β], [$k(a, b)$ or $k(b, a)$], [the subjects: $("Su", "Su")$; the keyword fixes the order (a is ANALOGOUS to b; b is an EXAMPLE of a)],
  [γ], [$k(b, a) and k(Y, X)$], [one relation holding on both pairs],
  [δ], [$k(Z, zeta)$], [premise predicate, acceptability: $("Pr", AA)$],
)

The candidates are deductive. $K(F,t)$ is empty for α FV/VP/FP. The PTA is
open to new types, so a lever outside the table is reported as `novel` rather
than forced into a listed type.

1. *Cue override.* If the context states a keyword ("is a SIGN of", "is
   ANALOGOUS to") between the argument's own terms, return that keyword with
   probability 1.
2. *Otherwise oracle O8.* Write out each candidate lever statement $ell_k$ as a
   sentence, the hypothesis $h_k$ ("rising prices are a CAUSE of the strike"). Score
   each with an NLI model#footnote[Natural language inference: given a text and
   a hypothesis, the model scores whether the text entails the hypothesis (makes
   it follow), contradicts it, or neither.] as entailment of $h_k$ by the
   context. Normalise over $K(F, t) union {"none"}$ with a
   softmax;#footnote[softmax turns a list of scores into probabilities that sum
   to 1, keeping their order: $"softmax"(z)_k = e^(z_k) \/ sum_j e^(z_j)$.]
   `none` above a threshold gives `novel`.

$ l(a) = "softmax"_(k in K(F,t) union {"none"}) "entail"("ctx", h_k) $

```python
def lever(a, form, substance):
    K = LEVERS[form][substance]               # table lookup
    if not K:
        return {"novel": 1.0}
    for k in K:
        if cue(k).links(a.terms, a.ctx):      # e.g. "is a SIGN of"
            return {k: 1.0}
    h = {k: fill(TEMPLATE[k], a) for k in K}
    h["none"] = "none of these"
    return softmax({k: entail(a.ctx, h_k) for k, h_k in h.items()})
```

Running example, α VF. The candidates and their filled-in hypotheses
(Y = "raising the university budget", X = "doing a great job"):

#table(
  columns: (auto, auto, auto),
  table.header([$k$], [$h_k$], [$P$]),
  [CRITERION], [raising the university budget is a criterion for doing a great job], [0.62],
  [SUBSUMED], [raising the university budget can be subsumed under doing a great job], [0.21],
  [DEFINITION], [raising the university budget is the definition of doing a great job], [0.09],
  [none], [], [0.08],
)

With a cue instead: "raising the budget is the very _definition_ of a great
job" skips the model and returns DEFINITION with probability 1.

=== Step 6: name

$ n : (F, t, k) -> N union {"novel"} $

$N$ is the set of the PTA's 50 type names. $n$ is a pure lookup in @types,
which reproduces ATIP's Table 7. `γ d` has no keyword ($k$ is empty) and maps
to `Non`, which is a type, not a missing value. Within a form the keyword alone fixes the name, as
the PTA names types after the lever's KEYWORD; $t$ is kept as a consistency
check (a keyword outside $K(F,t)$ is an error upstream).

```python
NAMES[("α", "VF", "CRITERION")]  # "argument from criterion (Cr)" -> "α VF Cr"
NAMES[("β", "su", "GENUS")]      # "argument from genus (G)"      -> "β su G"
NAMES[("γ", "d",  None)]         # "non sequitur (Non)"           -> "γ d Non"
NAMES.get(("α", "FV", None))     # None                           -> "novel"
```

=== Composition <composition>

The tree is small: at most 4 forms × 9 substances × 10 levers. Enumerate every
path and multiply its oracle probabilities to get an exact distribution over
codes:

$ P("code") = sum_("paths" -> "code") product_i P(O_i = v_i) $

Here $v_i$ is the answer oracle $O_i$ gives on that path. The output record's
`code` is the most likely code, `alternatives` the runners-up,
and `confidence` the top probability. The product assumes the oracles are
independent; the lab checks whether the resulting confidences are
calibrated.#footnote[Confidence matches accuracy: of all the codes given
confidence 0.8, about 80% are right.] Paths whose probability falls below a
threshold are pruned (not explored further).

```python
def classify(a):
    dist = Counter()
    for F, pF in form(a).items():
        if F == "⊥":
            dist["⊥"] += pF
            continue
        for t, pt in substance(a, F).items():
            for k, pk in lever(a, F, t).items():
                p = pF * pt * pk
                if p >= PRUNE:
                    dist[code(F, t, k)] += p
    return dist
```

Running example as a tree. Probabilities multiply down each path; the winning
path is bold.

#fig(80%)[
```mermaid
flowchart LR
  a(["a"]) --> D["δ 0.03"]
  a --> X["⊥ 0.04<br/>flagged"]
  a --> G["γ 0.05"]
  a ==> A["α 0.88"]
  A --> FF["FF 0.10"]
  A ==> VF["VF 0.81"]
  VF ==> Cr["Cr 0.62<br/><b>α VF Cr ≈ 0.44</b>"]
  VF --> Su["Su 0.21<br/>α VF Su ≈ 0.15"]
  VF --> Def["Def 0.09<br/>α VF Def ≈ 0.06"]
  VF --> N["none 0.08<br/>novel ≈ 0.06"]
  classDef alpha fill:#bfdbfe,stroke:#1d4ed8
  classDef win fill:#1d4ed8,color:#ffffff,stroke:#1e3a8a
  classDef gamma fill:#e9d5ff,stroke:#7e22ce
  classDef delta fill:#fed7aa,stroke:#c2410c
  classDef bot fill:#e5e7eb,stroke:#4b5563
  class A,VF,FF,Su,Def,N alpha
  class Cr win
  class G gamma
  class D delta
  class X bot
```
]

Record: `code: α VF Cr`, `confidence: 0.44`,
`alternatives: [α VF Su, α VF Def]`. A confidence that low says the label
should be reviewed before it is trusted.

The lever and naming tables are data, not code: one file read by both the lab
(Python) and the game (Rust).

== Oracles <oracles>

Each oracle has a rule baseline and at least one model arm. Several of the
models are already in use in the reading-notes lab, a sibling project that
maps passages of text to concepts.

#table(
  columns: (auto, auto, auto, auto, auto),
  table.header([id], [question], [values], [rule baseline], [model arm]),
  [O1], [where are $c$, $rho$, the subjects, the predicates and the markers?], [spans],
  [dependency parse + marker lexicon], [GLiNER2#footnote[A small encoder that
  extracts spans and classifies text against labels given at run time.]
  extraction],
  [O2], [$t_1 equiv t_2$?], [yes/no],
  [lemma#footnote[A word's dictionary form: "argued" → "argue".] match after
  coreference#footnote[Working out which expressions refer to the same thing:
  "Kant … he".]],
  [embedding cosine#footnote[Turn each term into a vector and score the angle
  between them; near 1 means similar meaning.], cross-encoder#footnote[A model that reads both terms together and scores
  them as a pair; slower than embeddings, usually more accurate.]],
  [O3], [predicate type], [F/V/P], [modals and imperatives → P; evaluative lexicon → V; else F], [GLiNER2 classification / small classifier],
  [O4], [subject quantity], [s/p/u], [determiners and quantifiers from the parse; proper noun → s], [rarely needed],
  [O5], [does the premise predicate something of a whole proposition $q_rho$, accepting or rejecting it?], [A/U/none], [reporting verbs with a clausal or anaphoric object, "according to", conditionals on $q$], [GLiNER2 classification],
  [O6], [whose perspective is $Z$?], [I/II/III], [grammatical person of the source], [rarely needed],
  [O7], [is $R_s = R_p$?], [i/d], [—], [NLI],
  [O8], [which lever?], [$K(F,t) union {"none"}$], [cue words], [NLI over filled-in levers],
  [O9], [which rewordings could make a term shared?], [candidate pairs $(c', rho')$ (text)], [passive ↔ active from the parse], [generative model],
  [O10], [does a rewording say the same as the original?], [probability], [—], [NLI, both directions],
)

Reuse: the reading-notes lab already runs embedding models (usable for O2) and
GLiNER2 (O1, O3, O5). Two things are new:
- *An NLI arm* (O7, O8): small DeBERTa-v3 NLI models (xsmall to base) run on
  CPU and export to ONNX,#footnote[A portable model format, run by ONNX Runtime
  in the lab and `ort` in Rust.] so they fit that lab's latency harness.
- *A dependency parser* for the rule baselines (spaCy `en_core_web_sm` in the
  lab). Most of the deductive work runs on it.

== Gold labels and evaluation <gold>

The gold labels are features on each `Connector` (@graph). The classifier's
output record has the same fields, so every gold value can be compared with
what the pipeline produced:

#table(
  columns: (auto, auto),
  table.header([feature], [values]),
  [`conclusion subject` · `conclusion predicate` · `premise subject` · `premise predicate`], [the canonical terms as text: $a$, $X$, $b$, $Y$ in the lever templates (the premise repeats $a$ for α and $X$ for β); for δ, $q$, `[is acceptable]` or `[is unacceptable]`, $q$, $Z$],
  [`transformations`], [the wording changes, each `kind (statement)` from a closed tagset: anaphora, explication, illocution substitution, passivization, activization, nominalisation, same term; once each, unordered],
  [`form`], [`alpha` · `beta` · `gamma` · `delta`],
  [`substance`], [the substance codes, prefixed by their form (`α VF`, `β su`, `γ i`, `δ III`, …)],
  [`lever`], [the lever keyword (`CAUSE`, `GENUS`, …), `none` for γ d, or `novel` with the wording in `note`],
  [`concepts`], [what the argument is about: one or more tags, each a broad `concept` or a writer's own `concept/sense` (`being`, `being/scotus`, `being/heidegger-ontological`)],
)

Concept tags are references, not a theory of concepts: a tag names what an
argument is about at the level of a glossary entry, and a sense records a
writer's own version where the passage depends on it. Whether two writers share
a concept stays a labelling decision, made per passage. Tags are lowercase,
because INCEpTION may compare tag names case-insensitively. The tagset is
open, so tags are added while labelling; together they become the concept list
the models later choose from. Constraints can't relate a concept to its senses
in a multi-valued feature, so the shared prefix does that job: typing `being`
lists every `being/…` sense.

Substance tags carry their form because INCEpTION may compare tag names
case-insensitively, which would merge `pp` with `PP` and `i` with `I`.
INCEpTION _constraints_ show the substances valid for the chosen form, and the
levers valid for the chosen substance, first and in bold; they don't forbid
the others, so the converter rejects invalid combinations. The layers and
constraints are generated from the type table (@types) by
`scripts/pta_schema.py` in the lab.

The name is derived from the three, so it isn't stored. The features map
one-to-one onto pipeline stages (the canonical terms and transformations onto
steps 1–2, the rest onto steps 3–5), which allows *stage-wise evaluation*: run
the pipeline with gold values substituted for everything upstream of a stage,
and that stage's errors are its own. Canonical terms are compared by meaning,
not string: span overlap for terms taken from the text, entailment both ways
(as O10 checks rewrites) for reworded ones. Transformations are compared as
sets. End to end, measure code top-1/top-3#footnote[Whether the gold
code is the most likely code / among the three most likely.] and calibration.
Statistics: each arm is compared pairwise against one baseline, with
confidence intervals from resampling by passage.

A second human pass on a sample gives the ceiling: ATIP is hard for people
too, and no arm should be expected to beat human agreement.

*Pilot corpus.* The first corpus is one short argumentative excerpt from
each of about 30 writers across traditions (ancient, Buddhist, patristic and scholastic, early modern,
German idealist, phenomenological, analytic, critical, psychoanalytic, Kyoto
School, and speeches), plus the ten single-argument examples from the PTA
website, which test typing on their own. One writer's style shouldn't shape
the whole corpus. The pilot finds where the pipeline breaks; it is too small
to rank arms.

- *Split by writer.* Each writer in turn is the test set and the rest form
  the dev set, so every annotation is tested once and no example helps to
  classify its own writer.
- *What the dev set is for.* O9's generative arm takes 3–8 dev cases as
  in-context examples (original pair, the labeller's rewording, its
  transformations), chosen by similarity to the current argument. The other
  oracles are used zero-shot; the dev set sets their thresholds (O2, O10) and
  calibrates their confidences (O7, O8, GLiNER2). Rule baselines may be fixed
  against the dev set only.
- *Rewordings as gold.* The canonical terms and transformations hold the
  labeller's rewording; `note` holds only remarks. O9's examples and its
  evaluation read the rewording; the subject/predicate splits are gold for O1
  and O2.
- *First run.* The classifier runs on the gold connectors, stage-wise and end
  to end. Finding the connectors automatically (the document-analysis
  procedure) has no oracles yet and comes later.

Records quote the lab's source texts, which are excerpts of published books, so
they are never committed.

== In-game use (sketch) <in-game>

The player argues with a non-player character (NPC); this pipeline types the
player's arguments. The result is one input to *key extraction*: the game's
step that decides which of the game's keys an argument unlocks.

What changes from the lab:
- *No gold spans.* O1 must find the claim, the reason and which is which, from
  the player's line _and_ the dialogue: the conclusion is often the NPC's last
  claim, which the player supports or attacks.
- *Short, informal text.* The rule baselines will do worse than on books; the
  lab should keep a set of player-style notes to measure this separately.
- *Runtime.* Rust with `ort`, on a throttled CPU. Every model arm must export
  to ONNX, and the rule baselines must be small enough to port. The tables are
  already shared data (@composition).
- *Rewriting in-game.* O9's LLM arm is too slow and too large (~400 MB at
  0.5B, 4-bit) for a reply that should feel immediate. In-game O9 uses the
  rule and seq2seq arms, gated as in @rewriting, and may run after the
  player's line rather than before the reply. NPC arguments are analysed
  offline. The LLM arm stays in the lab, where its reviewed outputs can train
  the seq2seq arm.

What key extraction gets, per argument:
- the code distribution;
- the *bound terms*: which spans filled $a$, $b$, $X$, $Y$, $q$, each run
  through the reading-notes lab's interpreters, which map a span to a concept
  id.

With the bound terms, an argument becomes a structured claim about concepts:
"the player argued that concept Y is a CAUSE of concept X". That is the
natural thing for a key to gate on, e.g. a key that needs concept X introduced
_and_ argued for by a lever of some type. The quality step slots in between:
it reads the same record and can veto. How keys combine these is left open.

== Risks and open questions <risks>

- *Subject/predicate splits in philosophical prose.* Nominalisations and long
  clauses will break the parse baseline. Expected to be the largest source of
  O1 error.
- *Sameness is the pivot.* O2 decides form, and form decides every later
  candidate set. Errors there cascade; stage-wise evaluation will show how
  much.
- *Rewriting decides form.* Allowed rewordings are loose enough that one
  argument can come out α, β or γ (@rewriting). O9 and O10 make the choice
  explicit and reviewable, but their errors move arguments between forms; the
  lab should measure how often O9's candidates include the labeller's
  rewording.
- *Condensed gamma.* No good scorer for "the insertion makes the premise
  relevant" yet. First version: try it, report both readings, lower the
  confidence.
- *Explication in free text.* Players will leave the link implicit. The lever
  is always reconstructed anyway (O8), but a missing _premise_ isn't handled.
  Deferred until there is player-style data.
- *Independence assumption* in the composition. Checked by calibration; if it
  fails, recalibrate the composed score rather than modelling dependencies.
- *A parser in Rust.* The rule baselines assume a dependency parser. The game
  needs one that runs under `ort` or in pure Rust; not yet surveyed.
- *Training data.* No PTA 3.1 corpus exists that I know of; Visser et al. 2021
  uses the old 36-type labels and would need remapping. Fine-tuning stays
  deferred, as in the reading-notes lab.

== Suggested order

1. Tables as data; form, substance, lever and naming as pure functions over
   given oracle values; composition. Testable with hand-made values.
2. Gold features in INCEpTION; stage-wise evaluation with gold oracles.
3. Rule baselines (parser, lexicons).
4. Model arms: embeddings (O2), GLiNER2 (O1, O3, O5), NLI (O7, O8).
5. Player-style data and in-game O1.

== References <references>

- Wagemans, J.H.M. (2026). _Argument Type Identification Procedure (ATIP) –
  Version 6._ #link("https://www.periodic-table-of-arguments.org/argument-type-identification-procedure")
- Wagemans, J.H.M. _Periodic Table of Arguments, version 3.1_, with worked
  examples of every type. #link("https://www.periodic-table-of-arguments.org/pta-3-1-clickable")
- Hinton, M., Wagemans, J.H.M. (2023). "How persuasive is AI-generated
  argumentation? An analysis of the quality of an argumentative text produced
  by the GPT-3 AI text generator." _Argument & Computation_ 14(1), 59–74.
  #link("https://doi.org/10.3233/AAC-210026") Local copy in `.docs/reference/`.
- Hinton, M., Wagemans, J.H.M. (2022). "Evaluating reasoning in natural
  arguments: A procedural approach." _Argumentation_ 36, 61–84. The
  type-specific lever questions.
- Visser, J., Lawrence, J., Reed, C., Wagemans, J., Walton, D. (2021).
  "Annotating Argument Schemes." _Argumentation_ 35, 101–139.
- Chesñevar, C., McGinnis, J., Modgil, S., Rahwan, I., Reed, C., Simari, G.,
  South, M., Vreeswijk, G., Willmott, S. (2006). "Towards an Argument
  Interchange Format." _Knowledge Engineering Review_ 21(4), 293–316.

== Appendix: the 50 PTA 3.1 types <types>

From ATIP's Table 7. The lever column is the lever statement's pattern, with
the keyword in capitals. For β, the substance is any one of those listed.

#table(
  columns: (auto, auto, auto, auto, auto),
  table.header([form], [substance], [lever], [name], [symbol]),
  [α], [FF], [Y is a SIGN of X], [argument from sign], [Sig],
  [α], [FF], [Y is a CAUSE of X], [argument from cause], [Cau],
  [α], [FF], [Y is an EFFECT of X], [argument from effect], [Ef],
  [α], [FF], [Y is CORRELATED with X], [argument from correlation], [Cor],
  [α], [FF], [Y is a MOTIVE for X], [argument from motive], [Mot],
  [α], [FF], [Y EXCLUDES X], [argument from incompatibility], [Inc],
  [α], [VF], [Y is a CRITERION for X], [argument from criterion], [Cr],
  [α], [VF], [Y is the DEFINITION of X], [argument from definition], [Def],
  [α], [VF], [Y can be SUBSUMED under X], [argument from subsumption], [Su],
  [α], [VV], [Y is a NORM for X], [argument from norm], [Nor],
  [α], [VV], [Y is an INSTANTIATION of X], [argument from instantiation], [Ins],
  [α], [VV], [Y is a DISQUALIFIER of X], [argument from disqualifier], [Dis],
  [α], [PF], [Y is a PRAGMATIC MOTIVATION for X], [pragmatic argument], [Pra],
  [α], [PF], [Y is a PRIOR INVESTMENT in X], [argument from waste], [W],
  [α], [PF], [Y is the FEASIBILITY of X], [argument from possibility], [Pos],
  [α], [PV], [Y is a PRINCIPLED MOTIVATION for X], [argument from principle], [Pri],
  [α], [PV], [Y is an EVALUATIVE MOTIVATION for X], [argument from evaluation], [Ev],
  [α], [PP], [Y is a DEONTIC MOTIVATION for X], [deontic argument], [Deo],
  [α], [PP], [Y is a TELEOLOGIC MOTIVATION for X], [teleologic argument], [Tel],
  [β], [ss, pp, uu], [a is ANALOGOUS to b], [argument from analogy], [A],
  [β], [ss, pp, uu], [a is SIMILAR to b], [argument from similarity], [Sim],
  [β], [ss, pp, uu], [a is COMPARABLE to b], [argument from comparison], [Cpa],
  [β], [ss, pp, uu], [a is EQUAL to b], [argument from equality], [Eq],
  [β], [ss, pp, uu], [a is described METAPHORICALLY as b], [metaphoric argument], [Me],
  [β], [ss, pp, uu], [a is COMPOSED of b], [argument from composition], [Cpo],
  [β], [ss, pp, uu], [a is a PART of b], [argument from division], [Div],
  [β], [ss, pp, uu], [a RANKS BELOW b], [_argumentum a maiore_], [Ma],
  [β], [ss, pp, uu], [a RANKS ABOVE b], [_argumentum a minore_], [Mi],
  [β], [ss, pp, uu], [a OWES RECIPROCITY to b], [argument from reciprocity], [R],
  [β], [ps, us, up], [b is an EXAMPLE of a], [argument from example], [Exa],
  [β], [ps, us, up], [b is a SPECIES of a], [argument from species], [Sp],
  [β], [sp, su, pu], [a belongs to the TOTALITY of b], [argument from totality], [To],
  [β], [sp, su, pu], [a belongs to the GENUS of b], [argument from genus], [G],
  [γ], [i], [b is SYNONYMOUS to a and Y is SYNONYMOUS to X], [argument from synonyms], [Sy],
  [γ], [i], [b is the OPPOSITE of a and Y is the OPPOSITE of X], [argument from opposites], [Op],
  [γ], [i], [b is DERIVATIVE of a and Y is DERIVATIVE of X], [argument from derivatives], [Der],
  [γ], [i], [b is INTEGRATIVE of a and Y is INTEGRATIVE of X], [argument from integratives], [Int],
  [γ], [i], [b is the CONVERSE of a and Y is the CONVERSE of X], [argument from converses], [Cve],
  [γ], [d], [—], [non sequitur], [Non],
  [δ], [I], [Z is ETHOTICALLY AUTHORITATIVE for A], [ethotic argument], [Eth],
  [δ], [II], [Z is CHARACTERALLY AUTHORITATIVE for U], [_argumentum ad hominem_], [H],
  [δ], [II], [Z is a NEGATIVE MOTIVATION for A], [_argumentum ad baculum_], [B],
  [δ], [II], [Z is an OFFERED REWARD for A], [_argumentum ad carotam_], [Car],
  [δ], [II], [Z COMMITS the addressee to A], [argument from concession], [Cce],
  [δ], [II], [Z is an UNDESIRABLE IMPLICATION supporting U], [_argumentum ad consequentiam_], [Cse],
  [δ], [III], [Z is EPISTEMICALLY AUTHORITATIVE for A], [argument from expert opinion], [Exp],
  [δ], [III], [Z is MORALLY AUTHORITATIVE for A], [argument from moral authority], [Mor],
  [δ], [III], [Z is TESTIMONIALLY AUTHORITATIVE for A], [argument from testimony], [Tes],
  [δ], [III], [Z is POPULARLY AUTHORITATIVE for A], [_argumentum ad populum_], [Pop],
  [δ], [III], [Z is a PRESUMPTION in favor of A], [_argumentum ad ignorantiam_], [Ig],
)
