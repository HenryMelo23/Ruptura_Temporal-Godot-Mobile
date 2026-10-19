extends "res://scripts/main.gd"
## Test-only instrumentation: inherited renderers execute unchanged.
var render_profile_us: Dictionary = {}
var enemy_render_reference: Script
var render_enemies_only := false

func _measure_render(key: String, started: int) -> void:
	render_profile_us[key] = Time.get_ticks_usec() - started

func _draw() -> void:
	render_profile_us.clear()
	var started := Time.get_ticks_usec()
	if render_enemies_only:
		draw_rect(get_viewport_rect(), Color(0.08, 0.09, 0.12))
		_draw_enemies(Vector2.ZERO)
	else:
		super._draw()
	_measure_render("draw_total", started)

func _draw_game(viewport: Vector2) -> void:
	var started := Time.get_ticks_usec()
	super._draw_game(viewport)
	_measure_render("world", started)

func _draw_enemies(camera: Vector2) -> void:
	var started := Time.get_ticks_usec()
	if enemy_render_reference != null:
		SineiroBorealPresentation.draw_world(self, camera)
		AmberSuturerPresentation.draw_world(self, camera)
		enemy_render_reference._draw_enemies(self, camera)
	else:
		super._draw_enemies(camera)
	_measure_render("enemies", started)

func _draw_projectiles(camera: Vector2) -> void:
	var started := Time.get_ticks_usec()
	super._draw_projectiles(camera)
	_measure_render("projectiles", started)

func _draw_hud(viewport: Vector2) -> void:
	var started := Time.get_ticks_usec()
	super._draw_hud(viewport)
	_measure_render("hud", started)

func _enemy_texture(enemy: Dictionary) -> Texture2D:
	var started := Time.get_ticks_usec()
	var result := super._enemy_texture(enemy)
	render_profile_us["enemy_texture"] = int(render_profile_us.get("enemy_texture", 0)) + Time.get_ticks_usec() - started
	return result

func _draw_enemy_health_bar(enemy: Dictionary, pos: Vector2, width: float, ratio: float) -> void:
	var started := Time.get_ticks_usec()
	super._draw_enemy_health_bar(enemy, pos, width, ratio)
	render_profile_us["enemy_bars"] = int(render_profile_us.get("enemy_bars", 0)) + Time.get_ticks_usec() - started

func _draw_dynamic_shadow(texture: Texture2D, center: Vector2, size: Vector2, flip_h = false, alpha = 0.42) -> void:
	var started := Time.get_ticks_usec()
	super._draw_dynamic_shadow(texture, center, size, flip_h, alpha)
	render_profile_us["shadows"] = int(render_profile_us.get("shadows", 0)) + Time.get_ticks_usec() - started
