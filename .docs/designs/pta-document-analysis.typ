#set heading(numbering: "1.")
#set page(numbering: "1")
#set text(size: 11pt)
#import "@preview/merman:0.3.0": show-mermaid-blocks

#show raw.where(block: true): set block(breakable: false)
#show raw.where(lang: "mermaid"): show-mermaid-blocks(typography: (font: ("Libertinus Serif",), size: "13px"), width: 100%)
#show raw.where(lang: "python"): it => block(fill: luma(246), inset: 8pt, radius: 3pt, width: 100%, it)
#show raw.where(lang: "yaml"): it => block(fill: luma(246), inset: 8pt, radius: 3pt, width: 100%, it)

#let fig(width, body) = align(center, block(width: width, body))

= Document argument analysis: finding and connecting arguments

The six-step ATIP classifier types one argument at a time. A real text
contains many arguments that share statements and support each other. This
note describes how to find those arguments in a document, record them as one
graph, and hand each one to the classifier. The procedure is ours, not part
of the published ATIP.

== Background <background>

The _Periodic Table of Arguments_ (PTA) treats an argument as three
statements: a *conclusion*, a *premise*, and a *lever* that says how the
premise supports the conclusion (usually left unstated). The PTA's framework
is _recursive_: any of the three can itself be argued for, and then becomes
the conclusion of a further argument (Wagemans, PTA website; @references).

We record a text as a graph with two kinds of node: *statements* $S$ and
*connectors* $K$, one connector per argument. Three role relations link them:

$ C, P, L subset.eq S times K $

$(s, k) in C$ reads "$s$ is the conclusion of $k$"; $P$ is premise and $L$
lever. Each connector has exactly one conclusion and one premise, and at most
one lever statement:

$ |C^(-1)(k)| = |P^(-1)(k)| = 1, quad |L^(-1)(k)| <= 1 $

A statement has no role of its own. Its roles are the links it takes part in,
so one statement can be the premise of one connector and the conclusion or
lever of another. That is how the PTA's recursion shows up in the graph. A
lever only gets a statement node when the text states it or argues about it;
otherwise the classifier records it as a keyword.

In diagrams, statements are gray boxes and connectors are white circles;
arrows run from premise and lever into the connector and from the connector
to its conclusion:

#fig(80%)[
```mermaid
flowchart LR
  s5["S5 · the parts move toward<br/>the universe's center"] -- P --> t4((T4))
  s7["S7 · what holds for the parts<br/>holds for the whole"] -- L --> t4
  t4 -- C --> s8["S8 · the whole earth moves<br/>toward the universe's center"]
  classDef stmt fill:#e5e7eb,stroke:#374151
  classDef conn fill:#ffffff,stroke:#b45309
  class s5,s7,s8 stmt
  class t4 conn
```
]

The structure matches the Argument Interchange Format (AIF): statements are
its information nodes and connectors its inference nodes, with the lever as
an extra input (Chesñevar et al. 2006).

== Running example <example>

An Aristotelian argument about the earth's natural motion, as presented by
Galileo (Finocchiaro's translation; see @references):

#quote(block: true)[
  Who is so blind as not to see that the parts of the element earth and of the
  element water, being heavy bodies, move naturally downwards, namely toward the
  center of the universe, assigned by nature herself as the goal and end of
  straight downward motion… Since this can be seen clearly, and since we are
  sure that the same holds for the whole as for the parts, must we not conclude
  that the natural motion of the \[whole globe\] earth is straight toward the
  center…?
]

We read it as Aristotle intends: "downwards" means toward the center of the
_universe_, and the passage argues that the whole earth moves there. (Galileo's
critique reads "the center" as the earth's own center, which makes the
conclusion incoherent.) This main reading is called *R-expanded*: it has five
arguments, T1–T5. Other readings are recorded as changes to it (@readings).

== Output <output>

The procedure produces one YAML file per document with four parts:

- `statements`: each statement's canonical text, its source span, and
  whether it was `reconstructed` (implicit in the text).
- `candidates`: every place in the text that might signal an argument, with
  its *disposition*: what we decided it is.
- `connectors`: the arguments, as references to statements.
- `readings`: the main reading and each alternative, as a list of changes.

A disposition is one of:

#table(
  columns: (auto, 1fr),
  table.header([disposition], [meaning]),
  [`connector`], [It signals an argument; names the connector.],
  [`lever`], [It introduces a stated lever of another connector.],
  [`rephrase`], [It restates something; no argument.],
  [`conflict`], [It attacks a statement ("but", "however"); say which in `note`. The attack's reason is an ordinary connector.],
  [`background`], [Explanation or context; no argument.],
  [`rhetorical`], [Framing only (a rhetorical question, emphasis); its content is kept, the framing dropped.],
  [`unresolved`], [Undecided; say why in `note`.],
)

The example's file, with spans shortened:

```yaml
statements:
  S1:
    text: "The parts of earth and water are heavy bodies."
    span: "being heavy bodies"
  S2:
    text: "Heavy bodies move naturally downwards."
    reconstructed: true
  S3:
    text: "The parts of earth and water move naturally downwards."
    span: "the parts … move naturally downwards"
  S4:
    text: "Downward motion is motion toward the universe's center."
    span: "downwards, namely toward the center of the universe"
  S5:
    text: "The parts of earth and water move naturally toward the universe's center."
    span: "the parts … toward the center of the universe"
  S6:
    text: "S5 can be seen clearly."
    span: "this can be seen clearly"
  S7:
    text: "What holds for the parts holds for the whole."
    span: "the same holds for the whole as for the parts"
  S8:
    text: "The whole earth moves naturally toward the universe's center."
    span: "the natural motion of the … earth is straight toward the center"
  S9:
    text: "Nature assigned the universe's center as the goal of downward motion."
    span: "assigned by nature herself as the goal …"

candidates:
  - {cue: "Who is so blind as not to see", disposition: rhetorical}
  - {cue: "being", disposition: connector, connector: T1}
  - {cue: "namely", disposition: connector, connector: T2}
  - {cue: "assigned by", disposition: connector, connector: T5}
  - {cue: "Since (1st)", disposition: connector, connector: T3}
  - {cue: "since (2nd)", disposition: lever, connector: T4, statement: S7}
  - {cue: "we are sure that", disposition: rhetorical}
  - {cue: "must we not conclude", disposition: connector, connector: T4}

connectors:
  T1: {conclusion: S3, premise: S2, lever_statement: S1}
  T2: {conclusion: S5, premise: S3, lever_statement: S4}
  T3: {conclusion: S5, premise: S6}
  T4: {conclusion: S8, premise: S5, lever_statement: S7}
  T5: {conclusion: S4, premise: S9}

readings:
  R-expanded: {}
  R-causal:
    note: "Heaviness itself is the reason; no general premise."
    replace: {T1: {conclusion: S3, premise: S1}}
    drop: [S2]
  R-rephrase:
    note: "'namely' only clarifies 'downwards'."
    merge: {S5: S3}
    drop: [T2, S4, T5, S9]
```

`lever_statement` is the optional lever node; the lever _keyword_ is the
classifier's output, stored separately. In INCEpTION, statements are
`Statement` spans and connectors are `Connector` spans with `conclusion`,
`premise` and `lever statement` links.

== Principles <principles>

1. *Read the author's argument.* Use the author's meaning and terms, not a
   critic's, and don't strengthen the argument while reconstructing it.
2. *Find before you simplify.* List the claims and transitions before
   canonicalizing. Merging two descriptions too early can hide an argument.
3. *Look for the lever.* For each reason, ask what makes it relevant. A
   stated membership or likeness claim ("Socrates is a man", "robots are just
   like us") is a lever before it is a premise; the generalization it applies
   is the premise. See D3.
4. *Reuse statements.* One statement, one node, however many roles it plays.
5. *Add as little as possible.* Add an implicit statement only when an
   argument can't be stated without it, and mark it `reconstructed`.
6. *Keep readings apart.* Competing reconstructions are separate readings,
   not extra arguments in one graph.

== Procedure <procedure>

Five steps. Three are interpretive judgements; two are mechanical. A failed
check in D5 sends you back to D2 for the affected part of the text.

#table(
  columns: (auto, auto, 1fr, auto),
  table.header([step], [kind], [does], [produces]),
  [D1], [judgement], [list the statements], [`statements`],
  [D2], [judgement], [find the cues that might signal arguments, and decide what each is], [`candidates`],
  [D3], [mechanical], [build a connector for each argument and link its statements], [`connectors`],
  [D4], [judgement], [record alternative reconstructions], [`readings`],
  [D5], [mechanical], [check each reading], [a graph per reading],
)

=== D1: statements <d1>

*Produces:* `statements`.

Go through the text and list every claim that could be a conclusion, premise
or lever. Resolve pronouns and "this"/"so" where the reference is clear;
record it in `note` where it isn't. Spans may overlap: a clause can contain a
claim about another claim. Same wording doesn't make two statements the same,
and different wording doesn't make them different.

*Example.* Nine statements (the YAML above). Three decisions matter:

- *S3 and S5 are separate*, though their spans overlap: "move downwards" and
  "move toward the universe's center" are the two descriptions "namely" links.
- *S2 is reconstructed*: it is the general premise "being heavy bodies"
  needs.
- *"we are sure that" is dropped* from S7: it is the arguer's stance, not part
  of the claim.

=== D2: candidates <d2>

*Produces:* `candidates`.

List every construction that might signal an argument, and give each a
disposition. One sentence can hold several arguments, and one cue can signal
none, so counting cues doesn't count arguments.

#table(
  columns: (auto, 1fr, 1fr),
  table.header([cue], [may signal], [check]),
  [because, since, therefore, so], [a premise and a conclusion], [Which claim is it for? Is it reasoning or just sequence?],
  [being, given, relative clauses], [a compressed premise or lever], [Is it offered as a reason, or only describes?],
  [namely, that is, by definition], [a rephrase, or an identification the author is establishing], [Would merging the two terms lose something?],
  [generalizations, conditionals], [a lever], [Does it link two claims, or is it background?],
  [clearly, can be seen, according to], [a reason to accept a claim (δ)], [Is it a reason, or emphasis?],
  [rhetorical questions], [an assertion or a challenge], [What is actually being asserted?],
)

For each candidate, ask: what is the reader asked to accept; what is offered
as a reason; what makes the reason relevant; is any of these argued for
elsewhere?

*Is it a coherence marker?* ATIP defines one by function only: it indicates
which statement is the conclusion and which the premise, and it is not part
of the propositional content (ATIP v6, Step 1). Step 2 replaces it with
"because"; structure, illocutive and perlocutive markers are dropped. These
three tests are ours; they reproduce ATIP's examples ("so", "if", and "many
people have said" as a predicate, not a marker). An expression is a coherence
marker if it passes all three:

+ *Substitution.* Replace it with "because" (transposing if needed). Both
  sides must still be complete statements, and nothing claimed may be lost.
  "Since", "so", "shows that", "proves that" pass; "many people have said q"
  fails, since "q because many people" has no premise left.
+ *Whose attitude.* If it reports an attitude to q, it is not a coherence
  marker. The arguer's own attitude is an illocutive or perlocutive marker
  ("unmistakably", "I argue that"): dropped, or A/U in δ. Anyone else's
  attitude ("according to The Economist", "we read there that") is content,
  part of a premise; it is δ only when the conclusion is the attributed
  proposition itself.
+ *What denying it means.* If denying it means denying that the premise
  supports the conclusion, it is a coherence marker: that is what "because"
  asserts. If it means denying a fact (did The Economist say so?), it is
  content.

A connector is anchored on its coherence marker. Where an illocutive marker
sits next to it ("we might be led to conjecture that"), either anchor gives
the same graph.

*Example.* Eight candidates (the YAML above). Five become connectors. The
second "since" introduces S7, the stated lever of T4, not a sixth argument.
The rhetorical questions are kept as the assertions S3/S5 and S8.

=== D3: connectors <d3>

*Produces:* `connectors`.

Create one connector per `connector` candidate and link its conclusion,
premise and (if stated) lever statement. Then check every statement in the
new connectors against the rest of the graph: is it argued for, or used,
anywhere else? Add connectors only where the text supports them.

*Premise or lever.* When two statements jointly support a conclusion, decide
which is the premise without looking at the type table:

+ If the text marks one as the reason ("because", "since", a participle such
  as "being heavy bodies"), it is the premise.
+ Otherwise, the generalization is the premise and the membership or likeness
  claim is the lever statement. "Socrates is mortal": premise "all men are
  mortal", lever "Socrates is a man" (β su G), not the reverse (α FF, no
  lever in the table).

The other split is mechanical (swap premise and lever), so the classifier
reports its type as a runner-up; the labeller doesn't weigh both. A connector
typed `novel` is a sign the split is wrong: try the swap before keeping it.

*Example.* The result for R-expanded:

#fig(78%)[
```mermaid
flowchart BT
  s2["S2 · heavy bodies<br/>move downwards<br/>(implicit)"] -- P --> t1((T1))
  s1["S1 · the parts are<br/>heavy bodies"] -- L --> t1
  t1 -- C --> s3["S3 · the parts<br/>move downwards"]
  s3 -- P --> t2((T2))
  s4["S4 · downward motion is<br/>toward the universe's center"] -- L --> t2
  t2 -- C --> s5["S5 · the parts move toward<br/>the universe's center"]
  s9["S9 · nature assigned<br/>that goal"] -- P --> t5((T5))
  t5 -- C --> s4
  s6["S6 · this can be<br/>seen clearly"] -- P --> t3((T3))
  t3 -- C --> s5
  s5 -- P --> t4((T4))
  s7["S7 · what holds for the parts<br/>holds for the whole"] -- L --> t4
  t4 -- C --> s8["S8 · the whole earth moves<br/>toward the universe's center"]
  classDef stmt fill:#e5e7eb,stroke:#374151
  classDef conn fill:#ffffff,stroke:#b45309
  class s1,s2,s3,s4,s5,s6,s7,s8,s9 stmt
  class t1,t2,t3,t4,t5 conn
```
]

T1 → T2 → T4 is a chain: each conclusion is the next premise. T3 is a second
argument for S5. T5 argues for S4, which is T2's lever: the lever recursion
the PTA describes.

=== D4: readings <readings>

*Produces:* `readings`.

Where the text supports more than one reconstruction, keep the main reading
and record each alternative as a change to it: connectors replaced or
dropped, statements merged or dropped. Don't add an alternative's links to the
main graph.

*Example.* "Being heavy bodies" has two readings:

*R-expanded (genus):* the general premise S2 supports S3; class
membership S1 is the lever.
#fig(60%)[
```mermaid
flowchart LR
  s2["S2 · heavy bodies<br/>move downwards"] -- P --> t1((T1))
  s1["S1 · the parts are<br/>heavy bodies"] -- L --> t1
  t1 -- C --> s3["S3 · the parts<br/>move downwards"]
  classDef stmt fill:#e5e7eb,stroke:#374151
  classDef conn fill:#ffffff,stroke:#b45309
  class s1,s2,s3 stmt
  class t1 conn
```
]

*R-causal:* heaviness S1 is itself the reason; S2 isn't needed.
#fig(55%)[
```mermaid
flowchart LR
  s1["S1 · the parts are<br/>heavy bodies"] -- P --> t1((T1))
  t1 -- C --> s3["S3 · the parts<br/>move downwards"]
  classDef stmt fill:#e5e7eb,stroke:#374151
  classDef conn fill:#ffffff,stroke:#b45309
  class s1,s3 stmt
  class t1 conn
```
]

Other open decisions:

#table(
  columns: (auto, 1fr, 1fr),
  table.header([decision], [alternative], [change]),
  ["namely"], [It only clarifies "downwards".], [R-rephrase: merge S5 into S3; drop T2, and with it S4, T5 and S9.],
  [visibility], ["This" refers to the downward motion only.], [T3's conclusion becomes S3.],
  [nature], [The assigned goal explains the motion instead of supporting S4.], [T5's conclusion changes, or T5 is dropped.],
)

An alternative that only changes a connector's _type_ (say, T5 as δ III Exp
or α FF Cau) is a classification question, not a new reading.

=== D5: validate <d5>

*Produces:* a checked graph per reading.

Check, for each reading:

- every connector has one conclusion and one premise, and at most one lever
  statement;
- every reference points at an existing statement, and every
  `reconstructed` statement is used;
- every candidate has a disposition;
- no two connectors are the same argument;
- premises that only work jointly are noted: the schema has one premise per
  connector, so it can't show joint support. A connector stands for an
  entailment, and joint premises entail their conclusion together, not
  each on its own; see the argument graph in the ATIP design.

A failed check sends you back to D2 for the affected part of the text, not
the whole document.

*Example.* R-expanded has 9 statements, 5 connectors and 13 links, all
connected. In R-causal, nothing still uses S2; in R-rephrase, nothing still
uses S4.

== Traversal <traversal>

Graph questions (what supports this claim, what uses it, which arguments are
connected) follow links in both directions and in every role. With
$E = C union P union L$, the neighbours of a statement and of a connector are

$ N(s) = { k : (s, k) in E }, quad N(k) = { s : (s, k) in E } $

and the connected parts of the document are found by a plain graph walk:

```python
def components(graph):
    seen = set()
    for root in graph.nodes():
        if root in seen:
            continue
        pending, component = [root], []
        while pending:
            node = pending.pop()
            if node in seen:
                continue
            seen.add(node)
            component.append(node)
            pending.extend(graph.neighbours(node))
        yield component
```

This is connectivity, not the PTA's recursion: being connected doesn't mean
one argument supports another. Walk each reading separately; mixing readings
builds a graph nobody proposed.

*Example.* From any node, R-expanded's walk reaches all 14 nodes: one
component.

== Handoff to classification <handoff>

Each connector, in each reading, is one input to the ATIP classifier:
$a = (c, rho, "ctx")$ with $c$ its conclusion, $rho$ its premise, and the
document as context, plus the lever statement if there is one. Classify each
connector once per reading; a statement shared by several connectors is not
typed itself.

*Example.* T1 in R-expanded is (S3, S2) with lever S1; T1 in R-causal is
(S3, S1), a different input with a different likely type (β pu G vs. α FF
Cau).

Store each result against its reading and connector. A type's confidence is
conditional on the reconstruction, so keep it separate from confidence in the
reconstruction itself, and don't multiply type probabilities along the graph.
If classification shows a reconstruction problem (a bad split, a missed
middle step), go back to D4; don't change the graph just to get a listed type.
`novel` is a valid result.

== Stopping

Discovery stops when every candidate has a disposition and D5 passes.
Missing support in the text is recorded as such ("no argument found"), not
filled in. A reference to text outside the excerpt is `unresolved`.

== Evaluation

Measure three things separately: finding arguments (candidates and their
dispositions), reconstructing them (statement identity, roles, readings), and
classifying them. A wrong role is a different error from a wrong type. Where
the text supports several readings, gold labels should include them; a
reading isn't better for having more arguments.

The judgements in D1, D2 and D4 are new semantic tasks, outside the
classifier's oracles, and need their own baselines. Validation and traversal
are mechanical.

== References <references>

- Wagemans, J.H.M. (2026). _Argument Type Identification Procedure (ATIP) –
  Version 6._ #link("https://www.periodic-table-of-arguments.org/argument-type-identification-procedure")
- Wagemans, J.H.M. _Periodic Table of Arguments_: theoretical framework.
  #link("https://periodic-table-of-arguments.org/theoretical-framework/")
- Chesñevar, C., McGinnis, J., Modgil, S., Rahwan, I., Reed, C., Simari, G.,
  South, M., Vreeswijk, G., Willmott, S. (2006). "Towards an Argument
  Interchange Format." _Knowledge Engineering Review_ 21(4), 293–316.
  #link("https://doi.org/10.1017/S0269888906001044")
- Galileo Galilei. _Galileo on the World Systems: A New Abridged Translation
  and Guide_, trans. and ed. M.A. Finocchiaro. University of California Press,
  1997, pp. 83–84. Source of the running example.
- Hinton, M., Wagemans, J.H.M. (2023). "How persuasive is AI-generated
  argumentation?" _Argument & Computation_ 14(1), 59–74.
  #link("https://doi.org/10.3233/AAC-210026") Picks arguments out of a text
  by "a preliminary reading"; this procedure makes that step explicit.
- `pta-atip-algorithm.typ`: the six-step classifier this procedure feeds.
