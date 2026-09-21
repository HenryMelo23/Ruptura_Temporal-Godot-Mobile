extends RefCounted

# Host-owned state and compatibility wrappers are retained during extraction.


static func _petro_frame(game: Node2D) -> Texture2D:
	var direction: String = game.petro_facing
	if game.petro_evolution > 1 and direction in ["up", "down", "stop"]:
		direction = "left" if game.petro_facing != "right" else "right"
	var candidates: = [
		"petro_%d_%s" % [game.petro_evolution, direction], 
		"petro_%d_left" % game.petro_evolution, 
		"petro_%d_right" % game.petro_evolution, 
		"petro_1_%s" % direction, 
		"petro_1_stop", 
		"petro_1_left", 
		"petro_1_right"
	]
	for key in candidates:
		var frame: Texture2D = game._companion_frame(String(key), game.petro_anim_time, 6.0)
		if frame != null:
			return frame
	return null


static func _companion_frame(game: Node2D, key: String, animation_time: float, fps: float) -> Texture2D:
	var frames = game.textures.get(key, [])
	if not frames is Array or frames.is_empty():
		return null
	return frames[int(animation_time * fps) % frames.size()]


static func _arauto_texture(game: Node2D) -> Texture2D:
	var frames: Array = game.textures.get("aguilhao" if game._arauto_is_aguilhao() else "arauto", [])
	if frames is Array and not frames.is_empty():
		var aguilhao_attack_frame: bool = game._arauto_is_aguilhao() and String(game.arauto.get("state", "idle")) in ["charge_windup", "charge", "seed", "pulse", "phase2_transition"]
		var index: = 1 if aguilhao_attack_frame and frames.size() > 1 else int(float(game.arauto.get("anim", 0.0)) * 5.5) % frames.size()
		var tex = frames[index]
		if tex:
			return tex
	var fallback: Array = game.textures.get("enemy_common_phase_1", [])
	if fallback is Array and not fallback.is_empty():
		return fallback[int(float(game.arauto.get("anim", 0.0)) * 5.5) % fallback.size()]
	return null


static func _enemy_draw_size(game: Node2D, enemy: Dictionary) -> Vector2:
	match String(enemy.get("type", game.ENEMY_COMMON)):
		game.ENEMY_AGGLOMERATOR:
			return Vector2(86, 86)
		game.ENEMY_LARAPIO:
			return Vector2(78, 78)
		game.ENEMY_ATIRADOR:
			return Vector2(82, 82)
		game.ENEMY_KAMIKAZE:
			return Vector2(78, 100)
		game.ENEMY_DEVOTO:
			return Vector2(62, 62)
		game.ENEMY_COUT_ATTACK_SPEED:
			return Vector2(82, 82)
		game.ENEMY_SHIELD_REFLECTOR:
			return Vector2(92, 92)
		game.ENEMY_GUARDIAO:
			return Vector2(98, 98)
		game.ENEMY_NEXUS_CHRONOPHAGE:
			return Vector2(94, 94)
		game.ENEMY_NEXUS_ECHO:
			return Vector2(76, 76)
		game.ENEMY_NEXUS_CARTOGRAPHER, game.ENEMY_NEXUS_REFRACTOR, game.ENEMY_NEXUS_WEAVER:
			return Vector2(84, 84)
		game.ENEMY_PYRO_PENGUIN:
			return Vector2(96, 137)
		game.ENEMY_MIASMA_EEL:
			return Vector2(92, 82)
		game.ENEMY_LODARIO:
			return Vector2(112, 60)
		game.ENEMY_FOSSIL_PUSTULE:
			return Vector2(92, 102)
		game.ENEMY_CHRONAL_LEECH:
			return Vector2(98, 62)
		game.ENEMY_CINERIDO:
			return Vector2(115, 52.5)
		game.ENEMY_PANGOLIRO:
			return Vector2(144, 90)
		game.ENEMY_CORVOL:
			return Vector2(86, 74)
	if game.current_phase == 4:
		return Vector2(84, 84)
	if game.current_phase == 6:
		return Vector2(88, 82)
	return Vector2(72, 72)


static func _enemy_texture(game: Node2D, enemy: Dictionary) -> Texture2D:
	var idx: int = int(enemy["phase"]) % 2
	var kind7: String = String(enemy.get("type", game.ENEMY_COMMON))
	if kind7 == game.ENEMY_CINERIDO:
		var cinerido_key: String = "enemy_phase_7_cinerido_atk" if String(enemy.get("phase7_state", "walk")) in ["windup", "active"] else "enemy_phase_7_cinerido_mov"
		var cinerido_frames: Array = game.textures.get(cinerido_key, [])
		var cinerido_idx: int = int(floor(float(enemy.get("phase", 0.0)))) % max(1, cinerido_frames.size())
		var cinerido_texture: Texture2D = game._texture_frame(cinerido_key, cinerido_idx)
		return cinerido_texture if cinerido_texture != null else game._texture_frame("enemy_common_phase_1", idx)
	if kind7 == game.ENEMY_PANGOLIRO:
		var pangoliro_key: String = "enemy_phase_7_pangoliro_atk" if String(enemy.get("phase7_state", "walk")) in ["windup", "roll"] else "enemy_phase_7_pangoliro"
		var pangoliro_frames: Array = game.textures.get(pangoliro_key, [])
		var pangoliro_idx: int = int(floor(float(enemy.get("phase", 0.0)))) % max(1, pangoliro_frames.size())
		var pangoliro_texture: Texture2D = game._texture_frame(pangoliro_key, pangoliro_idx)
		return pangoliro_texture if pangoliro_texture != null else game._texture_frame("enemy_common_phase_1", idx)
	if kind7 == game.ENEMY_CORVOL:
		var corvol_frames: Array = game.textures.get("enemy_phase_7_corvol", [])
		var corvol_idx: int = int(floor(float(enemy.get("phase", 0.0)))) % max(1, corvol_frames.size())
		var corvol_texture: Texture2D = game._texture_frame("enemy_phase_7_corvol", corvol_idx)
		return corvol_texture if corvol_texture != null else game._texture_frame("enemy_common_phase_1", idx)
	if game.current_phase == 6:
		var kind6: = String(enemy.get("type", game.ENEMY_MIASMA_EEL))
		if kind6 == game.ENEMY_MIASMA_EEL:
			idx = 1 if float(enemy.get("eel_attack_flash", 0.0)) > 0.0 else 0
		elif kind6 == game.ENEMY_LODARIO:
			idx = 1 if float(enemy.get("lodario_jump_progress", 0.0)) > 0.0 else 0
		elif kind6 == game.ENEMY_FOSSIL_PUSTULE:
			idx = 1 if float(enemy.get("pustule_spit_flash", 0.0)) > 0.0 else (int(floor(game.time_alive / 0.5)) % 2)
		elif kind6 == game.ENEMY_CHRONAL_LEECH:
			var leech_state: = String(enemy.get("leech_state", game.SANGUESSUGA_STATE_FALL_WARNING))
			idx = 1 if leech_state in [game.SANGUESSUGA_STATE_LEAPING, game.SANGUESSUGA_STATE_ATTACHED] else 0
		var phase6_texture: Texture2D = game._texture_frame(game._phase6_enemy_texture_key(kind6), idx)
		return phase6_texture if phase6_texture != null else game._texture_frame("enemy_common_phase_1", idx)
	if game.current_phase == 4:
		var moving_right4 = Vector2(enemy.get("facing_dir", Vector2.LEFT)).x >= 0.0
		var phase4_key = "enemy_phase_4_right" if moving_right4 else "enemy_phase_4_left"
		var phase4_texture: Texture2D = game._texture_frame(phase4_key, idx)
		return phase4_texture if phase4_texture != null else game._texture_frame("enemy_common_phase_1", idx)
	if game.current_phase == 3:
		var moving_right = Vector2(enemy.get("facing_dir", Vector2.LEFT)).x >= 0.0
		var phase3_key = "enemy_phase_3_right" if moving_right else "enemy_phase_3_left"
		var phase3_texture: Texture2D = game._texture_frame(phase3_key, idx)
		return phase3_texture if phase3_texture != null else game._texture_frame("enemy_common_phase_1", idx)
	var type_key: = ""
	match enemy["type"]:
		game.ENEMY_AGGLOMERATOR: type_key = "agglomerator"
		game.ENEMY_STALKER: type_key = "stalker"
		game.ENEMY_PROJECTOR: type_key = "projector"
		game.ENEMY_CRYSTAL: type_key = "crystal"
		game.ENEMY_CURATER: type_key = "curater"
		game.ENEMY_LARAPIO: type_key = "larapio"
	if type_key != "":
		var type_texture: Texture2D = game._texture_frame(type_key, idx)
		if type_texture != null:
			return type_texture
	if game.current_phase == 2:
		var phase2_kind: = String(enemy.get("type", game.ENEMY_COMMON))
		if phase2_kind == game.ENEMY_KAMIKAZE:
			var kamikaze_texture: Texture2D = game._texture_frame("enemy_phase_2_kamikaze", idx)
			if kamikaze_texture != null:
				return kamikaze_texture
		if phase2_kind == game.ENEMY_PYRO_PENGUIN:
			var pyro_texture: Texture2D = game._texture_frame("enemy_phase_2_pyro", idx)
			if pyro_texture != null:
				return pyro_texture
		var player_is_right = game.player_pos.x >= float(enemy["pos"].x)
		var phase2_key = "enemy_common_phase_2_right" if player_is_right else "enemy_common_phase_2_left"
		var phase2_texture: Texture2D = game._texture_frame(phase2_key, idx)
		if phase2_texture != null:
			return phase2_texture
	var common_texture: Texture2D = game._texture_frame("enemy_common_phase_1", idx)
	return common_texture if common_texture != null else game._texture_frame("enemy_left", idx)


static func _enemy_should_flip(game: Node2D, enemy: Dictionary) -> bool:
	if game.current_phase == 6:
		var phase6_kind: = String(enemy.get("type", game.ENEMY_COMMON))
		var phase6_dir: Vector2 = Vector2(enemy.get("facing_dir", game._enemy_default_facing(phase6_kind)))
		if phase6_kind == game.ENEMY_LODARIO:
			return phase6_dir.x > 0.05
		return false
	if game.current_phase == 3 or game.current_phase == 4:
		return false
	var dir: Vector2 = Vector2(enemy.get("facing_dir", game._enemy_default_facing(String(enemy.get("type", game.ENEMY_COMMON)))))
	var moving_right = dir.x >= 0.0
	match String(enemy.get("type", game.ENEMY_COMMON)):
		game.ENEMY_COMMON:
			return moving_right
		game.ENEMY_KAMIKAZE, game.ENEMY_PYRO_PENGUIN:
			return moving_right
		game.ENEMY_CINERIDO, game.ENEMY_PANGOLIRO, game.ENEMY_CORVOL:
			return moving_right
		game.ENEMY_STALKER:
			return not moving_right
		game.ENEMY_PROJECTOR:
			return not moving_right
		game.ENEMY_CRYSTAL:
			return moving_right
		game.ENEMY_LARAPIO:
			return not moving_right
		game.ENEMY_COUT_ATTACK_SPEED:
			return not moving_right
		game.ENEMY_SHIELD_REFLECTOR:
			return moving_right
	return false


static func _enemy_visual_offset(game: Node2D, enemy: Dictionary) -> Vector2:
	if String(enemy.get("type", "")) == game.ENEMY_LODARIO:
		return Vector2(0.0, - float(enemy.get("lodario_hop_arc", 0.0)))
	if String(enemy.get("type", "")) == game.ENEMY_CORVOL:
		return Vector2(0.0, -float(enemy.get("phase7_height", 22.0)))
	if String(enemy.get("type", "")) != game.ENEMY_LARAPIO:
		return Vector2.ZERO
	var move_dir: Vector2 = Vector2(enemy.get("last_move_dir", Vector2.ZERO))
	if move_dir.length() <= 0.05:
		return Vector2.ZERO
	var cycle = fmod(game.time_alive + float(enemy.get("phase", 0.0)) * 0.07, 1.0)
	var hop = 0.0
	var happy = float(enemy.get("happy_timer", 0.0)) > 0.0 or int(enemy.get("stolen", 0)) > 0
	var hop_window = 0.32 if happy else 0.22
	var hop_height = 24.0 if happy else 14.0
	if cycle < hop_window:
		hop = - sin(cycle / hop_window * PI) * hop_height
	return Vector2(0.0, hop)


static func _boss_texture(game: Node2D) -> Texture2D:
	if game.current_phase == 7:
		var key7: = "boss7_dive" if game.boss7_state == game.BOSS7_STATE_DIVE else "boss7_fly"
		var frames7: Array = game.textures.get(key7, [])
		if not frames7.is_empty() and frames7[int(game.boss_phase) % frames7.size()] != null:
			return frames7[int(game.boss_phase) % frames7.size()]
		return game.textures["boss"]
	if game.current_phase == 6:
		var form_key: String = game._boss6_form_key()
		var frames6: Array = game.textures.get(form_key, [])
		if not frames6.is_empty() and frames6[int(game.boss_phase) % frames6.size()] != null:
			return frames6[int(game.boss_phase) % frames6.size()]
		return game.textures["boss"]
	if game.current_phase == 5:
		if game.boss5_siphon_timer > 0.0:
			var shield_frames: Array = game.textures.get("boss5_shield", [])
			if not shield_frames.is_empty() and shield_frames[int(game.boss_phase) % shield_frames.size()] != null:
				return shield_frames[int(game.boss_phase) % shield_frames.size()]
		if game.damage_flash_timer > 0.0:
			var damage_frames: Array = game.textures.get("boss5_damage", [])
			if not damage_frames.is_empty() and damage_frames[int(game.boss_phase) % damage_frames.size()] != null:
				return damage_frames[int(game.boss_phase) % damage_frames.size()]
		var frames5: Array = game.textures.get("boss5", [])
		if not frames5.is_empty() and frames5[int(game.boss_phase) % frames5.size()] != null:
			return frames5[int(game.boss_phase) % frames5.size()]
		return game.textures["boss"]
	if game.current_phase == 4:
		if game.boss4_attack_pose_timer > 0.0 and game.textures.get("boss4_attack") != null:
			return game.textures["boss4_attack"]
		var frames4: Array = game.textures.get("boss4", [])
		if not frames4.is_empty():
			return frames4[int(game.boss4_anim_time) % frames4.size()]
		return game.textures["boss"]
	if game.current_phase == 3:
		var idx3 = int(game.boss_phase) % 2
		var use_walk_frames = game.boss3_is_moving and game.textures.has("boss_walk")
		return game.textures["boss_walk"][idx3] if use_walk_frames else game.textures["boss3"][idx3]
	if game.current_phase == 2:
		return game._boss2_texture()
	var pct = game.boss_hp / max(1.0, game.boss_hp_max)
	var idx = int(game.boss_phase) % 2
	if pct >= 0.6:
		return game.textures["boss_stage1"][idx] if game.textures["boss_stage1"][idx] else game.textures["boss"]
	if pct >= 0.4:
		return game.textures["boss_stage2"][idx] if game.textures["boss_stage2"][idx] else game.textures["boss"]
	return game.textures["boss_stage3"][idx] if game.textures["boss_stage3"][idx] else game.textures["boss"]


static func _boss2_texture(game: Node2D) -> Texture2D:
	var boss2_frames = game.textures.get("boss2", [])
	if not boss2_frames is Array or boss2_frames.is_empty():
		return game.textures["boss"]
	var frames: Array = boss2_frames
	var frame_count: = 2 if game.boss2_state == game.BOSS2_STATE_REPOSITION else frames.size()
	var idx = game.boss2_anim_frame % max(1, min(frame_count, frames.size()))
	return frames[idx] if frames[idx] else game.textures["boss"]


static func _boss_draw_position(game: Node2D) -> Vector2:
	if game.current_phase == 7:
		var hover: = -18.0 + sin(game.boss_phase * 0.9) * 5.0
		if game.boss7_state == game.BOSS7_STATE_DIVE:
			hover = -8.0
		return game.boss_pos + Vector2(0, hover)
	if game.current_phase == 6:
		return game.boss_pos
	if game.current_phase == 5:
		return game.boss_pos + Vector2(sin(game.boss_phase * 0.65) * 4.0, sin(game.boss_phase * 1.1) * 5.0)
	if game.current_phase == 4:
		return game.boss_pos + Vector2(0, sin(game.boss4_anim_time * 2.0) * 4.0)
	if game.current_phase == 3:
		return game.boss_pos
	if game.current_phase == 2:
		var bob: = 0.0
		if game.boss2_state == game.BOSS2_STATE_REPOSITION:
			bob = abs(sin((float(game.boss2_anim_frame) + game.boss2_anim_timer * 3.0) * PI)) * 9.0
		elif game.boss2_state != game.BOSS2_STATE_IDLE:
			bob = sin(game.time_alive * 6.0) * 3.0
		else:
			bob = sin(game.time_alive * 2.2) * 2.0
		return game.boss_pos + Vector2(0, - bob)
	if game.boss_stage_timer <= 0.0:
		return game.boss_pos
	var elapsed = game.BOSS_STAGE_JUMP_TIME - game.boss_stage_timer
	var hop = 0.0
	if elapsed <= game.BOSS_STAGE_SLAM_TIME:
		var jump_progress = clamp(elapsed / game.BOSS_STAGE_SLAM_TIME, 0.0, 1.0)
		hop = sin(jump_progress * PI) * 188.0
	else:
		var rebound_time = elapsed - game.BOSS_STAGE_SLAM_TIME
		hop = abs(sin(rebound_time * PI * 2.2)) * 28.0 * exp( - rebound_time * 2.6)
	return game.boss_pos + Vector2(0, - hop)


static func _boss_draw_size(game: Node2D) -> Vector2:
	return game.BOSS7_VISUAL_SIZE if game.current_phase == 7 else (Vector2(286, 257) if game.current_phase == 6 else (Vector2(300, 250) if game.current_phase == 4 else (Vector2(59.4, 88.0) if game.current_phase == 5 else Vector2(184, 170))))


static func _should_flip_player_sprite(game: Node2D) -> bool:
	if game.manifestation_key == "lacerante":
		# Dedicated left poses preserve the anatomical side of the eyepatch.
		return false
	var move = game._read_move()
	if game.lacerante_preparing and move.length() <= 0.12:
		return game.lacerante_prepare_dir.x < -0.1
	if game._player_attack_pose_active():
		if game.manifestation_key != "lacerante":
			return bool(game._player_fire_animation_info().get("flip_h", false))
		return game._aim_direction().x < -0.1
	if move.x < -0.1:
		return true
	if move.x > 0.1:
		return false
	return game.last_facing.x < -0.1


static func _player_is_moving_for_animation(game: Node2D) -> bool:
	var move = game._read_move()
	return move.length() > 0.12


static func _player_can_show_attack_sprite(game: Node2D) -> bool:
	return not game._player_is_moving_for_animation()


static func _player_attack_pose_active(game: Node2D) -> bool:
	var elapsed: float = game.time_alive - game.last_attack_time
	var duration: float = 0.5 if game.manifestation_key == "lacerante" else game.PLAYER_FIRE_FRAME_SECONDS * 2.0
	return elapsed >= 0.0 and elapsed < duration and game._player_can_show_attack_sprite()


static func _player_fire_animation_info(game: Node2D, direction: Vector2 = Vector2.ZERO) -> Dictionary:
	var source: Vector2 = direction if direction.length() > 0.05 else game.player_attack_visual_dir
	var dir: Vector2 = source.normalized() if source.length() > 0.05 else Vector2.RIGHT
	# Eight equal sectors: preserve E/W, provide real art for N/S and diagonals.
	var sector: int = posmod(roundi(dir.angle() / (PI / 4.0)), 8)
	var columns: Array[int] = [-1, 5, 0, 4, -1, 3, 1, 2]
	var column: int = columns[sector]
	if column < 0:
		return {"key": "player_fire", "flip_h": sector == 4, "network_offset": 0}
	return {"key": "player_fire_" + game.PLAYER_FIRE_DIRECTIONS[column], "flip_h": false, "network_offset": 2 + column * 2}


static func _player_fire_frame_index(game: Node2D, elapsed_time: float) -> int:
	return clampi(int(elapsed_time / game.PLAYER_FIRE_FRAME_SECONDS), 0, 1)


static func _player_fire_texture_for_current_attack(game: Node2D, elapsed_time: float) -> Texture2D:
	var info: Dictionary = game._player_fire_animation_info()
	var frames: Array = game.textures.get(String(info["key"]), [])
	return frames[game._player_fire_frame_index(elapsed_time)] if frames.size() == 2 else null


static func _player_fire_draw_profile(game: Node2D) -> Dictionary:
	if int(game._player_fire_animation_info()["network_offset"]) > 0:
		return {"preserve_height": true, "height": game.PLAYER_FIRE_CANVAS_HEIGHT, "offset": Vector2.ZERO}
	return {"size": game.PLAYER_DRAW_SHOT_SIZE, "offset": Vector2.ZERO}


static func _player_draw_profile(game: Node2D) -> Dictionary:
	var move = game._read_move()
	if game.manifestation_key == "lacerante":
		return {"preserve_height": true, "height": game.LaceranteSprites.DRAW_HEIGHT, "offset": Vector2.ZERO}
	if game.player_freeze_visual_timer > 0.0:
		return {
			"size": game.PLAYER_DRAW_FROZEN_SIZE, 
			"offset": Vector2.ZERO
		}
	if game.time_alive - game.last_damage_time < 0.35:
		return {
			"size": game.PLAYER_DRAW_DAMAGE_SIZE, 
			"offset": Vector2.ZERO
		}
	if game.lacerante_preparing and move.length() <= 0.12:
		return {
			"preserve_height": true, 
			"height": game.PLAYER_DRAW_LACERAR_HEIGHT, 
			"offset": Vector2.ZERO
		}
	if not game._active_prismatica_secondary().is_empty():
		return {
			"preserve_height": true, 
			"height": 84.0, 
			"offset": Vector2.ZERO
		}
	if game._player_attack_pose_active():
		if game.manifestation_key == "lacerante":
			return {
				"preserve_height": true, 
				"height": game.PLAYER_DRAW_LACERAR_HEIGHT, 
				"offset": Vector2.ZERO
			}
		if not game._player_is_moving_for_animation():
			return game._player_fire_draw_profile()
	if move.y < -0.1:
		return {
			"size": game.PLAYER_DRAW_UP_SIZE, 
			"offset": Vector2.ZERO
		}
	if move.y > 0.1:
		return {
			"size": game.PLAYER_DRAW_DOWN_SIZE, 
			"offset": Vector2.ZERO
		}
	if abs(move.x) > 0.1:
		return {
			"size": game.PLAYER_DRAW_SIDE_SIZE, 
			"offset": Vector2.ZERO
		}
	return {
		"size": game.PLAYER_DRAW_STOP_SIZE, 
		"offset": Vector2.ZERO
	}
