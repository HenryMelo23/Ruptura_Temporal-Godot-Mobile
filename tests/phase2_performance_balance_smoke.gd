extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("PHASE2_PERFORMANCE_BALANCE_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.gfx_low_resource = true
	game.gfx_memory_saver = false
	game.effects.clear()
	game.slashes.clear()
	game.boss2_frost_particles.clear()
	game.boss2_ice_shards.clear()

	var slash_cap := 42
	var frost_cap := 70
	for i in range(game.LOW_RESOURCE_EFFECT_CAP + 80):
		game.effects.append({"text": "", "pos": Vector2.ZERO, "life": 1.0, "max": 1.0})
	for i in range(slash_cap + 30):
		game.slashes.append({"life": 1.0, "max": 1.0})
	for i in range(frost_cap + 40):
		game.boss2_frost_particles.append({"life": 1.0, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	game._trim_visual_effect_arrays()
	_check(game.effects.size() <= game.LOW_RESOURCE_EFFECT_CAP, "low resource effect cap was not enforced")
	_check(game.slashes.size() <= slash_cap, "low resource slash cap was not enforced")
	_check(game.boss2_frost_particles.size() <= frost_cap, "low resource frost cap was not enforced")

	game.effects.append({"text": "", "pos": Vector2.ZERO, "life": 0.02, "max": 1.0})
	game.slashes.append({"life": 0.02, "max": 1.0})
	game.anchors.append({"life": 0.02})
	game.seed_links.append({"time": 0.02})
	game._update_effects(0.04)
	_check(game.effects.all(func(effect): return float(effect.get("life", 0.0)) > 0.0), "expired effects were not removed in place")
	_check(game.slashes.all(func(slash): return float(slash.get("life", 0.0)) > 0.0), "expired slashes were not removed in place")
	_check(game.anchors.all(func(anchor): return float(anchor.get("life", 0.0)) > 0.0), "expired anchors were not removed in place")
	_check(game.seed_links.all(func(link): return float(link.get("time", 0.0)) > 0.0), "expired seed links were not removed in place")

	game.current_phase = 2
	game.boss2_ice_shards.append({"life": 0.01, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	game.boss2_snow_zones.append({"life": 0.01, "pos": Vector2.ZERO, "radius": 16.0})
	game.boss2_frost_particles.append({"life": 0.01, "pos": Vector2.ZERO, "vel": Vector2.ZERO})
	game._update_boss2_environment(0.05)
	_check(game.boss2_ice_shards.all(func(shard): return float(shard.get("life", 0.0)) > 0.0), "expired boss2 ice shards survived")
	_check(game.boss2_snow_zones.all(func(zone): return float(zone.get("life", 0.0)) > 0.0), "expired boss2 snow zones survived")
	_check(game.boss2_frost_particles.all(func(particle): return float(particle.get("life", 0.0)) > 0.0), "expired boss2 frost particles survived")

	game.enemies.clear()
	game.enemy_speed_base = 100.0
	game._spawn_enemy(game.ENEMY_KAMIKAZE, Vector2(240, 240))
	_check(not game.enemies.is_empty(), "kamikaze did not spawn in smoke")
	_check(float(game.enemies.back().get("speed", 0.0)) >= 140.0, "kamikaze speed regressed")
	_check(game._boss2_scaled_damage(100.0) == 72, "boss2 damage multiplier was not applied")
	_check(game.BOSS2_FLASH_FREEZE_STUN >= 2.6, "boss2 flash freeze stun regressed")

	print("PHASE2_PERFORMANCE_BALANCE_SMOKE_OK effects=%d frost=%d kamikaze_speed=%.1f boss2_damage_100=%d" % [
		game.effects.size(),
		game.boss2_frost_particles.size(),
		float(game.enemies.back().get("speed", 0.0)),
		game._boss2_scaled_damage(100.0)
	])
	quit()
