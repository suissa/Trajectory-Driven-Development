# Trajectory-Driven DSL

## 1. Purpose

The Trajectory-Driven DSL (T-DD-DSL) is the declarative notation of Trajectory-Driven Development (T-DD).

It describes, with progressively precise semantics:

- destiny;
- intent;
- required information;
- behavior;
- state;
- actors and authorization;
- skills;
- evidence;
- constraints and forbidden scenarios;
- trajectory;
- implementation conformance.

The DSL is a specification language, not an implementation language. It does not prescribe TypeScript, Python, HTTP, databases, queues, frameworks, agents, or control-flow algorithms.

The central judgment is:

`implementation ⊨ trajectory ⊨ behavior ⊨ intent ⊨ destiny`

The implementation must satisfy the declared semantics. It must not redefine the declaration to fit its own behavior.

## 2. Specification order

The semantic refinement order is:

`DESTINY → INTENT → REQUIRED → BEHAVIOR → STATE → ACTOR → SKILL → EVIDENCE → CONSTRAINT → TRAJECTORY → DSL → IMPLEMENTATION`

Each layer adds specificity. A later layer may constrain an earlier layer, but must not contradict an earlier mandatory commitment.

The order answers:

- DESTINY: why;
- INTENT: what is requested;
- REQUIRED: what must be known;
- BEHAVIOR: what must happen;
- STATE: where the trajectory is;
- ACTOR: who may act;
- SKILL: which capability establishes a semantic change;
- EVIDENCE: what proves it;
- CONSTRAINT: what must or must not be true;
- TRAJECTORY: how the facts relate through time;
- DSL: how all of this is written compactly;
- IMPLEMENTATION: how a concrete program realizes it.

## 3. Minimal complete example

```text
@delivery

D: delivery → requested paid assigned tracked delivered settled
I: customer → deliver
R: pickup + dropoff

B: request
→ collect
→ discover(courier*)
→ select(min distance)
→ charge
→ confirm
→ release
→ track*
→ validate(code)
→ settle

S: requested
→ collecting
→ searching
→ assigned
→ awaiting_payment
→ paid
→ active
→ arriving
→ delivered
→ settled

A:
  customer { request address pay code }
  system   { classify collect discover select charge validate route settle }
  courier  { accept locate deliver }
  payment  { confirm reject }

E: request.received
→ intent.recognized
→ addresses.collected
→ courier.selected
→ payment.confirmed
→ delivery.released
→ location.received*
→ location.forwarded*
→ code.validated
→ settlement.completed

X:
  ¬ release(payment ≠ confirmed)
  ¬ settle(code ≠ valid)
  ¬ settle(location ≠ dropoff)
  ¬ select(courier ∉ available)
```

## 4. Lexical model

The language contains declarations, identifiers, operators, grouping, qualifiers, and annotations.

|D:  |     declaration|
----------------------
| delivery | identifier|
| →        | operator| 
| pickup + dropoff   | composition| 
| select(min distance) | parameterized semantic operation| 
| customer { ... }   | capability set| 
| @delivery          | annotation| 

Whitespace is insignificant except for token separation. Identifiers are case-sensitive. Reserved words and canonical aliases are defined in RESERVED-WORDS.md.

## 5. Semantics must precede syntax

The language is designed so that a reader can understand every symbol before seeing the complete DSL.

The core operators are:

`→` succession;
`+` required composition;
`∧` logical conjunction;
`¬` logical negation;
`=` equality/binding;
`≠` inequality;
`*` zero-or-more repetition;
`∈` membership;
`∉` non-membership;
`⊨` satisfaction/conformance.

Their normative definitions are in SYMBOLS.md.

## 6. Static validity

Parsing only proves structural validity. Semantic validation must additionally prove that:

- names resolve;
- states exist;
- actors exist;
- capabilities are authorized;
- skills reference valid inputs and outputs;
- evidence is declared;
- constraints are meaningful;
- transitions are legal;
- cardinalities are valid;
- the specification is internally consistent;
- at least one conforming trajectory is possible.

A DSL can therefore be syntactically valid but semantically invalid.

## 7. Runtime conformance

Runtime conformance evaluates observed evidence against the declared trajectory.

The validator must be able to answer:

```text
who acted?
what happened?
in which state?
through which skill?
with which evidence?
under which constraints?
what state followed?
```

The trajectory is the semantic history. Logs are only one possible physical source of evidence.

## 8. Canonical pipeline

```text
source
→ parse
→ AST
→ resolve
→ validate
→ normalize
→ project
→ execute
→ observe
→ compare
→ conformance
```

The parser must not execute business behavior.

The validator must not silently repair semantic contradictions.

The projection must not introduce domain semantics that are absent from the DSL.

## 9. Language independence

The same DSL is projected into TypeScript and Python.

The projection rule is:

`meaning(DSL) = meaning(TypeScript) = meaning(Python)`

Syntax may differ because each language has different type and runtime mechanisms. Semantic obligations may not differ.

See:

- 2typescript/SKILL.md
- 2python/SKILL.md

## 10. Design invariant

The shortest DSL is preferred only after the semantics are complete.

Compression must remove syntactic noise, never semantic information.

The fundamental development loop is:

`DESTINY → INTENT → BEHAVIOR → EVIDENCE → CONTRACT → STATE → ACTOR → SKILL → TRAJECTORY → DSL → IMPLEMENT → EXECUTE → OBSERVE → COMPARE ↺`


## 11. Compiler pipeline

The repository provides a deterministic reference compiler:

```
.tddl source
→ parse
→ AST
→ name/shape/semantic validation
→ normalized AST
→ TypeScript or Python projection
→ language classification
→ runtime tests
→ conformance
```

The canonical delivery source is `examples/delivery.tddl`. The compiler is `docs/DSL/compiler.mjs`.

The compiler must fail closed. It must never emit a successful projection after a syntax or semantic error.

Validation diagnostics use stable `T-DD-DSL_*` identities. Examples include:

- `T-DD-DSL_SYNTAX_*`: malformed DSL structure;
- `T-DD-DSL_*_RESOLUTION`: unresolved semantic name;
- `T-DD-DSL_STATE_*`: invalid state graph;
- `T-DD-DSL_INVALID_EVIDENCE`: malformed evidence identity;
- `T-DD-DSL_INVALID_BEHAVIOR`: malformed behavior term;
- `T-DD-DSL_ACTOR_RESOLUTION`: undeclared intent actor;
- `T-DD-DSL_TARGET`: unsupported projection target.

CI must test both failure and success paths, regenerate the projection from source, execute it, and regenerate again to prove deterministic output.

## 12. Semantic constraint compilation

The generated IR exposes the normalized Constraint AST as a first-class semantic artifact.

The reference compiler now treats X as a semantic language rather than an opaque string. Constraints are parsed into a normalized Boolean AST, checked for proven contradictions, and preserved in the generated semantic IR. This establishes a boundary between syntax validity, static semantic invalidity, and runtime conformance.

The current static checker is deliberately conservative: it rejects contradictions it can prove locally and rejects malformed expressions, while leaving general theorem proving and arbitrary satisfiability to a future formal backend.


## 13. Semantic Skills

A K declaration is a semantic unit, not merely a function signature. Its core relation is input → rule → output → evidence. Optional pre, post, when, from, to, requires, ensures, allows, and forbids fields refine that semantic unit. Constraint-bearing fields use the same grammar as X. When from and to are present, the compiler verifies that the transition exists in S; emitted evidence must exist in both E and T.

The compiler preserves these semantics in skill_semantics and exposes them to TypeScript and Python projections.

Semantic shape: precondition → authorization → input → rule → state transition → postcondition → evidence.

## 14. Trajectory proof

Runtime Skill conformance is the local proof obligation for one semantic transition. Trajectory proof composes those local proofs into a proof of the declared execution path.

The reference projections expose `proveTrajectory` / `prove_trajectory`. A trajectory proof requires:

- every observed Skill execution to conform locally;
- state transitions to remain legal;
- preconditions and postconditions to hold using accumulated trajectory facts;
- emitted evidence to belong to E and remain ordered according to T;
- every mandatory evidence item to be observed;
- the execution to reach the terminal state of S.

The resulting judgment is:

`observed trajectory ⊨ declared trajectory ⊨ intent`

This is stronger than validating isolated events. The proof carries facts forward between Skills, so an evidence item established by one Skill can satisfy the precondition of the next Skill.

The delivery example now declares a complete Skill chain from `requested` to `settled`, making the end-to-end proof executable in both TypeScript and Python.


## 15. Formal Trajectory Proof Artifact

A successful or failed trajectory proof can be materialized as a persistible, language-neutral artifact through `createTrajectoryProof` / `create_trajectory_proof`.

The artifact identifies the semantic declaration independently of a runtime process:

```text
TrajectoryID = identity of the declared trajectory
Behavior   = the semantic behavior being realized
```

The reference compiler derives a deterministic TrajectoryID from the normalized trajectory declaration. Behavior remains semantic content, not a separate identity in this artifact.

The artifact records:

- `version`;
- `conformant`;
- `trajectoryId` / `trajectory_id`;
- `behavior` / `behavior`;
- intent;
- start and end timestamps when runtime provenance supplies them;
- per-step provenance (`timestamp`, `source`, `sequence`);
- observed states;
- executed Skills;
- observed evidence;
- the first divergence, when conformance fails.

The first divergence is authoritative. It contains a stable diagnostic code, execution step, optional Skill, expected value, observed value, and diagnostic message. Later failures are not allowed to replace the first semantic divergence.

The artifact therefore changes the proof model from:

```text
execution → boolean conformance
```

to:

```text
execution
→ proof
→ identity
→ temporal provenance
→ first divergence
→ persistible evidence
```

The resulting relation is:

```text
ProofArtifact
  ⊨ TrajectoryID
  ⊨ Behavior
  ⊨ Intent
```

This is the foundation for later integration with trajectory history, Behavior/TrajectoryID indexing, causal analysis, and replay without coupling the DSL compiler to a particular observability backend.


## 16. Proof artifact persistence and replay

The formal trajectory proof artifact is now a portable persistence boundary.

The reference projections expose:

- `serializeTrajectoryProof` / `serialize_trajectory_proof`;
- `deserializeTrajectoryProof` / `deserialize_trajectory_proof`;
- `replayTrajectoryProof` / `replay_trajectory_proof`.

Serialization preserves the proof artifact as a language-neutral JSON representation. Deserialization is fail-closed: the artifact version and its `TrajectoryID` and `Behavior` must match the current semantic declaration.

Replay executes the same conformance proof against a new observation sequence and verifies that the resulting semantic identity and observed Skill/evidence sequence remain compatible with the persisted artifact.

The persistence model is therefore:

```text
execution
  ↓
proof artifact
  ↓
serialize
  ↓
persist
  ↓
deserialize
  ↓
replay
  ↓
semantic comparison
```

This deliberately keeps persistence independent from a database, event store, telemetry vendor, or observability backend.

The important invariant is:

```text
persisted ProofArtifact
  ⊨ current TrajectoryID
  ⊨ current Behavior
  ⊨ replayed trajectory
```

An artifact from a different semantic declaration must not silently replay against the current declaration. This establishes the integrity boundary required before introducing trajectory history and cross-execution causal analysis.


## 17. Trajectory History

The Proof Artifact represents one observed execution. Trajectory History aggregates multiple Proof Artifacts without coupling the semantic model to a database or observability backend.

The reference projections expose:

- `createTrajectoryHistory` / `create_trajectory_history`;
- `appendTrajectoryHistory` / `append_trajectory_history`;
- `queryTrajectoryHistory` / `query_trajectory_history`;
- `compareTrajectoryProofs` / `compare_trajectory_proofs`.

A history record preserves the declared `TrajectoryID`, the declared `Behavior`, temporal provenance, conformance, and the complete Proof Artifact. The history assigns a local monotonically increasing record identifier; this is a history position, not a semantic identity.

The first implementation supports in-memory append-only history and queries by:

- TrajectoryID;
- time interval using start/end provenance;
- conformance status.

Comparison is semantic rather than byte-oriented. Two proofs are compared across TrajectoryID, Behavior, states, Skills, and evidence, returning the first dimension that differs.

The model is:

```text
Proof Artifact
      ↓
Trajectory History
      ├── record
      ├── record
      ├── record
      └── ...
           ↓
       temporal query
           ↓
       comparison
           ↓
    behavioral analysis
```

The important distinction is:

```text
Behavior   = what semantic behavior is being realized
Trajectory = how that behavior evolves through states/evidence
Record     = one occurrence stored in history
```

Trajectory History therefore provides the temporal memory layer needed before causal analysis, trajectory clustering, anomaly detection, and predictive behavior analysis. It intentionally keeps Behavior as semantic content and leaves identity concerns outside this layer.
