class_name RTCharacterSelectPresentation
extends RefCounted

const CYAN := Color(0.12, 0.94, 1.0)
const ORANGE := Color(1.0, 0.42, 0.08)


static func draw(game: Node2D, viewport: Vector2) -> void:
	game._draw_holo_background(viewport, game.textures.get("choice_bg"), ORANGE if game.mode != "character_select" else CYAN)
	if game.mode == "character_select":
		_draw_character_cards(game, viewport)
	else:
		_draw_henry_build_step(game, viewport)


static func _draw_character_cards(game: Node2D, viewport: Vector2) -> void:
	game._draw_glitch_title("ESCOLHA QUEM ATRAVESSA", Vector2(viewport.x * 0.5, 66.0), 34, CYAN)
	game._draw_centered("Cada personagem possui sua própria família de poderes.", Vector2(viewport.x * 0.5, 106.0), 15, Color(0.78, 0.92, 1.0))
	var card_size := Vector2(minf(330.0, viewport.x * 0.36), minf(420.0, viewport.y * 0.62))
	var gap := minf(50.0, viewport.x * 0.04)
	var total := card_size.x * 2.0 + gap
	var left := Rect2(Vector2((viewport.x - total) * 0.5, 138.0), card_size)
	var right := Rect2(Vector2(left.end.x + gap, 138.0), card_size)
	game.buttons["character_geovana"] = left
	game.buttons["character_henry"] = right
	game.buttons["character_back"] = Rect2(30.0, viewport.y - 66.0, 170.0, 42.0)
	_draw_character_card(game, left, "GEOVANA", "Manifestações + Espectros", game._frame_texture("player_idle", 160, "player_fire"), game.character_select_index == 0, true, CYAN)
	var unlocked: bool = game._henry_unlocked()
	_draw_character_card(game, right, "HENRY", "Mutações + Efeitos", game._frame_texture("henry_idle", 165, "player_idle"), game.character_select_index == 1, unlocked, ORANGE)
	_draw_button(game, game.buttons["character_back"], "VOLTAR", false, Color(0.55, 0.72, 0.78))


static func _draw_character_card(game: Node2D, rect: Rect2, title: String, subtitle: String, texture: Texture2D, selected: bool, unlocked: bool, accent: Color) -> void:
	var alpha := 0.94 if unlocked else 0.52
	game.draw_rect(rect, Color(0.012, 0.025, 0.035, 0.92), true)
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, alpha), false, 4.0 if selected else 2.0)
	if selected:
		game.draw_rect(rect.grow(7.0), Color(accent.r, accent.g, accent.b, 0.18), false, 2.0)
	var portrait := Rect2(rect.position + Vector2(30.0, 32.0), Vector2(rect.size.x - 60.0, rect.size.y * 0.55))
	if texture != null:
		game.draw_texture_rect(texture, portrait, false, Color(1.0, 1.0, 1.0, alpha))
	game._draw_centered(title, Vector2(rect.get_center().x, rect.end.y - 92.0), 28, Color(0.95, 0.99, 1.0, alpha))
	game._draw_centered(subtitle, Vector2(rect.get_center().x, rect.end.y - 56.0), 15, Color(accent.r, accent.g, accent.b, alpha))
	if not unlocked:
		game.draw_rect(Rect2(rect.position + Vector2(18.0, rect.size.y * 0.44), Vector2(rect.size.x - 36.0, 72.0)), Color(0.02, 0.02, 0.025, 0.88), true)
		game._draw_centered("DERROTE A UMBRA", Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.44 + 28.0), 17, Color(1.0, 0.58, 0.28))
		game._draw_centered("para liberar Henry", Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.44 + 52.0), 13, Color(0.86, 0.88, 0.9))


static func _draw_henry_build_step(game: Node2D, viewport: Vector2) -> void:
	var mutation_step: bool = game.mode == "mutation_select" or game.mode == "mutation_select_mp"
	var item: Dictionary = game.HENRY_MUTATIONS[game.selected_mutation] if mutation_step else game.HENRY_EFFECTS[game.selected_effect]
	var accent: Color = item.get("accent", ORANGE)
	game._draw_glitch_title("MUTAÇÃO" if mutation_step else "EFEITO", Vector2(viewport.x * 0.5, 70.0), 36, accent)
	game._draw_centered("Henry não utiliza Manifestações nem Espectros.", Vector2(viewport.x * 0.5, 112.0), 15, Color(0.8, 0.92, 0.96))
	var panel_size := Vector2(minf(720.0, viewport.x * 0.82), minf(470.0, viewport.y * 0.66))
	var panel := Rect2(viewport * 0.5 - panel_size * 0.5 + Vector2(0.0, 26.0), panel_size)
	game.draw_rect(panel, Color(0.012, 0.025, 0.035, 0.94), true)
	game.draw_rect(panel, Color(accent.r, accent.g, accent.b, 0.9), false, 3.0)
	var texture: Texture2D = game._frame_texture("henry_idle", 165, "player_idle")
	if texture != null:
		game.draw_texture_rect(texture, Rect2(panel.position + Vector2(28.0, 36.0), Vector2(230.0, 290.0)), false)
	game._draw_centered(String(item.get("name", "")), Vector2(panel.position.x + panel.size.x * 0.68, panel.position.y + 80.0), 31, accent)
	game._draw_wrapped_clamped(String(item.get("desc", "")), Rect2(panel.position + Vector2(284.0, 116.0), Vector2(panel.size.x - 320.0, 110.0)), 17, Color(0.88, 0.96, 1.0), 4)
	if mutation_step:
		game._draw_wrapped_clamped("ATK: fagulhas que renovam a queimação\nHAB1: cone de chamas; mais perto, mais dano\nULT: onda de calor de 280 px e Incandescência", Rect2(panel.position + Vector2(284.0, 236.0), Vector2(panel.size.x - 320.0, 120.0)), 15, Color(1.0, 0.78, 0.42), 5)
	else:
		game._draw_wrapped_clamped("Queimação causa ticks proporcionais ao dano por 1,5 s. A ULT renova o efeito e, em alvos já queimando, aumenta dano e cadência por 3 s.", Rect2(panel.position + Vector2(284.0, 230.0), Vector2(panel.size.x - 320.0, 120.0)), 15, Color(1.0, 0.78, 0.42), 5)
	var continue_rect := Rect2(panel.end.x - 250.0, panel.end.y - 66.0, 220.0, 44.0)
	var back_rect := Rect2(panel.position.x + 30.0, panel.end.y - 66.0, 170.0, 44.0)
	game.buttons["henry_continue"] = continue_rect
	game.buttons["henry_back"] = back_rect
	var action_label := "CONTINUAR" if mutation_step else "INICIAR"
	if game.mode.ends_with("_mp") and not mutation_step:
		action_label = "INICIAR" if game._manifest_mp_start_available() else ("CANCELAR PRONTO" if game.mp_local_ready else "PRONTO")
	_draw_button(game, continue_rect, action_label, true, accent)
	_draw_button(game, back_rect, "VOLTAR", false, Color(0.55, 0.72, 0.78))


static func _draw_button(game: Node2D, rect: Rect2, label: String, primary: bool, accent: Color) -> void:
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.23 if primary else 0.08), true)
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.92), false, 2.0)
	game._draw_centered(label, rect.get_center() + Vector2(0.0, 4.0), 17, Color(0.96, 1.0, 1.0))
