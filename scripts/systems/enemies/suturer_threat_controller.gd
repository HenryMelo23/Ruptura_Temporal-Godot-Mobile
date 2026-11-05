class_name RTSuturerThreatController
extends RefCounted

## Suturador de Ambar como ameaca crescente: quanto mais tempo vivo, pior fica.
## - Pele de Ambar: com nos de sutura vivos ele regenera.
## - Remendo Vivo: costura inimigos mortos de volta a vida, com ambar (mais vida).
## - Casulo de Ambar: apos 40 s, prende um inimigo forte; se o casulo nao for
##   quebrado a tempo, nasce uma versao elite.
## Autoridade do mundo; a apresentacao le `stitch`, `cocoon` e `tethers`.

const SKIN_REGEN_RATIO := 0.015
const STITCH_COOLDOWN := 10.0
const STITCH_FIRST := 6.0
const STITCH_TELEGRAPH := 1.2
const STITCH_MAX := 3
const STITCH_HP_MULT := 1.6
const CORPSE_LIFE := 12.0
const CORPSE_RANGE := 900.0
const COCOON_AFTER := 40.0
const COCOON_COOLDOWN := 18.0
const COCOON_TIME := 6.0
const COCOON_RANGE := 760.0
const ELITE_HP_MULT := 2.5
const ELITE_DAMAGE_MULT := 1.6
const ELITE_SPEED_MULT := 1.2

var game: Node
var encounter_id := ""
var corpses: Array = []
var stitch: Dictionary = {}
var cocoon: Dictionary = {}
var tethers: Array = []
var stitch_cd := STITCH_FIRST
var cocoon_cd := 0.0
var _tracked: Dictionary = {}


func bind_game(p_game: Node) -> void:
	game = p_game


func reset() -> void:
	corpses.clear()
	stitch.clear()
	cocoon.clear()
	tethers.clear()
	stitch_cd = STITCH_FIRST
	cocoon_cd = 0.0
	_tracked.clear()


func _excluded(enemy: Dictionary) -> bool:
	var kind := String(enemy.get("type", ""))
	return kind in [RTPhase6AmberSuturerController.TYPE_ID, RTPhase6AmberSuturerController.NODE_TYPE_ID] \
		or bool(enemy.get("is_mini_boss", false)) or bool(enemy.get("aguilhao_nodule", false)) \
		or bool(enemy.get("eco_vinculado", false)) or bool(enemy.get("is_event_enemy", false))


## Chamado todo quadro na fase 6 (autoridade): registra mortes perto do Suturador.
func track_corpses(suturer: Dictionary, delta: float) -> void:
	var now: float = float(game.time_alive)
	var seen: Dictionary = {}
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if _excluded(enemy):
			continue
		var uid: int = int(enemy.get("uid", -1))
		seen[uid] = true
		_tracked[uid] = {"pos": Vector2(enemy.get("pos", Vector2.ZERO)), "type": String(enemy.get("type", "")), "hp_ratio": float(enemy.get("hp", 0.0)) / maxf(1.0, float(enemy.get("max_hp", 1.0)))}
	var spos: Vector2 = Vector2(suturer.get("pos", game.player_pos)) if not suturer.is_empty() else game.player_pos
	for uid in _tracked.keys():
		if seen.has(uid):
			continue
		var info: Dictionary = _tracked[uid]
		_tracked.erase(uid)
		# So conta como morte quem saiu ferido (descarte/despawn nao vira cadaver).
		if float(info["hp_ratio"]) > 0.4 or suturer.is_empty():
			continue
		if Vector2(info["pos"]).distance_to(spos) > CORPSE_RANGE:
			continue
		corpses.append({"pos": info["pos"], "type": info["type"], "t": now})
	corpses = corpses.filter(func(c): return now - float(Dictionary(c)["t"]) <= CORPSE_LIFE)
	while corpses.size() > 12:
		corpses.pop_front()


func update(suturer: Dictionary, delta: float) -> void:
	if game == null or suturer.is_empty():
		return
	var current_id := String(game.amber_suturer_state.get("encounter_id", ""))
	if current_id != encounter_id:
		encounter_id = current_id
		reset()
	track_corpses(suturer, delta)
	_update_skin(suturer, delta)
	_update_stitch(suturer, delta)
	_update_cocoon(suturer, delta)


func _update_skin(suturer: Dictionary, delta: float) -> void:
	tethers.clear()
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if String(enemy.get("type", "")) == RTPhase6AmberSuturerController.NODE_TYPE_ID and float(enemy.get("hp", 0.0)) > 0.0:
			tethers.append(Vector2(enemy["pos"]))
	if tethers.is_empty():
		return
	var max_hp: float = float(suturer.get("max_hp", 1.0))
	var hp: float = float(suturer.get("hp", max_hp))
	if hp < max_hp:
		suturer["hp"] = minf(max_hp, hp + max_hp * SKIN_REGEN_RATIO * float(tethers.size()) * 0.5 * delta)


func _update_stitch(suturer: Dictionary, delta: float) -> void:
	if not stitch.is_empty():
		stitch["age"] = float(stitch["age"]) + delta
		if float(stitch["age"]) >= STITCH_TELEGRAPH:
			for target_value in stitch["targets"]:
				var target: Dictionary = target_value
				var before: int = game.enemies.size()
				game._spawn_enemy(String(target["type"]), Vector2(target["pos"]))
				if game.enemies.size() > before:
					var revived: Dictionary = game.enemies.back()
					var hp: float = float(revived.get("max_hp", game.enemy_base_hp)) * STITCH_HP_MULT
					revived["hp"] = hp
					revived["max_hp"] = hp
					revived["amber_patched"] = true
					revived["skip_rewards"] = true
					revived["stun"] = 0.3
			game._add_text("REMENDO VIVO!", Vector2(suturer["pos"]) + Vector2(-80, -120), Color(1.0, 0.72, 0.26), 1.0, 20)
			stitch.clear()
		return
	stitch_cd = maxf(0.0, stitch_cd - delta)
	if stitch_cd > 0.0 or corpses.is_empty():
		return
	var spos: Vector2 = Vector2(suturer["pos"])
	corpses.sort_custom(func(a, b): return Vector2(Dictionary(a)["pos"]).distance_to(spos) < Vector2(Dictionary(b)["pos"]).distance_to(spos))
	var targets: Array = corpses.slice(0, STITCH_MAX)
	for target in targets:
		corpses.erase(target)
	stitch = {"age": 0.0, "targets": targets}
	stitch_cd = STITCH_COOLDOWN


func _update_cocoon(suturer: Dictionary, delta: float) -> void:
	if not cocoon.is_empty():
		cocoon["age"] = float(cocoon["age"]) + delta
		var host: Dictionary = _enemy_by_uid(int(cocoon["uid"]))
		if host.is_empty() or float(host.get("hp", 0.0)) <= 0.0:
			game._add_text("CASULO QUEBRADO", Vector2(cocoon["pos"]) + Vector2(-80, -80), Color(1.0, 0.86, 0.5), 1.0, 19)
			cocoon.clear()
			cocoon_cd = COCOON_COOLDOWN
			return
		cocoon["pos"] = Vector2(host["pos"])
		host["stun"] = maxf(float(host.get("stun", 0.0)), 0.2)
		if float(cocoon["age"]) >= COCOON_TIME:
			var hp: float = float(host.get("max_hp", 1.0)) * ELITE_HP_MULT
			host["hp"] = hp
			host["max_hp"] = hp
			host["damage"] = float(host.get("damage", 10.0)) * ELITE_DAMAGE_MULT
			host["speed"] = float(host.get("speed", 100.0)) * ELITE_SPEED_MULT
			host["amber_elite"] = true
			host["amber_patched"] = false
			host["stun"] = 0.0
			game._add_text("ELITE DE AMBAR!", Vector2(host["pos"]) + Vector2(-90, -96), Color(1.0, 0.56, 0.12), 1.4, 23)
			game.screen_shake_timer = maxf(float(game.screen_shake_timer), 0.18)
			game.screen_shake_strength = maxf(float(game.screen_shake_strength), 6.0)
			cocoon.clear()
			cocoon_cd = COCOON_COOLDOWN
		return
	if float(game.amber_suturer_state.get("battle_elapsed", 0.0)) < COCOON_AFTER:
		return
	cocoon_cd = maxf(0.0, cocoon_cd - delta)
	if cocoon_cd > 0.0:
		return
	var spos: Vector2 = Vector2(suturer["pos"])
	var best: Dictionary = {}
	var best_hp := -1.0
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if _excluded(enemy) or bool(enemy.get("amber_elite", false)) or float(enemy.get("hp", 0.0)) <= 0.0:
			continue
		if Vector2(enemy["pos"]).distance_to(spos) > COCOON_RANGE:
			continue
		if float(enemy.get("max_hp", 0.0)) > best_hp:
			best_hp = float(enemy.get("max_hp", 0.0))
			best = enemy
	if best.is_empty():
		cocoon_cd = 2.0
		return
	cocoon = {"uid": int(best.get("uid", -1)), "pos": Vector2(best["pos"]), "age": 0.0}
	game._add_text("CASULO DE AMBAR - QUEBRE!", Vector2(best["pos"]) + Vector2(-120, -96), Color(1.0, 0.72, 0.26), 1.4, 20)


func _enemy_by_uid(uid: int) -> Dictionary:
	for enemy_value in game.enemies:
		var enemy: Dictionary = enemy_value
		if int(enemy.get("uid", -2)) == uid:
			return enemy
	return {}
