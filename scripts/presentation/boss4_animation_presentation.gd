class_name RTBoss4AnimationPresentation
extends RefCounted

# Presentation-only resolver for the Rupture Astronaut Frog. Combat authority,
# movement and hit timing remain in RTBoss4Controller.

const DRAW_SIZE := Vector2(224.0, 224.0)
const DEATH_DURATION := 1.50
const ORIGINAL_ART_FACING := -1.0


static func reset(game: Node2D) -> void:
	game.boss4_visual_state = "idle"
	game.boss4_visual_state_elapsed = 0.0
	game.boss4_hit_timer = 0.0
	game.boss4_hit_duration = 0.22
	game.boss4_death_timer = 0.0
	game.boss4_death_duration = DEATH_DURATION
	game.boss4_death_pos = Vector2.ZERO
	game.boss4_ultimate_outcome = ""
	game.boss4_ultimate_outcome_timer = 0.0


static func update(game: Node2D, delta: float) -> void:
	game.boss4_hit_timer = maxf(0.0, game.boss4_hit_timer - delta)
	game.boss4_death_timer = maxf(0.0, game.boss4_death_timer - delta)
	game.boss4_ultimate_outcome_timer = maxf(0.0, game.boss4_ultimate_outcome_timer - delta)
	if game.boss4_ultimate_outcome_timer <= 0.0:
		game.boss4_ultimate_outcome = ""
	var next_state := visual_state(game)
	if next_state != game.boss4_visual_state:
		game.boss4_visual_state = next_state
		game.boss4_visual_state_elapsed = 0.0
	else:
		game.boss4_visual_state_elapsed += maxf(0.0, delta)


static func trigger_hit(game: Node2D, damage: float, source: String = "") -> void:
	if game.current_phase != 4 or damage <= 0.0 or death_active(game):
		return
	if source in ["veneno", "parasite_feast"] or source.begins_with("aura_"):
		return
	game.boss4_hit_timer = game.boss4_hit_duration


static func trigger_death(game: Node2D, death_position: Vector2 = Vector2.INF) -> void:
	if game.current_phase != 4 or death_active(game):
		return
	game.boss4_hit_timer = 0.0
	game.boss4_death_timer = DEATH_DURATION
	game.boss4_death_duration = DEATH_DURATION
	game.boss4_death_pos = game.boss_pos if not death_position.is_finite() else death_position
	game.boss4_visual_state = "death"
	game.boss4_visual_state_elapsed = 0.0


static func visual_state(game: Node2D) -> String:
	if death_active(game):
		return "death"
	if game.current_phase != 4:
		return ""
	if game.boss_entry_timer > 0.0:
		return "land"
	if game.boss4_hit_timer > 0.0:
		return "hit"
	if game.boss4_ultimate_outcome_timer > 0.0 and not game.boss4_ultimate_outcome.is_empty():
		return game.boss4_ultimate_outcome
	var state: String = String(game.boss4_controller.visual_state()) if game.boss4_controller != null else "idle"
	return state if not state.is_empty() else "idle"


static func active_texture(game: Node2D) -> Texture2D:
	var state := visual_state(game)
	if state.is_empty() or state == "death":
		return null
	var texture_key := "boss4_rework_" + state
	if not game.textures.has(texture_key):
		game._ensure_runtime_texture(texture_key)
	var frames: Array = game.textures.get(texture_key, [])
	if frames.is_empty():
		return null
	return frames[_frame_index(game, state, frames.size())] as Texture2D


static func draw_size(_game: Node2D) -> Vector2:
	return DRAW_SIZE


static func draw_position(game: Node2D) -> Vector2:
	var position: Vector2 = game.boss_pos
	if String(game.boss4_ai_state.get("state", "")) == "jump":
		var progress: float = clampf(float(game.boss4_ai_state.get("jump_progress", 0.0)), 0.0, 1.0)
		position.y -= sin(progress * PI) * 112.0
	return position


static func should_flip_h(game: Node2D) -> bool:
	return float(game.boss4_ai_state.get("facing", ORIGINAL_ART_FACING)) > 0.0


static func stage_modulate(game: Node2D) -> Color:
	var stage := clampi(int(game.boss4_stage), 1, 4)
	var colors := [Color.WHITE, Color(0.93, 1.0, 0.94), Color(1.0, 0.89, 0.95), Color(0.91, 0.76, 1.0)]
	var color: Color = colors[stage - 1]
	if game.boss4_hit_timer > 0.0:
		color = color.lerp(Color(1.0, 0.38, 0.36), 0.44)
	return color


static func death_active(game: Node2D) -> bool:
	return game.current_phase == 4 and game.boss4_death_timer > 0.0


static func draw_death(game: Node2D, camera: Vector2) -> void:
	var key := "boss4_rework_death"
	if not game.textures.has(key):
		game._ensure_runtime_texture(key)
	var frames: Array = game.textures.get(key, [])
	if frames.is_empty():
		return
	var progress: float = 1.0 - game.boss4_death_timer / maxf(0.001, game.boss4_death_duration)
	var index: int = clampi(int(floor(progress * float(frames.size()))), 0, frames.size() - 1)
	var texture := frames[index] as Texture2D
	var center: Vector2 = game.boss4_death_pos - camera
	var fade: float = 1.0 - clampf((progress - 0.86) / 0.14, 0.0, 1.0)
	if progress < 0.78:
		game._draw_dynamic_shadow_fit(texture, center + Vector2(0.0, 10.0), DRAW_SIZE, should_flip_h(game), true, 0.38 * fade)
	game._draw_entity_fit_flipped(texture, center, DRAW_SIZE, should_flip_h(game), Color(1.0, 1.0, 1.0, fade), true)


static func _frame_index(game: Node2D, state: String, frame_count: int) -> int:
	if frame_count <= 1:
		return 0
	if state == "hit":
		var progress: float = 1.0 - game.boss4_hit_timer / maxf(0.001, game.boss4_hit_duration)
		return clampi(int(floor(progress * float(frame_count))), 0, frame_count - 1)
	if state.begins_with("transition_"):
		var progress: float = clampf(game.boss4_visual_state_elapsed / 0.95, 0.0, 1.0)
		return clampi(int(floor(progress * float(frame_count))), 0, frame_count - 1)
	if state in ["slam", "tongue", "comet", "gravity"]:
		var total_by_state := {"slam": 1.31, "tongue": 1.22, "comet": 1.07, "gravity": 1.62}
		var total: float = float(total_by_state.get(state, 1.2))
		var progress: float = clampf(float(game.boss4_ai_state.get("action_total_elapsed", 0.0)) / total, 0.0, 1.0)
		return clampi(int(floor(progress * float(frame_count))), 0, frame_count - 1)
	if state == "jump":
		return clampi(int(floor(clampf(float(game.boss4_ai_state.get("jump_progress", 0.0)), 0.0, 1.0) * float(frame_count))), 0, frame_count - 1)
	if state == "land":
		var land_progress: float = clampf(float(game.boss4_ai_state.get("action_elapsed", 0.0)) / 0.18, 0.0, 1.0)
		return clampi(int(floor(land_progress * float(frame_count))), 0, frame_count - 1)
	if state in ["ultimate_interrupted", "ultimate_failure"]:
		var outcome_progress: float = 1.0 - game.boss4_ultimate_outcome_timer / 0.55
		return clampi(int(floor(outcome_progress * float(frame_count))), 0, frame_count - 1)
	if state == "ultimate":
		return mini(int(game.boss4_visual_state_elapsed * 6.0), frame_count - 1)
	var fps: float = 7.5 if state == "walk" else 5.0
	return int(game.boss4_visual_state_elapsed * fps) % frame_count
