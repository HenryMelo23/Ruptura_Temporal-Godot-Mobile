import sys

def main():
    with open('scripts/main.gd', 'r', encoding='utf-8') as f:
        lines = f.readlines()

    draw_menu_code = """func _draw_menu(viewport: Vector2) -> void:
	var msec = Time.get_ticks_msec()
	var cycle_pos = msec % 6950
	var current_bg: Texture2D = null
	if cycle_pos < 5000:
		current_bg = textures["menu_panels"][0]
	else:
		var trans_pos = int((cycle_pos - 5000) / 150)
		var sequence = [0, 3, 1, 3, 4, 2, 1, 2, 3, 4, 2, 1, 4]
		var idx = clamp(trans_pos, 0, sequence.size() - 1)
		current_bg = textures["menu_panels"][sequence[idx]]

	var accent = Color(0.0, 1.0, 0.82)
	_draw_holo_background(viewport, current_bg, accent)
	var portrait = _is_portrait(viewport)
	menu_buttons = _menu_rects(viewport)
	menu_selected = clampi(menu_selected, 0, max(0, _menu_option_count() - 1))

	var safe = max(16.0, min(viewport.x, viewport.y) * 0.03)
	var title_size = 32 if portrait else 42
	var title_pos = Vector2(viewport.x * 0.5, safe + title_size * (0.60 if portrait else 0.85))
	_draw_glitch_title("RUPTURA TEMPORAL", title_pos, title_size, accent)

	var top_chip = Rect2(viewport.x * 0.5 - (150.0 if portrait else 180.0), title_pos.y + title_size * (0.48 if portrait else 0.55), 300.0 if portrait else 360.0, 26.0)
	_draw_hub_chip(top_chip, "RUPTURA " + GAME_VERSION + " // HUB TEMPORAL", accent, true)
	if player_nickname != "":
		var nick_chip = Rect2(top_chip.position.x, top_chip.end.y + 6.0, top_chip.size.x, 22.0)
		_draw_hub_chip(nick_chip, "OPERADORA: " + player_nickname, Color(0.72, 0.92, 1.0), false)

	if menu_buttons.has("continue"):
		_draw_hub_button(menu_buttons["continue"], "CONTINUAR RUN", _interrupted_run_detail_text(), Color(0.0, 1.0, 0.78), menu_selected == _menu_index_for("continue"), true, "continue")
	_draw_hub_button(menu_buttons["start"], "NOVA SOLO RUN" if interrupted_run_available else "SOLO RUN", "selecao de manifestacao", Color(0.24, 0.85, 1.0), menu_selected == _menu_index_for("start"), not interrupted_run_available, "start")
	_draw_hub_button(menu_buttons["catalog"], "CATALOGO", "bestiario e cartas", Color(0.42, 0.78, 1.0), menu_selected == _menu_index_for("catalog"), false, "catalog")
	_draw_hub_button(menu_buttons["settings"], "CONFIGURACOES", "controles e jogo", Color(1.0, 0.75, 0.22), menu_selected == _menu_index_for("settings"), false, "settings")
	if QA_STREAMING_FEATURE_ENABLED and qa_streaming_unlocked and menu_buttons.has("stream"):
		var stream_active := qa_streaming_native_active or qa_streaming_desktop_ffmpeg_active or qa_streaming_frame_active or qa_streaming_in_flight
		var stream_title := "ENCERRAR STREAM" if stream_active else "STREAM QA"
		var stream_subtitle := _qa_stream_menu_subtitle()
		var stream_color := Color(0.0, 1.0, 0.82) if stream_active else Color(0.38, 0.88, 1.0)
		_draw_hub_button(menu_buttons["stream"], stream_title, stream_subtitle, stream_color, menu_selected == _menu_index_for("stream"), false, "stream")
	_draw_hub_button(menu_buttons["exit"], "SAIR DO JOGO", "fechar aplicacao", Color(1.0, 0.28, 0.40), menu_selected == _menu_index_for("exit"), false, "exit")

	draw_string(font, Vector2(safe, viewport.y - safe * 0.5), "v" + GAME_VERSION, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.74, 0.92, 1.0, 0.75))
"""

    draw_hub_btn_code = """func _draw_hub_button(rect: Rect2, label: String, detail: String, accent: Color, is_selected: bool, primary := false, button_type := "") -> void:
	var msec = Time.get_ticks_msec()
	var fill_alpha = 0.84 if is_selected else (0.65 if primary else 0.50)
	var bg_color = Color(0.02, 0.05, 0.09, fill_alpha)
	draw_rect(rect, bg_color, true)

	var sheen = Rect2(rect.position + Vector2(2, 2), Vector2(rect.size.x - 4, rect.size.y * 0.38))
	draw_rect(sheen, Color(accent.r, accent.g, accent.b, 0.12 if is_selected else 0.04), true)

	if is_selected:
		var pulse = 0.15 + 0.10 * sin(msec * 0.008)
		draw_rect(rect.grow(3.0), Color(accent.r, accent.g, accent.b, pulse), false, 2)
		draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.95), false, 1.5)
	else:
		draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.36 if primary else 0.26), false, 1.0)

	var bar_w = 6.0 if is_selected else (5.0 if primary else 3.5)
	var bar_rect = Rect2(rect.position + Vector2(2, 3), Vector2(bar_w, rect.size.y - 6))
	draw_rect(bar_rect, accent if (is_selected or primary) else Color(accent.r, accent.g, accent.b, 0.5), true)

	var icon_box_size = rect.size.y - 10.0
	var icon_center = Vector2(rect.position.x + bar_w + 10.0 + icon_box_size * 0.5, rect.get_center().y)
	var icon_r = icon_box_size * 0.34

	draw_circle(icon_center, icon_r, Color(accent.r, accent.g, accent.b, 0.20 if is_selected else 0.10))
	var arc_rot = (msec * 0.002) if is_selected else 0.0
	draw_arc(icon_center, icon_r + 2.5, arc_rot, arc_rot + PI * 1.5, 20, Color(accent.r, accent.g, accent.b, 0.85 if is_selected else 0.50), 1.5)

	match button_type:
		"continue":
			var tri = PackedVector2Array([
				icon_center + Vector2(-icon_r * 0.3, -icon_r * 0.48),
				icon_center + Vector2(icon_r * 0.55, 0.0),
				icon_center + Vector2(-icon_r * 0.3, icon_r * 0.48)
			])
			draw_polygon(tri, PackedColorArray([Color.WHITE]))
			draw_circle(icon_center, icon_r * 0.16, Color(0.0, 1.0, 0.78))

		"start":
			if primary:
				var tri = PackedVector2Array([
					icon_center + Vector2(-icon_r * 0.3, -icon_r * 0.48),
					icon_center + Vector2(icon_r * 0.55, 0.0),
					icon_center + Vector2(-icon_r * 0.3, icon_r * 0.48)
				])
				draw_polygon(tri, PackedColorArray([Color.WHITE]))
			else:
				var dia = PackedVector2Array([
					icon_center + Vector2(0, -icon_r * 0.6),
					icon_center + Vector2(icon_r * 0.6, 0),
					icon_center + Vector2(0, icon_r * 0.6),
					icon_center + Vector2(-icon_r * 0.6, 0),
					icon_center + Vector2(0, -icon_r * 0.6)
				])
				draw_polyline(dia, Color.WHITE, 1.5)
				draw_circle(icon_center, 3.0, accent)

		"catalog":
			var c1 = Rect2(icon_center + Vector2(-icon_r * 0.5, -icon_r * 0.45), Vector2(icon_r * 0.65, icon_r * 0.88))
			var c2 = Rect2(icon_center + Vector2(-icon_r * 0.2, -icon_r * 0.6), Vector2(icon_r * 0.65, icon_r * 0.88))
			draw_rect(c1, Color(accent.r, accent.g, accent.b, 0.4), true)
			draw_rect(c1, Color.WHITE, false, 1.2)
			draw_rect(c2, Color(accent.r, accent.g, accent.b, 0.7), true)
			draw_rect(c2, Color.WHITE, false, 1.2)

		"settings":
			draw_arc(icon_center, icon_r * 0.5, 0, TAU, 18, Color.WHITE, 1.5)
			draw_circle(icon_center, icon_r * 0.2, Color.WHITE)
			for i in range(6):
				var ang = i * (PI / 3.0)
				var p1 = icon_center + Vector2(cos(ang), sin(ang)) * (icon_r * 0.4)
				var p2 = icon_center + Vector2(cos(ang), sin(ang)) * (icon_r * 0.72)
				draw_line(p1, p2, Color.WHITE, 2.0)

		"stream":
			draw_circle(icon_center, icon_r * 0.35, Color.WHITE)
			draw_arc(icon_center, icon_r * 0.7, -PI * 0.4, PI * 0.4, 14, Color.WHITE, 1.5)
			draw_arc(icon_center, icon_r * 0.7, PI * 0.6, PI * 1.4, 14, Color.WHITE, 1.5)

		"exit":
			draw_arc(icon_center, icon_r * 0.58, -PI * 0.75, PI * 0.75, 18, Color.WHITE, 1.8)
			draw_line(icon_center + Vector2(0, -icon_r * 0.7), icon_center + Vector2(0, 0), Color.WHITE, 2.0)

		_:
			draw_circle(icon_center, 3.5, Color.WHITE)

	var text_x = icon_center.x + icon_r + 14.0
	var title_size = int(clamp(rect.size.y * (0.34 if primary else 0.32), 14.0, 18.0))
	var title_y = rect.position.y + rect.size.y * (0.46 if detail == "" else 0.38)
	
	draw_string(font, Vector2(text_x + 1, title_y + 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(0, 0, 0, 0.7))
	draw_string(font, Vector2(text_x, title_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color.WHITE if is_selected else Color(0.94, 0.97, 1.0))

	if detail != "":
		var detail_size = int(clamp(rect.size.y * 0.20, 10.0, 12.0))
		var sub_color = Color(accent.r, accent.g, accent.b, 0.95) if is_selected else Color(0.68, 0.84, 0.92, 0.82)
		draw_string(font, Vector2(text_x, rect.position.y + rect.size.y * 0.72), detail.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, detail_size, sub_color)

	var corner_x = rect.end.x - 10.0
	draw_line(Vector2(corner_x, rect.position.y + 6.0), Vector2(corner_x + 3.0, rect.position.y + 6.0), Color(accent.r, accent.g, accent.b, 0.5), 1.2)
	draw_line(Vector2(corner_x + 3.0, rect.position.y + 6.0), Vector2(corner_x + 3.0, rect.position.y + 9.0), Color(accent.r, accent.g, accent.b, 0.5), 1.2)
"""

    menu_option_keys_code = """func _menu_option_keys() -> Array:
	var keys := []
	if interrupted_run_available:
		keys.append("continue")
	keys.append("start")
	keys.append_array(["catalog", "settings"])
	if QA_STREAMING_FEATURE_ENABLED and qa_streaming_unlocked:
		keys.append("stream")
	keys.append("exit")
	return keys"""

    menu_rects_code = """func _menu_rects(viewport: Vector2) -> Dictionary:
	var portrait = _is_portrait(viewport)
	var rects := {}

	if portrait:
		var w = viewport.x * 0.72
		var margin_x = (viewport.x - w) * 0.5
		var start_y = viewport.y * 0.32
		var btn_h = clamp(viewport.y * 0.065, 44.0, 54.0)
		var gap = 10.0
		var half_w = (w - gap) * 0.5
		var y: float = start_y

		if interrupted_run_available:
			rects["continue"] = Rect2(margin_x, y, w, btn_h)
			y += btn_h + gap
			rects["start"] = Rect2(margin_x, y, w, btn_h)
			y += btn_h + gap
		else:
			rects["start"] = Rect2(margin_x, y, w, btn_h)
			y += btn_h + gap

		rects["catalog"] = Rect2(margin_x, y, half_w, btn_h)
		rects["settings"] = Rect2(margin_x + half_w + gap, y, half_w, btn_h)
		y += btn_h + gap

		if QA_STREAMING_FEATURE_ENABLED and qa_streaming_unlocked:
			rects["stream"] = Rect2(margin_x, y, w, btn_h)
			y += btn_h + gap

		rects["exit"] = Rect2(margin_x, y, w, btn_h * 0.9)
		return rects

	# Landscape layout: centered horizontally, compact sleek buttons (~48% scale reduction)
	var w = clamp(viewport.x * 0.28, 280.0, 360.0)
	var x = (viewport.x - w) * 0.5
	var btn_h = clamp(viewport.y * 0.068, 44.0, 52.0)
	var gap = clamp(viewport.y * 0.016, 10.0, 14.0)
	var y: float = viewport.y * 0.26

	if interrupted_run_available:
		rects["continue"] = Rect2(x, y, w, btn_h)
		y += btn_h + gap
		rects["start"] = Rect2(x, y, w, btn_h)
		y += btn_h + gap
	else:
		rects["start"] = Rect2(x, y, w, btn_h)
		y += btn_h + gap

	var half_w = (w - gap) * 0.5
	rects["catalog"] = Rect2(x, y, half_w, btn_h)
	rects["settings"] = Rect2(x + half_w + gap, y, half_w, btn_h)
	y += btn_h + gap

	if QA_STREAMING_FEATURE_ENABLED and qa_streaming_unlocked:
		rects["stream"] = Rect2(x, y, w, btn_h)
		y += btn_h + gap

	rects["exit"] = Rect2(x, y, w, btn_h * 0.9)
	return rects
"""

    idx_draw_menu_start = None
    idx_draw_menu_end = None
    idx_draw_hub_btn_start = None
    idx_draw_hub_btn_end = None
    idx_menu_keys_start = None
    idx_menu_keys_end = None
    idx_menu_rects_start = None
    idx_menu_rects_end = None

    for i, line in enumerate(lines):
        if line.startswith('func _draw_menu('):
            idx_draw_menu_start = i
        elif line.startswith('func _app_update_panel_rect('):
            idx_draw_menu_end = i
        elif line.startswith('func _draw_hub_button('):
            idx_draw_hub_btn_start = i
        elif line.startswith('func _draw_hub_manifest_card('):
            idx_draw_hub_btn_end = i
        elif line.startswith('func _menu_option_keys('):
            idx_menu_keys_start = i
        elif line.startswith('func _menu_option_count('):
            idx_menu_keys_end = i
        elif line.startswith('func _menu_rects('):
            idx_menu_rects_start = i
        elif line.startswith('func _draw_catalog('):
            idx_menu_rects_end = i

    print("Indices:", idx_draw_menu_start, idx_draw_menu_end, idx_draw_hub_btn_start, idx_draw_hub_btn_end, idx_menu_keys_start, idx_menu_keys_end, idx_menu_rects_start, idx_menu_rects_end)

    lines[idx_menu_rects_start:idx_menu_rects_end] = [menu_rects_code + "\n\n\n"]
    lines[idx_menu_keys_start:idx_menu_keys_end] = [menu_option_keys_code + "\n\n\n"]
    lines[idx_draw_hub_btn_start:idx_draw_hub_btn_end] = [draw_hub_btn_code + "\n\n\n"]
    lines[idx_draw_menu_start:idx_draw_menu_end] = [draw_menu_code + "\n\n\n"]

    with open('scripts/main.gd', 'w', encoding='utf-8', newline='\n') as f:
        f.writelines(lines)

    print("SUCCESSFULLY APPLIED NEW COMPACT MENU TO main.gd!")

if __name__ == '__main__':
    main()
