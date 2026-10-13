"""Rank structural root-cause candidates from candidate-causal paths."""

import math

from trajectory_causal_paths import analyze_causal_paths


def rank_causal_cascade_candidates(graph, max_depth=4, min_path_depth=1, min_score=0.0):
    analysis = analyze_causal_paths(graph, max_depth=max_depth, min_path_depth=min_path_depth)
    divergence_count = len(analysis["divergence_points"])
    candidates = []
    for candidate in analysis["root_cause_candidates"]:
        paths = [
            path for path in analysis["paths"]
            if path["nodes"][0] == candidate["node"] and path["terminal_type"] == "divergence"
        ]
        paths.sort(key=lambda path: (
            -path["path_score"], -path["support"], -path["depth"], "->".join(path["nodes"])
        ))
        best = paths[0] if paths else None
        outcomes = tuple(sorted({path["nodes"][-1] for path in paths}))
        max_path_depth = max((path["depth"] for path in paths), default=0)
        coverage = len(outcomes) / divergence_count if divergence_count else 0.0
        score = (
            best["path_score"] * best["support"]
            * (1 + math.log1p(len(outcomes)))
            * (1 + math.log1p(max_path_depth))
            * (1 + coverage)
            if best else 0.0
        )
        if score < float(min_score):
            continue
        candidates.append({
            "node": candidate["node"],
            "score": score,
            "best_path_score": best["path_score"] if best else 0.0,
            "support": best["support"] if best else 0.0,
            "max_depth": max_path_depth,
            "reachable_divergences": outcomes,
            "divergence_coverage": coverage,
            "best_path": best["nodes"] if best else (),
            "interpretation": "structural-root-candidate",
        })
    candidates.sort(key=lambda item: (
        -item["score"], -item["best_path_score"], -item["support"], item["node"]
    ))
    return {
        "version": 1,
        "scoring": "observational-heuristic-v1",
        "causal_proof": False,
        "candidate_count": len(candidates),
        "candidates": tuple(candidates),
    }
