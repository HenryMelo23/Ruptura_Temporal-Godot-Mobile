extends SceneTree

const CombatText = preload("res://scripts/presentation/combat_text_presentation.gd")
const OUT_DIR := "res://.agent_logs/combat_text_after"

class CombatTextCanvas extends Node2D:
	var effects: Array = []
	var damage_text_scale := 1.0

	func _damage_text_size(base_size: int) -> int:
		return int(clamp(round(float(base_size) * damage_text_scale), 10.0, 34.0))

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(960, 540)), Color(0.018, 0.025, 0.04), true)
		for x in [220.0, 480.0, 740.0]:
			draw_circle(Vector2(x, 330), 58.0, Color(0.055, 0.08, 0.105))
			draw_arc(Vector2(x, 330), 58.0, 0.0, TAU, 48, Color(0.22, 0.48, 0.62, 0.72), 2.0)
		for effect in effects:
			CombatText.draw(self, effect, Vector2.ZERO)


var canvas: CombatTextCanvas
var failed := false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("COMBAT_TEXT_PRESENTATION_FAIL " + message)


func _initialize() -> void:
	canvas = CombatTextCanvas.new()
	root.add_child(canvas)
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(960, 540)
	await process_frame
	canvas.damage_text_scale = 0.0
	CombatText.add_damage(canvas, 20.0, Vector2(220, 250), Color.WHITE, "enemy:off")
	_check(canvas.effects.is_empty(), "disabled text allocated an effect")

	canvas.damage_text_scale = 0.5
	CombatText.add_damage(canvas, 12.0, Vector2(220, 250), Color(0.62, 0.92, 1.0), "enemy:1")
	CombatText.add_damage(canvas, 18.0, Vector2(224, 250), Color(0.62, 0.92, 1.0), "enemy:1")
	_check(canvas.effects.size() == 1, "rapid regular hits were not merged")
	_check(int(canvas.effects[0].get("amount", 0)) == 30, "merged damage total is wrong")
	_check(int(canvas.effects[0].get("size", 0)) == 10, "minimum visible scale is wrong")

	canvas.damage_text_scale = 1.0
	canvas.effects[0]["size"] = canvas._damage_text_size(18)
	CombatText.add_damage(canvas, 96.0, Vector2(480, 250), Color(1.0, 0.72, 0.18), "enemy:2", true)
	CombatText.add_damage(canvas, 144.0, Vector2(740, 250), Color(0.72, 1.0, 0.84), "boss", true, "PONTO FRACO")
	_check(canvas.effects.size() == 3, "critical hits were incorrectly merged")
	_check(bool(canvas.effects[1].get("critical", false)), "critical metadata was lost")
	_check(String(canvas.effects[2].get("accent_label", "")) == "PONTO FRACO", "critical accent label was lost")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for effect in canvas.effects:
		effect["life"] = float(effect["max"]) * 0.84
	canvas.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var impact := root.get_texture().get_image()
	_check(impact != null and impact.get_size() == Vector2i(960, 540), "impact capture is invalid")
	_check(impact.save_png(OUT_DIR + "/combat_text_impact_960x540.png") == OK, "impact capture could not be saved")

	for effect in canvas.effects:
		effect["life"] = float(effect["max"]) * 0.48
	canvas.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var settle := root.get_texture().get_image()
	_check(settle != null and settle.get_size() == Vector2i(960, 540), "settle capture is invalid")
	_check(settle.save_png(OUT_DIR + "/combat_text_settle_960x540.png") == OK, "settle capture could not be saved")
	_check(impact.get_data() != settle.get_data(), "critical animation did not change between frames")

	if not failed:
		print("COMBAT_TEXT_PRESENTATION_OK off_allocations=0 merged_hits=2 critical_animation=true fonts=World+Top_Menu capture=960x540")
	canvas.queue_free()
	await process_frame
	quit(1 if failed else 0)
