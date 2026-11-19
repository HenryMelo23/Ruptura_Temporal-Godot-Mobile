extends SceneTree

## Proporcao dos quadros da Matriarca: todo quadro de corpo usado em jogo precisa ter os pes
## na mesma linha e a mesma escala de corpo. Arte nova = celula 448x448 (pes y=420);
## arte antiga de ataque so entra normalizada por LEGACY_FEET. Quadro fora disso falha.

const Pres = preload("res://scripts/presentation/boss6_animation_presentation.gd")
const BODY_KEYS := ["boss6_rework_idle", "boss6_rework_crawl", "boss6_rework_submerge", "boss6_rework_emerge", "boss6_rework_scythe", "boss6_rework_spit", "boss6_rework_tail", "boss6_rework_stage1_attack", "boss6_rework_stage2_attack", "boss6_rework_stage3_attack"]
const MAX_SIZE := Vector2(286.0, 257.0)

var game: Node
var failed := false


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition or failed:
		return
	failed = true
	push_error("BOSS6_PROPORTION_FAIL " + message)
	quit(1)


func _run() -> void:
	game._start_game()
	game.set_process(false)
	game._advance_to_phase(6)
	var ground: float = MAX_SIZE.y * 0.5
	var checked := 0
	var legacy_scale := -1.0
	for key in BODY_KEYS:
		if not game.textures.has(key):
			game._ensure_runtime_texture(key)
		for value in Array(game.textures.get(key, [])):
			var texture: Texture2D = value
			if texture == null:
				continue
			var name: String = texture.resource_path.get_file()
			var size: Vector2 = texture.get_size()
			var rect: Rect2 = Pres.body_rect(texture, MAX_SIZE)
			var is_cell: bool = size.is_equal_approx(Vector2(Pres.BODY_CELL, Pres.BODY_CELL))
			_check(is_cell or Pres.LEGACY_FEET.has(name), "%s is %dx%d and has no legacy anchor (would render at the wrong size)" % [name, int(size.x), int(size.y)])
			var scale: float = rect.size.x / size.x
			var feet_y: float = Pres.BODY_FEET_Y if is_cell else float(Pres.LEGACY_FEET.get(name, Vector2.ZERO).y)
			_check(absf(rect.position.y + feet_y * scale - ground) < 0.5, "%s feet are not on the ground line" % name)
			if is_cell:
				_check(is_equal_approx(scale, Pres.BODY_SCALE), "%s does not use the shared body scale" % name)
			else:
				if legacy_scale < 0.0:
					legacy_scale = scale
				_check(is_equal_approx(scale, legacy_scale), "%s legacy scale differs from its siblings" % name)
			if is_cell:
				_check_cell_art(texture, name)
			checked += 1
	_check(checked >= 20, "too few body frames were checked (%d)" % checked)
	if failed:
		return
	print("BOSS6_PROPORTION_OK frames=%d feet_line=true shared_scale=true legacy_normalized=true" % checked)
	quit(0)



## Pixels da arte: pes (mediana x das ultimas 40 linhas) perto do centro dos pes do idle depois do
## deslocamento, e quadros de locomocao sem afundar a cabeca demais em relacao ao idle.
func _check_cell_art(texture: Texture2D, name: String) -> void:
	var image: Image = texture.get_image()
	if image == null:
		return
	if image.is_compressed():
		image.decompress()
	var bottom := -1
	var top := -1
	for y in range(image.get_height()):
		var count := 0
		for x in range(0, image.get_width(), 2):
			if image.get_pixel(x, y).a > 0.5:
				count += 1
		if count > 3:
			if top < 0:
				top = y
			bottom = y
	var xs: Array = []
	for y in range(maxi(0, bottom - 40), bottom + 1):
		for x in range(0, image.get_width(), 2):
			if image.get_pixel(x, y).a > 0.5:
				xs.append(x)
	xs.sort()
	var feet_x: float = float(xs[xs.size() / 2]) + float(Pres.FRAME_SHIFT_X.get(name, 0.0))
	_check(absf(feet_x - 254.0) <= 40.0, "%s body is off-center in its cell (feet x=%.0f, idle 254)" % [name, feet_x])
	if name.begins_with("boss6_idle") or (name.begins_with("boss6_crawl") and Pres.CRAWL_ORDER.has(int(name.get_basename().right(2)))):
		_check(top <= 145 + 45, "%s sinks the body too much (top=%d, idle 145)" % [name, top])
