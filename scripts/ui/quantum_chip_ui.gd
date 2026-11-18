class_name RTQuantumChipUI
extends RefCounted

## Popup de selecao dos chips quanticos (aberto pela tela de Manifestacao/Espectro).
## Ícones: assets/sprites/quantum_chips/<id>.png quando existirem; ate la, o chip
## e desenhado de forma procedural.

const ICON_ROOT := "res://assets/sprites/quantum_chips/"

static var open := false
static var _icons: Dictionary = {}


static func icon(id: String) -> Texture2D:
	if _icons.has(id):
		return _icons[id]
	var path: String = ICON_ROOT + id + ".png"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_icons[id] = tex
	return tex


static func entries() -> Array:
	var out: Array = RTQuantumChipController.CHIPS.duplicate()
	out.append({
		"id": RTQuantumChipController.RANDOM, "name": "Chip Aleatorio", "short": "ALEATORIO",
		"buff": "No inicio da run, sorteia mais um chip entre os que nao estao ligados.",
		"debuff": "Voce so descobre qual foi quando a run comecar.",
		"color": Color(0.4, 0.95, 1.0), "glyph": "?",
	})
	return out


static func draw(game: Node2D, viewport: Vector2) -> void:
	if not open:
		return
	var chips: RTQuantumChipController = game._quantum_chips()
	var t: float = float(Time.get_ticks_msec()) * 0.001
	game.draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.0, 0.02, 0.78), true)
	var portrait: bool = viewport.y > viewport.x
	var panel_size := Vector2(minf(viewport.x * 0.94, 1180.0), minf(viewport.y * 0.9, 640.0))
	var panel := Rect2(viewport * 0.5 - panel_size * 0.5, panel_size)
	game.buttons["qchip_panel"] = panel
	game._draw_holo_panel(panel, Color(0.6, 0.45, 1.0), true, 0.92)
	game._draw_centered("CHIPS QUANTICOS", panel.position + Vector2(panel.size.x * 0.5, 34.0), 24, Color(0.86, 0.78, 1.0))
	var subtitle := "O host escolhe os chips para toda a equipe." if game.mode == "lobby_online_host" else "Mudam as regras da run. Ligue quantos quiser."
	game._draw_centered(subtitle, panel.position + Vector2(panel.size.x * 0.5, 58.0), 13, Color(0.7, 0.74, 0.86))
	var list: Array = entries()
	var cols: int = 2 if portrait else 3
	var rows: int = int(ceil(float(list.size()) / float(cols)))
	var grid := Rect2(panel.position + Vector2(18, 74), panel.size - Vector2(36, 74 + 64))
	var gap := 10.0
	var cw: float = (grid.size.x - gap * float(cols - 1)) / float(cols)
	var ch: float = (grid.size.y - gap * float(rows - 1)) / float(rows)
	for i in range(list.size()):
		var chip: Dictionary = list[i]
		var id: String = String(chip["id"])
		var rect := Rect2(grid.position + Vector2(float(i % cols) * (cw + gap), float(i / cols) * (ch + gap)), Vector2(cw, ch))
		var on: bool = chips.is_selected(id)
		var col: Color = chip.get("color", Color.WHITE)
		game.draw_rect(rect, Color(col.r, col.g, col.b, 0.16 if on else 0.05), true)
		game.draw_rect(rect, Color(col.r, col.g, col.b, 0.95 if on else 0.4), false, 3.0 if on else 1.5)
		var icon_size: float = minf(ch - 20.0, minf(cw * 0.3, 120.0))
		var icon_rect := Rect2(rect.position + Vector2(10, (ch - icon_size) * 0.5), Vector2(icon_size, icon_size))
		draw_chip_icon(game, icon_rect, id, col, on, t)
		var tx: float = icon_rect.end.x + 12.0
		var tw: float = rect.end.x - tx - 10.0
		game.draw_string(game.font, Vector2(tx, rect.position.y + 24), String(chip["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, tw, 15, col)
		game._draw_wrapped("+ " + String(chip["buff"]), Rect2(Vector2(tx, rect.position.y + 32), Vector2(tw, ch * 0.42)), 12, Color(0.72, 1.0, 0.7))
		game._draw_wrapped("- " + String(chip["debuff"]), Rect2(Vector2(tx, rect.position.y + 32 + ch * 0.42), Vector2(tw, ch * 0.45)), 12, Color(1.0, 0.62, 0.6))
		game.draw_string(game.font, Vector2(rect.end.x - 64, rect.position.y + 22), "LIGADO" if on else "DESLIGADO", HORIZONTAL_ALIGNMENT_RIGHT, 56, 11, col if on else Color(0.6, 0.62, 0.7))
		game.buttons["qchip_" + id] = rect
	var by: float = panel.end.y - 52.0
	var clear_r := Rect2(Vector2(panel.position.x + 18, by), Vector2(170, 40))
	var done_r := Rect2(Vector2(panel.end.x - 218, by), Vector2(200, 40))
	game._draw_big_button(clear_r, "DESLIGAR TODOS", Color(0.2, 0.04, 0.08, 0.7), Color(1.0, 0.36, 0.5), false)
	game._draw_big_button(done_r, "PRONTO (%d)" % chips.selected_count(), Color(0.12, 0.06, 0.26, 0.8), Color(0.78, 0.6, 1.0), true)
	game.buttons["qchip_clear"] = clear_r
	game.buttons["qchip_done"] = done_r


## Ícone do chip: arte do Codex se existir; senao placa de circuito procedural.
static func draw_chip_icon(game: Node2D, rect: Rect2, id: String, col: Color, on: bool, t: float) -> void:
	var tex: Texture2D = icon(id)
	if tex != null:
		game._draw_texture_contain(tex, rect, Color(1, 1, 1, 1.0 if on else 0.5))
		return
	var c: Vector2 = rect.get_center()
	var r: float = rect.size.x * 0.36
	var glow: float = (0.5 + 0.5 * sin(t * 3.0)) if on else 0.0
	for k in range(6):
		var a: float = float(k) * TAU / 6.0
		for side in [-1.0, 1.0]:
			var pin: Vector2 = c + Vector2.from_angle(a + side * 0.18) * r
			game.draw_line(pin, pin + Vector2.from_angle(a + side * 0.18) * 9.0, Color(0.8, 0.74, 0.5, 0.9), 2.0)
	var hex := PackedVector2Array()
	for k in range(7):
		hex.append(c + Vector2.from_angle(float(k) * TAU / 6.0 + PI / 6.0) * r)
	game.draw_colored_polygon(hex, Color(0.06, 0.05, 0.1))
	game.draw_polyline(hex, Color(col.r, col.g, col.b, 0.6 + 0.4 * glow), 2.5, true)
	game.draw_circle(c, r * 0.55, Color(col.r, col.g, col.b, 0.18 + 0.2 * glow))
	game._draw_centered(String(RTQuantumChipController.chip_def(id).get("glyph", "?")) if id != RTQuantumChipController.RANDOM else "?", c + Vector2(0, 7), int(r * 0.62), col)


static func handle_tap(game: Node2D, pos: Vector2) -> bool:
	if not open:
		return false
	var chips: RTQuantumChipController = game._quantum_chips()
	var b: Dictionary = game.buttons
	if b.has("qchip_done") and Rect2(b["qchip_done"]).has_point(pos):
		open = false
		return true
	if b.has("qchip_clear") and Rect2(b["qchip_clear"]).has_point(pos):
		chips.clear_selection()
		return true
	for entry in entries():
		var key: String = "qchip_" + String(entry["id"])
		if b.has(key) and Rect2(b[key]).has_point(pos):
			chips.toggle(String(entry["id"]))
			game._play_sfx("ui_manifest_switch", 0.01, 0.34, 1.1)
			return true
	if b.has("qchip_panel") and not Rect2(b["qchip_panel"]).has_point(pos):
		open = false
	return true


static func handle_key(game: Node2D, keycode: int) -> bool:
	if not open:
		return false
	if keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_C]:
		open = false
		return true
	var list: Array = entries()
	if keycode >= KEY_1 and keycode < KEY_1 + list.size():
		game._quantum_chips().toggle(String(list[keycode - KEY_1]["id"]))
	return true


## Sorteia uma opcao desbloqueada da etapa atual (Manifestacao ou Espectro).
static func pick_random_build(game: Node2D) -> void:
	var aura_view: bool = game.manifest_select_stage == game.MANIFEST_STAGE_AURA
	var current: int = game.selected_aura if aura_view else game.selected_manifestation
	var options: Array = []
	for value in game._manifest_selection_visible_indices(aura_view):
		var idx: int = int(value)
		if idx != current and game._manifest_select_item_unlocked(idx, aura_view):
			options.append(idx)
	if options.is_empty():
		return
	var pick: int = int(options[game.rng.randi_range(0, options.size() - 1)])
	if aura_view:
		game._set_selected_aura(pick, true)
		game.aura_scroll_pos = float(game._manifest_selection_slot_for_index(pick, true))
	else:
		game._set_selected_manifestation(pick, true)
		game.manifest_scroll_pos = float(game._manifest_selection_slot_for_index(pick, false))
	game._play_sfx("ui_manifest_switch", 0.01, 0.42, 1.25)
