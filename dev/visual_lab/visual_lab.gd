extends Node2D

const CAPTURE_ARG := "--visual-lab-capture"
const SCANLINE_SHADER := preload("res://dev/visual_lab/shaders/temporal_scanline.gdshader")

var active_demo := 0
var demo_names: Array[String] = ["UI STATES", "TEMPORAL SHOT", "D37 CORRUPTION", "IMPACT"]
var pulse := 0.0
var title_font: Font
var body_font: Font
var timeline_particles: GPUParticles2D
var infection_particles: GPUParticles2D
var impact_particles: GPUParticles2D
var ui_buttons: Array[Button] = []


func _ready() -> void:
	title_font = ThemeDB.fallback_font
	body_font = ThemeDB.fallback_font
	_try_load_fonts()
	_create_scanline_overlay()
	_create_controls()
	_create_particles()
	_configure_animation_player()
	set_process(true)
	if CAPTURE_ARG in OS.get_cmdline_user_args():
		call_deferred("_auto_cycle_for_capture")


func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		_set_demo((active_demo + 1) % demo_names.size())
	elif event.is_action_pressed("ui_left"):
		_set_demo((active_demo - 1 + demo_names.size()) % demo_names.size())
	elif event.is_action_pressed("ui_accept"):
		_play_current_demo()


func _draw() -> void:
	var viewport := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.018, 0.020, 0.030), true)
	_draw_lab_grid(viewport)
	_draw_header(viewport)
	_draw_demo_stage(viewport)
	_draw_notes(viewport)


func _try_load_fonts() -> void:
	var loaded_title: Resource = load("res://Game Base/Ruptura_Temporal-APOLO2.0/Texto/Top_Menu.otf")
	var loaded_body: Resource = load("res://Game Base/Ruptura_Temporal-APOLO2.0/Texto/World.otf")
	if loaded_title is Font:
		title_font = loaded_title
	if loaded_body is Font:
		body_font = loaded_body


func _create_scanline_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TemporalScanlineLayer"
	add_child(layer)
	var rect := ColorRect.new()
	rect.name = "TemporalScanline"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(0.02, 0.04, 0.08, 0.16)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var material := ShaderMaterial.new()
	material.shader = SCANLINE_SHADER
	rect.material = material
	layer.add_child(rect)


func _create_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "VisualLabControls"
	add_child(layer)

	var root := MarginContainer.new()
	root.name = "RootMargin"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_bottom", 24)
	layer.add_child(root)

	var box := VBoxContainer.new()
	box.name = "ButtonStack"
	box.alignment = BoxContainer.ALIGNMENT_END
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(box)

	var row := HBoxContainer.new()
	row.name = "DemoButtons"
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)

	for i in range(demo_names.size()):
		var button := Button.new()
		button.text = demo_names[i]
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(172, 42)
		button.pressed.connect(_set_demo.bind(i))
		row.add_child(button)
		ui_buttons.append(button)

	var play_button := Button.new()
	play_button.text = "PLAY"
	play_button.focus_mode = Control.FOCUS_ALL
	play_button.custom_minimum_size = Vector2(96, 42)
	play_button.pressed.connect(_play_current_demo)
	row.add_child(play_button)
	ui_buttons.append(play_button)
	_refresh_button_states()


func _create_particles() -> void:
	timeline_particles = _make_particles("TemporalShotParticles", Color(0.0, 0.95, 1.0), Color(1.0, 0.12, 0.68), 44, 0.62, 440.0, Vector2(340, 350))
	infection_particles = _make_particles("D37CorruptionParticles", Color(0.46, 1.0, 0.16), Color(0.08, 0.35, 0.05), 54, 0.92, 130.0, Vector2(640, 350))
	impact_particles = _make_particles("ImpactShardsParticles", Color(1.0, 0.55, 0.15), Color(0.0, 0.94, 1.0), 64, 0.42, 520.0, Vector2(900, 350))


func _make_particles(node_name: String, primary: Color, secondary: Color, amount: int, lifetime: float, speed: float, pos: Vector2) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = node_name
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 0.82
	particles.randomness = 0.28
	particles.local_coords = false
	particles.position = pos
	particles.emitting = false

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(1.0, -0.18, 0.0)
	material.spread = 42.0
	material.initial_velocity_min = speed * 0.35
	material.initial_velocity_max = speed
	material.angular_velocity_min = -220.0
	material.angular_velocity_max = 220.0
	material.gravity = Vector3(0.0, 160.0, 0.0)
	material.damping_min = 12.0
	material.damping_max = 32.0
	material.scale_min = 2.0
	material.scale_max = 8.0
	var gradient := Gradient.new()
	gradient.set_color(0, primary)
	gradient.set_color(1, Color(secondary.r, secondary.g, secondary.b, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	material.color_ramp = ramp
	particles.process_material = material

	add_child(particles)
	return particles


func _configure_animation_player() -> void:
	var player := $AnimationPlayer as AnimationPlayer
	var library := AnimationLibrary.new()
	var animation := Animation.new()
	animation.length = 0.55
	animation.loop_mode = Animation.LOOP_NONE
	library.add_animation("lab_pulse", animation)
	player.add_animation_library("", library)


func _set_demo(index: int) -> void:
	active_demo = clampi(index, 0, demo_names.size() - 1)
	_refresh_button_states()
	_play_current_demo()
	queue_redraw()


func _refresh_button_states() -> void:
	for i in range(ui_buttons.size()):
		var button := ui_buttons[i]
		if i < demo_names.size():
			button.modulate = Color(0.80, 1.0, 1.0) if i == active_demo else Color(0.64, 0.72, 0.78)


func _play_current_demo() -> void:
	match active_demo:
		0:
			($AnimationPlayer as AnimationPlayer).play("lab_pulse")
		1:
			timeline_particles.restart()
			timeline_particles.emitting = true
		2:
			infection_particles.restart()
			infection_particles.emitting = true
		3:
			impact_particles.restart()
			impact_particles.emitting = true


func _auto_cycle_for_capture() -> void:
	for i in range(demo_names.size()):
		_set_demo(i)
		await get_tree().create_timer(0.18).timeout


func _draw_lab_grid(viewport: Vector2) -> void:
	var step := 48.0
	var offset := fmod(pulse * 18.0, step)
	for x in range(-48, int(viewport.x + 48), int(step)):
		draw_line(Vector2(float(x) + offset, 0), Vector2(float(x) + offset, viewport.y), Color(0.0, 0.70, 0.88, 0.11), 1.0)
	for y in range(-48, int(viewport.y + 48), int(step)):
		draw_line(Vector2(0, float(y) + offset * 0.5), Vector2(viewport.x, float(y) + offset * 0.5), Color(0.0, 0.70, 0.88, 0.08), 1.0)


func _draw_header(viewport: Vector2) -> void:
	_draw_centered(title_font, "RUPTURA VISUAL LAB", Vector2(viewport.x * 0.5, 78), 44, Color(0.92, 0.98, 1.0))
	draw_line(Vector2(viewport.x * 0.20, 112), Vector2(viewport.x * 0.80, 112), Color(0.0, 1.0, 0.86, 0.58), 2.0)
	_draw_centered(body_font, "UI / VFX / SHADER / PARTICLES - SANDBOX ISOLADO", Vector2(viewport.x * 0.5, 138), 13, Color(0.70, 0.88, 0.96, 0.72))


func _draw_demo_stage(viewport: Vector2) -> void:
	var stage := Rect2(viewport.x * 0.10, viewport.y * 0.25, viewport.x * 0.80, viewport.y * 0.44)
	draw_rect(stage, Color(0.015, 0.018, 0.030, 0.70), true)
	draw_rect(stage, Color(0.0, 1.0, 0.86, 0.34), false, 1.5)
	var label := demo_names[active_demo]
	_draw_centered(body_font, label, stage.position + Vector2(stage.size.x * 0.5, 34), 18, Color(1.0, 0.96, 0.88, 0.95))
	_draw_temporal_arc(stage.get_center() + Vector2(-220, 10), 72, Color(0.0, 0.95, 1.0))
	_draw_d37_growth(stage.get_center(), 82)
	_draw_impact_mark(stage.get_center() + Vector2(230, 12), 74)


func _draw_notes(viewport: Vector2) -> void:
	var text := "Use setas para alternar e Enter/Space para reproduzir. Este laboratorio nao entra no jogo final."
	_draw_centered(body_font, text, Vector2(viewport.x * 0.5, viewport.y - 92), 13, Color(0.68, 0.80, 0.86, 0.72))


func _draw_temporal_arc(center: Vector2, radius: float, color: Color) -> void:
	for i in range(4):
		var r := radius + float(i) * 12.0
		draw_arc(center, r, pulse * (0.7 + i * 0.08), pulse * (0.7 + i * 0.08) + PI * 1.35, 64, Color(color.r, color.g, color.b, 0.36 - i * 0.05), 2.0)
		draw_line(center + Vector2(-r * 0.7, -r * 0.18), center + Vector2(r * 0.55, r * 0.10), Color(1.0, 0.12, 0.68, 0.12), 1.0)


func _draw_d37_growth(center: Vector2, radius: float) -> void:
	for i in range(12):
		var a := float(i) / 12.0 * TAU + sin(pulse + i) * 0.08
		var inner := center + Vector2(cos(a), sin(a)) * radius * 0.38
		var outer := center + Vector2(cos(a), sin(a)) * radius * (0.78 + 0.12 * sin(pulse * 2.0 + i))
		draw_line(inner, outer, Color(0.46, 1.0, 0.16, 0.34), 3.0)
		draw_circle(outer, 3.0, Color(0.16, 0.75, 0.08, 0.65))
	draw_arc(center, radius * 0.62, 0, TAU, 72, Color(0.46, 1.0, 0.16, 0.32), 2.0)


func _draw_impact_mark(center: Vector2, radius: float) -> void:
	for i in range(14):
		var a := float(i) / 14.0 * TAU
		var len := radius * (0.38 + 0.46 * fposmod(float(i) * 0.37, 1.0))
		var start := center + Vector2(cos(a), sin(a)) * radius * 0.16
		var end := center + Vector2(cos(a), sin(a)) * len
		draw_line(start, end, Color(1.0, 0.48, 0.12, 0.48), 2.4)
	draw_arc(center, radius * 0.42, 0, TAU, 48, Color(0.0, 0.95, 1.0, 0.36), 2.0)


func _draw_centered(font_resource: Font, text: String, pos: Vector2, size: int, color: Color) -> void:
	var text_size := font_resource.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var baseline_y := pos.y + font_resource.get_ascent(size) - text_size.y * 0.5
	draw_string(font_resource, Vector2(pos.x - text_size.x * 0.5, baseline_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
