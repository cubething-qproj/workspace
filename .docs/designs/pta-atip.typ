#set heading(numbering: "1.")

= Ontology <ontology>

Let's begin by defining our ontology. A basic understanding of the
terms used in the PTA-ATIP framework is assumed. We leave the exact semantics of
the predicate/subject division open for interpretation. Different
implementations of the ATIP may divide the same sentence differently. It remains
to be seen if using e.g. phrase structure grammar or dependency grammar will
result in different classifications.

Premises, conclusions, and

#table(
  columns: (auto, auto),
  table.header([set], [description]),
  $ N $, [The set of all names (alias argument types, symbols) as defined by the PTA.],
  $ Sigma $, [The class of all sentences.],
  $ PP ; rho = (s,p) in PP $, [The class of all premises.],
  $ CC ; c = (s,p) in "C" $, [The class of all conclusions.],
  $ "Pc" supset (PP, CC) $, [The class of all propositional content.],
  $ P ; p in P = [c_i : c_i in "Pc"] $, [The class of all complete propositions.],
  
  $ "Pr" ; p in "Pr" $, [The class of all predicates.],
  $ "Su" ; s in "Su" $, [The class of all subjects.],
  $ R_(( tau_1,...,tau_n )) ; R(t_1,...,t_n) in R_(( tau_1,...,tau_n )) $,
  [The class of all n-ary relations, where $n in NN$ and $d$ denotes the types of each argument.],
  
  $ FF := {alpha, beta, gamma, delta} $, [The set of all _forms._],
  $ SS := {S_alpha, ..., S_delta} $, [The set of all _substances._],
  $ LL := {L_alpha, ..., L_delta} $, [The set of all _levers._],
  $ "Sr" := {M_"ac", M_"as", M_i, M_p} $,
  [The set of all types of 'surrounding elements,' to be stripped from the
    sentence during canonicalization. The subscripts of each subset refer to the 4
    kinds of surrounding elements: argumentative coherence markers, argumentative
    structure markers, illocutive markers, and perlocutive markers. This is
    basically a bucket for "everything else," though these markers play a role in
    the final naming procedure.],
  
  $ AA = {A,U} $, [Acceptability relations of a premise.],
)

= The procedure

This consists of transformations over the various domains listed in @ontology.

== Part I. Standardization

This part requires a lot of NLP translation. It is a form of transformative analysis.

Let's denote our original sentence as $sigma$.

=== Step 1 - Parsing

Step 1 is to identify the subject-predicate form of the $sigma$. This is done
through the semantics of the chosen syntax grammar. Consider this a function

$ g(sigma): Sigma -> "AST" => a $

where "AST" refers to an abstract syntax tree. "g" is short for "grammar."#footnote[This could be inaccurate. If so then just replace this with whatever computational linguists actually do.] The AST is a tree graph $G = (V,E)$ where $e in E -> e in "Pr" union "Su" union "Pc"$.

=== Step 2 - Canonicalization

Step 2 is canonicalization, a translation of a declarative sentence of arbitrary
form to the form

$ c because rho = (s_1,p_1) because (s_2,p_2) quad (star) $

(This can
equivalently be written $rho therefore c$.) We define $kappa$ as our canonicalization function.

$ kappa(a) : "AST" -> "AST" => a' $

$a'$ is our _canonical form in tree representation._ To transform $a$ to $a'$ we
strip out any surrounding elements, resolve any enthymemes, and rearrange the
sentence to match $(star)$. A further list of possible steps in the
canonicalization procedure is enumerated in ATIP §1.2.

Flattening the AST back into a string gives us the _canonicalized sentence_ $sigma '$.

== Part II. Characterization

=== Step 3 - Form

We define the forms as follows.

#table(
  columns: (auto, auto),
  table.header("name", "symbolic repr."),
  $alpha$, $X.a because Y.a$,
  $beta$, $X.a because X.b$,
  $gamma$, $X.a because Y.b$,
  $delta$, [$xi .q because Z.q$, where $xi in AA$],
)

where $X,Y,Z,... in "Re"$, $a,b,c,... in "Su"$, $p,q,r,... in "Pr"$.

Define the procedure $f$ mapping a canonicalized sentence $sigma '$ to $FF$ using following the mapping above. Let $C$ be the class of canonicalized sentences.

$ f(sigma ') : C -> FF $

We can equivalently define this over the canonicalized AST, $a'$.

$ f(a') : "AST" -> FF $

=== Step 4 - Substance

Each form gets its own substance type $TT_F$, as follows.

$
  TT_alpha & = {F,V,P} \
   TT_beta & = {s,p,u} \
  TT_gamma & = {i,d} \
  TT_delta & = {"I", "II", "III"}
$

Then we may define a transformation $S_F$ as follows,

$
  S_alpha ((p_a,c_a)) & : "Pr"^2 -> TT_alpha^2 \
   S_beta ((s_a,s_b)) & : "Su"^2 -> TT_beta^2 \
   S_gamma (R_s, R_p) & : (R_(("Su","Su")), R_(( "Pr","Pr" )) ) -> TT_gamma \
       S_delta (q, Z) & : (P, R_(P)) -> TT_delta
$

where $Z$ denotes a relationship that applies to the full proposition $q$.

The exact procedures for the transformations above are outlined in ATIP §2.4.

=== Step 5 - Lever

Levers require a substance type and a keyword, $k in K_F$, as defined in ATIP
§2.5. Keywords are defined in CAPITAL LETTERS and are binary relations between predicates.

Define a mapping $l_F$ as follows:

$
  l_alpha ((t_1,t_2), k) & : (TT^2_alpha, K_alpha) -> L_alpha \
   l_beta ((t_1,t_2), k) & : (TT^2_beta, K_beta) -> L_beta \
          l_gamma (t, k) & : (TT_gamma, K_gamma) -> L_gamma union emptyset \
          l_delta (t, k) & : (TT_delta, K_delta) -> L_delta \
$

where $L_F$ is defined in ATIP §2.5. Note that $l_gamma (d, k) = emptyset$ for
all $k$. This is called a non-sequitur.

== Part III.

Here we bring it all together and define the full pipeline.

=== Step 6 - Naming

We define the naming function $n_F$ as follows.

$
  n_F (sigma ', s,l) : (C, SS, LL) -> N
$

where $s = S_F$, $l = L_F$.

We first find the substance type $t in TT_F$ by applying $s(sigma ')$.
Then we feed this into $l$, yielding $lambda in L_F$.
Finally, we consult table 7 in ATIP §2.6 to translate $(F, t, lambda)$ to the
argument's symbol.
