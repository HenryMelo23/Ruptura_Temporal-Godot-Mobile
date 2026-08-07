
extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect if has_node("ColorRect") else null
@onready var label_title: Label = $LabelTitle if has_node("LabelTitle") else null

var phase_names: = {
	1: "RUÍNAS CÓSMICAS", 
	2: "ÁRTICO IMPERIAL", 
	3: "CATEDRAL DOS VERMES", 
	4: "CHARCO DOS SAPOS", 
	5: "COLISÃO DE MUNDOS", 
	6: "ABISMO FINAL"
}

var phase_shaders: = {
	1: "res://shaders/transitions/star_dissolve.gdshader", 
	2: "res://shaders/transitions/blizzard_wipe.gdshader", 
	3: "res://shaders/transitions/slime_drip_melt.gdshader", 
	4: "res://shaders/transitions/black_hole_vortex.gdshader", 
	5: "res://shaders/transitions/energy_crack_shatter.gdshader", 
	6: "res://shaders/transitions/worm_devour.gdshader"
}


func _ready() -> void :
	layer = 128
	if not color_rect:
		color_rect = ColorRect.new()
		color_rect.name = "ColorRect"
		color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(color_rect)
	if not label_title:
		label_title = Label.new()
		label_title.name = "LabelTitle"
		label_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		label_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label_title.add_theme_font_size_override("font_size", 36)
		label_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
		add_child(label_title)
	visible = false


func change_phase(phase_number: int, next_scene_path: String) -> void :
	label_title.text = phase_names.get(phase_number, "FASE %d" % phase_number)
	label_title.visible = true
	color_rect.color = Color.BLACK
	color_rect.material = null
	visible = true

	await get_tree().create_timer(2.0).timeout

	if not next_scene_path.is_empty() and ResourceLoader.exists(next_scene_path):
		ResourceLoader.load_threaded_request(next_scene_path)
		while ResourceLoader.load_threaded_get_status(next_scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame

		var new_scene_packed: = ResourceLoader.load_threaded_get(next_scene_path) as PackedScene
		if new_scene_packed:
			get_tree().change_scene_to_packed(new_scene_packed)

	var shader_path: String = phase_shaders.get(phase_number, phase_shaders[1])
	if ResourceLoader.exists(shader_path):
		var mat: = ShaderMaterial.new()
		mat.shader = load(shader_path) as Shader
		color_rect.material = mat
		label_title.visible = false

		var tween: = create_tween()
		tween.tween_property(mat, "shader_parameter/progress", 1.0, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await tween.finished

	visible = false

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("play_portal_spawn_animation"):
		player.play_portal_spawn_animation()
