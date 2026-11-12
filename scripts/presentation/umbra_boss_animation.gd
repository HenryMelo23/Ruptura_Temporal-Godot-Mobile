class_name RTUmbraBossAnimation
extends RefCounted

## Corpo da UMBRA v3: a Geovana corrompida pelo poder cosmico, flutuando.
## Sem frames de andar: ela paira. Cada acao dispara uma animacao one-shot;
## fora delas fica o loop "idle". Sifao fica em loop enquanto dura.
##
## Frames: res://assets/sprites/umbra_v3/<anim>_NN.png (01, 02, ...), canvas
## 256x384, olhando para a DIREITA (o jogo espelha), mesma escala e ancora em
## todos. Enquanto a arte nao existe, o jogo usa os sprites antigos.

const ROOT := "res://assets/sprites/umbra_v3/"
## anim: [frames esperados, fps, loop]
const ANIMS: Dictionary = {
	"idle": [4, 6.0, true],
	"ataque": [4, 12.0, false],
	"teleporte": [2, 8.0, false],
	"sifao": [3, 6.0, true],
	"transmutar": [4, 8.0, false],
	"rebobinar": [3, 8.0, false],
	"eco": [3, 8.0, false],
	"conjurar": [3, 9.0, false],
	"dano": [2, 10.0, false],
	"morte": [2, 3.0, false],
}
const ACTION_ANIM: Dictionary = {
	"ATAQUE": "ataque",
	"TELEPORTE": "teleporte", "TELEPORTE_JUKE": "teleporte",
	"SIFON": "sifao",
	"REBOBINAR": "rebobinar",
	"ECO_PROFETICO": "eco",
	"VORTICE": "conjurar", "PRISAO": "conjurar", "MIASMA": "conjurar", "DESCARGA_ELETRICA": "conjurar",
	"CAMINHO_ESPINHOS": "conjurar", "LASER_SOBRECARGA": "conjurar", "PRAGA_RATOS": "conjurar",
}
## Caixa de desenho quando a arte v3 existe. O canvas 256x384 tem folga para
## cabelo, bracos e magia, entao o corpo visivel fica em torno de 3/4 disso:
## com 250 de altura ela aparece ~2,2x o jogador, como convem ao chefe final.
const DRAW_SIZE := Vector2(166.0, 250.0)
const HOVER := -16.0

static var _cache: Dictionary = {}
static var current := ""
static var started := 0.0


static func frames(anim: String) -> Array[Texture2D]:
	if _cache.has(anim):
		return _cache[anim]
	var out: Array[Texture2D] = []
	for i in range(1, 13):
		var path: String = "%s%s_%02d.png" % [ROOT, anim, i]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path)
		if tex == null:
			break
		out.append(tex)
	_cache[anim] = out
	return out


## A arte v3 so assume quando o loop basico existe.
static func available() -> bool:
	return not frames("idle").is_empty()


static func anim_for_action(action: String) -> String:
	if action.begins_with("TRANSMUTAR_"):
		return "transmutar"
	return String(ACTION_ANIM.get(action, ""))


## Chamado pelo executor quando a UMBRA age.
static func on_action(game: Node, action: String) -> void:
	var anim: String = anim_for_action(action)
	if anim == "" or anim == "sifao":
		return
	current = anim
	started = float(game.time_alive)


static func duration(anim: String) -> float:
	var spec: Array = ANIMS.get(anim, [1, 1.0, false])
	var n: int = frames(anim).size()
	return float(n if n > 0 else int(spec[0])) / float(spec[1])


## Nome da animacao que deve aparecer agora (sem depender da arte).
static func state(game: Node) -> String:
	if bool(game.boss_dead) or float(game.boss_hp) <= 0.0:
		return "morte"
	if float(game.boss5_siphon_timer) > 0.0:
		return "sifao"
	var t: float = float(game.time_alive)
	if current != "" and t - started < duration(current):
		return current
	current = ""
	if float(game.damage_flash_timer) > 0.0:
		return "dano"
	return "idle"


static func active_texture(game: Node) -> Texture2D:
	if not available():
		return null
	var anim: String = state(game)
	var list: Array[Texture2D] = frames(anim)
	if list.is_empty():
		list = frames("idle")
		anim = "idle"
	var spec: Array = ANIMS[anim]
	var t: float = float(game.time_alive) - (started if anim == current else 0.0)
	var idx: int = int(floor(t * float(spec[1])))
	idx = posmod(idx, list.size()) if bool(spec[2]) else clampi(idx, 0, list.size() - 1)
	return list[idx]


## A arte olha para a direita: espelha quando o jogador esta a esquerda.
static func should_flip_h(game: Node) -> bool:
	return Vector2(game.player_pos).x < Vector2(game.boss_pos).x - 6.0


static func draw_position(game: Node) -> Vector2:
	var bob: Vector2 = Vector2(sin(float(game.boss_phase) * 0.65) * 4.0, sin(float(game.boss_phase) * 1.1) * 6.0)
	return Vector2(game.boss_pos) + bob + Vector2(0.0, HOVER if available() else 0.0)
