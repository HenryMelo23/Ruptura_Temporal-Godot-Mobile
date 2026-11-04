extends SceneTree

## Colosso (rework de peso): hit-freeze, onda do 3o soco, estouro da transformacao,
## pisadas do gigante, decalques do salto/investida e quadros v2 opcionais.

var game: Node


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("HENRY_COLOSSUS_WEIGHT_FAIL " + message)
	quit(1)


func _spawn_target(position: Vector2, hp := 5000.0) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, position)
	var enemy: Dictionary = game.enemies[-1]
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["stun"] = 0.0
	return enemy


func _setup() -> void:
	game.active_character_key = game.CHARACTER_HENRY
	game.selected_mutation = 2
	game.selected_effect = 2
	game.forced_initial_phase = 1
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.henry_incendiary_ability_controller.cancel_entrance()
	game.henry_entry_timer = 0.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.player_pos = Vector2(700.0, 450.0)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.enemies.clear()
	game.henry_colossus_ability_controller.reset()


func _run() -> void:
	_setup()
	var owner = game.henry_colossus_ability_controller
	# 1) Golpes 1-2: hit-freeze + estrela; golpe 3: onda em leque atinge quem esta atras do alvo.
	var front := _spawn_target(game.player_pos + Vector2(70.0, 0.0))
	var behind := _spawn_target(game.player_pos + Vector2(102.0, 12.0))
	var back_side := _spawn_target(game.player_pos + Vector2(-90.0, 0.0))
	var behind_hp: float = float(behind["hp"])
	var back_hp: float = float(back_side["hp"])
	_check(owner.fire_auto_attack(), "first punch failed")
	_check(float(front.get("stun", 0.0)) >= owner.HIT_FREEZE - 0.001, "punch did not freeze the target")
	_check(owner.impact_decals.any(func(d): return String(d.get("kind", "")) == "star"), "punch left no impact star")
	owner.fire_auto_attack()
	var behind_before_third: float = float(behind["hp"])
	owner.fire_auto_attack()
	_check(float(behind["hp"]) < behind_before_third, "third punch shockwave did not hit the enemy behind the target")
	_check(is_equal_approx(float(back_side["hp"]), back_hp), "third punch shockwave hit an enemy behind Henry")
	_check(owner.impact_decals.any(func(d): return String(d.get("kind", "")) == "crack"), "third punch left no ground crack")

	# 2) Transformacao termina com estouro que empurra.
	_setup()
	owner = game.henry_colossus_ability_controller
	var near := _spawn_target(game.player_pos + Vector2(100.0, 0.0))
	owner.fury = owner.FURY_MAX
	_check(owner.cast_ultimate(), "transformation did not start")
	owner.update(owner.TRANSFORM_DURATION + 0.01)
	_check(owner.giant_active, "did not become giant")
	_check(Vector2(near.get("henry_colossus_knockback", Vector2.ZERO)).length() > 100.0, "transformation burst did not push nearby enemies")

	# 3) Gigante andando: pisada a cada intervalo (poeira + tremor).
	owner.impact_decals.clear()
	var steps_before: int = owner.impact_decals.size()
	if game.has_method("_read_move") and game._read_move().length() > 0.1:
		owner.update(owner.GIANT_STEP_INTERVAL + 0.02)
		_check(owner.impact_decals.size() > steps_before, "giant step left no dust")

	# 4) Salto do gigante: rachadura grande no pouso.
	owner.impact_decals.clear()
	_check(owner.begin_leap(game.player_pos + Vector2(200.0, 0.0)), "giant leap failed")
	owner.update(owner.LEAP_DURATION + 0.02)
	_check(owner.impact_decals.any(func(d): return String(d.get("kind", "")) == "crack" and float(d.get("radius", 0.0)) >= owner.LEAP_RADIUS), "leap landing left no big crack")

	# 5) Sem folhas v2 o caminho antigo continua (null), e o cache nao quebra.
	var has_v2: bool = ResourceLoader.exists(owner.V2_DIR + "henry_colossus_giant_walk_sheet_v2.png")
	var tex = owner.v2_texture(Vector2.ZERO)
	_check(has_v2 or tex == null, "v2 texture returned without a v2 sheet")
	_check(owner.attack_v2_index(0.0, 2) == 8 and owner.attack_v2_index(0.15, 2) == 10 and owner.attack_v2_index(0.3, 0) == 3, "attack v2 index mapping is wrong")
	print("HENRY_COLOSSUS_WEIGHT_OK hit_freeze=true third_shock_cone=true transform_burst=true leap_crack=true v2_fallback=true")
	quit(0)
