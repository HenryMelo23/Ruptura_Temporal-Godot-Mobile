extends SceneTree

const EV1_IDS := [
	"prismatica_ev1_reflexao_dupla", "prismatica_ev1_prisma_espelhado", "prismatica_ev1_triangulacao",
	"prismatica_ev1_espectro_separado", "prismatica_ev1_prisma_encadeado", "prismatica_ev1_reflexo_fantasma"
]
const EV2_IDS := [
	"prismatica_ev2_geometria_perfeita", "prismatica_ev2_luz_recursiva", "prismatica_ev2_prisma_harmonico",
	"prismatica_ev2_foco_absoluto", "prismatica_ev2_rede_espectral", "prismatica_ev2_colapso_cromatico"
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
	push_error("PRISMATICA_EVOLUTION_FUNCTIONAL_FAIL " + message)
	quit(1)


func _entry(evolution_id: String) -> Dictionary:
	for entry in game._manifest_evolution_entries("prismatica"):
		if String(Dictionary(entry).get("id", "")) == evolution_id:
			return Dictionary(entry)
	return {}


func _reset(ev1_id: String, ev2_id: String = "") -> void:
	game.manifestation_key = "prismatica"
	game._reset_manifest_evolution_state()
	game.mode = "game"
	game.player_pos = Vector2(640, 360)
	game.last_facing = Vector2.RIGHT
	game.player_damage = 100.0
	game.enemies.clear()
	game.bullets.clear()
	game.shockwaves.clear()
	game.slashes.clear()
	game.boss_active = false
	game.boss_hp = 0.0
	game.manifest_evolution_options = [_entry(ev1_id)]
	game._choose_manifest_evolution(0)
	if ev2_id != "":
		game.manifest_evolution_options = [_entry(ev2_id)]
		game._choose_manifest_evolution(0)


func _bullet(pos: Vector2 = Vector2(640, 360)) -> Dictionary:
	var bullet := {"pos": pos, "origin": pos, "dir": Vector2.RIGHT, "damage": 80.0, "speed": 520.0, "life": 1.0, "max_life": 1.0, "age": 0.0, "phase": 0.0, "trail_cd": 0.0, "hits": {}, "color": Color.WHITE, "kind": "prismatica", "pierce": false, "ricochets": 0, "durability": 0.0}
	game._apply_manifest_evolution_to_bullet(bullet)
	return bullet


func _formations() -> Array:
	return Array(Dictionary(game.manifest_evolution_state.get("prismatica", {})).get("formations", []))


func _has_formation(kind: String) -> bool:
	for formation in _formations():
		if String(Dictionary(formation).get("kind", "")) == kind:
			return true
	return false


func _spawn_enemy(pos: Vector2) -> Dictionary:
	game._spawn_enemy(game.ENEMY_COMMON, pos)
	return game.enemies.back()


func _prove_ev1() -> void:
	_reset(EV1_IDS[0])
	var first := _spawn_enemy(Vector2(720, 360))
	_spawn_enemy(Vector2(800, 360))
	var reflection := _bullet()
	var reflection_keep: bool = game._manifest_evolution_on_projectile_hit(reflection, first, Vector2(first["pos"]))
	_check(reflection_keep and int(reflection.get("prism_reflections_left", 0)) == 1 and Vector2(reflection["dir"]).x > 0.9, "Reflexao Dupla did not redirect a ray")
	proofs[EV1_IDS[0]] = "redirected"

	_reset(EV1_IDS[1])
	game._manifest_evolution_on_skill(Vector2(700, 360))
	_check(_has_formation("mirror"), "Prisma Espelhado did not place a mirror")
	var mirror := _bullet(Vector2(700, 360))
	game._update_manifest_evolution_projectile(mirror, 0.016)
	_check(bool(mirror.get("prism_reflected", false)), "Prisma Espelhado did not reflect at the placed surface")
	proofs[EV1_IDS[1]] = "mirror_contact"

	_reset(EV1_IDS[2])
	game._manifest_evolution_on_skill(Vector2(700, 360))
	_check(_has_formation("triangle"), "Triangulacao did not place triangle")
	var triangle := _bullet(Vector2(700, 360))
	game._update_manifest_evolution_projectile(triangle, 0.016)
	_check(bool(triangle.get("prism_triangle_charged", false)), "Triangulacao did not charge a ray inside geometry")
	var triangle_target := _spawn_enemy(Vector2(730, 360))
	var before_waves: int = game.shockwaves.size()
	game._manifest_evolution_on_projectile_hit(triangle, triangle_target, Vector2(triangle_target["pos"]))
	_check(game.shockwaves.size() > before_waves, "Triangulacao did not release charged impact")
	proofs[EV1_IDS[2]] = "triangle_charge"

	_reset(EV1_IDS[3])
	var spectrum_target := _spawn_enemy(Vector2(710, 360))
	var spectrum := _bullet()
	var before_spectrum: int = game.bullets.size()
	game._manifest_evolution_on_projectile_hit(spectrum, spectrum_target, Vector2(spectrum_target["pos"]))
	_check(game.bullets.size() == before_spectrum + 2, "Espectro Separado did not emit two surface rays")
	proofs[EV1_IDS[3]] = "two_surface_rays"

	_reset(EV1_IDS[4])
	var chain_a := _spawn_enemy(Vector2(700, 360))
	var chain_b := _spawn_enemy(Vector2(790, 360))
	var chain := _bullet()
	game._manifest_evolution_on_projectile_hit(chain, chain_a, Vector2(chain_a["pos"]))
	game._manifest_evolution_on_projectile_hit(chain, chain_b, Vector2(chain_b["pos"]))
	_check(_has_formation("chain_link") and not game.slashes.is_empty(), "Prisma Encadeado did not connect anchors")
	proofs[EV1_IDS[4]] = "linked_targets"

	_reset(EV1_IDS[5])
	game._manifest_evolution_on_teleport(Vector2(560, 360), Vector2(640, 360))
	game._update_manifest_evolution_effects(0.50)
	_check(not game.bullets.is_empty() and bool(game.bullets.back().get("prism_ghost", false)), "Reflexo Fantasma did not replay teleport direction")
	proofs[EV1_IDS[5]] = "delayed_replay"


func _prove_ev2() -> void:
	_reset(EV1_IDS[0], EV2_IDS[0])
	game._manifest_evolution_on_skill(Vector2(700, 360))
	_check(_has_formation("perfect"), "Geometria Perfeita did not place perfect formation")
	var perfect := _bullet(Vector2(700, 360))
	_spawn_enemy(Vector2(780, 360))
	game._update_manifest_evolution_projectile(perfect, 0.016)
	_check(bool(perfect.get("prism_perfect_pierce", false)), "Geometria Perfeita did not align a ray")
	proofs[EV2_IDS[0]] = "aligned_pierce"

	_reset(EV1_IDS[0], EV2_IDS[1])
	var recursive_a := _spawn_enemy(Vector2(700, 360))
	_spawn_enemy(Vector2(780, 360))
	var recursive := _bullet()
	game._manifest_evolution_on_projectile_hit(recursive, recursive_a, Vector2(recursive_a["pos"]))
	_check(int(recursive.get("prism_recursive_left", 0)) == 0, "Luz Recursiva did not consume a conditional return")
	proofs[EV2_IDS[1]] = "conditional_return"

	_reset(EV1_IDS[0], EV2_IDS[2])
	game._manifest_evolution_on_skill(Vector2(700, 360))
	var harmonic_enemy := _spawn_enemy(Vector2(700, 360))
	var harmonic_hp: float = float(harmonic_enemy["hp"])
	game._update_manifest_evolution_effects(0.80)
	_check(_has_formation("harmonic") and float(harmonic_enemy["hp"]) < harmonic_hp, "Prisma Harmonico did not pulse")
	proofs[EV2_IDS[2]] = "timed_pulse"

	_reset(EV1_IDS[0], EV2_IDS[3])
	var focus_target := _spawn_enemy(Vector2(700, 360))
	var focus := _bullet()
	for hit in range(4):
		game._manifest_evolution_on_projectile_hit(focus, focus_target, Vector2(focus_target["pos"]))
	_check(float(focus_target.get("stun", 0.0)) > 0.0, "Foco Absoluto did not release on fourth hit")
	proofs[EV2_IDS[3]] = "four_hit_release"

	_reset(EV1_IDS[0], EV2_IDS[4])
	game._manifest_evolution_on_skill(Vector2(700, 360))
	var network_enemy := _spawn_enemy(Vector2(700, 250))
	var network_hp: float = float(network_enemy["hp"])
	game._update_manifest_evolution_effects(0.70)
	_check(_has_formation("network") and float(network_enemy["hp"]) < network_hp, "Rede Espectral did not damage a line crossing")
	proofs[EV2_IDS[4]] = "segment_intercept"

	_reset(EV1_IDS[1], EV2_IDS[5])
	game._manifest_evolution_on_skill(Vector2(700, 360))
	_check(_has_formation("mirror"), "Colapso setup did not retain mirror")
	var before_collapse: int = game.shockwaves.size()
	game._manifest_evolution_on_skill(Vector2(720, 360))
	_check(_formations().is_empty() and game.shockwaves.size() > before_collapse, "Colapso Cromatico did not consume formation")
	proofs[EV2_IDS[5]] = "formation_consumed"


func _prove_all_pairs() -> void:
	var pairs := 0
	for ev1_id in EV1_IDS:
		for ev2_id in EV2_IDS:
			_reset(ev1_id, ev2_id)
			game._manifest_evolution_on_skill(Vector2(700, 360))
			var pair_bullet := _bullet(Vector2(700, 360))
			game._update_manifest_evolution_projectile(pair_bullet, 0.016)
			var target := _spawn_enemy(Vector2(750, 360))
			game._manifest_evolution_on_projectile_hit(pair_bullet, target, Vector2(target["pos"]))
			game._update_manifest_evolution_effects(0.75)
			_check(game._manifest_evolution_choices().size() == 2, "%s + %s lost a chosen contract" % [ev1_id, ev2_id])
			_check(game.bullets.size() <= int(game.MAX_BULLETS), "%s + %s exceeded projectile cap" % [ev1_id, ev2_id])
			_check(_formations().size() <= 6, "%s + %s exceeded formation cap" % [ev1_id, ev2_id])
			pairs += 1
	proofs["pairs"] = pairs


func _prove_boss_and_budget() -> void:
	_reset(EV1_IDS[2], EV2_IDS[0])
	game.boss_active = true
	game.boss_hp = 10000.0
	game.boss_hp_max = 10000.0
	game.boss_pos = Vector2(700, 360)
	game._manifest_evolution_on_skill(Vector2(700, 360))
	var boss_bullet := _bullet(Vector2(700, 360))
	game._update_manifest_evolution_projectile(boss_bullet, 0.016)
	game._manifest_evolution_on_projectile_hit(boss_bullet, {"uid": "boss", "kind": "boss", "pos": game.boss_pos}, game.boss_pos)
	_check(game.boss_hp < 10000.0, "geometry burst did not affect boss")
	for i in range(24):
		game._manifest_evolution_on_skill(Vector2(650 + (i % 3) * 24, 340))
		game._update_manifest_evolution_effects(0.10)
	_check(_formations().size() <= 6, "repeated skills exceeded formation cap")
	game.boss_active = false
	game.boss_hp = 0.0
	proofs["boss"] = "geometry_damage"


func _run() -> void:
	game._start_game()
	game.mode = "game"
	_prove_ev1()
	_prove_ev2()
	_prove_all_pairs()
	_prove_boss_and_budget()
	_check(proofs.size() == 14, "expected 12 id proofs plus pair and boss proofs")
	print("PRISMATICA_EVOLUTION_FUNCTIONAL_OK ids=12 pairs=%d boss=%s capped_formations=true" % [int(proofs.get("pairs", 0)), String(proofs.get("boss", ""))])
	game.set_process(false)
	game._cleanup_runtime_resources()
	game.queue_free()
	game = null
	for frame in range(4):
		await process_frame
	quit(0)
