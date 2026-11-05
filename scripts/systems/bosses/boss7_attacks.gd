class_name RTBoss7Attacks
extends RefCounted

## Mecanicas da Fenix que faltavam: a Chuva de Fogo (sky fireballs) so desenhava
## o aviso e nunca causava dano. Agora cada meteoro cai em sequencia, explode e
## deixa uma brasa curta no chao.

const METEOR_RADIUS := 46.0
const METEOR_STAGGER := 0.06
const METEOR_BURN_TIME := 1.6
const METEOR_BURN_TICK := 0.4


static func update_sky_fireballs(game: Node, attack: Dictionary, age: float, delta: float) -> void:
	var spots: Array = attack.get("spots", [])
	var warning: float = float(attack.get("warning", 0.85))
	var landed: Dictionary = attack.get("landed", {})
	var burn_cd: float = float(attack.get("burn_cd", 0.0)) - delta
	for i in range(spots.size()):
		var hit_t: float = warning + float(i) * METEOR_STAGGER
		if age < hit_t or landed.has(i):
			continue
		landed[i] = true
		var p: Vector2 = Vector2(spots[i])
		var dmg: int = int(game.player_hp_max * (0.06 if game.boss7_reborn else 0.052) + 16)
		if game.player_pos.distance_to(p) <= METEOR_RADIUS and game._local_player_damageable_by_contact():
			game._damage_player(dmg, "boss7_sky_fireball")
			game._apply_boss_burn(1)
		game._damage_remote_player_in_radius(p, METEOR_RADIUS, int(game.net_player_hp_max * 0.052 + 16), "boss7_sky_fireball", attack, "meteor_%d" % i)
		game._spawn_radial_particles(p, Color(1.0, 0.46, 0.08), 6 if game._memory_saver_active() else 14)
		if i % 4 == 0:
			game._play_sfx("boss_impact", 0.02, 0.28, 1.35 + game.rng.randf() * 0.2)
	attack["landed"] = landed
	# Brasas: queimam quem fica em cima.
	if burn_cd <= 0.0:
		burn_cd = METEOR_BURN_TICK
		for i in landed.keys():
			var hit_t2: float = warning + float(int(i)) * METEOR_STAGGER
			if age - hit_t2 > METEOR_BURN_TIME:
				continue
			var p2: Vector2 = Vector2(spots[int(i)])
			if game.player_pos.distance_to(p2) <= METEOR_RADIUS * 0.7 and game._local_player_damageable_by_contact():
				game._damage_player(int(game.player_hp_max * 0.012 + 4), "boss7_ember_patch")
				break
	attack["burn_cd"] = burn_cd
	attack["duration"] = maxf(float(attack.get("duration", 2.2)), warning + float(spots.size()) * METEOR_STAGGER + METEOR_BURN_TIME)
