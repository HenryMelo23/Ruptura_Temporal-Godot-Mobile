class_name RTMerchantRiftTransition
extends RefCounted

## Entrada e saida da Fenda do Mercador como cena, nao como corte seco.
##
##   dive       (mundo)    a fenda puxa a Geovana; os inimigos sao empurrados
##   land       (oficina)  ela cai do rasgo no teto da oficina
##   exit_dive  (oficina)  ela entra no portal de saida
##   emerge     (mundo)    ela sai do rasgo no ponto em que entrou
##
## O jeito muda com o numero de vezes que ela ja entrou NESTA partida:
##   1a        assustada   (arrastada, rodopia, cai de cara, levanta tonta)
##   2a a 4a   conformada  (anda ate a fenda, suspira e se deixa cair)
##   5a+       estilosa    (salta com mortal, aterrissagem heroica, sai na pose)
## Expulsa pelo colapso, ela sempre sai cuspida (ejected).
##
## Este arquivo cuida de tempo, posicao e trava de controle; o desenho fica em
## MerchantRiftTransitionPresentation. No multiplayer todos recebem a mesma
## entrada pela Fenda; so a autoridade empurra a horda.

const PHASE_NONE := ""
const PHASE_DIVE := "dive"
const PHASE_LAND := "land"
const PHASE_EXIT_DIVE := "exit_dive"
const PHASE_EMERGE := "emerge"

const MOOD_SCARED := "scared"
const MOOD_RESIGNED := "resigned"
const MOOD_STYLISH := "stylish"
const MOOD_EJECTED := "ejected"

## Entrada a partir da qual ela ja chega com estilo.
const STYLISH_FROM_ENTRY := 5

const DURATIONS := {
	"dive": {"scared": 1.35, "resigned": 1.05, "stylish": 0.95},
	"land": {"scared": 1.7, "resigned": 1.25, "stylish": 1.15},
	"exit_dive": {"scared": 0.95, "resigned": 0.8, "stylish": 0.8},
	"emerge": {"scared": 1.25, "resigned": 1.0, "stylish": 1.45, "ejected": 1.35},
}

## Empurrao ao entrar: todo inimigo mais perto que isso e jogado para a borda
## do anel, e e la que ele continua quando ela voltar da loja.
const PUSH_RADIUS := 470.0
const PUSH_JITTER := 70.0
const PUSH_TIME := 0.42
const BULLET_CLEAR_RADIUS := 560.0
## Respiro de invulnerabilidade depois que ela termina de sair.
const EMERGE_GRACE := 0.6

var core: Node = null
var phase: String = PHASE_NONE
var mood: String = MOOD_SCARED
var t: float = 0.0
var duration: float = 1.0
## Ponto de origem (onde ela comecou a cena) e alvo (fenda ou portal).
var origin: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
## Entradas concluidas nesta partida.
var entries: int = 0
var grace: float = 0.0
## Empurrao suave: [{enemy, from, to}] com referencia direta aos dicionarios.
var pushes: Array = []
var push_t: float = 0.0
## Instante (em t) do impacto no chao, para a presentation sincronizar poeira.
var impact_spawned: bool = false


func configure(runtime_core: Node) -> void:
	core = runtime_core


func reset_run() -> void:
	phase = PHASE_NONE
	t = 0.0
	entries = 0
	grace = 0.0
	pushes.clear()


func enabled() -> bool:
	return core != null and not bool(core.dedicated_server_mode)


func busy() -> bool:
	return phase != PHASE_NONE


func progress() -> float:
	return clampf(t / maxf(0.01, duration), 0.0, 1.0)


## Prende o jogador (movimento, ataque, habilidades) durante a cena.
func locks_player() -> bool:
	return busy()


func invulnerable() -> bool:
	return busy() or grace > 0.0


## Cena acontecendo dentro da oficina (queda pelo rasgo / saida pelo portal).
func busy_in_dimension() -> bool:
	return phase == PHASE_LAND or phase == PHASE_EXIT_DIVE


## A horda fica parada enquanto ela entra ou sai: e isso que garante que os
## inimigos empurrados continuem exatamente onde ficaram quando ela voltar.
func freezes_enemies() -> bool:
	return phase == PHASE_DIVE or phase == PHASE_EMERGE


static func mood_for_entry(entry_number: int) -> String:
	if entry_number <= 1:
		return MOOD_SCARED
	if entry_number < STYLISH_FROM_ENTRY:
		return MOOD_RESIGNED
	return MOOD_STYLISH


func _start(new_phase: String, new_mood: String, from: Vector2, to: Vector2) -> void:
	phase = new_phase
	mood = new_mood
	t = 0.0
	impact_spawned = false
	duration = float(Dictionary(DURATIONS[new_phase]).get(new_mood, 1.0))
	origin = from
	target = to


# ------------------------------------------------------------------ entrada
## Chamado pela fenda quando ela encosta. A troca para a oficina acontece no
## fim do mergulho.
func begin_dive(rift_pos: Vector2) -> void:
	_start(PHASE_DIVE, mood_for_entry(entries + 1), Vector2(core.player_pos), rift_pos)
	if core._is_world_authority():
		push_enemies_smooth(rift_pos)
	core._clear_attack_lock()
	core._stop_move_touch()
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.22)
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), 8.0)
	core._spawn_radial_particles(rift_pos, Color(0.86, 0.6, 1.0), 30)
	core._play_sfx("Portal.mp3", 0.04, 0.55, 0.78)


## Ja dentro da oficina: comeca a queda pelo rasgo.
func begin_land(entry_pos: Vector2) -> void:
	entries += 1
	_start(PHASE_LAND, mood_for_entry(entries), entry_pos, entry_pos)


func begin_exit_dive(portal_pos: Vector2) -> void:
	_start(PHASE_EXIT_DIVE, mood_for_entry(entries), Vector2(core.player_pos), portal_pos)
	core._stop_move_touch()
	core._play_sfx("Portal.mp3", 0.04, 0.5, 1.05)


## Ja de volta ao mundo, no ponto em que ela entrou.
func begin_emerge(expelled: bool) -> void:
	var emerge_mood: String = MOOD_EJECTED if expelled else mood_for_entry(entries)
	_start(PHASE_EMERGE, emerge_mood, Vector2(core.player_pos), Vector2(core.player_pos))


# ------------------------------------------------------------------ ciclo
func update(delta: float) -> void:
	grace = maxf(0.0, grace - delta)
	_update_pushes(delta)
	if not busy():
		return
	t += delta
	var p: float = progress()
	match phase:
		PHASE_DIVE:
			core.player_pos = origin.lerp(target, _dive_pull(p))
			if p >= 1.0:
				_finish_dive()
		PHASE_LAND:
			core.player_pos = target
			if not impact_spawned and p >= impact_time():
				impact_spawned = true
				_on_impact()
			if p >= 1.0:
				phase = PHASE_NONE
		PHASE_EXIT_DIVE:
			core.player_pos = origin.lerp(target, _exit_pull(p))
			if p >= 1.0:
				phase = PHASE_NONE
				# leave() chama begin_emerge() de volta.
				core._merchant_dimension().leave(false)
		PHASE_EMERGE:
			core.player_pos = target
			if not impact_spawned and p >= impact_time():
				impact_spawned = true
				_on_impact()
			if p >= 1.0:
				phase = PHASE_NONE
				grace = EMERGE_GRACE


## Fracao (0..1) da cena em que ela toca o chao.
func impact_time() -> float:
	if phase == PHASE_LAND:
		match mood:
			MOOD_SCARED:
				return 0.36
			MOOD_RESIGNED:
				return 0.38
			MOOD_STYLISH:
				return 0.42
	if phase == PHASE_EMERGE:
		match mood:
			MOOD_EJECTED, MOOD_SCARED:
				return 0.42
			MOOD_RESIGNED:
				return 0.3
			MOOD_STYLISH:
				return 0.38
	return 1.0


func _on_impact() -> void:
	# A poeira do impacto e desenhada pela presentation (arte rift_fx/dust);
	# a fumaca generica de pouso so entra se essa arte nao existir.
	if not ResourceLoader.exists("res://assets/sprites/rift_fx/dust_0.png"):
		core._spawn_player_landing_smoke(Vector2(core.player_pos))
	match mood:
		MOOD_STYLISH:
			core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.2)
			core.screen_shake_strength = maxf(float(core.screen_shake_strength), 10.0)
			core._spawn_radial_particles(Vector2(core.player_pos), Color(1.0, 0.84, 0.36), 22)
			core._vibrate(90, 0.5)
		MOOD_SCARED, MOOD_EJECTED:
			core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.16)
			core.screen_shake_strength = maxf(float(core.screen_shake_strength), 7.0)
			core._vibrate(140, 0.6)
		_:
			core._vibrate(50, 0.3)


func _finish_dive() -> void:
	phase = PHASE_NONE
	core.player_pos = target
	_settle_pushes()
	if core.shop_rift_controller.active():
		var rift: Dictionary = core.shop_rift
		rift["diving"] = false
		rift["state"] = RTMerchantRiftController.STATE_ENTERED
		rift["state_age"] = 0.0
		rift["entered_msec"] = Time.get_ticks_msec()
	if core._merchant_dimension().enter():
		begin_land(Vector2(core.player_pos))
		return
	# A oficina recusou (nao deveria): cai no fluxo antigo da loja.
	core.shop_controller.start_opening_animation(true)


## Quanto do caminho ate a fenda ela ja percorreu, por humor.
func _dive_pull(p: float) -> float:
	match mood:
		MOOD_SCARED:
			# Resiste no comeco (escorrega devagar), depois e sugada.
			return clampf(p * p * 0.55 + smoothstep(0.35, 0.8, p) * 0.45, 0.0, 1.0)
		MOOD_RESIGNED:
			return smoothstep(0.0, 0.55, p)
		MOOD_STYLISH:
			return smoothstep(0.0, 0.42, p)
	return p


func _exit_pull(p: float) -> float:
	match mood:
		MOOD_SCARED:
			return smoothstep(0.25, 0.9, p)
		MOOD_STYLISH:
			return smoothstep(0.0, 0.6, p)
	return smoothstep(0.0, 0.8, p)


# ------------------------------------------------------------------ empurrao
## Empurra (com animacao curta) todo inimigo perto da fenda para fora do anel
## e apaga os tiros inimigos ao redor. E chamado ao comecar o mergulho.
func push_enemies_smooth(center: Vector2) -> void:
	pushes.clear()
	push_t = 0.0
	for enemy in core.enemies:
		var to: Vector2 = _pushed_position(enemy, center)
		if to.is_finite():
			pushes.append({"enemy": enemy, "from": Vector2(enemy["pos"]), "to": to})
	_clear_bullets(center)


## Garante o anel livre na hora de salvar o mundo (ao entrar na oficina):
## o que ainda estiver dentro vai direto para a borda e fica la.
func push_enemies_now(center: Vector2) -> void:
	_settle_pushes()
	for enemy in core.enemies:
		var to: Vector2 = _pushed_position(enemy, center)
		if to.is_finite():
			enemy["pos"] = to
	_clear_bullets(center)


func _pushed_position(enemy: Dictionary, center: Vector2) -> Vector2:
	if float(enemy.get("hp", 0.0)) <= 0.0 or bool(enemy.get("is_boss", false)):
		return Vector2.INF
	if String(enemy.get("type", "")) == String(core.ENEMY_AMBER_SUTURE_NODE):
		return Vector2.INF # no de sutura e preso no chao
	var pos: Vector2 = Vector2(enemy["pos"])
	var offset: Vector2 = pos - center
	var dist: float = offset.length()
	if dist >= PUSH_RADIUS:
		return Vector2.INF
	var dir: Vector2 = offset / dist if dist > 1.0 else Vector2.RIGHT.rotated(float(int(enemy.get("uid", 0)) % 24) * TAU / 24.0)
	var jitter: float = float(int(enemy.get("uid", 0)) % 7) / 6.0 * PUSH_JITTER
	var world: Vector2 = Vector2(core.WORLD_SIZE)
	return (center + dir * (PUSH_RADIUS + jitter)).clamp(Vector2(40, 40), world - Vector2(40, 40))


func _update_pushes(delta: float) -> void:
	if pushes.is_empty():
		return
	push_t += delta
	var k: float = clampf(push_t / PUSH_TIME, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - k, 3.0)
	for item in pushes:
		var enemy: Dictionary = item["enemy"]
		enemy["pos"] = Vector2(item["from"]).lerp(Vector2(item["to"]), eased)
	if k >= 1.0:
		pushes.clear()


func _settle_pushes() -> void:
	for item in pushes:
		var enemy: Dictionary = item["enemy"]
		enemy["pos"] = Vector2(item["to"])
	pushes.clear()


func _clear_bullets(center: Vector2) -> void:
	var kept: Array = []
	for bullet in core.enemy_bullets:
		if Vector2(bullet.get("pos", Vector2.INF)).distance_to(center) > BULLET_CLEAR_RADIUS:
			kept.append(bullet)
	core.enemy_bullets.assign(kept)


func save_state() -> Dictionary:
	return {"entries": entries}


func load_state(data: Dictionary) -> void:
	entries = maxi(0, int(data.get("entries", entries)))
	phase = PHASE_NONE
	pushes.clear()
