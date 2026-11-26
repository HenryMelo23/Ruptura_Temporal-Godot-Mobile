class_name RTColorVisionFilter
extends RefCounted

## Modo de cor para daltonismo (Configuracoes > Jogabilidade > MODO DE COR).
## Um unico passe de tela cheia num CanvasLayer acima de tudo: corrige a cena
## inteira (mundo, telegrafia de perigo, HUD e menus) sem tocar em cada cor.
## Desligado, o no nem existe: custo zero no Android.
## Correcao por redistribuicao do erro (Fidaner) sobre a simulacao de Machado
## (severidade 1.0); alto contraste so aumenta saturacao e contraste.

const LAYER_NAME := "ColorVisionFilter"
const RECT_NAME := "Grade"
const LAYER_INDEX := 121 # acima do pos-processo da morte (120)

const MODE_OFF := "off"
const MODES: Array[String] = [MODE_OFF, "protanopia", "deuteranopia", "tritanopia", "alto_contraste"]
const LABELS: Dictionary = {
	MODE_OFF: "DESLIGADO",
	"protanopia": "PROTANOPIA",
	"deuteranopia": "DEUTERANOPIA",
	"tritanopia": "TRITANOPIA",
	"alto_contraste": "ALTO CONTRASTE",
}

const SHADER_CODE := """
shader_type canvas_item;
render_mode unshaded;

uniform int mode = 0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

const mat3 PROTAN = mat3(vec3(0.152286, 0.114503, -0.003882), vec3(1.052583, 0.786281, -0.048116), vec3(-0.204868, 0.099216, 1.051998));
const mat3 DEUTAN = mat3(vec3(0.367322, 0.280085, -0.011820), vec3(0.860646, 0.672501, 0.042940), vec3(-0.227968, 0.047413, 0.968881));
const mat3 TRITAN = mat3(vec3(1.255528, -0.078411, 0.004733), vec3(-0.076749, 0.930809, 0.691367), vec3(-0.178779, 0.147602, 0.303900));

void fragment() {
	vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	vec3 o = c;
	if (mode == 4) {
		float l = dot(c, vec3(0.299, 0.587, 0.114));
		o = mix(vec3(l), c, 1.5);
		o = (o - 0.5) * 1.25 + 0.5;
	} else if (mode == 3) {
		vec3 e = c - TRITAN * c;
		o = c + vec3(e.r + 0.7 * e.b, e.g + 0.7 * e.b, 0.0);
	} else {
		vec3 e = c - DEUTAN * c;
		if (mode == 1) {
			e = c - PROTAN * c;
		}
		o = c + vec3(0.0, 0.7 * e.r + e.g, 0.7 * e.r + e.b);
	}
	COLOR = vec4(clamp(o, vec3(0.0), vec3(1.0)), 1.0);
}
"""


static func sanitize(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	return normalized if MODES.has(normalized) else MODE_OFF


static func label(value: String) -> String:
	return String(LABELS.get(sanitize(value), "DESLIGADO"))


static func next(value: String, direction: int = 1) -> String:
	var index: int = MODES.find(sanitize(value))
	return MODES[(index + direction + MODES.size()) % MODES.size()]


static func shader_mode(value: String) -> int:
	return MODES.find(sanitize(value))


## Aplica `game.color_vision_mode` (normalizado) ao filtro.
static func apply(game: Node) -> void:
	game.color_vision_mode = sanitize(String(game.color_vision_mode))
	sync(game, game.color_vision_mode)


static func cycle(game: Node, direction: int = 1) -> void:
	game.color_vision_mode = next(String(game.color_vision_mode), direction)
	sync(game, game.color_vision_mode)


## Cria, atualiza ou remove o filtro conforme o modo salvo.
static func sync(game: Node, value: String) -> void:
	var layer: CanvasLayer = game.get_node_or_null(LAYER_NAME) as CanvasLayer
	var mode: int = shader_mode(value)
	if mode <= 0:
		if layer != null:
			game.remove_child(layer)
			layer.queue_free()
		return
	if layer == null:
		layer = _build_layer()
		game.add_child(layer)
	var grade: ColorRect = layer.get_node(RECT_NAME) as ColorRect
	(grade.material as ShaderMaterial).set_shader_parameter("mode", mode)


static func _build_layer() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = LAYER_NAME
	layer.layer = LAYER_INDEX
	var grade := ColorRect.new()
	grade.name = RECT_NAME
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.color = Color.WHITE
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	grade.material = material
	layer.add_child(grade)
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return layer
