# Causal Cascade and Root-Cause Candidate Ranking

T-DD adds a ranking layer on top of the multi-hop candidate-causal graph. It combines path strength, minimum support, path depth, and the fraction of observed divergence outcomes reachable from a source candidate.

## Pipeline

Trajectory History -> Candidate Causal Analysis -> Causal Trajectory Graph -> Multi-Hop Paths -> Cascade Candidate Ranking.

## API

JavaScript:

`rankCausalCascadeCandidates(graph, { maxDepth: 4, minScore: 0 })`

Python:

`rank_causal_cascade_candidates(graph, max_depth=4, min_score=0.0)`

## Ranking heuristic

For each source node with a candidate path to one or more divergence nodes, the score is:

`bestPathScore × bestPathSupport × (1 + ln(1 + reachableOutcomes)) × (1 + ln(1 + maxDepth)) × (1 + divergenceCoverage)`

`bestPathScore` is the minimum lift along the selected path; `bestPathSupport` is the minimum edge support. `divergenceCoverage` is the number of distinct reachable divergence outcomes divided by the number of divergence nodes in the graph.

This score is a deterministic prioritization heuristic, not a probability. It is not normalized across graphs, and should not be compared across unrelated datasets without calibration. Use `minScore` to filter low-ranked candidates when appropriate.

## Output

Each candidate includes its score, best path score, support, maximum path depth, reachable divergence nodes, divergence coverage, and best path. Output explicitly declares `causalProof: false` / `causal_proof: false`.

## Interpretation and limits

The ranking helps decide which upstream nodes deserve investigation first. It does not prove that a node caused an outcome. Observational event sequences can contain confounding, omitted events, selection effects, and delayed dependencies. Stronger causal claims require additional assumptions and validation, such as domain constraints, held-out predictive tests, interventions, counterfactual analysis, or known-ground-truth benchmarks. See the work on event-sequence causal discovery and root-cause evaluation for examples of those distinctions: https://proceedings.neurips.cc/paper_files/paper/2024/hash/2b22bacd7ad8677f4837b28a11fe496f-Abstract-Conference.html and https://github.com/phamquiluan/RCAEval.
