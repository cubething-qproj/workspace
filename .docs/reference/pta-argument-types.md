# PTA argument types

Reference list of the 50 argument types in the Periodic Table of Arguments
(PTA), one entry per type. Source:
<https://periodic-table-of-arguments.org/alphabetical-list-of-argument-types/>,
scraped 2026-10-24. Wording is the site's; check the linked page for the
assessment questions, notes, and extra examples left out here.

See also `argument-scheme-vocab.md` (other scheme typologies),
`aif-node-types.md`, and `../designs/pta-atip-algorithm.typ` (the ATIP as a
classifier).

## How to read an entry

Each type is fixed by three parameters (see the ATIP):

- **Form**: where the conclusion and the premise share terms.
  - alpha: *a is X because a is Y* (same subject, different predicates)
  - beta: *a is X because b is X* (different subjects, same predicate)
  - gamma: *a is X because b is Y* (subjects and predicates both differ)
  - delta: *q is A because q is Z* (the premise is about the conclusion as a
    whole)
- **Substance**: what kind of statements make up the argument.
  - alpha: statement types of conclusion and premise, F (fact), V (value),
    P (policy), e.g. `PF`
  - beta: quantity of the two subjects, s (singular), p (particular), u
    (universal), e.g. `us`
  - gamma: whether the subject and predicate relations are identical (`i`) or
    different (`d`)
  - delta: who the conclusion is attributed to: I (the arguer), II (the
    addressee), III (a third party)
- **Lever**: the keyword naming the relation that licenses the step from
  premise to conclusion.

## Index


### Alpha quadrant: *a is X because a is Y*

| Type | Substance | Lever |
| --- | --- | --- |
| [Argument from cause](#argument-from-cause) | `FF` | CAUSE |
| [Argument from correlation](#argument-from-correlation) | `FF` | CORRELATION |
| [Argument from effect](#argument-from-effect) | `FF` | EFFECT |
| [Argument from incompatibility](#argument-from-incompatibility) | `FF` | EXCLUDES |
| [Argument from motive](#argument-from-motive) | `FF` | MOTIVE |
| [Argument from sign](#argument-from-sign) | `FF` | SIGN |
| [Argument from possibility](#argument-from-possibility) | `PF` | FEASIBILITY |
| [Argument from waste](#argument-from-waste) | `PF` | PRIOR INVESTMENT |
| [Pragmatic argument](#pragmatic-argument) | `PF` | PRAGMATIC MOTIVATION |
| [Deontic argument](#deontic-argument) | `PP` | DEONTIC MOTIVATION |
| [Teleologic argument](#teleologic-argument) | `PP` | TELEOLOGIC MOTIVATION |
| [Argument from evaluation](#argument-from-evaluation) | `PV` | EVALUATIVE MOTIVATION |
| [Argument from principle](#argument-from-principle) | `PV` | PRINCIPLED MOTIVATION |
| [Argument from criterion](#argument-from-criterion) | `VF` | CRITERION |
| [Argument from definition](#argument-from-definition) | `VF` | DEFINITION |
| [Argument from subsumption](#argument-from-subsumption) | `VF` | SUBSUMPTION |
| [Argument from disqualifier](#argument-from-disqualifier) | `VV` | DISQUALIFIER |
| [Argument from instantiation](#argument-from-instantiation) | `VV` | INSTANTIATION |
| [Argument from norm](#argument-from-norm) | `VV` | NORM |

### Beta quadrant: *a is X because b is X*

| Type | Substance | Lever |
| --- | --- | --- |
| [Argument from genus](#argument-from-genus) | `pu` | BELONGS TO THE GENUS OF |
| [Argument from analogy](#argument-from-analogy) | `ss` | ANALOGOUS |
| [Argument from comparison](#argument-from-comparison) | `ss` | COMPARABLE |
| [Argument from reciprocity](#argument-from-reciprocity) | `ss` | OWES RECIPROCITY |
| [Argument from similarity](#argument-from-similarity) | `ss` | SIMILAR |
| [Argumentum a minore](#argumentum-a-minore) | `ss` | RANKS ABOVE |
| [Metaphoric argument](#metaphoric-argument) | `ss` | METAPHORICALLY |
| [Argument from totality](#argument-from-totality) | `su` | BELONGS TO THE TOTALITY OF |
| [Argument from species](#argument-from-species) | `up` | A SPECIES OF |
| [Argument from example](#argument-from-example) | `us` | AN EXAMPLE OF |
| [Argument from composition](#argument-from-composition) | `uu` | COMPOSED OF |
| [Argument from division](#argument-from-division) | `uu` | A PART OF |
| [Argument from equality](#argument-from-equality) | `uu` | EQUAL |
| [Argumentum a maiore](#argumentum-a-maiore) | `uu` | RANKS BELOW |

### Gamma quadrant: *a is X because b is Y*

| Type | Substance | Lever |
| --- | --- | --- |
| [Non sequitur](#non-sequitur) | `d` | — |
| [Argument from converses](#argument-from-converses) | `i` | CONVERSE |
| [Argument from derivatives](#argument-from-derivatives) | `i` | DERIVATIVE |
| [Argument from integratives](#argument-from-integratives) | `i` | INTEGRATIVE |
| [Argument from opposites](#argument-from-opposites) | `i` | OPPOSITE |
| [Argument from synonyms](#argument-from-synonyms) | `i` | SYNONYMOUS |

### Delta quadrant: *q is A because q is Z*

| Type | Substance | Lever |
| --- | --- | --- |
| [Ethotic argument](#ethotic-argument) | `I` | ETHOTICALLY AUTHORITATIVE |
| [Argument from concession](#argument-from-concession) | `II` | COMMITS |
| [Argumentum ad baculum](#argumentum-ad-baculum) | `II` | NEGATIVE MOTIVATION |
| [Argumentum ad carotam](#argumentum-ad-carotam) | `II` | OFFERED REWARD |
| [Argumentum ad consequentiam](#argumentum-ad-consequentiam) | `II` | UNDESIRABLE IMPLICATION |
| [Argumentum ad hominem](#argumentum-ad-hominem) | `II` | CHARACTERALLY AUTHORITATIVE |
| [Argument from expert opinion](#argument-from-expert-opinion) | `III` | EPISTEMICALLY AUTHORITATIVE |
| [Argument from moral authority](#argument-from-moral-authority) | `III` | MORALLY AUTHORITATIVE |
| [Argument from testimony](#argument-from-testimony) | `III` | TESTIMONIALLY AUTHORITATIVE |
| [Argumentum ad ignorantiam](#argumentum-ad-ignorantiam) | `III` | PRESUMPTION |
| [Argumentum ad populum](#argumentum-ad-populum) | `III` | POPULARLY AUTHORITATIVE |

## Types

### Argument from analogy

- **Link**: <https://periodic-table-of-arguments.org/argument-from-analogy/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `ss`
- **Lever**: ANALOGOUS

Something is claimed about one case by pointing to a second, different case about which the same thing is already accepted. The argument works because the two cases are alike in the respect that matters here, so what holds for one carries over to the other. You can attack it by denying that the cases are alike in the way the claim requires, which collapses the argument without disputing anything about the second case.

**Example.** The impact of a large asteroid darkened the earth for several years, because the eruption of Krakatoa in 1883 darkened the earth for over two years

**Standardized form.** The asteroid impact (a) darkened the earth for years (X) because the Krakatoa eruption (b) darkened the earth for years (X).

**Lever formulation.** “The asteroid impact (a) is ANALOGOUS to the Krakatoa eruption (b) with respect to darkening the earth for years (X)”

**Not to be confused with:**

- [Argument from similarity](#argument-from-similarity): Substance in the alpha sense: a factual claim supported by a factual one. F ← F
- [Argument from comparison](#argument-from-comparison): An evaluation supported by an evaluation. V ← V
- [Argument from equality](#argument-from-equality): A policy claim supported by a factual one. P ← F
- [Argument from example](#argument-from-example): Substance, not lever: the conclusion is about a whole class and the premise about one member of it. us

**Source.** Alvarez, L.W., Alvarez, W., Asaro, F., & Michel, H.V. (1980). Extraterrestrial cause for the Cretaceous-Tertiary extinction. Science, 208(4448), 1095–1108 (p. 1105). Discussed in Shelley, C. (2004). Analogy counterarguments: A taxonomy for critical thinking. Argumentation, 18(2), 223–238.

### Argumentum ad baculum

- **Link**: <https://periodic-table-of-arguments.org/argumentum-ad-baculum/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `II`
- **Lever**: NEGATIVE MOTIVATION

The hearer is pressed to accept a claim by being shown what will happen to them if they refuse. The argument works because the harm that follows disagreement gives the hearer a motive to stop objecting, whatever they think of the claim. You can attack it by pointing to the gap between motive and evidence: a threat gives a reason to say yes, but no reason to believe.

**Example.** We have a right to these territories; our victorious armies will demonstrate this forcefully if you insist upon disputing our rights

**Standardized form.** “We have a right to these territories” (q) is acceptable (A) because “we have a right to these territories” (q) will be demonstrated forcefully if you insist upon disputing our rights (Z).

**Lever formulation.** “Being demonstrated forcefully if you insist upon disputing our rights (Z) is a NEGATIVE MOTIVATION for being acceptable (A)”

**Not to be confused with:**

- [Argumentum ad carotam](#argumentum-ad-carotam): The mirror image: a promised benefit instead of a threatened harm. OFFERED REWARD
- [Argumentum ad hominem](#argumentum-ad-hominem): Also addressed to the second person, but it attacks the claim through the character of its source. CHARACTERALLY AUTHORITATIVE, U
- [Ethotic argument](#ethotic-argument): The premise points to the arguer themselves and appeals to their reputation. I
- [Argument from expert opinion](#argument-from-expert-opinion): The premise names a third party’s knowledge, not a consequence for the hearer. III

**Source.** Werkmeister (1948, p. 63), quoted in Walton, D.N. (2000), Scare Tactics. Dordrecht: Springer.

### Argumentum ad carotam

- **Link**: <https://periodic-table-of-arguments.org/argumentum-ad-carotam/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `II`
- **Lever**: OFFERED REWARD

The hearer is pressed to accept a claim by being shown what they stand to gain by accepting it. The argument works because the benefit on offer gives the hearer a motive to agree: a carrot (instead of the stick of the argumentum ad baculum). You can attack it by pointing to the gap between motive and evidence, exactly as with the ad baculum: a reward gives a reason to say yes, but no reason to believe.

**Example.** We have the best offer on this car; agree to it today and I will throw in a free set of winter tires

**Standardized form.** “We have the best offer on this car” (q) is acceptable (A) because “we have the best offer on this car” (q) will be rewarded with a free set of winter tires if you agree to it today (Z).

**Lever formulation.** “Being rewarded with a free set of winter tires if you agree to it today (Z) is an OFFERED REWARD for being acceptable (A)”

**Not to be confused with:**

- [Argumentum ad baculum](#argumentum-ad-baculum): The mirror image: a threatened harm instead of a promised benefit. NEGATIVE MOTIVATION
- [Argumentum ad hominem](#argumentum-ad-hominem): Also addressed to the second person, but it attacks the claim through the character of its source. CHARACTERALLY AUTHORITATIVE, U
- [Teleologic argument](#teleologic-argument): Form, not lever: there the good consequences follow from doing the thing and here from accepting the claim. alpha
- [Argument from expert opinion](#argument-from-expert-opinion): The premise names a third party’s knowledge, not a benefit for the hearer. III

**Source.** Invented example.

### Argument from cause

- **Link**: <https://periodic-table-of-arguments.org/argument-from-cause/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `FF`
- **Lever**: CAUSE

A present state is explained by pointing to what happened to the thing earlier. The argument works through an unstated rule that this kind of event produces this kind of result, so once the event is granted, the result is expected. You can attack it by showing that the rule has exceptions, or that something intervened and stopped the usual result from occurring.

**Example.** The students must have come into the classroom soaking wet because they came cycling through the pouring rain

**Standardized form.** The students (a) must have come into the classroom soaking wet (X) because the students (a) came cycling through the pouring rain (Y).

**Lever formulation.** “Cycling through the pouring rain (Y) is a CAUSE of coming into the classroom soaking wet (X)”

**Not to be confused with:**

- [Argument from effect](#argument-from-effect): The lever runs the other way: the premise names the result, not what produced it. EFFECT
- [Argument from sign](#argument-from-sign): The premise names a reliable mark of the conclusion without producing it. SIGN
- [Argument from motive](#argument-from-motive): What produces the state is a person’s reason for acting rather than a physical process. MOTIVE
- [Pragmatic argument](#pragmatic-argument): Substance, not lever: the conclusion recommends a course of action instead of stating what happened. PF

**Source.** Invented example.

### Argument from comparison

- **Link**: <https://periodic-table-of-arguments.org/argument-from-comparison/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `ss`
- **Lever**: COMPARABLE

One thing is rated by setting it beside another that already carries the rating wanted. The argument works because the second thing is agreed to be excellent or dreadful, and the first is held to belong in the same bracket, so the agreed rating carries over. You can attack it by denying that the two are of a kind, which rejects the argument without disputing anything about the second thing.

**Example.** The Jane must be an excellent restaurant because Oud Sluis is an excellent restaurant

**Standardized form.** The Jane (a) must be an excellent restaurant (X) because Oud Sluis (b) is an excellent restaurant (X).

**Lever formulation.** “The Jane (a) is COMPARABLE to Oud Sluis (b) with respect to being an excellent restaurant (X)”

**Not to be confused with:**

- [Argument from similarity](#argument-from-similarity): What is transferred is something that happened rather than a judgment of quality. F ← F
- [Argument from equality](#argument-from-equality): What is transferred is an entitlement, and the premise remains factual. P ← F
- [Argument from analogy](#argument-from-analogy): The likeness is one of relations: elements of the one case stand to each other as elements of the other case do, rather than the two cases being measurable by the same standard. ANALOGOUS
- [Metaphoric argument](#metaphoric-argument): The second case is a figure of speech, and the shared verdict is left unstated. METAPHORICALLY

**Source.** Invented example.

### Argument from composition

- **Link**: <https://periodic-table-of-arguments.org/argument-from-composition/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `uu`
- **Lever**: COMPOSED OF

The reasoning runs upward from the parts to the whole they make up: what is true of every part is claimed for the thing they compose. The argument works by treating the whole as nothing more than its parts put together, so that a quality shared by all the parts must belong to the whole as well. You can attack it by showing that a whole can have qualities that arise only when the parts work together, and lack qualities that each part has on its own.

**Example.** Who is so blind as not to see that the parts of the element earth and of the element water, being heavy bodies, move naturally downwards, namely toward the center of the universe, assigned by nature herself as the goal and end of straight downward motion… Since this can be seen clearly, and since we are sure that the same holds for the whole as for the parts, must we not conclude that the natural motion of the [whole globe] earth is straight toward the center…?

**Standardized form.** The whole earth (a) moves naturally toward the center of the earth (X) because all the parts of the earth (b) move naturally toward the center of the earth (X).

**Lever formulation.** “The whole earth (a) is COMPOSED of all the parts of the earth (b) with respect to moving naturally toward the center of the earth (X)”

**Not to be confused with:**

- [Argument from division](#argument-from-division): The same relationship run the other way, from the whole down to its parts. A PART OF
- [Argument from example](#argument-from-example): The premise offers one member as a specimen, not the complete set of parts. us
- [Argument from species](#argument-from-species): The premise is a kind within a wider kind, not the components of a thing. A SPECIES OF

**Source.** Aristotle, On the Heavens 296b7–297a1, as reconstructed and criticized by Galileo Galilei, Galileo on the World Systems: A New Abridged Translation and Guide, translated and edited by Maurice A. Finocchiaro (Berkeley: University of California Press, 1997), pp. 83–84. Discussed in Maurice A. Finocchiaro, “The fallacy of composition: Guiding concepts, historical cases, and research problems”, Journal of Applied Logic 13 (2015), 24–43, at pp. 31–32.

### Argument from concession

- **Link**: <https://periodic-table-of-arguments.org/argument-from-concession/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `II`
- **Lever**: COMMITS

The addressee is pressed to accept a claim because they have already granted it themselves. The argument works by holding people to their own record: having asserted something earlier, the addressee is taken to be committed to it, and that commitment, not any evidence, is what is offered for the claim. You can attack it by showing that the earlier statement was withdrawn, was made in a different sense, or was never made at all.

**Example.** You cannot deny that the deficit matters, because you said so yourself last week.

**Standardized form.** “The deficit matters” (q) is acceptable (A) because “the deficit matters” (q) was said by you yourself last week (Z).

**Lever formulation.** “Having been said by you yourself last week (Z) COMMITS you to its being acceptable (A)”

**Not to be confused with:**

- [Argumentum ad hominem](#argumentum-ad-hominem): Also addressed to the second person, but it attacks a claim through the addressee’s character rather than defending one through their record. CHARACTERALLY AUTHORITATIVE, U
- [Argumentum ad baculum](#argumentum-ad-baculum): The addressee is given a motive to agree, not held to something they already agreed. NEGATIVE MOTIVATION
- [Ethotic argument](#ethotic-argument): The premise points at the arguer’s own standing, not the addressee’s prior statement. I
- [Argument from expert opinion](#argument-from-expert-opinion): The premise names a third party’s knowledge. III

**Source.** Invented example.

### Argumentum ad consequentiam

- **Link**: <https://periodic-table-of-arguments.org/argumentum-ad-consequentiam/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `II`
- **Lever**: UNDESIRABLE IMPLICATION

A claim is rejected because of what would follow if it were true. The argument works by treating the unwelcomeness of a state of affairs as evidence against it: the consequences of the claim’s being true are so undesirable that its being false is offered as the safer thing to believe. You can attack it by pointing out that the world is under no obligation to be agreeable, so how bad a truth would be has no bearing on whether it is one.

**Example.** Your theory cannot be right, because if it were, the last twenty years of your work would have been wasted.

**Standardized form.** “Your theory is right” (q) is unacceptable (U) because “your theory is right” (q) would, if true, mean that the last twenty years of your work were wasted (Z).

**Lever formulation.** “Meaning, if true, that the last twenty years of your work were wasted (Z) is an UNDESIRABLE IMPLICATION supporting being unacceptable (U)”

**Not to be confused with:**

- [Argumentum ad baculum](#argumentum-ad-baculum): The harm follows from accepting the claim, not from the claim’s being true. NEGATIVE MOTIVATION
- [Argumentum ad hominem](#argumentum-ad-hominem): The claim is attacked through the character of its source, not through what its truth would entail. CHARACTERALLY AUTHORITATIVE
- [Pragmatic argument](#pragmatic-argument): Form: the consequences belong to an action, not to the truth of a statement. alpha

**Source.** Invented example.

### Argument from converses

- **Link**: <https://periodic-table-of-arguments.org/argument-from-converses/>
- **Form**: gamma (*a is X because b is Y*)
- **Substance**: `i`
- **Lever**: CONVERSE

A claim is supported by stating the same relation from the other end: if one party did the giving, the other party did the receiving. The argument works because the two subjects and the two predicates are converse pairs that describe a single relation, so asserting it from one side is the same as asserting it from the other. You can attack it by showing that the two predicates are not true converses because one side of the relation can hold without the other.

**Example.** The tenant must have received the notice, because the landlord sent it.

**Standardized form.** The tenant (a) must have received the notice (X) because the landlord (b) sent the notice (Y).

**Lever formulation.** “The landlord (b) is the CONVERSE of the tenant (a) in an identical way as sending the notice (Y) is the CONVERSE of receiving the notice (X)”

**Not to be confused with:**

- [Argument from opposites](#argument-from-opposites): The matching relation is opposition, not conversion: peace and war exclude each other, while sending and receiving complete each other. OPPOSITE
- [Argument from derivatives](#argument-from-derivatives): The two terms are grammatical forms of one word, not two ends of one relation. DERIVATIVE
- [Argument from synonyms](#argument-from-synonyms): The two statements mean the same thing said twice; here they describe one relation from two positions. SYNONYMOUS
- [Argument from effect](#argument-from-effect): Read as an alpha argument about the notice alone, the sending would be the cause of the receiving. EFFECT

**Source.** Invented example.

### Argument from correlation

- **Link**: <https://periodic-table-of-arguments.org/argument-from-correlation/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `FF`
- **Lever**: CORRELATION

One fact about something is inferred from another fact that is usually found alongside it. The argument works on nothing more than the two things tending to go together: no claim is made that either one produces the other. You can attack it by showing the pairing is a coincidence, or that a third factor underlies both, so the presence of one says nothing reliable about the other.

**Example.** He must eat a lot of meat because he is always so agitated.

**Standardized form.** He (a) must eat a lot of meat (X) because he (a) is always so agitated (Y).

**Lever formulation.** “Always being so agitated (Y) is CORRELATED with eating a lot of meat (X)”

**Not to be confused with:**

- [Argument from cause](#argument-from-cause): The premise names what produced the state in the conclusion. CAUSE
- [Argument from effect](#argument-from-effect): The premise names what that state produced. EFFECT
- [Argument from sign](#argument-from-sign): The premise is offered as a reliable indicator, not merely as something that often coincides. SIGN
- [Argument from motive](#argument-from-motive): The premise names the reason a person has for acting. MOTIVE
- 

**Source.** Source not yet recorded.

### Argument from criterion

- **Link**: <https://periodic-table-of-arguments.org/argument-from-criterion/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `VF`
- **Lever**: CRITERION

Something is judged good or bad by pointing to a feature. The argument works by treating that feature as a yardstick: the feature is a plain matter of description, and the verdict follows once the yardstick is accepted. You can attack it by accepting the feature but rejecting the yardstick: this, the critic says, is simply not what quality consists in.

**Example.** Morandi’s paintings are great because they are not realistic representations of bottles

**Standardized form.** Morandi’s paintings (a) are great (X) because Morandi’s paintings (a) are not realistic representations of bottles (Y).

**Lever formulation.** “Not being realistic representations of bottles (Y) is a CRITERION for being great (X)”

**Not to be confused with:**

- [Argument from definition](#argument-from-definition): The premise states what the word in the conclusion means, rather than a standard for applying a verdict. DEFINITION
- [Argument from subsumption](#argument-from-subsumption): The premise names a case that falls under the term in the conclusion. SUBSUMPTION
- [Argument from norm](#argument-from-norm): Substance, not lever: the premise is itself a verdict rather than a description. VV
- [Argument from sign](#argument-from-sign): Substance: the conclusion states a fact rather than passing judgment. FF

**Source.** Adapted from a discussion on Reddit, r/ContemporaryArt: “Please could someone explain to me why Giorgio…”.

### Argument from definition

- **Link**: <https://periodic-table-of-arguments.org/argument-from-definition/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `VF`
- **Lever**: DEFINITION

Whether a label applies to something is decided by spelling out what the label means and checking the case against it. The argument works because a definition sets the conditions for using a word: if the case meets them, it gets the name, and if it does not, the name is withheld. You can attack it by disputing the definition offered, arguing that it is not what the word means, or that it does not capture everything the word means.

**Example.** Unauthorized downloading is not theft because unauthorized downloading does not deprive the original owner of the use of an object

**Standardized form.** Unauthorized downloading (a) is not theft (X) because unauthorized downloading (a) does not deprive the original owner of the use of an object (Y).

**Lever formulation.** “Depriving the original owner of the use of an object (Y) is the DEFINITION of theft (X)”

**Not to be confused with:**

- [Argument from criterion](#argument-from-criterion): The premise supplies a standard for a judgment of quality, not the meaning of the term in the conclusion. CRITERION
- [Argument from subsumption](#argument-from-subsumption): The premise names a particular case that falls under the term instead of spelling the term out. SUBSUMPTION
- [Argument from disqualifier](#argument-from-disqualifier): Substance, not lever: the premise is itself evaluative, and it qualifies the label rather than withholding it. VV

**Source.** Comment on an article published on techdirt.com, 05.04.2010.

### Deontic argument

- **Link**: <https://periodic-table-of-arguments.org/deontic-argument/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `PP`
- **Lever**: DEONTIC MOTIVATION

One obligation is derived from another. The argument rests on the rule that whoever is bound to an end is bound to the means: once someone must reach a certain goal, they are held to the step that gets them there. You can attack it by denying the larger obligation, or by showing it can be reached without taking this particular step.

**Example.** We should decarbonize the power sector because we should reach net-zero emissions by 2050

**Standardized form.** We (a) should decarbonize the power sector (X) because we (a) should reach net-zero emissions by 2050 (Y).

**Lever formulation.** “Having to reach net-zero emissions by 2050 (Y) is a DEONTIC MOTIVATION for having to decarbonize the power sector (X)”

**Not to be confused with:**

- [Teleologic argument](#teleologic-argument): The premise names an end the actor pursues rather than an obligation owed. TELEOLOGIC MOTIVATION
- [Pragmatic argument](#pragmatic-argument): Substance: the premise predicts a consequence. PF
- [Argument from principle](#argument-from-principle): Substance: the premise passes a moral verdict on the activity. PV
- [Argument from evaluation](#argument-from-evaluation): Substance: the premise rates the activity as worth doing. PV

**Source.** Source not yet recorded.

### Argument from derivatives

- **Link**: <https://periodic-table-of-arguments.org/argument-from-derivatives/>
- **Form**: gamma (*a is X because b is Y*)
- **Substance**: `i`
- **Lever**: DERIVATIVE

A claim is supported by asserting a stripped version of it. The argument works because claim and support are the same statement in two shapes, one wrapped and the other bare. You can attack it by showing that the wrapping isn’t neutral but changes what the terms pick out, so what was true of them on their own stops being true inside the wrapping.

**Example.** Eating the Minotaur is eating something human, because the Minotaur is human

**Standardized form.** Eating the Minotaur (a) is eating something human (X) because the Minotaur (b) is human (Y).

**Lever formulation.** “The Minotaur (b) is DERIVATIVE of eating the Minotaur (a) in an identical way as human (Y) is DERIVATIVE of eating something human (X)”

**Not to be confused with:**

- [Argument from synonyms](#argument-from-synonyms): The matching relation is sameness of meaning. SYNONYMOUS
- [Argument from opposites](#argument-from-opposites): The matching relation is opposition. OPPOSITE
- [Argument from integratives](#argument-from-integratives): The relation is part to whole. INTEGRATIVE
- [Non sequitur](#non-sequitur): Substance, not lever: the two relations do not match, so no lever can be formulated. d

**Source.** Source not yet recorded.

### Argument from disqualifier

- **Link**: <https://periodic-table-of-arguments.org/argument-from-disqualifier/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `VV`
- **Lever**: DISQUALIFIER

A description of something is modified by adding a qualification that stops the description from being the whole story. The argument works by conceding the description and denying that it exhausts the case. You can attack it by denying that the qualification makes any real difference, by denying that the case really has it, or by holding that the original description is still the whole story.

**Example.** History is not just storytelling. It is evidence-based storytelling

**Standardized form.** History (a) is not just storytelling (X) because history (a) is evidence-based storytelling (Y).

**Lever formulation.** “Being evidence-based storytelling (Y) is a DISQUALIFIER of being just storytelling (X)”

**Not to be confused with:**

- [Argument from norm](#argument-from-norm): The premise names a standard the subject meets, rather than qualifying a label. NORM
- [Argument from instantiation](#argument-from-instantiation): The premise names a kind of the quality claimed, with no label being taken back. INSTANTIATION
- [Argument from definition](#argument-from-definition): Substance, not lever: there the premise is a description, and the label is withheld outright rather than qualified. VF
- [Argument from subsumption](#argument-from-subsumption): Substance: the premise states a matter of fact. VF

**Source.** Source not yet recorded.

### Argument from division

- **Link**: <https://periodic-table-of-arguments.org/argument-from-division/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `uu`
- **Lever**: A PART OF

The reasoning runs downward from a whole to its parts: what is true of the whole is claimed for each part in it. The argument works by treating each part as sharing the character of the whole. You can attack it by showing that a whole can be excellent overall while one of its parts is weak, or that a part can lack a quality the whole owes to the rest of its parts.

**Example.** All the faculties of the University of Amsterdam are excellent because the University of Amsterdam is excellent

**Standardized form.** All the faculties of the University of Amsterdam (a) are excellent (X) because the University of Amsterdam (b) is excellent (X).

**Lever formulation.** “All the faculties of the University of Amsterdam (a) are a PART of the University of Amsterdam (b) with respect to being excellent (X)”

**Not to be confused with:**

- [Argument from composition](#argument-from-composition): The same relationship run the other way, from the parts up to the whole. COMPOSED OF
- [Argument from totality](#argument-from-totality): The conclusion is one member of the collection, not the complete set of parts. su
- [Argument from genus](#argument-from-genus): The premise is a wider kind and the conclusion a narrower kind, not a thing and its components. BELONGS TO THE GENUS OF

**Source.** Invented example.

### Argument from effect

- **Link**: <https://periodic-table-of-arguments.org/argument-from-effect/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `FF`
- **Lever**: EFFECT

An outcome is noticed and taken to show what must have produced it. The argument works by running a causal rule backwards: this kind of result normally comes from that kind of cause, so the result is taken as evidence that the cause occurred. You can attack it by pointing to another way the same outcome could have come about, since the argument needs the named cause to be the only plausible one.

**Example.** In the center of Amsterdam, parking rates must have gone up because there are more empty spaces on the streets

**Standardized form.** In the center of Amsterdam (a), parking rates must have gone up (X) because in the center of Amsterdam (a) there are more empty spaces on the streets (Y).

**Lever formulation.** “More empty spaces on the street (Y) is an EFFECT of increased parking rates (X)”

**Not to be confused with:**

- [Argument from cause](#argument-from-cause): The premise names what produced the state in the conclusion, not what that state produced. CAUSE
- [Argument from sign](#argument-from-sign): The premise names a mark that goes with the conclusion without being produced by it. SIGN
- [Argument from correlation](#argument-from-correlation): No direction of production is claimed at all. CORRELATION
- [Argument from motive](#argument-from-motive): The producer is an agent’s reason for acting rather than a process. MOTIVE

**Source.** Invented example.

### Argument from equality

- **Link**: <https://periodic-table-of-arguments.org/argument-from-equality/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `uu`
- **Lever**: EQUAL

A permission, an entitlement or an obligation is claimed for one party on the ground that another party already has it or takes it. The argument rests on the rule that like cases should be treated alike, so what the other party does or gets becomes what the first party may or should do. You can attack it by showing that the two parties are not owed the same treatment, so that what holds for the one need not hold for the other.

**Example.** Dutch royals should pay taxes because every other citizen pays taxes

**Standardized form.** Dutch royals (a) should pay taxes (X) because every other citizen (b) pays taxes (X).

**Lever formulation.** “Dutch royals (a) are EQUAL to every other citizen (b) with respect to having to pay taxes (X)”

**Not to be confused with:**

- [Argument from comparison](#argument-from-comparison): What is transferred is a judgment of quality rather than a permission. V ← V
- [Argument from similarity](#argument-from-similarity): Both halves report how things stand; nothing is being recommended. F ← F
- [Argument from analogy](#argument-from-analogy): The likeness is one of relations: elements of the one case stand to each other as elements of the other case do, rather than the two cases having the same normative standing. ANALOGOUS
- [Argument from totality](#argument-from-totality): The premise class is one the conclusion’s subject belongs to, not a separate party held to be its equal. BELONGS TO THE TOTALITY OF

**Source.** From a news item on a poll by the Dutch television program EenVandaag, in which 62 percent of Dutch people said King Willem-Alexander, Queen Máxima and Princess Beatrix should pay taxes like every other citizen.

### Ethotic argument

- **Link**: <https://periodic-table-of-arguments.org/ethotic-argument/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `I`
- **Lever**: ETHOTICALLY AUTHORITATIVE

The speaker backs their claim by offering themselves as its guarantee. The argument works because they present themselves as someone whose word counts, so their standing carries the claim in place of anything about the subject matter itself. You can attack it by questioning that standing, or by showing it is irrelevant to the matter at hand.

**Example.** In this book, I say that the late Prince Bernhard had a third extramarital daughter, and I have built a good reputation when it comes to royal revelations

**Standardized form.** “The late Prince Bernhard had a third extramarital daughter” (q) is acceptable (A) because “the late Prince Bernhard had a third extramarital daughter” (q) is said by me (Z).

**Lever formulation.** “Being said by me (Z) is ETHOTICALLY AUTHORITATIVE for being acceptable (A)”

**Not to be confused with:**

- [Argumentum ad hominem](#argumentum-ad-hominem): The premise points at the person addressed, and attacks acceptability rather than supporting it. II, U
- [Argument from expert opinion](#argument-from-expert-opinion): The source is a third party, credited with knowing the subject. III
- [Argument from testimony](#argument-from-testimony): The source is a third party who was in a position to see what happened. III
- [Argumentum ad populum](#argumentum-ad-populum): The source is a third party, and it is their number that counts. III

**Source.** Adapted from an interview with Dutch royal watcher Marc van der Linden, talk show Knevel & Van den Brink, Dutch television, 23 August 2011.

### Argument from evaluation

- **Link**: <https://periodic-table-of-arguments.org/argument-from-evaluation/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `PV`
- **Lever**: EVALUATIVE MOTIVATION

An activity is recommended by saying how good, worthwhile, enjoyable, or rewarding it is. The argument works because the value of the activity itself is offered as the reason. You can attack it by disputing the valuation, since the argument reaches only as far as the hearer shares the speaker’s sense of what is worthwhile.

**Example.** You should do paragliding because it is a great experience

**Standardized form.** Paragliding (a) should be done by you (X) because paragliding (a) is a great experience (Y).

**Lever formulation.** “Being a great experience (Y) is an EVALUATIVE MOTIVATION for having to be done by you (X)”

**Not to be confused with:**

- [Argument from principle](#argument-from-principle): The premise names a right or a rule at stake rather than the worth of the experience. PRINCIPLED MOTIVATION
- [Pragmatic argument](#pragmatic-argument): Substance: the premise predicts what the activity will bring about. PF
- [Teleologic argument](#teleologic-argument): Substance: the premise names an end the actor is pursuing. PP
- [Argument from norm](#argument-from-norm): Substance: the conclusion rates something instead of recommending it. VV
- 

**Source.** Review on TripAdvisor by Karanuppal24, 13 December 2017.

### Argument from example

- **Link**: <https://periodic-table-of-arguments.org/argument-from-example/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `us`
- **Lever**: AN EXAMPLE OF

A claim about a whole class of things is supported by producing a single member of it. The argument works by treating one case as representative of the whole class. You can attack it by showing the case is not typical, since one instance is a thin basis for a claim about every member of the class.

**Example.** Electric cars are cheap to run, because ours is

**Standardized form.** Electric cars (a) are cheap to run (X) because our electric car (b) is cheap to run (X).

**Lever formulation.** “Our electric car (b) is an EXAMPLE of electric cars (a) with respect to being cheap to run (X)”

**Not to be confused with:**

- [Argument from species](#argument-from-species): The premise is a kind within the class, covering some of its members, not one individual case. up
- [Argument from totality](#argument-from-totality): Runs the other way, from the whole class down to one case. su
- [Argument from analogy](#argument-from-analogy): Both halves are about single cases of the same rank, with no class relation between them. ss

**Source.** Invented example.

### Argument from expert opinion

- **Link**: <https://periodic-table-of-arguments.org/argument-from-expert-opinion/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `III`
- **Lever**: EPISTEMICALLY AUTHORITATIVE

A claim is backed by who made it, and the person named is someone who is supposed to know the subject. The argument works because the expert’s knowledge is offered in place of any argument about the matter itself: if they know, and they say so, that is reason enough. You can attack it by showing that the expertise is not real, not relevant to this particular question, or not shared by others in the field.

**Example.** We only use 10% of our mental potentials. This was the belief of Albert Einstein, the greatest physicist of recent times.

**Standardized form.** “We only use 10% of our mental potentials” (q) is acceptable (A) because “we only use 10% of our mental potentials” (q) is said by Einstein (Z).

**Lever formulation.** “Being said by Einstein (Z) is EPISTEMICALLY AUTHORITATIVE for being acceptable (A)”

**Not to be confused with:**

- [Argument from testimony](#argument-from-testimony): The source counts because they were in a position to see, not because of what they know in general. TESTIMONIALLY AUTHORITATIVE
- [Argument from moral authority](#argument-from-moral-authority): The source counts because of their standing to say what is right. MORALLY AUTHORITATIVE
- [Argumentum ad populum](#argumentum-ad-populum): Authority is quantitative: how many say it, not who. POPULARLY AUTHORITATIVE
- [Argumentum ad hominem](#argumentum-ad-hominem): The premise points at the addressee and attacks acceptability. II, U

**Source.** A pamphlet reproducing the well-known urban myth that Einstein said we only use 10% of our mental potentials. Einstein said no such thing.

### Argument from genus

- **Link**: <https://periodic-table-of-arguments.org/argument-from-genus/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `pu`
- **Lever**: BELONGS TO THE GENUS OF

A claim about one kind of thing is supported by pointing to the wider kind it falls under. The argument works by passing down what is said of the wider class to the narrower one: birds have emotions because all animals do. You can attack it by showing that the property does not belong to the wider class as such — to every member, because it is a member — but only to most of them as it happens.

**Example.** Birds have emotions because all animals have emotions

**Standardized form.** Birds (a) have emotions (X) because all animals (b) have emotions (X).

**Lever formulation.** “Birds (a) belong to the GENUS of animals (b) with respect to having emotions (X)”

**Not to be confused with:**

- [Argument from totality](#argument-from-totality): The conclusion is one individual member of the collection, not a kind within it. su
- [Argument from species](#argument-from-species): Runs the other way, from the narrower kind up to the wider one. up
- [Argument from division](#argument-from-division): The premise and conclusion are a thing and its components, not a wider kind and a narrower one. A PART OF

**Source.** Source not yet recorded.

### Argumentum ad hominem

- **Link**: <https://periodic-table-of-arguments.org/argumentum-ad-hominem/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `II`
- **Lever**: CHARACTERALLY AUTHORITATIVE

What someone has said is rejected by pointing at the person who said it. The argument works on the assumption that who makes a claim settles whether it is true, so the speaker’s character, situation or conduct is offered as reason enough to dismiss the claim without examining it. You can attack it by observing that a claim can be correct whoever happens to make it.

**Example.** Your claim that everyone should become a vegetarian makes no sense. You work at a seafood restaurant!

**Standardized form.** “Everyone should become a vegetarian” (q) is unacceptable (U) because “everyone should become a vegetarian” (q) is said by you (Z).

**Lever formulation.** “Being said by you (Z) is CHARACTERALLY AUTHORITATIVE for being unacceptable (U)”

**Not to be confused with:**

- [Ethotic argument](#ethotic-argument): The premise points at the arguer themselves, and supports acceptability. I, A
- [Argumentum ad baculum](#argumentum-ad-baculum): Also addressed to the second person, but the premise offers a threatened harm rather than a bad character. NEGATIVE MOTIVATION
- [Argumentum ad carotam](#argumentum-ad-carotam): Also addressed to the second person, but the premise offers a promised benefit. OFFERED REWARD
- [Argument from expert opinion](#argument-from-expert-opinion): A third party, and acceptability supported rather than attacked. III, A

**Source.** Invented example.

### Argumentum ad ignorantiam

- **Link**: <https://periodic-table-of-arguments.org/argumentum-ad-ignorantiam/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `III`
- **Lever**: PRESUMPTION

A claim is said to deserve acceptance because nobody has shown it to be false. The argument works by shifting the burden of proof: in the absence of a refutation, the claim is treated as standing by default, so the silence of its opponents is offered in place of any evidence for it. You can attack it by pointing out that a claim can be unrefuted simply because nobody has looked, and that absence of evidence counts as evidence of absence only where the evidence would have turned up if it existed.

**Example.** Ghosts exist, because nobody has ever proved that they don’t.

**Standardized form.** “Ghosts exist” (q) is acceptable (A) because “ghosts exist” (q) has never been refuted by anyone (Z).

**Lever formulation.** “Never having been refuted by anyone (Z) is a PRESUMPTION in favor of being acceptable (A)”

**Not to be confused with:**

- [Argumentum ad populum](#argumentum-ad-populum): Third parties are counted for what they assert, not for what they have failed to refute. POPULARLY AUTHORITATIVE
- [Argument from expert opinion](#argument-from-expert-opinion): A named third party is credited with knowledge; here nobody is credited with anything. EPISTEMICALLY AUTHORITATIVE
- [Argumentum ad hominem](#argumentum-ad-hominem): Substance and direction: the premise points at the addressee and attacks acceptability. II, U

**Source.** Invented example.

### Argument from incompatibility

- **Link**: <https://periodic-table-of-arguments.org/argument-from-incompatibility/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `FF`
- **Lever**: EXCLUDES

Something is ruled out by pointing to a second fact about the same thing that cannot hold together with it. The argument works through an unstated rule that the two properties exclude one another, so that establishing the one is enough to deny the other. You can attack it by showing that the two are compatible after all — that the exclusion is only usual, not strict, or that it does not apply in this case.

**Example.** Peter cannot be the burglar, because he was in Lisbon on the night of the break-in.

**Standardized form.** Peter (a) cannot be the burglar (X) because Peter (a) was in Lisbon on the night of the break-in (Y).

**Lever formulation.** “Being in Lisbon on the night of the break-in (Y) EXCLUDES being the burglar (X)”

**Not to be confused with:**

- [Argument from sign](#argument-from-sign): The premise-predicate is a positive indicator of the conclusion-predicate rather than something that rules it out. SIGN
- [Argument from cause](#argument-from-cause): The premise names what brought the conclusion about; here it names what makes the conclusion impossible. CAUSE
- [Argument from disqualifier](#argument-from-disqualifier): The label is kept and qualified; here the label is withdrawn altogether. DISQUALIFIER

**Source.** Invented example.

### Argument from instantiation

- **Link**: <https://periodic-table-of-arguments.org/argument-from-instantiation/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `VV`
- **Lever**: INSTANTIATION

A judgment is supported by naming a more specific version of the very quality being claimed. The argument works because the supporting quality is one of the forms the general quality can take — being tragic is one way of being moving — so having the specific version means having the general one. You can attack it by denying that the two really stand as kind to sub-kind, treating them instead as different things altogether.

**Example.** The story of Oedipus is moving because it is tragic

**Standardized form.** The story of Oedipus (a) is moving (X) because the story of Oedipus (a) is tragic (Y).

**Lever formulation.** “Being tragic (Y) is an INSTANTIATION of being moving (X)”

**Not to be confused with:**

- [Argument from norm](#argument-from-norm): The premise names a separate quality serving as a standard, not a kind of the quality claimed. NORM
- [Argument from disqualifier](#argument-from-disqualifier): The premise qualifies a label the conclusion denies. DISQUALIFIER
- [Argument from subsumption](#argument-from-subsumption): Substance, not lever: there the premise is a description rather than a verdict. VF
- [Argument from evaluation](#argument-from-evaluation): Substance: the conclusion recommends doing something. PV

**Source.** Source not yet recorded.

### Argument from integratives

- **Link**: <https://periodic-table-of-arguments.org/argument-from-integratives/>
- **Form**: gamma (*a is X because b is Y*)
- **Substance**: `i`
- **Lever**: INTEGRATIVE

A claim about something is supported by saying a different thing about one part or aspect of it. The argument works by letting the part settle the whole: how hard a thing is to defeat is treated as deciding whether it will win. You can attack it by denying that the part is decisive for the whole.

**Example.** Evil will never beat good because defeating evil is easier than defeating good

**Standardized form.** Evil (a) will never beat good (X) because defeating evil (b) is easier than defeating good (Y).

**Lever formulation.** “Defeating evil (b) is INTEGRATIVE of evil (a) in an identical way as being easier than defeating good (Y) is INTEGRATIVE of never beating good (X)”

**Not to be confused with:**

- [Argument from synonyms](#argument-from-synonyms): The matching relation is sameness of meaning. SYNONYMOUS
- [Argument from opposites](#argument-from-opposites): The matching relation is opposition. OPPOSITE
- [Argument from derivatives](#argument-from-derivatives): One term is formed from the other. DERIVATIVE
- [Non sequitur](#non-sequitur): Substance, not lever: the two relations do not match, so no lever can be formulated. d

**Source.** Source not yet recorded.

### Argumentum a maiore

- **Link**: <https://periodic-table-of-arguments.org/argumentum-a-maiore/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `uu`
- **Lever**: RANKS BELOW

The argument runs from the greater case to the lesser one: if something holds even where it is hardest to believe — of the strongest, the wisest, the most exalted, the nearest relation — then it surely holds of the ordinary case. The argument works because the two cases are placed on one scale, so that whatever is granted at the top must be granted below it. You can attack it by denying the scale, since without it there is no reason why what holds of the one case should hold of the other.

**Example.** Humans don’t know everything because even the gods don’t know everything

**Standardized form.** Humans (a) don’t know everything (X) because even the gods (b) don’t know everything (X).

**Lever formulation.** “Humans (a) RANK BELOW the gods (b) with respect to not knowing everything (X)”

**Not to be confused with:**

- [Argumentum a minore](#argumentum-a-minore): The mirror image: the subject of the conclusion is the greater case and the subject of the premise the lesser one, so the argument runs up the scale instead of down it. RANKS ABOVE
- [Argument from example](#argument-from-example): The premise is a specimen of the class in the conclusion, not a case ranked above it. AN EXAMPLE OF
- [Argument from analogy](#argument-from-analogy): The two cases are held to be alike, with no ranking between them. ANALOGOUS

**Source.** Source not yet recorded.

### Metaphoric argument

- **Link**: <https://periodic-table-of-arguments.org/metaphoric-argument/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `ss`
- **Lever**: METAPHORICALLY

Judgment is passed on something by calling it something else entirely. The argument works because the approval or disapproval that attaches to the image is meant to settle on the thing described without ever being stated: nobody is asked to check whether the image is literally true, only to feel its force. You can attack it by questioning whether the image is apt — whether the thing really resembles what it is being called in the respect that carries the judgment.

**Example.** This leader is a captain who abandons ship

**Standardized form.** This leader (a) is bad (X) because a captain abandoning ship (b) is bad (X).

**Lever formulation.** “This leader (a) is described METAPHORICALLY as a captain abandoning ship (b) with respect to being bad (X)”

**Not to be confused with:**

- [Argument from comparison](#argument-from-comparison): The second case is a real comparable and the shared verdict is stated outright. COMPARABLE
- [Argument from analogy](#argument-from-analogy): The likeness is asserted literally, in the respect that matters to the claim. ANALOGOUS
- [Argument from similarity](#argument-from-similarity): The premise reports something that actually happened. SIMILAR

**Source.** Source not yet recorded.

### Argumentum a minore

- **Link**: <https://periodic-table-of-arguments.org/argumentum-a-minore/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `ss`
- **Lever**: RANKS ABOVE

The argument runs from the lesser case to the greater one: what holds even of the weaker, the less able, the less likely candidate is taken to hold all the more of the stronger one. The argument works because both cases are placed on one scale, so that whatever is granted lower down must be granted higher up. You can attack it by denying the scale, since without it there is no reason why what holds of the one case should hold of the other.

**Example.** Einstein can solve this equation because even I can solve it

**Standardized form.** Einstein (a) can solve this equation (X) because even I (b) can solve this equation (X).

**Lever formulation.** “Einstein (a) RANKS ABOVE me (b) with respect to being able to solve this equation (X)”

**Not to be confused with:**

- [Argumentum a maiore](#argumentum-a-maiore): The mirror image: the subject of the conclusion is the lesser case and the subject of the premise the greater one, so the argument runs down the scale instead of up it. RANKS BELOW
- [Argument from analogy](#argument-from-analogy): The two cases are held to be alike, with no ranking between them. ANALOGOUS
- [Argument from example](#argument-from-example): Substance: the conclusion is about a whole class rather than one further individual. us

**Source.** Source not yet recorded.

### Argument from moral authority

- **Link**: <https://periodic-table-of-arguments.org/argument-from-moral-authority/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `III`
- **Lever**: MORALLY AUTHORITATIVE

A claim about what ought to be done is backed by who says so, and the person named is someone whose business it is to say what is right — a religious leader, a court, an elder. The argument works because it is their standing to judge, not their information, that is meant to settle the matter. You can attack it by refusing to recognize that standing, since the argument reaches only those who do.

**Example.** According to the pope, rich countries ought to take in more refugees

**Standardized form.** “Rich countries ought to take in more refugees” (q) is acceptable (A) because “rich countries ought to take in more refugees” (q) is said by the pope (Z).

**Lever formulation.** “Being said by the pope (Z) is MORALLY AUTHORITATIVE for being acceptable (A)”

**Not to be confused with:**

- [Argument from expert opinion](#argument-from-expert-opinion): The source is credited with knowing the subject rather than with standing to judge it. EPISTEMICALLY AUTHORITATIVE
- [Argument from testimony](#argument-from-testimony): The source is credited with having been in a position to see. TESTIMONIALLY AUTHORITATIVE
- [Argumentum ad populum](#argumentum-ad-populum): Authority is quantitative: how many say it, not who. POPULARLY AUTHORITATIVE
- [Ethotic argument](#ethotic-argument): The arguer offers their own standing rather than a third party’s. I

**Source.** Invented example.

### Argument from motive

- **Link**: <https://periodic-table-of-arguments.org/argument-from-motive/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `FF`
- **Lever**: MOTIVE

What someone will do is predicted by naming the reason they have for doing it — a wish, an interest, an attachment. The argument works on the assumption that people act on their reasons, so a strong enough reason makes the action likely. You can attack it by showing that the person has a stronger reason to do something else, or that they do not in fact hold the reason ascribed to them.

**Example.** Bill will pay the ransom because he loves his wife and children

**Standardized form.** Bill (a) will pay the ransom (X) because Bill (a) loves his wife and children (Y).

**Lever formulation.** “Loving your wife and children (Y) is a MOTIVE for paying the ransom (X)”

**Not to be confused with:**

- [Argument from cause](#argument-from-cause): What produces the action is a process rather than an agent’s reason. CAUSE
- [Argument from sign](#argument-from-sign): The premise names a mark of the conclusion rather than a ground for acting. SIGN
- [Argument from correlation](#argument-from-correlation): The two facts merely go together; no reason for acting is named. CORRELATION
- [Pragmatic argument](#pragmatic-argument): Substance, not lever: the conclusion tells someone what to do rather than predicting what they will do. PF

**Source.** Source not yet recorded.

### Non sequitur

- **Link**: <https://periodic-table-of-arguments.org/non-sequitur/>
- **Form**: gamma (*a is X because b is Y*)
- **Substance**: `d`
- **Lever**: —

A reason is offered that has no bearing on the claim at all: it talks about something else and says something unrelated about it. There is no mechanism to make it work, because no connection can be found either between the two things talked about or between the two things said. It needs no attack, since there is nothing to attack; when it turns up in real discourse, the useful response is to ask what link the speaker had in mind and left unsaid.

**Example.** The moon is made of cheese because Máxima is queen of the Netherlands

**Standardized form.** The moon (a) is made of cheese (X) because Máxima (b) is queen of the Netherlands (Y).

**Lever formulation.** No keyword can be found, because there is no meaningful semantic link between the subjects and none between the predicates. Since no lever can be formulated, the argument is identified as a non sequitur.

**Not to be confused with:**

- [Argument from synonyms](#argument-from-synonyms): The two relations match, and the relation is sameness of meaning. i
- [Argument from opposites](#argument-from-opposites): The two relations match, and the relation is opposition. i
- [Argument from derivatives](#argument-from-derivatives): The two relations match, and one term is formed from the other. i
- [Argument from integratives](#argument-from-integratives): The two relations match, and the relation is part to whole. i

**Source.** Invented example.

### Argument from norm

- **Link**: <https://periodic-table-of-arguments.org/argument-from-norm/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `VV`
- **Lever**: NORM

One judgment of quality is backed with another. The argument works by treating the supporting quality as a standard: whatever has it counts as good, or bad, in the way claimed. You can attack it by refusing the standard — a hearer who thinks a song can be catchy and still be throwaway will not grant that the one quality settles the other.

**Example.** This song is awesome because it’s catchy

**Standardized form.** This song (a) is awesome (X) because this song (a) is catchy (Y).

**Lever formulation.** “Being catchy (Y) is a NORM for being awesome (X)”

**Not to be confused with:**

- [Argument from criterion](#argument-from-criterion): Substance, not lever: there the premise is a description rather than a verdict. VF
- [Argument from instantiation](#argument-from-instantiation): The quality in the premise is a particular case of the one in the conclusion, not a separate standard. INSTANTIATION
- [Argument from disqualifier](#argument-from-disqualifier): The premise takes back part of a label the conclusion denies. DISQUALIFIER
- [Argument from evaluation](#argument-from-evaluation): Substance: the conclusion recommends doing something rather than rating it. PV

**Source.** Source not yet recorded.

### Argument from opposites

- **Link**: <https://periodic-table-of-arguments.org/argument-from-opposites/>
- **Form**: gamma (*a is X because b is Y*)
- **Substance**: `i`
- **Lever**: OPPOSITE

A claim is supported by stating its mirror image. The argument works because the support talks about the opposite thing and says the opposite of it, and the two oppositions line up: if lies start wars, truth starts peace. You can attack it by showing that one of the pairs is not a true opposition, or that the two oppositions do not run parallel.

**Example.** Peace can be started by the truth because war can be started by lies

**Standardized form.** Peace (a) can be started by the truth (X) because war (b) can be started by lies (Y).

**Lever formulation.** “War (b) is the OPPOSITE of peace (a) in an identical way as being started by lies (Y) is the OPPOSITE of being started by the truth (X)”

**Not to be confused with:**

- [Argument from synonyms](#argument-from-synonyms): The matching relation is sameness of meaning. SYNONYMOUS
- [Argument from derivatives](#argument-from-derivatives): One term is formed from the other. DERIVATIVE
- [Argument from integratives](#argument-from-integratives): The relation is part to whole. INTEGRATIVE
- [Non sequitur](#non-sequitur): Substance, not lever: the two relations do not match, so no lever can be formulated. d

**Source.** The example is based on a quotation by Julian Assange.

### Argumentum ad populum

- **Link**: <https://periodic-table-of-arguments.org/argumentum-ad-populum/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `III`
- **Lever**: POPULARLY AUTHORITATIVE

A claim is backed by saying how many people accept it. The argument works because the number of voices is meant to do the work: no one in particular is named, and nothing is offered about what any of them knows. You can attack it by pointing out that widespread belief is not the same as truth — many people have been wrong together — unless some reason is given why the many should be right about this.

**Example.** Many people have said I am the world’s greatest writer of 140 character sentences

**Standardized form.** “I am the world’s greatest writer of 140 character sentences” (q) is acceptable (A) because “I am the world’s greatest writer of 140 character sentences” (q) is said by many people (Z).

**Lever formulation.** “Being said by many people (Z) is POPULARLY AUTHORITATIVE for being acceptable (A)”

**Not to be confused with:**

- [Argument from expert opinion](#argument-from-expert-opinion): A named source, credited with knowing the subject. EPISTEMICALLY AUTHORITATIVE
- [Argument from testimony](#argument-from-testimony): A named source, credited with having been in a position to see. TESTIMONIALLY AUTHORITATIVE
- [Argument from moral authority](#argument-from-moral-authority): A named source, credited with standing to say what is right. MORALLY AUTHORITATIVE
- [Ethotic argument](#ethotic-argument): The arguer offers their own standing rather than other people’s numbers. I

**Source.** A tweet by Donald J. Trump, 24 July 2014.

### Argument from possibility

- **Link**: <https://periodic-table-of-arguments.org/argument-from-possibility/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `PF`
- **Lever**: FEASIBILITY

A course of action is recommended on the ground that it can now be done. The argument works by letting feasibility stand in for desirability: once the obstacle to doing something is gone, the fact that it is within reach is offered as reason enough to do it. You can attack it by insisting that being able to do something is no reason to do it, or by disputing whether it is really feasible at all.

**Example.** We should send astronauts to Mars, because we now have the technology to get them there.

**Standardized form.** Sending astronauts to Mars (a) should be done (X) because sending astronauts to Mars (a) is now technically possible (Y).

**Lever formulation.** “Being now technically possible (Y) is the FEASIBILITY of being done (X)”

**Not to be confused with:**

- [Teleologic argument](#teleologic-argument): The action is recommended as a means to a goal; here no goal is named, only the fact that the action is within reach. TELEOLOGIC MOTIVATION
- [Pragmatic argument](#pragmatic-argument): The action is recommended for what it will bring about, not for being possible. PRAGMATIC MOTIVATION
- [Argument from evaluation](#argument-from-evaluation): Substance, not lever: the premise is a judgment of how worthwhile the action is, not a fact about whether it can be done. PV

**Source.** Invented example.

### Pragmatic argument

- **Link**: <https://periodic-table-of-arguments.org/pragmatic-argument/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `PF`
- **Lever**: PRAGMATIC MOTIVATION

A course of action is argued for or against by predicting what it will lead to. The argument works because a forecast of gain or harm gives a reason to act: if the action brings the good result it should be done, and if it brings the bad one it should not. You can attack it by disputing the forecast, or by insisting that the action should be judged on principle regardless of its results.

**Example.** The government should not introduce a basic income because that will lead to a drop in income for most people

**Standardized form.** Introducing a basic income (a) should not be done (X) because introducing a basic income (a) will lead to a drop in income for most people (Y).

**Lever formulation.** “Leading to a drop in income for most people (Y) is a PRAGMATIC MOTIVATION for not having to be done (X)”

**Not to be confused with:**

- [Argument from principle](#argument-from-principle): Substance: the premise passes a moral verdict on the measure instead of predicting its results. PV
- [Argument from evaluation](#argument-from-evaluation): Substance: the premise rates the activity rather than forecasting what it will bring. PV
- [Deontic argument](#deontic-argument): Substance: the premise states another obligation. PP
- [Teleologic argument](#teleologic-argument): Substance: the premise states an end the actor pursues. PP

**Source.** Source not yet recorded.

### Argument from principle

- **Link**: <https://periodic-table-of-arguments.org/argument-from-principle/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `PV`
- **Lever**: PRINCIPLED MOTIVATION

A course of action is opposed by naming the wrong it would do, or supported by naming the right it would honor. The argument works because a rule or a right is taken to settle the matter on its own, so that the objection would hold even if the consequences turned out well. You can attack it by denying that the rule applies, that the right exists, or that the action really breaches it.

**Example.** New-born children should not be circumcised because that violates their right to self-determination

**Standardized form.** Circumcising new-born children (a) should not be done (X) because circumcising new-born children (a) violates their right to self-determination (Y).

**Lever formulation.** “Violating their right to self-determination (Y) is a PRINCIPLED MOTIVATION for not having to be done (X)”

**Not to be confused with:**

- [Argument from evaluation](#argument-from-evaluation): The premise rates how good the activity is rather than naming a rule or right it breaches. EVALUATIVE MOTIVATION
- [Pragmatic argument](#pragmatic-argument): Substance: the premise predicts a consequence rather than passing a verdict. PF
- [Deontic argument](#deontic-argument): Substance: the premise is itself an obligation. PP
- [Argument from norm](#argument-from-norm): Substance: the conclusion is a verdict rather than a recommendation. VV

**Source.** Source not yet recorded.

### Argument from reciprocity

- **Link**: <https://periodic-table-of-arguments.org/argument-from-reciprocity/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `ss`
- **Lever**: OWES RECIPROCITY

One party is said to owe a second a certain treatment because the second treated the first that way. The argument works on the rule that what is received should be returned: the earlier act creates a debt, and the debt is offered as the reason for the act now being asked for. You can attack it by denying that the earlier act was owed anything in return, or by showing that the debt has already been paid.

**Example.** You should back Maria’s proposal, because she backed yours.

**Standardized form.** You (a) should back the other party’s proposal (X) because Maria (b) backed the other party’s proposal (X).

**Lever formulation.** “You (a) OWE RECIPROCITY to Maria (b) with respect to having to back the other party’s proposal (X)”

**Not to be confused with:**

- [Argument from equality](#argument-from-equality): The two parties are to be treated alike by some third party or rule; here the parties are to treat each other alike. EQUAL
- [Argument from analogy](#argument-from-analogy): The two cases are held to be alike in a relevant respect; here they are not alike but in debt to one another. ANALOGOUS
- [Argument from similarity](#argument-from-similarity): Both statements are statements of fact rather than a policy claim and a fact. F ← F

**Source.** Invented example.

### Argument from sign

- **Link**: <https://periodic-table-of-arguments.org/argument-from-sign/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `FF`
- **Lever**: SIGN

Something is argued to be the case by pointing to a telltale mark that usually goes with it. The argument works because the mark tends to appear when the claim is true, so seeing the one lets you infer the other, even though the mark did not bring the situation about. You can attack it by showing that the mark is not distinctive — that many other things leave the same trace, so it points to nothing in particular.

**Example.** This movie must have been directed by Christopher Nolan because it has a non-linear plot

**Standardized form.** This movie (a) must have been directed by Christopher Nolan (X) because this movie (a) has a non-linear plot (Y).

**Lever formulation.** “Having a non-linear plot (Y) is a SIGN of having been directed by Christopher Nolan (X)”

**Not to be confused with:**

- [Argument from cause](#argument-from-cause): The premise names what produced the state in the conclusion, rather than a mark of it. CAUSE
- [Argument from effect](#argument-from-effect): The premise names what the state in the conclusion produced. EFFECT
- [Argument from correlation](#argument-from-correlation): The two features are merely found together; neither is offered as an indicator of the other. CORRELATION
- [Argument from criterion](#argument-from-criterion): Substance, not lever: the conclusion is a verdict rather than a matter of fact. VF

**Source.** Invented example.

### Argument from similarity

- **Link**: <https://periodic-table-of-arguments.org/argument-from-similarity/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `ss`
- **Lever**: SIMILAR

What may happen to one thing is stated by reporting what actually happened to another thing of the same sort. The argument works because the earlier case did turn out this way, and the present case is held to be enough like it for the same outcome to be open. You can attack it by showing that the two cases differ in whatever made the earlier outcome possible.

**Example.** It is possible that the Tories will recover from their bad position because Labour recovered from their bad position in 2019

**Standardized form.** The Tories (a) can possibly recover from their bad position (X) because Labour in 2019 (b) recovered from their bad position (X).

**Lever formulation.** “The Tories (a) are SIMILAR to Labour in 2019 (b) with respect to possibly recovering from their bad position (X)”

**Not to be confused with:**

- [Argument from analogy](#argument-from-analogy): The likeness is one of relations: elements of the one case stand to each other as elements of the other case do, rather than the two cases sharing the properties that make the outcome possible. ANALOGOUS
- [Argument from comparison](#argument-from-comparison): The two cases are set side by side and measured against each other, rather than one being taken as a precedent for the other. COMPARABLE
- [Argument from equality](#argument-from-equality): The two cases are claimed to be entitled to the same treatment, not merely to be alike. EQUAL
- [Metaphoric argument](#metaphoric-argument): The second case is not a real comparable at all but a figure of speech. METAPHORICALLY

**Source.** Adapted from an article in The Guardian. The article is not identified on the type page; full citation not yet recorded.

### Argument from species

- **Link**: <https://periodic-table-of-arguments.org/argument-from-species/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `up`
- **Lever**: A SPECIES OF

A claim about a whole class is supported by pointing to one kind within it. The argument works by carrying what holds of that kind up to the class — unlike an argument from example, the support is not a single individual but a sub-group, humans, say, as one kind of animal. You can attack it by showing that the chosen kind is exactly the one least fit to speak for the rest.

**Example.** All animals are able to feel pain because humans are able to feel pain

**Standardized form.** All animals (a) are able to feel pain (X) because humans (b) are able to feel pain (X).

**Lever formulation.** “Humans (b) are a SPECIES of all animals (a) with respect to being able to feel pain (X)”

**Not to be confused with:**

- [Argument from example](#argument-from-example): The premise is a single individual offered as a specimen, not a kind within the class. us
- [Argument from genus](#argument-from-genus): Runs the other way, from the wider kind down to the narrower one. pu
- [Argument from composition](#argument-from-composition): The premise is the complete set of parts making up the thing in the conclusion, not a kind within a kind. COMPOSED OF

**Source.** Source not yet recorded.

### Argument from subsumption

- **Link**: <https://periodic-table-of-arguments.org/argument-from-subsumption/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `VF`
- **Lever**: SUBSUMPTION

A general label is applied to a case by pointing out that the case already has a more specific name of its own. The argument works because the specific thing is one of the things the general label covers, so membership alone carries the label across, without the general term having to be spelled out in full. You can attack it by accepting the specific description and denying that it belongs under the general term.

**Example.** These prisoners have been subjected to torture because they have been subjected to waterboarding

**Standardized form.** These prisoners (a) have been subjected to torture (X) because these prisoners (a) have been subjected to waterboarding (Y).

**Lever formulation.** “Having been subjected to waterboarding (Y) can be SUBSUMED under having been subjected to torture (X)”

**Not to be confused with:**

- [Argument from definition](#argument-from-definition): The premise gives the meaning of the term as a whole, not one case that falls under it. DEFINITION
- [Argument from criterion](#argument-from-criterion): The premise supplies a standard for a judgment of quality. CRITERION
- [Argument from instantiation](#argument-from-instantiation): Substance, not lever: there the premise is itself a verdict rather than a description. VV

**Source.** Source not yet recorded.

### Argument from synonyms

- **Link**: <https://periodic-table-of-arguments.org/argument-from-synonyms/>
- **Form**: gamma (*a is X because b is Y*)
- **Substance**: `i`
- **Lever**: SYNONYMOUS

A claim is supported by saying it again in other words. The argument works because the support talks about something differently named and says something differently phrased about it, yet each is merely another way of putting what the claim already said, so accepting the one means accepting the other. You can attack it by pointing out that the support adds no independent reason to believe the claim, so the reasoning goes round in a circle.

**Example.** Freedom of speech is important because being able to say what you want is crucial

**Standardized form.** Freedom of speech (a) is important (X) because being able to say what you want (b) is crucial (Y).

**Lever formulation.** “Being able to say what you want (b) is SYNONYMOUS with freedom of speech (a) in an identical way as crucial (Y) is SYNONYMOUS with important (X)”

**Not to be confused with:**

- [Argument from opposites](#argument-from-opposites): The matching relation is opposition rather than sameness of meaning. OPPOSITE
- [Argument from derivatives](#argument-from-derivatives): One term is formed from the other. DERIVATIVE
- [Argument from integratives](#argument-from-integratives): The relation is part to whole. INTEGRATIVE
- [Non sequitur](#non-sequitur): Substance, not lever: the two relations do not match, so no lever can be formulated. d

**Source.** Source not yet recorded.

### Teleologic argument

- **Link**: <https://periodic-table-of-arguments.org/teleologic-argument/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `PP`
- **Lever**: TELEOLOGIC MOTIVATION

A course of action is recommended as a means to a goal the actor is already pursuing. The argument works because the goal is already wanted, so any action that serves it inherits that wanting: this is what the actor is trying to achieve, so this is what the actor should do. You can attack it by showing that the action is not a good route to the goal, or that a better route exists.

**Example.** The University of Amsterdam should invest in AI research because it should foster innovation

**Standardized form.** The University of Amsterdam (a) should invest in AI research (X) because the University of Amsterdam (a) should foster innovation (Y).

**Lever formulation.** “Having to foster innovation (Y) is a TELEOLOGIC MOTIVATION for having to invest in AI research (X)”

**Not to be confused with:**

- [Deontic argument](#deontic-argument): The premise expresses an obligation owed rather than an end pursued. DEONTIC MOTIVATION
- [Pragmatic argument](#pragmatic-argument): Substance: the premise forecasts what the action will bring about. PF
- [Argument from principle](#argument-from-principle): Substance: the premise passes a moral verdict on the action. PV
- [Argument from evaluation](#argument-from-evaluation): Substance: the premise rates the activity as worth doing. PV

**Source.** Source not yet recorded.

### Argument from testimony

- **Link**: <https://periodic-table-of-arguments.org/argument-from-testimony/>
- **Form**: delta (*q is A because q is Z*)
- **Substance**: `III`
- **Lever**: TESTIMONIALLY AUTHORITATIVE

A claim about what happened is backed by someone who was there and says so. The argument works because the source is credited not with expertise but with a place at the scene: they were in a position to see or hear it, so their report stands in for the event itself. You can attack it by questioning whether the witness really had that position, saw clearly, and remembers accurately.

**Example.** The blue van went through the red light; the woman waiting at the bus stop on the corner saw the whole thing

**Standardized form.** “The blue van went through the red light” (q) is acceptable (A) because “the blue van went through the red light” (q) is said by the woman who was waiting at the bus stop on the corner (Z).

**Lever formulation.** “Being said by the woman who was waiting at the bus stop on the corner (Z) is TESTIMONIALLY AUTHORITATIVE for being acceptable (A)”

**Not to be confused with:**

- [Argument from expert opinion](#argument-from-expert-opinion): The source is credited with knowing the subject, not with having been present. EPISTEMICALLY AUTHORITATIVE
- [Argument from moral authority](#argument-from-moral-authority): The source is credited with standing to say what is right. MORALLY AUTHORITATIVE
- [Argumentum ad populum](#argumentum-ad-populum): Authority is a matter of numbers, not of who saw what. POPULARLY AUTHORITATIVE
- [Ethotic argument](#ethotic-argument): The arguer vouches for their own claim. I

**Source.** Invented example.

### Argument from totality

- **Link**: <https://periodic-table-of-arguments.org/argument-from-totality/>
- **Form**: beta (*a is X because b is X*)
- **Substance**: `su`
- **Lever**: BELONGS TO THE TOTALITY OF

A claim about one case is supported by pointing to the larger body it belongs to. The argument works by handing down what is said of the collection to the single item: Greek salad is healthy because Mediterranean food is. You can attack it by showing that this particular case is an exception to what holds of the whole.

**Example.** Greek salad is healthy because Mediterranean food is healthy

**Standardized form.** Greek salad (a) is healthy (X) because Mediterranean food (b) is healthy (X).

**Lever formulation.** “Greek salad (a) belongs to the TOTALITY of Mediterranean food (b) with respect to being healthy (X)”

**Not to be confused with:**

- [Argument from genus](#argument-from-genus): The conclusion is about a kind within the class, not about one individual member of it. pu
- [Argument from example](#argument-from-example): Runs the other way, from one case up to the whole class. us
- [Argument from division](#argument-from-division): The conclusion is the complete set of parts of the thing in the premise, not one member of a collection. A PART OF

**Source.** Source not yet recorded.

### Argument from waste

- **Link**: <https://periodic-table-of-arguments.org/argument-from-waste/>
- **Form**: alpha (*a is X because a is Y*)
- **Substance**: `PF`
- **Lever**: PRIOR INVESTMENT

Something is said to deserve carrying on because so much has already been put into it. The argument works by treating the earlier investment as a reason in itself: to stop now would throw away what has been spent, so the spending is offered as a ground for continuing. You can attack it by pointing out that what has already been spent cannot be recovered whatever is decided, so it says nothing about whether continuing is worth it.

**Example.** We must finish the tunnel, because we have already spent two billion on it.

**Standardized form.** The tunnel (a) must be finished (X) because the tunnel (a) has already cost two billion (Y).

**Lever formulation.** “Having already cost two billion (Y) is a PRIOR INVESTMENT in being finished (X)”

**Not to be confused with:**

- [Pragmatic argument](#pragmatic-argument): Looks forward to what the action will bring about; this argument looks back to what it has already cost. PRAGMATIC MOTIVATION
- [Teleologic argument](#teleologic-argument): The action is recommended as a means to a goal that is still wanted, not because of resources already spent. TELEOLOGIC MOTIVATION
- [Deontic argument](#deontic-argument): Substance, not lever: the premise is itself an obligation, not a fact about expenditure. PP

**Source.** Invented example.
