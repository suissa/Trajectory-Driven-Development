import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from causal_cascade_ranking import rank_causal_cascade_candidates

GRAPH = {
    "nodes": [
        {"id": "evidence:root", "type": "evidence", "value": "root"},
        {"id": "skill:middle", "type": "skill", "value": "middle"},
        {"id": "divergence:failure-a", "type": "divergence", "value": "failure-a"},
        {"id": "divergence:failure-b", "type": "divergence", "value": "failure-b"},
        {"id": "evidence:other", "type": "evidence", "value": "other"},
    ],
    "edges": [
        {"id": "1", "from": "evidence:root", "to": "skill:middle", "support": 0.8, "lift": 3},
        {"id": "2", "from": "skill:middle", "to": "divergence:failure-a", "support": 0.6, "lift": 2},
        {"id": "3", "from": "evidence:root", "to": "divergence:failure-b", "support": 0.5, "lift": 1.5},
        {"id": "4", "from": "evidence:other", "to": "divergence:failure-a", "support": 0.4, "lift": 1.1},
    ],
}


class TestCausalCascadeRanking(unittest.TestCase):
    def test_ranks_and_labels_candidates_as_heuristic(self):
        result = rank_causal_cascade_candidates(GRAPH)
        self.assertFalse(result["causal_proof"])
        self.assertEqual(result["scoring"], "observational-heuristic-v1")
        self.assertEqual(result["candidates"][0]["node"], "evidence:root")
        self.assertEqual(result["candidates"][0]["reachable_divergences"], (
            "divergence:failure-a", "divergence:failure-b"
        ))

    def test_min_score_filter(self):
        all_candidates = rank_causal_cascade_candidates(GRAPH)
        filtered = rank_causal_cascade_candidates(
            GRAPH, min_score=all_candidates["candidates"][0]["score"] + 1
        )
        self.assertLess(filtered["candidate_count"], all_candidates["candidate_count"])


if __name__ == "__main__":
    unittest.main()
