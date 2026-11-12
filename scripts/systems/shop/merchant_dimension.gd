class_name RTMerchantDimension
extends RefCounted

## A Fenda do Mercador virou um lugar: uma dimensao pequena e instavel onde o
## Mercador conserta o teleportador dele. A Geovana entra pela fenda, corre ate
## a bancada e troca essencia por cartas enquanto o portal aguenta.
##
## Nao e um modo de UI: o mundo continua rodando (ela anda, a camera segue), so
## que sem horda e com o mapa trocado. A loja antiga abre ao falar com ele.
##
## MULTIPLAYER: todos entram juntos (a propria fenda ja avisa os outros antes
## de abrir). O tempo vale para a sala inteira e usa o orcamento do jogador que
## tem mais cartas para comprar. Ninguem sai sozinho: cada um toca a saida, e o
## portal so cospe o grupo quando todos tocarem. Se o tempo acabar com alguem
## fora da saida, a fenda confisca a essencia de todo mundo.

const WORLD_SIZE := Vector2(1500.0, 1050.0)
const MERCHANT_POS := Vector2(556.0, 586.0)
## A geringonca fica no centro; ele trabalha ao lado dela, sem ficar escondido.
const TELEPORTER_POS := Vector2(812.0, 496.0)
const PLAYER_ENTRY := Vector2(750.0, 798.0)
const EXIT_PORTAL_POS := Vector2(750.0, 975.0)
const TALK_RADIUS := 132.0
const EXIT_RADIUS := 86.0
const ENTRY_FADE := 0.55

## Fenda instavel: o jogador leva cerca de 20 s para decidir cada carta.
const SECONDS_PER_CARD := 20.0
## Quantas compras o orcamento de um jogador pode pagar, dentro destes limites.
const MIN_BUDGET_CARDS := 3
const MAX_BUDGET_CARDS := 12
const MIN_SECONDS := 45.0
const WARN_SECONDS := 10.0
## A partir daqui a contagem regressiva grande aparece na tela.
const COUNTDOWN_SECONDS := 15.0
const COLLAPSE_TIME := 1.4

var core: Node = null
## Estado da fase guardado enquanto ela esta na dimensao.
var saved: Dictionary = {}
var active := false
var timer := 0.0
var limit := 0.0
var collapsing := 0.0
var entry_age := 0.0
var talked_this_visit := false
## A bancada so reabre depois que ela se afasta: senao a loja colaria nela.
var counter_armed := true
## Quanto o mercador ficou devendo (pontos confiscados na ultima expulsao).
var confiscated := 0
## Quantas vezes a fenda ja colapsou: o id do evento de pontos precisa ser
## unico, senao a segunda expulsao da run seria descartada como repetida.
var collapses := 0
## ------------------------------------------------------------ multiplayer
## Este jogador ja encostou no portal de saida e espera os companheiros.
var mp_ready := false
## Companheiros que ja avisaram que estao na saida, por peer: contar peers
## distintos e o que faz a regra valer para 3 jogadores, nao so para 2.
var mp_ready_peers: Dictionary = {}
## Maior orcamento anunciado na sala, em cartas.
var mp_budget_cards := 0
## Algum companheiro ja entregou as pecas: a fenda vale estavel para a sala
## inteira, senao o relogio correria so para metade dos jogadores.
var mp_room_stable := false
var mp_last_second_announced := -1


func configure(runtime_core: Node) -> void:
	core = runtime_core


## Sinal de "minha fenda esta estavel" dentro do pacote de orcamento.
const BUDGET_STABLE := -1


func stable() -> bool:
	if core == null:
		return false
	return core._merchant_npc().mission_complete() or mp_room_stable


func remaining() -> float:
	return maxf(0.0, limit - timer)


func urgent() -> bool:
	return active and not stable() and remaining() <= WARN_SECONDS


## Janela da contagem regressiva grande, com aviso para ir para a saida.
func counting_down() -> bool:
	return active and not stable() and remaining() <= COUNTDOWN_SECONDS


func multiplayer_room() -> bool:
	return core != null and core.is_multiplayer


## Quantos ja estao na saida, contando este jogador.
func mp_ready_total() -> int:
	return mp_ready_peers.size() + (1 if mp_ready else 0)


## Quantos companheiros ainda faltam tocar na saida (0 = pode sair).
func mp_waiting_count() -> int:
	if not multiplayer_room():
		return 0
	var expected: int = maxi(1, int(core.shop_mp_expected_count))
	return maxi(0, expected - maxi(mp_ready_total(), int(core.shop_mp_ready_count)))


## Companheiro avisou que chegou na saida.
func on_remote_exit_ready(peer_id: int) -> void:
	if not active or peer_id == 0:
		return
	mp_ready_peers[peer_id] = true


func mp_everyone_ready() -> bool:
	if not multiplayer_room():
		return true
	if not mp_ready:
		return false
	var expected: int = maxi(1, int(core.shop_mp_expected_count))
	# O servidor dedicado manda a contagem pronta; entre pares, somamos os
	# peers que avisaram. shop_mp_partner_ready sozinho nao serve: com tres
	# jogadores ele ficaria verdadeiro com um unico companheiro na saida.
	return mp_ready_total() >= expected or int(core.shop_mp_ready_count) >= expected


# ================================================================ entrada
## Quantas cartas a essencia deste jogador paga. E o que define o tempo dele.
func budget_cards() -> int:
	if core == null:
		return MIN_BUDGET_CARDS
	var price: int = maxi(1, int(core.card_cost))
	return clampi(int(core.score) / price, MIN_BUDGET_CARDS, MAX_BUDGET_CARDS)


func _limit_for(cards: int) -> float:
	return maxf(float(cards) * SECONDS_PER_CARD, MIN_SECONDS)


## Orcamento anunciado por um companheiro: a sala passa a usar o maior.
func on_remote_budget(cards: int) -> void:
	if cards == BUDGET_STABLE:
		mp_room_stable = true
		return
	var clamped: int = clampi(cards, MIN_BUDGET_CARDS, MAX_BUDGET_CARDS)
	if clamped <= mp_budget_cards:
		return
	mp_budget_cards = clamped
	# O tempo so cresce: encurtar a fenda no meio da compra seria injusto.
	limit = maxf(limit, _limit_for(clamped))


func enter() -> bool:
	if active or core == null:
		return false
	saved = {
		"world": Vector2(core.WORLD_SIZE),
		"player_pos": Vector2(core.player_pos),
		"enemies": core.enemies.duplicate(),
		"enemy_bullets": core.enemy_bullets.duplicate(),
		"bullets": core.bullets.duplicate(),
		"spawn_timer": float(core.spawn_timer),
		"heal_orbs": core.heal_orbs.duplicate(),
	}
	core.enemies.clear()
	core.enemy_bullets.clear()
	core.bullets.clear()
	core.heal_orbs.clear()
	core.WORLD_SIZE = WORLD_SIZE
	core.player_pos = PLAYER_ENTRY
	core.camera_follow_initialized = false
	core.spawn_timer = 99999.0
	active = true
	entry_age = 0.0
	talked_this_visit = false
	counter_armed = true
	collapsing = 0.0
	timer = 0.0
	mp_ready = false
	mp_ready_peers.clear()
	mp_room_stable = false
	mp_last_second_announced = -1
	mp_budget_cards = budget_cards()
	limit = _limit_for(mp_budget_cards)
	if multiplayer_room():
		# Cada um anuncia o proprio orcamento; a sala fica com o maior.
		core.shop_mp_ready_count = 0
		core.shop_mp_partner_ready = false
		core.shop_mp_ready_to_leave = false
		core.shop_mp_expected_count = maxi(1, core._living_run_player_peer_ids().size())
		core._announce_merchant_rift_budget(BUDGET_STABLE if stable() else mp_budget_cards)
	core._merchant_npc().on_dimension_entered(confiscated)
	core._play_sfx("Portal.mp3", 0.04, 0.72, 0.9)
	core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.4)
	core.screen_shake_strength = maxf(float(core.screen_shake_strength), 14.0)
	return true


## Saida normal (pelo portal) ou expulsao. `expelled` confisca a essencia.
func leave(expelled: bool) -> void:
	if not active:
		return
	active = false
	collapsing = 0.0
	mp_ready = false
	mp_ready_peers.clear()
	if expelled:
		collapses += 1
		confiscated = maxi(0, int(core.score))
		if confiscated > 0:
			# Castigo local de cada bolso, sem passar pela autoridade: com
			# broadcast a replica descartaria o desconto e so o anfitriao
			# perderia a essencia.
			core._apply_score_delta(-confiscated, false, "merchant_rift_collapse_%d" % collapses)
			var warning: String = "A FENDA LEVOU %s PONTOS" % core._format_points(confiscated)
			if multiplayer_room():
				warning = "A FENDA LEVOU A ESSENCIA DE TODOS"
			core._add_text(warning, core.player_pos + Vector2(-150, -120), Color(1.0, 0.38, 0.42), 2.6, 22)
		core._merchant_npc().on_player_expelled()
	core.WORLD_SIZE = Vector2(saved.get("world", core.DEFAULT_WORLD_SIZE))
	core.player_pos = Vector2(saved.get("player_pos", core.player_pos))
	core.enemies.assign(Array(saved.get("enemies", [])))
	core.enemy_bullets.assign(Array(saved.get("enemy_bullets", [])))
	core.bullets.assign(Array(saved.get("bullets", [])))
	core.heal_orbs.assign(Array(saved.get("heal_orbs", [])))
	core.spawn_timer = float(saved.get("spawn_timer", 2.0))
	core.camera_follow_initialized = false
	saved.clear()
	if core.mode == "shop" or core.mode == "shop_mp_waiting":
		core.shop_controller.finish()
		if core.mode == "shop_return":
			# A fenda fechou com a tela de cartas aberta: nao ha visor para
			# recolher com animacao, ela ja esta de volta ao mundo.
			core.mode = "game"
			core.shop_return_timer = 0.0
	core._play_sfx("Portal.mp3", 0.04, 0.68, 1.15)


# ================================================================ ciclo
func update(delta: float) -> void:
	if not active:
		return
	entry_age += delta
	_refresh_mp_expectation()
	var npc: RTMerchantNpc = core._merchant_npc()
	npc.update(delta)
	if collapsing > 0.0:
		collapsing = maxf(0.0, collapsing - delta)
		core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.3)
		core.screen_shake_strength = maxf(float(core.screen_shake_strength), 16.0)
		if collapsing <= 0.0:
			leave(true)
		return
	# O cronometro corre com a fenda instavel, inclusive com a loja aberta:
	# escolher carta tambem gasta o tempo dela.
	if not stable() and not core._dialogue().busy():
		timer += delta
		_tick_countdown_feedback()
		if timer >= limit:
			_begin_collapse()
			return
		if urgent() and core.rng.randf() < delta * 0.9:
			core.screen_shake_timer = maxf(float(core.screen_shake_timer), 0.12)
			core.screen_shake_strength = maxf(float(core.screen_shake_strength), 3.5)
	# Na sala cheia a saida e coletiva: quem ja tocou espera os outros.
	if mp_ready:
		if mp_everyone_ready():
			leave(false)
		return
	if core.mode != "game" or core._dialogue().busy():
		return
	var dist: float = core.player_pos.distance_to(MERCHANT_POS)
	if dist > TALK_RADIUS * 1.35:
		counter_armed = true
	if dist <= TALK_RADIUS:
		if not talked_this_visit:
			talked_this_visit = true
			npc.greet(self)
		elif counter_armed and not core.shop_controller.busy():
			counter_armed = false
			_open_counter()
	elif core.player_pos.distance_to(EXIT_PORTAL_POS) <= EXIT_RADIUS and entry_age > 1.2:
		_reach_exit()


## A sala muda de tamanho: quem morreu, virou espectador ou caiu fora nao pode
## prender o grupo esperando um toque no portal que nunca vem.
func _refresh_mp_expectation() -> void:
	if not multiplayer_room():
		return
	var living: Array = core._living_run_player_peer_ids()
	core.shop_mp_expected_count = maxi(1, living.size())
	for peer_id in mp_ready_peers.keys():
		if not living.has(int(peer_id)):
			mp_ready_peers.erase(peer_id)
	if not mp_ready and (bool(core.is_dead) or bool(core.online_local_spectator)):
		# Espectador nao anda ate o portal: entra pronto e espera os vivos.
		mp_ready = true


## Encostou no portal. Em solo sai na hora; na sala cheia vira "pronto".
func _reach_exit() -> void:
	if not multiplayer_room():
		leave(false)
		return
	mp_ready = true
	core.shop_mp_ready_to_leave = true
	core.shop_mp_ready_count = maxi(int(core.shop_mp_ready_count), 1)
	if core._shop_rpc_available():
		core.rpc("_rpc_shop_ready")
	core._add_text("ESPERANDO A EQUIPE", core.player_pos + Vector2(-110, -110), Color(0.6, 0.9, 1.0), 2.0, 18)
	if mp_everyone_ready():
		leave(false)


## Tique sonoro e vibracao nos ultimos segundos, uma vez por segundo.
func _tick_countdown_feedback() -> void:
	if not counting_down():
		return
	var second: int = int(ceil(remaining()))
	if second == mp_last_second_announced:
		return
	mp_last_second_announced = second
	core._play_sfx("shop_countdown_tick", 0.0, 0.5, 1.0 + float(COUNTDOWN_SECONDS - second) * 0.03)
	if second <= 5:
		core._vibrate(90, 0.4)


func _begin_collapse() -> void:
	collapsing = COLLAPSE_TIME
	core._add_text("A FENDA COLAPSA!", core.player_pos + Vector2(-110, -150), Color(1.0, 0.3, 0.3), 1.6, 26)
	core._play_sfx("shop_countdown_tick", 0.0, 0.9, 0.7)
	core._vibrate(420, 0.9)


## Abre a loja antiga na bancada do Mercador.
func _open_counter() -> void:
	if core.mode == "shop" or core.mode == "shop_opening":
		return
	core.shop_controller.open_shop(true)


func save_state() -> Dictionary:
	return {"active": active, "timer": timer, "limit": limit, "confiscated": confiscated, "talked": talked_this_visit, "collapses": collapses}


func load_state(data: Dictionary) -> void:
	timer = float(data.get("timer", 0.0))
	limit = float(data.get("limit", MIN_SECONDS))
	confiscated = int(data.get("confiscated", 0))
	talked_this_visit = bool(data.get("talked", false))
	collapses = int(data.get("collapses", 0))
