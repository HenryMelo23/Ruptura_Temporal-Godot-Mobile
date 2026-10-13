extends SceneTree

# This is deliberately an end-to-end contract test.  It never calls an
# evolution callback directly: choices go through `_choose_manifest_evolution`,
# actions go through the public attack/Q/TP entry points, and outcomes are
# observed only after the regular runtime update methods resolve them.
#
# It is expected to fail while an evolution is only a catalog/visual change.
# The `EVP-<id>` output is the reproducible defect key for that evolution.

const Catalog = preload("res://scripts/systems/manifest_evolutions/manifest_evolution_catalog.gd")

var game: Node
var behavioral_failures: Array[String] = []
var blocked: Array[String] = []
var design_review_groups: Array[String] = []
var checked_by_manifestation: Dictionary = {}
var last_evidence: Dictionary = {}


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _fail(message: String) -> void:
	push_error("MANIFEST_EVOLUTION_PUBLIC_CONTRACT_FAIL " + message)


func _entry_for(key: String, stage: String, slot: int) -> Dictionary:
	var entries: Array = game._manifest_evolution_entries(key, stage)
	if slot < 0 or slot >= entries.size():
		return {}
	return Dictionary(entries[slot])


func _record_failure(entry: Dictionary, reason: String) -> void:
	var id := String(entry.get("id", "unknown"))
	var defect := "EVP-%s: %s evidence=%s" % [id, reason, JSON.stringify(last_evidence)]
	behavioral_failures.append(defect)
	_fail(defect)


func _prepare(key: String, entry: Dictionary = {}) -> Array:
	# Reusing the real run initializer prevents a fixture-only state from making
	# a route appear functional.  The clock is advanced only to make the public
	# cooldown checks deterministic.
	game._start_game()
	game.mode = "game"
	game.manifestation_key = key
	game.player_pos = Vector2(640.0, 360.0)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.time_alive = 1000.0
	# `_start_game` intentionally starts the playable character in a short
	# landing animation.  A contract test must wait past that real input lock
	# before exercising public controls; otherwise every route would look like a
	# placebo merely because no input was accepted.
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	if key == "eclipsada":
		# Keep this public attack probe on the Sol branch: it is the branch that
		# emits projectiles. Lua is still exercised by the E-route coverage pass.
		game.eclipsada_form = game.ECLIPSADA_FORM_SOL
		game.eclipsada_next_attack_time = 0.0
	game.last_attack_time = -1000.0
	game.last_skill_time = -1000.0
	game.last_secondary_time = -1000.0
	game.effects.clear()
	game.bullets.clear()
	game.return_bullets.clear()
	game.enemies.clear()
	game.shockwaves.clear()
	game.slashes.clear()
	game.manifest_evolution_combat_event_log.clear()
	game._reset_manifest_evolution_state()
	if not entry.is_empty():
		game.manifest_evolution_options = [entry]
		game._choose_manifest_evolution(0)
	var targets: Array = []
	for offset in [Vector2(108.0, 0.0), Vector2(154.0, 34.0), Vector2(196.0, -34.0)]:
		game._spawn_enemy(game.ENEMY_COMMON, game.player_pos + offset)
		var enemy: Dictionary = game.enemies.back()
		enemy["hp"] = 100000.0
		enemy["max_hp"] = 100000.0
		targets.append(enemy)
	return targets


func _advance_combat(delta: float = 0.03, frames: int = 16) -> void:
	for _frame in range(frames):
		game._update_bullets(delta)
		game._update_return_bullets(delta)
		game._update_manifest_evolution_effects(delta)
		game._update_acorrentada_state(delta)


func _public_attack(key: String, resolve: bool = true) -> void:
	game.effects = game.effects.filter(func(effect): return not bool(Dictionary(effect).get("skill_lock", false)))
	game.time_alive += 10.0
	game.last_attack_time = -1000.0
	game._try_attack()
	if key == "lacerante":
		game._update_lacerante_prepare(1.0)
	if resolve:
		# Acorrentada resolves its real windup/out/hold/return state machine.
		# Giving it the full motion duration here avoids mistaking an incomplete
		# animation for an evolution that failed to receive a hit event.
		_advance_combat(0.03, 60 if key == "acorrentada" else 16)


func _public_skill(key: String) -> void:
	game.effects = game.effects.filter(func(effect): return not bool(Dictionary(effect).get("skill_lock", false)))
	game.time_alive += 10.0
	game.last_skill_time = -1000.0
	if key == "necronada":
		game.necronada_vestiges = [{
			"id": 901, "enemy_type": game.ENEMY_COMMON,
			"pos": game.player_pos + Vector2(24.0, 0.0),
			"profile": game._necronada_profile(game.ENEMY_COMMON), "depth": 1
		}]
	game._use_skill(game.player_pos + Vector2(112.0, 0.0))
	_advance_combat(0.05, 8)


func _public_teleport(key: String) -> void:
	game.effects = game.effects.filter(func(effect): return not bool(Dictionary(effect).get("skill_lock", false)))
	game.time_alive += 10.0
	game._execute_teleport(game.player_pos + Vector2(124.0, 0.0))
	if key == "cartografica":
		# Cartografica's first public TP places the pin; the second is the actual
		# displacement and therefore the only valid evolution trigger.
		game.time_alive += 10.0
		game._execute_teleport(game.player_pos + Vector2(124.0, 0.0))
	_advance_combat(0.05, 8)


func _projectile_snapshot() -> Dictionary:
	var all: Array = []
	all.append_array(game.bullets)
	all.append_array(game.return_bullets)
	var flags := {"pierce": false, "homing": false, "prism": false, "count": all.size()}
	for value in all:
		var bullet: Dictionary = Dictionary(value)
		flags["pierce"] = bool(flags["pierce"]) or int(bullet.get("evolution_pierce_left", 0)) > 0
		flags["homing"] = bool(flags["homing"]) or bool(bullet.get("evolution_homing", false))
		flags["prism"] = bool(flags["prism"]) or bool(bullet.get("prismatica_evolution", false))
	return flags


func _impact_snapshot(targets: Array) -> Dictionary:
	var first: Dictionary = Dictionary(targets[0])
	var second: Dictionary = Dictionary(targets[1])
	return {
		"first_hp": float(first.get("hp", 100000.0)),
		"first_pos": Vector2(first.get("pos", Vector2.ZERO)),
		"slow": float(first.get("evolution_slow", 0.0)),
		"stun": float(first.get("stun", 0.0)),
		"side_hp": float(second.get("hp", 100000.0)),
		"side_pos": Vector2(second.get("pos", Vector2.ZERO)),
		"waves": game.shockwaves.size()
	}


func _exercise_generic(key: String, entry: Dictionary) -> bool:
	var profile: Dictionary = Dictionary(entry.get("profile", {}))
	var effect := String(profile.get("effect", ""))
	var repeats := maxi(1, int(profile.get("every", 1)))
	if effect == "impact_seal":
		repeats = maxi(1, int(profile.get("hits", 1)))
	var baseline_targets := _prepare(key)
	var baseline: Dictionary = {}
	match effect:
		"projectile_echo", "projectile_echo_plus", "projectile_pierce", "projectile_homing", "grand_manifestation":
			for _i in range(repeats):
				_public_attack(key, false)
			baseline = _projectile_snapshot()
		"impact_link", "impact_burst", "impact_chain_burst", "impact_vortex", "impact_seal":
			for _i in range(repeats):
				_public_attack(key, true)
			baseline = _impact_snapshot(baseline_targets)
		"skill_field":
			_public_skill(key)
			baseline = _impact_snapshot(baseline_targets)
			baseline["fields"] = Array(game.manifest_evolution_state.get("fields", [])).size()
			baseline["field_tick"] = float(Dictionary(Array(game.manifest_evolution_state.get("fields", [{}]))[0]).get("tick", 0.0)) if int(baseline["fields"]) > 0 else 0.0
		"teleport_burst":
			_public_teleport(key)
			baseline = _impact_snapshot(baseline_targets)
		_:
			blocked.append(String(entry.get("id", "")) + " unsupported effect=" + effect)
			return false

	var selected_targets := _prepare(key, entry)
	var selected: Dictionary = {}
	match effect:
		"projectile_echo", "projectile_echo_plus", "projectile_pierce", "projectile_homing", "grand_manifestation":
			for _i in range(repeats):
				_public_attack(key, false)
			selected = _projectile_snapshot()
			last_evidence = {"baseline": baseline, "selected": selected, "effect": effect}
			if effect.begins_with("projectile_echo"):
				return int(selected["count"]) > int(baseline["count"])
			if effect == "projectile_pierce":
				return bool(selected["pierce"]) and not bool(baseline["pierce"])
			if effect == "projectile_homing":
				return bool(selected["homing"]) and not bool(baseline["homing"])
			return bool(selected["pierce"]) and bool(selected["homing"])
		"impact_link", "impact_burst", "impact_chain_burst", "impact_vortex", "impact_seal":
			for _i in range(repeats):
				_public_attack(key, true)
			selected = _impact_snapshot(selected_targets)
			last_evidence = {"baseline": baseline, "selected": selected, "effect": effect}
			return float(selected["slow"]) > float(baseline["slow"]) or float(selected["stun"]) > float(baseline["stun"]) or float(selected["first_hp"]) < float(baseline["first_hp"]) or Vector2(selected["first_pos"]) != Vector2(baseline["first_pos"]) or float(selected["side_hp"]) < float(baseline["side_hp"]) or Vector2(selected["side_pos"]) != Vector2(baseline["side_pos"])
		"skill_field":
			_public_skill(key)
			selected = _impact_snapshot(selected_targets)
			selected["fields"] = Array(game.manifest_evolution_state.get("fields", [])).size()
			selected["field_tick"] = float(Dictionary(Array(game.manifest_evolution_state.get("fields", [{}]))[0]).get("tick", 0.0)) if int(selected["fields"]) > 0 else 0.0
			last_evidence = {"baseline": baseline, "selected": selected, "effect": effect}
			# A field is valid only if a regular update consumed it (tick advanced),
			# never merely because the selection handler appended inert state.
			return int(selected["fields"]) > int(baseline["fields"]) and float(selected["field_tick"]) > 0.0
		"teleport_burst":
			_public_teleport(key)
			selected = _impact_snapshot(selected_targets)
			last_evidence = {"baseline": baseline, "selected": selected, "effect": effect}
			return float(selected["first_hp"]) < float(baseline["first_hp"]) or Vector2(selected["first_pos"]) != Vector2(baseline["first_pos"]) or float(selected["side_hp"]) < float(baseline["side_hp"]) or Vector2(selected["side_pos"]) != Vector2(baseline["side_pos"])
	return false


func _choose_prism_pair(entry: Dictionary) -> void:
	var stage := String(entry.get("stage", ""))
	if stage == "ev2":
		var companion := _entry_for("prismatica", "ev1", 0)
		game.manifest_evolution_options = [companion]
		game._choose_manifest_evolution(0)
	game.manifest_evolution_options = [entry]
	game._choose_manifest_evolution(0)


func _prism_state() -> Dictionary:
	return Dictionary(game.manifest_evolution_state.get("prismatica", {}))


func _compact_prism_evidence(effect: String, target: Dictionary = {}) -> Dictionary:
	var state := _prism_state()
	return {
		"effect": effect,
		"formations": Array(state.get("formations", [])).size(),
		"ghosts": Array(state.get("ghosts", [])).size(),
		"focus": Dictionary(state.get("focus", {})).size(),
		"bullets": game.bullets.size(),
		"target_hp": float(target.get("hp", 100000.0)),
		"target_stun": float(target.get("stun", 0.0)),
		"target_slow": float(target.get("evolution_slow", 0.0))
	}


func _exercise_prismatica(entry: Dictionary) -> bool:
	var profile: Dictionary = Dictionary(entry.get("profile", {}))
	var effect := String(profile.get("effect", ""))
	_prepare("prismatica")
	var baseline_targets: Array = game.enemies.duplicate()
	var baseline := {"formations": 0, "ghosts": 0, "second_hp": float(Dictionary(baseline_targets[1]).get("hp", 100000.0)), "third_hp": float(Dictionary(baseline_targets[2]).get("hp", 100000.0)), "stun": float(Dictionary(baseline_targets[0]).get("stun", 0.0)), "bullets": 0}
	match String(profile.get("hook", "")):
		"skill":
			_public_skill("prismatica")
			baseline["formations"] = Array(_prism_state().get("formations", [])).size()
		"teleport":
			_public_teleport("prismatica")
			_advance_combat(0.5, 2)
			baseline["ghosts"] = Array(_prism_state().get("ghosts", [])).size()
			baseline["bullets"] = game.bullets.size()
		_:
			_public_attack("prismatica", true)
			baseline["second_hp"] = float(Dictionary(baseline_targets[1]).get("hp", 100000.0))

	_prepare("prismatica")
	_choose_prism_pair(entry)
	var targets: Array = game.enemies.duplicate()
	match String(profile.get("hook", "")):
		"skill":
			if effect == "prismatica_colapso_cromatico":
				_public_skill("prismatica")
				_public_skill("prismatica")
				last_evidence = _compact_prism_evidence(effect, Dictionary(targets[0]))
				return float(Dictionary(targets[0]).get("hp", 100000.0)) < 100000.0 and Array(_prism_state().get("formations", [])).is_empty()
			_public_skill("prismatica")
			var formations: Array = Array(_prism_state().get("formations", []))
			if effect == "prismatica_prisma_harmonico":
				_advance_combat(0.8, 2)
				last_evidence = _compact_prism_evidence(effect, Dictionary(targets[0]))
				return float(Dictionary(targets[0]).get("hp", 100000.0)) < 100000.0 or float(Dictionary(targets[0]).get("evolution_slow", 0.0)) > 0.0
			if effect == "prismatica_rede_espectral":
				if formations.is_empty():
					return false
				var points: Array = Array(Dictionary(formations[0]).get("points", []))
				if points.size() != 3:
					return false
				game.enemies[0]["pos"] = Vector2(points[0]).lerp(Vector2(points[1]), 0.5)
				_advance_combat(0.8, 2)
				last_evidence = _compact_prism_evidence(effect, Dictionary(game.enemies[0]))
				return float(Dictionary(game.enemies[0]).get("hp", 100000.0)) < 100000.0 or float(Dictionary(game.enemies[0]).get("evolution_slow", 0.0)) > 0.0
			return formations.size() > int(baseline["formations"])
		"teleport":
			_public_teleport("prismatica")
			_advance_combat(0.5, 2)
			last_evidence = _compact_prism_evidence(effect)
			return game.bullets.size() > int(baseline["bullets"])
		_:
			if effect == "prismatica_foco_absoluto":
				game.enemies = [game.enemies[0]]
			var attempts := 4 if effect == "prismatica_foco_absoluto" else 1
			for _i in range(attempts):
				_public_attack("prismatica", true)
			if effect == "prismatica_reflexao_dupla" or effect == "prismatica_luz_recursiva":
				last_evidence = _compact_prism_evidence(effect, Dictionary(targets[2]))
				return float(Dictionary(targets[2]).get("hp", 100000.0)) < float(baseline["third_hp"])
			if effect == "prismatica_espectro_separado":
				last_evidence = _compact_prism_evidence(effect, Dictionary(targets[1]))
				return game.bullets.size() > 0 or float(Dictionary(targets[1]).get("hp", 100000.0)) < float(baseline["second_hp"])
			if effect == "prismatica_prisma_encadeado":
				last_evidence = _compact_prism_evidence(effect)
				return Array(_prism_state().get("formations", [])).size() > 0
			if effect == "prismatica_foco_absoluto":
				last_evidence = _compact_prism_evidence(effect, Dictionary(game.enemies[0]))
				return float(Dictionary(game.enemies[0]).get("stun", 0.0)) > float(baseline["stun"])
	return false


func _inventory_and_design_review(entries: Array) -> void:
	var grouped: Dictionary = {}
	for value in entries:
		var entry: Dictionary = Dictionary(value)
		var profile: Dictionary = Dictionary(entry.get("profile", {}))
		print("MANIFEST_EVOLUTION_INVENTORY_ROW id=%s manifestation=%s stage=%s trigger=%s source=%s baseline=no_choice expected=measurable_%s" % [String(entry.get("id", "")), String(entry.get("manifestation", "")), String(entry.get("stage", "")), String(profile.get("hook", "")), "public_attack_q_tp", String(profile.get("effect", ""))])
		var key := "%s|%s|%s" % [String(entry.get("stage", "")), String(profile.get("effect", "")), String(profile.get("hook", ""))]
		if String(entry.get("manifestation", "")) != "prismatica":
			if not grouped.has(key):
				grouped[key] = []
			grouped[key].append(String(entry.get("id", "")))
	for signature in grouped:
		var ids: Array = grouped[signature]
		if ids.size() > 1:
			design_review_groups.append("%s ids=%d" % [signature, ids.size()])
	print("MANIFEST_EVOLUTION_INVENTORY entries=%d expected=%d semantic_groups_for_design_review=%d" % [entries.size(), Catalog.TOTAL_EVOLUTIONS, design_review_groups.size()])
	for group in design_review_groups:
		print("MANIFEST_EVOLUTION_DESIGN_REVIEW " + group)


func _exercise_secondary_actions() -> void:
	# E is intentionally exercised through the public entry point for every
	# manifestation. It is a route-coverage guard; evolution assertions remain
	# tied to each evolution's documented hook above.
	for item_value in game.MANIFESTATIONS:
		var key := String(Dictionary(item_value).get("key", ""))
		_prepare(key)
		game.time_alive += 10.0
		game.last_secondary_time = -1000.0
		game._use_secondary_skill(game.player_pos + Vector2(112.0, 0.0))
		_advance_combat(0.15, 2)


func _run() -> void:
	game._start_game()
	var entries: Array = Catalog.all_entries()
	_inventory_and_design_review(entries)
	if entries.size() != Catalog.TOTAL_EVOLUTIONS:
		_fail("catalog size expected %d got %d" % [Catalog.TOTAL_EVOLUTIONS, entries.size()])
		quit(1)
		return
	_exercise_secondary_actions()
	for value in entries:
		var entry: Dictionary = Dictionary(value)
		var key := String(entry.get("manifestation", ""))
		var behavior_ok := _exercise_prismatica(entry) if key == "prismatica" else _exercise_generic(key, entry)
		checked_by_manifestation[key] = int(checked_by_manifestation.get(key, 0)) + 1
		if not behavior_ok:
			_record_failure(entry, "public %s route produced no measurable gameplay delta over baseline" % String(Dictionary(entry.get("profile", {})).get("hook", "unknown")))
	for item_value in game.MANIFESTATIONS:
		var key := String(Dictionary(item_value).get("key", ""))
		var count := int(checked_by_manifestation.get(key, 0))
		print("MANIFEST_EVOLUTION_COVERAGE manifestation=%s checked=%d/12" % [key, count])
		if count != 12:
			_fail("coverage incomplete for %s: %d/12" % [key, count])
	if blocked.is_empty() and behavioral_failures.is_empty():
		print("MANIFEST_EVOLUTION_PUBLIC_CONTRACT_OK definitions=180 source=public_attack_q_e_tp design_review_groups=%d" % design_review_groups.size())
	else:
		print("MANIFEST_EVOLUTION_PUBLIC_CONTRACT_REPROVED placebo=%d blocked=%d design_review_groups=%d" % [behavioral_failures.size(), blocked.size(), design_review_groups.size()])
		for item in blocked:
			push_warning("MANIFEST_EVOLUTION_BLOCKED " + item)
	game.set_process(false)
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	quit(0 if behavioral_failures.is_empty() and blocked.is_empty() else 1)
