extends SceneTree

const Controller = preload("res://scripts/systems/performance/runtime_performance_controller.gd")

var failed := false


class FakeGame extends Node:
	var mode := "game"
	var dedicated_server_mode := false
	var gfx_fps_limit := 60
	var gfx_low_resource := false
	var gfx_memory_saver := false
	var mobile_adaptive_visual_budget := false
	var mobile_low_fps_seconds := 0.0
	var mobile_recovered_fps_seconds := 0.0

	func _memory_saver_active() -> bool:
		return gfx_memory_saver


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := FakeGame.new()
	root.add_child(game)
	var controller := Controller.new()

	_check(controller.effective_stage(game) == Controller.STAGE_FULL, "new run must start at full presentation")
	for _sample in range(20):
		controller.update(game, 0.1, 40.0)
	_check(controller.stage == Controller.STAGE_REDUCED, "sustained sub-target FPS must enter reduced stage")
	_check(game.mobile_adaptive_visual_budget, "compatibility budget flag must follow controller")
	_check(is_equal_approx(controller.separation_interval(game), 1.0 / 30.0), "reduced separation cadence must be 30 Hz")

	for _sample in range(10):
		controller.update(game, 0.1, 18.0)
	_check(controller.stage == Controller.STAGE_EMERGENCY, "critical FPS must enter emergency stage")
	_check(is_equal_approx(controller.separation_interval(game), 1.0 / 15.0), "emergency separation cadence must be 15 Hz")
	var critical_redraws := 0
	for _sample in range(10):
		critical_redraws += 1 if controller.should_redraw(game, 1.0 / 18.0) else 0
	_check(critical_redraws == 5, "critical renderer protection must alternate redraw submissions")

	for _sample in range(75):
		controller.update(game, 0.1, 60.0)
	_check(controller.stage == Controller.STAGE_REDUCED, "healthy FPS must recover emergency to reduced")
	for _sample in range(115):
		controller.update(game, 0.1, 60.0)
	_check(controller.stage == Controller.STAGE_FULL, "long healthy window must restore full presentation")
	_check(not game.mobile_adaptive_visual_budget, "compatibility budget flag must clear after recovery")

	controller.reset()
	game.gfx_fps_limit = 30
	for _sample in range(120):
		controller.update(game, 0.1, 30.0)
	_check(controller.stage == Controller.STAGE_FULL, "intentional 30 FPS cap must not trigger degradation")
	game.gfx_fps_limit = 60
	game.gfx_low_resource = true
	_check(controller.effective_stage(game) == Controller.STAGE_REDUCED, "manual performance profile must retain reduced floor")
	controller.force_stage_for_test(Controller.STAGE_EMERGENCY)
	_check(controller.effective_stage(game) == Controller.STAGE_EMERGENCY, "manual profile must still allow emergency protection")
	game.mode = "menu"
	_check(controller.should_redraw(game, 0.001), "menus must never be throttled by gameplay redraw cadence")

	game.queue_free()
	print("RUNTIME_ADAPTIVE_PERFORMANCE_OK stages=full,reduced,emergency recovery=hysteresis gameplay_contract=unchanged")
	quit(1 if failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("RUNTIME_ADAPTIVE_PERFORMANCE_FAIL " + message)
