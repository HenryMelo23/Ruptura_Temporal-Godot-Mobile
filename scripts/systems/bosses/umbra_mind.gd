class_name RTUmbraMind
extends RefCounted

## Mente da UMBRA: politica linear leve (acao x contexto) + parametros taticos.
## Camadas, da mais geral para a mais pessoal:
##   1. base      - res://assets/data/umbra_mind_base.json (treino headless, vem no jogo)
##   2. coletiva  - user://umbra_mind/umbra_collective_mind.json (VPS, todas as partidas)
##   3. jogador   - user://umbra_mind/umbra_player_mind.json (este aparelho)
## Cada camada soma ajustes sobre a anterior. O executor continua validando
## tudo: a mente so muda a preferencia entre acoes ja legais.

const SCHEMA_VERSION := 1
const BASE_PATH := "res://assets/data/umbra_mind_base.json"
const COLLECTIVE_PATH := "user://umbra_mind/umbra_collective_mind.json"
const PLAYER_PATH := "user://umbra_mind/umbra_player_mind.json"

const FEATURES: Array[String] = [
	"bias", "distance", "umbra_hp", "player_hp", "player_speed", "player_edge",
	"player_dash_ready", "under_fire", "dimension_base", "hazards", "rewind_armed", "fight_time",
]
const ACTIONS: Array[String] = [
	"ATAQUE", "SIFON", "TELEPORTE", "TELEPORTE_JUKE",
	"TRANSMUTAR_VORTICE", "TRANSMUTAR_GRAVIDADE", "TRANSMUTAR_NECROSE", "TRANSMUTAR_RESSONANCIA",
	"TRANSMUTAR_HEMORRAGIA", "TRANSMUTAR_ATRITO", "TRANSMUTAR_RASTRO",
	"VORTICE", "PRISAO", "MIASMA", "DESCARGA_ELETRICA", "CAMINHO_ESPINHOS", "LASER_SOBRECARGA", "PRAGA_RATOS",
	"REBOBINAR", "ECO_PROFETICO",
]
const MAX_BONUS := 2.0
const DEFAULT_AIM_LEAD := 0.72

## Treino headless: nao le nem grava camadas do usuario.
static var training_mode := false
## Coleta headless: chance de explorar uma acao legal aleatoria.
static var explore_epsilon := 0.0
static var explore_rng: RandomNumberGenerator = null
static var last_explored := false

var core: Node = null
## weights[action] = Array[float] com FEATURES.size() valores.
var weights: Dictionary = {}
var aim_lead := DEFAULT_AIM_LEAD
var version := "untrained"
var trained_episodes := 0
var collective_runs := 0
var layers: Array[String] = []
## Priors das habilidades do kit base (eco_along, eco_side, rewind_escape...)
## acumulados pelas camadas: {chave: [valor, amostras]}.
var skill_priors: Dictionary = {}
var _feat := PackedFloat32Array()

# Rastreamento do encontro atual (vira relatorio para a VPS e camada do jogador).
const OUTCOME_WINDOW := 3.0
const DEALT_W := 10.0
const TAKEN_W := 30.0
var enc_active := false
var enc_elapsed := 0.0
var enc_dealt := 0.0
var enc_taken := 0.0
var enc_last_hp := -1.0
var enc_last_boss_hp := -1.0
var enc_pending: Array[Dictionary] = []
## stats[action] = {n, sum_y, xtx: PackedFloat64Array(144), xty: PackedFloat64Array(12)}
var enc_stats: Dictionary = {}
var enc_plasma_shots := 0
var enc_plasma_hits := 0
var enc_outcome := ""
var last_report: Dictionary = {}


## Pasta das camadas do usuario (testes usam outra para nao sujar o aparelho).
var user_dir := "user://umbra_mind/"


func configure(runtime_core: Node) -> void:
	core = runtime_core
	_feat.resize(FEATURES.size())
	var loop = Engine.get_main_loop()
	if loop != null and loop.get_script() != null:
		user_dir = "user://umbra_mind_test/"
	reset_weights()


func collective_path() -> String:
	return user_dir + COLLECTIVE_PATH.get_file()


func player_path() -> String:
	return user_dir + PLAYER_PATH.get_file()


func reset_weights() -> void:
	weights.clear()
	for a in ACTIONS:
		var row: Array = []
		row.resize(FEATURES.size())
		row.fill(0.0)
		weights[a] = row
	aim_lead = DEFAULT_AIM_LEAD
	layers.clear()
	skill_priors.clear()


## Carrega base + coletiva + jogador. `allow_user` false no treino headless.
func load_layers(allow_user: bool = true) -> void:
	reset_weights()
	var base: Dictionary = _read(BASE_PATH)
	if not base.is_empty():
		apply_layer(base, 1.0)
		version = String(base.get("version", "base"))
		trained_episodes = int(base.get("trained_episodes", 0))
		layers.append("base")
	if not allow_user:
		return
	var collective: Dictionary = _read(collective_path())
	if not collective.is_empty():
		apply_layer(collective, 1.0)
		collective_runs = int(collective.get("runs", 0))
		layers.append("coletiva")
	var mine: Dictionary = _read(player_path())
	if not mine.is_empty():
		apply_layer(mine, 1.0)
		layers.append("jogador")


## Aplica uma camada. mode "add" (padrao) soma; mode "blend" mistura com
## `confidence` (0..1): w = (1-c)*w + c*camada. Valores fora de faixa sao cortados.
func apply_layer(data: Dictionary, scale: float) -> void:
	if int(data.get("schema_version", SCHEMA_VERSION)) != SCHEMA_VERSION:
		return
	var blend: bool = String(data.get("mode", "add")) == "blend"
	var c: float = clampf(float(data.get("confidence", 0.0)), 0.0, 0.85) * scale
	var feats: Array = Array(data.get("features", FEATURES))
	var w: Dictionary = Dictionary(data.get("weights", {}))
	for a in w.keys():
		if not weights.has(a):
			continue
		var row: Array = weights[a]
		var src: Array = Array(w[a])
		for i in range(mini(src.size(), feats.size())):
			var idx: int = FEATURES.find(String(feats[i]))
			if idx < 0:
				continue
			var v: float = clampf(float(src[i]), -3.0, 3.0)
			row[idx] = clampf(lerpf(float(row[idx]), v, c) if blend else float(row[idx]) + v * scale, -3.0, 3.0)
	var priors: Dictionary = Dictionary(data.get("skill_priors", {}))
	for key in priors.keys():
		var entry: Array = Array(priors[key]) if priors[key] is Array else [priors[key], 1]
		var value: float = float(entry[0])
		var n: float = maxf(0.0, float(entry[1]) if entry.size() > 1 else 1.0)
		if skill_priors.has(key):
			var old: Array = skill_priors[key]
			var total: float = float(old[1]) + n
			skill_priors[key] = [(float(old[0]) * float(old[1]) + value * n) / maxf(1.0, total), total]
		else:
			skill_priors[key] = [value, n]
	if data.has("aim_lead_delta"):
		aim_lead = clampf(aim_lead + float(data["aim_lead_delta"]) * scale, 0.2, 1.1)
	elif data.has("aim_lead"):
		aim_lead = clampf(float(data["aim_lead"]), 0.2, 1.1)


func export_layer() -> Dictionary:
	var w: Dictionary = {}
	for a in ACTIONS:
		var row: Array = []
		for v in Array(weights[a]):
			row.append(snappedf(float(v), 0.0001))
		w[a] = row
	return {
		"schema_version": SCHEMA_VERSION, "features": FEATURES.duplicate(), "actions": ACTIONS.duplicate(),
		"weights": w, "aim_lead": snappedf(aim_lead, 0.001),
	}


# ================================================================ vetor de parametros (treino)
func param_count() -> int:
	return ACTIONS.size() * FEATURES.size() + 1


func to_params() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for a in ACTIONS:
		for v in Array(weights[a]):
			out.append(float(v))
	out.append(aim_lead)
	return out


func from_params(p: PackedFloat32Array) -> void:
	var k := 0
	for a in ACTIONS:
		var row: Array = weights[a]
		for i in range(FEATURES.size()):
			row[i] = clampf(p[k], -3.0, 3.0)
			k += 1
	aim_lead = clampf(p[k], 0.2, 1.1)


# ================================================================ decisao
func features() -> PackedFloat32Array:
	var dist: float = Vector2(core.boss_pos).distance_to(core.player_pos)
	var vel: Vector2 = RTUmbraAim.history_velocity(core.phase5_player_history, core.player_pos)
	var skills: RTUmbraBaseSkills = core._umbra_base_skills()
	_feat[0] = 1.0
	_feat[1] = clampf(dist / 1000.0, 0.0, 1.5)
	_feat[2] = clampf(float(core.boss_hp) / maxf(1.0, float(core.boss_hp_max)), 0.0, 1.0)
	_feat[3] = clampf(float(core.player_hp) / maxf(1.0, float(core.player_hp_max)), 0.0, 1.0)
	_feat[4] = clampf(vel.length() / 300.0, 0.0, 1.5)
	_feat[5] = 1.0 if core._player_near_edge() else 0.0
	_feat[6] = 1.0 if skills._player_dash_ready() else 0.0
	_feat[7] = _under_fire()
	_feat[8] = 1.0 if String(core.boss5_dimension) == "base" else 0.0
	_feat[9] = clampf(float(core.phase5_hazards.size() + core.phase5_rats.size() / 3 + skills.ecos.size()) / 3.0, 0.0, 1.0)
	_feat[10] = 0.0 if skills.rewinds.is_empty() else 1.0
	_feat[11] = clampf((float(core.time_alive) - skills.encounter_started) / 120.0, 0.0, 1.5)
	return _feat


func _under_fire() -> float:
	var bp: Vector2 = core.boss_pos
	for b in core.bullets:
		var d: Dictionary = b
		var pos: Vector2 = Vector2(d.get("pos", Vector2.ZERO))
		if pos.distance_squared_to(bp) < 160000.0 and Vector2(d.get("dir", Vector2.ZERO)).dot((bp - pos).normalized()) > 0.85:
			return 1.0
	return 0.0


## Soma a preferencia da mente nas acoes disponiveis.
func apply(scores: Dictionary, available: Array) -> void:
	last_explored = false
	if explore_epsilon > 0.0 and explore_rng != null and explore_rng.randf() < explore_epsilon:
		var legal: Array = available.filter(func(x): return weights.has(String(x)))
		if not legal.is_empty():
			var pick: String = String(legal[explore_rng.randi_range(0, legal.size() - 1)])
			scores[pick] = float(scores.get(pick, 0.0)) + 50.0
			last_explored = true
			return
	var f: PackedFloat32Array = features()
	for action in available:
		var a: String = String(action)
		if not weights.has(a):
			continue
		var row: Array = weights[a]
		var s := 0.0
		for i in range(f.size()):
			s += float(row[i]) * f[i]
		scores[a] = float(scores.get(a, 0.0)) + clampf(s, -MAX_BONUS, MAX_BONUS)


# ================================================================ encontro (aprendizado online)
func begin_encounter() -> void:
	enc_active = true
	enc_elapsed = 0.0
	enc_dealt = 0.0
	enc_taken = 0.0
	enc_last_hp = float(core.player_hp)
	enc_last_boss_hp = float(core.boss_hp)
	enc_pending.clear()
	enc_stats.clear()
	enc_plasma_shots = 0
	enc_plasma_hits = 0
	enc_outcome = ""


func on_decision(action: String) -> void:
	if not enc_active or not weights.has(action):
		return
	if action == "ATAQUE":
		enc_plasma_shots += 1
	enc_pending.append({"a": action, "f": features().duplicate(), "t": enc_elapsed, "d0": enc_dealt, "k0": enc_taken})


func note_player_damage(source: String) -> void:
	if enc_active and source == "umbra_plasma":
		enc_plasma_hits += 1


func track(delta: float) -> void:
	if not enc_active:
		return
	enc_elapsed += delta
	var hp: float = float(core.player_hp)
	var bhp: float = float(core.boss_hp)
	if hp < enc_last_hp:
		enc_dealt += (enc_last_hp - hp) / maxf(1.0, float(core.player_hp_max))
	if bhp < enc_last_boss_hp:
		enc_taken += (enc_last_boss_hp - bhp) / maxf(1.0, float(core.boss_hp_max))
	enc_last_hp = hp
	enc_last_boss_hp = bhp
	while not enc_pending.is_empty() and enc_elapsed - float(enc_pending[0]["t"]) >= OUTCOME_WINDOW:
		_flush(enc_pending.pop_front())


func _flush(p: Dictionary) -> void:
	var y: float = DEALT_W * (enc_dealt - float(p["d0"])) - TAKEN_W * (enc_taken - float(p["k0"]))
	var f: PackedFloat32Array = p["f"]
	var n_f: int = FEATURES.size()
	var a: String = String(p["a"])
	if not enc_stats.has(a):
		var xtx := PackedFloat64Array()
		xtx.resize(n_f * n_f)
		var xty := PackedFloat64Array()
		xty.resize(n_f)
		enc_stats[a] = {"n": 0, "sum_y": 0.0, "xtx": xtx, "xty": xty}
	var st: Dictionary = enc_stats[a]
	st["n"] = int(st["n"]) + 1
	st["sum_y"] = float(st["sum_y"]) + y
	var xtx2: PackedFloat64Array = st["xtx"]
	var xty2: PackedFloat64Array = st["xty"]
	for i in range(n_f):
		xty2[i] += f[i] * y
		for j in range(n_f):
			xtx2[i * n_f + j] += f[i] * f[j]
	st["xtx"] = xtx2
	st["xty"] = xty2


## Fecha o encontro: relatorio para a VPS e camada pessoal deste aparelho.
func finish_encounter(outcome: String, skills_learned: Dictionary) -> void:
	if not enc_active:
		return
	enc_active = false
	enc_outcome = outcome
	for p in enc_pending:
		_flush(p)
	enc_pending.clear()
	last_report = combat_report(skills_learned)
	if not training_mode and enc_elapsed >= 10.0:
		_update_player_layer(skills_learned)


func combat_report(skills_learned: Dictionary = {}) -> Dictionary:
	if enc_stats.is_empty() and enc_elapsed <= 0.0:
		return last_report
	var acts: Dictionary = {}
	for a in enc_stats.keys():
		var st: Dictionary = enc_stats[a]
		var xtx: Array = []
		for v in PackedFloat64Array(st["xtx"]):
			xtx.append(snappedf(v, 0.0001))
		var xty: Array = []
		for v in PackedFloat64Array(st["xty"]):
			xty.append(snappedf(v, 0.0001))
		acts[a] = {"n": int(st["n"]), "sum_y": snappedf(float(st["sum_y"]), 0.0001), "xtx": xtx, "xty": xty}
	var priors: Dictionary = {}
	for key in ["eco_along", "eco_side", "rewind_escape"]:
		if skills_learned.has(key):
			var samples_key: String = "eco_samples" if key.begins_with("eco") else "rewind_samples"
			priors[key] = [snappedf(float(skills_learned[key]), 0.001), int(skills_learned.get(samples_key, 0))]
	return {
		"schema_version": SCHEMA_VERSION, "mind_version": version, "layers": layers.duplicate(),
		"features": FEATURES.duplicate(), "encounter_seconds": snappedf(enc_elapsed, 0.1),
		"outcome": enc_outcome, "aim_lead": snappedf(aim_lead, 0.001),
		"plasma": {"shots": enc_plasma_shots, "hits": enc_plasma_hits},
		"actions": acts, "skill_priors": priors,
	}


## Camada pessoal: vies por acao (retorno medio da acao - media geral) e
## priors das habilidades. Decai devagar para acompanhar mudancas do jogador.
func _update_player_layer(skills_learned: Dictionary) -> void:
	var data: Dictionary = _read(player_path())
	var w: Dictionary = Dictionary(data.get("weights", {}))
	var total_n := 0
	var total_y := 0.0
	for a in enc_stats.keys():
		total_n += int(enc_stats[a]["n"])
		total_y += float(enc_stats[a]["sum_y"])
	var mean_all: float = total_y / maxf(1.0, float(total_n))
	for a in ACTIONS:
		var row: Array = Array(w.get(a, []))
		row.resize(FEATURES.size())
		for i in range(row.size()):
			row[i] = float(row[i]) * 0.97 if row[i] != null else 0.0
		if enc_stats.has(a) and int(enc_stats[a]["n"]) >= 2:
			var st: Dictionary = enc_stats[a]
			var adv: float = float(st["sum_y"]) / float(st["n"]) - mean_all
			row[0] = clampf(float(row[0]) + clampf(adv * 2.0, -0.25, 0.25), -1.2, 1.2)
		w[a] = row
	var priors: Dictionary = Dictionary(combat_report(skills_learned).get("skill_priors", {}))
	var old_priors: Dictionary = Dictionary(data.get("skill_priors", {}))
	for key in priors.keys():
		var cur: Array = priors[key]
		if old_priors.has(key):
			var old: Array = old_priors[key]
			var n: float = minf(60.0, float(old[1]) + float(cur[1]))
			var v: float = (float(old[0]) * float(old[1]) + float(cur[0]) * float(cur[1])) / maxf(1.0, float(old[1]) + float(cur[1]))
			old_priors[key] = [snappedf(v, 0.001), int(n)]
		else:
			old_priors[key] = cur
	var out := {
		"schema_version": SCHEMA_VERSION, "mode": "add", "features": FEATURES.duplicate(),
		"weights": w, "skill_priors": old_priors, "encounters": int(data.get("encounters", 0)) + 1,
		"updated_unix": int(Time.get_unix_time_from_system()),
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(user_dir))
	var f := FileAccess.open(player_path(), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out))


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
