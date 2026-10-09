extends SceneTree

const Boss1VFX = preload("res://scripts/vfx/boss1_vfx.gd")
const WIDTH: int = 1280
const HEIGHT: int = 720

class PreviewCanvas:
	extends Node2D

	const VFX = preload("res://scripts/vfx/boss1_vfx.gd")
	var attack: Dictionary = {}
	var low: bool = false

	func _draw() -> void:
		draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0.025, 0.035, 0.065), true)
		for x in range(0, WIDTH + 1, 64):
			draw_line(Vector2(x, 0), Vector2(x, HEIGHT), Color(0.08, 0.12, 0.18, 0.42), 1.0)
		for y in range(0, HEIGHT + 1, 64):
			draw_line(Vector2(0, y), Vector2(WIDTH, y), Color(0.08, 0.12, 0.18, 0.42), 1.0)
		draw_circle(Vector2(WIDTH * 0.5, HEIGHT * 0.5), 34.0, Color(0.08, 0.1, 0.16, 0.92))
		VFX.pincer_tenaz(self, attack, Vector2(WIDTH * 0.5, HEIGHT * 0.5), 1.7, low)


var canvas: Node2D


func _initialize() -> void:
	root.size = Vector2i(WIDTH, HEIGHT)
	canvas = PreviewCanvas.new()
	canvas.low = "--low" in OS.get_cmdline_user_args()
	root.add_child(canvas)
	call_deferred("_run")


func _save_state(name: String, attack: Dictionary) -> void:
	canvas.attack = attack
	canvas.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	assert(image != null and image.get_width() == WIDTH and image.get_height() == HEIGHT)
	var suffix: String = "_low" if canvas.low else ""
	var output_dir: String = "res://.agent_logs/boss1_pincer_tenaz_visual"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	assert(image.save_png("%s/%s%s.png" % [output_dir, name, suffix]) == OK)


func _run() -> void:
	var common: Dictionary = {
		"kind": "pincer_tenaz",
		"warning": 0.82,
		"first_dir": Vector2.RIGHT,
		"second_dir": Vector2.LEFT,
		"seed": 47
	}
	await _save_state("telegraph_first", common.merged({"state": "telegraph_first", "state_age": 0.45, "strike_index": 0}))
	await _save_state("telegraph_second", common.merged({"state": "telegraph_second", "state_age": 0.45, "strike_index": 2}))
	await _save_state("dash_first", common.merged({"state": "dash_first", "state_age": 0.28, "strike_index": 1}))
	await _save_state("dash_second", common.merged({"state": "dash_second", "state_age": 0.28, "strike_index": 2}))
	await _save_state("recovery", common.merged({"state": "recovery", "state_age": 0.16, "strike_index": 2}))
	print("BOSS1_PINCER_TENAZ_VISUAL_OK output=res://.agent_logs/boss1_pincer_tenaz_visual low=%s" % str(canvas.low))
	canvas.free()
	for _frame in range(3):
		await process_frame
	quit(0)
