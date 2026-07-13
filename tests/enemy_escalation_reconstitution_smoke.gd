extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ENEMY_ESCALATION_RECONSTITUTION_FAIL " + message)
	quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game._start_game()
	game.player_crit_chance = 0.0
	game.player_pos = Vector2(760, 420)

	_check(is_equal_approx(game.PLAYER_DASH_DISTANCE, 350.0), "teleport distance was not increased by 20px")
	_check(is_equal_approx(game.COUT_AS_SPAWN_TIME, 420.0), "rebobinador spawn was not delayed to 7 minutes")
	_check(is_equal_approx(game.SHIELD_REFLECTOR_SPAWN_TIME, 600.0), "briguer shield spawn was not delayed to 10 minutes")
	game.catalog_tab = 1
	var enemy_catalog: Array = game._catalog_items()
	_check(enemy_catalog.any(func(item): return String(item.get("name", "")) == "Rebobinador" and String(item.get("desc", "")).find("7 minutos") >= 0), "enemy catalog does not explain rebobinador")
	_check(enemy_catalog.any(func(item): return String(item.get("name", "")) == "Briguer Escudeiro" and String(item.get("desc", "")).find("10 minutos") >= 0), "enemy catalog does not explain briguer shield")

	game.time_alive = game.ANOMALIA_ESPREITADOR_TIME
	var early_stalker: Dictionary = game._stalker_profile()
	game.time_alive = 720.0
	var late_stalker: Dictionary = game._stalker_profile()
	_check(float(late_stalker["base"]) > float(early_stalker["base"]) + 0.30, "stalker base speed did not scale enough")
	_check(float(late_stalker["sprint"]) > float(early_stalker["sprint"]) + 0.45, "stalker sprint speed did not scale enough")

	var damage_probe := {"type": game.ENEMY_COMMON, "damage": 100.0}
	game.player_defense = 0
	game.time_alive = 0.0
	var early_damage: int = game._enemy_damage(damage_probe)
	game.time_alive = 900.0
	var late_damage: int = game._enemy_damage(damage_probe)
	_check(late_damage > early_damage, "enemy damage did not scale up with time")

	game.enemies.clear()
	game.time_alive = game.LARAPIO_AGGRESSIVE_AFTER + 4.0
	game._spawn_enemy(game.ENEMY_LARAPIO, Vector2(620, 420))
	var larapio: Dictionary = game.enemies[0]
	larapio["spawned_at"] = 0.0
	larapio["stolen"] = 0
	game.enemy_bullets.clear()
	game._throw_larapio_projectile(larapio)
	_check(float(game.enemy_bullets[0]["speed_mult"]) >= 1.50 * game.LARAPIO_AGGRESSIVE_STONE_SPEED_MULT, "larapio stone speed stayed at old value")

	game.enemies.clear()
	game.time_alive = 140.0
	game._spawn_enemy(game.ENEMY_COUT_ATTACK_SPEED, Vector2(600, 420))
	game._spawn_enemy(game.ENEMY_COMMON, Vector2(600 + game.COUT_AS_AURA_RADIUS - 8.0, 420))
	var caster: Dictionary = game.enemies[0]
	var victim: Dictionary = game.enemies[1]
	var old_speed := float(victim["speed"])
	victim["hp"] = 0.0
	game._kill_enemy(victim)
	_check(game.enemies.has(victim), "enemy was not reconstituted inside orange aura")
	_check(is_equal_approx(float(victim["hp"]), float(victim["max_hp"]) * game.COUT_AS_RECONSTITUTE_HP_RATIO), "reconstituted hp is not 25 percent")
	_check(float(victim["speed"]) >= old_speed * game.COUT_AS_RECONSTITUTE_SPEED_MULT, "reconstituted enemy did not gain 90 percent speed")
	_check(is_equal_approx(float(victim["reconstitute_time"]), 1.0) and float(caster["reconstitute_pulse"]) > 0.0, "reconstitution animation state was not set to one second")
	_check(bool(victim.get("reconstituted_once", false)), "reconstitution did not mark the enemy as already revived")
	victim["hp"] = 0.0
	game._kill_enemy(victim)
	_check(not game.enemies.has(victim), "enemy was reconstituted more than once")
	game.enemies.clear()
	game._spawn_enemy(game.ENEMY_COUT_ATTACK_SPEED, Vector2(600, 420))
	game._spawn_enemy(game.ENEMY_COUT_ATTACK_SPEED, Vector2(650, 420))
	var rebob_victim: Dictionary = game.enemies[1]
	rebob_victim["hp"] = 0.0
	game._kill_enemy(rebob_victim)
	_check(not game.enemies.has(rebob_victim), "rebobinador reconstituted another rebobinador")

	game.arauto = {
		"active": true,
		"pos": Vector2(900, 420),
		"hp": 1000.0,
		"max_hp": 1000.0,
		"entry_timer": 0.0,
		"phase2": false
	}
	game.enemies.clear()
	game.aura_state = game.AuraSystem.create("Nula", 3)
	var hp_before := float(game.arauto["hp"])
	game._apply_bullet_effect_to_arauto({"kind": "eletrica", "damage": 100.0, "pos": Vector2(game.arauto["pos"]), "aura_null": true})
	var arauto_damage := hp_before - float(game.arauto["hp"])
	_check(arauto_damage > 100.0, "Arauto did not receive manifestation/aura passive damage path")
	_check(float(game.arauto.get("aura_null", 0.0)) > 0.0, "Arauto did not receive Nula passive marker")

	print("ENEMY_ESCALATION_RECONSTITUTION_SMOKE_OK tp=350 spawn_gates=true stalker=true damage=true larapio_stone=true reconstitute_once=true no_rebob_chain=true arauto_passive=true")
	quit(0)
