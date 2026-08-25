import math
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import balance_scaling_sampler as sampler


class BalanceScalingSamplerTest(unittest.TestCase):
    def test_boss_phase_hp_matches_project_baselines_without_farm(self) -> None:
        expected = {
            1: 4860.0,
            2: 8910.0,
            3: 17280.0,
            4: 25380.0,
            5: 35100.0,
            6: 4860.0,
        }
        for phase, hp in expected.items():
            with self.subTest(phase=phase):
                self.assertTrue(math.isclose(sampler.boss_hp(phase, 0.0, 0.0, 0.0), hp))

    def test_fixed_card_stats_follow_main_gd_scaling(self) -> None:
        cards = sampler.CardState(
            {
                "Disparo crescente": 2,
                "Tempestade": 3,
                "Porcao": 2,
                "Defesa": 5,
                "Speed Atack": 4,
                "Carta Zero": 1,
            }
        )
        stats = sampler.player_stats("eletrica", cards)
        zero = 1.06
        expected_damage = 32.0 + 32.0 * ((1.15**2 - 1.0) * zero) + 5.0 * 3.0 * zero
        expected_hp = 450.0 * ((1.0 + 0.1 * zero) ** 2)

        self.assertTrue(math.isclose(stats["player_damage"], expected_damage))
        self.assertTrue(math.isclose(stats["player_hp"], expected_hp))
        self.assertTrue(math.isclose(stats["player_defense"], 17.5 * zero))
        self.assertTrue(math.isclose(stats["attack_interval"], 0.68 - 0.014 * 4.0 * zero))

    def test_sample_rows_cross_enemy_and_boss_opposites(self) -> None:
        config = sampler.SampleConfig(
            max_minutes=12.0,
            step_minutes=6.0,
            score_per_minute=0.0,
            kills_per_minute=0.0,
            cards=sampler.CardState({"Disparo crescente": 1}),
        )
        rows = sampler.sample_rows(config)
        self.assertEqual(len(rows), 3)
        self.assertGreater(rows[-1]["player_damage"], rows[0]["damage_per_basic_to_boss"])
        self.assertGreater(rows[-1]["boss_hp"], rows[-1]["enemy_hp"])
        self.assertIn("boss_time_to_kill_seconds", rows[-1])


if __name__ == "__main__":
    unittest.main()
