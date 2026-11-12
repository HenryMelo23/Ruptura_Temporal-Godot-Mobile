class_name RTWorldLighting
extends RefCounted

## Iluminacao do mundo, barata para celular:
##  - LightLayer: no filho com blend ADITIVO desenhado acima do chao e abaixo
##    das entidades. Pocas de luz reais (acumulam brilho) sob jogador,
##    projeteis, orbes, boss e efeitos marcados com "light".
##  - draw_screen(): vinheta + banho de cor da fase por cima do mundo, antes
##    do HUD (desenhado pelo proprio canvas do jogo, sem no extra).
## Tudo usa uma unica textura radial gerada uma vez; nada por pixel no frame.

const MAX_LIGHTS := 30
const BUDGET_LIGHTS := 12
const MAX_BULLET_LIGHTS := 18

## Banho de cor por fase (surface do mapa): cor e intensidade bem sutis.
const PHASE_GRADE: Dictionary = {
	1: Color(0.30, 0.16, 0.42, 0.070),
	2: Color(0.16, 0.38, 0.62, 0.085),
	3: Color(0.20, 0.42, 0.10, 0.080),
	4: Color(0.38, 0.14, 0.52, 0.075),
	5: Color(0.05, 0.42, 0.30, 0.080),
	6: Color(0.46, 0.34, 0.08, 0.070),
	7: Color(0.60, 0.18, 0.05, 0.085),
	9: Color(0.10, 0.36, 0.24, 0.070),
}
## Luz dos projeteis inimigos que emitem brilho proprio.
const ENEMY_BULLET_LIGHT: Dictionary = {
	"umbra_plasma": Color(0.30, 1.0, 0.45),
	"phase7_fireball": Color(1.0, 0.52, 0.12),
	"boss7_dive_fireball": Color(1.0, 0.46, 0.10),
	"pyro_wall_seed": Color(1.0, 0.30, 0.06),
	"rat_spit": Color(0.55, 0.95, 0.25),
}

static var _light_tex: Texture2D = null
static var _vignette_tex: Texture2D = null
static var _palette_cache: Dictionary = {}


## Gradiente radial suave (branco -> transparente), base de luzes e sombras.
static func light_texture() -> Texture2D:
	if _light_tex == null:
		var size := 96
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center := Vector2(size, size) * 0.5
		for y in range(size):
			for x in range(size):
				var d: float = (Vector2(x + 0.5, y + 0.5) - center).length() / (size * 0.5)
				var falloff: float = clampf(1.0 - d, 0.0, 1.0)
				falloff = falloff * falloff * (1.4 - 0.4 * falloff)  # nucleo quente, borda longa
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(falloff, 0.0, 1.0)))
		_light_tex = ImageTexture.create_from_image(image)
	return _light_tex


## Vinheta: centro transparente, cantos escuros. Um unico quad por frame.
static func vignette_texture() -> Texture2D:
	if _vignette_tex == null:
		var w := 160
		var h := 96
		var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in range(h):
			for x in range(w):
				var n := Vector2((float(x) + 0.5) / w * 2.0 - 1.0, (float(y) + 0.5) / h * 2.0 - 1.0)
				var d: float = n.length()
				var a: float = smoothstep(0.62, 1.42, d)
				image.set_pixel(x, y, Color(0.01, 0.01, 0.03, a * 0.42))
		_vignette_tex = ImageTexture.create_from_image(image)
	return _vignette_tex


## Camada aditiva: filho com show_behind_parent, criado depois do mapa para
## ficar acima do chao e abaixo de tudo que o jogo desenha.
class LightLayer extends Node2D:
	var entries: Array[Rect2] = []
	var colors: Array[Color] = []
	var count := 0

	func _init() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
		show_behind_parent = true

	func begin() -> void:
		count = 0

	func push(rect: Rect2, color: Color) -> void:
		if count < entries.size():
			entries[count] = rect
			colors[count] = color
		else:
			entries.append(rect)
			colors.append(color)
		count += 1

	func _draw() -> void:
		var tex := RTWorldLighting.light_texture()
		for i in range(count):
			draw_texture_rect(tex, entries[i], false, colors[i])


static func _layer(game: Node2D) -> LightLayer:
	var layer: LightLayer = game.get("world_light_layer")
	if layer == null or not is_instance_valid(layer):
		layer = LightLayer.new()
		layer.name = "WorldLightLayer"
		game.add_child(layer)
		game.set("world_light_layer", layer)
	return layer


static func _kind_glow(game: Node2D, kind: String) -> Color:
	if not _palette_cache.has(kind):
		_palette_cache[kind] = Color(game._projectile_palette(kind).get("glow", Color(0.72, 0.92, 1.0)))
	return _palette_cache[kind]


## Junta as luzes do frame e apresenta a camada aditiva.
static func collect_and_present(game: Node2D, camera: Vector2, viewport: Vector2) -> void:
	# A camada precisa nascer DEPOIS do mapa para render acima do chao.
	if game.phase_map_layer == null or not is_instance_valid(game.phase_map_layer):
		return
	var layer := _layer(game)
	layer.begin()
	layer.position = Vector2.ZERO
	var budget: bool = game._runtime_visual_budget_active() or game.gfx_low_resource
	var cap: int = BUDGET_LIGHTS if budget else MAX_LIGHTS
	if bool(game.gfx_particles) and game.mode != "menu":
		var view := Rect2(camera - Vector2(140, 140), viewport + Vector2(280, 280))
		# Jogador: luz da manifestacao.
		if not bool(game.is_dead):
			var player_glow := _kind_glow(game, String(game.manifestation_key))
			_push(layer, game.player_pos - camera, 165.0, Color(player_glow, 0.17))
		# UMBRA: presenca luminosa propria.
		if game.current_phase == 5 and bool(game.boss_active) and not bool(game.boss_dead):
			_push(layer, Vector2(game.boss_pos) - camera, 190.0, Color(0.22, 1.0, 0.5, 0.15))
		# Projeteis do jogador.
		var bullet_lights := 0
		var bullet_cap: int = mini(MAX_BULLET_LIGHTS, cap - layer.count)
		var local_count: int = game.bullets.size()
		var total: int = local_count + game.remote_bullets.size()
		for index in range(total):
			if bullet_lights >= bullet_cap:
				break
			var bullet: Dictionary = game.bullets[index] if index < local_count else game.remote_bullets[index - local_count]
			var pos := Vector2(bullet.get("pos", Vector2.ZERO))
			if not view.has_point(pos):
				continue
			_push(layer, pos - camera, 52.0, Color(_kind_glow(game, String(bullet.get("kind", ""))), 0.33))
			bullet_lights += 1
		# Projeteis inimigos que brilham.
		for bullet_value in game.enemy_bullets:
			if layer.count >= cap:
				break
			var enemy_bullet: Dictionary = bullet_value
			var light_color_value = ENEMY_BULLET_LIGHT.get(String(enemy_bullet.get("type", "")), null)
			if light_color_value == null:
				continue
			var enemy_pos := Vector2(enemy_bullet.get("pos", Vector2.ZERO))
			if view.has_point(enemy_pos):
				_push(layer, enemy_pos - camera, 62.0, Color(light_color_value, 0.30))
		# Orbes de cura e efeitos marcados com "light" (muzzle, impactos...).
		for orb_value in game.heal_orbs:
			if layer.count >= cap:
				break
			var orb: Dictionary = orb_value
			var orb_pos := Vector2(orb.get("pos", Vector2.ZERO))
			if view.has_point(orb_pos):
				_push(layer, orb_pos - camera, 40.0, Color(0.35, 1.0, 0.5, 0.22))
		for hit_enemy_value in game.enemies:
			if layer.count >= cap:
				break
			var hit_enemy: Dictionary = hit_enemy_value
			var flash_left: float = float(hit_enemy.get("hit_flash_until", 0.0)) - float(game.time_alive)
			if flash_left <= 0.0:
				continue
			var hit_pos := Vector2(hit_enemy.get("pos", Vector2.ZERO))
			if view.has_point(hit_pos):
				_push(layer, hit_pos - camera, 58.0, Color(1.0, 1.0, 1.0, 0.26 * clampf(flash_left / 0.12, 0.0, 1.0)))
		for effect_value in game.effects:
			if layer.count >= cap:
				break
			var effect: Dictionary = effect_value
			if not effect.has("light"):
				continue
			var effect_pos := Vector2(effect.get("pos", Vector2.ZERO))
			if not view.has_point(effect_pos):
				continue
			var strength: float = clampf(float(effect.get("life", 0.0)) / maxf(0.01, float(effect.get("max", 1.0))), 0.0, 1.0)
			var effect_color := Color(effect.get("color", Color.WHITE))
			_push(layer, effect_pos - camera, float(effect["light"]), Color(effect_color.r, effect_color.g, effect_color.b, 0.4 * strength))
	layer.queue_redraw()


static func _push(layer: LightLayer, screen_pos: Vector2, radius: float, color: Color) -> void:
	layer.push(Rect2(screen_pos - Vector2(radius, radius), Vector2(radius, radius) * 2.0), color)


## Vinheta + banho de cor da fase. Chamado pelo canvas do jogo antes do HUD.
static func draw_screen(game: Node2D, viewport: Vector2, surface: int) -> void:
	var grade_value = PHASE_GRADE.get(surface, null)
	if grade_value != null:
		var grade: Color = grade_value
		if game.current_phase == 5 and String(game.boss5_dimension) != "base":
			grade.a *= 1.35  # dimensoes transmutadas pesam mais no clima
		game.draw_rect(Rect2(Vector2.ZERO, viewport), grade, true)
	game.draw_texture_rect(vignette_texture(), Rect2(Vector2.ZERO, viewport), false)
