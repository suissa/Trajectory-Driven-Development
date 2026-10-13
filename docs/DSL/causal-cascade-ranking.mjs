import { analyzeCausalPaths } from "./trajectory-causal-paths.mjs";

/**
 * Rank structural root-cause candidates from candidate-causal paths.
 * Scores are observational heuristics, not intervention-based causal effects.
 */
export function rankCausalCascadeCandidates(graph, options = {}) {
  const analysis = analyzeCausalPaths(graph, options);
  const minScore = Number(options.minScore ?? 0);
  const candidates = analysis.rootCauseCandidates.map(candidate => {
    const paths = analysis.paths.filter(path =>
      path.nodes[0] === candidate.node && path.terminalType === "divergence"
    );
    const bestPath = [...paths].sort((a, b) =>
      b.pathScore - a.pathScore || b.support - a.support || b.depth - a.depth ||
      a.nodes.join("->").localeCompare(b.nodes.join("->"))
    )[0];
    const outcomes = [...new Set(paths.map(path => path.nodes.at(-1)))].sort();
    const maxDepth = paths.reduce((max, path) => Math.max(max, path.depth), 0);
    const coverage = analysis.divergencePoints.length
      ? new Set(paths.map(path => path.nodes.at(-1))).size / analysis.divergencePoints.length
      : 0;
    // Transparent heuristic: edge association strength, support, reach and cascade depth.
    const score = bestPath
      ? bestPath.pathScore * bestPath.support * (1 + Math.log1p(outcomes.length)) *
        (1 + Math.log1p(maxDepth)) * (1 + coverage)
      : 0;
    return {
      node: candidate.node,
      score,
      bestPathScore: bestPath?.pathScore ?? 0,
      support: bestPath?.support ?? 0,
      maxDepth,
      reachableDivergences: outcomes,
      divergenceCoverage: coverage,
      bestPath: bestPath?.nodes ?? [],
      interpretation: "structural-root-candidate"
    };
  }).filter(candidate => candidate.score >= minScore);

  candidates.sort((a, b) => b.score - a.score ||
    b.bestPathScore - a.bestPathScore || b.support - a.support || a.node.localeCompare(b.node));

  return {
    version: 1,
    scoring: "observational-heuristic-v1",
    causalProof: false,
    candidateCount: candidates.length,
    candidates
  };
}
