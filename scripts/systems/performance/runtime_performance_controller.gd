class_name RTRuntimePerformanceController
extends RefCounted

# Runtime-only quality governor. It never changes combat, spawn, score or
# network authority; it only selects bounded presentation/sampling budgets.
const STAGE_FULL := 0
const STAGE_REDUCED := 1
const STAGE_EMERGENCY := 2

const REFERENCE_TARGET_FPS := 60.0
const LOW_FPS_RATIO := 0.82
const CRITICAL_FPS_RATIO := 0.48
const RECOVER_FPS_RATIO := 0.93
const REDUCED_TRIGGER_SECONDS := 1.5
const EMERGENCY_TRIGGER_SECONDS := 0.55
const REDUCED_TO_EMERGENCY_SECONDS := 3.0
const EMERGENCY_RECOVER_SECONDS := 6.0
const FULL_RECOVER_SECONDS := 10.0
const SAMPLE_RESPONSE := 4.0

var stage: int = STAGE_FULL
var smoothed_fps: float = 0.0
var low_fps_seconds: float = 0.0
var critical_fps_seconds: float = 0.0
var recovered_fps_seconds: float = 0.0
var sample_seconds: float = 0.0
var redraw_accumulator: float = 0.0
var emergency_skip_flip: bool = false


func reset() -> void:
	stage = STAGE_FULL
	smoothed_fps = 0.0
	low_fps_seconds = 0.0
	critical_fps_seconds = 0.0
	recovered_fps_seconds = 0.0
	sample_seconds = 0.0
	redraw_accumulator = 0.0
	emergency_skip_flip = false


func target_fps(game: Node) -> float:
	var configured := int(game.gfx_fps_limit)
	if configured <= 0:
		return REFERENCE_TARGET_FPS
	return minf(float(configured), REFERENCE_TARGET_FPS)


func effective_stage(game: Node) -> int:
	var result := stage
	# Compatibility with the former mobile boolean and the two explicit player
	# profiles. Those profiles start at the reduced presentation budget, but may
	# still escalate when the device cannot keep up.
	if bool(game.mobile_adaptive_visual_budget) or bool(game.gfx_low_resource) or bool(game._memory_saver_active()):
		result = maxi(result, STAGE_REDUCED)
	return result


func is_emergency(game: Node) -> bool:
	return effective_stage(game) >= STAGE_EMERGENCY


func force_stage_for_test(value: int) -> void:
	stage = clampi(value, STAGE_FULL, STAGE_EMERGENCY)


func update(game: Node, delta: float, measured_fps: float = -1.0) -> bool:
	if game.mode != "game" or game.dedicated_server_mode:
		low_fps_seconds = 0.0
		critical_fps_seconds = 0.0
		recovered_fps_seconds = 0.0
		return false
	var fps := measured_fps if measured_fps >= 0.0 else float(Engine.get_frames_per_second())
	if fps <= 0.0:
		return false
	var weight := clampf(1.0 - exp(-SAMPLE_RESPONSE * maxf(delta, 0.001)), 0.02, 1.0)
	smoothed_fps = fps if smoothed_fps <= 0.0 else lerpf(smoothed_fps, fps, weight)
	sample_seconds += delta
	if sample_seconds < 0.5:
		return false

	var target := target_fps(game)
	var low_threshold := target * LOW_FPS_RATIO
	var critical_threshold := target * CRITICAL_FPS_RATIO
	var recover_threshold := target * RECOVER_FPS_RATIO
	var previous_stage := stage

	if smoothed_fps < critical_threshold:
		critical_fps_seconds += delta
		low_fps_seconds += delta
		recovered_fps_seconds = 0.0
		if critical_fps_seconds >= EMERGENCY_TRIGGER_SECONDS:
			stage = STAGE_EMERGENCY
	elif smoothed_fps < low_threshold:
		critical_fps_seconds = 0.0
		low_fps_seconds += delta
		recovered_fps_seconds = 0.0
		if stage == STAGE_FULL and low_fps_seconds >= REDUCED_TRIGGER_SECONDS:
			stage = STAGE_REDUCED
		elif stage == STAGE_REDUCED and low_fps_seconds >= REDUCED_TO_EMERGENCY_SECONDS:
			stage = STAGE_EMERGENCY
	elif smoothed_fps >= recover_threshold:
		low_fps_seconds = 0.0
		critical_fps_seconds = 0.0
		recovered_fps_seconds += delta
		if stage == STAGE_EMERGENCY and recovered_fps_seconds >= EMERGENCY_RECOVER_SECONDS:
			stage = STAGE_REDUCED
			recovered_fps_seconds = 0.0
		elif stage == STAGE_REDUCED and recovered_fps_seconds >= FULL_RECOVER_SECONDS:
			stage = STAGE_FULL
			recovered_fps_seconds = 0.0
	else:
		critical_fps_seconds = 0.0
		low_fps_seconds = 0.0
		recovered_fps_seconds = 0.0

	game.mobile_adaptive_visual_budget = stage > STAGE_FULL
	game.mobile_low_fps_seconds = low_fps_seconds
	game.mobile_recovered_fps_seconds = recovered_fps_seconds
	return stage != previous_stage


func should_redraw(game: Node, delta: float) -> bool:
	var active_stage := effective_stage(game)
	if active_stage == STAGE_FULL or game.mode != "game":
		redraw_accumulator = 0.0
		return true
	var target_redraw_fps := 45.0 if active_stage == STAGE_REDUCED else 30.0
	# Below half of the requested frame rate, a redraw on every simulation tick
	# can trap a weak renderer at 18 FPS. Alternate submissions until it climbs
	# back above the critical band; simulation and multiplayer ticks keep running.
	if active_stage == STAGE_EMERGENCY and smoothed_fps > 0.0 and smoothed_fps < target_fps(game) * 0.55:
		emergency_skip_flip = not emergency_skip_flip
		if emergency_skip_flip:
			return false
	redraw_accumulator += delta
	var interval := 1.0 / target_redraw_fps
	if redraw_accumulator + 0.0001 < interval:
		return false
	redraw_accumulator = fmod(redraw_accumulator, interval)
	return true


func separation_interval(game: Node) -> float:
	match effective_stage(game):
		STAGE_EMERGENCY:
			return 1.0 / 15.0
		STAGE_REDUCED:
			return 1.0 / 30.0
	return 0.0
