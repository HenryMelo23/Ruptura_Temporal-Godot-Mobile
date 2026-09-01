extends Node2D

const MAIN_SCENE_PATH: = "res://scenes/Main.tscn"
const BOOT_VISUAL_SMOKE_ARG: = "--boot-visual-smoke"

var boot_started_ms: = 0
var load_started_ms: = 0
var progress: = 0.0
var status_text: = "Sincronizando ruptura..."
var title_font: Font
var body_font: Font
var load_requested: = false
var handoff_started: = false
var visual_smoke_only: = false
var handoff_queued: = false
var keep_alive_for_agent_smoke: = false
var spawned_main: Node


func _ready() -> void :
	boot_started_ms = Time.get_ticks_msec()
	title_font = ThemeDB.fallback_font
	body_font = ThemeDB.fallback_font
	visual_smoke_only = BOOT_VISUAL_SMOKE_ARG in OS.get_cmdline_user_args()
	keep_alive_for_agent_smoke = _is_agent_smoke_for_boot()
	print("PERF boot_scene_ready %dms" % (Time.get_ticks_msec() - boot_started_ms))
	set_process(true)
	queue_redraw()
	if not visual_smoke_only:
		call_deferred("_start_main_load_after_first_frame")


func _process(_delta: float) -> void :
	if load_requested and not handoff_started:
		_poll_main_load()
	queue_redraw()


func _start_main_load_after_first_frame() -> void :
	await get_tree().process_frame
	_load_boot_fonts()
	load_started_ms = Time.get_ticks_msec()
	var err: = ResourceLoader.load_threaded_request(MAIN_SCENE_PATH, "PackedScene")
	if err != OK:
		status_text = "Falha ao sincronizar ruptura."
		push_error("Boot failed to request threaded load for %s: %s" % [MAIN_SCENE_PATH, error_string(err)])
		return
	load_requested = true
	print("PERF main_scene_load_started %dms" % (load_started_ms - boot_started_ms))
	call_deferred("_complete_main_load_after_visual_tick")


func _complete_main_load_after_visual_tick() -> void :
	if handoff_queued or handoff_started or not load_requested:
		return
	handoff_queued = true
	await get_tree().process_frame
	await get_tree().process_frame
	if handoff_started or not load_requested:
		return
	progress = maxf(progress, 0.62)
	status_text = "Abrindo ruptura..."
	queue_redraw()
	await get_tree().process_frame
	_handoff_to_main()


func _load_boot_fonts() -> void :
	var loaded_title: Resource = load("res://assets/fonts/Top_Menu.otf")
	var loaded_body: Resource = load("res://assets/fonts/World.otf")
	if loaded_title is Font:
		title_font = loaded_title
	else:
		push_warning("Boot font fallback: Top_Menu.otf was not available.")
	if loaded_body is Font:
		body_font = loaded_body
	else:
		push_warning("Boot font fallback: World.otf was not available.")


func _poll_main_load() -> void :
	var progress_array: Array = []
	var status: = ResourceLoader.load_threaded_get_status(MAIN_SCENE_PATH, progress_array)
	if progress_array.size() > 0:
		progress = clampf(float(progress_array[0]), 0.0, 1.0)
	match status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			load_requested = false
			status_text = "Falha ao sincronizar ruptura."
			push_error("Boot threaded load invalid resource: " + MAIN_SCENE_PATH)
		ResourceLoader.THREAD_LOAD_FAILED:
			load_requested = false
			status_text = "Falha ao sincronizar ruptura."
			push_error("Boot threaded load failed: " + MAIN_SCENE_PATH)
		ResourceLoader.THREAD_LOAD_LOADED:
			progress = 1.0
			_handoff_to_main()


func _handoff_to_main() -> void :
	if handoff_started:
		return
	handoff_started = true
	var loaded: = ResourceLoader.load_threaded_get(MAIN_SCENE_PATH)
	var main_scene: = loaded as PackedScene
	if main_scene == null:
		status_text = "Falha ao sincronizar ruptura."
		push_error("Boot loaded resource is not a PackedScene: " + MAIN_SCENE_PATH)
		return
	print("PERF main_scene_loaded %dms" % (Time.get_ticks_msec() - boot_started_ms))
	status_text = "Abrindo ruptura..."
	queue_redraw()
	var main: = main_scene.instantiate()
	spawned_main = main
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	print("PERF main_scene_instantiated %dms" % (Time.get_ticks_msec() - boot_started_ms))
	await get_tree().process_frame
	print("PERF first_menu_frame %dms" % (Time.get_ticks_msec() - boot_started_ms))
	if keep_alive_for_agent_smoke:
		visible = false
		set_process(false)
	else:
		queue_free()


func _cleanup_runtime_resources() -> void :
	if spawned_main != null and is_instance_valid(spawned_main):
		if get_tree().current_scene == spawned_main:
			get_tree().current_scene = null
		if spawned_main.has_method("_cleanup_runtime_resources"):
			spawned_main.call("_cleanup_runtime_resources")
		if "textures" in spawned_main:
			spawned_main.textures.clear()
		if "audio_streams" in spawned_main:
			spawned_main.audio_streams.clear()
		if spawned_main.get_parent() != null:
			spawned_main.get_parent().remove_child(spawned_main)
		spawned_main.free()
	spawned_main = null


func _is_agent_smoke_for_boot() -> bool:
	for argument in OS.get_cmdline_args():
		if argument.find("agent_smoke_test.gd") != -1:
			return true
	for argument in OS.get_cmdline_user_args():
		if argument == "--scene=res://scenes/Boot.tscn":
			return true
		if argument.begins_with("--frames="):
			return true
	return false


func _draw() -> void :
	var viewport: = get_viewport_rect().size
	var t: = float(Time.get_ticks_msec() - boot_started_ms) * 0.001
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.006, 0.01, 0.026), true)
	_draw_grid(viewport, t)
	_draw_temporal_core(viewport, t)
	_draw_boot_title(viewport, t)
	_draw_status(viewport, t)
	_draw_version(viewport)


func _draw_grid(viewport: Vector2, t: float) -> void :
	var grid_color: = Color(0.0, 0.82, 0.95, 0.12)
	var step: = 52.0
	var offset: = fmod(t * 18.0, step)
	for x in range( - int(step), int(viewport.x + step), int(step)):
		draw_line(Vector2(float(x) + offset, 0.0), Vector2(float(x) + offset, viewport.y), grid_color, 1.0)
	for y in range( - int(step), int(viewport.y + step), int(step)):
		draw_line(Vector2(0.0, float(y) + offset * 0.55), Vector2(viewport.x, float(y) + offset * 0.55), grid_color, 1.0)
	for i in range(7):
		var p: = fposmod(t * (0.045 + float(i) * 0.009) + float(i) * 0.131, 1.0)
		var y: = viewport.y * (0.18 + float(i % 4) * 0.17)
		var x: = lerpf(-90.0, viewport.x + 90.0, p)
		draw_line(Vector2(x - 44.0, y), Vector2(x + 78.0, y + 10.0), Color(0.0, 1.0, 0.86, 0.16), 2.0, true)


func _draw_temporal_core(viewport: Vector2, t: float) -> void :
	var title_size: = _boot_title_size(viewport)
	var title_y: = _boot_title_y(viewport)
	var status_y: = _boot_status_y(viewport)
	var top_limit: = title_y + title_size * 0.74
	var bottom_limit: = status_y - 32.0
	var center_y: = clampf(viewport.y * 0.5 + viewport.y * 0.035, top_limit + 24.0, bottom_limit - 24.0)
	var center: = Vector2(viewport.x * 0.5, center_y)
	var radius: = minf(minf(viewport.x, viewport.y) * 0.18, maxf(34.0, (bottom_limit - top_limit) * 0.42))
	var pulse: = 0.5 + 0.5 * sin(t * 3.2)
	draw_circle(center, radius * (0.82 + pulse * 0.06), Color(0.0, 0.8, 1.0, 0.055))
	draw_circle(center, radius * (0.55 + pulse * 0.04), Color(1.0, 0.0, 0.58, 0.052))
	for i in range(3):
		var r: = radius * (0.58 + float(i) * 0.19 + pulse * 0.025)
		draw_arc(center, r, t * (0.7 + i * 0.18), t * (0.7 + i * 0.18) + PI * 1.55, 64, Color(0.0, 1.0, 0.88, 0.42 - i * 0.08), 2.0)
		draw_arc(center, r * 0.92, - t * (0.8 + i * 0.12), - t * (0.8 + i * 0.12) + PI * 1.2, 64, Color(1.0, 0.08, 0.66, 0.3 - i * 0.06), 1.4)


func _draw_boot_title(viewport: Vector2, t: float) -> void :
	var text: = "RUPTURA TEMPORAL 2.0"
	var size: = _boot_title_size(viewport)
	var pos: = Vector2(viewport.x * 0.5, _boot_title_y(viewport))
	var jitter: = sin(t * 26.0) * 1.8
	_draw_centered_with_font(title_font, text, pos + Vector2(4.0, 5.0), size, Color(0.02, 0.0, 0.05, 0.96))
	_draw_centered_with_font(title_font, text, pos + Vector2(-2.0 + jitter, 0.0), size, Color(1.0, 0.08, 0.7, 0.42))
	_draw_centered_with_font(title_font, text, pos + Vector2(2.0 - jitter, -1.0), size, Color(0.0, 0.94, 1.0, 0.48))
	_draw_centered_with_font(title_font, text, pos + Vector2(1.0, 1.0), size, Color(0.14, 0.02, 0.26, 0.92))
	_draw_centered_with_font(title_font, text, pos, size, Color(0.86, 0.96, 1.0, 0.96))
	var line_w: = minf(viewport.x * 0.44, title_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.48)
	draw_line(pos + Vector2( - line_w, size * 0.46), pos + Vector2(line_w, size * 0.46), Color(0.0, 1.0, 0.84, 0.72), 2.0)


func _draw_status(viewport: Vector2, t: float) -> void :
	var panel_w: = clampf(viewport.x * 0.42, 340.0, 540.0)
	var panel_h: = 58.0
	var rect: = Rect2(Vector2(viewport.x * 0.5 - panel_w * 0.5, _boot_status_y(viewport)), Vector2(panel_w, panel_h))
	var pulse: = 0.5 + 0.5 * sin(t * 4.0)
	draw_rect(rect, Color(0.01, 0.016, 0.034, 0.76), true)
	draw_rect(rect, Color(0.0, 1.0, 0.86, 0.34 + pulse * 0.22), false, 1.5)
	var bar_rect: = Rect2(rect.position + Vector2(18.0, rect.size.y - 17.0), Vector2(rect.size.x - 36.0, 5.0))
	draw_rect(bar_rect, Color(0.12, 0.16, 0.25, 0.92), true)
	var visible_progress: = progress
	if not load_requested:
		visible_progress = fmod(t * 0.22, 1.0) * 0.38
	if load_requested and progress <= 0.0:
		visible_progress = 0.32 + pulse * 0.1
	var filled: = Rect2(bar_rect.position, Vector2(bar_rect.size.x * clampf(visible_progress, 0.0, 1.0), bar_rect.size.y))
	draw_rect(filled, Color(0.0, 1.0, 0.86, 0.88), true)
	draw_rect(Rect2(filled.position + Vector2(maxf(0.0, filled.size.x - 36.0), 0.0), Vector2(minf(36.0, filled.size.x), filled.size.y)), Color(1.0, 0.04, 0.72, 0.62), true)
	_draw_centered_with_font(body_font, status_text, rect.position + Vector2(rect.size.x * 0.5, 23.0), 15, Color(0.82, 1.0, 0.96, 0.94))


func _boot_title_size(viewport: Vector2) -> int:
	return int(clampf(minf(viewport.y * 0.096, viewport.x * 0.078), 38.0, 78.0))


func _boot_title_y(viewport: Vector2) -> float:
	return clampf(viewport.y * 0.19, 58.0, 150.0)


func _boot_status_y(viewport: Vector2) -> float:
	return clampf(viewport.y * 0.72, viewport.y - 150.0, viewport.y - 88.0)


func _draw_version(viewport: Vector2) -> void :
	var version: = String(ProjectSettings.get_setting("application/config/version", "2.0.31c"))
	draw_string(body_font, Vector2(18.0, viewport.y - 14.0), "v" + version, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.88, 0.95, 0.62))


func _draw_centered_with_font(font_resource: Font, text: String, pos: Vector2, size: int, color: Color) -> void :
	var text_size: = font_resource.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var baseline_y: = pos.y + font_resource.get_ascent(size) - text_size.y * 0.5
	draw_string(font_resource, Vector2(pos.x - text_size.x * 0.5, baseline_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
