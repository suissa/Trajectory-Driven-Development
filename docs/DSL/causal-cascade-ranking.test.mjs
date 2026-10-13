import assert from "node:assert/strict";
import test from "node:test";
import { rankCausalCascadeCandidates } from "./causal-cascade-ranking.mjs";

const graph = {
  nodes: [
    { id: "evidence:root", type: "evidence", value: "root" },
    { id: "skill:middle", type: "skill", value: "middle" },
    { id: "divergence:failure-a", type: "divergence", value: "failure-a" },
    { id: "divergence:failure-b", type: "divergence", value: "failure-b" },
    { id: "evidence:other", type: "evidence", value: "other" }
  ],
  edges: [
    { id: "1", from: "evidence:root", to: "skill:middle", support: 0.8, lift: 3 },
    { id: "2", from: "skill:middle", to: "divergence:failure-a", support: 0.6, lift: 2 },
    { id: "3", from: "evidence:root", to: "divergence:failure-b", support: 0.5, lift: 1.5 },
    { id: "4", from: "evidence:other", to: "divergence:failure-a", support: 0.4, lift: 1.1 }
  ]
};

test("ranks root candidates by cascade evidence and exposes the scoring contract", () => {
  const result = rankCausalCascadeCandidates(graph, { maxDepth: 4 });
  assert.equal(result.causalProof, false);
  assert.equal(result.scoring, "observational-heuristic-v1");
  assert.equal(result.candidates[0].node, "evidence:root");
  assert.deepEqual(result.candidates[0].reachableDivergences, [
    "divergence:failure-a", "divergence:failure-b"
  ]);
  assert.ok(result.candidates[0].bestPath.length >= 2);
});

test("supports filtering by minimum heuristic score", () => {
  const all = rankCausalCascadeCandidates(graph);
  const filtered = rankCausalCascadeCandidates(graph, { minScore: all.candidates[0].score + 1 });
  assert.ok(filtered.candidateCount < all.candidateCount);
});
