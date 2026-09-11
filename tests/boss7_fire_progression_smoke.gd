extends SceneTree

const Fire = preload("res://scripts/vfx/phoenix_fire.gd")
var game: Node
var failed := false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("BOSS7_FIRE_PROGRESSION_FAIL " + message)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _sample_damage(pos: Vector2, elapsed: float) -> int:
	game.player_pos = pos
	game.player_hp = game.player_hp_max
	game.last_damage_time = -100.0
	game.last_dash_time = -100.0
	game.time_alive = 100.0 + elapsed
	game.boss7_ultimate_active = true
	game.boss7_ultimate_timer = Fire.DURATION - elapsed
	game.boss7_ultimate_tick_timer = 0.0
	var hp: int = game.player_hp
	game._update_boss7_ultimate(0.0)
	return hp - int(game.player_hp)


func _run() -> void:
	game._start_game(false)
	game.set_process(false)
	game.current_phase = 7
	game.mode = "game"
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.boss_active = true
	game.boss_dead = false
	game.boss_hp_max = 10000.0
	game.boss_hp = 2900.0
	game.player_hp_max = 1000
	game.player_hp = 1000
	game.enemies.clear()
	game.boss_attacks.clear()
	game._reset_boss7_state()
	game._check_boss7_ultimate(0.0)
	_check(game.boss7_ultimate_active, "ultimate did not trigger below 30 percent")
	_check(game.boss7_ultimate_quadrants == [1, 0, 0, 0], "all quadrants started together")
	var outer := Vector2(80, 45)
	var inner := Vector2(760, 420)
	_check(Fire.heat_at(outer, game.WORLD_SIZE, 2.9) == 0.0, "warning deals heat")
	_check(Fire.heat_at(outer, game.WORLD_SIZE, 5.0) > Fire.heat_at(inner, game.WORLD_SIZE, 5.0), "flame front does not advance")
	_check(_sample_damage(outer, 2.9) == 0, "warning dealt damage")
	_check(_sample_damage(inner, 5.0) == 0, "damage arrived ahead of flame front")
	_check(_sample_damage(outer, 5.0) > 0, "hot front did not deal damage")
	_check(_sample_damage(Vector2(1200, 650), 9.0) == 0, "safe quadrant dealt damage")
	_check(_sample_damage(outer, 19.1) == 0, "extinguished quadrant dealt damage")
	for sample in range(501):
		var elapsed := sample * 0.1
		var active := 0
		for quadrant in range(4):
			if Fire.phase(elapsed, quadrant) > 0:
				active += 1
		_check(active <= 2, "no escape route at %.1fs" % elapsed)
	for quadrant in range(4):
		var pos := Fire.quadrant_rect(quadrant, game.WORLD_SIZE).get_center()
		var start: float = Fire.ORDER.find(quadrant) * Fire.STAGGER
		_check(Fire.heat_at(pos, game.WORLD_SIZE, start + 9.0) > 0.99, "quadrant never ignites")
		_check(Fire.heat_at(pos, game.WORLD_SIZE, start + 18.0) < 0.5, "quadrant never cools")
	game.boss7_ultimate_active = true
	game.boss7_ultimate_timer = 35.0
	var packet: Dictionary = game._pack_net_boss_visuals()
	_check(is_equal_approx(float(packet.get("b7_heat", -1.0)), 35.0), "heat clock missing from snapshot")
	game.boss7_ultimate_active = false
	game.boss7_ultimate_timer = 0.0
	game._apply_remote_boss_visual_snapshot(packet)
	_check(game.boss7_ultimate_active and is_equal_approx(game.boss7_ultimate_timer, 35.0), "late join heat clock differs")
	_check(game.boss7_ultimate_quadrants == [3, 2, 0, 0], "remote quadrant phases differ")
	game._apply_remote_boss_visual_snapshot({})
	_check(not game.boss7_ultimate_active, "legacy snapshot retained stale heat")
	game.boss7_ultimate_active = true
	game.boss7_ultimate_timer = 0.01
	game._update_boss7_ultimate(0.02)
	game._check_boss7_ultimate(0.0)
	_check(not game.boss7_ultimate_active, "ultimate immediately restarted after 50 seconds")
	game._reset_boss7_state()
	_check(not game.boss7_ultimate_used and game.boss7_ultimate_quadrants == [0, 0, 0, 0], "new encounter retained heat")
	game._check_boss7_ultimate(0.0)
	game._start_boss7_rebirth()
	_check(not game.boss7_ultimate_active, "ash core retained invisible hazard")
	if not failed:
		print("BOSS7_FIRE_PROGRESSION_OK samples=501 warning=true front=true safe_routes=true damage=true cooling=true reset=true snapshot=true")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	quit(1 if failed else 0)
