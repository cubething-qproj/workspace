# AIF node types

Quick reference for the Argument Interchange Format (AIF) and its dialogue
extension AIF+, as used by Inference Anchoring Theory (IAT). For comparison
with note-lab's annotation schema (`misc/labs/nlp/inception/layers.json`).

An AIF graph is directed. Edges connect an I-node to an S-node or one S-node to
another, **never I-node to I-node directly**: every relation between two
propositions goes through an S-node.

## Core AIF

| Node | Family | Stands for | Typical edges | note-lab equivalent |
| ---- | ------ | ---------- | ------------- | ------------------- |
| I-node | Information | A proposition (claim, premise, conclusion). Content only, no stance. | In from / out to S-nodes. A premise has no incoming RA; a conclusion is the target of one. | `Argument` span |
| RA | S-node (scheme application) | Inference: premises support a conclusion. May fulfil a named argumentation scheme (Walton etc.). | Several premise I-nodes → RA → one conclusion I-node. Several inputs = linked premises; several RAs into one I-node = convergent support. | `ArgumentRelation` `label: inference`; linked premises share `group` |
| CA | S-node | Conflict: one node attacks another. | I-node → CA → I-node (rebut), or I-node → CA → RA (undercut: attacks the inference). | `label: conflict`; `kind` approximates undercut, since our edges can't target edges |
| PA | S-node | Preference: one node is preferred over another. | I/S-node → PA → I/S-node. | none |
| MA | S-node | Rephrase: one proposition restates another. Added after the original AIF, used by IAT. | I-node → MA → I-node. | `label: rephrase` |
| F-node | Form | A scheme definition: the general pattern an S-node fulfils (premise and conclusion descriptors, presumptions, exceptions). Part of the ontology, not of a particular argument. | S-node *fulfils* F-node. | none (would be our strategy types) |

## AIF+ / IAT (dialogue)

| Node | Family | Stands for | Typical edges | note-lab equivalent |
| ---- | ------ | ---------- | ------------- | ------------------- |
| L-node | I-node subtype (locution) | A speech act as it happened: who said what ("Quine says: …"). | Connected to other L-nodes by TA; anchored to content via YA. | partly `voice` |
| TA | S-node (transition) | Dialogue transition: how one locution follows another (reply, response). | L-node → TA → L-node. | none |
| YA | S-node (illocutionary) | Illocutionary force: asserting, questioning, challenging, arguing, agreeing, disagreeing, restating, … Anchors the dialogue to the argument. | L-node → YA → I-node; TA → YA → RA/CA/MA. | partly `Move` layer |

## Sources

- Chesñevar et al. "Towards an Argument Interchange Format." *Knowledge
  Engineering Review* 21(4), 2006. Core AIF: I-nodes, RA/CA/PA.
- Rahwan et al. "On Building Argumentation Schemes Using the Argument
  Interchange Format." 2007. F-nodes and the RDF/OWL ontology (AIF-RDF).
- Reed, Wells, Devereux, Rowe. "AIF+: Dialogue in the Argument Interchange
  Format." COMMA 2008. L-nodes, TA, YA.
- ARG-tech. Inference Anchoring Theory guidelines, 2023.
  <https://github.com/arg-tech/aif-arg-datasets/blob/main/docs_add_info/IAT_guidelines_and_tutorials-2023-10.pdf>
