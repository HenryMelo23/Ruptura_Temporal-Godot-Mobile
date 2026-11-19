extends SceneTree

## Ultimate (2026-11-18): reapertar durante a habilidade cancela; no toque
## rapido (mira automatica) a mira aparece no inimigo de onde ela vai sair.

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("ULTIMATE_CANCEL_FAIL " + message)


func _select(key: String) -> void:
	game.manifestation_key = key
	game.selected_manifestation = game._manifestation_index_for_key(key, -1)
	game.manifestation_secondaries.clear()
	game.last_secondary_time = -999.0
	game.player_pos = Vector2(640.0, 360.0)


func _active(kind: String) -> bool:
	for s in game.manifestation_secondaries:
		if String(s.get("kind", "")) == kind and float(s.get("life", 0.0)) > 0.0:
			return true
	return false


func _run() -> void:
	game._start_game()
	game.set_process(false)
	game.mode = "game"
	game.is_multiplayer = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 100.0
	game.enemies.clear()
	game.boss_active = false
	game.arauto.clear()
	for kind in ["lacerante", "gravitante"]:
		_select(kind)
		game._use_secondary_skill(game.player_pos + Vector2(120.0, 0.0))
		_check(_active(kind), "%s nao lancou" % kind)
		game._use_secondary_skill()
		game._update_manifestation_secondaries(1.0 / 60.0)
		_check(not _active(kind), "%s nao cancelou ao reapertar" % kind)
		if kind == "lacerante":
			_check(game._active_lacerante_secondary().is_empty(), "Lacerante continuou presa apos cancelar")
		game._use_secondary_skill()
		_check(not _active(kind), "%s relancou durante a recarga" % kind)

	# Mira automatica: toque sem arrastar mira no inimigo; arrastar volta ao manual.
	_select("lacerante")
	game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + Vector2(150.0, 0.0))
	var target: Dictionary = game.enemies[-1]
	target["pos"] = game.player_pos + Vector2(150.0, 0.0)
	var viewport := Vector2(1280, 720)
	game.ui_platform_override = game.UI_PLATFORM_ANDROID
	game._update_button_layout(viewport)
	var center: Vector2 = game.buttons["secondary"].get_center()
	game._handle_touch_press(51, center, viewport)
	var preview = game._secondary_quick_target_preview()
	_check(preview is Vector2 and Vector2(preview).distance_to(Vector2(target["pos"])) < 0.1, "preview nao mirou no inimigo")
	game.player_control_controller.secondary_press_started_msec -= 2000
	_check(game._secondary_quick_target_preview() is Vector2, "segurar parado no toque perdeu a mira automatica")
	game._handle_touch_drag(51, center + Vector2(-140.0, -60.0), viewport)
	_check(game._secondary_quick_target_preview() == null, "arrastar nao trocou para mira manual")
	game._handle_touch_drag(51, center, viewport)
	game._handle_touch_release(51, center, viewport)
	var cast_center: Vector2 = Vector2(game.manifestation_secondaries[0].get("center", Vector2.ZERO)) if not game.manifestation_secondaries.is_empty() else Vector2.INF
	_check(cast_center.distance_to(Vector2(target["pos"])) < 0.1, "ultimate nao saiu no inimigo mostrado")
	if not failed:
		print("ULTIMATE_CANCEL_AUTOAIM_OK")
	quit(1 if failed else 0)
