class_name RTBaileBeatClock
extends RefCounted

## Relogio de batida do Bailao (Fase 10). E o MAESTRO da fase: inimigos se
## deslocam e atacam na batida, nunca fora dela. A musica da fase deve ser
## produzida neste BPM; o relogio nao depende da faixa tocar (headless/mudo).
##
## Base pesquisada (eletrofunk): ~130 BPM, kick reto + sincope do tamborzao
## (3+3+2 semicolcheias). Virada para 150 BPM (mandelao) no Estagio 2 do boss.
##
## Contagem (indice da batida comeca em 0):
## - compasso de 4: bar_beat() 0..3 — "no 4" = bar_beat() == 3.
## - drop a cada 16: drop_slot() 14 = CONGELA (aviso), 15 = ARRANCADA.
## - passinho: impulsos nas semicolcheias 0, 3 e 6 de cada grupo de 8.

const BPM_BASE := 130.0
const BPM_REMIX := 150.0
const BEATS_PER_BAR := 4
const DROP_EVERY := 16
const FREEZE_SLOT := 14
const DROP_SLOT := 15
const DROP_BOOST := 1.8
## Envelope do impulso (em semicolcheias) e mistura para velocidade media ~1.0:
## media do envelope = PULSE_WINDOW / 8 * (1/3) * 3 = 0.25 -> 0.4 + 2.4 * 0.25 = 1.0.
const PULSE_WINDOW := 2.0
const PULSE_FLOOR := 0.4
const PULSE_GAIN := 2.4
const PULSE_STEPS := [0.0, 3.0, 6.0]

var bpm := BPM_BASE
var beat_pos := 0.0          # batidas decorridas (continuo)
var beat_index := 0          # batida atual (inteiro)
var beat_event := false      # true no quadro em que uma batida nova comeca
var _last_index := -1


func reset(start_bpm: float = BPM_BASE) -> void:
	bpm = start_bpm
	beat_pos = 0.0
	beat_index = 0
	beat_event = false
	_last_index = -1


func update(delta: float) -> void:
	beat_pos += maxf(0.0, delta) * bpm / 60.0
	beat_index = int(floor(beat_pos))
	beat_event = beat_index != _last_index
	_last_index = beat_index


## Replica: adota a posicao da autoridade sem disparar batidas repetidas.
func sync(remote_pos: float, remote_bpm: float) -> void:
	bpm = remote_bpm
	if absf(remote_pos - beat_pos) > 0.25:
		beat_pos = remote_pos
		beat_index = int(floor(beat_pos))
		_last_index = beat_index


func beat_len() -> float:
	return 60.0 / bpm


func bar_len() -> float:
	return beat_len() * BEATS_PER_BAR


## Fracao [0, 1) dentro da batida atual.
func beat_phase() -> float:
	return fposmod(beat_pos, 1.0)


func bar_beat() -> int:
	return posmod(beat_index, BEATS_PER_BAR)


func drop_slot() -> int:
	return posmod(beat_index, DROP_EVERY)


func is_freeze() -> bool:
	return drop_slot() == FREEZE_SLOT


func is_drop() -> bool:
	return drop_slot() == DROP_SLOT


func is_downbeat_event() -> bool:
	return beat_event and bar_beat() == 0


## Semicolcheias desde o ultimo impulso do tamborzao (0 = acabou de bater).
static func since_pulse(pos: float) -> float:
	var s: float = fposmod(pos * 4.0, 8.0)
	var since := s
	for step in PULSE_STEPS:
		if s >= float(step):
			since = s - float(step)
	return since


## Envelope [0, 1] do impulso: 1 no "tum", cai rapido ate o "ta".
static func pulse_envelope(pos: float) -> float:
	var k: float = clampf(1.0 - since_pulse(pos) / PULSE_WINDOW, 0.0, 1.0)
	return k * k


## Multiplicador de velocidade do passinho (media ~1.0). Congela no aviso do
## drop e arranca na batida do drop. phase_offset desencontra cada inimigo um
## pouco (em batidas) para a pista nao parecer um bloco unico.
func step_multiplier(phase_offset: float = 0.0) -> float:
	if is_freeze():
		return 0.0
	var m: float = PULSE_FLOOR + PULSE_GAIN * pulse_envelope(beat_pos + phase_offset)
	if is_drop():
		m *= DROP_BOOST
	return m


## Balanco lateral (passinho de lado) em [-1, 1], 1 ciclo a cada 2 batidas.
func sway(phase_offset: float = 0.0) -> float:
	return sin((beat_pos + phase_offset) * PI)


## Pulso visual da batida [0, 1] (luzes, chao, HUD).
func light_pulse() -> float:
	var p: float = 1.0 - beat_phase()
	return p * p * p
