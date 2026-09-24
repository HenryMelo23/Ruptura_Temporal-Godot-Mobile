extends RefCounted

# Draws through the main CanvasItem; state stays on the host during migration.


static func _draw_startup_thanks(game: Node2D, viewport: Vector2) -> void :
	if game.startup_thanks_done:
		return

	var alpha = 1.0
	if game.startup_thanks_fading:
		alpha = 1.0 - clampf(game.startup_thanks_timer / maxf(0.01, game.STARTUP_THANKS_FADE_TIME), 0.0, 1.0)

	var texture: Texture2D = null
	if game.startup_thanks_teaser_available:
		texture = game._get_startup_thanks_frame_texture(game.startup_thanks_frame_index)
	else:
		texture = game.textures.get("startup_thanks", null)
	if texture != null:
		var texture_size = texture.get_size()
		if texture_size.x > 0.0 and texture_size.y > 0.0:
			var scale = maxf(viewport.x / texture_size.x, viewport.y / texture_size.y)
			var draw_size = texture_size * scale
			var image_rect = Rect2((viewport - draw_size) * 0.5, draw_size)
			game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, alpha), true)
			game.draw_texture_rect(texture, image_rect, false, Color(1.0, 1.0, 1.0, alpha))

	if game.startup_thanks_hold_timer > 0.0 and not game.startup_thanks_fading:
		var ratio = clampf(game.startup_thanks_hold_timer / game.STARTUP_THANKS_SKIP_HOLD_TIME, 0.0, 1.0)
		var center = game.startup_thanks_hold_pos
		if center == Vector2.ZERO or center.x < 0.0 or center.y < 0.0:
			center = viewport * 0.5

		var radius = 56.0
		var width = 8.0

		game.draw_circle(center, radius + 18.0, Color(0.0, 0.0, 0.0, 0.45 * alpha))
		game.draw_arc(center, radius, 0.0, TAU, 64, Color(0.0, 0.0, 0.0, 0.72 * alpha), width + 6.0, true)
		game.draw_arc(center, radius, 0.0, TAU, 48, Color(0.1, 0.15, 0.25, 0.5 * alpha), width, true)
		var start_angle = -PI * 0.5
		var end_angle = start_angle + ratio * TAU
		if ratio > 0.01:
			game.draw_arc(center, radius, start_angle, end_angle, 64, Color(0.0, 0.85, 1.0, 0.95 * alpha), width + 2.0, true)
			game.draw_arc(center, radius, start_angle, end_angle, 48, Color(1.0, 1.0, 1.0, 0.9 * alpha), width * 0.5, true)

		game.draw_circle(center, radius * 0.35, Color(0.0, 0.85, 1.0, 0.15 * ratio * alpha))

		if game.font != null:
			var text = "SEGURE ESC PARA PULAR" if game._uses_desktop_ui() else "SEGURE PARA PULAR"
			var font_size = 18
			var text_size = game.font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos = Vector2(center.x - text_size.x * 0.5, center.y + radius + 22.0)
			game.draw_string_outline(game.font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0.0, 0.0, 0.0, 0.8 * alpha))
			game.draw_string(game.font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.9, 0.95, 1.0, 0.9 * alpha))


static func _draw_tutorial_overlay(game: Node2D, viewport: Vector2, camera: Vector2) -> void:
	if not game._tutorial_active():
		return
	var t: float = Time.get_ticks_msec() * 0.001
	if game.tutorial_state == game.TUTORIAL_STATE_OFFER:
		game._draw_tutorial_offer(viewport, t)
		return
	if game._tutorial_practical_state():
		game._draw_tutorial_practical_step(viewport, camera, t)
		return
	game._draw_tutorial_story_step(viewport, t)


static func _draw_tutorial_offer(game: Node2D, viewport: Vector2, t: float) -> void:
	var panel: Rect2 = game._tutorial_panel_rect(viewport)
	var rects: Dictionary = game._tutorial_prompt_rects(viewport)
	var body_rect = Rect2(panel.position + Vector2(42.0, 82.0), Vector2(panel.size.x - 84.0, maxf(72.0, panel.size.y - 166.0)))
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.48), true)
	game._draw_menu_grid(viewport, Color(0.0, 1.0, 0.82, 0.09), 42.0)
	game._draw_holo_panel(panel, Color(0.0, 1.0, 0.82), true, 0.84)
	game._draw_glitch_title("TREINAMENTO DE RUPTURA", panel.position + Vector2(panel.size.x * 0.5, 48.0), 28, Color(0.0, 1.0, 0.82))
	game._draw_wrapped("Antes da partida comecar, Geovana pode sincronizar um treinamento curto. Ele ensina disparo, habilidade, segunda habilidade e dash sem liberar a invasao completa.", body_rect, 18, Color(0.88, 0.96, 1.0, 0.96))
	var pulse: float = 0.5 + sin(t * 5.0) * 0.5
	game.draw_line(panel.position + Vector2(34.0, panel.size.y - 78.0), panel.position + Vector2(panel.size.x - 34.0, panel.size.y - 78.0), Color(1.0, 0.12, 0.72, 0.2 + pulse * 0.22), 2.0)
	game._draw_big_button(Rect2(rects["tutorial_yes"]), "JOGAR TUTORIAL", Color(0.0, 0.42, 0.42, 0.75), Color(0.0, 1.0, 0.82), game.tutorial_prompt_selected == 0)
	game._draw_big_button(Rect2(rects["tutorial_no"]), "INICIAR RUN", Color(0.22, 0.06, 0.11, 0.72), Color(1.0, 0.18, 0.48), game.tutorial_prompt_selected == 1)


static func _draw_tutorial_story_step(game: Node2D, viewport: Vector2, t: float) -> void:
	var panel: Rect2 = game._tutorial_panel_rect(viewport)
	var rects: Dictionary = game._tutorial_prompt_rects(viewport)
	var data: Dictionary = Dictionary(game.TUTORIAL_STEP_TEXTS.get(game.tutorial_state, {}))
	var title: String = String(data.get("title", "RUPTURA"))
	var body: String = String(data.get("body", ""))
	var hint: String = String(data.get("hint", ""))
	var body_rect = Rect2(panel.position + Vector2(44.0, 86.0), Vector2(panel.size.x - 88.0, maxf(74.0, panel.size.y - 182.0)))
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.44), true)
	game._draw_menu_grid(viewport, Color(0.36, 0.0, 0.8, 0.085), 46.0)
	game._draw_holo_panel(panel, Color(0.76, 0.18, 1.0), true, 0.86)
	var pulse: float = 0.55 + sin(t * 4.8) * 0.45
	game.draw_arc(panel.get_center(), minf(panel.size.x, panel.size.y) * 0.46 + pulse * 7.0, t, t + PI * 1.4, 64, Color(0.0, 1.0, 0.82, 0.2), 2.0, true)
	game._draw_centered(title, panel.position + Vector2(panel.size.x * 0.5, 48.0), 26, Color(0.94, 0.98, 1.0, 0.98))
	game._draw_wrapped(body, body_rect, 18, Color(0.88, 0.94, 1.0, 0.96))
	game._draw_centered(hint, panel.position + Vector2(panel.size.x * 0.5, panel.size.y - 82.0), 15, Color(0.0, 1.0, 0.82, 0.86))
	game._draw_tutorial_context_button_hint(t)
	game._draw_big_button(Rect2(rects["tutorial_continue"]), "CONTINUAR", Color(0.02, 0.34, 0.4, 0.75), Color(0.0, 1.0, 0.82), true)


static func _draw_tutorial_practical_step(game: Node2D, viewport: Vector2, camera: Vector2, t: float) -> void:
	var panel: Rect2 = game._tutorial_compact_panel_rect(viewport)
	var data: Dictionary = Dictionary(game.TUTORIAL_STEP_TEXTS.get(game.tutorial_state, {}))
	var title: String = String(data.get("title", "TREINO"))
	var body: String = String(data.get("body", ""))
	var hint: String = String(data.get("hint", ""))
	var body_rect = Rect2(panel.position + Vector2(28.0, 52.0), Vector2(panel.size.x - 56.0, maxf(40.0, panel.size.y - 88.0)))
	game._draw_tutorial_target_markers(camera, t)
	game._draw_tutorial_control_highlight(t)
	game._draw_holo_panel(panel, Color(0.0, 1.0, 0.82), true, 0.78)
	game._draw_centered(title, panel.position + Vector2(panel.size.x * 0.5, 32.0), 23, Color(0.96, 0.98, 1.0, 0.98))
	game._draw_wrapped(body, body_rect, 15, Color(0.86, 0.94, 1.0, 0.93))
	game._draw_centered(hint, panel.position + Vector2(panel.size.x * 0.5, panel.size.y - 22.0), 15, Color(1.0, 0.84, 0.22, 0.95))


static func _draw_tutorial_target_markers(game: Node2D, camera: Vector2, t: float) -> void:
	if game.tutorial_state == game.TUTORIAL_STATE_DASH:
		var player_screen: Vector2 = game.player_pos - camera
		var danger_r: float = 84.0 + sin(t * 6.0) * 7.0
		game.draw_circle(player_screen, danger_r, Color(1.0, 0.12, 0.16, 0.07))
		game.draw_arc(player_screen, danger_r, 0.0, TAU, 58, Color(1.0, 0.22, 0.24, 0.76), 3.0, true)
		game.draw_arc(player_screen, danger_r + 22.0, -t * 2.0, -t * 2.0 + PI * 1.2, 50, Color(0.0, 1.0, 0.82, 0.58), 2.0, true)
		return
	for enemy in game.enemies:
		if not bool(enemy.get("tutorial", false)) or String(enemy.get("tutorial_stage", "")) != game.tutorial_state:
			continue
		var pos: Vector2 = Vector2(enemy.get("pos", game.player_pos)) - camera
		var radius: float = 44.0 + sin(t * 7.0 + float(enemy.get("uid", 0))) * 5.0
		game.draw_circle(pos, radius, Color(1.0, 0.2, 0.62, 0.08))
		game.draw_arc(pos, radius, t * 2.4, t * 2.4 + PI * 1.55, 48, Color(1.0, 0.18, 0.72, 0.82), 3.0, true)
		game.draw_arc(pos, radius * 0.72, -t * 3.1, -t * 3.1 + PI * 1.25, 42, Color(0.0, 1.0, 0.82, 0.76), 2.0, true)
		game._draw_centered("ALVO", pos + Vector2(0.0, -radius - 14.0), 13, Color(1.0, 0.9, 0.3, 0.95))


static func _draw_tutorial_context_button_hint(game: Node2D, t: float) -> void:
	var action_key = ""
	var label = ""
	match game.tutorial_state:
		game.TUTORIAL_STATE_SHOP:
			action_key = "shop_manual"
			label = "LOJA"
		game.TUTORIAL_STATE_BOSS_CALL:
			action_key = "boss"
			label = "BOSS"
	if action_key == "" or not game.buttons.has(action_key):
		return
	var rect: Rect2 = Rect2(game.buttons[action_key])
	var pulse: float = 0.5 + sin(t * 6.2) * 0.5
	var glow: Rect2 = rect.grow(12.0 + pulse * 8.0)
	game.draw_rect(glow, Color(1.0, 0.74, 0.16, 0.08 + pulse * 0.05), true)
	game.draw_rect(glow, Color(1.0, 0.74, 0.16, 0.82), false, 3.0)
	var arrow_tip: Vector2 = rect.get_center()
	var arrow_from: Vector2 = arrow_tip + Vector2(-92.0, -70.0)
	if arrow_tip.x < game.get_viewport_rect().size.x * 0.5:
		arrow_from = arrow_tip + Vector2(92.0, -70.0)
	game.draw_line(arrow_from, arrow_tip, Color(1.0, 0.82, 0.22, 0.88), 4.0)
	var dir: Vector2 = (arrow_tip - arrow_from).normalized()
	var side: Vector2 = dir.orthogonal()
	var head: PackedVector2Array = PackedVector2Array([arrow_tip, arrow_tip - dir * 22.0 + side * 10.0, arrow_tip - dir * 22.0 - side * 10.0])
	game.draw_colored_polygon(head, Color(1.0, 0.82, 0.22, 0.9))
	game._draw_centered(label, arrow_from + Vector2(0.0, -14.0), 16, Color(1.0, 0.88, 0.3, 0.96))


static func _draw_dance_wheel(game: Node2D, viewport: Vector2) -> void:
	if not game.dance_wheel_active:
		return
	var center: Vector2 = game.dance_wheel_start_pos
	var radius: float = 85.0
	game.draw_circle(center, radius, Color(0.08, 0.04, 0.12, 0.72))
	game.draw_arc(center, radius, 0.0, TAU, 48, Color(0.9, 0.35, 1.0, 0.85), 3.0)
	game.draw_arc(center, radius * 0.4, 0.0, TAU, 32, Color(0.7, 0.4, 0.9, 0.5), 1.5)
	var emotes: Array = ["DANCA 💃", "FOGO 🔥", "VITORIA 🏆", "ESPECIAL ✨"]
	for i in range(emotes.size()):
		var angle: float = float(i) * (TAU / float(emotes.size())) - (PI * 0.5)
		var item_pos: Vector2 = center + Vector2.from_angle(angle) * (radius * 0.65)
		game.draw_circle(item_pos, 16.0, Color(0.3, 0.1, 0.4, 0.8))
		game.draw_arc(item_pos, 16.0, 0.0, TAU, 24, Color(0.95, 0.5, 1.0, 0.9), 1.5)
		game._draw_centered(emotes[i], item_pos, 11, Color.WHITE)


static func _draw_custom_mouse_cursor(game: Node2D, _viewport: Vector2) -> void :
	var pos = game.get_viewport().get_mouse_position()
	var red_accent = Color(1.0, 0.12, 0.18, 1.0)
	var bright_center = Color(1.0, 0.92, 0.92, 1.0)
	var outline_color = Color(0.0, 0.0, 0.0, 0.85)

	game.draw_arc(pos, 14.0, 0.0, TAU, 32, outline_color, 2.5, true)
	game.draw_arc(pos, 14.0, 0.0, TAU, 32, red_accent, 1.2, true)

	var gap = 5.0
	var tick_len = 10.0
	var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

	for d in dirs:
		var p1 = pos + d * gap
		var p2 = pos + d * (gap + tick_len)
		game.draw_line(p1, p2, outline_color, 3.0, true)
		game.draw_line(p1, p2, red_accent, 1.6, true)

	game.draw_circle(pos, 3.5, outline_color)
	game.draw_circle(pos, 2.2, red_accent)
	game.draw_circle(pos, 1.0, bright_center)


static func _draw_manifest_evolution_choice(game: Node2D, viewport: Vector2) -> void :
	game.manifest_evolution_focus_timer += 0.016
	var accent = game._manifestation_color()
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.46), true)
	var panel_w: float = min(980.0, viewport.x * 0.88)
	var panel_h: float = min(520.0, viewport.y * 0.72)
	var panel = Rect2(viewport * 0.5 - Vector2(panel_w, panel_h) * 0.5, Vector2(panel_w, panel_h))
	game._draw_holo_panel(panel, accent, true, 0.88)
	game._draw_glitch_title("EVOLUCAO DO ARAUTO", Vector2(panel.get_center().x, panel.position.y + 54.0), 30, accent)
	game._draw_centered(game._manifestation_display_name(game.manifestation_key), Vector2(panel.get_center().x, panel.position.y + 92.0), 17, Color(0.86, 0.96, 1.0, 0.9))
	var gap = 18.0
	var card_w = (panel.size.x - 72.0 - gap * 2.0) / 3.0
	var card_h = panel.size.y - 164.0
	var start_x = panel.position.x + 36.0
	var start_y = panel.position.y + 126.0
	for i in range(game.manifest_evolution_options.size()):
		var entry: Dictionary = game.manifest_evolution_options[i]
		var rect = Rect2(start_x + i * (card_w + gap), start_y, card_w, card_h)
		game.buttons["manifest_evolution_%d" % i] = rect
		var selected = i == game.manifest_evolution_selected
		var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008 + i)
		var border = Color(1.0, 1.0, 1.0, 0.92) if selected else accent
		var fill = Color(accent.r * 0.12, accent.g * 0.12, accent.b * 0.12, 0.88)
		game.draw_rect(rect, fill, true)
		game.draw_rect(rect.grow(4.0 if selected else 2.0), Color(border.r, border.g, border.b, (0.72 + pulse * 0.18) if selected else 0.42), false, 2.4 if selected else 1.4)
		game.draw_circle(rect.get_center() + Vector2(0, - card_h * 0.24), 34.0 + pulse * 4.0, Color(accent.r, accent.g, accent.b, 0.16))
		game._draw_centered(String(entry.get("name", "")), Vector2(rect.get_center().x, rect.position.y + 72.0), 18, Color.WHITE)
		game._draw_centered(String(entry.get("family", "")).to_upper(), Vector2(rect.get_center().x, rect.position.y + 104.0), 12, accent)
		game._draw_wrapped(String(entry.get("summary", "")), Rect2(rect.position.x + 18.0, rect.position.y + 132.0, rect.size.x - 36.0, rect.size.y - 176.0), 14, Color(0.84, 0.92, 1.0, 0.88))
		game._draw_centered("ESCOLHER", Vector2(rect.get_center().x, rect.end.y - 28.0), 15, Color(1.0, 0.92, 0.52, 0.95) if selected else Color(0.78, 0.86, 0.9, 0.75))


static func _draw_nickname_setup(game: Node2D, viewport: Vector2) -> void :
	game._draw_holo_background(viewport, game.textures.get("choice_bg", null), Color(0.0, 1.0, 0.82))
	game._sync_nickname_input_rect(viewport)
	var panel = game._nickname_panel_rect(viewport)
	game._draw_holo_panel(panel, Color(0.0, 1.0, 0.82), true, 0.82)
	game._draw_glitch_title("IDENTIDADE", Vector2(panel.get_center().x, panel.position.y + 58.0), 34, Color(0.0, 1.0, 0.82))
	game._draw_centered("Escolha o nick usado no placar das runs.", Vector2(panel.get_center().x, panel.position.y + 104.0), 16, Color(0.82, 0.95, 1.0, 0.92))
	var input_rect = Rect2(panel.position.x + 44.0, panel.position.y + panel.size.y * 0.44, panel.size.x - 88.0, 48.0)
	game.draw_rect(input_rect.grow(5.0), Color(0.0, 0.0, 0.0, 0.64), true)
	game.draw_rect(input_rect.grow(5.0), Color(0.0, 1.0, 0.82, 0.74), false, 2)
	var confirm = Rect2(panel.get_center().x - 126.0, panel.end.y - 76.0, 252.0, 52.0)
	game.buttons["nick_confirm"] = confirm
	game._draw_big_button(confirm, "CONFIRMAR", Color(0.02, 0.14, 0.13, 0.92), Color(0.0, 1.0, 0.82))
	if game.nickname_error != "":
		game._draw_centered(game.nickname_error, Vector2(panel.get_center().x, confirm.position.y - 18.0), 13, Color(1.0, 0.28, 0.28))
	else:
		game._draw_centered("Pode trocar depois limpando o perfil salvo.", Vector2(panel.get_center().x, confirm.position.y - 18.0), 12, Color(0.68, 0.8, 0.86, 0.78))


static func _draw_menu(game: Node2D, viewport: Vector2) -> void :
	var msec = Time.get_ticks_msec()
	var cycle_pos = msec % 6950
	var current_bg: Texture2D = null
	if cycle_pos < 5000:
		current_bg = game.textures["menu_panels"][0]
	else:
		var trans_pos = int((cycle_pos - 5000) / 150)
		var sequence = [0, 3, 1, 3, 4, 2, 1, 2, 3, 4, 2, 1, 4]
		var idx = clamp(trans_pos, 0, sequence.size() - 1)
		current_bg = game.textures["menu_panels"][sequence[idx]]

	var accent = Color(0.36, 0.88, 0.87)
	game._draw_texture_cover(current_bg, Rect2(Vector2.ZERO, viewport))
	game._draw_menu_scrim(viewport, false)
	game.menu_buttons = game._menu_rects(viewport)
	game.menu_selected = clampi(game.menu_selected, 0, max(0, game._menu_option_count() - 1))
	var x: float = viewport.x * 0.06
	var title_size = int(clampf(viewport.y * 0.085, 38.0, 68.0))
	var title_y: float = viewport.y * 0.115
	game._draw_ui_text("D37  /  FRATURA TEMPORAL", Vector2(x, title_y - 28.0), 11, accent)
	var title_width: float = game.menu_title_font.get_string_size("TEMPORAL", HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	game._draw_centered_with_font(game.menu_title_font, "RUPTURA", Vector2(x + title_width * 0.5, title_y + title_size * 0.3), title_size, Color(0.95, 0.94, 0.88))
	game._draw_centered_with_font(game.menu_title_font, "TEMPORAL", Vector2(x + title_width * 0.5, title_y + title_size * 1.4), title_size, Color(0.95, 0.94, 0.88))
	game._draw_ui_text("O tempo se rompe. Sua jornada continua.", Vector2(x, title_y + title_size * 2.18), 13, Color(0.67, 0.76, 0.78))
	if game.menu_buttons.has("continue"):
		game._draw_hub_button(game.menu_buttons["continue"], "Continuar jornada", game._interrupted_run_detail_text(), accent, game.menu_selected == game._menu_index_for("continue"), true, "continue")
	game._draw_hub_button(game.menu_buttons["start"], "Nova jornada" if game.interrupted_run_available else "Iniciar jornada", "", accent, game.menu_selected == game._menu_index_for("start"), not game.interrupted_run_available, "start")
	if game.menu_buttons.has("multiplayer"):
		game._draw_hub_button(game.menu_buttons["multiplayer"], "Modo online", "", accent, game.menu_selected == game._menu_index_for("multiplayer"), false, "multiplayer")
	game._draw_hub_button(game.menu_buttons["catalog"], "Catálogo temporal", "", accent, game.menu_selected == game._menu_index_for("catalog"), false, "catalog")
	game._draw_hub_button(game.menu_buttons["settings"], "Configurações", "", accent, game.menu_selected == game._menu_index_for("settings"), false, "settings")
	if game.QA_STREAMING_FEATURE_ENABLED and game.qa_streaming_unlocked and game.menu_buttons.has("stream"):
		game._draw_hub_button(game.menu_buttons["stream"], "Encerrar ao vivo" if game._qa_streaming_is_active() else "Transmitir partida", game._qa_stream_menu_subtitle(), accent, game.menu_selected == game._menu_index_for("stream"), false, "stream")
	game._draw_hub_button(game.menu_buttons["exit"], "Sair do jogo", "", Color(0.88, 0.53, 0.44), game.menu_selected == game._menu_index_for("exit"), false, "exit")
	var footer_y: float = viewport.y - 22.0
	game.draw_line(Vector2(x, footer_y - 20.0), Vector2(viewport.x - x, footer_y - 20.0), Color(0.7, 0.84, 0.83, 0.18), 1.0)
	game._draw_ui_text(game.player_nickname if game.player_nickname != "" else "RUPTURA TEMPORAL", Vector2(x, footer_y), 11, Color(0.67, 0.76, 0.78))
	game._draw_ui_text("v" + game.GAME_VERSION, Vector2(viewport.x - x - 65.0, footer_y), 11, Color(0.67, 0.76, 0.78))
	if game.content_update_status == "updated":
		game._draw_centered("Conteudo atualizado. Feche e reabra o jogo para aplicar.", Vector2(viewport.x * 0.5, footer_y), 11, Color(0.4, 1.0, 0.8))


static func _draw_ui_text(game: Node2D, text: String, draw_pos: Vector2, size: int, color: Color, width: float = -1.0) -> void:
	var fitted: int = size
	if width > 0.0:
		while fitted > 10 and game.menu_ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > width:
			fitted -= 1
	var shown: String = text
	if width > 0.0 and game.menu_ui_font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > width:
		while shown.length() > 1 and game.menu_ui_font.get_string_size(shown + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > width:
			shown = shown.left(shown.length() - 1)
		shown += "…"
	game.draw_string(game.menu_ui_font, draw_pos, shown, HORIZONTAL_ALIGNMENT_LEFT, width, fitted, color)


static func _draw_ui_wrap(game: Node2D, text: String, rect: Rect2, size: int, color: Color, lines: int = 3) -> void:
	var words = text.split(" ")
	var line = ""
	var y: float = rect.position.y + size
	var count: int = 0
	for word in words:
		var next: String = word if line.is_empty() else line + " " + word
		if game.menu_ui_font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x and not line.is_empty():
			game._draw_ui_text(line, Vector2(rect.position.x, y), size, color, rect.size.x)
			count += 1
			y += size + 5.0
			line = word
			if count >= lines or y > rect.end.y:
				return
		else:
			line = next
	game._draw_ui_text(line, Vector2(rect.position.x, y), size, color, rect.size.x)


static func _draw_app_update_popup(game: Node2D, viewport: Vector2) -> void :
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.76), true)
	var panel = game._app_update_panel_rect(viewport)
	var accent = Color(0.0, 1.0, 0.82)
	game._draw_holo_panel(panel, accent, true, 0.94)
	var version = String(game.app_update_manifest.get("version", "NOVA"))
	game._draw_glitch_title("ATUALIZACAO DISPONIVEL", Vector2(panel.get_center().x, panel.position.y + 48.0), 27, accent)
	game._draw_centered("v%s  ->  v%s" % [game.GAME_VERSION, version], Vector2(panel.get_center().x, panel.position.y + 82.0), 17, Color(0.82, 0.96, 1.0))
	var summary_rect = Rect2(panel.position.x + 36.0, panel.position.y + 104.0, panel.size.x - 72.0, 62.0)
	game.draw_rect(summary_rect, Color(0.0, 0.06, 0.08, 0.74), true)
	game.draw_rect(summary_rect, Color(accent.r, accent.g, accent.b, 0.38), false, 1.5)
	var summary = "%s seguro | %s | instalador antigo sera limpo automaticamente" % [game._app_update_file_label(), game._format_download_size(int(game.app_update_manifest.get("size", 0)))]
	game._draw_wrapped_clamped(summary, summary_rect.grow(-14.0), 14, Color(0.86, 0.96, 1.0, 0.92), 2)
	var content_rect = Rect2(panel.position.x + 42.0, panel.position.y + 184.0, panel.size.x - 84.0, panel.size.y - 282.0)
	var status_text = ""
	match game.app_update_status:
		"available":
			var notes: Array = game.app_update_manifest.get("notes", [])
			status_text = "Esta versao substitui a anterior e preserva seus saves locais."
			if not notes.is_empty():
				status_text += "\n\nPrincipais mudancas:"
				var limit: int = mini(7, notes.size())
				for i in range(limit):
					status_text += "\n- " + String(notes[i])
		"downloading":
			var downloaded = game.app_update_download_request.get_downloaded_bytes() if game.app_update_download_request != null else 0
			var total = int(game.app_update_manifest.get("size", 0))
			var progress = clampf(float(downloaded) / float(maxi(1, total)), 0.0, 1.0)
			status_text = "Baixando %s direto do servidor.\nMantenha o jogo aberto ate a verificacao terminar.\n%s de %s" % [game._app_update_file_label(), game._format_download_size(downloaded), game._format_download_size(total)]
			var bar = Rect2(content_rect.position.x, content_rect.position.y + 96.0, content_rect.size.x, 20.0)
			game.draw_rect(bar, Color(0.01, 0.04, 0.07, 0.92), true)
			game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color(0.0, 0.88, 0.72, 0.92), true)
			game.draw_rect(bar, Color(0.42, 1.0, 0.9, 0.7), false, 1.5)
			game._draw_centered("%d%%" % int(round(progress * 100.0)), bar.get_center() + Vector2(0, 5), 12, Color.WHITE)
		"verifying":
			status_text = "Download concluido.\nVerificando tamanho e assinatura SHA-256 antes de abrir o instalador."
		"permission_required":
			status_text = "O Android pediu permissao para instalar atualizacoes deste app.\nAutorize o Ruptura Temporal, volte ao jogo e toque em CONTINUAR INSTALACAO."
		"installer_open":
			status_text = "APK validado. O instalador do Android foi aberto para concluir a atualizacao." if OS.get_name() == "Android" else "EXE validado. A nova versao foi aberta; feche esta janela antiga quando terminar."
		"browser_fallback":
			status_text = "Este aparelho abriu o download seguro no navegador porque o instalador integrado nao estava disponivel."
		"validated":
			status_text = "%s baixado e validado com sucesso." % game._app_update_file_label()
		"error":
			status_text = game.app_update_error
		_:
			status_text = "Preparando atualizacao..."
	game._draw_wrapped_clamped(status_text, content_rect, 15, Color(0.86, 0.94, 0.98, 0.94), 10)
	var rects = game._app_update_button_rects(viewport)
	game.buttons.erase("app_update_primary")
	game.buttons.erase("app_update_later")
	if game.app_update_status == "verifying":
		game._draw_centered("VERIFICANDO...", Vector2(panel.get_center().x, panel.end.y - 44.0), 16, accent)
		return
	if rects.is_empty():
		return
	game.buttons["app_update_primary"] = rects[0]
	var primary_label = "ATUALIZAR AGORA"
	match game.app_update_status:
		"downloading": primary_label = "CANCELAR DOWNLOAD"
		"permission_required": primary_label = "CONTINUAR INSTALACAO"
		"error": primary_label = "TENTAR NOVAMENTE"
		"installer_open", "browser_fallback", "validated": primary_label = "FECHAR"
	game._draw_big_button(rects[0], primary_label, Color(0.02, 0.16, 0.14, 0.96), accent)
	if game.app_update_selected == 0:
		game.draw_rect(rects[0].grow(5.0), Color(0.72, 1.0, 0.94, 0.92), false, 2.5)
	if rects.size() > 1:
		game.buttons["app_update_later"] = rects[1]
		game._draw_big_button(rects[1], "DEPOIS", Color(0.12, 0.06, 0.1, 0.96), Color(1.0, 0.32, 0.56))
		if game.app_update_selected == 1:
			game.draw_rect(rects[1].grow(5.0), Color(1.0, 0.76, 0.86, 0.92), false, 2.5)


static func _draw_menu_button(game: Node2D, rect: Rect2, label: String, is_selected: bool) -> void :
	if is_selected:
		var bg_color = Color(0.0, 0.7, 0.78, 0.25)
		game.draw_rect(rect, bg_color, true)
		var border_color = Color(0.0, 1.0, 0.9, 1.0)
		game.draw_rect(rect, border_color, false, 2)
		var bar_rect = Rect2(rect.position, Vector2(6.0, rect.size.y))
		game.draw_rect(bar_rect, Color(0.0, 1.0, 0.9), true)
		game._draw_centered(label, rect.get_center() + Vector2(0, 6), 16, Color.WHITE)
	else:
		var bg_color = Color(0.06, 0.06, 0.1, 0.62)
		game.draw_rect(rect, bg_color, true)
		var border_color = Color(0.39, 0.39, 0.58, 0.18)
		game.draw_rect(rect, border_color, false, 1)
		game._draw_centered(label, rect.get_center() + Vector2(0, 6), 16, Color(0.78, 0.78, 0.86))


static func _draw_hub_button(game: Node2D, rect: Rect2, label: String, detail: String, accent: Color, is_selected: bool, primary: = false, button_type: = "") -> void:
	var weight: float = game._menu_focus_weight(button_type, is_selected)
	var entrance: float = 1.0 - pow(1.0 - clampf(game.menu_page_age / 0.28, 0.0, 1.0), 3.0)
	var local_rect = Rect2(rect.position + Vector2((1.0 - entrance) * -12.0, 0.0), rect.size)
	var pressed: bool = rect.has_point(game.get_global_mouse_position()) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var fill = Color(0.024, 0.045, 0.052, 0.78).lerp(Color(0.1, 0.22, 0.23, 0.96), weight)
	if primary:
		fill = Color(0.19, 0.48, 0.48, 0.96).lerp(Color(0.31, 0.68, 0.66, 0.98), weight)
	if pressed:
		fill = fill.darkened(0.2)
	game.draw_rect(local_rect, fill)
	game.draw_line(local_rect.position, Vector2(local_rect.end.x, local_rect.position.y), Color(accent, 0.18 + weight * 0.5), 1.0)
	game.draw_rect(Rect2(local_rect.position, Vector2(3.0, local_rect.size.y)), Color(accent, 0.25 + weight * 0.75))
	var size = 19 if primary else 16
	var text_color = Color(0.97, 0.97, 0.91) if not primary else Color(0.025, 0.07, 0.075)
	var baseline: float = local_rect.get_center().y + 6.0 if detail.is_empty() else local_rect.get_center().y - 2.0
	game._draw_ui_text(label, Vector2(local_rect.position.x + 22.0 + weight * 5.0, baseline), size, text_color, local_rect.size.x - 68.0)
	if not detail.is_empty():
		game._draw_ui_text(detail, Vector2(local_rect.position.x + 27.0, baseline + 16.0), 10, text_color, local_rect.size.x - 65.0)
	var arrow = Vector2(local_rect.end.x - 24.0 + weight * 3.0, local_rect.get_center().y)
	game.draw_polyline(PackedVector2Array([arrow + Vector2(-4, -5), arrow + Vector2(1, 0), arrow + Vector2(-4, 5)]), Color(text_color, 0.45 + weight * 0.55), 1.6, true)


static func _draw_hub_manifest_card(game: Node2D, rect: Rect2) -> void :
	var item: Dictionary = game.MANIFESTATIONS[game.selected_manifestation]
	var color: Color = item["color"]
	game._draw_holo_panel(rect, color, false, 0.5)
	var icon_rect = Rect2(rect.position + Vector2(12.0, 10.0), Vector2(rect.size.y - 20.0, rect.size.y - 20.0))
	game._draw_texture_contain(game.textures.get("manifestation_" + item["key"]), icon_rect, Color.WHITE)
	var text_x = icon_rect.end.x + 14.0
	game.draw_string(game.font, Vector2(text_x, rect.position.y + rect.size.y * 0.36), String(item["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
	game._draw_wrapped(String(item["desc"]), Rect2(Vector2(text_x, rect.position.y + rect.size.y * 0.48), Vector2(rect.end.x - text_x - 12.0, rect.size.y * 0.44)), 12, Color(0.8, 0.9, 0.92, 0.86))


static func _draw_settings(game: Node2D, viewport: Vector2) -> void :
	game._draw_settings_shell(viewport, "Configurações", "Seu jeito de atravessar a ruptura.")
	game.settings_buttons = game._settings_rects(viewport)
	game.settings_selected = clampi(game.settings_selected, 0, max(0, game._settings_option_count() - 1))
	var keys: Array = game._settings_option_keys()
	for key in keys:
		var key_s: String = String(key)
		if not game.settings_buttons.has(key_s):
			continue
		game._draw_settings_card(game.settings_buttons[key_s], game._settings_option_title(key_s), game._settings_option_summary(key_s), game._settings_option_color(key_s), game.settings_selected == game._settings_index_for(key_s))
	game._draw_settings_info_panel(viewport, game._settings_selected_key())


static func _draw_gamepad_settings(game: Node2D, viewport: Vector2) -> void :
	game._draw_settings_shell(viewport, "Controle", "Selecione uma ação para mapear o controle conectado.")
	game.settings_buttons = game._gamepad_settings_rects(viewport)
	var actions = game._gamepad_action_order()
	for i in range(actions.size()):
		var action = actions[i]
		var value = "Pressione..." if game.gamepad_mapping_action == action else game._format_binding_name(game.gamepad_bindings.get(action, -1))
		game._draw_gameplay_preference(game.settings_buttons[action], game._gamepad_action_title(action), game._gamepad_action_subtitle(action), value, game._gamepad_action_color(action), game.settings_selected == i)
	game._draw_settings_card(game.settings_buttons["back"], "VOLTAR", "retornar", Color(1.0, 0.26, 0.36), game.settings_selected == actions.size())


static func _draw_keyboard_settings(game: Node2D, viewport: Vector2) -> void :
	game._draw_settings_shell(viewport, "Teclado e mouse", "Selecione uma ação para remapear. Backspace / Delete remove a associação.")
	game.settings_buttons = game._keyboard_settings_rects(viewport)
	var actions = game._keyboard_action_order()
	for i in range(actions.size()):
		var action = actions[i]
		var value = "PRESSIONE TECLA/MOUSE..." if game.keyboard_mapping_action == action else game._format_key_binding_name(game.keyboard_bindings.get(action, game.INPUT_BIND_NONE))
		game._draw_gameplay_preference(game.settings_buttons[action], game._keyboard_action_title(action), game._keyboard_action_subtitle(action), value, game._keyboard_action_color(action), game.settings_selected == i)
	game._draw_settings_card(game.settings_buttons["reset"], "RESTAURAR PADRAO", "restaurar os atalhos originais", Color(0.58, 0.82, 1.0), game.settings_selected == actions.size())
	game._draw_settings_card(game.settings_buttons["back"], "VOLTAR", "retornar", Color(1.0, 0.26, 0.36), game.settings_selected == actions.size() + 1)


static func _draw_gameplay_settings(game: Node2D, viewport: Vector2) -> void :
	game._draw_settings_shell(viewport, "Jogabilidade", "Ajuste os comandos, a mira e a leitura do combate.")
	game.settings_buttons = game._gameplay_preferences_rects(viewport)
	var analog_accent = Color(0.0, 1.0, 0.82) if game.analog_fixed else Color(1.0, 0.74, 0.22)
	game._draw_gameplay_preference(game.settings_buttons["analog"], "ANALOGICO", "Origem do controle de movimento.", "FIXO" if game.analog_fixed else "DINAMICO", analog_accent, game.settings_selected == game._gameplay_preference_index("analog"))
	var shop_accent = Color(0.0, 1.0, 0.82) if game.shop_auto_enabled else Color(1.0, 0.68, 0.24)
	game._draw_gameplay_preference(game.settings_buttons["shop_mode"], "ABERTURA DA LOJA", "Automatica usa contagem; manual usa botao no HUD.", "AUTOMATICA" if game.shop_auto_enabled else "MANUAL", shop_accent, game.settings_selected == game._gameplay_preference_index("shop_mode"))
	game._draw_toggle_switch(game._shop_mode_toggle_rect(game.settings_buttons["shop_mode"]), game.shop_auto_enabled, shop_accent)
	var interval_panel: Rect2 = game.settings_buttons["shop_interval"]
	var interval_value = "%d MIN" % int(game.shop_auto_interval / 60.0) if game.shop_auto_enabled else "DESATIVADO"
	game._draw_gameplay_preference(interval_panel, "INTERVALO DA LOJA", "Tempo entre aberturas automaticas.", interval_value, Color(0.44, 0.82, 1.0) if game.shop_auto_enabled else Color(0.48, 0.52, 0.58), game.settings_selected == game._gameplay_preference_index("shop_interval"))
	if game.shop_auto_enabled:
		game._draw_small_rect_button(game._shop_interval_minus_rect(interval_panel), "-", Color(0.04, 0.1, 0.14), Color(0.44, 0.82, 1.0))
		game._draw_small_rect_button(game._shop_interval_plus_rect(interval_panel), "+", Color(0.04, 0.1, 0.14), Color(0.44, 0.82, 1.0))
	game._draw_gameplay_preference(game.settings_buttons["target_priority"], "PRIORIDADE DO DISPARO", "Define o alvo escolhido pela mira automatica.", game._target_priority_label(), Color(1.0, 0.48, 0.74), game.settings_selected == game._gameplay_preference_index("target_priority"))
	if game._uses_desktop_ui() and game.settings_buttons.has("desktop_aim"):
		game._draw_gameplay_preference(game.settings_buttons["desktop_aim"], "MIRA DAS HABILIDADES", "Como Q/E usam o cursor no desktop.", game._desktop_aim_mode_label(), Color(0.42, 0.92, 1.0), game.settings_selected == game._gameplay_preference_index("desktop_aim"))
	if game._uses_desktop_ui() and game.settings_buttons.has("desktop_teleport"):
		game._draw_gameplay_preference(game.settings_buttons["desktop_teleport"], "TELEPORTE DESKTOP", "Cursor, alvo automatico ou confirmacao visual.", game._desktop_teleport_mode_label(), Color(0.56, 0.72, 1.0), game.settings_selected == game._gameplay_preference_index("desktop_teleport"))
	if game._uses_desktop_ui() and game.settings_buttons.has("desktop_attack_aim"):
		game._draw_gameplay_preference(game.settings_buttons["desktop_attack_aim"], "MIRA DO ATAQUE BASICO", "Alvo automatico ou direcao do cursor.", game._desktop_attack_aim_mode_label(), Color(0.48, 0.88, 0.64), game.settings_selected == game._gameplay_preference_index("desktop_attack_aim"))
	if game._uses_desktop_ui() and game.settings_buttons.has("desktop_hud_scale"):
		var desktop_hud_panel: Rect2 = game.settings_buttons["desktop_hud_scale"]
		game._draw_gameplay_preference(desktop_hud_panel, "TAMANHO DO HUD", "Proporcao dos icones fixos no desktop.", game._desktop_hud_scale_label(), Color(0.72, 1.0, 0.48), game.settings_selected == game._gameplay_preference_index("desktop_hud_scale"))
		game._draw_small_rect_button(game._desktop_hud_scale_minus_rect(desktop_hud_panel), "-", Color(0.06, 0.14, 0.08), Color(0.72, 1.0, 0.48))
		game._draw_small_rect_button(game._desktop_hud_scale_plus_rect(desktop_hud_panel), "+", Color(0.06, 0.14, 0.08), Color(0.72, 1.0, 0.48))
	var damage_panel = game.settings_buttons["damage_text"]
	game._draw_gameplay_preference(damage_panel, "TEXTO DE DANO", "Tamanho dos numeros exibidos nos inimigos.", "%d%%" % int(round(game.damage_text_scale * 100.0)), Color(1.0, 0.5, 0.28), game.settings_selected == game._gameplay_preference_index("damage_text"))
	game._draw_small_rect_button(game._damage_text_minus_rect(damage_panel), "-", Color(0.2, 0.1, 0.08), Color(1.0, 0.5, 0.28))
	game._draw_small_rect_button(game._damage_text_plus_rect(damage_panel), "+", Color(0.2, 0.1, 0.08), Color(1.0, 0.5, 0.28))
	var interface_panel = game.settings_buttons["interface_text"]
	game._draw_gameplay_preference(interface_panel, "TEXTOS DA INTERFACE", "Escala de textos da loja e manifestações.", "%d%%" % int(round(game.interface_text_scale * 100.0)), Color(0.62, 0.88, 1.0), game.settings_selected == game._gameplay_preference_index("interface_text"))
	game._draw_small_rect_button(game._interface_text_minus_rect(interface_panel), "-", Color(0.04, 0.1, 0.16), Color(0.62, 0.88, 1.0))
	game._draw_small_rect_button(game._interface_text_plus_rect(interface_panel), "+", Color(0.04, 0.1, 0.16), Color(0.62, 0.88, 1.0))
	var fps_accent = Color(0.0, 1.0, 0.82) if game.show_fps_counter else Color(0.48, 0.52, 0.58)
	game._draw_gameplay_preference(game.settings_buttons["fps"], "CONTADOR DE FPS", "Mostra desempenho no canto da tela.", "ON" if game.show_fps_counter else "OFF", fps_accent, game.settings_selected == game._gameplay_preference_index("fps"))
	game._draw_toggle_switch(game._shop_mode_toggle_rect(game.settings_buttons["fps"]), game.show_fps_counter, fps_accent)
	var tutorial_accent = Color(0.0, 1.0, 0.82) if game.run_tutorial_enabled else Color(0.48, 0.52, 0.58)
	game._draw_gameplay_preference(game.settings_buttons["tutorial"], "TUTORIAL INICIAL", "Pergunta ao iniciar a proxima partida.", "ON" if game.run_tutorial_enabled else "OFF", tutorial_accent, game.settings_selected == game._gameplay_preference_index("tutorial"))
	game._draw_toggle_switch(game._shop_mode_toggle_rect(game.settings_buttons["tutorial"]), game.run_tutorial_enabled, tutorial_accent)
	var cheat_value = "QA ATIVO" if game.qa_data_unlocked else ("ONLINE OK" if game.online_mode_unlocked else ("RETORNANTE OK" if game.retornante_unlocked else (game.gameplay_cheat_text if game.gameplay_cheat_text != "" else "TOQUE E DIGITE")))
	var cheat_accent = Color(0.74, 1.0, 0.36) if game.qa_data_unlocked else (Color(0.0, 1.0, 0.82) if game.online_mode_unlocked else (Color(0.86, 0.48, 1.0) if game.retornante_unlocked else Color(0.64, 0.44, 1.0)))
	if game.gameplay_cheat_focused:
		cheat_value = "DIGITANDO..."
	game._draw_gameplay_preference(game.settings_buttons["retornante_cheat"], "CHEAT SECRETO", "Campo reservado para codigos de QA e dev.", cheat_value, cheat_accent, game.settings_selected == game._gameplay_preference_index("retornante_cheat"))
	var haptics_accent = Color(0.0, 1.0, 0.82) if game.haptics_enabled else Color(0.48, 0.52, 0.58)
	game._draw_gameplay_preference(game.settings_buttons["haptics"], "VIBRACAO", "Feedback tatil dos impactos e habilidades.", "ON" if game.haptics_enabled else "OFF", haptics_accent, game.settings_selected == game._gameplay_preference_index("haptics"))
	game._draw_toggle_switch(game._shop_mode_toggle_rect(game.settings_buttons["haptics"]), game.haptics_enabled, haptics_accent)
	if game.ui_platform_override_unlocked and game.settings_buttons.has("ui_platform_profile"):
		game._draw_gameplay_preference(game.settings_buttons["ui_platform_profile"], "PERFIL DE INTERFACE", "Auto detecta %s; cheat libera Android/Desktop." % game._runtime_platform_name(), game._ui_platform_profile_label(), Color(1.0, 0.78, 0.22), game.settings_selected == game._gameplay_preference_index("ui_platform_profile"))
	if game.QA_STREAMING_FEATURE_ENABLED and game.qa_streaming_unlocked and game.settings_buttons.has("qa_stream_quality"):
		var quality_size = game._qa_stream_target_size()
		var quality_label = "%s (%dx%d)" % [game.qa_streaming_quality_mode.to_upper(), quality_size.x, quality_size.y]
		game._draw_gameplay_preference(game.settings_buttons["qa_stream_quality"], "QUALIDADE AO VIVO", "Usada pelo botao de transmissao do menu.", quality_label, Color(0.38, 0.88, 1.0), game.settings_selected == game._gameplay_preference_index("qa_stream_quality"))
	game._draw_settings_card(game.settings_buttons["back"], "VOLTAR", "retornar as configuracoes", Color(1.0, 0.26, 0.36), game.settings_selected == game._gameplay_preference_index("back"))
	if game.gameplay_cheat_focused:
		game._draw_cheat_popup(viewport)


static func _draw_cheat_popup(game: Node2D, viewport: Vector2) -> void :
	game._sync_cheat_input_rect(viewport)
	var accent = Color(0.64, 0.44, 1.0)
	var panel = game._cheat_popup_rect(viewport)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.54), true)
	game._draw_holo_panel(panel, accent, true, 0.84)
	game._draw_glitch_title("CHEAT", Vector2(panel.get_center().x, panel.position.y + 48.0), 30, accent)
	game._draw_centered("Digite o codigo secreto.", Vector2(panel.get_center().x, panel.position.y + 82.0), 14, Color(0.82, 0.92, 1.0, 0.88))
	var input_rect = game._cheat_input_rect(viewport)
	game.draw_rect(input_rect.grow(5.0), Color(0.0, 0.0, 0.0, 0.7), true)
	game.draw_rect(input_rect.grow(5.0), Color(accent.r, accent.g, accent.b, 0.82), false, 2)
	game.settings_buttons["cheat_ok"] = Rect2(panel.position.x + panel.size.x * 0.5 - 168.0, panel.end.y - 62.0, 152.0, 44.0)
	game.settings_buttons["cheat_cancel"] = Rect2(panel.position.x + panel.size.x * 0.5 + 16.0, panel.end.y - 62.0, 152.0, 44.0)
	game._draw_big_button(game.settings_buttons["cheat_ok"], "OK", Color(0.06, 0.12, 0.18, 0.94), accent)
	game._draw_big_button(game.settings_buttons["cheat_cancel"], "CANCELAR", Color(0.13, 0.04, 0.06, 0.94), Color(1.0, 0.26, 0.36))


static func _draw_gameplay_preference(game: Node2D, rect: Rect2, title: String, subtitle: String, value: String, accent: Color, selected: bool = false) -> void :
	game._draw_settings_surface(rect, selected)
	var value_rect: Rect2 = game._gameplay_value_rect(rect)
	if game.mode == "settings_graphics":
		value_rect = Rect2(rect.end.x - 136.0, rect.get_center().y - 18.0, 116.0, 36.0)
	var text_width: float = maxf(100.0, value_rect.position.x - rect.position.x - 30.0)
	var stepper: bool = title in ["INTERVALO DA LOJA", "TEXTO DE DANO", "TEXTOS DA INTERFACE", "TAMANHO DO HUD"]
	if stepper:
		text_width -= 48.0
	var title_size: int = 15 if rect.size.y >= 64.0 else 13
	game._draw_ui_text(game._menu_sentence_case(title), rect.position + Vector2(16, rect.size.y * 0.39), title_size, Color(0.93, 0.94, 0.9), text_width)
	game._draw_ui_wrap(subtitle, Rect2(rect.position + Vector2(16, rect.size.y * 0.51), Vector2(text_width, rect.size.y * 0.45)), 11 if rect.size.y >= 64.0 else 10, Color(0.61, 0.72, 0.74), 2 if rect.size.y >= 56.0 else 1)
	game.draw_rect(value_rect, Color(accent, 0.09))
	game.draw_line(Vector2(value_rect.position.x, value_rect.end.y), value_rect.end, Color(accent, 0.52), 1.0)
	var shown: String = "Ligado" if value == "ON" else ("Desligado" if value == "OFF" else value)
	var size: int = 13
	while size > 10 and game.menu_ui_font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > value_rect.size.x - 12.0:
		size -= 1
	game._draw_centered_with_font(game.menu_ui_font, shown, value_rect.get_center(), size, Color(0.87, 0.94, 0.92))


static func _draw_audio_settings(game: Node2D, viewport: Vector2) -> void :
	game._draw_settings_shell(viewport, "Som", "Equilibre a trilha, os impactos e os sons de combate.")
	game.settings_buttons = game._audio_settings_rects(viewport)
	var panel: Rect2 = game.settings_buttons["panel"]
	game._draw_settings_surface(panel, false)
	game._draw_ui_text("VOLUME POR CANAL", panel.position + Vector2(24.0, 28.0), 11, Color(0.36, 0.78, 0.78))
	game._draw_ui_text("Arraste para ajustar · use − / + para passos de 10%", panel.position + Vector2(24.0, 47.0), 11, Color(0.59, 0.7, 0.73))
	var titles = ["Geral", "Música", "Efeitos", "Disparos"]
	var details = ["Todo o áudio", "Trilha sonora", "Impactos e avisos", "Sons de ataque"]
	for i in range(4):
		var row: Rect2 = game._audio_slider_row_rect(panel, i)
		var bar: Rect2 = game._audio_slider_rect(panel, i)
		var volume: float = game._audio_volume_index(i)
		var active: bool = game.settings_selected == i or game.audio_slider_drag_index == i
		var accent = Color(0.36, 0.88, 0.87)
		game._draw_settings_surface(row, active)
		game._draw_ui_text(titles[i], Vector2(row.position.x + 14.0, row.get_center().y - 2.0), 16, Color(0.93, 0.94, 0.9))
		game._draw_ui_text(details[i], Vector2(row.position.x + 14.0, row.get_center().y + 15.0), 10, Color(0.57, 0.69, 0.71))
		game.draw_rect(bar, Color(0.17, 0.26, 0.28))
		for tick in range(1, 10):
			var tx: float = bar.position.x + bar.size.x * float(tick) / 10.0
			game.draw_line(Vector2(tx, bar.end.y + 5.0), Vector2(tx, bar.end.y + 8.0), Color(0.3, 0.43, 0.44), 1.0)
		game.draw_rect(Rect2(bar.position, Vector2(bar.size.x * volume, bar.size.y)), Color(accent, 0.9 if active else 0.6))
		var knob = Vector2(bar.position.x + bar.size.x * volume, bar.get_center().y)
		if active:
			game.draw_circle(knob, 13.0, Color(accent, 0.14))
		game.draw_circle(knob, 7.0 if active else 5.0, Color(0.89, 0.97, 0.94))
		for step in [-1, 1]:
			var button: Rect2 = game._audio_minus_rect(panel, i) if step == -1 else game._audio_plus_rect(panel, i)
			game._draw_settings_surface(button, button.has_point(game.get_global_mouse_position()))
			game._draw_centered_with_font(game.menu_ui_font, "−" if step == -1 else "+", button.get_center(), 20, Color(0.73, 0.85, 0.84))
		game._draw_centered_with_font(game.menu_ui_font, "%d%%" % roundi(volume * 100.0), Vector2(row.end.x - 32.0, row.get_center().y), 13, Color(0.9, 0.93, 0.88))
	game._draw_settings_card(game.settings_buttons["back"], "VOLTAR", "retornar às configurações", Color(0.36, 0.88, 0.87), game.settings_selected == 4)


static func _draw_data_settings(game: Node2D, viewport: Vector2) -> void :
	game._draw_holo_background(viewport, null, Color(0.74, 1.0, 0.36))
	game._sync_webhook_input_rect(viewport)
	var portrait = game._is_portrait(viewport)
	game._draw_glitch_title("DADOS QA", Vector2(viewport.x * 0.5, 56 if not portrait else 48), 34 if not portrait else 30, Color(0.74, 1.0, 0.36))
	var panel = game._data_settings_panel_rect(viewport)
	game._draw_holo_panel(panel, Color(0.74, 1.0, 0.36), true, 0.7)
	game.draw_string(game.font, panel.position + Vector2(34, 44), "ENVIO DE DADOS DA PARTIDA", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 68.0, 20, Color.WHITE)
	game.draw_string(game.font, panel.position + Vector2(34, 72), "Cole aqui o webhook descartavel enviado pelo dev. O jogo envia o relatorio ao fim da run.", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 68.0, 12, Color(0.78, 0.92, 0.84, 0.86))
	var input_rect = Rect2(panel.position.x + 40.0, panel.position.y + panel.size.y * 0.38, panel.size.x - 80.0, 48.0)
	game.draw_rect(input_rect.grow(5.0), Color(0.0, 0.0, 0.0, 0.64), true)
	game.draw_rect(input_rect.grow(5.0), Color(0.74, 1.0, 0.36, 0.78), false, 2)
	var active_text = "CONFIGURADO" if game.run_report_webhook_url != "" else "NAO CONFIGURADO"
	var status_color = Color(0.74, 1.0, 0.36) if game.run_report_webhook_url != "" else Color(1.0, 0.34, 0.32)
	game._draw_centered(active_text, Vector2(panel.get_center().x, input_rect.position.y - 18.0), 13, status_color)
	if game.webhook_error != "":
		game._draw_centered(game.webhook_error, Vector2(panel.get_center().x, input_rect.end.y + 28.0), 12, Color(0.86, 0.96, 0.88, 0.9))
	game.settings_buttons["data_save"] = Rect2(panel.position.x + 40.0, panel.end.y - 78.0, 170.0, 52.0)
	game.settings_buttons["data_clear"] = Rect2(panel.position.x + 228.0, panel.end.y - 78.0, 170.0, 52.0)
	game.settings_buttons["data_back"] = Rect2(panel.end.x - 210.0, panel.end.y - 78.0, 170.0, 52.0)
	game._draw_big_button(game.settings_buttons["data_save"], "SALVAR", Color(0.05, 0.15, 0.06, 0.92), Color(0.74, 1.0, 0.36), game.settings_selected == 0)
	game._draw_big_button(game.settings_buttons["data_clear"], "LIMPAR", Color(0.15, 0.1, 0.04, 0.92), Color(1.0, 0.68, 0.24), game.settings_selected == 1)
	game._draw_big_button(game.settings_buttons["data_back"], "VOLTAR", Color(0.13, 0.04, 0.06, 0.92), Color(1.0, 0.26, 0.36), game.settings_selected == 2)


static func _draw_settings_info_panel(game: Node2D, viewport: Vector2, key: String) -> void:
	if game._is_portrait(viewport):
		return
	var bounds: Rect2 = game._settings_list_bounds(viewport)
	var panel = Rect2(viewport.x * 0.47, bounds.position.y, viewport.x * 0.47, bounds.size.y)
	game._draw_settings_surface(panel, false)
	var x: float = panel.position.x + 28.0
	var width: float = panel.size.x - 56.0
	game._draw_ui_text("PREFERÊNCIAS / %02d" % (game._settings_index_for(key) + 1), Vector2(x, panel.position.y + 34.0), 11, Color(0.36, 0.78, 0.78))
	game._draw_ui_text(game._menu_sentence_case(game._settings_option_title(key)), Vector2(x, panel.position.y + 76.0), 27, Color(0.95, 0.94, 0.89), width)
	game._draw_ui_wrap(game._settings_option_help(key), Rect2(x, panel.position.y + 98.0, width, 126.0), 15, Color(0.67, 0.77, 0.79), 5)
	var note_y: float = maxf(panel.position.y + 228.0, panel.end.y - 106.0)
	game.draw_line(Vector2(x, note_y - 16.0), Vector2(x + width, note_y - 16.0), Color(0.36, 0.65, 0.66, 0.3), 1.0)
	game._draw_ui_text("SOBRE ESTE AJUSTE", Vector2(x, note_y + 3.0), 10, Color(0.72, 0.63, 0.44))
	game._draw_ui_wrap(game._settings_impact_text(key), Rect2(x, note_y + 14.0, width, 56.0), 12, Color(0.63, 0.73, 0.75), 3)


static func _draw_texture_cover(game: Node2D, texture: Texture2D, rect: Rect2, modulate: = Color.WHITE) -> void :
	if texture == null:
		game.draw_rect(rect, Color(0.01, 0.014, 0.03), true)
		return
	var src = Rect2(Vector2.ZERO, texture.get_size())
	var src_ratio = src.size.x / max(1.0, src.size.y)
	var dst_ratio = rect.size.x / max(1.0, rect.size.y)
	if src_ratio > dst_ratio:
		var w = src.size.y * dst_ratio
		src.position.x = (src.size.x - w) * 0.5
		src.size.x = w
	else:
		var h = src.size.x / dst_ratio
		src.position.y = (src.size.y - h) * 0.5
		src.size.y = h
	game.draw_texture_rect_region(texture, rect, src, modulate)


static func _draw_holo_background(game: Node2D, viewport: Vector2, texture: Texture2D = null, accent: = Color(0.0, 1.0, 0.82)) -> void :
	if texture:
		game._draw_texture_cover(texture, Rect2(Vector2.ZERO, viewport))
	else:
		game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.006, 0.01, 0.026), true)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.58), true)
	game._draw_menu_grid(viewport, Color(accent.r, accent.g, accent.b, 0.13), 38.0)
	for i in range(12):
		var x1 = fmod(game.time_alive * (28.0 + i * 2.0) + i * 97.0, viewport.x + 220.0) - 110.0
		var y1 = viewport.y * (0.1 + (i % 6) * 0.14)
		game.draw_line(Vector2(x1, y1), Vector2(x1 + 92.0, y1 + 12.0), Color(accent.r, accent.g, accent.b, 0.15), 2)
	for y in range(0, int(viewport.y), 5):
		if y % 15 == 0:
			game.draw_line(Vector2(0, y), Vector2(viewport.x, y), Color(1, 1, 1, 0.025), 1)


static func _draw_glitch_title(game: Node2D, text: String, pos: Vector2, size: int, accent: = Color(0.0, 1.0, 0.82)) -> void :
	var msec = Time.get_ticks_msec()
	var sec = float(msec) * 0.001
	var cycle = fposmod(sec, 20.0)
	var is_glitching = cycle < 1.0

	var title_font = game.menu_title_font if game.menu_title_font != null else game.font
	var line_w = title_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.58

	if is_glitching:
		var glitch_intensity = sin(cycle * PI)
		var jitter = sin(float(msec) * 0.08) * (7.0 * glitch_intensity)
		var offset_r = Vector2(-5.0 * glitch_intensity + jitter, sin(sec * 45.0) * 3.0)
		var offset_b = Vector2(5.0 * glitch_intensity - jitter, - sin(sec * 40.0) * 3.0)

		game._draw_centered_with_font(title_font, text, pos + Vector2(5.0, 6.0), size, Color(0.06, 0.0, 0.1, 0.96))
		game._draw_centered_with_font(title_font, text, pos + offset_r, size, Color(1.0, 0.08, 0.32, 0.88))
		game._draw_centered_with_font(title_font, text, pos + offset_b, size, Color(0.0, 0.92, 1.0, 0.88))
		game._draw_centered_with_font(title_font, text, pos + Vector2(jitter * 0.6, 0), size, Color(1.0, 0.92, 0.2, 0.65))
		game._draw_centered_with_font(title_font, text, pos, size, Color(0.96, 0.98, 1.0))

		var scan_y = pos.y + (sin(sec * 60.0) * size * 0.35)
		game.draw_line(pos + Vector2( - line_w * 1.1, scan_y - pos.y), pos + Vector2(line_w * 1.1, scan_y - pos.y), Color(1.0, 0.18, 0.45, 0.85), 2.5)
	else:
		game._draw_centered_with_font(title_font, text, pos + Vector2(3.0, 4.0), size, Color(0.04, 0.0, 0.08, 0.8))
		game._draw_centered_with_font(title_font, text, pos + Vector2(1.0, 1.0), size, Color(accent.r, accent.g, accent.b, 0.35))
		game._draw_centered_with_font(title_font, text, pos, size, Color(0.96, 0.98, 1.0))

	game.draw_line(pos + Vector2( - line_w, size * 0.45), pos + Vector2(line_w, size * 0.45), Color(accent.r, accent.g, accent.b, 0.74), 2)


static func _draw_holo_panel(game: Node2D, rect: Rect2, border: = Color(0.0, 1.0, 0.82), selected: = false, fill_alpha: = 0.7) -> void :
	var bg = Color(0.01, 0.025, 0.04, fill_alpha)
	if selected:
		bg = bg.lerp(border, 0.12)
	game.draw_rect(rect, bg, true)
	game.draw_rect(rect.grow(-5), Color(1, 1, 1, 0.035), false, 1)
	game.draw_rect(rect, Color(border.r, border.g, border.b, 0.96 if selected else 0.54), false, 3 if selected else 2)
	var left = rect.position + Vector2(0, rect.size.y * 0.2)
	var right = rect.position + Vector2(rect.size.x, rect.size.y * 0.8)
	game.draw_line(left, left + Vector2(0, rect.size.y * 0.58), Color(border.r, border.g, border.b, 0.5), 4)
	game.draw_line(right, right - Vector2(0, rect.size.y * 0.58), Color(1.0, 0.08, 0.78, 0.28), 3)
	for i in range(3):
		var yy = rect.position.y + 12 + i * 9
		game.draw_line(Vector2(rect.position.x + 14, yy), Vector2(rect.position.x + 54 + i * 18, yy), Color(border.r, border.g, border.b, 0.28), 1)


static func _draw_section_flow(game: Node2D, label: String, label_color: Color, text: String, text_color: Color, start_y: float, details_rect: Rect2, font_size: int) -> float:

	game.draw_string(game.font, Vector2(details_rect.position.x + 20, start_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, label_color)


	var text_y = start_y + font_size + 5
	var words = text.split(" ")
	var line = ""
	var max_w = details_rect.size.x - 40

	for word in words:
		var test = line + (" " if line != "" else "") + word
		if game.font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_w and line != "":
			game.draw_string(game.font, Vector2(details_rect.position.x + 20, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
			line = word
			text_y += font_size + 4
		else:
			line = test

	if line != "":
		game.draw_string(game.font, Vector2(details_rect.position.x + 20, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
		text_y += font_size + 4


	return text_y + 12


static func _draw_minimal_info_row(game: Node2D, rect: Rect2, label: String, text: String, accent: Color, selected: = false) -> void :
	var fill = Color(accent.r, accent.g, accent.b, 0.1 if not selected else 0.16)
	game.draw_rect(rect, fill, true)
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.26 if not selected else 0.45), false, 1)
	var label_w = min(122.0, rect.size.x * 0.27)
	var label_rect = Rect2(rect.position + Vector2(10.0, 7.0), Vector2(label_w, rect.size.y - 14.0))
	game.draw_rect(label_rect, Color(0.0, 0.0, 0.0, 0.2), true)
	game.draw_line(label_rect.position + Vector2(0, label_rect.size.y), label_rect.end, Color(accent.r, accent.g, accent.b, 0.62), 2)
	var label_size = game._fit_text_size(label, label_rect.size.x - 12.0, mini(game._readable_text_size(11), 13), 9)
	game._draw_centered(label, label_rect.get_center() + Vector2(0, 4), label_size, Color(accent.r, accent.g, accent.b, 0.96))
	var text_rect = Rect2(rect.position.x + label_w + 24.0, rect.position.y + 8.0, rect.size.x - label_w - 36.0, rect.size.y - 16.0)
	var body_size = mini(game._readable_text_size(12), 15)
	game._draw_wrapped(text, text_rect, body_size, Color(0.88, 0.94, 0.97, 0.92))


static func _draw_manifest_info_panel(game: Node2D, rect: Rect2, item: Dictionary, details: Dictionary, aura_view: bool, accent: Color) -> void :
	game._draw_holo_panel(rect, accent, true, 0.94)
	var pad = 18.0
	var header_h = 76.0
	var title_size = game._fit_text_size(String(item["name"]).to_upper(), rect.size.x - pad * 2.0, mini(game._readable_text_size(25), 27), 18)
	game.draw_string(game.font, rect.position + Vector2(pad, 34.0), String(item["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, title_size, accent)
	var caption = "ESTADO ESPECTRAL" if aura_view else "MANIFESTACAO ATIVA"
	var caption_size = game._fit_text_size(caption, rect.size.x - pad * 2.0, mini(game._readable_text_size(11), 13), 9)
	game.draw_string(game.font, rect.position + Vector2(pad, 58.0), caption, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - pad * 2.0, caption_size, Color(0.62, 0.8, 0.86, 0.8))
	game.draw_line(rect.position + Vector2(pad, header_h), rect.position + Vector2(rect.size.x - pad, header_h), Color(accent.r, accent.g, accent.b, 0.34), 1)

	var rows = game._manifest_info_rows(item, details, aura_view)
	var footer_h = 48.0
	var gap = 8.0
	var rows_area = Rect2(rect.position.x + pad, rect.position.y + header_h + 14.0, rect.size.x - pad * 2.0, rect.size.y - header_h - footer_h - 30.0)
	var row_h = max(54.0, (rows_area.size.y - gap * float(rows.size() - 1)) / max(1.0, float(rows.size())))
	for i in range(rows.size()):
		var row = rows[i]
		var row_rect = Rect2(rows_area.position.x, rows_area.position.y + i * (row_h + gap), rows_area.size.x, row_h)
		game._draw_minimal_info_row(row_rect, String(row["label"]), String(row["text"]), accent, i == 0)

	var footer = Rect2(rect.position.x + pad, rect.end.y - footer_h - 14.0, rect.size.x - pad * 2.0, footer_h)
	game._draw_manifest_footer(footer, aura_view, accent)


static func _draw_manifest_footer(game: Node2D, rect: Rect2, aura_view: bool, accent: Color) -> void :
	game.draw_rect(rect, Color(0.0, 0.0, 0.0, 0.18), true)
	game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.3), false, 1)
	var label = "ESCOLHA O ESPECTRO" if aura_view else "PROXIMA ETAPA"
	var value = String(game.AURAS[game.selected_aura]["name"]).to_upper() if aura_view else "REVELAR ESPECTRO"
	if aura_view:
		game.buttons["aura_prev"] = Rect2(rect.position, Vector2(44.0, rect.size.y))
		game.buttons["aura_next"] = Rect2(rect.end - Vector2(44.0, rect.size.y), Vector2(44.0, rect.size.y))
		game._draw_centered("<", game.buttons["aura_prev"].get_center() + Vector2(0, 5), 22, accent)
		game._draw_centered(">", game.buttons["aura_next"].get_center() + Vector2(0, 5), 22, accent)
	else:
		game.buttons.erase("aura_prev")
		game.buttons.erase("aura_next")
	game.draw_string(game.font, rect.position + Vector2(54.0, 18.0), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 108.0, mini(game._readable_text_size(9), 11), Color(0.65, 0.8, 0.84, 0.78))
	game._draw_centered(value, rect.get_center() + Vector2(0, 8), game._fit_text_size(value, rect.size.x - 116.0, mini(game._readable_text_size(14), 16), 10), accent)


static func _draw_catalog_locked_card_icon(game: Node2D, rect: Rect2, large: = false) -> void:
	var bg = Color(0.015, 0.022, 0.03, 0.92)
	var edge = Color(0.54, 0.26, 0.92, 0.88)
	var cyan = Color(0.26, 0.9, 1.0, 0.48)
	game.draw_rect(rect, bg, true)
	game.draw_rect(rect, edge, false, 2)
	game.draw_rect(rect.grow(-5), Color(0.06, 0.02, 0.11, 0.42), false, 1)
	var scan_step: float = maxf(6.0, rect.size.y / 10.0)
	var scan_y: float = rect.position.y + 6.0
	while scan_y < rect.end.y - 4.0:
		game.draw_line(Vector2(rect.position.x + 7.0, scan_y), Vector2(rect.end.x - 7.0, scan_y), Color(cyan.r, cyan.g, cyan.b, 0.18), 1)
		scan_y += scan_step
	for i in range(4):
		var p0 = rect.position + Vector2(8.0 + i * 9.0, 10.0 + i * 5.0)
		game.draw_line(p0, p0 + Vector2(rect.size.x * 0.22, 0.0), Color(edge.r, edge.g, edge.b, 0.55), 1)
	var pulse: float = 0.65 + 0.25 * sin(float(Time.get_ticks_msec()) / 230.0)
	var text_size: int = 32 if large else 22
	game._draw_centered("???", rect.get_center() + Vector2(0, -4 if large else 0), text_size, Color(0.86, 0.92, 1.0, pulse))
	if large:
		game._draw_centered("REGISTRO BLOQUEADO", Vector2(rect.get_center().x, rect.end.y - 34.0), 13, Color(0.68, 0.82, 1.0, 0.86))


static func _draw_spectrum_reveal_fragments(game: Node2D, center_x: float, center_y: float, card_w: float, card_h: float, spacing: float, progress: float) -> void :
	var break_t = smoothstep(0.0, 0.56, progress)
	var rebuild_t = smoothstep(0.34, 1.0, progress)
	for diff in [-1, 0, 1]:
		var abs_diff = abs(float(diff))
		var scale = 1.15 if diff == 0 else 0.85
		var pos_x = center_x + float(diff) * spacing
		var rect = Rect2(pos_x - card_w * scale * 0.5, center_y - card_h * scale * 0.5, card_w * scale, card_h * scale)
		var manifest_idx = posmod(game.selected_manifestation + diff, game.MANIFESTATIONS.size())
		var aura_idx = posmod(game.selected_aura + diff, game.AURAS.size())
		var manifest_item: Dictionary = game.MANIFESTATIONS[manifest_idx]
		var aura_item: Dictionary = game.AURAS[aura_idx]
		var manifest_color = game._manifest_select_item_color(manifest_item, false)
		var aura_color = game._manifest_select_item_color(aura_item, true)
		var manifest_tex = game._manifest_select_item_texture(manifest_item, false)
		var aura_tex = game._manifest_select_item_texture(aura_item, true)
		if progress < 0.78:
			game._draw_fragmented_choice_texture(manifest_tex, rect.grow(-22 * scale), manifest_color, break_t, true, diff)
		if progress > 0.24:
			game._draw_fragmented_choice_texture(aura_tex, rect.grow(-22 * scale), aura_color, rebuild_t, false, diff + 9)
		var pull_alpha = sin(clamp(progress, 0.0, 1.0) * PI) * (0.3 if diff == 0 else 0.16)
		for ray in range(5):
			var a = float(ray) * TAU / 5.0 + progress * TAU + diff * 0.7
			var from = rect.get_center() + Vector2.from_angle(a) * rect.size.x * 0.72
			game.draw_line(from, rect.get_center(), Color(aura_color.r, aura_color.g, aura_color.b, pull_alpha), 1)


static func _draw_fragmented_choice_texture(game: Node2D, texture: Texture2D, rect: Rect2, color: Color, amount: float, breaking: bool, slot: int) -> void :
	var cols = 4
	var rows = 4
	var piece_size = Vector2(rect.size.x / cols, rect.size.y / rows)
	var tex_size = texture.get_size() if texture else Vector2(256, 256)
	for gx in range(cols):
		for gy in range(rows):
			var piece = Rect2(rect.position + Vector2(gx * piece_size.x, gy * piece_size.y), piece_size)
			var src = Rect2(Vector2(float(gx) / cols, float(gy) / rows) * tex_size, Vector2(tex_size.x / cols, tex_size.y / rows))
			var seed = float(abs((game.manifest_transition_seed + slot * 971 + gx * 193 + gy * 449) % 1000)) / 1000.0
			var dir = Vector2.from_angle(seed * TAU + float(gx - gy) * 0.22)
			var force = 38.0 + 78.0 * seed
			var t = clamp(amount, 0.0, 1.0)
			var offset = dir * force * (t if breaking else 1.0 - t)
			offset += Vector2(sin(Time.get_ticks_msec() * 0.012 + seed * 9.0), cos(Time.get_ticks_msec() * 0.01 + seed * 7.0)) * 5.0 * sin(t * PI)
			var alpha = (1.0 - t * 0.82) if breaking else t
			var dest = Rect2(piece.position + offset, piece.size).grow(-1.0)
			if texture:
				game.draw_texture_rect_region(texture, dest, src, Color(1, 1, 1, alpha))
				game.draw_rect(dest, Color(color.r, color.g, color.b, 0.22 * alpha), true)
			game.draw_rect(dest, Color(color.r, color.g, color.b, 0.26 * alpha), false, 1)


static func _draw_manifest_mp(game: Node2D, viewport: Vector2) -> void :
	game._draw_holo_background(viewport, null, Color(0.0, 1.0, 0.82))
	var local_scroll: float = game.aura_scroll_pos if game.manifest_select_stage == game.MANIFEST_STAGE_AURA else game.manifest_scroll_pos
	var aura_view: bool = game.manifest_select_stage == game.MANIFEST_STAGE_AURA
	var active_items: Array = game.AURAS if aura_view else game.MANIFESTATIONS
	var active_selected: int = game.selected_aura if aura_view else game.selected_manifestation
	var item: Dictionary = active_items[active_selected]
	var color: Color = game._manifest_select_item_color(item, aura_view)
	var margin: float = clampf(viewport.x * 0.03, 18.0, 36.0)
	var title_size: int = int(clampf(viewport.y * 0.046, 24.0, 34.0))
	var header_y: float = clampf(viewport.y * 0.085, 44.0, 64.0)
	game._draw_glitch_title("EQUIPE ONLINE", Vector2(viewport.x * 0.5, header_y), title_size, color)
	var stage_label: String = "ESPECTRO" if aura_view else "MANIFESTACAO"
	var status_text: String = "confirme seu estado final" if aura_view else "selecione sua manifestacao"
	if game.mp_local_ready:
		status_text = "sua escolha esta travada"
	game._draw_centered(stage_label + " // " + status_text.to_upper(), Vector2(viewport.x * 0.5, header_y + 34.0), game._readable_text_size(11), Color(0.78, 0.93, 0.98, 0.9))

	var panel_top: float = header_y + 58.0
	var panel: Rect2 = Rect2(margin, panel_top, viewport.x - margin * 2.0, viewport.y - panel_top - margin)
	game.draw_rect(panel, Color(0.015, 0.025, 0.028, 0.9))
	game.draw_line(panel.position, Vector2(panel.end.x, panel.position.y), color, 2.0)
	var inner_pad: float = clampf(panel.size.x * 0.018, 16.0, 24.0)
	var team_w: float = clampf(panel.size.x * 0.31, 256.0, 384.0)
	if viewport.x < 1040.0:
		team_w = clampf(panel.size.x * 0.29, 238.0, 292.0)
	var action_h: float = 56.0
	var content_top: float = panel.position.y + 28.0
	var content_bottom: float = panel.end.y - action_h - 20.0
	var choice_rect: Rect2 = Rect2(panel.position.x + inner_pad, content_top, panel.size.x - team_w - inner_pad * 3.0, content_bottom - content_top)
	var team_rect: Rect2 = Rect2(panel.end.x - team_w - inner_pad, content_top, team_w, content_bottom - content_top)
	if choice_rect.size.x < 430.0:
		team_w = maxf(220.0, panel.size.x - inner_pad * 3.0 - 430.0)
		choice_rect.size.x = panel.size.x - team_w - inner_pad * 3.0
		team_rect = Rect2(panel.end.x - team_w - inner_pad, content_top, team_w, content_bottom - content_top)
	game._draw_manifest_mp_choice_surface(choice_rect, active_items, active_selected, local_scroll, aura_view, color)
	game._draw_manifest_mp_team_panel(team_rect, color)
	var footer_y: float = panel.end.y - action_h - 10.0
	game.buttons["mp_manifest_ready"] = Rect2(choice_rect.position.x, footer_y, choice_rect.size.x * (0.58 if aura_view and not game.mp_local_ready else 0.74), 46.0)
	var btn_label: String = "PRONTO" if aura_view else "REVELAR ESPECTRO"
	if game.mp_local_ready:
		btn_label = "CANCELAR PRONTO"
	game._draw_big_button(game.buttons["mp_manifest_ready"], btn_label, Color(0.02, 0.14, 0.11, 0.9) if not game.mp_local_ready else Color(0.18, 0.06, 0.08, 0.78), color if not game.mp_local_ready else Color(1.0, 0.22, 0.3), game.mp_local_ready)
	if aura_view and not game.mp_local_ready:
		game.buttons["mp_manifest_back_manifestation"] = Rect2(game.buttons["mp_manifest_ready"].end.x + 12.0, footer_y, maxf(136.0, choice_rect.size.x - game.buttons["mp_manifest_ready"].size.x - 12.0), 46.0)
		game._draw_big_button(game.buttons["mp_manifest_back_manifestation"], "TROCAR MANIF.", Color(0.03, 0.08, 0.12, 0.86), Color(0.56, 0.76, 1.0), false)
	else:
		game.buttons.erase("mp_manifest_back_manifestation")
	game.buttons["mp_manifest_start"] = Rect2(team_rect.position.x, footer_y, team_rect.size.x, 46.0)
	var all_ready: bool = game._manifest_all_players_ready()
	var can_start: bool = game._manifest_mp_start_available()
	var owner_start: bool = game._manifest_mp_local_can_start()
	var start_label: String = "INICIAR PARTIDA" if can_start and owner_start else ("AGUARDE O HOST" if all_ready and not owner_start else "AGUARDANDO EQUIPE")
	if game.mp_manifest_start_pending:
		start_label = "INICIANDO..."
	var start_border: Color = Color(0.16, 1.0, 0.54) if can_start and owner_start else Color(0.34, 0.52, 0.62)
	var start_bg: Color = Color(0.02, 0.16, 0.09, 0.9) if can_start and owner_start else Color(0.03, 0.05, 0.07, 0.62)
	game._draw_big_button(game.buttons["mp_manifest_start"], start_label, start_bg, start_border, can_start and owner_start)
	if game.mp_manifest_rejection_timer > 0.0 and game.mp_manifest_rejection_message != "":
		var warning_rect: Rect2 = Rect2(viewport.x * 0.5 - 240.0, viewport.y - 58.0, 480.0, 38.0)
		game._draw_holo_panel(warning_rect, Color(1.0, 0.18, 0.24), true, 0.86)
		game._draw_centered(game.mp_manifest_rejection_message, warning_rect.get_center() + Vector2(0, 5), 14, Color.WHITE)


static func _draw_manifest_mp_choice_surface(game: Node2D, rect: Rect2, active_items: Array, active_selected: int, scroll: float, aura_view: bool, accent: Color) -> void :
	var item: Dictionary = active_items[active_selected]
	game.draw_rect(rect, Color(0.02, 0.035, 0.04, 0.82))
	var header_h: float = 58.0
	var title: String = String(item.get("name", "???")).to_upper()
	var caption: String = "ESPECTRO SELECIONADO" if aura_view else "MANIFESTACAO SELECIONADA"
	game.draw_string(game.font, rect.position + Vector2(20.0, 30.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 40.0, game._fit_text_size(title, rect.size.x - 40.0, 24, 15), accent)
	game.draw_string(game.font, rect.position + Vector2(20.0, 50.0), caption, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 40.0, game._readable_text_size(9), Color(0.72, 0.9, 0.96, 0.82))
	game.draw_line(rect.position + Vector2(18.0, header_h), rect.position + Vector2(rect.size.x - 18.0, header_h), Color(accent.r, accent.g, accent.b, 0.34), 1.0)

	var carousel_rect: Rect2 = Rect2(rect.position.x + 16.0, rect.position.y + header_h + 10.0, rect.size.x - 32.0, maxf(100.0, rect.size.y - 258.0))
	var center_x: float = carousel_rect.get_center().x
	var center_y: float = carousel_rect.get_center().y
	var card_w: float = clampf(rect.size.x * 0.17, 78.0, 124.0)
	var card_h: float = card_w * 1.16
	var spacing: float = clampf(card_w * 1.13, 90.0, 138.0)
	var half_size: float = active_items.size() / 2.0
	for i in range(active_items.size()):
		var diff: float = float(i) - scroll
		if diff > half_size:
			diff -= active_items.size()
		elif diff < - half_size:
			diff += active_items.size()
		var abs_diff: float = abs(diff)
		if abs_diff > 2.25:
			continue
		var card_scale: float = lerp(1.12, 0.68, min(abs_diff, 1.0))
		var opacity: float = lerp(1.0, 0.26, min(abs_diff, 1.0))
		var pos_x: float = center_x + diff * spacing
		var item_rect: Rect2 = Rect2(pos_x - card_w * card_scale * 0.5, center_y - card_h * card_scale * 0.5, card_w * card_scale, card_h * card_scale)
		var card_item: Dictionary = active_items[i]
		var item_unlocked: bool = game._manifest_select_item_unlocked(i, aura_view)
		var item_color: Color = game._manifest_select_item_color(card_item, aura_view) if item_unlocked else Color(0.42, 0.46, 0.68)
		var taken: bool = game._manifest_choice_taken(i, aura_view)
		if taken:
			item_color = Color(1.0, 0.18, 0.24)
		game._draw_holo_panel(item_rect, item_color, abs_diff < 0.5, opacity * 0.72)
		var icon: Texture2D = game._manifest_select_item_texture(card_item, aura_view)
		if not item_unlocked:
			game._draw_catalog_locked_card_icon(item_rect.grow(-18.0 * card_scale), false)
		elif icon:
			game._draw_texture_contain(icon, item_rect.grow(-17.0 * card_scale), Color(0.38, 0.38, 0.42, opacity) if taken else Color(1, 1, 1, opacity))
		if taken:
			game._draw_centered("EM USO", item_rect.get_center() + Vector2(0, 5), game._fit_text_size("EM USO", item_rect.size.x - 12.0, 12, 9), Color(1.0, 0.88, 0.88, opacity))
	if game.manifest_select_stage == game.MANIFEST_STAGE_TRANSITION:
		game._draw_spectrum_reveal_fragments(center_x, center_y, card_w, card_h, spacing, game._manifest_transition_progress())

	var dots_y: float = carousel_rect.end.y + 10.0
	var total_w: float = active_items.size() * 14.0
	for i in range(active_items.size()):
		var x: float = center_x - total_w * 0.5 + i * 14.0
		game.draw_circle(Vector2(x, dots_y), 5.5 if i == active_selected else 3.0, accent if i == active_selected else Color(0.36, 0.52, 0.62, 0.42))

	var details: Dictionary = game._aura_details(String(item["name"])) if aura_view else game._manifestation_details(item["key"])
	var info_rect: Rect2 = Rect2(rect.position.x + 20.0, dots_y + 18.0, rect.size.x - 40.0, rect.end.y - dots_y - 32.0)
	game._draw_manifest_mp_compact_info(info_rect, item, details, aura_view, accent)


static func _draw_manifest_mp_team_panel(game: Node2D, rect: Rect2, accent: Color) -> void :
	game.draw_line(rect.position, Vector2(rect.position.x, rect.end.y), Color(accent, 0.32), 1.0)
	var local_state: Dictionary = {
		"stage": game.manifest_select_stage,
		"manifestation": game.selected_manifestation,
		"aura": game.selected_aura,
		"ready": game.mp_local_ready,
		"name": game.player_nickname if game.player_nickname != "" else "Voce"
	}
	var rows: Array = [{"peer_id": game._mp_unique_id(), "state": local_state, "local": true}]
	var peer_ids: Array = game.mp_manifest_state_by_peer.keys()
	peer_ids.sort()
	for peer_id_value in peer_ids:
		rows.append({"peer_id": int(peer_id_value), "state": game.mp_manifest_state_by_peer[peer_id_value], "local": false})
	if rows.size() == 1:
		rows.append({"peer_id": 0, "state": {"stage": game.mp_remote_manifest_stage, "manifestation": game.mp_remote_manifestation, "aura": game.mp_remote_aura, "ready": game.mp_remote_ready, "name": "Parceiro"}, "local": false})
	var ready_count: int = 0
	for row in rows:
		if bool(Dictionary(row["state"]).get("ready", false)):
			ready_count += 1
	game._draw_online_label("EQUIPE  %d/%d PRONTOS" % [ready_count, rows.size()], Rect2(rect.position + Vector2(16, 8), Vector2(rect.size.x - 32, 26)), 18, Color.WHITE)
	game._draw_online_label("Manifestacao + espectro", Rect2(rect.position + Vector2(16, 36), Vector2(rect.size.x - 32, 22)), 14, Color(0.64, 0.8, 0.83))
	var gap: float = 10.0
	var list_top: float = rect.position.y + 66.0
	var available_h: float = rect.end.y - list_top - 12.0
	var row_h: float = minf(112.0, (available_h - gap * float(maxi(0, rows.size() - 1))) / float(maxi(1, rows.size())))
	for i in range(rows.size()):
		if list_top + float(i) * (row_h + gap) + row_h > rect.end.y - 6.0:
			break
		var row_data: Dictionary = rows[i]
		game._draw_manifest_peer_summary_row(Rect2(rect.position.x + 12.0, list_top + float(i) * (row_h + gap), rect.size.x - 24.0, row_h), int(row_data["peer_id"]), Dictionary(row_data["state"]), bool(row_data["local"]))


static func _draw_manifest_peer_summary_row(game: Node2D, rect: Rect2, peer_id: int, state: Dictionary, is_local: = false) -> void :
	var stage = String(state.get("stage", game.MANIFEST_STAGE_MANIFESTATION))
	var aura_view = stage == game.MANIFEST_STAGE_AURA
	var manifest_idx: int = clampi(int(state.get("manifestation", 0)), 0, game.MANIFESTATIONS.size() - 1)
	var aura_idx: int = clampi(int(state.get("aura", 0)), 0, game.AURAS.size() - 1)
	var manifest_item: Dictionary = game.MANIFESTATIONS[manifest_idx]
	var aura_item: Dictionary = game.AURAS[aura_idx]
	var color: Color = game._manifest_select_item_color(aura_item, true) if aura_view else game._manifest_select_item_color(manifest_item, false)
	var manifest_color: Color = game._manifest_select_item_color(manifest_item, false)
	var aura_color: Color = game._manifest_select_item_color(aura_item, true)
	game.draw_rect(rect, Color(0.035, 0.06, 0.065, 0.96))
	game.draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), color)
	var icon_size: float = minf(rect.size.y - 28.0, 42.0)
	var icon_rect: Rect2 = Rect2(rect.position + Vector2(12, 10), Vector2(icon_size, icon_size))
	var manifest_icon: Texture2D = game._manifest_select_item_texture(manifest_item, false)
	var aura_icon: Texture2D = game._manifest_select_item_texture(aura_item, true)
	if manifest_icon != null:
		game._draw_texture_contain(manifest_icon, icon_rect, Color(1.0, 1.0, 1.0, 0.88))
	if aura_view and aura_icon != null:
		var aura_rect = Rect2(icon_rect.end - Vector2(icon_size * 0.52, icon_size * 0.52), Vector2(icon_size * 0.46, icon_size * 0.46))
		game._draw_holo_panel(aura_rect.grow(3.0), aura_color, true, 0.56)
		game._draw_texture_contain(aura_icon, aura_rect, Color.WHITE)
	var text_x: float = icon_rect.end.x + 10.0
	var text_w: float = rect.end.x - text_x - 14.0
	var player_label: String = String(state.get("name", "Player %d" % peer_id))
	if is_local:
		player_label += " (voce)"
	var line_h: float = (rect.size.y - 14.0) / 4.0
	game._draw_online_label(player_label, Rect2(text_x, rect.position.y + 5, text_w, line_h), 16, Color.WHITE)
	game._draw_online_label(String(manifest_item.get("name", "???")), Rect2(text_x, rect.position.y + 5 + line_h, text_w, line_h), 15, manifest_color)
	var aura_label: String = String(aura_item.get("name", "???")) if aura_view else "Espectro a escolher"
	game._draw_online_label(aura_label, Rect2(text_x, rect.position.y + 5 + line_h * 2, text_w, line_h), 14, aura_color if aura_view else Color(0.65, 0.76, 0.8))
	game._draw_online_label("PRONTO" if bool(state.get("ready", false)) else "ESCOLHENDO", Rect2(text_x, rect.position.y + 5 + line_h * 3, text_w, line_h), 12, Color(0.2, 1.0, 0.52) if bool(state.get("ready", false)) else Color(1.0, 0.82, 0.24))


static func _draw_manifest_mp_half(game: Node2D, rect: Rect2, stage: String, selected_manif: int, selected_aur: int, scroll: float, is_remote: bool, is_ready: bool) -> void :
	var aura_view = stage == game.MANIFEST_STAGE_AURA
	var active_items: Array = game.AURAS if aura_view else game.MANIFESTATIONS
	var active_selected = selected_aur if aura_view else selected_manif

	var item: Dictionary = active_items[active_selected]
	var color: Color = game._manifest_select_item_color(item, aura_view)

	var center_x = rect.position.x + rect.size.x * 0.5
	var center_y = rect.position.y + rect.size.y * 0.35
	var card_w = 110.0
	var card_h = 130.0
	var spacing = 120.0

	var title = "ESPECTRO" if aura_view else "MANIFESTACOES"
	var subtitle = "AGUARDANDO PARCEIRO..." if is_remote else ("SUA ESCOLHA: " + title)
	if is_ready: subtitle = "PRONTO!"

	var is_host_player = game.multiplayer.is_server() if game.multiplayer != null else game.is_host
	var side_is_host = is_host_player if not is_remote else not is_host_player
	var identity_str = "VOCE (" + ("HOST" if is_host_player else "CLIENT") + ")" if not is_remote else "PARCEIRO (" + ("HOST" if side_is_host else "CLIENT") + ")"

	game._draw_spectrum_title(title, Vector2(center_x, rect.position.y + 36), 24, color, 1.0)
	game._draw_centered(identity_str, Vector2(center_x, rect.position.y + 64), game._readable_text_size(14), Color(1, 0.84, 0.0) if side_is_host else Color(0.3, 0.8, 1.0))
	game._draw_centered(subtitle, Vector2(center_x, rect.position.y + 84), game._readable_text_size(11), color if is_ready else Color(0.72, 0.94, 1.0, 0.9))

	var half_size = active_items.size() / 2.0
	for i in range(active_items.size()):
		var diff = float(i) - scroll
		if diff > half_size: diff -= active_items.size()
		elif diff < - half_size: diff += active_items.size()

		var abs_diff = abs(diff)
		if abs_diff > 2.0: continue

		var scale = lerp(1.1, 0.7, min(abs_diff, 1.0))
		var opacity = lerp(1.0, 0.3, min(abs_diff, 1.0))

		var pos_x = center_x + diff * spacing
		var item_rect = Rect2(pos_x - card_w * scale * 0.5, center_y - card_h * scale * 0.5, card_w * scale, card_h * scale)

		var card_item = active_items[i]
		if not aura_view and not game._manifestation_unlocked(i): continue

		var item_color = game._manifest_select_item_color(card_item, aura_view)
		var taken = not is_remote and game._manifest_choice_taken(i, aura_view)
		if taken:
			item_color = Color(1.0, 0.18, 0.24)
		game._draw_holo_panel(item_rect, item_color, abs_diff < 0.5, opacity * 0.7)

		var icon: Texture2D = game._manifest_select_item_texture(card_item, aura_view)
		if icon:
			game._draw_texture_contain(icon, item_rect.grow(-15 * scale), Color(0.36, 0.36, 0.4, opacity) if taken else Color(1, 1, 1, opacity))
		if taken:
			game._draw_centered("EM USO", item_rect.get_center() + Vector2(0, 6), 13, Color(1.0, 0.86, 0.88))

	var details = game._aura_details(String(item["name"])) if aura_view else game._manifestation_details(item["key"])
	var details_rect = Rect2(rect.position.x + 8.0, rect.end.y - min(138.0, rect.size.y * 0.25), rect.size.x - 16.0, min(138.0, rect.size.y * 0.25))
	game._draw_manifest_mp_compact_info(details_rect, item, details, aura_view, color)

	if is_ready:
		game._draw_holo_panel(rect, Color(0, 1, 0), true, 0.1)

	if not is_remote:
		var btn_ready_rect = Rect2(rect.position.x + rect.size.x * 0.22, details_rect.position.y - 64.0, rect.size.x * 0.56, 46.0)
		game.buttons["mp_manifest_ready"] = btn_ready_rect
		var btn_label = "PRONTO" if aura_view else "REVELAR ESPECTRO"
		game._draw_big_button(btn_ready_rect, btn_label, Color(0.02, 0.14, 0.11, 0.88), color)


static func _draw_manifest_mp_compact_info(game: Node2D, rect: Rect2, item: Dictionary, details: Dictionary, aura_view: bool, accent: Color) -> void:
	var rows: Array = game._manifest_info_rows(item, details, aura_view)
	var count: int = mini(3, rows.size())
	var row_h: float = rect.size.y / float(maxi(1, count))
	for i in range(count):
		var row: Dictionary = rows[i]
		var y: float = rect.position.y + row_h * i
		game.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(accent, 0.3), 1.0)
		game._draw_online_label(String(row.get("label", row.get("title", "EFEITO"))), Rect2(rect.position.x + 4, y + 3, 88, row_h - 6), 14, accent)
		game._draw_online_label(String(row.get("text", item.get("desc", ""))), Rect2(rect.position.x + 96, y + 3, rect.size.x - 100, row_h - 6), 15, Color(0.9, 0.95, 0.97))


static func _draw_online_label(game: Node2D, text: String, rect: Rect2, size: int, color: Color) -> void:
	var label: String = text
	var label_size: int = size
	while label_size > 12 and game.menu_ui_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x > rect.size.x:
		label_size -= 1
	if game.menu_ui_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x > rect.size.x:
		while label.length() > 1 and game.menu_ui_font.get_string_size(label + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x > rect.size.x:
			label = label.left(-1)
		label += "..."
	var baseline: float = rect.position.y + (rect.size.y - game.menu_ui_font.get_height(label_size)) * 0.5 + game.menu_ui_font.get_ascent(label_size)
	game.draw_string(game.menu_ui_font, Vector2(rect.position.x, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, label_size, color)


static func _draw_manifest_select(game: Node2D, viewport: Vector2) -> void :

	game._draw_holo_background(viewport, null, Color(0.0, 1.0, 0.82))
	var portrait = game._is_portrait(viewport)


	var title_x = viewport.x * 0.5 if portrait else viewport.x * 0.28
	var title_y = 74 if portrait else 64
	var transition_t = game._manifest_transition_progress()
	var aura_view = game.manifest_select_stage == game.MANIFEST_STAGE_AURA or (game.manifest_select_stage == game.MANIFEST_STAGE_TRANSITION and transition_t >= 0.52)
	var title_manifest_alpha = 1.0 if game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION else 1.0 - smoothstep(0.0, 0.42, transition_t)
	var title_aura_alpha = 1.0 if aura_view else smoothstep(0.38, 1.0, transition_t)
	if title_manifest_alpha > 0.02:
		game._draw_spectrum_title("MANIFESTACOES", Vector2(title_x, title_y), 34, Color(0.0, 1.0, 0.82), title_manifest_alpha)
	if title_aura_alpha > 0.02:
		game._draw_spectrum_title("ESPECTRO", Vector2(title_x, title_y), 34, game._aura_color(), title_aura_alpha)
	var subtitle_text = "ESCOLHA A FORMA DA RUPTURA EM GEOVANA" if not aura_view and game.manifest_select_stage != game.MANIFEST_STAGE_TRANSITION else "ESCOLHA O ESTADO ESPECTRAL DA PERSONAGEM"
	game._draw_centered(subtitle_text, Vector2(title_x, title_y + 38), game._readable_text_size(12 if not portrait else 14), Color(0.72, 0.94, 1.0, 0.9))

	var active_items: Array = game.AURAS if aura_view else game.MANIFESTATIONS
	var active_scroll = game.aura_scroll_pos if aura_view else game.manifest_scroll_pos
	var active_selected = game.selected_aura if aura_view else game.selected_manifestation
	var item: Dictionary = active_items[active_selected]
	var selected_unlocked = game._manifest_select_item_unlocked(active_selected, aura_view)
	var color: Color = game._manifest_select_item_color(item, aura_view) if selected_unlocked else Color(0.42, 0.46, 0.68)


	var center_x = viewport.x * 0.5 if portrait else viewport.x * 0.28
	var center_y = viewport.y * 0.29 if portrait else viewport.y * 0.405
	var card_w = 136.0 if portrait else 154.0
	var card_h = 154.0 if portrait else 174.0
	var spacing = game._manifest_carousel_spacing(viewport)

	var half_size = active_items.size() / 2.0
	for i in range(active_items.size()):
		var diff = float(i) - active_scroll
		if diff > half_size:
			diff -= active_items.size()
		elif diff < - half_size:
			diff += active_items.size()

		var abs_diff = abs(diff)
		if abs_diff > 2.2:
			continue


		var scale = 1.15
		if abs_diff <= 1.0:
			scale = lerp(1.15, 0.85, abs_diff)
		else:
			scale = lerp(0.85, 0.65, clamp(abs_diff - 1.0, 0.0, 1.0))

		var opacity = 1.0
		if abs_diff <= 1.0:
			opacity = lerp(1.0, 0.45, abs_diff)
		else:
			opacity = lerp(0.45, 0.15, clamp(abs_diff - 1.0, 0.0, 1.0))

		var pos_x = center_x + diff * spacing
		var rect = Rect2(pos_x - card_w * scale * 0.5, center_y - card_h * scale * 0.5, card_w * scale, card_h * scale)


		var card_item: Dictionary = active_items[i]
		var item_unlocked = game._manifest_select_item_unlocked(i, aura_view)
		var item_color: Color = game._manifest_select_item_color(card_item, aura_view) if item_unlocked else Color(0.42, 0.46, 0.68)
		game._draw_holo_panel(rect, item_color, abs_diff < 0.5, opacity * 0.7)

		if abs_diff < 0.5:

			game._draw_energy_particles(rect, item_color, int(24 * (1.0 - abs_diff)))


		var icon: Texture2D = game._manifest_select_item_texture(card_item, aura_view)
		if not item_unlocked:
			game._draw_catalog_locked_card_icon(rect.grow(-26 * scale), false)
		elif icon:
			var icon_color = Color(1, 1, 1, opacity)
			game._draw_texture_contain(icon, rect.grow(-26 * scale), icon_color)


		var name_color = Color(1, 1, 1, opacity)
		var label_y = rect.end.y - (18 * scale)
		var display_name = String(card_item["name"]).to_upper() if item_unlocked else "???"
		game._draw_centered(display_name, Vector2(rect.get_center().x, label_y), game._readable_text_size(int(16 * scale)), name_color)

	if game.manifest_select_stage == game.MANIFEST_STAGE_TRANSITION:
		game._draw_spectrum_reveal_fragments(center_x, center_y, card_w, card_h, spacing, transition_t)


	var dots_y = center_y + (card_h * 0.65) + 10
	var total_w = active_items.size() * 18
	for i in range(active_items.size()):
		var x = center_x - total_w * 0.5 + i * 18
		game.draw_circle(Vector2(x, dots_y), 4 if i != active_selected else 7, color if i == active_selected else Color(0.38, 0.52, 0.62, 0.6 * (1.0 if i == active_selected else 0.5)))


	var details_rect: Rect2
	if portrait:
		details_rect = Rect2(viewport.x * 0.06, viewport.y * 0.48, viewport.x * 0.88, viewport.y * 0.38)
	else:
		details_rect = Rect2(viewport.x * 0.53, viewport.y * 0.145, viewport.x * 0.405, viewport.y * 0.67)

	var details = game._aura_details(String(item["name"])) if aura_view and selected_unlocked else (game._manifestation_details(item["key"]) if selected_unlocked else {})
	var panel_shake = game._spectrum_panel_shake()
	details_rect.position += panel_shake
	game._draw_holo_panel(details_rect, color, true, 0.42)


	var title_pos = details_rect.position + Vector2(20, 26)
	game.draw_string(game.font, title_pos, item["name"].to_upper() if selected_unlocked else "???", HORIZONTAL_ALIGNMENT_LEFT, -1, game._readable_text_size(22), color)
	var detail_caption = "ESPECTRO DA AUREA // ESTADO ATIVO" if aura_view else "NOME DE CODIGO // SINAL ESTAVEL"
	if not selected_unlocked:
		detail_caption = "REGISTRO BLOQUEADO // OBJETIVO PENDENTE"
	game.draw_string(game.font, title_pos + Vector2(0, 24), detail_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, game._readable_text_size(12), Color(0.5, 0.78, 0.86, 0.82))


	var line_y = title_pos.y + game._readable_text_size(22) + 16
	game.draw_line(Vector2(details_rect.position.x + 20, line_y), Vector2(details_rect.end.x - 20, line_y), Color(color.r, color.g, color.b, 0.26), 1)


	var current_y = line_y + 14
	var font_size = game._readable_text_size(11 if portrait else 12)
	var text_color = Color(0.8, 0.9, 0.95, 0.9)

	if selected_unlocked:
		current_y = game._draw_section_flow("FUNCAO", color, details["funcao"], text_color, current_y, details_rect, font_size)
		current_y = game._draw_section_flow("GATILHO" if aura_view else "DISPARO", color, details["disparo"], text_color, current_y, details_rect, font_size)
		var third_label = "EFEITO PRINCIPAL" if aura_view else "HABILIDADE ATIVA: " + String(details["habilidade"]).to_upper()
		current_y = game._draw_section_flow(third_label, color, details["desc_hab"], text_color, current_y, details_rect, font_size)

		var traco_risco_text = details["traco"] + " // Risco: " + details["risco"]
		current_y = game._draw_section_flow("TRACO E RISCO", color, traco_risco_text, text_color, current_y, details_rect, font_size)
	else:
		current_y = game._draw_section_flow("OBJETIVO", color, game._manifest_select_unlock_objective_text(active_selected, aura_view, true), text_color, current_y, details_rect, font_size)
		current_y = game._draw_section_flow("ARQUIVO", color, "Nome, imagem e detalhes permanecem lacrados ate cumprir o desafio.", text_color, current_y, details_rect, font_size)

	var aura_item: Dictionary = game.AURAS[game.selected_aura]
	var aura_color = game._aura_color()
	var aura_rect = Rect2(details_rect.position.x + 18.0, details_rect.end.y - 62.0, details_rect.size.x - 36.0, 46.0)
	game._draw_combat_panel(aura_rect, aura_color if aura_view else color, 0.52)
	game.buttons.erase("aura_prev")
	game.buttons.erase("aura_next")
	if aura_view:
		game.buttons["aura_prev"] = Rect2(aura_rect.position, Vector2(44.0, aura_rect.size.y))
		game.buttons["aura_next"] = Rect2(aura_rect.end - Vector2(44.0, aura_rect.size.y), Vector2(44.0, aura_rect.size.y))
		game._draw_centered("<", game.buttons["aura_prev"].get_center() + Vector2(0, 5), 24, aura_color)
		game._draw_centered(">", game.buttons["aura_next"].get_center() + Vector2(0, 5), 24, aura_color)
		game._draw_centered("ESPECTRO // " + String(aura_item["name"]).to_upper(), aura_rect.get_center() + Vector2(0, -6), game._readable_text_size(14), aura_color)
		game._draw_wrapped(String(game.MANIFESTATIONS[game.selected_manifestation]["name"]).to_upper() + " vinculada a esta aurea", Rect2(aura_rect.position + Vector2(48, 24), Vector2(aura_rect.size.x - 96, 18)), game._readable_text_size(8), Color(0.84, 0.91, 0.94, 0.86))
	else:
		if selected_unlocked:
			game._draw_centered("PROXIMO: REVELAR ESPECTRO", aura_rect.get_center() + Vector2(0, -6), game._readable_text_size(14), aura_color)
			game._draw_wrapped("Depois da manifestacao, escolha a aurea que define o estado da Geovana.", Rect2(aura_rect.position + Vector2(16, 24), Vector2(aura_rect.size.x - 32, 18)), game._readable_text_size(8), Color(0.84, 0.91, 0.94, 0.86))
		else:
			game._draw_centered("BLOQUEADO", aura_rect.get_center() + Vector2(0, -6), game._readable_text_size(14), color)
			game._draw_wrapped(game._manifest_select_unlock_objective_text(active_selected, aura_view, false), Rect2(aura_rect.position + Vector2(16, 24), Vector2(aura_rect.size.x - 32, 18)), game._readable_text_size(8), Color(0.84, 0.91, 0.94, 0.86))


	var detail_clean_rect = Rect2(details_rect.position - Vector2(8.0, 8.0), Vector2(details_rect.size.x + 16.0, viewport.y - details_rect.position.y - 78.0))
	game.draw_rect(detail_clean_rect, Color(0.0, 0.0, 0.0, 1.0), true)
	if selected_unlocked:
		game._draw_manifest_info_panel(details_rect, item, details, aura_view, color)
	else:
		game._draw_holo_panel(details_rect, color, true, 0.46)
		game._draw_catalog_locked_card_icon(Rect2(details_rect.position + Vector2(26, 86), Vector2(minf(150.0, details_rect.size.x * 0.32), minf(150.0, details_rect.size.y * 0.32))), true)
		var lock_text_rect = Rect2(details_rect.position + Vector2(206, 92), Vector2(details_rect.size.x - 232, 120))
		if portrait:
			lock_text_rect = Rect2(details_rect.position + Vector2(26, 210), Vector2(details_rect.size.x - 52, 92))
		game._draw_wrapped(game._manifest_select_unlock_objective_text(active_selected, aura_view, true), lock_text_rect, game._readable_text_size(12), Color(0.84, 0.91, 0.98, 0.92))

	var button_y = viewport.y - 72
	var btn_w = 200.0
	var btn_h = 44.0
	var btn_start_rect: Rect2
	var btn_back_rect: Rect2
	var btn_preview_rect: Rect2
	var btn_details_rect: Rect2

	if portrait:
		var py = viewport.y - 82
		var pw = viewport.x * 0.4
		var ph = 52.0
		btn_start_rect = Rect2(viewport.x * 0.08, py, pw, ph)
		btn_back_rect = Rect2(viewport.x * 0.52, py, pw, ph)
		btn_preview_rect = Rect2(viewport.x * 0.08, py - 54.0, viewport.x * 0.4, 40.0)
		btn_details_rect = Rect2(viewport.x * 0.52, py - 54.0, viewport.x * 0.4, 40.0)
	else:
		btn_start_rect = Rect2(viewport.x * 0.1, button_y, btn_w, btn_h)
		btn_back_rect = Rect2(viewport.x * 0.1 + 220, button_y, btn_w, btn_h)
		btn_preview_rect = Rect2(viewport.x * 0.1 + 440, button_y, 172.0, btn_h)
		btn_details_rect = Rect2(viewport.x * 0.1 + 632.0, button_y, 172.0, btn_h)


	game.buttons["manifest_start"] = btn_start_rect
	game.buttons["manifest_back"] = btn_back_rect
	game.buttons.erase("manifest_preview")
	game.buttons.erase("manifest_details")
	game.buttons.erase("manifest_preview_popup")
	game.buttons.erase("manifest_details_popup")
	game.buttons.erase("manifest_details_close")
	if not aura_view and game.manifest_select_stage == game.MANIFEST_STAGE_MANIFESTATION and selected_unlocked:
		game.buttons["manifest_preview"] = btn_preview_rect
		game.buttons["manifest_details"] = btn_details_rect

	var start_label = "INICIAR" if aura_view else "REVELAR ESPECTRO"
	if not selected_unlocked:
		start_label = "BLOQUEADO"
	var start_accent = (aura_color if aura_view else Color(0.0, 1.0, 0.82)) if selected_unlocked else Color(0.48, 0.52, 0.68)
	game._draw_big_button(btn_start_rect, start_label, Color(0.02, 0.14, 0.11, 0.88), start_accent)
	game._draw_big_button(btn_back_rect, "VOLTAR", Color(0.12, 0.04, 0.05, 0.88), Color(1.0, 0.28, 0.34))
	if game.buttons.has("manifest_preview"):
		game._draw_big_button(btn_preview_rect, "PREVIEW", Color(0.04, 0.1, 0.16, 0.88), color)
	if game.buttons.has("manifest_details"):
		game._draw_big_button(btn_details_rect, "DETALHES", Color(0.05, 0.08, 0.12, 0.88), color)
	if game.manifest_preview_open:
		game._draw_manifest_preview_popup(viewport, game.MANIFESTATIONS[game.selected_manifestation])
	if game.manifest_details_open:
		game._draw_manifest_details_popup(viewport, game.MANIFESTATIONS[game.selected_manifestation])


static func _draw_manifest_preview_popup(game: Node2D, viewport: Vector2, item: Dictionary) -> void :
	var portrait = game._is_portrait(viewport)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.56), true)

	var popup_size = Vector2(min(viewport.x * 0.88, 1100.0), min(viewport.y * 0.88, 640.0))
	if portrait:
		popup_size = Vector2(viewport.x * 0.94, viewport.y * 0.88)
	var popup = Rect2(viewport * 0.5 - popup_size * 0.5, popup_size)
	game.buttons["manifest_preview_popup"] = popup

	var accent: Color = item.get("color", Color(0.0, 1.0, 0.82))
	game._draw_holo_panel(popup, accent, true, 0.88)
	game.draw_rect(popup.grow(-10.0), Color(0.0, 0.0, 0.0, 0.22), true)

	game._draw_centered("PREVIEW // " + String(item["name"]).to_upper(), popup.position + Vector2(popup.size.x * 0.5, 28.0), game._readable_text_size(18), accent)

	var tab_y = popup.position.y + 52.0
	var tab_w = min(124.0, popup.size.x * 0.25)
	var tab_h = 36.0
	var tab_gap = 10.0
	var tab_total = tab_w * 3.0 + tab_gap * 2.0
	var tab_x = popup.position.x + popup.size.x * 0.5 - tab_total * 0.5
	var tabs = [
		{"label": "ATK", "kind": "atk"}, 
		{"label": "Q", "kind": "skill"}, 
		{"label": "E", "kind": "ultimate"}
	]
	for i in range(tabs.size()):
		var tab: Dictionary = tabs[i]
		var rect = Rect2(tab_x + i * (tab_w + tab_gap), tab_y, tab_w, tab_h)
		game.buttons["manifest_preview_" + String(tab["kind"])] = rect
		var selected = game.manifest_preview_kind == String(tab["kind"])
		game._draw_holo_panel(rect, accent if selected else Color(0.34, 0.52, 0.62), selected, 0.56)
		game._draw_centered(String(tab["label"]), rect.get_center() + Vector2(0, 4), game._readable_text_size(13), Color.WHITE if selected else Color(0.72, 0.84, 0.9, 0.78))

	var video_rect = popup.grow(-28.0)
	video_rect.position.y = tab_y + tab_h + 10.0
	video_rect.size.y = popup.end.y - video_rect.position.y - 46.0
	game._draw_manifest_preview_scene(video_rect, item, game._manifest_preview_tab_label(game.manifest_preview_kind), game.manifest_preview_kind, game.manifest_preview_time, accent, true)
	game._draw_centered("TOQUE NA JANELA PARA FECHAR", popup.position + Vector2(popup.size.x * 0.5, popup.size.y - 24.0), game._readable_text_size(10), Color(0.86, 0.94, 1.0, 0.7))


static func _draw_manifest_details_popup(game: Node2D, viewport: Vector2, item: Dictionary) -> void :
	var portrait = game._is_portrait(viewport)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.58), true)
	var popup_size = Vector2(min(viewport.x * 0.9, 980.0), min(viewport.y * 0.88, 620.0))
	if portrait:
		popup_size = Vector2(viewport.x * 0.94, viewport.y * 0.88)
	var popup = Rect2(viewport * 0.5 - popup_size * 0.5, popup_size)
	game.buttons["manifest_details_popup"] = popup
	var accent: Color = item.get("color", Color(0.0, 1.0, 0.82))
	game._draw_holo_panel(popup, accent, true, 0.9)
	game.draw_rect(popup.grow(-10.0), Color(0.0, 0.0, 0.0, 0.3), true)

	var close_rect = Rect2(popup.end - Vector2(58.0, popup.size.y - 16.0), Vector2(40.0, 32.0))
	game.buttons["manifest_details_close"] = close_rect
	game._draw_holo_panel(close_rect, Color(1.0, 0.24, 0.32), false, 0.72)
	game._draw_centered("X", close_rect.get_center() + Vector2(0, 5), game._readable_text_size(16), Color.WHITE)

	game._draw_centered("DETALHES // " + String(item["name"]).to_upper(), popup.position + Vector2(popup.size.x * 0.5, 30.0), game._readable_text_size(20), accent)
	game._draw_wrapped(String(item.get("desc", "")), Rect2(popup.position + Vector2(34.0, 56.0), Vector2(popup.size.x - 68.0, 48.0)), game._readable_text_size(13), Color(0.86, 0.95, 1.0, 0.9))

	var details = game._manifestation_details(String(item.get("key", "")))
	var content = popup.grow(-32.0)
	content.position.y += 102.0
	content.size.y -= 138.0
	var y = content.position.y
	var fs = game._readable_text_size(12 if portrait else 13)
	var body = Color(0.82, 0.92, 0.96, 0.92)
	y = game._draw_section_flow("FUNCAO", accent, String(details.get("funcao", "")), body, y, content, fs)
	y = game._draw_section_flow("ATK", accent, String(details.get("disparo", "")), body, y, content, fs)
	y = game._draw_section_flow(String(details.get("habilidade", "Q")), accent, String(details.get("desc_hab", "")), body, y, content, fs)
	y = game._draw_section_flow("E / TRACO", accent, String(details.get("traco", "")), body, y, content, fs)
	y = game._draw_section_flow("RISCO / TP", accent, String(details.get("risco", "")), body, y, content, fs)
	var rows: Array = details.get("info_rows", [])
	for row in rows:
		if y > content.end.y - 38.0:
			break
		y = game._draw_section_flow(String(row.get("label", "INFO")), accent, String(row.get("text", "")), body, y, content, fs - 1)
	game._draw_centered("TOQUE FORA OU NO X PARA FECHAR", popup.position + Vector2(popup.size.x * 0.5, popup.size.y - 24.0), game._readable_text_size(10), Color(0.86, 0.94, 1.0, 0.7))


static func _draw_manifest_preview_scene(game: Node2D, rect: Rect2, item: Dictionary, label: String, kind: String, t: float, accent: Color, large: = false) -> void :
	game._draw_combat_panel(rect, accent, 0.56)
	game.draw_rect(rect.grow(-7.0), Color(accent.r, accent.g, accent.b, 0.045), true)
	game.draw_string(game.font, rect.position + Vector2(16.0, 30.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, game._readable_text_size(16 if large else 14), accent)
	var scene = rect.grow(-20.0 if large else -18.0)
	scene.position.y += 36.0 if large else 24.0
	scene.size.y -= 44.0 if large else 24.0
	var key = String(item["key"])
	var title = "DISPARO" if kind == "atk" else ("SEGUNDA HABILIDADE" if kind == "skill" else "ULTIMATE")
	game._draw_centered(title, Vector2(rect.get_center().x, rect.end.y - 17.0), game._readable_text_size(10 if large else 8), Color(0.82, 0.92, 0.98, 0.66))
	if game._draw_manifest_preview_atlas(scene, key, kind, t):
		return
	match kind:
		"atk":
			game._draw_manifest_preview_atk(scene, key, t, accent)
		"skill":
			game._draw_manifest_preview_skill(scene, key, t, accent)
		_:
			game._draw_manifest_preview_ultimate(scene, key, t, accent)


static func _draw_manifest_preview_atlas(game: Node2D, rect: Rect2, key: String, kind: String, t: float) -> bool:
	if game.preview_capture_mode:
		return false
	var texture = game._manifest_preview_atlas(key, kind)
	if texture == null:
		return false
	var frame = posmod(int(floor(t * game.MANIFEST_PREVIEW_FPS)), game.MANIFEST_PREVIEW_FRAME_COUNT)
	var frame_w = texture.get_width() / game.MANIFEST_PREVIEW_ATLAS_COLS
	var frame_h = texture.get_height() / game._manifest_preview_atlas_rows(texture)
	if frame_w <= 0 or frame_h <= 0:
		return false
	var col = frame % game.MANIFEST_PREVIEW_ATLAS_COLS
	var row = frame / game.MANIFEST_PREVIEW_ATLAS_COLS
	var src = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
	var dst = game._contain_rect(Vector2(frame_w, frame_h), rect)
	game.draw_rect(rect, Color(0.0, 0.0, 0.0, 0.42), true)
	game.draw_texture_rect_region(texture, dst, src, Color.WHITE)
	game.draw_rect(dst, Color(1.0, 1.0, 1.0, 0.16), false, 1.0)
	return true


static func _draw_manifest_preview_atk(game: Node2D, rect: Rect2, key: String, t: float, accent: Color) -> void :
	var p = Vector2(rect.position.x + rect.size.x * 0.23, rect.get_center().y + rect.size.y * 0.18)
	var e = Vector2(rect.end.x - rect.size.x * 0.18, rect.get_center().y - rect.size.y * 0.1)
	game._draw_preview_geovana(p, rect.size.y * 0.16, accent)
	game._draw_preview_enemy(e, rect.size.y * 0.13, accent)
	var pulse = 0.5 + 0.5 * sin(t * TAU)
	match key:
		"eletrica":
			game._draw_preview_bolt(p + Vector2(20, -8), e - Vector2(16, 0), accent, t, 3.0)
			game.draw_circle(e, 22.0 + pulse * 8.0, Color(0.55, 0.95, 1.0, 0.12))
		"lacerante":
			for i in range(3):
				var off = Vector2(lerp(8.0, rect.size.x * 0.48, pulse), -18.0 + i * 18.0)
				game._draw_preview_slash(p + off, -0.22 + i * 0.12, rect.size.x * 0.34, Color(1.0, 0.08, 0.14, 0.88), 4.0 - i)
		"prismatica":
			var beam_end = e - Vector2(16, 0)
			game.draw_line(p + Vector2(22, -8), beam_end, Color(accent.r, accent.g, accent.b, 0.38), 8.0)
			game.draw_line(p + Vector2(22, -8), beam_end, Color(1.0, 1.0, 1.0, 0.8), 2.0)
			game.draw_circle(beam_end, 12.0 + pulse * 8.0, Color(1.0, 0.42, 0.88, 0.32))
		"retornante":
			var mid = p.lerp(e, 0.52) + Vector2(0, -34.0 * sin(t * TAU))
			game.draw_arc(mid, rect.size.x * 0.21, PI * 0.15, PI * 1.18, 42, Color(accent.r, accent.g, accent.b, 0.6), 3.0)
			game.draw_circle(p.lerp(e, fposmod(t * 0.6, 1.0)), 8.0, Color(1.0, 0.48, 0.84, 0.9))
			game.draw_circle(e.lerp(p, fposmod(t * 0.8 + 0.35, 1.0)), 6.0, Color(0.82, 0.7, 1.0, 0.8))
		"parasitica":
			var worm = p.lerp(e, fposmod(t * 0.75, 1.0))
			game._draw_preview_worm_path(p + Vector2(18, 0), e - Vector2(16, 0), t, accent)
			game.draw_circle(worm, 7.0, Color(0.72, 1.0, 0.3, 0.88))
			game.draw_circle(e + Vector2(0, 14), 16.0, Color(0.2, 0.92, 0.22, 0.18))
		"gravitante":
			var orb = p.lerp(e, fposmod(t * 0.55, 1.0))
			game.draw_circle(orb, 12.0, Color(0.15, 0.45, 1.0, 0.34))
			game.draw_arc(orb, 18.0, - t * TAU, - t * TAU + PI * 1.3, 32, accent, 2.0)
			game.draw_line(orb, e, Color(0.66, 0.88, 1.0, 0.26), 2.0)
		"acorrentada":
			var step = int(fposmod(floor(t * 3.0), 3.0)) + 1
			if step == 1:
				game._draw_acorrentada_chain(p + Vector2(18, -4), e - Vector2(14, 0), Color(0.18, 0.86, 1.0, 0.86), 5.0, 1.0, true)
			elif step == 2:
				game.draw_arc(p, rect.size.x * 0.34, -0.65, 0.75, 42, Color(0.92, 0.12, 0.1, 0.68), 6.0)
				game._draw_acorrentada_chain(p + Vector2(20, 8), e - Vector2(8, 8), Color(0.92, 0.12, 0.1, 0.84), 8.0, 1.0, false)
			else:
				game._draw_acorrentada_chain(p + Vector2(16, -22), e + Vector2(-10, 18), Color(0.18, 0.86, 1.0, 0.84), 6.0, 1.0, true)
				game._draw_acorrentada_chain(p + Vector2(16, 22), e + Vector2(-10, -18), Color(0.92, 0.12, 0.1, 0.84), 8.0, 1.0, false)
				game.draw_circle(e, 18.0 + pulse * 7.0, Color(1.0, 1.0, 1.0, 0.24))
		"eclipsada":
			var step = int(fposmod(floor(t * 4.0), 4.0)) + 1
			var slash_center: Vector2 = p + Vector2(54.0, -8.0)
			var slash_angle: float = -0.9 + pulse * 1.8 + float(step) * 0.34
			game.draw_circle(slash_center, 80.0, Color(0.06, 0.2, 0.48, 0.1))
			game.draw_arc(slash_center, 80.0, slash_angle, slash_angle + PI * 1.38, 54, Color(accent.r, accent.g, accent.b, 0.88), 7.0 if step == 4 else 5.0)
			game.draw_arc(slash_center, 72.0, slash_angle + 0.12, slash_angle + PI * 1.22, 48, Color(0.9, 0.98, 1.0, 0.78), 2.0)
			if step == 4:
				game.draw_arc(slash_center, 54.0, - slash_angle, TAU - slash_angle, 48, Color(1.0, 0.86, 0.3, 0.68), 3.0)
		_:
			game.draw_line(p + Vector2(20, 0), e - Vector2(16, 0), Color(accent.r, accent.g, accent.b, 0.7), 5.0)
			game.draw_circle(e, 17.0 + pulse * 5.0, Color(1.0, 0.78, 0.26, 0.2))


static func _draw_manifest_preview_skill(game: Node2D, rect: Rect2, key: String, t: float, accent: Color) -> void :
	var c = rect.get_center()
	var p = c + Vector2( - rect.size.x * 0.24, rect.size.y * 0.16)
	var e1 = c + Vector2(rect.size.x * 0.2, - rect.size.y * 0.12)
	var e2 = c + Vector2(rect.size.x * 0.3, rect.size.y * 0.22)
	game._draw_preview_geovana(p, rect.size.y * 0.15, accent)
	game._draw_preview_enemy(e1, rect.size.y * 0.11, accent)
	game._draw_preview_enemy(e2, rect.size.y * 0.1, accent)
	var pulse = 0.5 + 0.5 * sin(t * TAU)
	match key:
		"eletrica":
			for i in range(3):
				game.draw_arc(p, 34.0 + i * 18.0 + pulse * 6.0, 0.0, TAU, 64, Color(0.44, 0.96, 1.0, 0.42 - i * 0.09), 2.0)
			game._draw_preview_bolt(p, e1, accent, t, 2.0)
			game._draw_preview_bolt(p, e2, accent, t + 0.3, 2.0)
		"lacerante":
			game.draw_arc(p, 52.0 + pulse * 10.0, - PI * 0.1, PI * 1.7, 72, Color(1.0, 0.08, 0.14, 0.76), 5.0)
			for i in range(5):
				game._draw_preview_slash(p + Vector2.from_angle(t * TAU + i) * (30.0 + i * 3.0), t + i * 0.35, 48.0, Color(1.0, 0.12, 0.2, 0.76), 2.5)
		"prismatica":
			var prism = c + Vector2(10, 0)
			game._draw_preview_diamond(prism, 24.0 + pulse * 3.0, accent)
			for angle in [-0.7, 0.0, 0.7, 1.35, -1.35]:
				game.draw_line(prism, prism + Vector2.from_angle(angle) * rect.size.x * 0.28, Color(accent.r, accent.g, accent.b, 0.48), 4.0)
		"retornante":
			for i in range(4):
				var r = 28.0 + i * 13.0 + pulse * 4.0
				game.draw_arc(c, r, t * TAU + i, t * TAU + i + PI * 1.25, 48, Color(accent.r, accent.g, accent.b, 0.42 - i * 0.06), 2.0)
			game.draw_circle(c, 10.0 + pulse * 5.0, Color(1.0, 0.38, 0.7, 0.42))
		"parasitica":
			game.draw_circle(c + Vector2(8, 10), 58.0 + pulse * 6.0, Color(0.16, 0.75, 0.18, 0.18))
			for i in range(8):
				var a = t * TAU + i * TAU / 8.0
				var worm = c + Vector2(cos(a) * 44.0, sin(a * 1.7) * 18.0 + 10.0)
				game.draw_circle(worm, 5.0 + float(i % 2), Color(0.75, 1.0, 0.28, 0.82))
		"gravitante":
			game._draw_preview_enemy(e1 + (c - e1).normalized() * pulse * 28.0, rect.size.y * 0.1, accent)
			game._draw_preview_enemy(e2 + (c - e2).normalized() * pulse * 28.0, rect.size.y * 0.1, accent)
			game.draw_line(e1, e2, Color(0.64, 0.88, 1.0, 0.46), 3.0)
			game.draw_circle(c, 24.0 + pulse * 12.0, Color(0.12, 0.28, 0.72, 0.24))
		"acorrentada":
			game._draw_acorrentada_chain(e1, e2, Color(0.18, 0.86, 1.0, 0.82), 6.0, 1.0, true)
			game._draw_acorrentada_chain(p + Vector2(10, -4), e1, Color(0.92, 0.12, 0.1, 0.7), 7.0, 1.0, false)
			game.draw_arc(e1.lerp(e2, 0.5), 26.0 + pulse * 9.0, 0.0, TAU, 36, Color(1.0, 0.24, 0.18, 0.42), 2.4)
		"eclipsada":
			var dash_end: Vector2 = p + Vector2(52.0, -18.0)
			game.draw_rect(rect, Color(0.02, 0.16, 0.38, 0.12), true)
			game.draw_line(p - Vector2(42, 0), dash_end + Vector2(34, 0), Color(0.04, 0.1, 0.28, 0.72), 24.0, true)
			game.draw_line(p - Vector2(42, 0), dash_end + Vector2(34, 0), Color(accent.r, accent.g, accent.b, 0.82), 5.0, true)
			for enemy_pos in [e1, e2]:
				game.draw_arc(enemy_pos + Vector2(8, -8), 18.0 + pulse * 5.0, - t * TAU, TAU - t * TAU, 30, Color(1.0, 0.88, 0.3, 0.88), 2.5)
				game.draw_line(enemy_pos + Vector2(0, -8), enemy_pos + Vector2(16, -8), Color(0.92, 0.98, 1.0, 0.78), 1.5)
		_:
			game.draw_arc(p, 58.0 + pulse * 7.0, 0.0, TAU, 72, Color(accent.r, accent.g, accent.b, 0.54), 3.0)
			game.draw_line(p, e1, Color(1.0, 0.8, 0.26, 0.46), 3.0)


static func _draw_effects(game: Node2D, camera: Vector2) -> void :
	var draw_cap: int = game.MEMORY_EFFECT_DRAW_CAP if game._memory_saver_active() else (game.MOBILE_EFFECT_DRAW_CAP if game._runtime_visual_budget_active() else 999999)
	var drawn: int = 0
	for effect in (game.effects + game.net_effects):
		if drawn >= draw_cap:
			break
		var effect_world_pos: Vector2 = Vector2(effect.get("pos", Vector2.ZERO))
		if not game._world_point_in_view(effect_world_pos, camera, 160.0):
			continue
		drawn += 1
		var alpha = clamp(float(effect["life"]) / float(effect["max"]), 0.0, 1.0)
		var color: Color = effect["color"]
		color.a = alpha
		var kind = String(effect.get("kind", ""))
		if String(effect.get("text", "")) != "":
			game._draw_centered(effect["text"], effect["pos"] - camera, int(effect["size"]), color)
		elif kind == "enemy_shard":
			var pos = effect["pos"] - camera
			var size = float(effect["size"]) * (0.72 + alpha * 0.65)
			var phase = float(effect.get("phase", 0.0))
			var tip = Vector2.from_angle(phase) * size
			var side = Vector2.from_angle(phase + PI * 0.5) * size * 0.62
			var points = PackedVector2Array([
				pos + tip, 
				pos + side, 
				pos - tip, 
				pos - side
			])
			game.draw_polygon(points, PackedColorArray([Color(color.r, color.g, color.b, alpha * 0.92)]))
			game.draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(1.0, 1.0, 1.0, alpha * 0.75), 1.5, true)
			game.draw_circle(pos, size * 0.34, Color(1.0, 1.0, 1.0, alpha * 0.85))
		elif kind == "trail":
			var p = effect["pos"] - camera
			var radius = float(effect["size"]) * alpha
			game.draw_circle(p, radius, color)
			game.draw_circle(p, radius * 1.8, Color(color.r, color.g, color.b, alpha * 0.2))
			if effect.has("vel"):
				var vel: Vector2 = effect["vel"]
				if vel.length() > 4.0:
					game.draw_line(p - vel.normalized() * radius * 1.6, p, Color(1.0, 1.0, 1.0, alpha * 0.7), max(1.0, radius * 0.34))
		elif kind == "spark":
			var p = effect["pos"] - camera
			var r = float(effect["size"]) * alpha
			game.draw_line(p - effect["vel"].normalized() * r * 2.0, p + effect["vel"].normalized() * r * 2.0, color, r)
			game.draw_circle(p, r * 1.5, Color(1, 1, 1, alpha))
		elif kind == "slash_mark":
			var p = effect["pos"] - camera
			var r = float(effect["size"]) * alpha
			var a = float(effect.get("angle", 0.0))
			game.draw_line(p - Vector2.from_angle(a) * r * 3.0, p + Vector2.from_angle(a) * r * 3.0, color, r * 0.8)
			game.draw_line(p - Vector2.from_angle(a) * r * 1.5, p + Vector2.from_angle(a) * r * 1.5, Color(1, 1, 1, alpha), r * 0.4)
		elif kind == "shard":
			var p = effect["pos"] - camera
			var r = float(effect["size"]) * alpha
			var rot = float(effect.get("rot", 0.0))
			game.draw_set_transform(p, rot * (1.0 - alpha), Vector2.ONE)
			game.draw_rect(Rect2(Vector2( - r, - r), Vector2(r * 2, r * 2)), color, true)
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif kind == "bullet_fragment":
			var p: Vector2 = Vector2(effect["pos"]) - camera
			var r: float = maxf(1.0, float(effect["size"]) * (0.45 + alpha))
			var angle: float = float(effect.get("phase", 0.0))
			var forward: Vector2 = Vector2.from_angle(angle) * r * 2.2
			var side: Vector2 = Vector2.from_angle(angle + PI * 0.5) * r * 0.62
			var points = PackedVector2Array([p + forward, p + side, p - forward * 0.48, p - side])
			game.draw_circle(p, r * 2.4, Color(color.r, color.g, color.b, alpha * 0.18))
			game.draw_polygon(points, PackedColorArray([Color(color.r, color.g, color.b, alpha * 0.92)]))
			game.draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(1.0, 1.0, 1.0, alpha * 0.78), 1.2, true)
		elif kind == "landing_smoke":
			var p: Vector2 = Vector2(effect["pos"]) - camera
			var growth: float = 1.0 - alpha
			var r: float = float(effect["size"]) * (0.72 + growth * 1.85)
			game.draw_set_transform(p, float(effect.get("phase", 0.0)) * 0.08, Vector2(1.0, 0.34))
			game.draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, alpha * 0.46))
			game.draw_arc(Vector2.ZERO, r * 1.08, PI * 0.08, PI * 1.72, 14, Color(0.95, 1.0, 0.96, alpha * 0.28), 1.4)
			game.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif kind == "bit":
			var p = effect["pos"] - camera
			var r = float(effect["size"]) * alpha
			game.draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2, r * 2)), color, false, max(1.0, r * 0.5))
			game.draw_rect(Rect2(p - Vector2(r * 0.5, r * 0.5), Vector2(r, r)), Color(1, 1, 1, alpha), true)
		else:
			game.draw_circle(effect["pos"] - camera, float(effect["size"]) * alpha, color)


static func _draw_unlock_notifications(game: Node2D, viewport: Vector2) -> void :
	if game.unlock_notifications.is_empty():
		return
	var base_width: float = min(680.0, max(360.0, viewport.x * 0.58))
	var panel_height: float = 88.0
	var t: float = float(Time.get_ticks_msec()) * 0.001
	for i in range(game.unlock_notifications.size()):
		var notice: Dictionary = game.unlock_notifications[i]
		var life: float = float(notice.get("life", 0.0))
		var max_life: float = max(0.01, float(notice.get("max", game.UNLOCK_NOTIFICATION_LIFETIME)))
		var age: float = float(notice.get("age", max_life - life))
		var enter: float = smoothstep(0.0, game.UNLOCK_NOTIFICATION_ENTER_TIME, age)
		var exit: float = smoothstep(0.0, game.UNLOCK_NOTIFICATION_EXIT_TIME, game.UNLOCK_NOTIFICATION_EXIT_TIME - life)
		var visibility: float = clampf(enter * (1.0 - exit), 0.0, 1.0)
		if visibility <= 0.01:
			continue
		var rect = Rect2(Vector2((viewport.x - base_width) * 0.5, lerpf(-panel_height - 24.0, 26.0 + float(i) * (panel_height + 10.0), visibility)), Vector2(base_width, panel_height))
		var accent: Color = notice.get("accent", Color(0.12, 0.82, 1.0))
		var alpha: float = visibility
		var glow: Rect2 = rect.grow(10.0 + sin(t * 8.0 + float(i)) * 2.0)
		game.draw_rect(glow, Color(accent.r, accent.g, accent.b, 0.045 * alpha), true)
		game.draw_rect(rect, Color(0.006, 0.018, 0.034, 0.56 * alpha), true)
		game.draw_rect(rect.grow(-4.0), Color(accent.r, accent.g, accent.b, 0.035 * alpha), true)
		game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.9 * alpha), false, 2.5)
		game.draw_rect(rect.grow(-5.0), Color(0.72, 0.95, 1.0, 0.18 * alpha), false, 1.0)
		var icon_rect = Rect2(rect.position + Vector2(16.0, 14.0), Vector2(60.0, 60.0))
		game.draw_rect(icon_rect.grow(5.0), Color(0.0, 0.12, 0.18, 0.5 * alpha), true)
		game.draw_rect(icon_rect.grow(5.0), Color(accent.r, accent.g, accent.b, 0.75 * alpha), false, 1.5)
		var icon_texture: Texture2D = notice.get("icon", null)
		game._draw_texture_contain(icon_texture, icon_rect, Color(1.0, 1.0, 1.0, alpha))
		var text_x: float = icon_rect.end.x + 18.0
		var title_color: Color = Color(0.58, 0.94, 1.0, 0.86 * alpha)
		var name_color: Color = Color(1.0, 1.0, 1.0, alpha)
		var challenge_color: Color = Color(0.24, 0.94, 1.0, 0.92 * alpha)
		game.draw_string(game.font, Vector2(text_x, rect.position.y + 24.0), String(notice.get("title", "DESBLOQUEIO CONCLUIDO")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 110.0, game._readable_text_size(12), title_color)
		game.draw_string(game.font, Vector2(text_x, rect.position.y + 51.0), String(notice.get("name", "NOVO ITEM")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 116.0, game._readable_text_size(21), name_color)
		game.draw_string(game.font, Vector2(text_x, rect.position.y + 75.0), String(notice.get("challenge", "Desafio concluido")), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 124.0, game._readable_text_size(13), challenge_color)
		var tag_rect = Rect2(rect.end - Vector2(134.0, 29.0), Vector2(114.0, 18.0))
		game.draw_rect(tag_rect, Color(0.0, 0.12, 0.2, 0.58 * alpha), true)
		game.draw_rect(tag_rect, Color(0.58, 0.94, 1.0, 0.48 * alpha), false, 1.0)
		game._draw_centered("NOVO", tag_rect.get_center() + Vector2(0.0, 4.0), game._readable_text_size(10), Color(0.76, 0.98, 1.0, alpha))
		game._draw_unlock_electric_border(rect, accent, alpha, t + float(notice.get("seed", 0)) * 0.001)


static func _draw_unlock_electric_border(game: Node2D, rect: Rect2, accent: Color, alpha: float, phase: float) -> void :
	var points: Array = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position
	]
	for edge in range(4):
		var a: Vector2 = points[edge]
		var b: Vector2 = points[edge + 1]
		var dir: Vector2 = (b - a).normalized()
		var normal: Vector2 = Vector2(-dir.y, dir.x)
		var last: Vector2 = a
		var steps: int = 7
		for s in range(1, steps + 1):
			var ratio: float = float(s) / float(steps)
			var jitter: float = sin(phase * 11.0 + float(edge * 19 + s * 7)) * 4.0
			var p: Vector2 = a.lerp(b, ratio) + normal * jitter
			var bolt_alpha: float = alpha * (0.22 + 0.34 * max(0.0, sin(phase * 7.0 + float(s + edge))))
			game.draw_line(last, p, Color(0.46, 0.96, 1.0, bolt_alpha), 1.4)
			if s % 3 == 0:
				var branch: Vector2 = p + normal * (8.0 + abs(jitter)) + dir * sin(phase * 5.0 + s) * 12.0
				game.draw_line(p, branch, Color(0.82, 0.98, 1.0, bolt_alpha * 0.72), 1.0)
			last = p


static func _draw_judicial_order_paper(game: Node2D, rect: Rect2, label: String, desc: String, progress_text: String, timer_text: String, compact: = false) -> void :
	var paper = Color(0.94, 0.79, 0.42, 0.96)
	var paper_dark = Color(0.52, 0.25, 0.07, 0.88)
	var ink = Color(0.19, 0.09, 0.035, 0.96)
	var seal = Color(0.62, 0.05, 0.035, 0.82)
	game.draw_rect(rect.grow(8.0), Color(0.0, 0.0, 0.0, 0.36), true)
	game.draw_rect(rect, paper, true)
	game.draw_rect(rect, paper_dark, false, 3.0)
	game.draw_rect(rect.grow(-8.0), Color(1.0, 0.93, 0.62, 0.28), false, 1.4)
	var fold = minf(rect.size.x, rect.size.y) * (0.16 if compact else 0.11)
	var fold_points = PackedVector2Array([
		Vector2(rect.end.x - fold, rect.position.y), 
		Vector2(rect.end.x, rect.position.y), 
		Vector2(rect.end.x, rect.position.y + fold)
	])
	game.draw_polygon(fold_points, PackedColorArray([Color(0.72, 0.48, 0.2, 0.88), Color(0.72, 0.48, 0.2, 0.88), Color(0.72, 0.48, 0.2, 0.88)]))
	game.draw_line(Vector2(rect.end.x - fold, rect.position.y), Vector2(rect.end.x, rect.position.y + fold), Color(0.34, 0.14, 0.035, 0.7), 1.5)
	if compact:
		game.draw_string(game.font, rect.position + Vector2(16.0, 25.0), "ORDEM JUDICIAL", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 86.0, game._readable_text_size(13), ink)
		game.draw_string(game.font, rect.position + Vector2(16.0, 49.0), label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 86.0, game._readable_text_size(11), Color(0.3, 0.12, 0.03, 0.94))
		game.draw_string(game.font, rect.position + Vector2(rect.size.x - 74.0, 52.0), timer_text, HORIZONTAL_ALIGNMENT_CENTER, 58.0, game._readable_text_size(13), seal)
		game.draw_string(game.font, rect.position + Vector2(18.0, 96.0), progress_text, HORIZONTAL_ALIGNMENT_LEFT, 74.0, game._readable_text_size(12), ink)
		game._draw_judicial_stamp(rect.position + Vector2(rect.size.x - 48.0, 28.0), 21.0, "LEI")
		return
	var header = Rect2(rect.position + Vector2(26.0, 20.0), Vector2(rect.size.x - 52.0, 42.0))
	game.draw_rect(header, Color(0.43, 0.16, 0.04, 0.88), true)
	game.draw_rect(header, Color(1.0, 0.83, 0.38, 0.38), false, 1.2)
	game._draw_centered("TRIBUNAL DA RUPTURA TEMPORAL", header.get_center() + Vector2(0, 5), game._readable_text_size(13), Color(1.0, 0.86, 0.48, 0.96))
	game._draw_centered("ORDEM JUDICIAL", rect.position + Vector2(rect.size.x * 0.5, 91.0), game._readable_text_size(26), ink)
	game.draw_line(rect.position + Vector2(62.0, 108.0), rect.position + Vector2(rect.size.x - 62.0, 108.0), paper_dark, 2.0)
	game._draw_wrapped(desc, Rect2(rect.position + Vector2(54.0, 126.0), Vector2(rect.size.x - 168.0, 56.0)), game._readable_text_size(16), ink)
	game.draw_string(game.font, rect.position + Vector2(54.0, rect.size.y - 46.0), "PROCESSO: %s" % label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 190.0, game._readable_text_size(12), Color(0.34, 0.14, 0.04, 0.94))
	game.draw_string(game.font, rect.position + Vector2(54.0, rect.size.y - 22.0), "PROGRESSO: %s" % progress_text, HORIZONTAL_ALIGNMENT_LEFT, 160.0, game._readable_text_size(12), Color(0.34, 0.14, 0.04, 0.94))
	var deadline_rect = Rect2(rect.end - Vector2(176.0, 62.0), Vector2(142.0, 34.0))
	game.draw_rect(deadline_rect, Color(0.36, 0.12, 0.035, 0.16), true)
	game.draw_rect(deadline_rect, paper_dark, false, 1.2)
	game._draw_centered(timer_text, deadline_rect.get_center() + Vector2(0, 5), game._readable_text_size(13), ink)
	game._draw_judicial_stamp(rect.position + Vector2(rect.size.x - 86.0, 143.0), 42.0, "DEFERIDO")


static func _draw_ground_target_preview(game: Node2D, viewport: Vector2, camera: Vector2) -> void :
	var secondary = false
	var touch_pos = Vector2.ZERO
	if game.skill_touch_index != -1 and not game._ground_target_profile(false).is_empty():
		touch_pos = game.skill_touch_pos
	elif game.secondary_touch_index != -1 and not game._ground_target_profile(true).is_empty():
		secondary = true
		touch_pos = game.secondary_touch_pos
	else:
		return
	if game._ability_cancel_has_point(touch_pos, viewport):
		return
	var profile = game._ground_target_profile(secondary)
	var target_world = game._desktop_cursor_ground_target(secondary) if game.desktop_aim_action in ["skill", "secondary"] else game._ground_target_world(touch_pos, viewport, secondary)
	var start = game.player_pos - camera
	var target = target_world - camera
	var color: Color = profile["color"]
	var radius = float(profile["radius"])
	var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.01) * 0.5
	game.draw_arc(start, float(profile["range"]), 0.0, TAU, 96, Color(color.r, color.g, color.b, 0.18), 2.0)
	game.draw_line(start, target, Color(color.r, color.g, color.b, 0.24), 10.0)
	game.draw_line(start, target, Color(color.r, color.g, color.b, 0.86), 2.0)
	game.draw_circle(target, radius, Color(color.r, color.g, color.b, 0.1 + pulse * 0.04))
	game.draw_arc(target, radius + pulse * 5.0, 0.0, TAU, 64, Color(color.r, color.g, color.b, 0.94), 3.0)
	game.draw_arc(target, radius * 0.68, - Time.get_ticks_msec() * 0.002, TAU - Time.get_ticks_msec() * 0.002, 48, Color(1.0, 1.0, 1.0, 0.54), 1.5)
	game.draw_line(target + Vector2(-14.0, 0.0), target + Vector2(14.0, 0.0), Color.WHITE, 2.0)
	game.draw_line(target + Vector2(0.0, -14.0), target + Vector2(0.0, 14.0), Color.WHITE, 2.0)


static func _draw_scifi_frame(game: Node2D, rect: Rect2, accent: Color = Color(0.0, 0.85, 1.0), corner_cut: float = 8.0, bg_alpha: float = 0.88) -> void:
	var x: float = rect.position.x
	var y: float = rect.position.y
	var w: float = rect.size.x
	var h: float = rect.size.y
	var cut: float = minf(corner_cut, minf(w, h) * 0.4)

	var points = PackedVector2Array([
		Vector2(x + cut, y),
		Vector2(x + w - cut, y),
		Vector2(x + w, y + cut),
		Vector2(x + w, y + h - cut),
		Vector2(x + w - cut, y + h),
		Vector2(x + cut, y + h),
		Vector2(x, y + h - cut),
		Vector2(x, y + cut)
	])

	game.draw_colored_polygon(points, Color(0.04, 0.07, 0.11, bg_alpha))

	var inner_points = PackedVector2Array([
		Vector2(x + cut + 2, y + 2),
		Vector2(x + w - cut - 2, y + 2),
		Vector2(x + w - 2, y + cut + 2),
		Vector2(x + w - 2, y + h - cut - 2),
		Vector2(x + w - cut - 2, y + h - 2),
		Vector2(x + cut + 2, y + h - 2),
		Vector2(x + 2, y + h - cut - 2),
		Vector2(x + 2, y + cut + 2)
	])
	game.draw_polyline(inner_points, Color(0.12, 0.17, 0.23, 0.70 * bg_alpha), 1.5)

	var border_pts = points.duplicate()
	border_pts.append(points[0])
	game.draw_polyline(border_pts, Color(0.20, 0.28, 0.36, 0.95 * bg_alpha), 2.0)

	game.draw_line(Vector2(x, y + cut), Vector2(x + cut, y), Color(accent.r, accent.g, accent.b, 0.85 * bg_alpha), 2.0)
	game.draw_line(Vector2(x + w - cut, y), Vector2(x + w, y + cut), Color(accent.r, accent.g, accent.b, 0.85 * bg_alpha), 2.0)
	game.draw_line(Vector2(x + w, y + h - cut), Vector2(x + w - cut, y + h), Color(accent.r, accent.g, accent.b, 0.85 * bg_alpha), 2.0)
	game.draw_line(Vector2(x + w - cut, y + h), Vector2(x, y + h - cut), Color(accent.r, accent.g, accent.b, 0.85 * bg_alpha), 2.0)

	var rivet_col = Color(0.25, 0.35, 0.44, 0.85 * bg_alpha)
	var rivet_r = 1.8
	game.draw_circle(Vector2(x + cut + 4.0, y + 5.0), rivet_r, rivet_col)
	game.draw_circle(Vector2(x + w - cut - 4.0, y + 5.0), rivet_r, rivet_col)
	game.draw_circle(Vector2(x + w - cut - 4.0, y + h - 5.0), rivet_r, rivet_col)
	game.draw_circle(Vector2(x + cut + 4.0, y + h - 5.0), rivet_r, rivet_col)


static func _draw_icon_sword(game: Node2D, center: Vector2, size: float, color: Color) -> void:
	var half: float = size * 0.5
	var blade_top = center + Vector2(0, -half * 0.85)
	var blade_bot = center + Vector2(0, half * 0.4)
	game.draw_line(blade_top, blade_bot, color, 3.0)
	var tip = PackedVector2Array([
		blade_top,
		center + Vector2(-3.0, -half * 0.5),
		blade_bot,
		center + Vector2(3.0, -half * 0.5)
	])
	game.draw_colored_polygon(tip, Color(color.r, color.g, color.b, 0.35))
	game.draw_line(center + Vector2(-half * 0.5, half * 0.2), center + Vector2(half * 0.5, half * 0.2), color, 2.5)
	game.draw_line(center + Vector2(0, half * 0.2), center + Vector2(0, half * 0.75), Color(0.7, 0.8, 0.9), 2.0)
	game.draw_circle(center + Vector2(0, half * 0.8), 2.5, color)


static func _draw_icon_star(game: Node2D, center: Vector2, size: float, color: Color) -> void:
	var r_outer: float = size * 0.5
	var r_inner: float = size * 0.22
	var pts = PackedVector2Array()
	for i in range(8):
		var angle: float = i * PI * 0.25 - PI * 0.5
		var r: float = r_outer if (i % 2 == 0) else r_inner
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	game.draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.4))
	pts.append(pts[0])
	game.draw_polyline(pts, color, 2.0)


static func _draw_icon_trident(game: Node2D, center: Vector2, size: float, color: Color) -> void:
	var half: float = size * 0.5
	game.draw_line(center + Vector2(0, -half * 0.85), center + Vector2(0, half * 0.8), color, 2.5)
	game.draw_line(center + Vector2(-half * 0.6, -half * 0.1), center + Vector2(half * 0.6, -half * 0.1), color, 2.0)
	game.draw_line(center + Vector2(-half * 0.6, -half * 0.1), center + Vector2(-half * 0.6, -half * 0.75), color, 2.0)
	game.draw_line(center + Vector2(-half * 0.6, -half * 0.75), center + Vector2(-half * 0.5, -half * 0.85), color, 2.0)
	game.draw_line(center + Vector2(half * 0.6, -half * 0.1), center + Vector2(half * 0.6, -half * 0.75), color, 2.0)
	game.draw_line(center + Vector2(half * 0.6, -half * 0.75), center + Vector2(half * 0.5, -half * 0.85), color, 2.0)
	var tip = PackedVector2Array([
		center + Vector2(0, -half * 0.95),
		center + Vector2(-3.0, -half * 0.65),
		center + Vector2(3.0, -half * 0.65)
	])
	game.draw_colored_polygon(tip, color)


static func _draw_icon_portal(game: Node2D, center: Vector2, size: float, color: Color) -> void:
	var rx: float = size * 0.42
	var ry: float = size * 0.5
	var pts = PackedVector2Array()
	for i in range(24):
		var angle: float = i * TAU / 24.0
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	game.draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.25))
	pts.append(pts[0])
	game.draw_polyline(pts, color, 2.0)
	var inner_pts = PackedVector2Array()
	for i in range(16):
		var angle: float = i * TAU / 16.0
		inner_pts.append(center + Vector2(cos(angle) * rx * 0.55, sin(angle) * ry * 0.55))
	inner_pts.append(inner_pts[0])
	game.draw_polyline(inner_pts, Color(1.0, 1.0, 1.0, 0.85), 1.5)
	game.draw_circle(center, 2.5, Color.WHITE)


static func _draw_icon_hourglass(game: Node2D, center: Vector2, size: float, color: Color) -> void:
	var half: float = size * 0.5
	game.draw_line(center + Vector2(-half * 0.7, -half * 0.8), center + Vector2(half * 0.7, -half * 0.8), color, 2.0)
	game.draw_line(center + Vector2(-half * 0.7, half * 0.8), center + Vector2(half * 0.7, half * 0.8), color, 2.0)
	var top_tri = PackedVector2Array([
		center + Vector2(-half * 0.65, -half * 0.75),
		center + Vector2(half * 0.65, -half * 0.75),
		center + Vector2(0, 0)
	])
	var bot_tri = PackedVector2Array([
		center + Vector2(0, 0),
		center + Vector2(half * 0.65, half * 0.75),
		center + Vector2(-half * 0.65, half * 0.75)
	])
	game.draw_colored_polygon(top_tri, Color(color.r, color.g, color.b, 0.35))
	game.draw_colored_polygon(bot_tri, Color(color.r, color.g, color.b, 0.55))
	top_tri.append(top_tri[0])
	bot_tri.append(bot_tri[0])
	game.draw_polyline(top_tri, color, 1.8)
	game.draw_polyline(bot_tri, color, 1.8)


static func _draw_icon_cart(game: Node2D, center: Vector2, size: float, color: Color) -> void:
	var half: float = size * 0.5
	game.draw_line(center + Vector2(-half * 0.8, -half * 0.6), center + Vector2(-half * 0.5, -half * 0.6), color, 2.0)
	game.draw_line(center + Vector2(-half * 0.5, -half * 0.6), center + Vector2(-half * 0.3, half * 0.3), color, 2.0)
	var basket = PackedVector2Array([
		center + Vector2(-half * 0.45, -half * 0.4),
		center + Vector2(half * 0.7, -half * 0.4),
		center + Vector2(half * 0.45, half * 0.3),
		center + Vector2(-half * 0.3, half * 0.3)
	])
	game.draw_colored_polygon(basket, Color(color.r, color.g, color.b, 0.30))
	basket.append(basket[0])
	game.draw_polyline(basket, color, 2.0)
	game.draw_circle(center + Vector2(-half * 0.2, half * 0.6), 3.0, color)
	game.draw_circle(center + Vector2(half * 0.35, half * 0.6), 3.0, color)


static func _draw_icon_skull(game: Node2D, center: Vector2, size: float, color: Color) -> void:
	var half: float = size * 0.5
	var head_pts = PackedVector2Array()
	for i in range(16):
		var a: float = PI + i * PI / 15.0
		head_pts.append(center + Vector2(cos(a) * half * 0.65, sin(a) * half * 0.65 - half * 0.1))
	head_pts.append(center + Vector2(half * 0.4, half * 0.45))
	head_pts.append(center + Vector2(-half * 0.4, half * 0.45))
	game.draw_colored_polygon(head_pts, Color(color.r, color.g, color.b, 0.35))
	head_pts.append(head_pts[0])
	game.draw_polyline(head_pts, color, 2.0)
	game.draw_circle(center + Vector2(-half * 0.28, -half * 0.1), 3.2, Color(0.04, 0.06, 0.1))
	game.draw_circle(center + Vector2(half * 0.28, -half * 0.1), 3.2, Color(0.04, 0.06, 0.1))
	game.draw_line(center + Vector2(-half * 0.15, half * 0.25), center + Vector2(-half * 0.15, half * 0.45), color, 1.5)
	game.draw_line(center + Vector2(0, half * 0.2), center + Vector2(0, half * 0.45), color, 1.5)
	game.draw_line(center + Vector2(half * 0.15, half * 0.25), center + Vector2(half * 0.15, half * 0.45), color, 1.5)


static func _draw_icon_ecg(game: Node2D, center: Vector2, size: float, color: Color) -> void:
	var half: float = size * 0.5
	var pts = PackedVector2Array([
		center + Vector2(-half * 0.9, 0),
		center + Vector2(-half * 0.4, 0),
		center + Vector2(-half * 0.2, half * 0.3),
		center + Vector2(0, -half * 0.75),
		center + Vector2(half * 0.2, half * 0.5),
		center + Vector2(half * 0.45, -half * 0.2),
		center + Vector2(half * 0.6, 0),
		center + Vector2(half * 0.9, 0)
	])
	game.draw_polyline(pts, color, 2.0)


static func _draw_icon_gem(game: Node2D, center: Vector2, size: float, color: Color) -> void:
	var half: float = size * 0.5
	var pts = PackedVector2Array([
		center + Vector2(0, -half * 0.85),
		center + Vector2(half * 0.7, 0),
		center + Vector2(0, half * 0.85),
		center + Vector2(-half * 0.7, 0)
	])
	game.draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.35))
	pts.append(pts[0])
	game.draw_polyline(pts, color, 2.0)
	game.draw_line(center + Vector2(0, -half * 0.85), center + Vector2(0, half * 0.85), Color(1.0, 1.0, 1.0, 0.6), 1.2)


static func _draw_desktop_session_buttons(game: Node2D, _viewport: Vector2) -> void :
	if game.buttons.has("pause"):
		var pause_rect: Rect2 = game.buttons["pause"]
		game._draw_hud_rect_button(pause_rect, "II", game.CombatHud.CYAN)
		game._draw_centered(game._compact_key_binding_name("pause"), pause_rect.get_center() + Vector2(0, -24), 10, Color(0.72, 1.0, 0.94, 0.9))

	if game.buttons.has("shop_manual"):
		var shop_rect: Rect2 = game.buttons["shop_manual"]
		var shop_accent = Color(0.0, 0.88, 1.0) if game._affordable_card_count() > 0 and game.mode == "game" else Color(0.38, 0.42, 0.46)
		game.hud_feedback.surface(game, shop_rect, shop_accent)
		game._draw_icon_cart(Vector2(shop_rect.position.x + 26.0, shop_rect.position.y + 22.0), 22.0, shop_accent)
		game._draw_centered("LOJA", shop_rect.get_center() + Vector2(14.0, 4.0), 16, shop_accent)

	if game.boss_ready and not game.boss_active and not game.boss_dead and game.buttons.has("boss"):
		var boss_rect: Rect2 = game.buttons["boss"]
		var boss_accent = Color(1.0, 0.22, 0.28)
		game.hud_feedback.surface(game, boss_rect, boss_accent)
		game._draw_icon_skull(Vector2(boss_rect.position.x + 26.0, boss_rect.position.y + 22.0), 22.0, boss_accent)
		game._draw_centered("BOSS", boss_rect.get_center() + Vector2(14.0, 4.0), 16, boss_accent)


static func _draw_shop_mp_request(game: Node2D, viewport: Vector2) -> void :
	var panel_w: float = min(440.0, viewport.x * 0.86)
	var panel_h = 122.0 if game.shop_mp_request_incoming else 78.0
	var panel = Rect2(viewport.x * 0.5 - panel_w * 0.5, 26.0, panel_w, panel_h)
	var accent = Color(0.0, 1.0, 0.82) if game.shop_mp_request_incoming else Color(1.0, 0.76, 0.25)
	game._draw_holo_panel(panel, accent, true, 0.86)
	var remaining = int(ceil(max(0.0, game.shop_mp_request_timer)))
	var title = "PARCEIRO PEDIU LOJA" if game.shop_mp_request_incoming else "PEDIDO DE LOJA ENVIADO"
	game._draw_centered(title, Vector2(panel.get_center().x, panel.position.y + 30.0), game._readable_text_size(15), accent)
	var status = "aguardando confirmacao %ds" % remaining
	if game.shop_mp_request_incoming:
		status = "clique ou enter/espaco em %ds" % remaining
	game._draw_centered(status.to_upper(), Vector2(panel.get_center().x, panel.position.y + 56.0), game._readable_text_size(12), Color(0.92, 0.96, 1.0))
	game.buttons.erase("shop_mp_accept")
	if game.shop_mp_request_incoming:
		game.buttons["shop_mp_accept"] = Rect2(panel.get_center().x - 94.0, panel.end.y - 42.0, 188.0, 32.0)
		game._draw_small_rect_button(game.buttons["shop_mp_accept"], "ACEITAR  ENTER", Color(0.03, 0.18, 0.12, 0.92), Color(0.0, 1.0, 0.82))


static func _draw_team_revival_world(game: Node2D, camera: Vector2) -> void:
	if not game.revival_active or game.mode != "game":
		return
	var t: float = Time.get_ticks_msec() * 0.001
	for fragment in game.revival_fragments:
		var data: Dictionary = fragment
		if bool(data.get("collected", false)):
			continue
		var pos: Vector2 = Vector2(data.get("pos", Vector2.ZERO)) - camera
		var phase: float = float(data.get("phase", 0.0)) + t * 3.0
		var pulse: float = 0.5 + sin(phase) * 0.5
		var shard_size: float = 16.0 + pulse * 6.0
		var hue: float = fposmod(0.52 + sin(phase * 0.7) * 0.08, 1.0)
		var cyan = Color.from_hsv(hue, 0.55 + pulse * 0.35, 1.0, 0.94)
		var core = Color(1.0, 1.0, 1.0, 0.86)
		var diamond = PackedVector2Array([pos + Vector2(0, -shard_size), pos + Vector2(shard_size * 0.72, 0), pos + Vector2(0, shard_size), pos + Vector2(-shard_size * 0.72, 0)])
		var outline = PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]])
		game.draw_circle(pos, shard_size * (1.65 + pulse * 0.35), Color(cyan.r, cyan.g, cyan.b, 0.13 + pulse * 0.09), true)
		game.draw_colored_polygon(diamond, Color(cyan.r * 0.11, cyan.g * 0.2, cyan.b * 0.24, 0.92))
		game.draw_polyline(outline, cyan, 3.0, true)
		game.draw_polyline(outline, Color(1.0, 1.0, 1.0, 0.5), 1.1, true)
		game.draw_line(pos + Vector2(-shard_size * 0.55, -shard_size * 0.12), pos + Vector2(shard_size * 0.54, shard_size * 0.18), core, 2.0, true)
		game.draw_circle(pos, 4.2 + pulse * 1.6, core)
	if game.revival_altars_active:
		game._draw_team_revival_altar(game.revival_altar_life_pos - camera, Color(1.0, 0.18, 0.26), "VIDA", t)
		game._draw_team_revival_altar(game.revival_altar_points_pos - camera, Color(0.08, 0.62, 1.0), "4 CARTAS", t + 1.4)
		game._draw_revival_altar_talkbox(camera)


static func _draw_team_revival_altar(game: Node2D, center: Vector2, color: Color, label: String, phase: float) -> void:
	var pulse: float = 0.5 + sin(phase * 4.0) * 0.5
	var ground_alpha: float = 0.11 + pulse * 0.05
	game.draw_circle(center + Vector2(0, 20), game.REVIVAL_ALTAR_RADIUS * 0.86, Color(color.r, color.g, color.b, ground_alpha))
	game.draw_arc(center + Vector2(0, 20), game.REVIVAL_ALTAR_RADIUS * 0.84, phase, phase + TAU, 80, Color(color.r, color.g, color.b, 0.72), 3.0, true)
	var base_top = PackedVector2Array([
		center + Vector2(-42, 12),
		center + Vector2(42, 12),
		center + Vector2(56, 28),
		center + Vector2(0, 44),
		center + Vector2(-56, 28)
	])
	var base_face = PackedVector2Array([
		center + Vector2(-56, 28),
		center + Vector2(0, 44),
		center + Vector2(56, 28),
		center + Vector2(42, 50),
		center + Vector2(-42, 50)
	])
	game.draw_colored_polygon(base_face, Color(0.03, 0.05, 0.07, 0.94))
	game.draw_colored_polygon(base_top, Color(0.05, 0.13, 0.15, 0.96))
	game.draw_polyline(PackedVector2Array([base_top[0], base_top[1], base_top[2], base_top[3], base_top[4], base_top[0]]), Color(color.r, color.g, color.b, 0.9), 2.0, true)
	game.draw_line(center + Vector2(-42, 50), center + Vector2(42, 50), Color(color.r, color.g, color.b, 0.56), 2.0, true)
	var crystal_y: float = sin(phase * 3.0) * 4.0 - 14.0
	var crystal = PackedVector2Array([
		center + Vector2(0, crystal_y - 38),
		center + Vector2(22, crystal_y - 10),
		center + Vector2(14, crystal_y + 22),
		center + Vector2(-14, crystal_y + 22),
		center + Vector2(-22, crystal_y - 10)
	])
	game.draw_colored_polygon(crystal, Color(color.r * 0.22, color.g * 0.22, color.b * 0.22, 0.92))
	game.draw_polyline(PackedVector2Array([crystal[0], crystal[1], crystal[2], crystal[3], crystal[4], crystal[0]]), Color(color.r, color.g, color.b, 0.98), 2.4, true)
	game.draw_line(center + Vector2(0, crystal_y - 34), center + Vector2(0, crystal_y + 18), Color(1.0, 1.0, 1.0, 0.42), 1.2, true)
	game.draw_circle(center + Vector2(0, crystal_y - 8), 28.0 + pulse * 6.0, Color(color.r, color.g, color.b, 0.08), true)
	game._draw_centered(label, center + Vector2(0, 72), 13, Color(1.0, 1.0, 1.0, 0.94))


static func _draw_revival_altar_talkbox(game: Node2D, camera: Vector2) -> void:
	var method: String = game._local_revival_altar_method()
	if method == "":
		return
	var altar_world: Vector2 = game.revival_altar_life_pos if method == game.REVIVE_PAY_LIFE else game.revival_altar_points_pos
	var center: Vector2 = altar_world - camera
	var key_name: String = game._compact_key_binding_name("interact")
	var cost_text: String = "%.0f%% DA VIDA" % (game._revival_life_sacrifice_rate() * 100.0)
	var detail: String = "divide entre %d caido(s)" % game._team_revival_dead_count()
	if method == game.REVIVE_PAY_POINTS:
		cost_text = "%d PONTOS" % game._revival_points_cost()
		detail = "gasto individual"
	var rect: Rect2 = Rect2(center.x - 172.0, center.y - 132.0, 344.0, 72.0)
	game._draw_holo_panel(rect, Color(0.0, 1.0, 0.82), true, 0.78)
	game._draw_centered("ALTAR " + game._revival_method_label(method), Vector2(rect.get_center().x, rect.position.y + 23.0), game._readable_text_size(12), Color(0.0, 1.0, 0.82))
	game._draw_centered("%s  %s  |  %s" % [key_name, cost_text, detail], Vector2(rect.get_center().x, rect.position.y + 49.0), game._readable_text_size(10), Color(0.94, 1.0, 0.98))


static func _draw_revival_interaction_prompt(game: Node2D, viewport: Vector2) -> void:
	var method: String = game._local_revival_altar_method()
	if method == "":
		return
	var key_name: String = game._compact_key_binding_name("interact")
	var cost_text: String = "%.0f%% DA VIDA" % (game._revival_life_sacrifice_rate() * 100.0)
	if method == game.REVIVE_PAY_POINTS:
		cost_text = "%d PONTOS" % game._revival_points_cost()
	var text: String = "%s INTERAGIR - ALTAR %s (%s)" % [key_name, game._revival_method_label(method), cost_text]
	var rect: Rect2 = Rect2(viewport.x * 0.5 - 230.0, viewport.y * 0.58, 460.0, 38.0)
	game._draw_holo_panel(rect, Color(0.0, 1.0, 0.82), true, 0.78)
	game._draw_centered(text, rect.get_center() + Vector2(0, 4), game._readable_text_size(12), Color(0.94, 1.0, 0.98))


static func _draw_revive_request(game: Node2D, viewport: Vector2) -> void :
	if not game._revive_request_visible():
		return
	if game._team_revival_hud_visible():
		game._draw_team_revival_hud(viewport)
		return
	var panel_w: float = min(620.0, viewport.x * 0.88)
	var panel_h = 218.0 if game.revive_request_incoming else 164.0
	var panel = Rect2(viewport.x * 0.5 - panel_w * 0.5, viewport.y * 0.5 - panel_h * 0.5, panel_w, panel_h)
	var accent = Color(0.2, 1.0, 0.5)
	game._draw_holo_panel(panel, accent, true, 0.88)
	game.buttons.erase("revive_request")
	game.buttons.erase("revive_accept")
	game.buttons.erase("revive_accept_points")
	game.buttons.erase("revive_accept_life")
	game.buttons.erase("revive_reject")
	var cost = game._revive_cost() if game.revive_request_cost <= 0 else game.revive_request_cost
	if game.revive_request_incoming:
		var remaining = int(ceil(max(0.0, game.revive_request_timer)))
		game._draw_centered("ALIADO CAIDO PEDE REVIVE", Vector2(panel.get_center().x, panel.position.y + 34.0), game._readable_text_size(15), accent)
		game._draw_centered("ESCOLHA COMO REERGUER O ALIADO  |  %ds" % remaining, Vector2(panel.get_center().x, panel.position.y + 66.0), game._readable_text_size(12), Color(0.92, 0.96, 1.0))
		game._draw_centered("PONTOS: %d  OU  VIDA: -50%% HP" % cost, Vector2(panel.get_center().x, panel.position.y + 96.0), game._readable_text_size(13), Color(1.0, 0.86, 0.26))
		var sacrifice_rect = Rect2(panel.position.x + 28.0, panel.position.y + 112.0, panel.size.x - 56.0, 28.0)
		game._draw_wrapped_clamped("SACRIFICIO: SUAS CURAS FICAM 50% MAIS FRACAS POR 1 MINUTO", sacrifice_rect, game._readable_text_size(10), Color(1.0, 0.58, 0.62), 1)
		var gap = 10.0
		var bw = (panel_w - 56.0 - gap * 2.0) / 3.0
		var by = panel.end.y - 46.0
		game.buttons["revive_accept_points"] = Rect2(panel.position.x + 18.0, by, bw, 34.0)
		game.buttons["revive_accept_life"] = Rect2(game.buttons["revive_accept_points"].end.x + gap, by, bw, 34.0)
		game.buttons["revive_reject"] = Rect2(game.buttons["revive_accept_life"].end.x + gap, by, bw, 34.0)
		var points_enabled: bool = game.score >= cost
		game._draw_small_rect_button(game.buttons["revive_accept_points"], "PONTOS", Color(0.03, 0.18, 0.12, 0.92) if points_enabled else Color(0.09, 0.1, 0.11, 0.86), accent if points_enabled else Color(0.48, 0.52, 0.56))
		game._draw_small_rect_button(game.buttons["revive_accept_life"], "VIDA", Color(0.18, 0.08, 0.08, 0.92), Color(1.0, 0.34, 0.42))
		game._draw_small_rect_button(game.buttons["revive_reject"], "RECUSAR", Color(0.18, 0.04, 0.06, 0.92), Color(1.0, 0.2, 0.3))
		return
	if game.is_dead:
		var title = "VOCE FOI ELIMINADO"
		var detail = "ALIADO PODE PAGAR %d PONTOS OU DOAR VIDA" % cost
		var enabled: bool = game.revive_request_cooldown <= 0.0 and not game.revive_request_outgoing
		if game.revive_request_outgoing:
			detail = "PEDIDO ENVIADO %.0fs" % ceil(max(0.0, game.revive_request_timer))
		elif game.revive_request_cooldown > 0.0:
			detail = "AGUARDE %.0fs PARA PEDIR" % ceil(game.revive_request_cooldown)
		game._draw_centered(title, Vector2(panel.get_center().x, panel.position.y + 34.0), game._readable_text_size(15), accent)
		game._draw_centered(detail, Vector2(panel.get_center().x, panel.position.y + 68.0), game._readable_text_size(13), Color(0.92, 0.96, 1.0))
		var sacrifice_rect = Rect2(panel.position.x + 30.0, panel.position.y + 88.0, panel.size.x - 60.0, 28.0)
		game._draw_wrapped_clamped("DOACAO DE VIDA REDUZ CURAS DO ALIADO POR 1 MINUTO", sacrifice_rect, game._readable_text_size(10), Color(1.0, 0.58, 0.62), 1)
		game.buttons["revive_request"] = Rect2(panel.get_center().x - 112.0, panel.end.y - 42.0, 224.0, 32.0)
		game._draw_small_rect_button(game.buttons["revive_request"], "PEDIR REVIVE", Color(0.03, 0.18, 0.12, 0.92) if enabled else Color(0.09, 0.1, 0.11, 0.86), accent if enabled else Color(0.48, 0.52, 0.56))


static func _draw_shop_mp_waiting_legacy(game: Node2D, viewport: Vector2) -> void :
	var panel_w: float = min(500.0, viewport.x * 0.84)
	var panel = Rect2(viewport.x * 0.5 - panel_w * 0.5, viewport.y * 0.5 - 92.0, panel_w, 184.0)
	game._draw_holo_background(viewport, null, Color(0.0, 0.0, 0.0, 0.58))
	game._draw_holo_panel(panel, Color(0.0, 1.0, 0.82), true, 0.88)
	game._draw_glitch_title("AGUARDANDO EQUIPE", Vector2(panel.get_center().x, panel.position.y + 52.0), 24, Color(0.0, 1.0, 0.82))
	var detail = "VOCE JA TERMINOU SUAS COMPRAS"
	if game._affordable_card_count() <= 0:
		detail = "SEM PONTOS PARA NOVAS CARTAS"
	game._draw_centered(detail, panel.get_center() + Vector2(0, 10), game._readable_text_size(17), Color(1.0, 0.86, 0.26))
	game._draw_centered("PRONTOS %d/%d - A PARTIDA VOLTA COM TODA A EQUIPE" % [game.shop_mp_ready_count, game.shop_mp_expected_count], panel.get_center() + Vector2(0, 48), game._readable_text_size(13), Color(0.9, 0.96, 1.0, 0.92))


static func _draw_cinzas_shader_card(game: Node2D, card: Dictionary, rect: Rect2, texture: Texture2D, alpha: float = 1.0, _show_title: bool = true) -> bool:
	if texture == null or game._is_empty_shop_slot(card) or not bool(card.get("cinzas_return_buff", false)):
		return false
	if alpha <= 0.01 or rect.size.x <= 4.0 or rect.size.y <= 4.0:
		return false
	var holder = game._ensure_cinzas_burn_shader_node(game.cinzas_burn_texture_index)
	game.cinzas_burn_texture_index += 1
	holder.visible = true
	holder.position = rect.position
	holder.size = rect.size
	holder.modulate = Color(1.0, 1.0, 1.0, alpha)

	var texture_rect = holder.get_node("Texture") as TextureRect
	texture_rect.position = Vector2.ZERO
	texture_rect.size = rect.size
	texture_rect.texture = texture
	texture_rect.material = game._pixel_card_burn_material(card, rect)
	game._configure_cinzas_ember_nodes(holder, card, rect.size, alpha)
	return true


static func _draw_card_surface(game: Node2D, card: Dictionary, rect: Rect2, selected: bool, alpha: = 1.0, count: = 0) -> void :
	var color: Color = card["color"]
	var rarity_color = game._card_rarity_color(card)
	var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.007) * 0.5
	var bg = Color(0.025, 0.03, 0.046, 0.92 * alpha).lerp(color, 0.12 if selected else 0.05)
	game.draw_rect(rect, bg, true)
	if selected:
		for g in range(1, 5):
			game.draw_rect(rect.grow(g * (3.0 + pulse * 1.8)), Color(rarity_color.r, rarity_color.g, rarity_color.b, (0.22 + pulse * 0.1) / float(g)), false, 2)
	game.draw_rect(rect, Color(rarity_color.r, rarity_color.g, rarity_color.b, (0.96 if selected else 0.58) * alpha), false, 4 if selected else 2)
	var icon: Texture2D = game._card_texture(card)
	if icon:
		game._draw_texture_contain(icon, rect.grow(-8.0), Color(1.0, 1.0, 1.0, alpha))
	var rarity_badge = Rect2(rect.position + Vector2(8.0, 8.0), Vector2(56.0, 24.0))
	game.draw_rect(rarity_badge, Color(0.0, 0.0, 0.0, 0.74 * alpha), true)
	game.draw_rect(rarity_badge, Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.92 * alpha), false, 1)
	game._draw_centered(game._card_rarity_label(card), rarity_badge.get_center() + Vector2(0, 4), 10, rarity_color)
	game.draw_rect(Rect2(rect.position.x, rect.end.y - 44.0, rect.size.x, 44.0), Color(0.0, 0.0, 0.0, 0.58 * alpha), true)
	game._draw_centered(String(card["nick"]).to_upper(), Vector2(rect.get_center().x, rect.end.y - 18.0), 11 if not selected else 13, Color(1.0, 1.0, 1.0, alpha))
	if count > 0:
		var badge = Rect2(rect.end.x - 44.0, rect.position.y + 8.0, 34.0, 28.0)
		game.draw_rect(badge, Color(0.0, 0.0, 0.0, 0.76 * alpha), true)
		game.draw_rect(badge, Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.92 * alpha), false, 2)
		game._draw_centered("x%d" % count, badge.get_center() + Vector2(0, 5), 14, Color.WHITE)


static func _draw_card_detail_panel(game: Node2D, card: Dictionary, rect: Rect2, owned_count: = 0, compact: = false) -> void :
	var color: Color = card["color"]
	var rarity_color = game._card_rarity_color(card)
	game.draw_rect(rect, Color(0.02, 0.025, 0.04, 0.92), true)
	game.draw_rect(rect, Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.78), false, 2)
	game.draw_string(game.font, rect.position + Vector2(18, 26), String(card["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if compact else 22, color)
	var count_text = "x%d NO DECK" % owned_count if owned_count > 0 else "AINDA NAO POSSUI"
	game.draw_string(game.font, rect.position + Vector2(18, 48), "%s | %s" % [game._card_rarity_label(card), count_text], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, rarity_color)
	game._draw_card_stat_chips(game._card_stat_chips(String(card["name"])), rect.position + Vector2(rect.size.x * 0.42, 17.0), rect.size.x * 0.54, color, 12)
	var desc_y = 60.0 if compact else 72.0
	var desc_rect = Rect2(rect.position + Vector2(18, desc_y), Vector2(rect.size.x - 36, max(24.0, rect.size.y - desc_y - 10.0)))
	var detail_lines = [String(card["desc"])]
	for line in game._card_projection_lines(card):
		detail_lines.append(String(line))
	game._draw_wrapped("\n".join(detail_lines), desc_rect, 11 if compact else 13, Color(0.84, 0.88, 0.92))


static func _draw_end_overlay(game: Node2D, viewport: Vector2, title: String, color: Color) -> void :
	if title == "GAME OVER":
		game._draw_game_over_overlay(viewport)
		return
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.64), true)
	var portrait = game._is_portrait(viewport)
	var panel = Rect2(viewport.x * 0.18 if not portrait else viewport.x * 0.08, viewport.y * 0.22, viewport.x * 0.64 if not portrait else viewport.x * 0.84, viewport.y * 0.56)
	game._draw_holo_panel(panel, color, true, 0.82)
	game._draw_glitch_title(title, Vector2(viewport.x * 0.5, panel.position.y + 64.0), 36 if not portrait else 42, color)
	var summary = Rect2(panel.position.x + 24.0, panel.position.y + 104.0, panel.size.x - 48.0, panel.size.y - 196.0)
	game._draw_run_summary(summary, color, false)
	if game.run_report_status != "":
		game._draw_centered(game.run_report_status.to_upper(), Vector2(viewport.x * 0.5, panel.end.y - 92.0), 12, Color(0.74, 0.92, 1.0, 0.82))
	var btn_w = 260.0 if not portrait else 340.0
	var btn_h = 52.0 if not portrait else 68.0
	var gap = 14.0
	var ranking_rect: Rect2
	var menu_rect: Rect2
	if portrait:
		ranking_rect = Rect2(viewport.x * 0.5 - btn_w * 0.5, panel.end.y - btn_h * 2.0 - gap - 20.0, btn_w, btn_h)
		menu_rect = Rect2(viewport.x * 0.5 - btn_w * 0.5, panel.end.y - btn_h - 20.0, btn_w, btn_h)
	else:
		var total_w = btn_w * 2.0 + gap
		ranking_rect = Rect2(viewport.x * 0.5 - total_w * 0.5, panel.end.y - btn_h - 24.0, btn_w, btn_h)
		menu_rect = Rect2(ranking_rect.end.x + gap, ranking_rect.position.y, btn_w, btn_h)
	game._draw_big_button(ranking_rect, "RANKING", Color(0.1, 0.04, 0.16, 0.92), Color(1.0, 0.28, 0.78))
	game._draw_big_button(menu_rect, "MENU", Color(0.04, 0.13, 0.17, 0.92), Color(0.0, 1.0, 0.82))
	game.buttons["end_ranking"] = ranking_rect
	game.buttons["end_menu"] = menu_rect


static func _draw_specter_upgrade(game: Node2D, viewport: Vector2) -> void:
	game.buttons.erase("specter_upgrade_prev")
	game.buttons.erase("specter_upgrade_next")
	game.buttons.erase("specter_upgrade_confirm")
	game.buttons.erase("specter_upgrade_continue")
	var portrait = game._is_portrait(viewport)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.68), true)
	var panel_w = viewport.x * (0.82 if not portrait else 0.9)
	var panel_h = viewport.y * (0.68 if not portrait else 0.76)
	var panel = Rect2(viewport.x * 0.5 - panel_w * 0.5, viewport.y * 0.5 - panel_h * 0.5, panel_w, panel_h)
	game._draw_holo_panel(panel, Color(0.0, 1.0, 0.82), true, 0.86)
	game._draw_glitch_title("UPGRADE DE ESPECTRO", Vector2(panel.get_center().x, panel.position.y + 44.0), 30 if not portrait else 24, Color(0.0, 1.0, 0.82))
	game._draw_centered("Nucleos instaveis coletados nas runs: %d" % game.spectral_coins, Vector2(panel.get_center().x, panel.position.y + 78.0), 15 if not portrait else 12, Color(0.76, 0.94, 1.0, 0.92))

	var key = game._current_specter_key()
	var name = game._current_specter_name()
	var level = game._specter_level(key)
	var unlocked = game._spectrum_unlocked(game.specter_upgrade_selected_index)
	var maxed = level >= game.AuraSystem.RUN_MAX_LEVEL
	var cost = game._specter_upgrade_cost_for_key(key)
	var accent = Color(0.0, 1.0, 0.82) if unlocked else Color(1.0, 0.22, 0.42)
	var body_top = panel.position.y + 108.0
	var icon_box = Rect2(panel.position.x + panel.size.x * 0.08, body_top + 18.0, panel.size.x * 0.26, panel.size.y * 0.42)
	game.draw_rect(icon_box, Color(0.015, 0.026, 0.04, 0.88), true)
	game.draw_rect(icon_box, Color(accent.r, accent.g, accent.b, 0.8), false, 2)
	if game.textures.has("aura_" + key) and game.textures["aura_" + key] != null:
		game._draw_texture_contain(game.textures["aura_" + key], icon_box.grow(-22.0), Color(1.0, 1.0, 1.0, 0.98 if unlocked else 0.28))
	else:
		game.draw_circle(icon_box.get_center(), min(icon_box.size.x, icon_box.size.y) * 0.24, Color(accent.r, accent.g, accent.b, 0.38))
	game._draw_centered(name.to_upper() if unlocked else "???", Vector2(icon_box.get_center().x, icon_box.end.y + 28.0), 22 if not portrait else 17, accent)
	game._draw_centered("NIVEL %d/%d" % [level, game.AuraSystem.RUN_MAX_LEVEL], Vector2(icon_box.get_center().x, icon_box.end.y + 56.0), 15, Color.WHITE)

	var info = Rect2(panel.position.x + panel.size.x * 0.39, body_top + 18.0, panel.size.x * 0.53, panel.size.y * 0.43)
	game.draw_rect(info, Color(0.01, 0.016, 0.028, 0.82), true)
	game.draw_rect(info, Color(accent.r, accent.g, accent.b, 0.64), false, 2)
	var headline = "PROXIMO NIVEL" if unlocked and not maxed else ("NIVEL MAXIMO" if maxed else "ESPECTRO BLOQUEADO")
	game._draw_centered(headline, Vector2(info.get_center().x, info.position.y + 30.0), 18, accent)
	var text_rect = Rect2(info.position + Vector2(24.0, 58.0), info.size - Vector2(48.0, 118.0))
	var lines: Array = []
	if not unlocked:
		var rule: Dictionary = game._spectrum_unlock_rule(key)
		lines.append("Desbloqueie este espectro antes de investir nucleos nele.")
		if not rule.is_empty():
			lines.append(game._spectrum_unlock_objective_text(key, true))
	elif maxed:
		lines.append("Este espectro ja atingiu o limite maximo da run.")
	else:
		lines = game._specter_upgrade_effect_lines()
		lines.append("Custo do upgrade: %d nucleos." % cost)
	game._draw_wrapped("\n".join(lines), text_rect, 14 if not portrait else 12, Color(0.86, 0.94, 1.0, 0.94))
	var status_text = game.specter_upgrade_message
	if status_text == "":
		status_text = "Saldo suficiente." if game._specter_can_upgrade() else ("Colete mais nucleos instaveis nas proximas runs." if unlocked and not maxed else "")
	game._draw_centered(status_text, Vector2(info.get_center().x, info.end.y - 34.0), 13 if not portrait else 11, Color(1.0, 0.86, 0.28, 0.96))

	var nav_y = panel.end.y - 92.0
	var nav_w = 76.0
	game.buttons["specter_upgrade_prev"] = Rect2(panel.position.x + 28.0, nav_y, nav_w, 46.0)
	game.buttons["specter_upgrade_next"] = Rect2(panel.end.x - 28.0 - nav_w, nav_y, nav_w, 46.0)
	var confirm_w: float = min(300.0, panel.size.x * 0.34)
	var continue_w: float = min(260.0, panel.size.x * 0.28)
	game.buttons["specter_upgrade_confirm"] = Rect2(panel.get_center().x - confirm_w - 8.0, nav_y, confirm_w, 46.0)
	game.buttons["specter_upgrade_continue"] = Rect2(panel.get_center().x + 8.0, nav_y, continue_w, 46.0)
	game._draw_big_button(game.buttons["specter_upgrade_prev"], "<", Color(0.02, 0.08, 0.12, 0.88), Color(0.5, 0.94, 1.0))
	game._draw_big_button(game.buttons["specter_upgrade_next"], ">", Color(0.02, 0.08, 0.12, 0.88), Color(0.5, 0.94, 1.0))
	var confirm_label = "EVOLUIR (%d)" % cost if unlocked and not maxed else "INDISPONIVEL"
	game._draw_big_button(game.buttons["specter_upgrade_confirm"], confirm_label, Color(0.02, 0.16, 0.14, 0.88) if game._specter_can_upgrade() else Color(0.09, 0.09, 0.11, 0.72), Color(0.0, 1.0, 0.82) if game._specter_can_upgrade() else Color(0.42, 0.48, 0.54))
	game._draw_big_button(game.buttons["specter_upgrade_continue"], "CONTINUAR", Color(0.12, 0.04, 0.08, 0.88), Color(1.0, 0.24, 0.42))


static func _draw_game_over_overlay(game: Node2D, viewport: Vector2) -> void :
	var t = float(Time.get_ticks_msec()) * 0.001
	var end_buttons = game._game_over_button_layout(viewport)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.015, 0.01, 0.02, 0.88), true)
	for gx in range(0, int(viewport.x) + 80, 80):
		for gy in range(0, int(viewport.y) + 80, 80):
			game.draw_circle(Vector2(gx, gy), 1.2, Color(1.0, 0.1, 0.28, 0.13))

	var center = viewport * 0.5
	var crack = PackedVector2Array()
	var crack_w = min(viewport.x * 0.62, 720.0)
	for i in range(18):
		var k = float(i) / 17.0
		var x = center.x - crack_w * 0.5 + crack_w * k
		var y = center.y - 58.0 + (k - 0.5) * 150.0 + sin(t * 6.0 + i * 1.77) * (10.0 + float(i % 3) * 7.0)
		crack.append(Vector2(x, y))
	for width_alpha in [[14.0, 0.08], [8.0, 0.18], [4.0, 0.52], [1.6, 0.94]]:
		var c = Color(1.0, 0.18, 0.42, float(width_alpha[1]))
		if float(width_alpha[0]) <= 4.0:
			c = Color(0.35, 1.0, 0.88, float(width_alpha[1]))
		game.draw_polyline(crack, c, float(width_alpha[0]), false)

	for i in range(38):
		var seed = float(i) * 19.17
		var x = fposmod(seed * 31.0 + sin(t * 0.8 + seed) * 140.0, viewport.x + 80.0) - 40.0
		var y = fposmod(viewport.y - t * (24.0 + float(i % 5) * 7.0) + seed * 23.0, viewport.y + 80.0) - 40.0
		var sz = 4.0 + float(i % 5)
		var rot = t * (0.8 + float(i % 4) * 0.22) + seed
		var shard = PackedVector2Array([
			Vector2(x, y) + Vector2.from_angle(rot) * sz, 
			Vector2(x, y) + Vector2.from_angle(rot + TAU / 3.0) * sz, 
			Vector2(x, y) + Vector2.from_angle(rot + TAU * 2.0 / 3.0) * sz
		])
		var sc = [Color(0.0, 1.0, 0.82, 0.3), Color(0.7, 0.34, 1.0, 0.28), Color(1.0, 0.12, 0.34, 0.3)][i % 3]
		game.draw_polygon(shard, PackedColorArray([sc]))

	var glitch = 3.0 if int(Time.get_ticks_msec() / 90) % 7 == 0 else 1.0
	game._draw_centered("FLUXO TEMPORAL ROMPIDO", Vector2(center.x - glitch, viewport.y * 0.2), 42 if not game._is_portrait(viewport) else 34, Color(0.0, 1.0, 0.82, 0.78))
	game._draw_centered("FLUXO TEMPORAL ROMPIDO", Vector2(center.x + glitch, viewport.y * 0.2), 42 if not game._is_portrait(viewport) else 34, Color(1.0, 0.0, 0.45, 0.78))
	game._draw_centered_outlined("FLUXO TEMPORAL ROMPIDO", Vector2(center.x, viewport.y * 0.2), 42 if not game._is_portrait(viewport) else 34, Color.WHITE, Color(0, 0, 0, 0.9), 3)
	game._draw_centered("A fenda colapsou o espaco-tempo. Sua jornada foi fragmentada.", Vector2(center.x, viewport.y * 0.29), 18 if not game._is_portrait(viewport) else 14, Color(0.74, 0.76, 0.84, 0.9))
	var summary = Rect2(viewport.x * (0.12 if not game._is_portrait(viewport) else 0.08), viewport.y * (0.32 if not game._is_portrait(viewport) else 0.3), viewport.x * (0.76 if not game._is_portrait(viewport) else 0.84), viewport.y * (0.18 if not game._is_portrait(viewport) else 0.27))
	game._draw_run_summary(summary, Color(1.0, 0.12, 0.28), true)
	if game.run_report_status != "":
		game._draw_centered(game.run_report_status.to_upper(), Vector2(center.x, summary.end.y + 22.0), 12, Color(0.82, 0.92, 1.0, 0.8))

	var retry_label = "TENTAR NOVAMENTE %d/%d" % [game.retry_charges_used + 1, game.RUN_RETRY_MAX_CHARGES] if game._retry_available() else "NOVA RUN"
	var labels = [
		["end_retry", retry_label, Color(0.0, 1.0, 0.82) if game._retry_available() else Color(0.72, 0.88, 0.96)], 
		["end_ranking", "ABRIR RANKING", Color(1.0, 0.28, 0.78)], 
		["end_menu", "VOLTAR AO MENU", Color(0.72, 0.34, 1.0)]
	]
	game.buttons.erase("end_exit")
	for i in range(labels.size()):
		var rect: Rect2 = end_buttons[String(labels[i][0])]
		game.buttons[String(labels[i][0])] = rect
		var accent: Color = labels[i][2]
		if game.is_gamepad_active and game.gameover_selected == i:
			accent = Color(1.0, 1.0, 1.0)
		var pulse = 0.18 + 0.08 * sin(t * 4.0 + i)
		game._draw_holo_panel(rect, accent, false, 0.68)
		game.draw_rect(rect.grow(-8), Color(0.02, 0.014, 0.025, 0.54 + pulse), true)
		game._draw_centered(String(labels[i][1]), rect.get_center() + Vector2(0, 4), 19 if not game._is_portrait(viewport) else 17, Color.WHITE)
	if game.retry_confirm_visible:
		game._draw_retry_confirm_popup(viewport)


static func _draw_retry_confirm_popup(game: Node2D, viewport: Vector2) -> void:
	var portrait = game._is_portrait(viewport)
	var panel_w: float = minf(viewport.x * (0.82 if not portrait else 0.9), 720.0)
	var panel_h: float = 270.0 if not portrait else 310.0
	var panel = Rect2(viewport.x * 0.5 - panel_w * 0.5, viewport.y * 0.5 - panel_h * 0.5, panel_w, panel_h)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, 0.42), true)
	game._draw_holo_panel(panel, Color(0.0, 1.0, 0.82), true, 0.9)
	game._draw_glitch_title("CONFIRMAR RETORNO", Vector2(panel.get_center().x, panel.position.y + 46.0), 26 if not portrait else 21, Color(0.0, 1.0, 0.82))
	var body_rect = Rect2(panel.position.x + 34.0, panel.position.y + 78.0, panel.size.x - 68.0, panel.size.y - 154.0)
	var lines: Array[String] = game._retry_confirm_lines()
	game._draw_wrapped_clamped("\n".join(lines), body_rect, 15 if not portrait else 13, Color(0.84, 0.94, 0.98, 0.96), 6)
	var btn_h: float = 46.0 if not portrait else 50.0
	var gap: float = 18.0
	var btn_w: float = minf(220.0, (panel.size.x - 82.0 - gap) * 0.5)
	var y: float = panel.end.y - btn_h - 28.0
	var no_rect = Rect2(panel.get_center().x - btn_w - gap * 0.5, y, btn_w, btn_h)
	var yes_rect = Rect2(panel.get_center().x + gap * 0.5, y, btn_w, btn_h)
	game.buttons["retry_confirm_no"] = no_rect
	game.buttons["retry_confirm_yes"] = yes_rect
	game._draw_big_button(no_rect, "NAO", Color(0.13, 0.04, 0.08, 0.94), Color(1.0, 0.24, 0.42))
	game._draw_big_button(yes_rect, "SIM", Color(0.02, 0.14, 0.12, 0.94), Color(0.0, 1.0, 0.82))


static func _draw_shop_return_transition_legacy(game: Node2D, viewport: Vector2) -> void:
	var progress: float = clampf(1.0 - game.shop_return_visual_timer / maxf(0.01, game.SHOP_RETURN_VISUAL_TIME), 0.0, 1.0)
	var center = viewport * 0.5
	var accent = Color(0.0, 1.0, 0.82)
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.0, lerpf(0.18, 0.035, progress)), true)
	for i in range(4):
		var radius: float = lerpf(38.0 + i * 34.0, 260.0 + i * 46.0, progress)
		var ring_alpha: float = (0.34 - i * 0.045) * (1.0 - progress * 0.78)
		game.draw_arc(center, radius, -progress * TAU + i * 0.42, TAU - progress * TAU + i * 0.42, 72, Color(accent.r, accent.g, accent.b, ring_alpha), 2.0)
	var return_panel = Rect2(viewport.x * 0.5 - 230.0, 34.0, 460.0, 70.0)
	game._draw_holo_panel(return_panel, Color(0.72, 1.0, 1.0), true, 0.72)
	var title: String = "SAINDO DA LOJA" if progress < 0.72 else "CAMPO ESTABILIZADO"
	game._draw_centered(title, return_panel.get_center() + Vector2(0, -7), 20, Color(0.72, 1.0, 1.0))
	game._draw_centered("RETOMANDO EM %.0fs" % max(0.0, ceil(game.shop_return_timer)), return_panel.get_center() + Vector2(0, 19), 13, Color(1.0, 0.88, 0.32))


static func _draw_retry_return_transition(game: Node2D, viewport: Vector2) -> void:
	var progress: float = clampf(1.0 - game.retry_return_timer / maxf(0.01, game.RETRY_RETURN_ANIM_TIME), 0.0, 1.0)
	var center = viewport * 0.5
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.012, 0.03, 0.94), true)
	for i in range(5):
		var radius: float = lerpf(260.0 - i * 38.0, 48.0 + i * 18.0, progress)
		var color = Color(0.0, 1.0, 0.82, 0.14 + progress * 0.16)
		game.draw_arc(center, radius, progress * TAU + i * 0.5, progress * TAU + TAU * 0.78 + i * 0.5, 80, color, 3.0)
	var frames: Array = game.textures.get("player_idle", [])
	if not frames.is_empty() and frames[0] is Texture2D:
		var rise: float = (1.0 - progress) * 110.0
		var alpha: float = clampf(progress * 1.4, 0.0, 1.0)
		game._draw_entity_fit(frames[0], center + Vector2(0.0, 44.0 - rise), Vector2(82.0, 118.0), Color(1.0, 1.0, 1.0, alpha), false)
	game._draw_glitch_title("GEOVANA RETORNANDO", Vector2(center.x, center.y - 126.0), 28 if not game._is_portrait(viewport) else 22, Color(0.0, 1.0, 0.82))
	game._draw_centered("recompondo a run salva...", Vector2(center.x, center.y + 130.0), 15, Color(0.82, 0.94, 1.0, 0.88))


static func _draw_run_summary(game: Node2D, area: Rect2, accent: Color, lost: bool) -> void :
	var entries = [
		["JOGADOR", game.player_nickname if game.player_nickname != "" else "SEM NICK"], 
		["RESULTADO", "EXTRACAO" if game.run_extracted else ("DERROTA" if lost else "VITORIA")], 
		["TEMPO", game._run_time_text()], 
		["INIMIGOS", str(game.enemies_killed)], 
		["DANO INIMIGOS", str(int(round(game.run_damage_to_enemies)))], 
		["PONTOS GANHOS", str(game.run_points_earned)], 
		["PONTOS GASTOS", str(game.run_points_spent)], 
		["CARTAS", str(game._deck_total_cards())], 
		["FASE DA QUEDA" if lost else "FASE CONCLUIDA", str(game.current_phase)]
	]
	var columns = 2 if game._is_portrait(game.get_viewport_rect().size) else 3
	var rows = int(ceil(float(entries.size()) / float(columns)))
	var gap = 8.0
	var cell_size = Vector2((area.size.x - gap * float(columns - 1)) / float(columns), (area.size.y - gap * float(rows - 1)) / float(rows))
	for i in range(entries.size()):
		var column = i % columns
		var row = int(i / columns)
		var rect = Rect2(area.position + Vector2(column * (cell_size.x + gap), row * (cell_size.y + gap)), cell_size)
		game.draw_rect(rect, Color(0.01, 0.015, 0.025, 0.82), true)
		game.draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.5), false, 1.4)
		var label_size = game._fit_text_size(String(entries[i][0]), rect.size.x - 14.0, 11, 8)
		game._draw_centered(String(entries[i][0]), Vector2(rect.get_center().x, rect.position.y + min(18.0, rect.size.y * 0.36)), label_size, Color(accent.r, accent.g, accent.b, 0.86))
		var value_size = game._fit_text_size(String(entries[i][1]), rect.size.x - 14.0, 22, 14)
		game._draw_centered(String(entries[i][1]), Vector2(rect.get_center().x, rect.end.y - min(12.0, rect.size.y * 0.24)), value_size, Color.WHITE)


static func _draw_shop_opening_upgrade(game: Node2D, viewport: Vector2) -> void :
	var progress = 1.0 - clamp(game.shop_opening_timer / game.SHOP_OPENING_ANIM_TIME, 0.0, 1.0)
	var camera = game._camera(viewport) + game._screen_shake_offset()
	var player_screen = (game.player_pos - camera).clamp(Vector2(58, 80), viewport - Vector2(58, 70))
	var ground = player_screen + Vector2(0, 34)
	var strike = smoothstep(0.0, 0.32, progress)
	var absorb = smoothstep(0.22, 0.62, progress)
	var spread = smoothstep(0.48, 1.0, progress)
	var fade = 1.0 - smoothstep(0.82, 1.0, progress)
	var flash = sin(progress * PI) * 0.28 + 0.08
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.06, 0.1, 0.13, flash * fade), true)

	var bolt_alpha = (1.0 - smoothstep(0.5, 0.88, progress)) * max(0.18, strike)
	var seed = float(Time.get_ticks_msec() % 100000) * 0.001
	for bolt in range(3):
		var previous = Vector2(player_screen.x + sin(seed * 7.0 + bolt) * 18.0, -26.0)
		var segments = 7
		for i in range(1, segments + 1):
			var t = float(i) / float(segments)
			var jitter = sin(seed * (9.0 + bolt) + i * 2.31 + bolt * 5.7) * (18.0 + bolt * 7.0) * (1.0 - t * 0.42)
			var next = Vector2(lerp(previous.x, player_screen.x, 0.36) + jitter, lerp(-26.0, player_screen.y - 18.0, t))
			var main_color = Color(0.68, 0.98, 1.0, 0.88 * bolt_alpha)
			var core_color = Color(1.0, 1.0, 1.0, 0.94 * bolt_alpha)
			game.draw_line(previous, next, main_color, 8.0 - bolt * 2.0)
			game.draw_line(previous, next, core_color, 3.0)
			if i in [2, 4, 6]:
				var branch_dir = Vector2.from_angle( - PI * 0.5 + sin(seed + i + bolt) * 1.8)
				game.draw_line(next, next + branch_dir * (34.0 + bolt * 12.0), Color(0.42, 0.92, 1.0, 0.34 * bolt_alpha), 2.0)
			previous = next

	var body_glow = sin(progress * PI) * fade
	for i in range(5):
		var radius = 30.0 + i * 15.0 + absorb * 18.0
		game.draw_circle(player_screen, radius, Color(0.15, 0.95, 1.0, body_glow * (0.11 - i * 0.015)))
	game.draw_circle(player_screen, 18.0 + 10.0 * absorb, Color(1.0, 1.0, 1.0, 0.24 * body_glow))

	for ring in range(4):
		var ring_t = clamp(spread - ring * 0.14, 0.0, 1.0)
		if ring_t <= 0.0:
			continue
		var radius = lerp(26.0 + ring * 12.0, 220.0 + ring * 26.0, ring_t)
		var alpha = (1.0 - ring_t) * 0.62 * fade
		game.draw_arc(ground, radius, 0.0, TAU, 96, Color(0.08, 0.92, 1.0, alpha), 4.0)
		game.draw_arc(ground, radius * 0.74, - progress * TAU, TAU * 0.62 - progress * TAU, 64, Color(1.0, 0.86, 0.3, alpha * 0.62), 2.0)

	for crack in range(12):
		var crack_t = clamp(spread - float(crack % 4) * 0.06, 0.0, 1.0)
		if crack_t <= 0.0:
			continue
		var angle = float(crack) * TAU / 12.0 + sin(seed + crack) * 0.14
		var length = lerp(22.0, 145.0 + float(crack % 3) * 34.0, crack_t)
		var start = ground + Vector2.from_angle(angle) * 18.0
		var mid = ground + Vector2.from_angle(angle + sin(seed * 1.7 + crack) * 0.16) * length * 0.58
		var end = ground + Vector2.from_angle(angle + cos(seed * 1.3 + crack) * 0.12) * length
		var alpha = (1.0 - crack_t * 0.62) * fade
		game.draw_line(start, mid, Color(0.0, 0.8, 1.0, alpha * 0.5), 3.0)
		game.draw_line(mid, end, Color(1.0, 0.9, 0.34, alpha * 0.38), 2.0)

	if progress > 0.72:
		var bloom = smoothstep(0.72, 1.0, progress)
		game.draw_circle(player_screen, 60.0 + bloom * 140.0, Color(1.0, 1.0, 1.0, 0.24 * (1.0 - bloom)))


static func _draw_big_button(game: Node2D, rect: Rect2, label: String, bg: Color, border: Color, selected: bool = false) -> void :
	game._draw_holo_panel(rect, border, selected, max(0.56, bg.a))
	game.draw_rect(rect.grow(-9), Color(bg.r, bg.g, bg.b, 0.42), true)


	var font_size = int(rect.size.y * 0.45)
	var text_size = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	while text_size.x > rect.size.x - 24 and font_size > 12:
		font_size -= 1
		text_size = game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)


	var y_offset = text_size.y * 0.16
	game._draw_centered(label, rect.get_center() + Vector2(0, y_offset), font_size, Color.WHITE)


static func _draw_button(game: Node2D, center: Vector2, radius: float, label: String, color: Color) -> void :
	var c = color
	var alpha: float = clampf(c.a, 0.0, 1.0)
	game.draw_circle(center, radius, Color(0.02, 0.03, 0.04, 0.3 * alpha))
	game.draw_circle(center, radius * 0.84, Color(c.r, c.g, c.b, 0.18 * alpha))
	game.draw_arc(center, radius, - PI * 0.28, PI * 1.24, 48, Color(c.r, c.g, c.b, 0.92 * alpha), 2.6)
	game.draw_arc(center, radius * 0.72, PI * 0.58, PI * 1.66, 32, Color(1.0, 1.0, 1.0, 0.34 * alpha), 1.4)
	var sweep: float = fposmod(game.time_alive * 1.7, TAU)
	game.draw_arc(center, radius * 0.9, sweep, sweep + 0.52, 18, Color(1.0, 1.0, 1.0, 0.34 * alpha), 1.8)
	for tick_index in range(4):
		var tick_angle: float = -PI * 0.7 + float(tick_index) * PI * 0.46
		var tick_from: Vector2 = center + Vector2.from_angle(tick_angle) * (radius * 0.88)
		var tick_to: Vector2 = center + Vector2.from_angle(tick_angle) * (radius * 0.98)
		game.draw_line(tick_from, tick_to, Color(c.r, c.g, c.b, 0.5 * alpha), 1.2, true)
	game.draw_circle(center, radius * 0.34, Color(c.r, c.g, c.b, 0.18 * alpha))
	game.draw_arc(center, radius * 0.44, -PI * 0.92, -PI * 0.2, 18, Color(1.0, 1.0, 1.0, 0.26 * alpha), 1.2)
	var font_size = int(clamp(radius * 0.34, 15.0, 22.0))
	game.draw_string(game.menu_ui_font, center + Vector2(-radius, font_size * 0.3), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, Color(1.0, 1.0, 1.0, alpha))


static func _draw_toggle_switch(game: Node2D, rect: Rect2, enabled: bool, accent: Color) -> void :
	var track = accent if enabled else Color(0.28, 0.32, 0.36)
	if game.mode.begins_with("settings"):
		track = Color(0.36, 0.72, 0.72) if enabled else Color(0.28, 0.32, 0.36)
	game.draw_rect(rect, Color(track.r, track.g, track.b, 0.3), true)
	game.draw_rect(rect, Color(track.r, track.g, track.b, 0.92), false, 2.0)
	var knob_radius = rect.size.y * 0.34
	var knob_x = rect.end.x - rect.size.y * 0.5 if enabled else rect.position.x + rect.size.y * 0.5
	game.draw_circle(Vector2(knob_x, rect.get_center().y), knob_radius, Color.WHITE)


static func _draw_tesla_health_bar_fx(game: Node2D, pos: Vector2, width: float, ratio: float, shock_time: float, uid: int) -> void :
	var power: float = clamp(shock_time / 0.42, 0.0, 1.0)
	var filled_width: float = max(10.0, width * clamp(ratio, 0.0, 1.0))
	var base_y: float = pos.y + 3.5
	var bolt_points = PackedVector2Array([
		Vector2(pos.x, base_y - 6.0), 
		Vector2(pos.x + filled_width * 0.3, base_y - 6.0), 
		Vector2(pos.x + filled_width * 0.2, base_y - 15.0), 
		Vector2(pos.x + filled_width * 0.62, base_y + 1.0), 
		Vector2(pos.x + filled_width * 0.44, base_y + 1.0), 
		Vector2(pos.x + filled_width * 0.6, base_y + 11.0), 
		Vector2(pos.x + filled_width, base_y - 4.0), 
		Vector2(pos.x + filled_width * 0.64, base_y + 5.0), 
		Vector2(pos.x + filled_width * 0.78, base_y + 15.0), 
		Vector2(pos.x + filled_width * 0.36, base_y - 1.0), 
		Vector2(pos.x + filled_width * 0.52, base_y - 1.0), 
		Vector2(pos.x + filled_width * 0.34, base_y - 10.0)
	])
	var jitter = Vector2(sin(game.time_alive * 82.0 + uid) * 1.8, cos(game.time_alive * 71.0 + uid) * 1.4) * power
	for i in range(bolt_points.size()):
		var local_jitter = Vector2(sin(game.time_alive * 92.0 + float(uid) * 0.2 + i) * 1.2, cos(game.time_alive * 88.0 + i * 1.7) * 1.0) * power
		bolt_points[i] += jitter + local_jitter
	var full_outline = PackedVector2Array([
		Vector2(pos.x - 3.0, base_y - 8.5), 
		Vector2(pos.x + width * 0.34, base_y - 8.5), 
		Vector2(pos.x + width * 0.24, base_y - 18.0), 
		Vector2(pos.x + width * 0.68, base_y - 0.5), 
		Vector2(pos.x + width * 0.5, base_y - 0.5), 
		Vector2(pos.x + width * 0.66, base_y + 10.5), 
		Vector2(pos.x + width + 4.0, base_y - 5.5), 
		Vector2(pos.x + width * 0.68, base_y + 7.5), 
		Vector2(pos.x + width * 0.83, base_y + 18.0), 
		Vector2(pos.x + width * 0.34, base_y + 1.5), 
		Vector2(pos.x + width * 0.48, base_y + 1.5), 
		Vector2(pos.x + width * 0.29, base_y - 8.5)
	])
	game.draw_polyline(full_outline, Color(0.05, 0.0, 0.1, 0.88 * power), 8.0, true)
	game.draw_polyline(full_outline, Color(0.78, 0.14, 1.0, 0.96 * power), 4.0, true)
	game.draw_polyline(bolt_points, Color(1.0, 0.86, 0.1, 0.88 * power), 5.0, true)
	game.draw_polyline(bolt_points, Color(0.32, 0.98, 1.0, 0.82 * power), 2.0, true)
	game.draw_polyline(bolt_points, Color(1.0, 1.0, 1.0, 0.58 * power), 0.9, true)
	for spark in range(3):
		var t: float = 0.18 + spark * 0.27 + sin(game.time_alive * 24.0 + spark + uid) * 0.04
		var a = Vector2(pos.x + filled_width * t, base_y - 9.0 + sin(game.time_alive * 60.0 + spark) * 3.0)
		var b = a + Vector2(7.0 + spark * 2.0, 10.0 + sin(game.time_alive * 42.0 + uid + spark) * 5.0)
		game.draw_line(a, b, Color(0.93, 0.52, 1.0, 0.7 * power), 1.4, true)


static func _draw_centered_outlined(game: Node2D, text: String, pos: Vector2, size: int, color: Color, outline: Color, thickness: int) -> void :
	var offsets = [
		Vector2( - thickness, 0), 
		Vector2(thickness, 0), 
		Vector2(0, - thickness), 
		Vector2(0, thickness), 
		Vector2( - thickness, - thickness), 
		Vector2(thickness, - thickness), 
		Vector2( - thickness, thickness), 
		Vector2(thickness, thickness)
	]
	for offset in offsets:
		game._draw_centered(text, pos + offset, size, outline)
	game._draw_centered(text, pos + Vector2(0, thickness * 0.45), size, Color(0.0, 0.0, 0.0, min(0.55, outline.a)))
	game._draw_centered(text, pos, size, color)


static func _draw_wrapped(game: Node2D, text: String, rect: Rect2, size: int, color: Color) -> void :
	var words = text.split(" ")
	var line = ""
	var y = rect.position.y + size
	for word in words:
		var test = line + (" " if line != "" else "") + word
		if game.font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x and line != "":
			game.draw_string(game.font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
			line = word
			y += size + 4
			if y > rect.end.y:
				return
		else:
			line = test
	if line != "" and y <= rect.end.y:
		game.draw_string(game.font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func _draw_wrapped_clamped(game: Node2D, text: String, rect: Rect2, size: int, color: Color, max_lines: int) -> void:
	if max_lines <= 0:
		game._draw_wrapped(text, rect, size, color)
		return
	var words = text.replace("\n", " ").split(" ")
	var line = ""
	var y = rect.position.y + size
	var lines_drawn = 0
	for word in words:
		var clean_word = String(word).strip_edges()
		if clean_word == "":
			continue
		var test = line + (" " if line != "" else "") + clean_word
		if game.font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x and line != "":
			lines_drawn += 1
			if lines_drawn >= max_lines or y > rect.end.y:
				var final_line = line
				while final_line.length() > 3 and game.font.get_string_size(final_line + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x:
					final_line = final_line.substr(0, final_line.length() - 1).strip_edges()
				game.draw_string(game.font, Vector2(rect.position.x, y), final_line + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
				return
			game.draw_string(game.font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
			line = clean_word
			y += size + 4
		else:
			line = test
	if line != "" and y <= rect.end.y and lines_drawn < max_lines:
		game.draw_string(game.font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func _draw_corner_limbo(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	var rects: Array[Rect2] = game._corner_limbo_rects(camera, viewport)
	if rects.is_empty():
		return
	var pulse: float = 0.5 + 0.5 * sin(game.time_alive * 1.7)
	for idx in range(rects.size()):
		var rect: Rect2 = rects[idx]
		game.draw_rect(rect, Color(0.005, 0.008, 0.026, 0.96), true)
		game.draw_rect(rect, Color(0.0, 0.72, 0.78, 0.1), false, 1.0)
		var grid_start_x: float = floor(rect.position.x / game.CORNER_LIMBO_GRID_STEP) * game.CORNER_LIMBO_GRID_STEP
		var grid_start_y: float = floor(rect.position.y / game.CORNER_LIMBO_GRID_STEP) * game.CORNER_LIMBO_GRID_STEP
		var x: float = grid_start_x
		while x <= rect.end.x:
			game.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.0, 0.72, 0.78, 0.055), 1.0)
			x += game.CORNER_LIMBO_GRID_STEP
		var y: float = grid_start_y
		while y <= rect.end.y:
			game.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.36, 0.12, 0.8, 0.045), 1.0)
			y += game.CORNER_LIMBO_GRID_STEP
		for i in range(game.CORNER_LIMBO_STAR_COUNT):
			var star_seed: int = idx * 1000 + i * 17
			var pos: Vector2 = rect.position + Vector2(game._limbo_hash(star_seed) * rect.size.x, game._limbo_hash(star_seed + 7) * rect.size.y)
			var size: float = 1.0 + game._limbo_hash(star_seed + 13) * 1.8
			var alpha: float = 0.42 + game._limbo_hash(star_seed + 19) * 0.38 + pulse * 0.12
			game.draw_circle(pos, size, Color(0.74, 0.94, 1.0, alpha))
			if i % 9 == 0:
				game.draw_line(pos + Vector2(-4.0, 0.0), pos + Vector2(4.0, 0.0), Color(0.0, 0.95, 1.0, alpha * 0.35), 1.0)
				game.draw_line(pos + Vector2(0.0, -4.0), pos + Vector2(0.0, 4.0), Color(0.7, 0.32, 1.0, alpha * 0.25), 1.0)
		if rect.position.x <= 0.0 and rect.end.x < viewport.x:
			game.draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.end.y), Color(0.0, 0.95, 1.0, 0.38), 2.0)
		if rect.position.y <= 0.0 and rect.end.y < viewport.y:
			game.draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.end.y), Color(0.0, 0.95, 1.0, 0.34), 2.0)
		if rect.end.x >= viewport.x and rect.position.x > 0.0:
			game.draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x, rect.end.y), Color(0.0, 0.95, 1.0, 0.38), 2.0)
		if rect.end.y >= viewport.y and rect.position.y > 0.0:
			game.draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.end.x, rect.position.y), Color(0.0, 0.95, 1.0, 0.34), 2.0)


static func _draw_pause_mp_request(game: Node2D, viewport: Vector2) -> void :
	var panel_w = minf(460.0, viewport.x * 0.86)
	var panel_h = 132.0 if game.pause_mp_request_incoming else 82.0
	var panel = Rect2(viewport.x * 0.5 - panel_w * 0.5, viewport.y - panel_h - 24.0, panel_w, panel_h)
	var accent = Color(0.38, 0.84, 1.0) if game.pause_mp_target_paused else Color(0.34, 1.0, 0.58)
	game._draw_holo_panel(panel, accent, true, 0.88)
	var action_text = "PAUSAR" if game.pause_mp_target_paused else "RETOMAR"
	var title = "EQUIPE QUER %s" % action_text if game.pause_mp_request_incoming else "PEDIDO PARA %s ENVIADO" % action_text
	game._draw_centered(title, Vector2(panel.get_center().x, panel.position.y + 30.0), 15, accent)
	game._draw_centered("CONFIRMACOES %d/%d" % [game.pause_mp_vote_count, game.pause_mp_expected_count], Vector2(panel.get_center().x, panel.position.y + 56.0), 12, Color.WHITE)
	game.buttons.erase("pause_mp_accept")
	if game.pause_mp_request_incoming:
		game._draw_centered("CLIQUE OU ENTER/ESPACO", Vector2(panel.get_center().x, panel.position.y + 78.0), 11, Color(0.88, 0.96, 1.0))
		game.buttons["pause_mp_accept"] = game._pause_mp_accept_rect(viewport)
		game._draw_small_rect_button(game.buttons["pause_mp_accept"], "CONCORDAR  ENTER", Color(0.03, 0.14, 0.18, 0.94), accent)


static func _draw_graphics_settings(game: Node2D, viewport: Vector2) -> void :
	game._draw_settings_shell(viewport, "Gráficos", "Ajuste a atmosfera e encontre o melhor desempenho.")
	game.settings_buttons = game._graphics_settings_rects(viewport)
	var keys = game._graphics_setting_keys()
	for i in range(keys.size()):
		var key = String(keys[i])
		if key == "back":
			game._draw_settings_card(game.settings_buttons[key], "VOLTAR", "retornar as configuracoes", Color(1.0, 0.26, 0.36), game.settings_selected == i)
			continue
		game._draw_gameplay_preference(game.settings_buttons[key], game._graphics_setting_title(key), game._graphics_setting_subtitle(key), game._graphics_setting_value(key), game._graphics_setting_color(key), game.settings_selected == i)


static func _draw_online_create_room(game: Node2D, viewport: Vector2) -> void:
	var accent = Color(1.0, 0.44, 0.88)
	game._draw_online_header(viewport, "CRIAR SALA ONLINE", accent, "defina nome, senha e convide a equipe")
	game._sync_online_room_input_rects(viewport)
	var panel = game._online_create_panel_rect(viewport)
	game._draw_holo_panel(panel, accent, true, 0.68)
	var status = game.online_status if game.online_status != "" else "CONFIGURE SUA SALA"
	game._draw_centered(status, panel.position + Vector2(panel.size.x * 0.5, 54.0), 18, Color.WHITE)

	var name_rect = game._online_create_name_input_rect(viewport)
	var password_rect = game._online_create_password_input_rect(viewport)
	game._draw_online_input_backing(name_rect, "NOME DA SALA", accent)
	game._draw_online_input_backing(password_rect, "SENHA", accent)
	var visibility_label = "PUBLICA" if game.online_room_password.strip_edges() == "" else "PRIVADA"
	var info_rect = Rect2(panel.position.x + 44.0, panel.position.y + 294.0, panel.size.x - 88.0, 56.0)
	game._draw_holo_panel(info_rect, Color(0.0, 1.0, 0.82), false, 0.32)
	game._draw_centered("VISIBILIDADE: " + visibility_label, info_rect.position + Vector2(info_rect.size.x * 0.5, 24.0), 14, Color(0.0, 1.0, 0.82))
	game._draw_centered("sem senha aparece aberta; com senha exige confirmacao ao entrar", info_rect.position + Vector2(info_rect.size.x * 0.5, 44.0), 11, Color(0.76, 0.94, 1.0, 0.82))

	var button_y = panel.end.y - 76.0
	game.buttons["online_create_submit"] = Rect2(panel.position.x + 44.0, button_y, panel.size.x * 0.52, 48.0)
	game.buttons["online_create_back"] = Rect2(panel.end.x - panel.size.x * 0.34 - 44.0, button_y, panel.size.x * 0.34, 48.0)
	game._draw_big_button(game.buttons["online_create_submit"], "CRIAR SALA", Color(0.05, 0.12, 0.12, 0.92), Color(0.0, 1.0, 0.82))
	game._draw_big_button(game.buttons["online_create_back"], "VOLTAR", Color(0.1, 0.05, 0.07, 0.92), Color(1.0, 0.24, 0.34))


static func _draw_online_find_room(game: Node2D, viewport: Vector2) -> void:
	var accent = Color(0.0, 1.0, 0.82)
	game._draw_online_header(viewport, "PROCURAR SALA", accent, "entre por lista publica ou codigo privado")
	game._sync_online_room_input_rects(viewport)
	for key in game.buttons.keys():
		var button_key = String(key)
		if button_key.begins_with("room_select_"):
			game.buttons.erase(button_key)
	var panel = game._online_find_panel_rect(viewport)
	game._draw_holo_panel(panel, accent, true, 0.64)
	var status = game.online_status if game.online_status != "" else "BUSCANDO SALAS ONLINE..."
	game._draw_centered(status, panel.position + Vector2(panel.size.x * 0.5, 48.0), 18, Color.WHITE)

	var list_rect = Rect2(panel.position.x + 36.0, panel.position.y + 80.0, panel.size.x - 72.0, panel.size.y - 260.0)
	game._draw_holo_panel(list_rect, accent, false, 0.22)
	if game.online_room_list.is_empty():
		game._draw_centered("NENHUMA SALA ABERTA", list_rect.get_center() + Vector2(0.0, -12.0), 18, Color(1.0, 0.82, 0.24))
		game._draw_centered("use um codigo privado ou atualize a lista", list_rect.get_center() + Vector2(0.0, 18.0), 12, Color(0.76, 0.94, 1.0, 0.82))
	else:
		var row_h: float = min(58.0, (list_rect.size.y - 18.0) / float(mini(5, game.online_room_list.size())))
		var visible_count: int = mini(5, game.online_room_list.size())
		for i in range(visible_count):
			var room: Dictionary = Dictionary(game.online_room_list[i])
			var row = Rect2(list_rect.position.x + 16.0, list_rect.position.y + 12.0 + float(i) * (row_h + 8.0), list_rect.size.x - 32.0, row_h)
			game.buttons["room_select_" + str(i)] = row
			game._draw_online_room_row(row, room, i == game.lobby_client_selected)

	var code_rect = game._online_find_code_input_rect(viewport)
	var password_rect = game._online_find_password_input_rect(viewport)
	game._draw_online_input_backing(code_rect, "CODIGO", accent)
	game._draw_online_input_backing(password_rect, "SENHA", accent)
	game.buttons["online_find_join"] = Rect2(panel.end.x - 176.0, panel.end.y - 150.0, 132.0, 44.0)
	game.buttons["room_refresh"] = Rect2(panel.position.x + 44.0, panel.end.y - 74.0, 190.0, 44.0)
	game.buttons["lobby_cancel"] = Rect2(panel.end.x - 234.0, panel.end.y - 74.0, 190.0, 44.0)
	game._draw_big_button(game.buttons["online_find_join"], "ENTRAR", Color(0.04, 0.14, 0.13, 0.92), accent)
	game._draw_big_button(game.buttons["room_refresh"], "ATUALIZAR", Color(0.04, 0.14, 0.13, 0.92), Color(0.72, 1.0, 0.94))
	game._draw_big_button(game.buttons["lobby_cancel"], "VOLTAR", Color(0.1, 0.05, 0.05, 0.92), Color(1.0, 0.24, 0.34))


static func _draw_online_room_row(game: Node2D, rect: Rect2, room: Dictionary, selected: bool) -> void:
	var accent = Color(0.0, 1.0, 0.82) if not bool(room.get("locked", false)) else Color(1.0, 0.82, 0.24)
	game._draw_holo_panel(rect, accent, selected, 0.34 if not selected else 0.52)
	var code = String(room.get("code", "------"))
	var name = String(room.get("name", "Sala " + code))
	var players = int(room.get("players", 1))
	var max_players = int(room.get("maxPlayers", game.ONLINE_MAX_PLAYERS))
	var lock_text = "COM SENHA" if bool(room.get("locked", false)) else "PUBLICA"
	game.draw_string(game.font, rect.position + Vector2(18.0, 24.0), name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.52, game._fit_text_size(name.to_upper(), rect.size.x * 0.52, 16, 11), Color.WHITE)
	game.draw_string(game.font, rect.position + Vector2(18.0, 45.0), "CODIGO " + code, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x * 0.36, 11, Color(0.72, 0.94, 1.0, 0.86))
	game._draw_centered("%d/%d" % [players, max_players], rect.position + Vector2(rect.size.x * 0.72, rect.size.y * 0.5 + 5.0), 16, accent)
	game._draw_centered(lock_text, rect.position + Vector2(rect.size.x * 0.9, rect.size.y * 0.5 + 5.0), 12, accent)


static func _draw_online_lobby_roster(game: Node2D, rect: Rect2, accent: Color) -> void:
	game._draw_online_label("TRIPULACAO", Rect2(rect.position + Vector2(14, 0), Vector2(rect.size.x - 28, 32)), 18, Color.WHITE)
	var roster: Array = game.online_lobby_roster.duplicate()
	if roster.is_empty():
		roster.append({"peer_id": game._mp_unique_id(), "name": game.player_nickname if game.player_nickname != "" else "Voce", "owner": game.online_room_owner, "ready": game.online_room_owner, "spectator": false})
	var row_h: float = minf(72.0, (rect.size.y - 44.0) / float(maxi(1, mini(4, roster.size()))))
	var visible_count: int = mini(4, roster.size())
	for i in range(visible_count):
		var entry: Dictionary = Dictionary(roster[i])
		var y: float = rect.position.y + 40.0 + float(i) * row_h
		var row = Rect2(rect.position.x + 14.0, y, rect.size.x - 28.0, row_h - 8.0)
		var is_owner_entry: bool = bool(entry.get("owner", false))
		var is_ready_entry: bool = bool(entry.get("ready", false))
		var spectator = bool(entry.get("spectator", false))
		var row_color = Color(1.0, 0.82, 0.24) if is_owner_entry else (Color(0.62, 0.42, 1.0) if spectator else accent)
		game.draw_rect(row, Color(0.025, 0.05, 0.055, 0.96))
		game.draw_rect(Rect2(row.position, Vector2(3, row.size.y)), row_color)
		game._draw_online_label("%02d" % (i + 1), Rect2(row.position + Vector2(14, 0), Vector2(38, row.size.y)), 20, row_color)
		game._draw_online_label(String(entry.get("name", "Player")), Rect2(row.position + Vector2(62, 0), Vector2(row.size.x * 0.48 - 62, row.size.y)), 20, Color.WHITE)
		var role = "HOST / LIDER" if is_owner_entry else ("ESPECTADOR" if spectator else "ALIADO")
		game._draw_online_label(role, Rect2(row.position + Vector2(row.size.x * 0.52, 0), Vector2(row.size.x * 0.23, row.size.y)), 15, row_color)
		var status: String = "ASSISTINDO" if spectator else ("PRONTO" if is_ready_entry or is_owner_entry else "AGUARDANDO")
		game._draw_online_label(status, Rect2(row.position + Vector2(row.size.x * 0.78, 0), Vector2(row.size.x * 0.22 - 12, row.size.y)), 15, Color(0.2, 1.0, 0.52) if is_ready_entry or is_owner_entry else Color(1.0, 0.82, 0.24))


static func _draw_lobby_online_host(game: Node2D, viewport: Vector2) -> void :
	var accent = Color(0.18, 0.86, 0.78)
	game._draw_online_header(viewport, "SALA ONLINE", accent, "HOST / LIDER DA EQUIPE")

	var panel = Rect2(viewport.x * 0.5 - min(1040.0, viewport.x * 0.86) * 0.5, viewport.y * 0.17, min(1040.0, viewport.x * 0.86), viewport.y * 0.68)
	game.draw_rect(panel, Color(0.015, 0.025, 0.028, 0.94))
	game.draw_line(panel.position, Vector2(panel.end.x, panel.position.y), accent, 2.0)

	var room_title = game.online_room_name if game.online_room_name != "" else "Sala " + (game.online_room_code if game.online_room_code != "" else "Online")
	game.draw_string(game.font, panel.position + Vector2(34.0, 44.0), room_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x * 0.56, game._fit_text_size(room_title.to_upper(), panel.size.x * 0.56, 22, 14), Color.WHITE)
	var code_text = "CODIGO " + (game.online_room_code if game.online_room_code != "" else "------")
	var lock_text = "PRIVADA" if game.online_room_locked else "PUBLICA"
	game._draw_centered(code_text, panel.position + Vector2(panel.size.x * 0.72, 39.0), 15, Color(0.0, 1.0, 0.82))
	game._draw_centered(lock_text, panel.position + Vector2(panel.size.x * 0.9, 39.0), 13, Color(1.0, 0.82, 0.24) if game.online_room_locked else Color(0.0, 1.0, 0.82))

	var status = game.online_status
	if status == "":
		status = "CONECTADO AO SERVIDOR" if game.online_connected else "INICIANDO SERVIDOR..."
	game._draw_centered(status, panel.position + Vector2(panel.size.x * 0.5, 82.0), 15, Color(0.82, 0.94, 1.0, 0.92))

	var roster_rect = Rect2(panel.position.x + 34.0, panel.position.y + 112.0, panel.size.x - 68.0, panel.size.y - 226.0)
	game._draw_online_lobby_roster(roster_rect, accent)

	var client_ready = game._online_client_ready()
	var active_players = game.online_lobby_active_player_count if game.online_lobby_active_player_count > 0 else game.online_lobby_connected_count
	var spectators = game.online_lobby_spectator_count
	var info_text = "AGUARDANDO JOGADOR (%d/%d)" % [game.online_lobby_connected_count, game.ONLINE_MAX_PLAYERS] if game.online_lobby_connected_count < game.ONLINE_MIN_PLAYERS else ("EQUIPE PRONTA! %d JOG. / %d ESP." % [active_players, spectators] if client_ready else "AGUARDANDO EQUIPE: %d/%d PRONTOS" % [game.online_lobby_ready_count, maxi(0, active_players - 1)])
	game._draw_centered(info_text, panel.position + Vector2(panel.size.x * 0.5, panel.size.y - 86.0), 14, Color(0.0, 1.0, 0.82) if client_ready else Color(1.0, 0.82, 0.24))

	game.buttons["lobby_start"] = Rect2(panel.position.x + 34.0, panel.end.y - 66.0, panel.size.x * 0.56, 46.0)
	game.buttons["lobby_cancel"] = Rect2(panel.end.x - panel.size.x * 0.32 - 34.0, panel.end.y - 66.0, panel.size.x * 0.32, 46.0)

	var can_start = game.online_lobby_connected_count >= game.ONLINE_MIN_PLAYERS and client_ready
	var start_color = Color(1.0, 1.0, 1.0) if (game.is_gamepad_active and game.lobby_host_selected == 0) else (Color(0.0, 1.0, 0.82) if can_start else Color(0.5, 0.5, 0.5))
	game._draw_big_button(game.buttons["lobby_start"], "ESCOLHER HABILIDADES", Color(0.1, 0.1, 0.1, 0.9), start_color)
	game._draw_big_button(game.buttons["lobby_cancel"], "CANCELAR", Color(0.1, 0.05, 0.05, 0.9), Color(1.0, 1.0, 1.0) if (game.is_gamepad_active and game.lobby_host_selected == 1) else Color(1.0, 0.2, 0.2))


static func _draw_lobby_online_client(game: Node2D, viewport: Vector2) -> void :
	var accent = Color(0.0, 1.0, 0.82)
	game._draw_online_header(viewport, "SALA ONLINE", accent, "EQUIPE / AGUARDANDO O HOST")
	if not game.online_connected and game.online_room_code == "":
		game._draw_online_find_room(viewport)
		return

	var panel = Rect2(viewport.x * 0.5 - min(980.0, viewport.x * 0.86) * 0.5, viewport.y * 0.17, min(980.0, viewport.x * 0.86), viewport.y * 0.68)
	game.draw_rect(panel, Color(0.015, 0.025, 0.028, 0.94))
	game.draw_line(panel.position, Vector2(panel.end.x, panel.position.y), accent, 2.0)

	var room_title = game.online_room_name if game.online_room_name != "" else "Sala " + (game.online_room_code if game.online_room_code != "" else "Online")
	game.draw_string(game.font, panel.position + Vector2(34.0, 44.0), room_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, panel.size.x * 0.56, game._fit_text_size(room_title.to_upper(), panel.size.x * 0.56, 22, 14), Color.WHITE)
	if game.online_room_code != "":
		game._draw_centered("CODIGO " + game.online_room_code, panel.position + Vector2(panel.size.x * 0.76, 39.0), 15, accent)
	var status = game.online_status
	if status == "":
		status = "CONECTADO" if game.online_connected else "BUSCANDO SALA..."
	game._draw_centered(status, panel.position + Vector2(panel.size.x * 0.5, 82.0), 15, Color(0.82, 0.94, 1.0, 0.92))

	var roster_rect = Rect2(panel.position.x + 34.0, panel.position.y + 112.0, panel.size.x - 68.0, panel.size.y - 228.0)
	game._draw_online_lobby_roster(roster_rect, accent)

	var active_players = game.online_lobby_active_player_count if game.online_lobby_active_player_count > 0 else game.online_lobby_connected_count
	var info_text = "AGUARDANDO CONEXAO (%d/%d JOGADORES)" % [game.online_lobby_connected_count, game.ONLINE_MAX_PLAYERS] if game.online_lobby_connected_count < game.ONLINE_MIN_PLAYERS else "SALA ONLINE: %d JOG. / %d ESP." % [active_players, game.online_lobby_spectator_count]
	game._draw_centered(info_text, panel.position + Vector2(panel.size.x * 0.5, panel.size.y - 90.0), 14, Color.WHITE)

	game.buttons["lobby_ready"] = Rect2(panel.position.x + 34.0, panel.end.y - 66.0, panel.size.x * 0.42, 46.0)
	game.buttons["lobby_spectator"] = Rect2(panel.position.x + panel.size.x * 0.49, panel.end.y - 66.0, panel.size.x * 0.24, 46.0)
	game.buttons["lobby_cancel"] = Rect2(panel.end.x - panel.size.x * 0.2 - 34.0, panel.end.y - 66.0, panel.size.x * 0.2, 46.0)

	var ready_bg = Color(0.05, 0.2, 0.1, 0.9) if game.local_player_ready else Color(0.1, 0.1, 0.1, 0.9)
	var ready_border = accent if game.online_connected else Color(0.5, 0.5, 0.5)
	var ready_text = "ESPECTADOR" if game.online_local_spectator else ("PRONTO CONFIRMADO" if game.online_local_ready_confirmed else ("CONFIRMANDO..." if game.online_lobby_ready_pending else ("ESTOU PRONTO" if game.local_player_ready else "MARCAR PRONTO")))
	var spectator_text = "JOGAR" if game.online_local_spectator else "ASSISTIR"

	game._draw_big_button(game.buttons["lobby_ready"], ready_text, ready_bg, ready_border if not game.online_local_spectator else Color(0.45, 0.62, 0.7))
	game._draw_big_button(game.buttons["lobby_spectator"], spectator_text, Color(0.04, 0.12, 0.18, 0.9), Color.WHITE if (game.is_gamepad_active and game.lobby_client_selected == 1) else Color(0.35, 0.85, 1.0))
	game._draw_big_button(game.buttons["lobby_cancel"], "SAIR", Color(0.1, 0.05, 0.05, 0.9), Color.WHITE if (game.is_gamepad_active and game.lobby_client_selected == 2) else Color(1.0, 0.2, 0.2))
