class_name RTFirstRunHudDefaults
extends RefCounted

## Padrao da primeira instalacao (sem `user://hud_config.save`), copiado da
## configuracao Android montada pelo autor em 2026-11-19. As posicoes foram
## salvas numa tela de referencia 1280x720; cada uma fica presa a borda mais
## proxima (esquerda/direita, cima/baixo) para servir em telas mais largas
## (20:9) ou mais altas (4:3) sem sair do lugar relativo.

const REFERENCE_VIEWPORT := Vector2(1280.0, 720.0)
const EDGE_MARGIN := 24.0

## Centros dos controles de toque (`hud_*_pos`).
const CONTROL_POSITIONS: Dictionary = {
	"hud_joy_pos": Vector2(169.4, 459.0),
	"hud_attack_pos": Vector2(1133.2, 573.2),
	"hud_secondary_pos": Vector2(1187.5, 363.0),
	"hud_dash_pos": Vector2(802.0, 646.0),
	"hud_lacerante_empower_pos": Vector2(934.6, 553.2),
	# Canto superior esquerdo do botao de habilidade e dos paineis.
	"hud_skill_pos": Vector2(963.0, 371.0),
	"hud_aura_panel_pos": Vector2(16.0, 98.0),
	"hud_cards_panel_pos": Vector2(16.0, 152.0),
	"hud_coagulum_pos": Vector2(364.0, 54.0),
}

const CONTROL_SCALES: Dictionary = {
	"hud_joy_scale": 1.0,
	"hud_attack_scale": 2.2,
	"hud_skill_scale": 1.1,
	"hud_secondary_scale": 1.5,
	"hud_dash_scale": 1.0,
	"hud_lacerante_empower_scale": 1.4,
}

## Preferencias de jogo/HUD do mesmo save.
const PREFERENCES: Dictionary = {
	"analog_fixed": false, # analogico dinamico
	"auto_target_priority": "nearest",
	"haptics_enabled": true,
	"interface_text_scale": 1.25,
	"damage_text_scale": 1.0,
	"auto_attack_range_color_index": 2,
	"auto_attack_range_opacity": 0.7,
}


static func anchored(reference_pos: Vector2, viewport: Vector2) -> Vector2:
	var pos: Vector2 = reference_pos
	if reference_pos.x > REFERENCE_VIEWPORT.x * 0.5:
		pos.x = viewport.x - (REFERENCE_VIEWPORT.x - reference_pos.x)
	if reference_pos.y > REFERENCE_VIEWPORT.y * 0.5:
		pos.y = viewport.y - (REFERENCE_VIEWPORT.y - reference_pos.y)
	var limit: Vector2 = (viewport - Vector2(EDGE_MARGIN, EDGE_MARGIN)).max(Vector2(EDGE_MARGIN, EDGE_MARGIN))
	return pos.clamp(Vector2(EDGE_MARGIN, EDGE_MARGIN) * 0.5, limit)


static func apply(core: Object, viewport: Vector2) -> void:
	if viewport.x <= 0.0 or viewport.y <= 0.0:
		viewport = REFERENCE_VIEWPORT
	for key: String in CONTROL_POSITIONS:
		core.set(key, anchored(Vector2(CONTROL_POSITIONS[key]), viewport))
	for key: String in CONTROL_SCALES:
		core.set(key, float(CONTROL_SCALES[key]))
	for key: String in PREFERENCES:
		core.set(key, PREFERENCES[key])
