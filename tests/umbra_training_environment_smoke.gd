extends SceneTree

const Schema = preload("res://scripts/systems/umbra_observation_schema.gd")
const Policy = preload("res://scripts/systems/umbra_multihead_policy.gd")
const Fixture = preload("res://tests/fixtures/umbra_multihead_parity_fixture.gd")
const Runtime = preload("res://tools/umbra_rl_runtime.gd")
const Apolo = preload("res://tools/apolo_observation.gd")
var game: Node
var checks := 0
var failed := false
var results: Dictionary = {}


func _initialize() -> void:
	RTUmbraMind.training_mode = true
	game = load("res://tools/umbra_rl_scene.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("UMBRA_TRAINING_ENV_FAIL " + label)


func _setup() -> void:
	game.start_apolo_phase5_exhibition(0)
	if game._tutorial_active():
		game._finish_tutorial(false)
	game.shop_auto_enabled = false
	game.run_report_sent = true
	game.boss5_multihead_policy = null
	game.boss5_action_timer = 999.0
	game.boss5_decision_timer = 999.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.boss_hp_max = 30000.0
	game.boss_hp = 30000.0
	game.player_hp_max = 5000
	game.player_hp = 5000
	var center: Vector2 = game.experimental_phase_controller.boss_encounter_center()
	game.player_pos = center + Vector2(-160, 0)
	game.boss_pos = center + Vector2(160, 0)
	game.phase5_player_history.clear()
	for _i in range(10):
		game.phase5_player_history.append(game.player_pos)
	game.boss5_authoritative_decision.clear()
	game.reference_center = center
	game.reference_movement = {"style": "stationary"}
	game.player_auto_attack = false
	game.boss5_dimension = "base"
	game.phase5_hazards.clear()
	game.phase5_rats.clear()
	game.bullets.clear()
	game.enemy_bullets.clear()
	game._umbra_base_skills().reset_encounter()
	game.applied_commands.clear()
	game.damage_events.clear()
	game.external_command.clear()


func _ticks(count: int) -> void:
	for _i in range(count):
		game.advance_training_tick(1.0 / 60.0)


func _feature(observation: Dictionary, name: String) -> float:
	return float(observation["values"][observation["feature_schema"].find(name)])


func _run() -> void:
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	_setup()
	_check(Schema.feature_names().size() == 83 and Schema.ACTIONS.size() == 23, "legacy ABI changed")
	_check(Policy.contract_error(Fixture.model()) == "", "legacy model rejected")
	var model := _training_model()
	_check(Policy.contract_error(model) != "", "research model silently accepted by production loader")
	_check(Policy.contract_error(model, 3) == "", "explicit research contract rejected")
	var policy = Policy.create(model, 3)
	var observation := Schema.build_training(game)
	_check(Schema.validate_training_observation(observation) == "", "invalid observation")
	_check(policy != null and not policy.step(observation).has("error"), "research inference failed")
	var corrupt := observation.duplicate(true)
	corrupt["feature_schema"][0] = "incorrect"
	_check(Schema.validate_training_observation(corrupt) != "", "wrong feature order accepted")
	corrupt = observation.duplicate(true)
	corrupt["values"][0] = NAN
	_check(Schema.validate_training_observation(corrupt) != "", "NaN accepted")
	var dimension_values: Array = []
	for dimension in Schema.TRAINING_DIMENSIONS:
		game.boss5_dimension = dimension
		var value := _feature(Schema.build_training(game), "space.dimension")
		_check(not dimension_values.has(value), "dimension alias " + dimension)
		dimension_values.append(value)
	game.boss_pos.x = 2100.0
	var first := _feature(Schema.build_training(game), "umbra.position_x")
	game.boss_pos.x = 2800.0
	_check(first != _feature(Schema.build_training(game), "umbra.position_x"), "large-map position saturated")
	_setup()
	var coverage: Dictionary = {}
	for action in ["ATAQUE", "SIFON", "VORTICE", "PRISAO", "MIASMA", "DESCARGA_ELETRICA", "CAMINHO_ESPINHOS", "LASER_SOBRECARGA", "PRAGA_RATOS", "REBOBINAR", "ECO_PROFETICO"]:
		game.phase5_hazards.clear()
		game.phase5_rats.clear()
		game.enemy_bullets.clear()
		game._umbra_base_skills().reset_encounter()
		game._spawn_umbra_action(action)
		var perception := Apolo.build(game)
		coverage[action] = perception["threats"].size()
		_check(bool(perception["coverage_complete"]) and not perception["threats"].is_empty(), "blind threat " + action)
		if action == "PRISAO":
			_check(_feature(Schema.build_training(game), "space.hazard.prison") == 1.0, "Sopro Artico not encoded")
		if action == "REBOBINAR":
			_check(_feature(Schema.build_training(game), "skills.rewind_active") == 1.0, "rewind mark absent")
		if action == "ECO_PROFETICO":
			_check(_feature(Schema.build_training(game), "skills.eco_count") > -1.0, "eco warning absent")
	game.phase5_hazards.append({"kind": "new_unencoded_threat"})
	_check(not bool(Apolo.build(game)["coverage_complete"]), "unknown threat treated as safe")
	results["threat_coverage"] = coverage
	_setup()
	game._spawn_umbra_action("ECO_PROFETICO")
	var hp: int = game.player_hp
	_ticks(50)
	_check(game.player_hp == hp, "eco hit before telegraph delay")
	_ticks(30)
	_check(game.player_hp < hp, "eco never damaged player")
	_check(game.damage_events.any(func(e): return e["source"] == "umbra_eco"), "eco source not recorded")
	_check(_feature(Schema.build_training(game), "combat.player_damage_recent") > -1.0, "recent player damage absent")
	results["eco_damage"] = hp - int(game.player_hp)
	_setup()
	game.player_auto_attack = true
	_ticks(1)
	_check(not game.bullets.is_empty(), "player did not fire through normal flow")
	if not game.bullets.is_empty():
		var bullet: Dictionary = game.bullets[0]
		var pos: Vector2 = bullet["pos"]
		_ticks(1)
		_check(Vector2(bullet["pos"]) != pos, "player projectile frozen")
	_ticks(100)
	_check(game.boss_hp < game.boss_hp_max, "player attack never damaged Umbra")
	_check(game.damage_events.any(func(e): return e["recipient"] == "umbra"), "boss damage event missing")
	results["boss_damage"] = game.boss_hp_max - game.boss_hp
	_setup()
	game._spawn_umbra_action("ATAQUE")
	var plasma: Dictionary = game.enemy_bullets[0]
	var plasma_pos: Vector2 = plasma["pos"]
	_ticks(6)
	_check(Vector2(plasma["pos"]) != plasma_pos, "Umbra plasma frozen")
	_ticks(90)
	_check(game.damage_events.any(func(e): return e["source"] == "umbra_plasma"), "plasma collision/damage missing")
	results["plasma_damage"] = game.player_hp_max - game.player_hp
	_setup()
	game.boss5_action_timer = 0.0
	game.boss5_decision_timer = 0.0
	for _i in range(120):
		game.external_command = {"action": "ATAQUE", "space": {}}
		_ticks(1)
	_check(game.applied_commands.size() > 0 and game.applied_commands.size() <= 3, "external requests bypassed real cadence")
	results["actions_in_120_requests"] = game.applied_commands.size()
	_setup()
	game.boss5_action_timer = 0.0
	game.boss5_decision_timer = 0.0
	game.external_command = {"action": "MIASMA", "space": {}}
	_ticks(1)
	_check(game.phase5_hazards.is_empty() and game.applied_commands.is_empty(), "illegal dimension ability executed")
	_setup()
	game.boss5_dimension = "necrose"
	game.boss5_dimension_timer = 40.0
	game.boss5_ability_cooldowns["MIASMA"] = 0.0
	game.boss5_action_timer = 0.0
	game.boss5_decision_timer = 0.0
	game.external_command = {"action": "MIASMA", "space": {"x": 0.25, "y": 0.4}}
	_ticks(1)
	_check(not game.phase5_hazards.is_empty(), "valid external spatial action did not execute")
	if not game.phase5_hazards.is_empty():
		_check(Vector2(game.phase5_hazards[0]["pos"]).distance_to(Vector2(game.WORLD_SIZE) * Vector2(0.25, 0.4)) < 0.01, "spatial command was only logged, not applied")
	game.player_burn_stacks = 2
	game.player_burn_timer = 3.0
	_check(Apolo.build(game)["statuses"]["burn_stacks"] == 2, "delayed burn invisible")
	results["checks"] = checks
	results["passed"] = not failed
	results["legacy_abi_preserved"] = true
	results["training_features"] = Schema.training_feature_names().size()
	results["training_actions"] = Schema.TRAINING_ACTIONS.size()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			var path := arg.trim_prefix("--out=")
			DirAccess.make_dir_recursive_absolute(path.get_base_dir())
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_string(JSON.stringify(results, "\t"))
	print("UMBRA_TRAINING_ENV_%s checks=%d results=%s" % ["OK" if not failed else "FAIL", checks, JSON.stringify(results)])
	game._cleanup_runtime_resources()
	root.remove_child(game)
	game.free()
	for _i in range(4):
		await process_frame
	quit(1 if failed else 0)


func _training_model() -> Dictionary:
	var model := Fixture.model()
	model["model_version"] = Policy.TRAINING_MODEL_VERSION
	model["observation_schema_version"] = 3
	model["action_schema_version"] = 3
	model["feature_schema"] = Schema.training_feature_names()
	model["action_schema"] = Schema.TRAINING_ACTIONS
	model["architecture"]["input_size"] = Schema.training_feature_names().size()
	model["architecture"]["action_head_size"] = Schema.TRAINING_ACTIONS.size()
	for key in ["encoder.weight", "heads.action.weight", "heads.action.bias"]:
		var tensor: Dictionary = model["tensors"][key]
		if key == "encoder.weight":
			tensor["shape"][1] = Schema.training_feature_names().size()
		else:
			tensor["shape"][0] = Schema.TRAINING_ACTIONS.size()
		var count := 1
		for size_value in tensor["shape"]:
			count *= int(size_value)
		tensor["data"].resize(count)
		tensor["data"].fill(0.01)
	model["integrity"]["tensors_sha256"] = Policy.compute_tensor_sha256(model)
	return model
