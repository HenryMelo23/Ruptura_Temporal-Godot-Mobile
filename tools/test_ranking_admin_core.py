#!/usr/bin/env python3

import unittest

from ranking_admin_core import (
    ModerationError,
    add_synthetic_run,
    moderate_player_store,
    moderate_run_store,
    moderate_security_ip,
    synthetic_ranking_score,
)


class RankingAdminCoreTests(unittest.TestCase):
    def setUp(self):
        self.store = {
            "runs": [
                {
                    "id": "run-a",
                    "player": "Jogador A",
                    "profileId": "profile-a",
                    "rankEligible": False,
                    "suspicious": True,
                    "suspicionReasons": ["signature_mismatch"],
                    "score": 0,
                },
                {
                    "id": "run-b",
                    "player": "Jogador A",
                    "profileId": "profile-a",
                    "rankEligible": True,
                    "suspicious": False,
                    "suspicionReasons": [],
                    "score": 4000,
                },
                {
                    "id": "run-c",
                    "player": "Jogador B",
                    "profileId": "profile-b",
                    "rankEligible": True,
                    "suspicious": False,
                    "suspicionReasons": [],
                    "score": 5000,
                },
            ],
            "profiles": {},
        }

    def test_release_false_positive_and_restore_automatic(self):
        run = moderate_run_store(self.store, "run-a", "released", "teste validado", "Henrique", "2026-11-05T12:00:00Z")
        self.assertTrue(run["rankEligible"])
        self.assertFalse(run["suspicious"])
        self.assertEqual(run["suspicionReasons"], [])
        self.assertEqual(run["manualModeration"]["original"]["suspicionReasons"], ["signature_mismatch"])

        restored = moderate_run_store(self.store, "run-a", "automatic", "voltar para auditoria", "Henrique", "2026-11-05T12:01:00Z")
        self.assertFalse(restored["rankEligible"])
        self.assertTrue(restored["suspicious"])
        self.assertEqual(restored["suspicionReasons"], ["signature_mismatch"])
        self.assertNotIn("manualModeration", restored)
        self.assertEqual(len(restored["manualModerationHistory"]), 2)

    def test_block_one_run_is_reversible(self):
        run = moderate_run_store(self.store, "run-c", "blocked", "run de laboratorio")
        self.assertFalse(run["rankEligible"])
        self.assertIn("manual_block", run["suspicionReasons"])
        run = moderate_run_store(self.store, "run-c", "automatic", "decisao removida")
        self.assertTrue(run["rankEligible"])
        self.assertFalse(run["suspicious"])

    def test_player_action_targets_only_same_profile(self):
        affected = moderate_player_store(self.store, "run-b", "blocked", "conta de teste")
        self.assertEqual(set(affected), {"run-a", "run-b"})
        self.assertFalse(self.store["runs"][0]["rankEligible"])
        self.assertFalse(self.store["runs"][1]["rankEligible"])
        self.assertTrue(self.store["runs"][2]["rankEligible"])

    def test_security_block_release_and_restore(self):
        security = {
            "ips": {
                "198.51.100.42": {
                    "strikes": 2,
                    "reports": [1000],
                    "blockedUntil": 2000,
                    "lastReason": "automatic_test",
                    "lastSeen": 1500,
                }
            },
            "sessions": {},
            "audit": [],
        }
        state = moderate_security_ip(security, "198.51.100.42", "blocked", "bloqueio manual", now_ms=10_000, duration_ms=60_000)
        self.assertEqual(state["blockedUntil"], 70_000)
        self.assertGreaterEqual(state["strikes"], 4)

        state = moderate_security_ip(security, "198.51.100.42", "released", "falso positivo", now_ms=20_000)
        self.assertEqual(state["blockedUntil"], 0)
        self.assertEqual(state["strikes"], 0)
        self.assertEqual(state["reports"], [])

        state = moderate_security_ip(security, "198.51.100.42", "automatic", "restaurar detector", now_ms=30_000)
        self.assertEqual(state["strikes"], 2)
        self.assertEqual(state["blockedUntil"], 2000)
        self.assertEqual(state["lastReason"], "automatic_test")

    def test_reason_and_ip_are_validated(self):
        with self.assertRaises(ModerationError):
            moderate_run_store(self.store, "run-a", "blocked", "")
        with self.assertRaises(ModerationError):
            moderate_security_ip({"ips": {}}, "127.0.0.1", "blocked", "não permitido")

    def test_synthetic_run_is_publicly_fake_and_excluded_from_umbra(self):
        run = add_synthetic_run(self.store, {
            "player": "Rival",
            "phase": 4,
            "bossesDefeated": 3,
            "bossDamageTaken": 250,
            "victory": False,
            "durationSeconds": 900,
            "kills": 120,
            "pointsEarned": 4000,
            "pointsSpent": 3000,
            "cardsTotal": 12,
            "manifestation": "Elétrica",
            "spectrum": "Impulsiva",
            "reason": "demonstração administrativa",
        }, actor="Henrique", now_unix=1_800_000_000, run_uuid="1234567890abcdef")
        self.assertTrue(run["rankEligible"])
        self.assertTrue(run["manualSynthetic"])
        self.assertIn("LOSER LOSER — RUN DE POSER", run["player"])
        self.assertEqual(run["version"], "ADMIN-FAKE")
        self.assertFalse(run["umbraTrainingEligible"])
        self.assertEqual(run["umbraTrainingReasons"], ["admin_fake_run"])
        self.assertEqual(run["score"], synthetic_ranking_score(4, 3, 250, False))
        self.assertEqual(self.store["profiles"][run["profileId"]]["bestScore"], run["score"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
