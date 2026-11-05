class_name RTBoss7Animator
extends RefCounted

## Escolhe o frame da Fenix por estado, com fps proprio por animacao.
## Frames novos (Codex) ficam em res://assets/sprites/boss7_fenix/v2/<anim>_<NN>.png
## e sao carregados se existirem; sem eles cai nas animacoes antigas.

const V2_DIR := "res://assets/sprites/boss7_fenix/v2/"
const ANIMS := {
	# chave: [frames esperados, fps, loop, fallback]
	"fly": [8, 12.0, true, "boss7_fly"],
	"glide": [6, 10.0, true, "boss7_fly"],
	"cast": [6, 0.0, false, "boss7_fly"],
	"wing": [6, 0.0, false, "boss7_fly"],
	"rise": [4, 14.0, true, "boss7_fly"],
	"dive": [4, 16.0, true, "boss7_dive"],
	"land": [5, 0.0, false, "boss7_dive"],
	"screech": [6, 12.0, true, "boss7_fly"],
	"egg": [6, 8.0, true, "boss7_core"],
	"rebirth": [8, 0.0, false, "boss7_fly"],
}

static var _cache: Dictionary = {}


static func frames(anim: String) -> Array:
	if _cache.has(anim):
		return _cache[anim]
	var out: Array = []
	var spec: Array = ANIMS.get(anim, [0])
	for i in range(int(spec[0])):
		var path := "%s%s_%02d.png" % [V2_DIR, anim, i + 1]
		if not ResourceLoader.exists(path):
			out.clear()
			break
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			out.clear()
			break
		out.append(tex)
	_cache[anim] = out
	return out


static func has_v2(anim: String) -> bool:
	return not frames(anim).is_empty()


## Animacao logica atual + progresso (0..1) para as que nao fazem loop.
static func current(game: Node) -> Array:
	var motion: RTBoss7MotionController = game._boss7_motion()
	var state: String = String(game.boss7_state)
	if game.boss7_core_active:
		return ["egg", -1.0]
	match state:
		game.BOSS7_STATE_FEATHER:
			return ["cast", 1.0 - float(game.boss7_state_timer) / maxf(0.01, game.BOSS7_FEATHER_WINDUP)]
		game.BOSS7_STATE_WING:
			return ["wing", 1.0 - float(game.boss7_state_timer) / maxf(0.01, game.BOSS7_WING_WINDUP)]
		game.BOSS7_STATE_DIVE_PREP:
			return ["rise", -1.0]
		game.BOSS7_STATE_DIVE:
			return ["dive", -1.0]
		game.BOSS7_STATE_REBIRTH, game.BOSS7_STATE_INTRO:
			return ["rebirth", 1.0 - float(game.boss7_state_timer) / maxf(0.01, game.BOSS7_REBIRTH_ANIM_TIME)]
		RTBoss7MotionController.STATE_SWOOP:
			return ["dive", -1.0]
		RTBoss7MotionController.STATE_SWOOP_WARN:
			return ["glide", -1.0]
		game.BOSS7_STATE_RECOVERY:
			if motion.land_left > 0.0:
				return ["land", 1.0 - motion.land_left / RTBoss7MotionController.LAND_TIME]
	if game.boss7_whirlwind_active or _crown_active(game):
		return ["screech", -1.0]
	if motion.speed() > 200.0:
		return ["glide", -1.0]
	return ["fly", -1.0]


static func _crown_active(game: Node) -> bool:
	for atk in game.boss_attacks:
		if String(atk.get("kind", "")) == game.BOSS7_ATTACK_CROWN:
			return true
	return false


static func texture(game: Node) -> Texture2D:
	var cur: Array = current(game)
	var anim: String = String(cur[0])
	var progress: float = float(cur[1])
	var spec: Array = ANIMS.get(anim, [4, 10.0, true, "boss7_fly"])
	var list: Array = frames(anim)
	var fps: float = float(spec[1])
	if list.is_empty():
		list = game.textures.get(String(spec[3]), [])
		# Animacao antiga tem so 4 frames: mais lenta para nao tremer.
		fps = 7.5 if String(spec[3]) == "boss7_fly" else 9.0
		progress = -1.0
	if list.is_empty():
		return game.textures.get("boss")
	var idx: int
	if progress >= 0.0:
		idx = clampi(int(progress * float(list.size())), 0, list.size() - 1)
	else:
		# Batida de asa acelera com a velocidade do voo.
		var speed_k: float = 1.0 + clampf(game._boss7_motion().speed() / 300.0, 0.0, 1.0) * 0.35
		idx = int(float(game.time_alive) * fps * speed_k) % list.size()
	var tex: Texture2D = list[idx]
	return tex if tex != null else game.textures.get("boss")


## Glide/dive/land sao desenhados de lado olhando para a direita: espelha
## quando a Fenix vai para a esquerda.
static func should_flip(game: Node) -> bool:
	var anim: String = String(current(game)[0])
	if not anim in ["glide", "dive", "land"]:
		return false
	return Vector2(game.boss7_attack_dir).x < -0.05


## Fase da batida (0..1) para o squash/stretch procedural.
static func flap_phase(game: Node) -> float:
	return fposmod(float(game.time_alive) * 12.0 / 8.0, 1.0)
