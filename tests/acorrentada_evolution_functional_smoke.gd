extends SceneTree

const EV1_IDS := [
	"acorrentada_ev1_corrente_tripla", "acorrentada_ev1_tensao_residual", "acorrentada_ev1_grilhao_movel",
	"acorrentada_ev1_elo_espelhado", "acorrentada_ev1_ancora_corrente", "acorrentada_ev1_sobretensao_continua"
]
const EV2_IDS := [
	"acorrentada_ev2_teia_grilhoes", "acorrentada_ev2_ruptura_sequencial", "acorrentada_ev2_corrente_arrasto",
	"acorrentada_ev2_prisao_total", "acorrentada_ev2_sobrecarga_tensao", "acorrentada_ev2_sentenca_ferro"
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
	push_error("ACORRENTADA_EVOLUTION_FUNCTIONAL_FAIL " + message)
	quit(1)


func _entry(evolution_id: String) -> Dictionary:
	for entry_value in game._manifest_evolution_entries("acorrentada"):
		var entry := Dictionary(entry_value)
		if String(entry.get("id", "")) == evolution_id:
			return entry
	return {}


func _reset(ev1_id: String, ev2_id: String = "") -> void:
	game.manifestation_key = "acorrentada"
	game._reset_manifest_evolution_state()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.player_start_down_fall_timer = 0.0
	game.player_start_down_landing_timer = 0.0
	game.time_alive = 1000.0
	game.last_attack_time = -1000.0
	game.last_skill_time = -1000.0
	game.last_secondary_time = -1000.0
	game.last_dash_time = -1000.0
	game.acorrentada_combo_step = 1
	game.acorrentada_combo_reset_timer = 0.0
	game.acorrentada_tension = 0.0
	game.acorrentada_overcharge_ready = false
	game.acorrentada_links.clear()
	game.acorrentada_visuals.clear()
	game.acorrentada_worn_chains.clear()
	game.manifestation_secondaries.clear()
	game.enemies.clear()
	game.bullets.clear()
	game.shockwaves.clear()
	game.slashes.clear()
	game.effects.clear()
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
	return Dictionary(game.manifest_evolution_state.get("acorrentada", {}))


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
		game._update_manifest_evolution_effects(delta)
		game._update_acorrentada_state(delta)


func _typed_hit(target: Dictionary, suffix: String) -> void:
	game._manifest_evolution_on_combat_hit("acorrentada_test:%s" % suffix, "acorrentada", target, Vector2(target.get("pos", game.player_pos)))


func _public_combo_three() -> void:
	game.effects = game.effects.filter(func(effect): return not bool(Dictionary(effect).get("skill_lock", false)))
	game.time_alive += 10.0
	game.last_attack_time = -1000.0
	game.acorrentada_combo_step = 3
	game._try_attack()
	_advance(0.03, 52)


func _public_q(center: Vector2) -> void:
	game.effects = game.effects.filter(func(effect): return not bool(Dictionary(effect).get("skill_lock", false)))
	game.time_alive += 10.0
	game.last_skill_time = -1000.0
	game._use_skill(center)


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
	var triple_primary := _spawn_enemy(Vector2(742, 360))
	var triple_extra := _spawn_enemy(Vector2(812, 382))
	var extra_hp := float(triple_extra["hp"])
	_public_combo_three()
	_check(float(triple_primary["hp"]) < 100000.0, "Corrente Tripla did not resolve the base third combo hit")
	_check(float(triple_extra["hp"]) < extra_hp and int(_metrics().get(EV1_IDS[0], 0)) == 1, "Corrente Tripla did not create a functional third capture")
	_check(game.bullets.is_empty(), "Corrente Tripla incorrectly depended on a projectile")
	proofs[EV1_IDS[0]] = "third_segment_hit"

	_reset(EV1_IDS[1])
	game._add_acorrentada_tension(100.0)
	_check(is_equal_approx(float(_state().get("residual", 0.0)), 30.0), "Tensao Residual did not bank capped energy")
	_check(game._consume_acorrentada_overcharge(), "Tensao Residual setup did not consume overcharge")
	_check(is_equal_approx(float(game.acorrentada_tension), 65.0) and is_zero_approx(float(_state().get("residual", -1.0))), "Tensao Residual did not restore banked energy")
	proofs[EV1_IDS[1]] = "banked_30_restored"

	_reset(EV1_IDS[2])
	var mobile_target := _spawn_enemy(Vector2(742, 360))
	var mobile_neighbor := _spawn_enemy(Vector2(820, 390))
	_typed_hit(mobile_target, "mobile")
	mobile_target["pos"] = Vector2(770, 390)
	var neighbor_before := Vector2(mobile_neighbor["pos"])
	_advance(0.46, 1)
	var shackles := Array(_state().get("shackles", []))
	_check(shackles.size() == 1 and Vector2(Dictionary(shackles[0]).get("pos", Vector2.ZERO)) == Vector2(mobile_target["pos"]), "Grilhao Movel did not follow its bound target")
	_check(Vector2(mobile_neighbor["pos"]) != neighbor_before, "Grilhao Movel did not influence a nearby enemy")
	proofs[EV1_IDS[2]] = "followed_and_pulled"

	_reset(EV1_IDS[3])
	var mirror_source := _spawn_enemy(Vector2(742, 360))
	var mirror_target := _spawn_enemy(Vector2(830, 360))
	var mirror_hp := float(mirror_target["hp"])
	_typed_hit(mirror_source, "mirror")
	_check(float(mirror_target["hp"]) < mirror_hp and game._acorrentada_enemy_elos(mirror_target) == 1, "Elo Espelhado did not damage and mark the reflected target")
	proofs[EV1_IDS[3]] = "reflected_to_neighbor"

	_reset(EV1_IDS[4])
	var anchor_target := _spawn_enemy(Vector2(760, 360))
	var anchor_before := Vector2(anchor_target["pos"])
	_public_q(Vector2(700, 360))
	_advance(0.56, 1)
	_check(Array(_state().get("anchors", [])).size() == 1, "Ancora De Corrente did not persist a real anchor")
	_check(Vector2(anchor_target["pos"]) != anchor_before and game._acorrentada_enemy_elos(anchor_target) > 0, "Ancora De Corrente did not pull and mark")
	proofs[EV1_IDS[4]] = "territorial_anchor_tick"

	_reset(EV1_IDS[5])
	_spawn_enemy(Vector2(742, 360))
	_spawn_enemy(Vector2(804, 380))
	_public_q(Vector2(760, 360))
	game.acorrentada_tension = 40.0
	game.acorrentada_last_hit_timer = 20.0
	_advance(0.5, 2)
	_check(float(game.acorrentada_tension) >= 41.0 and float(game.acorrentada_last_hit_timer) <= 0.51, "Sobretensao Continua did not suspend decay and pulse while bound")
	proofs[EV1_IDS[5]] = "binding_sustained_tension"


func _prove_ev2() -> void:
	_reset(EV1_IDS[0], EV2_IDS[0])
	var web_targets := [
		_spawn_enemy(Vector2(710, 315)), _spawn_enemy(Vector2(800, 325)),
		_spawn_enemy(Vector2(820, 410)), _spawn_enemy(Vector2(710, 420))
	]
	_public_q(Vector2(760, 365))
	var web_hp := float(Dictionary(web_targets[0])["hp"])
	_advance(0.36, 1)
	_check(Array(_state().get("webs", [])).size() == 1 and int(_metrics().get("web_hits", 0)) > 0, "Teia De Grilhoes did not tick its physical network")
	_check(float(Dictionary(web_targets[0])["hp"]) < web_hp, "Teia De Grilhoes segment was visual-only")
	proofs[EV2_IDS[0]] = "bounded_network_hit"

	_reset(EV1_IDS[0], EV2_IDS[1])
	var sequence_targets := [_spawn_enemy(Vector2(720, 360)), _spawn_enemy(Vector2(770, 360)), _spawn_enemy(Vector2(820, 360))]
	for index in range(3):
		_typed_hit(Dictionary(sequence_targets[index]), "sequence_%d" % index)
	_advance(0.18, 3)
	_check(int(_metrics().get("sequence_pulses", 0)) == 3 and Array(_state().get("ruptures", [])).is_empty(), "Ruptura Sequencial did not resolve three ordered pulses")
	proofs[EV2_IDS[1]] = "three_ordered_pulses"

	_reset(EV1_IDS[0], EV2_IDS[2])
	var drag_a := _spawn_enemy(Vector2(700, 360))
	var drag_b := _spawn_enemy(Vector2(750, 380))
	var drag_before_a := Vector2(drag_a["pos"])
	var drag_before_b := Vector2(drag_b["pos"])
	_public_tp(Vector2(840, 360))
	_check(Vector2(drag_a["pos"]).distance_to(Vector2(840, 360)) < drag_before_a.distance_to(Vector2(840, 360)), "Corrente De Arrasto did not move first crossed target")
	_check(Vector2(drag_b["pos"]).distance_to(Vector2(840, 360)) < drag_before_b.distance_to(Vector2(840, 360)), "Corrente De Arrasto did not move second crossed target")
	proofs[EV2_IDS[2]] = "teleport_path_drag"

	_reset(EV1_IDS[0], EV2_IDS[3])
	var prison_target := _spawn_enemy(Vector2(720, 360))
	game.boss_active = true
	game.boss_hp = 100000.0
	game.boss_hp_max = 100000.0
	game.boss_pos = Vector2(750, 360)
	_public_q(Vector2(735, 360))
	_check(float(prison_target.get("stun", 0.0)) >= 1.15, "Prisao Total did not immobilize the group target")
	_check(float(game.boss_tp_stun_timer) > 0.0 and float(game.boss_tp_stun_timer) <= 0.18, "Prisao Total did not apply boss resistance")
	var prison_metric := int(_metrics().get(EV2_IDS[3], 0))
	_public_q(Vector2(735, 360))
	_check(int(_metrics().get(EV2_IDS[3], 0)) == prison_metric, "Prisao Total ignored its anti-loop cooldown")
	proofs[EV2_IDS[3]] = "group_prison_boss_resistant"

	_reset(EV1_IDS[0], EV2_IDS[4])
	var overload_source := _spawn_enemy(Vector2(720, 360))
	var overload_side := _spawn_enemy(Vector2(800, 360))
	game.acorrentada_tension = 100.0
	_check(game._consume_acorrentada_overcharge(), "Sobrecarga De Tensao setup did not consume overcharge")
	var overload_hp := float(overload_side["hp"])
	_typed_hit(overload_source, "overload")
	_check(float(overload_side["hp"]) < overload_hp and float(_state().get("overload_timer", 0.0)) > 0.0, "Sobrecarga De Tensao did not conduct during its timed window")
	proofs[EV2_IDS[4]] = "four_second_conduction"

	_reset(EV1_IDS[0], EV2_IDS[5])
	var verdict_target := _spawn_enemy(Vector2(720, 360))
	_spawn_enemy(Vector2(790, 380))
	_public_e(Vector2(750, 360))
	_check(not Dictionary(_state().get("verdicts", {})).is_empty(), "Sentenca De Ferro did not mark E targets")
	var verdict_hp := float(verdict_target["hp"])
	_typed_hit(verdict_target, "verdict")
	_check(float(verdict_target["hp"]) < verdict_hp and float(verdict_target.get("stun", 0.0)) >= 0.35, "Sentenca De Ferro did not consume its delayed verdict")
	proofs[EV2_IDS[5]] = "e_verdict_consumed"


func _prove_synergies_and_all_pairs() -> void:
	_reset(EV1_IDS[1], EV2_IDS[4])
	game._add_acorrentada_tension(100.0)
	game._consume_acorrentada_overcharge()
	_check(is_equal_approx(float(game.acorrentada_tension), 65.0) and float(_state().get("overload_timer", 0.0)) == 4.0, "Residual + Overload did not preserve both mechanics")
	proofs["synergy_residual_overload"] = true

	_reset(EV1_IDS[2], EV2_IDS[0])
	var mobile_web_a := _spawn_enemy(Vector2(710, 330))
	_spawn_enemy(Vector2(805, 330))
	_spawn_enemy(Vector2(805, 410))
	_typed_hit(mobile_web_a, "mobile_web")
	_public_q(Vector2(755, 365))
	_advance(0.5, 1)
	_check(Array(_state().get("shackles", [])).size() == 1 and Array(_state().get("webs", [])).size() == 1, "Mobile Shackle + Web did not coexist")
	proofs["synergy_mobile_web"] = true
	var save_snapshot: Dictionary = Dictionary(game._build_interrupted_run_snapshot())
	var saved_evolution := Dictionary(Dictionary(Dictionary(save_snapshot.get("fields", {})).get("manifest_evolution_state", {})).get("acorrentada", {}))
	_check(Array(saved_evolution.get("shackles", [])).size() == 1 and Array(saved_evolution.get("webs", [])).size() == 1, "save snapshot did not preserve Acorrentada mechanic state")
	proofs["save_snapshot"] = true

	var pairs := 0
	for ev1_id in EV1_IDS:
		for ev2_id in EV2_IDS:
			_reset(ev1_id, ev2_id)
			var targets := [
				_spawn_enemy(Vector2(708, 330)), _spawn_enemy(Vector2(770, 350)),
				_spawn_enemy(Vector2(824, 390)), _spawn_enemy(Vector2(730, 425))
			]
			_typed_hit(Dictionary(targets[0]), "%s:%s:a" % [ev1_id, ev2_id])
			_typed_hit(Dictionary(targets[1]), "%s:%s:b" % [ev1_id, ev2_id])
			_typed_hit(Dictionary(targets[2]), "%s:%s:c" % [ev1_id, ev2_id])
			_public_q(Vector2(760, 370))
			_public_tp(Vector2(820, 370))
			_public_e(Vector2(760, 370))
			_advance(0.2, 6)
			var state := _state()
			_check(game._manifest_evolution_choices().size() == 2, "%s + %s lost its two selected contracts" % [ev1_id, ev2_id])
			_check(Array(state.get("shackles", [])).size() <= 2, "%s + %s exceeded shackle cap" % [ev1_id, ev2_id])
			_check(Array(state.get("anchors", [])).size() <= 2, "%s + %s exceeded anchor cap" % [ev1_id, ev2_id])
			_check(Array(state.get("webs", [])).size() <= 1, "%s + %s exceeded web cap" % [ev1_id, ev2_id])
			_check(Array(state.get("ruptures", [])).size() <= 6, "%s + %s exceeded rupture cap" % [ev1_id, ev2_id])
			_check(Dictionary(state.get("verdicts", {})).size() <= 6, "%s + %s exceeded verdict cap" % [ev1_id, ev2_id])
			pairs += 1
	proofs["pairs"] = pairs


func _run() -> void:
	game._start_game()
	game.mode = "game"
	_prove_ev1()
	_prove_ev2()
	_prove_synergies_and_all_pairs()
	_check(proofs.size() == 16, "expected 12 ID proofs, two synergy proofs, save proof and pair proof")
	print("ACORRENTADA_EVOLUTION_FUNCTIONAL_OK ids=12 pairs=%d synergies=2 save_snapshot=true combo_projectiles=0 boss_resistant=true caps=true" % int(proofs.get("pairs", 0)))
	game.set_process(false)
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for _frame in range(4):
		await process_frame
	quit(0)
