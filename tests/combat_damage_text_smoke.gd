extends SceneTree

const CombatText = preload("res://scripts/presentation/combat_text_presentation.gd")

var game: Node2D
var failed := false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("COMBAT_DAMAGE_TEXT_FAIL " + message)


func _combat_texts() -> Array:
	return game.effects.filter(func(effect: Dictionary) -> bool: return String(effect.get("kind", "")) == CombatText.KIND)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	game.run_tutorial_enabled = false
	game._start_game()
	game.gfx_particles = false
	game.enemies.clear()
	game.effects.clear()
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(120, 0))
	var enemy: Dictionary = game.enemies[0]
	enemy["hp"] = 500.0
	enemy["max_hp"] = 500.0

	game.damage_text_scale = 1.0
	game._damage_enemy(enemy, 40.0, "eletrica", true, false, game.player_pos, "basic_attack", 0, "", true, "CRÍTICO")
	var texts := _combat_texts()
	_check(texts.size() == 1, "confirmed enemy damage did not create one combat text")
	if texts.size() == 1:
		_check(bool(texts[0].get("critical", false)), "critical hit lost its animation flag")
		_check(String(texts[0].get("accent_label", "")) == "CRÍTICO", "critical label was not consolidated")
		_check(int(texts[0].get("amount", 0)) == 40, "combat text does not show confirmed damage")

	game.effects.clear()
	game.damage_text_scale = 0.0
	game._damage_enemy(enemy, 25.0, "eletrica", true, false, game.player_pos, "basic_attack")
	_check(_combat_texts().is_empty(), "disabled damage text still allocated an effect")

	game.player_crit_chance = 1.0
	var critical_result: Dictionary = game._critical_damage(20.0)
	_check(bool(critical_result.get("critical", false)), "guaranteed critical was not reported")
	_check(is_equal_approx(float(critical_result.get("amount", 0.0)), 60.0), "critical multiplier changed")

	game.damage_text_scale = game.DAMAGE_TEXT_SCALE_MIN
	game._adjust_damage_text_scale(-1)
	_check(is_zero_approx(game.damage_text_scale), "minimum did not step to off")
	game._adjust_damage_text_scale(1)
	_check(is_equal_approx(game.damage_text_scale, game.DAMAGE_TEXT_SCALE_MIN), "off did not step back to minimum")

	if not failed:
		print("COMBAT_DAMAGE_TEXT_OK confirmed_damage=true critical_consolidated=true off_allocations=0 scale_min=50")
	game._cleanup_runtime_resources()
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failed else 0)
