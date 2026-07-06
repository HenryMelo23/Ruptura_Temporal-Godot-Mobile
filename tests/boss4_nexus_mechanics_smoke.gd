extends SceneTree

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game._advance_to_phase(4)
	game.boss_active = true
	game.boss_dead = false
	game.boss_entry_timer = 0.0
	game.boss_pos = game.boss4_entry_target
	game.boss_hp_max = 12000.0
	game.boss_hp = game.boss_hp_max
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.player_defense = 0.0
	game.player_pos = Vector2(620, 450)

	game.boss_hp = game.boss_hp_max * 0.74
	game._update_boss4_stage()
	assert(game.boss4_stage == 2)
	game.boss_hp = game.boss_hp_max * 0.49
	game._update_boss4_stage()
	assert(game.boss4_stage == 3)
	game.boss_hp = game.boss_hp_max * 0.24
	game._update_boss4_stage()
	assert(game.boss4_stage == 4)

	game.petro_active = true
	game.petro_hp_max = 900
	game.petro_hp = 900
	game.petro_pos = Vector2(500, 460)
	game.boss_hp = game.boss_hp_max * 0.50
	game._start_boss4_vampirism()
	game._update_boss4_specials(0.50)
	assert(game.petro_hp < 900)
	assert(game.boss_hp > game.boss_hp_max * 0.50)
	var vampire_before: float = game.boss4_vampire_timer
	game._damage_boss(120.0, "eletrica")
	assert(game.boss4_vampire_timer < vampire_before)

	game._start_boss4_orbital_prison()
	assert(not game.boss4_prison.is_empty())
	var prison_pos: Vector2 = Vector2(game.boss4_prison["pos"])
	assert(game._damage_phase4_planet_at(prison_pos, 50.0, 30.0))
	assert(int(game.boss4_prison.get("fragments", 0)) == 3)

	game._spawn_boss4_clone()
	assert(not game.boss4_clone.is_empty())
	var clone_pos: Vector2 = Vector2(game.boss4_clone["pos"])
	assert(game._damage_phase4_planet_at(clone_pos, 9999.0, 40.0))
	assert(game.boss4_clone.is_empty())
	assert(game.phase4_enemy_hazards.any(func(h): return String(h.get("kind", "")) == "safe_zone"))

	game.phase4_enemy_hazards.clear()
	game.phase4_null_zones.clear()
	game.boss4_ultimate_used = false
	game._start_boss4_ultimate()
	assert(game.boss4_ultimate_active)
	assert(game.boss4_rupture_anchors.size() == 4)
	for i in range(3):
		var anchor_pos: Vector2 = Vector2(game.boss4_rupture_anchors[i]["pos"])
		assert(game._damage_phase4_planet_at(anchor_pos, game.BOSS4_ULTIMATE_ANCHOR_HP + 10.0, 80.0))
	game._update_boss4_ultimate(0.05)
	assert(not game.boss4_ultimate_active)
	assert(game.boss4_stun_timer > 0.0)
	assert(game.boss4_vulnerable_timer > 0.0)

	game.boss4_stun_timer = 0.0
	game.boss4_vulnerable_timer = 0.0
	game.boss4_ultimate_used = false
	game.player_hp = 1000
	game.boss_hp = game.boss_hp_max * 0.30
	game._start_boss4_ultimate()
	game.boss4_ultimate_timer = 0.01
	game._update_boss4_ultimate(0.02)
	assert(not game.boss4_ultimate_active)
	assert(game.player_hp < 1000)
	assert(game.boss4_instability >= 99.0)
	assert(game.phase4_null_zones.size() >= 4)

	print("BOSS4_NEXUS_MECHANICS_SMOKE_OK stages=true vampire=true prison=true clone=true ultimate_success=true ultimate_fail=true")
	quit(0)
