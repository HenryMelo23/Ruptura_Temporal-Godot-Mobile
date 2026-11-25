class_name RTPropheticRewind
extends RefCounted

## Profecia do espectro Profetica.
##
## Fora de recarga e em combate, um olho dourado aparece fechado sobre a barra
## de vida e abre (presagio). Abriu: comecam 10 s de profecia, com a Geovana
## mais rapida para andar e atacar, e o mundo e gravado. Se ela for atingida
## dentro desses 10 s, o golpe nao entra: o tempo volta ao inicio da profecia
## e ela ve passado e presente. Os inimigos refazem exatamente o que fizeram
## (posicoes, disparos, entradas) ate o instante do golpe, e ela pode refazer
## tudo para escapar. Recarga: 50 s se a profecia foi gasta (voltou o tempo),
## 30 s se terminou sem golpe.
##
## O QUE E REPRODUZIDO EXATAMENTE (ate o instante do golpe):
## - trajetoria de cada inimigo vivo, amostrada a 30 Hz e interpolada;
## - cada projetil inimigo, recriado no mesmo instante com o mesmo estado;
## - cada inimigo que entrou no mapa, no mesmo instante e no mesmo lugar;
## - posicao do chefe e do Arauto; relogio da run e semente do RNG voltam.
## O QUE NAO E (segue simulando ao vivo a partir do estado restaurado):
## - golpes corpo a corpo/explosoes decididos pela IA na hora (a IA roda e so
##   a posicao e corrigida), telegrafos/areas dos chefes e hazards da fase;
## - filhotes criados por mortes que ela causar diferente na segunda vez;
## - drops ja coletados e cartas compradas (o placar de pontos volta).
## Multiplayer: desligada (voltar o mundo de uma sala inteira fica pendente).

const STATE_COOLDOWN := "cooldown"
const STATE_OMEN := "omen"
const STATE_RECORDING := "recording"
const STATE_REWINDING := "rewinding"
const STATE_REPLAY := "replay"

const WINDOW := 10.0
const OMEN_TIME := 1.3
## Abertura do olho dentro do presagio (o resto e o brilho antes da contagem).
const OMEN_OPEN_START := 0.45
const OMEN_OPEN_END := 1.05
const REWIND_TIME := 0.9
const COOLDOWN_SPENT := 50.0
const COOLDOWN_UNSPENT := 30.0
const FIRST_COOLDOWN := 8.0
const SAMPLE_INTERVAL := 1.0 / 30.0
const MOVE_BUFF := 1.25
const ATTACK_INTERVAL_BUFF := 0.75
const POST_REWIND_GRACE := 0.7
const BUFF_KEY := "prophecy_rewind_buff"
## Marca dos projeteis inimigos que ja pertencem a linha do tempo gravada.
const SEEN_KEY := "_profecia"
## Dano que vem dela mesma nao conta como "ser atingida".
const SELF_SOURCES := ["aura", "divida_equilibrista", "teste_oficina"]

var core: Node = null
var state := STATE_COOLDOWN
var cooldown := FIRST_COOLDOWN
## Tempo dentro do estado atual (na gravacao e no replay: segundos de profecia).
var clock := 0.0
## Instante da gravacao em que o golpe voltou o tempo (fim do replay exato).
var hit_at := -1.0
var rewinds := 0
var snapshot: Dictionary = {}
var samples: Array[Dictionary] = []
var bullet_events: Array[Dictionary] = []
var spawn_events: Array[Dictionary] = []
var known_uids: Dictionary = {}
var _sample_timer := 0.0
var _bullet_cursor := 0
var _spawn_cursor := 0
var _sample_cursor := 0


## Nova run: liga ao core e volta para a recarga inicial.
func reset(runtime_core: Node) -> void:
	core = runtime_core
	_set_buff(false)
	state = STATE_COOLDOWN
	cooldown = FIRST_COOLDOWN
	clock = 0.0
	hit_at = -1.0
	_clear_recording()


func available() -> bool:
	return core != null and String(core.aura_state.get("name", "")) == "Profetica" and not bool(core.is_multiplayer)


func active() -> bool:
	return state in [STATE_RECORDING, STATE_REWINDING, STATE_REPLAY]


func replaying() -> bool:
	return state == STATE_REPLAY and clock < hit_at


## 0 = olho fechado, 1 = aberto (HUD).
func eye_open() -> float:
	match state:
		STATE_OMEN:
			return clampf((clock - OMEN_OPEN_START) / (OMEN_OPEN_END - OMEN_OPEN_START), 0.0, 1.0)
		STATE_RECORDING, STATE_REWINDING, STATE_REPLAY:
			return 1.0
	return 0.0


func time_left() -> float:
	if state == STATE_RECORDING or state == STATE_REPLAY:
		return maxf(0.0, WINDOW - clock)
	if state == STATE_REWINDING:
		return WINDOW
	return 0.0


# ================================================================ ciclo
## Fim de cada quadro de jogo (depois de inimigos e projeteis andarem).
func update(delta: float) -> void:
	if not available():
		if state != STATE_COOLDOWN:
			_finish(false)
		return
	if active() and _world_changed():
		_finish(state == STATE_REPLAY)
		return
	match state:
		STATE_COOLDOWN:
			cooldown = maxf(0.0, cooldown - delta)
			if cooldown <= 0.0 and _in_combat():
				state = STATE_OMEN
				clock = 0.0
				core._play_sfx("ui_manifest_switch", 0.01, 0.5, 0.62)
		STATE_OMEN:
			clock += delta
			if not _in_combat():
				state = STATE_COOLDOWN
			elif clock >= OMEN_TIME:
				_begin_recording()
		STATE_RECORDING:
			clock += delta
			_set_buff(true)
			_record(delta)
			if clock >= WINDOW:
				_finish(false)
		STATE_REPLAY:
			clock += delta
			_set_buff(true)
			if clock <= hit_at + SAMPLE_INTERVAL:
				_drive_replay()
			if clock >= WINDOW:
				_finish(true)


## Durante a volta no tempo o mundo para; o core retorna cedo do quadro.
func blocks_world(delta: float) -> bool:
	if state != STATE_REWINDING:
		return false
	clock += delta
	_scrub(clampf(clock / REWIND_TIME, 0.0, 1.0))
	if clock >= REWIND_TIME:
		_restore()
	return true


## Golpe recebido: dentro da profecia ele nao entra e o tempo volta.
func intercept_hit(source: String) -> bool:
	if state != STATE_RECORDING or not available():
		return false
	if source.begins_with("pact_") or SELF_SOURCES.has(source):
		return false
	_record(0.0)
	_take_sample(clock)
	hit_at = clock
	state = STATE_REWINDING
	clock = 0.0
	rewinds += 1
	core._play_sfx("Retrocede.mp3", 0.04, 0.85, 1.0)
	core._add_text("A PROFECIA SE CUMPRE", core.player_pos + Vector2(-120, -130), Color(1.0, 0.86, 0.38), 1.6, 24)
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.25)
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), 8.0)
	return true


func _in_combat() -> bool:
	if String(core.mode) != "game" or core._merchant_dimension().seals_phase_world():
		return false
	return not core.enemies.is_empty() or bool(core.boss_active)


func _world_changed() -> bool:
	if snapshot.is_empty():
		return false
	return int(core.current_phase) != int(snapshot.get("phase", -1)) or bool(core.boss_active) != bool(snapshot.get("boss_active", false)) or core._merchant_dimension().seals_phase_world()


func _set_buff(on: bool) -> void:
	if core != null and core.aura_state is Dictionary:
		core.aura_state[BUFF_KEY] = 1.0 if on else 0.0


func _finish(spent: bool) -> void:
	_set_buff(false)
	state = STATE_COOLDOWN
	cooldown = COOLDOWN_SPENT if spent else COOLDOWN_UNSPENT
	clock = 0.0
	hit_at = -1.0
	_clear_recording()


func _clear_recording() -> void:
	snapshot = {}
	samples.clear()
	bullet_events.clear()
	spawn_events.clear()
	known_uids.clear()
	_sample_timer = 0.0
	_bullet_cursor = 0
	_spawn_cursor = 0
	_sample_cursor = 0


# ================================================================ gravacao
func _begin_recording() -> void:
	_clear_recording()
	for bullet in core.enemy_bullets:
		Dictionary(bullet)[SEEN_KEY] = true
	for enemy in core.enemies:
		known_uids[int(Dictionary(enemy).get("uid", -1))] = true
	snapshot = {
		"phase": int(core.current_phase),
		"boss_active": bool(core.boss_active),
		"enemies": core.enemies.duplicate(true),
		"enemy_bullets": core.enemy_bullets.duplicate(true),
		"player_pos": Vector2(core.player_pos),
		"player_hp": int(core.player_hp),
		"score": int(core.score),
		"score_total": int(core.score_total),
		"run_points_earned": int(core.run_points_earned),
		"time_alive": float(core.time_alive),
		"spawn_timer": float(core.spawn_timer),
		"rng_state": core.rng.state,
		"boss_pos": Vector2(core.boss_pos),
		"boss_hp": float(core.boss_hp),
		"arauto": Dictionary(core.arauto).duplicate(true),
	}
	state = STATE_RECORDING
	clock = 0.0
	_set_buff(true)
	_take_sample(0.0)
	core._add_text("PROFECIA: 10 s", core.player_pos + Vector2(-70, -128), Color(1.0, 0.86, 0.38), 1.2, 22)


func _record(delta: float) -> void:
	for bullet in core.enemy_bullets:
		var b: Dictionary = bullet
		if not b.has(SEEN_KEY):
			b[SEEN_KEY] = true
			bullet_events.append({"t": clock, "bullet": b.duplicate(true)})
	for enemy in core.enemies:
		var uid: int = int(Dictionary(enemy).get("uid", -1))
		if not known_uids.has(uid):
			known_uids[uid] = true
			spawn_events.append({"t": clock, "enemy": Dictionary(enemy).duplicate(true)})
	_sample_timer += delta
	if _sample_timer >= SAMPLE_INTERVAL:
		_sample_timer = fmod(_sample_timer, SAMPLE_INTERVAL)
		_take_sample(clock)


func _take_sample(t: float) -> void:
	var uids := PackedInt64Array()
	var positions := PackedVector2Array()
	for enemy in core.enemies:
		uids.append(int(Dictionary(enemy).get("uid", -1)))
		positions.append(Vector2(Dictionary(enemy).get("pos", Vector2.ZERO)))
	samples.append({
		"t": t,
		"uids": uids,
		"pos": positions,
		"player": Vector2(core.player_pos),
		"boss": Vector2(core.boss_pos),
		"arauto": Vector2(Dictionary(core.arauto).get("pos", Vector2.ZERO)),
	})


# ================================================================ volta
## Cena da volta: a gravacao corre de tras para frente na tela.
func _scrub(k: float) -> void:
	if samples.is_empty():
		return
	var sample: Dictionary = samples[clampi(int(round((1.0 - k) * float(samples.size() - 1))), 0, samples.size() - 1)]
	core.player_pos = Vector2(sample["player"])
	_apply_sample_positions(sample, sample, 0.0)


func _restore() -> void:
	core.enemies.assign(Array(snapshot.get("enemies", [])).duplicate(true))
	core.enemy_bullets.assign(Array(snapshot.get("enemy_bullets", [])).duplicate(true))
	core.player_pos = Vector2(snapshot["player_pos"])
	core.player_hp = int(snapshot["player_hp"])
	core.score = int(snapshot["score"])
	core.score_total = int(snapshot["score_total"])
	core.run_points_earned = int(snapshot["run_points_earned"])
	core.time_alive = float(snapshot["time_alive"])
	core.spawn_timer = float(snapshot["spawn_timer"])
	core.rng.state = snapshot["rng_state"]
	if bool(core.boss_active):
		core.boss_pos = Vector2(snapshot["boss_pos"])
		core.boss_hp = float(snapshot["boss_hp"])
	var arauto_before: Dictionary = snapshot.get("arauto", {})
	if not arauto_before.is_empty():
		core.arauto = arauto_before.duplicate(true)
	core.run_retry_invulnerability_timer = maxf(float(core.run_retry_invulnerability_timer), POST_REWIND_GRACE)
	state = STATE_REPLAY
	clock = 0.0
	_bullet_cursor = 0
	_spawn_cursor = 0
	_sample_cursor = 0


# ================================================================ replay
func _drive_replay() -> void:
	var t: float = clock
	while _spawn_cursor < spawn_events.size() and float(spawn_events[_spawn_cursor]["t"]) <= t:
		var spawned: Dictionary = Dictionary(spawn_events[_spawn_cursor]["enemy"]).duplicate(true)
		if core._enemy_by_uid(int(spawned.get("uid", -1))) == null:
			core.enemies.append(spawned)
		_spawn_cursor += 1
	# Projeteis que a IA ao vivo cria agora nao pertencem a linha gravada.
	core.enemy_bullets.assign(core.enemy_bullets.filter(func(b): return Dictionary(b).has(SEEN_KEY)))
	while _bullet_cursor < bullet_events.size() and float(bullet_events[_bullet_cursor]["t"]) <= t:
		core.enemy_bullets.append(Dictionary(bullet_events[_bullet_cursor]["bullet"]).duplicate(true))
		_bullet_cursor += 1
	# Entradas ao vivo que nao estavam na gravacao tambem nao valem.
	core.enemies.assign(core.enemies.filter(func(e): return known_uids.has(int(Dictionary(e).get("uid", -1)))))
	while _sample_cursor + 1 < samples.size() and float(samples[_sample_cursor + 1]["t"]) <= t:
		_sample_cursor += 1
	var a: Dictionary = samples[_sample_cursor]
	var b: Dictionary = samples[mini(_sample_cursor + 1, samples.size() - 1)]
	var span: float = float(b["t"]) - float(a["t"])
	var k: float = clampf((t - float(a["t"])) / span, 0.0, 1.0) if span > 0.0001 else 0.0
	_apply_sample_positions(a, b, k)


func _apply_sample_positions(a: Dictionary, b: Dictionary, k: float) -> void:
	var a_index: Dictionary = _index_of(a)
	var b_index: Dictionary = _index_of(b)
	var a_pos: PackedVector2Array = a["pos"]
	var b_pos: PackedVector2Array = b["pos"]
	for enemy in core.enemies:
		var uid: int = int(Dictionary(enemy).get("uid", -1))
		if not a_index.has(uid):
			continue
		var from: Vector2 = a_pos[int(a_index[uid])]
		var to: Vector2 = b_pos[int(b_index[uid])] if b_index.has(uid) else from
		enemy["pos"] = from.lerp(to, k)
	if bool(core.boss_active):
		core.boss_pos = Vector2(a["boss"]).lerp(Vector2(b["boss"]), k)
	if core._arauto_active():
		core.arauto["pos"] = Vector2(a["arauto"]).lerp(Vector2(b["arauto"]), k)


func _index_of(sample: Dictionary) -> Dictionary:
	var out := {}
	var uids: PackedInt64Array = sample["uids"]
	for i in range(uids.size()):
		out[uids[i]] = i
	return out


## Onde ela estava na primeira linha do tempo neste instante (fantasma dourado).
func past_self_position() -> Vector2:
	if state != STATE_REPLAY or samples.is_empty() or clock > hit_at:
		return Vector2.INF
	var i: int = clampi(_sample_cursor, 0, samples.size() - 1)
	return Vector2(samples[i]["player"])


## Onde cada inimigo gravado vai estar daqui a `ahead` segundos (presente/futuro).
func future_positions(ahead: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if state != STATE_REPLAY or samples.is_empty() or clock > hit_at:
		return out
	var target_t: float = minf(clock + ahead, hit_at)
	var i: int = _sample_cursor
	while i + 1 < samples.size() and float(samples[i + 1]["t"]) <= target_t:
		i += 1
	var sample: Dictionary = samples[i]
	var alive: Dictionary = {}
	for enemy in core.enemies:
		alive[int(Dictionary(enemy).get("uid", -1))] = true
	var uids: PackedInt64Array = sample["uids"]
	var positions: PackedVector2Array = sample["pos"]
	for j in range(uids.size()):
		if alive.has(uids[j]):
			out.append(positions[j])
	return out
