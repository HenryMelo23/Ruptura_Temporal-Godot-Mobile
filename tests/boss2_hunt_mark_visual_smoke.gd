extends SceneTree

const Boss2VFX = preload("res://scripts/vfx/boss2_vfx.gd")

class HuntMarkCanvas:
	extends Node2D

	var t: float = 22.4

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.015, 0.025, 0.04, 1.0))
		for x in range(120, 1280, 160):
			draw_line(Vector2(x, 80), Vector2(x - 80, 680), Color(0.08, 0.16, 0.2, 0.28), 1.0)
		var origin := Vector2(850, 305)
		var target := Vector2(430, 430)
		Boss2VFX.hunt_mark(self, origin, target, target, 72.0, 42.0, 1.08, 1.82, 0.38, t, false)
		draw_circle(origin, 36.0, Color(0.05, 0.22, 0.34, 0.72))
		draw_arc(origin, 42.0, 0.0, TAU, 48, Color(0.62, 0.96, 1.0, 0.9), 3.0)
		draw_circle(target, 14.0, Color(0.96, 0.96, 1.0, 0.88))

var canvas: HuntMarkCanvas


func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	canvas = HuntMarkCanvas.new()
	root.add_child(canvas)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("BOSS2_HUNT_MARK_VISUAL_FAIL " + message)
	quit(1)


func _run() -> void:
	canvas.queue_redraw()
	await process_frame
	await process_frame
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() > 0 and image.get_height() > 0, "invalid_capture")
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path("res://.codex"))
	var output := "res://.codex/boss2_hunt_mark_telegraph_qa_1280x720.png"
	_check(image.save_png(output) == OK, "save_failed")
	print("BOSS2_HUNT_MARK_VISUAL_OK " + ProjectSettings.globalize_path(output))
	quit(0)
