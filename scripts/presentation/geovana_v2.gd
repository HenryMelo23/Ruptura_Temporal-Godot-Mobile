class_name RTGeovanaV2
extends RefCounted

## Geovana base v2 (arte refeita pelo Codex a partir de uma folha-modelo unica):
## repouso, andar em 3 direcoes, disparo em 8 direcoes, queda inicial e dano.
##
## Frames: res://assets/sprites/player/geovana_v2/<anim>_NN.png (recortados por
## tools/geovana_v2_slice.py). Todos no mesmo canvas 256x256 e na mesma escala:
## de pe ela tem 170 px e os pes ficam em y=246. Desenhados com DRAW_HEIGHT,
## a pose de pe mede os mesmos 80 px de antes e os pes ficam em player_pos + 40.
##
## install() troca as listas de textura do jogo (player_idle, player_right,
## player_up, player_down, player_fire*, player_damage, player_start_down), entao
## a logica de animacao, prioridade e multiplayer continua a mesma; so a arte e
## o numero de quadros mudam. Sem os arquivos, nada muda (arte antiga).

const ROOT := "res://assets/sprites/player/geovana_v2/"
const CANVAS := 256.0
const STAND_H := 170.0
const FEET_Y := 246.0
const PLAYER_H := 80.0
const DRAW_HEIGHT := CANVAS * PLAYER_H / STAND_H
## Desce o desenho para os pes (y=246 do canvas) cairem em player_pos + 40.
const FEET_OFFSET := Vector2(0.0, (CANVAS - FEET_Y) * PLAYER_H / STAND_H)
const FIRE_DIRS := ["south", "north", "northeast", "northwest", "southwest", "southeast"]
const WALK_MS := 95
const IDLE_MS := 190
const LAND_FRAMES := 4

static var _installed_ids: Dictionary = {}


static func available() -> bool:
	return ResourceLoader.exists(ROOT + "idle_01.png")


static func frames(anim: String) -> Array:
	var out: Array = []
	for i in range(1, 13):
		var path := "%s%s_%02d.png" % [ROOT, anim, i]
		if not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path)
		if tex == null:
			break
		out.append(tex)
	return out


static func is_v2(tex: Texture2D) -> bool:
	return tex != null and _installed_ids.has(tex.get_instance_id())


static func _remember(list: Array) -> Array:
	for tex in list:
		if tex != null:
			_installed_ids[tex.get_instance_id()] = true
	return list


## Troca a arte da Geovana base. Chamado depois que as texturas antigas carregam.
static func install(game: Node) -> bool:
	if not available():
		return false
	var t: Dictionary = game.textures
	var idle := _remember(frames("idle"))
	var right := _remember(frames("walk_right"))
	var down := _remember(frames("walk_down"))
	var up := _remember(frames("walk_up"))
	var east := _remember(frames("fire_east"))
	var damage := _remember(frames("damage"))
	var fall := _remember(frames("fall"))
	var land := _remember(frames("land"))
	if idle.is_empty() or right.is_empty() or east.is_empty():
		return false
	t["player_idle"] = idle
	t["player_right"] = right
	t["player_left"] = right
	if not up.is_empty():
		t["player_up"] = up
	if not down.is_empty():
		t["player_down"] = down
	if not damage.is_empty():
		t["player_damage"] = damage
	if fall.size() >= 4 and land.size() >= LAND_FRAMES:
		t["player_start_down"] = fall + land
	t["player_fire"] = east
	# Rede: um bloco de quadros por direcao (leste primeiro), na ordem de
	# PLAYER_FIRE_DIRECTIONS; o indice enviado e offset + quadro, como o local.
	var network: Array = east.duplicate()
	for dir in FIRE_DIRS:
		var list := _remember(frames("fire_" + dir))
		if list.size() != east.size():
			list = east
		t["player_fire_" + dir] = list
		network.append_array(list)
	t["player_fire_network"] = network
	t["player_fire_back_diag"] = t["player_fire_northeast"]
	t["player_fire_up"] = t["player_fire_north"]
	t["player_fire_down"] = t["player_fire_south"]
	return true


static func draw_profile() -> Dictionary:
	return {"preserve_height": true, "height": DRAW_HEIGHT, "offset": FEET_OFFSET}


## Quadro do disparo com N quadros dentro da mesma janela da pose de ataque.
static func fire_frame(frame_count: int, elapsed: float, pose_seconds: float) -> int:
	return clampi(int(elapsed / maxf(0.001, pose_seconds / float(frame_count))), 0, frame_count - 1)


## Queda inicial: 2 quadros caindo em loop, o 3o perto do chao, depois o
## impacto e a aterrissagem em sequencia (sem loop).
static func start_down_frame(falling: bool, progress: float, landing_elapsed: float, land_time: float, frame_time: float) -> int:
	if falling:
		return 2 if progress >= 0.78 else int(floor(progress / maxf(0.01, frame_time))) % 2
	var steps: int = LAND_FRAMES + 1
	return 3 + clampi(int(landing_elapsed / maxf(0.01, land_time / float(steps))), 0, LAND_FRAMES)
