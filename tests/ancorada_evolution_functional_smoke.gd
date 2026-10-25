extends SceneTree

const EV1_IDS := [
	"ancorada_ev1_fundacao_profunda", "ancorada_ev1_muralha_ruptura", "ancorada_ev1_peso_absoluto",
	"ancorada_ev1_territorio_jurado", "ancorada_ev1_contra_impacto", "ancorada_ev1_linha_fundacao"
]
const EV2_IDS := [
	"ancorada_ev2_fortaleza_autoportante", "ancorada_ev2_coracao_fortaleza", "ancorada_ev2_queda_monumental",
	"ancorada_ev2_rede_fundacoes", "ancorada_ev2_ultimo_bastiao", "ancorada_ev2_continente_imovel"
]

var game: Node
var proofs: Dictionary = {}


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("ANCORADA_EVOLUTION_FUNCTIONAL_FAIL " + message)
	quit(1)


func _entry(evolution_id: String) -> Dictionary:
	for entry_value in game._manifest_evolution_entries("ancorada"):
		var entry := Dictionary(entry_value)
		if String(entry.get("id", "")) == evolution_id:
			return entry
	return {}


func _reset(ev1_id: String, ev2_id: String = "") -> void:
	game.manifestation_key = "ancorada"
	game._reset_manifest_evolution_state()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.player_hp_max = 1000.0
	game.player_hp = 1000.0
	game.is_dead = false
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 1000.0
	game.last_attack_time = -1000.0
	game.last_skill_time = -1000.0
	game.last_secondary_time = -1000.0
	game.last_dash_time = -1000.0
	game.lastro_stacks = 0
	game.lastro_points = 0
	game.hab1_ancorada_active = false
	game.hab1_ancorada_impact_done = false
	game.anchors.clear()
	game.enemies.clear()
	game.enemy_bullets.clear()
	game.bullets.clear()
	game.manifestation_secondaries.clear()
	game.effects.clear()
	game.shockwaves.clear()
	game.slashes.clear()
	game.boss_active = false
	game.boss_hp = 0.0
	game.boss_hp_max = 0.0
	game.boss_tp_stun_timer = 0.0
	game.manifest_evolution_options = [_entry(ev1_id)]
	game._choose_manifest_evolution(0)
	if ev2_id != "":
		game.manifest_evolution_options = [_entry(ev2_id)]
		game._choose_manifest_evolution(0)


func _state() -> Dictionary:
	return Dictionary(game.manifest_evolution_state.get("ancorada", {}))


func _metrics() -> Dictionary:
	return Dictionary(_state().get("metrics", {}))


func _spawn_enemy(pos: Vector2) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	var enemy: Dictionary = game.enemies.back()
	enemy["hp"] = 100000.0
	enemy["max_hp"] = 100000.0
	return enemy


func _advance(delta: float, frames: int) -> void:
	for _frame in range(frames):
		game._update_ancorada_standing_still(delta)
		game._update_manifest_evolution_effects(delta)


func _typed_hit(target: Dictionary, suffix: String) -> void:
	game._manifest_evolution_on_combat_hit("ancorada_test:%s" % suffix, "ancorada", target, Vector2(target.get("pos", game.player_pos)))


func _place_anchor(pos: Vector2, linked_from: Vector2 = Vector2.ZERO, source: String = "ancorada_test") -> Dictionary:
	var origin: Vector2 = linked_from if linked_from != Vector2.ZERO else Vector2(game.player_pos)
	return game._place_anchor(pos, origin, source, true)


func _public_q(center: Vector2) -> void:
	game.effects = game.effects.filter(func(effect): return not bool(Dictionary(effect).get("skill_lock", false)))
	game.time_alive += 10.0
	game.last_skill_time = -1000.0
	game._use_skill(center)
	_advance(0.10, 5)


func _public_tp(destination: Vector2) -> void:
	game.effects = game.effects.filter(func(effect): return not bool(Dictionary(effect).get("skill_lock", false)))
	game.time_alive += 10.0
	game.last_dash_time = -1000.0
	game._execute_teleport(destination)


func _public_e(center: Vector2) -> void:
	game.effects = game.effects.filter(func(effect): return not bool(Dictionary(effect).get("skill_lock", false)))
	game.time_alive += 10.0
	game.last_secondary_time = -1000.0
	game._use_secondary_skill(center)


func _prove_ev1() -> void:
	_reset(EV1_IDS[0])
	var deep := _place_anchor(Vector2(720, 360))
	_check(float(deep.get("life", 0.0)) == 12.0 and float(deep.get("structure_hp", 0.0)) == 220.0, "Fundacao Profunda did not extend a real anchor")
	game.player_pos = Vector2(720, 360)
	_advance(0.55, 4)
	_check(int(game.lastro_points) > 0 and int(_metrics().get("deep_lastro_pulses", 0)) > 0, "Fundacao Profunda did not generate Lastro near its persistent anchor")
	proofs[EV1_IDS[0]] = "anchor_12s_lastro_pulse"

	_reset(EV1_IDS[1])
	_public_q(Vector2(760, 360))
	var walls := Array(_state().get("walls", []))
	_check(walls.size() == 1 and float(Dictionary(walls[0]).get("hp", 0.0)) == 420.0, "Muralha De Ruptura did not create a structure with HP")
	var wall := Dictionary(walls[0])
	var wall_center := (Vector2(wall["a"]) + Vector2(wall["b"])) * 0.5
	var routed := _spawn_enemy(wall_center)
	var routed_before := Vector2(routed["pos"])
	_advance(0.09, 1)
	_check(Vector2(routed["pos"]) != routed_before and float(wall.get("hp", 420.0)) < 420.0, "Muralha De Ruptura did not block, reroute and lose integrity")
	_check(Vector2(routed["pos"]).x >= 40.0 and Vector2(routed["pos"]).x <= game.WORLD_SIZE.x - 40.0, "Muralha routed an enemy outside map limits")
	wall["hp"] = 10.0
	_spawn_enemy(wall_center)
	_advance(0.09, 2)
	_check(Array(_state().get("walls", [])).is_empty(), "Muralha De Ruptura did not disappear when structural HP reached zero")
	proofs[EV1_IDS[1]] = "wall_hp_destroyed_path_detour"

	_reset(EV1_IDS[2])
	game.lastro_stacks = 3
	var weighted := _spawn_enemy(Vector2(740, 360))
	_typed_hit(weighted, "absolute")
	weighted["pos"] = Vector2(860, 360)
	_advance(0.10, 1)
	_check(Vector2(weighted["pos"]).x < 860.0 and Array(_state().get("absolute_pins", [])).size() == 1, "Peso Absoluto did not hold the moving target at the impact point")
	proofs[EV1_IDS[2]] = "moving_target_pinned"

	_reset(EV1_IDS[3])
	var oath_target := _spawn_enemy(Vector2(760, 360))
	var oath_hp := float(oath_target["hp"])
	_public_q(Vector2(760, 360))
	game.enemy_bullets.append({"pos": Vector2(760, 360), "dir": Vector2.LEFT, "life": 3.0, "damage": 100.0, "speed_mult": 1.0})
	_advance(0.11, 1)
	var oath_bullet := Dictionary(game.enemy_bullets[0])
	_check(float(oath_target["hp"]) < oath_hp and is_equal_approx(float(oath_bullet["damage"]), 65.0), "Territorio Jurado did not apply entry impact and projectile protection")
	_check(is_equal_approx(float(oath_bullet["speed_mult"]), 0.58), "Territorio Jurado did not slow a hostile projectile")
	proofs[EV1_IDS[3]] = "domain_entry_and_projectile_guard"

	_reset(EV1_IDS[4])
	var counter_anchor := _place_anchor(Vector2(720, 360))
	var counter_target := _spawn_enemy(Vector2(744, 360))
	var counter_hp := float(counter_target["hp"])
	var counter_pos := Vector2(counter_target["pos"])
	_advance(0.09, 1)
	_check(float(counter_target["hp"]) < counter_hp and Vector2(counter_target["pos"]) != counter_pos, "Contra-Impacto did not retaliate from an anchor collision")
	_check(not counter_anchor.is_empty() and int(_metrics().get(EV1_IDS[4], 0)) == 1, "Contra-Impacto ignored its per-target gate")
	proofs[EV1_IDS[4]] = "anchor_collision_countered"

	_reset(EV1_IDS[5])
	_place_anchor(Vector2(680, 330))
	_place_anchor(Vector2(840, 390))
	var lines := Array(_state().get("foundation_lines", []))
	_check(lines.size() == 1 and int(Dictionary(lines[0]).get("charges", 0)) == 3, "Linha De Fundacao did not connect consecutive anchors")
	var line := Dictionary(lines[0])
	game.enemy_bullets.append({"pos": (Vector2(line["a"]) + Vector2(line["b"])) * 0.5, "life": 3.0, "damage": 50.0})
	_advance(0.11, 1)
	_check(float(Dictionary(game.enemy_bullets[0]).get("life", 1.0)) <= 0.0 and int(line.get("charges", 0)) == 2, "Linha De Fundacao did not spend one charge intercepting a projectile")
	proofs[EV1_IDS[5]] = "three_charge_defensive_line"


func _prove_ev2() -> void:
	_reset(EV1_IDS[0], EV2_IDS[0])
	var fortress_target := _spawn_enemy(Vector2(770, 360))
	_public_q(Vector2(760, 360))
	var fortresses := Array(_state().get("fortresses", []))
	var fortress_hp := float(fortress_target["hp"])
	_advance(0.10, 9)
	_check(fortresses.size() == 1 and Array(Dictionary(fortresses[0]).get("pillars", [])).size() == 3, "Fortaleza Autoportante did not erect three physical pillars")
	_check(float(fortress_target["hp"]) < fortress_hp and int(_metrics().get("fortress_shots", 0)) > 0, "Fortaleza Autoportante did not attack autonomously")
	proofs[EV2_IDS[0]] = "three_pillars_autonomous_hit"

	_reset(EV1_IDS[0], EV2_IDS[1])
	_place_anchor(Vector2(680, 340))
	_place_anchor(Vector2(820, 380))
	game.enemy_bullets.append({"pos": Vector2(750, 360), "life": 3.0, "damage": 100.0, "speed_mult": 1.0})
	_advance(0.76, 1)
	_check(is_equal_approx(float(Dictionary(game.enemy_bullets[0]).get("damage", 0.0)), 78.0), "Coracao Da Fortaleza did not protect the center between anchors")
	_check(int(_metrics().get(EV2_IDS[1], 0)) > 0, "Coracao Da Fortaleza did not pulse from two foundations")
	proofs[EV2_IDS[1]] = "two_anchor_repair_heart"

	_reset(EV1_IDS[0], EV2_IDS[2])
	var fall_target := _spawn_enemy(Vector2(800, 360))
	var fall_hp := float(fall_target["hp"])
	var fall_pos := Vector2(fall_target["pos"])
	_public_tp(Vector2(800, 360))
	_advance(0.11, 5)
	var monuments := Array(_state().get("monuments", []))
	_check(monuments.size() == 1 and bool(Dictionary(monuments[0]).get("landed", false)), "Queda Monumental did not land after its telegraph")
	_check(float(fall_target["hp"]) < fall_hp and Vector2(fall_target["pos"]) != fall_pos and float(Dictionary(monuments[0]).get("hp", 0.0)) > 0.0, "Queda Monumental was visual-only")
	proofs[EV2_IDS[2]] = "delayed_drop_damage_obstacle"

	_reset(EV1_IDS[0], EV2_IDS[3])
	_place_anchor(Vector2(690, 350))
	_place_anchor(Vector2(825, 370))
	var network_source := _spawn_enemy(Vector2(700, 350))
	var network_side := _spawn_enemy(Vector2(825, 370))
	var network_hp := float(network_side["hp"])
	_typed_hit(network_source, "network")
	_check(float(network_side["hp"]) < network_hp and int(_metrics().get(EV2_IDS[3], 0)) > 0, "Rede De Fundacoes did not transmit charge to another anchor")
	_check(Array(_state().get("network_arcs", [])).size() <= 8, "Rede De Fundacoes exceeded its visual arc cap")
	proofs[EV2_IDS[3]] = "distinct_target_load_transmission"

	_reset(EV1_IDS[0], EV2_IDS[4])
	game.player_hp = 240.0
	game.enemy_bullets.append({"pos": game.player_pos, "life": 3.0, "damage": 80.0})
	_advance(0.11, 1)
	var bastion := Dictionary(_state().get("bastion", {}))
	_check(not bastion.is_empty() and float(Dictionary(game.enemy_bullets[0]).get("life", 1.0)) <= 0.0, "Ultimo Bastiao did not react to critical risk and absorb the projectile")
	_check(float(bastion.get("hp", 0.0)) < float(bastion.get("max_hp", 0.0)) and float(_state().get("bastion_cooldown", 0.0)) > 31.0, "Ultimo Bastiao lacks bounded HP/cooldown state")
	proofs[EV2_IDS[4]] = "critical_hp_projectile_refuge"

	_reset(EV1_IDS[0], EV2_IDS[5])
	_public_e(game.player_pos)
	var continent := Dictionary(_state().get("continent", {}))
	var nodes := Array(continent.get("nodes", []))
	_check(nodes.size() >= 3 and nodes.size() <= 5, "Continente Imovel did not create bounded structural borders")
	var border_mid := (Vector2(nodes[0]) + Vector2(nodes[1])) * 0.5
	var border_target := _spawn_enemy(border_mid)
	var border_before := Vector2(border_target["pos"])
	game.boss_active = true
	game.boss_hp = 100000.0
	game.boss_hp_max = 100000.0
	game.boss_pos = border_mid
	_advance(0.09, 1)
	_check(Vector2(border_target["pos"]) != border_before, "Continente Imovel did not redirect a moving enemy at its border")
	_check(float(game.boss_tp_stun_timer) > 0.0 and float(game.boss_tp_stun_timer) <= 0.05, "Continente Imovel did not preserve boss resistance")
	proofs[EV2_IDS[5]] = "ultimate_polygon_boundary"


func _prove_synergies_and_all_pairs() -> void:
	_reset(EV1_IDS[0], EV2_IDS[3])
	var deep_a := _place_anchor(Vector2(690, 350))
	var deep_b := _place_anchor(Vector2(825, 370))
	var deep_source := _spawn_enemy(Vector2(700, 350))
	var deep_side := _spawn_enemy(Vector2(825, 370))
	var deep_side_hp := float(deep_side["hp"])
	_typed_hit(deep_source, "deep_network")
	_check(bool(deep_a.get("deep_foundation", false)) and bool(deep_b.get("deep_foundation", false)) and float(deep_side["hp"]) < deep_side_hp, "Fundacao Profunda + Rede did not preserve persistence and transmission")
	proofs["synergy_deep_network"] = true

	_reset(EV1_IDS[1], EV2_IDS[1])
	_public_q(Vector2(760, 360))
	_place_anchor(Vector2(610, 360))
	var synergy_wall := Dictionary(Array(_state().get("walls", []))[0])
	synergy_wall["hp"] = 300.0
	_advance(0.76, 1)
	_check(float(synergy_wall.get("hp", 0.0)) > 300.0, "Muralha + Coracao did not repair structural HP")
	proofs["synergy_wall_heart"] = true

	_reset(EV1_IDS[3], EV2_IDS[4])
	_public_q(Vector2(700, 360))
	game.player_pos = Vector2(700, 360)
	game.player_hp = 240.0
	game.enemy_bullets.append({"pos": game.player_pos, "life": 3.0, "damage": 100.0, "speed_mult": 1.0})
	_advance(0.11, 1)
	_check(not Dictionary(_state().get("bastion", {})).is_empty() and float(Dictionary(game.enemy_bullets[0]).get("life", 1.0)) <= 0.0, "Territorio + Bastiao did not layer proactive and emergency defense")
	proofs["synergy_domain_bastion"] = true

	var save_snapshot: Dictionary = Dictionary(game._build_interrupted_run_snapshot())
	var saved_state := Dictionary(Dictionary(Dictionary(save_snapshot.get("fields", {})).get("manifest_evolution_state", {})).get("ancorada", {}))
	_check(not Dictionary(saved_state.get("bastion", {})).is_empty() and Array(saved_state.get("domains", [])).size() == 1, "save snapshot did not preserve Ancorada structures")
	proofs["save_snapshot"] = true

	var pairs := 0
	for ev1_id in EV1_IDS:
		for ev2_id in EV2_IDS:
			_reset(ev1_id, ev2_id)
			var targets := [_spawn_enemy(Vector2(710, 340)), _spawn_enemy(Vector2(790, 370)), _spawn_enemy(Vector2(840, 410))]
			_place_anchor(Vector2(690, 330))
			_place_anchor(Vector2(820, 390))
			game.lastro_stacks = 3
			_typed_hit(Dictionary(targets[0]), "%s:%s" % [ev1_id, ev2_id])
			_public_q(Vector2(760, 370))
			_public_tp(Vector2(840, 370))
			_public_e(Vector2(760, 370))
			game.player_hp = 240.0
			_advance(0.12, 7)
			var state := _state()
			_check(game._manifest_evolution_choices().size() == 2, "%s + %s lost one selected contract" % [ev1_id, ev2_id])
			_check(Array(state.get("walls", [])).size() <= 2, "%s + %s exceeded wall cap" % [ev1_id, ev2_id])
			_check(Array(state.get("domains", [])).size() <= 1, "%s + %s exceeded domain cap" % [ev1_id, ev2_id])
			_check(Array(state.get("foundation_lines", [])).size() <= 3, "%s + %s exceeded foundation-line cap" % [ev1_id, ev2_id])
			_check(Array(state.get("fortresses", [])).size() <= 1, "%s + %s exceeded fortress cap" % [ev1_id, ev2_id])
			_check(Array(state.get("monuments", [])).size() <= 3, "%s + %s exceeded monument cap" % [ev1_id, ev2_id])
			_check(Array(state.get("absolute_pins", [])).size() <= 3, "%s + %s exceeded pin cap" % [ev1_id, ev2_id])
			pairs += 1
	proofs["pairs"] = pairs


func _run() -> void:
	game._start_game()
	game.mode = "game"
	_prove_ev1()
	_prove_ev2()
	_prove_synergies_and_all_pairs()
	_check(proofs.size() == 17, "expected 12 ID proofs, three synergies, save and pair proofs")
	print("ANCORADA_EVOLUTION_FUNCTIONAL_OK ids=12 pairs=%d synergies=3 save_snapshot=true structures_hp=true path_detour=true map_bounds=true boss_resistant=true caps=true" % int(proofs.get("pairs", 0)))
	game.set_process(false)
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	quit(0)
