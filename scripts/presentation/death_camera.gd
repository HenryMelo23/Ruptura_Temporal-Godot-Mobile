class_name RTDeathCamera
extends RefCounted

## Camera e pos-processamento da morte local. A logica da derrota continua no
## runtime; esta classe cuida apenas do foco cinematografico e da dessaturacao.

const POST_PROCESS_LAYER := "DeathCameraPostProcess"
const POST_PROCESS_RECT := "Grade"
const ZOOM_END := 1.52

const GRAYSCALE_SHADER := """
shader_type canvas_item;
render_mode unshaded;

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec4 source = textureLod(screen_texture, SCREEN_UV, 0.0);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 monochrome = vec3(luminance);
	vec3 graded = mix(source.rgb, monochrome, amount);
	graded = mix(graded, (graded - 0.5) * 1.08 + 0.5, amount * 0.32);
	float edge = smoothstep(0.22, 0.72, distance(SCREEN_UV, vec2(0.5)));
	graded *= 1.0 - edge * vignette;
	COLOR = vec4(max(graded, vec3(0.0)), source.a);
}
"""


static func _ease(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func active(game: Node2D) -> bool:
	return game.mode == "death_slow" and game.death_screen_delay_timer > 0.0


static func progress(game: Node2D) -> float:
	return clampf(1.0 - game.death_screen_delay_timer / maxf(0.01, game.DEATH_SCREEN_SLOW_TIME), 0.0, 1.0)


static func zoom_at(value: float) -> float:
	var p := _ease(clampf((value - 0.04) / 0.96, 0.0, 1.0))
	return lerpf(1.0, ZOOM_END, p)


static func _post_process_rect(game: Node2D) -> ColorRect:
	var layer := game.get_node_or_null(POST_PROCESS_LAYER) as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = POST_PROCESS_LAYER
		layer.layer = 120
		game.add_child(layer)
	var grade := layer.get_node_or_null(POST_PROCESS_RECT) as ColorRect
	if grade != null:
		return grade
	grade = ColorRect.new()
	grade.name = POST_PROCESS_RECT
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.color = Color.WHITE
	layer.add_child(grade)
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = GRAYSCALE_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	grade.material = material
	grade.hide()
	return grade


static func apply(game: Node2D, viewport: Vector2, camera: Vector2) -> void:
	if not active(game):
		return
	var vp := game.get_viewport()
	if vp == null:
		return
	var p := progress(game)
	var zoom := zoom_at(p)
	var focus_world := Vector2(game.death_screen_focus_pos)
	if focus_world == Vector2.ZERO:
		focus_world = Vector2(game.player_pos)
	var focus := focus_world - camera + Vector2(0.0, -24.0)
	var anchor := focus.lerp(viewport * 0.5, _ease(p))
	vp.canvas_transform = Transform2D(0.0, Vector2(zoom, zoom), 0.0, anchor - focus * zoom)

	var grade := _post_process_rect(game)
	grade.show()
	var material := grade.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("amount", _ease(p))
		material.set_shader_parameter("vignette", _ease(clampf((p - 0.18) / 0.82, 0.0, 1.0)) * 0.58)


static func begin(game: Node2D) -> void:
	var grade := _post_process_rect(game)
	grade.show()
	var material := grade.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("amount", 0.0)
		material.set_shader_parameter("vignette", 0.0)


static func draw_subject(game: Node2D, viewport: Vector2) -> void:
	if not active(game):
		return
	var texture: Texture2D = game._player_texture()
	var vp := game.get_viewport()
	if texture == null or vp == null:
		return
	var camera: Vector2 = game._camera(viewport) + game._screen_shake_offset()
	var screen_pos: Vector2 = vp.canvas_transform * (Vector2(game.death_screen_focus_pos) - camera)
	var zoom: float = vp.canvas_transform.get_scale().x
	var profile: Dictionary = game._player_draw_profile()
	var offset: Vector2 = Vector2(profile.get("offset", Vector2.ZERO)) * zoom
	var flip_h: bool = game._should_flip_player_sprite()
	if bool(profile.get("preserve_height", false)):
		game._draw_entity_by_height_rotated(texture, screen_pos + offset, float(profile.get("height", game.PLAYER_DRAW_LACERAR_HEIGHT)) * zoom, 0.0, Color.WHITE, flip_h)
	elif bool(profile.get("fit_aspect", false)):
		game._draw_entity_fit_flipped(texture, screen_pos + offset, Vector2(profile.get("size", game.PLAYER_DRAW_BOX_SIZE)) * zoom, flip_h, Color.WHITE, true)
	else:
		game._draw_entity_stretched_rotated(texture, screen_pos + offset, Vector2(profile.get("size", game.PLAYER_DRAW_BOX_SIZE)) * zoom, 0.0, Color.WHITE, flip_h)


static func clear(game: Node2D) -> void:
	var layer := game.get_node_or_null(POST_PROCESS_LAYER) as CanvasLayer
	if layer != null:
		var grade := layer.get_node_or_null(POST_PROCESS_RECT) as ColorRect
		if grade != null:
			grade.hide()
	var vp := game.get_viewport()
	if vp != null and vp.canvas_transform != Transform2D.IDENTITY:
		vp.canvas_transform = Transform2D.IDENTITY
