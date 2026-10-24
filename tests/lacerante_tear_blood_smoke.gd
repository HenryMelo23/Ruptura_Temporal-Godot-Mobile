extends SceneTree

# Focused smoke test for Lacerante visceral teleport tear and dynamic passive blood/ground trail.

const LaceranteVfx = preload("res://scripts/presentation/lacerante_vfx_presentation.gd")

var game: Node
var canvas_drawer: Node2D


class TestDrawer extends Node2D:
	var tear_slash: Dictionary = {}
	var run_drawer: bool = false
	var game_ref: Node2D

	func _draw() -> void:
		if not run_drawer or game_ref == null:
			return
		if not tear_slash.is_empty():
			LaceranteVfx.draw_teleport_tear(self, tear_slash, Vector2.ZERO)
		LaceranteVfx.draw_ground_marks(self, Vector2.ZERO)
		LaceranteVfx.draw_blood_spurts(self, Vector2.ZERO)


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("LACERANTE_TEAR_BLOOD_FAIL " + message)
	quit(1)


func _run() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame

	canvas_drawer = TestDrawer.new()
	canvas_drawer.game_ref = game
	root.add_child(canvas_drawer)

	game.vol_master = 0.0
	game.gfx_particles = true
	game.manifestation_key = "lacerante"
	game.mode = "game"
	game.player_pos = Vector2(400.0, 300.0)

	# 1. Test Teleport Tear creation and rendering
	LaceranteVfx.reset()
	_check(LaceranteVfx.flying_spurts.is_empty(), "spurts should be empty on reset")
	_check(LaceranteVfx.ground_marks.is_empty(), "ground marks should be empty on reset")

	var origin := Vector2(300.0, 300.0)
	var dest := Vector2(550.0, 300.0)
	var tear_slash := {
		"a": origin,
		"b": dest,
		"life": 3.0,
		"max": 3.0,
		"kind": "lacerante_tp",
		"color": Color(1.0, 0.08, 0.18),
		"width": 42.0
	}
	game.slashes.append(tear_slash)
	canvas_drawer.tear_slash = tear_slash
	canvas_drawer.run_drawer = true

	# Trigger canvas redraw inside valid _draw() context
	canvas_drawer.queue_redraw()
	await process_frame

	tear_slash["life"] = 1.5
	canvas_drawer.queue_redraw()
	await process_frame

	tear_slash["life"] = 0.1
	canvas_drawer.queue_redraw()
	await process_frame

	# 2. Test Passive Lacerar application & Blood Gushing
	var dummy_enemy := {
		"uid": 9999,
		"type": "comum",
		"pos": Vector2(450.0, 320.0),
		"hp": 100.0,
		"max_hp": 100.0,
		"speed": 80.0,
		"laceracao": 1,
		"bleed_timer": 4.0
	}
	game.enemies.append(dummy_enemy)

	LaceranteVfx.on_lacerate_applied(game, dummy_enemy)
	_check(LaceranteVfx.flying_spurts.size() >= 5, "on_lacerate_applied should emit dynamic blood spurts")
	_check(LaceranteVfx.ground_marks.size() >= 1, "on_lacerate_applied should create initial ground blood mark")

	var initial_ground_count: int = LaceranteVfx.ground_marks.size()

	# 3. Test dynamic physics update (droplets flying, gravity, drag, ground marks)
	LaceranteVfx.update(game, 0.1)
	_check(LaceranteVfx.flying_spurts.size() > 0, "flying spurts should still exist during flight")

	# Render valid draw pass
	canvas_drawer.queue_redraw()
	await process_frame

	# 4. Advance time so spurts land and bleeding enemy deposits continuous ground trail
	for step in range(25):
		dummy_enemy["pos"] = Vector2(dummy_enemy["pos"]) + Vector2(4.0, 1.0)
		LaceranteVfx.update(game, 0.1)

	_check(LaceranteVfx.ground_marks.size() > initial_ground_count, "moving bleeding enemy should leave progressive ground trail marks")
	_check(LaceranteVfx.flying_spurts.size() <= LaceranteVfx.MAX_FLYING_SPURTS_DESKTOP, "flying blood VFX exceeded its desktop safety cap")
	_check(LaceranteVfx.ground_marks.size() <= LaceranteVfx.MAX_GROUND_MARKS_DESKTOP, "ground blood VFX exceeded its desktop safety cap")

	canvas_drawer.queue_redraw()
	await process_frame

	# 5. Verify progressive fading until the end
	dummy_enemy["bleed_timer"] = 0.0
	dummy_enemy["laceracao"] = 0

	var max_wait_steps := 60
	for step in range(max_wait_steps):
		LaceranteVfx.update(game, 0.15)
		if LaceranteVfx.ground_marks.is_empty():
			break

	_check(LaceranteVfx.ground_marks.is_empty(), "ground blood marks should progressively fade until completely gone")

	# 6. Memory-saver caps keep the effect bounded on integrated/mobile GPUs.
	game.gfx_memory_saver = true
	for burst in range(24):
		LaceranteVfx.on_lacerate_applied(game, Vector2(500.0 + float(burst), 500.0))
	_check(LaceranteVfx.flying_spurts.size() <= 25, "memory-saver flying blood cap was exceeded")
	_check(LaceranteVfx.ground_marks.size() <= 30, "memory-saver ground blood cap was exceeded")
	game.gfx_memory_saver = false

	# 7. Test reset
	LaceranteVfx.on_lacerate_applied(game, Vector2(500, 500))
	_check(not LaceranteVfx.ground_marks.is_empty(), "marks should be present before reset")
	LaceranteVfx.reset()
	_check(LaceranteVfx.ground_marks.is_empty(), "reset should clear ground marks")
	_check(LaceranteVfx.flying_spurts.is_empty(), "reset should clear flying spurts")

	print("LACERANTE_TEAR_BLOOD_SMOKE_OK tear_render=true blood_spurts=true trail_dynamic=true fade_out=true")
	quit(0)
