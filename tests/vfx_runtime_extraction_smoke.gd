extends SceneTree

var game: Node2D
var baseline: Node2D
var failed: bool = false

func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline="):
			baseline = load(arg.trim_prefix("--baseline=")).new()
			root.add_child(baseline)
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failed = true
		push_error("VFX_RUNTIME_EXTRACTION_FAIL " + label)

func _prepare(host: Node2D) -> void:
	host.set_process(false)
	host.gfx_particles = true
	host.gfx_low_resource = false
	host.gfx_memory_saver = false
	host.mobile_adaptive_visual_budget = false
	host.effects.clear()
	host.enemies.clear()
	host.rng.seed = 8675309

func _run() -> void:
	var compared_baseline: bool = baseline != null
	_prepare(game)
	if baseline != null:
		_prepare(baseline)
	var position := Vector2(320, 240)
	var cases: Array = [
		["_spawn_radial_particles", [position, Color.CYAN, 12]],
		["_spawn_bullet_hit_fragments", [position, {"kind": "eletrica", "dir": Vector2.RIGHT}]],
		["_spawn_player_landing_smoke", [position]],
		["_spawn_music_notes", [position, 8]],
		["_spawn_secondary_drain_sparks", [position]],
		["_spawn_enemy_desfragmentation", [position, Color.RED, 16]],
		["_spawn_projectile_muzzle", ["eletrica", position, Vector2.RIGHT]],
		["_emit_projectile_trail", [{"kind": "eletrica", "pos": position, "dir": Vector2.RIGHT}]],
	]
	for entry in cases:
		game.effects.clear()
		game.callv(entry[0], entry[1])
		_check(not game.effects.is_empty(), entry[0] + " emission")
		for effect in game.effects:
			_check(float(effect["life"]) > 0.0, entry[0] + " lifetime")
			_check(Vector2(effect["pos"]).is_finite(), entry[0] + " position")
		if baseline != null:
			baseline.effects.clear()
			baseline.callv(entry[0], entry[1])
			_check(game.effects == baseline.effects, entry[0] + " baseline parity")
	var chain: Dictionary = game._init_chain_physics(Vector2.ZERO, position)
	var old_chain: Dictionary = baseline._init_chain_physics(Vector2.ZERO, position) if baseline != null else {}
	for frame in range(60):
		game._update_single_chain_physics(chain, Vector2.ZERO, position, 1.0 / 60.0)
		if baseline != null:
			baseline._update_single_chain_physics(old_chain, Vector2.ZERO, position, 1.0 / 60.0)
	_check(chain["points"][0]["pos"] == Vector2.ZERO, "chain origin")
	_check(chain["points"][-1]["pos"] == position, "chain target")
	if baseline != null:
		_check(chain == old_chain, "chain baseline parity")
	game.effects.clear()
	game.gfx_particles = false
	game._spawn_radial_particles(position, Color.CYAN, 12)
	_check(game.effects.is_empty(), "disabled particles")
	game.gfx_low_resource = true
	_check(game._adaptive_particle_count(100) < 100, "low resource budget")
	for host in [game, baseline]:
		if host != null:
			host._cleanup_runtime_resources()
			host.textures.clear()
			host.audio_streams.clear()
			host.free()
	for frame in range(4):
		await process_frame
	if not failed:
		print("VFX_RUNTIME_EXTRACTION_OK emitters=8 chain_frames=60 budgets=true baseline=" + str(compared_baseline))
	quit(1 if failed else 0)
