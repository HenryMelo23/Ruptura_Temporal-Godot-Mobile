import sys

with open('scripts/main.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add menu tracks to root_music
target_root = """\tvar root_music = {
\t\t"Menu.mp3": "res://Menu.mp3",
\t\t"Boss1-1.mp3": "res://Boss1-1.mp3"
\t}"""
replacement_root = """\tvar root_music = {
\t\t"Menu.mp3": "res://Menu.mp3",
\t\t"Menu1-2.mp3": "res://Menu1-2.mp3",
\t\t"Menu1-3.MP3": "res://Menu1-3.MP3",
\t\t"Menu1-4.mp3": "res://Menu1-4.mp3",
\t\t"Boss1-1.mp3": "res://Boss1-1.mp3"
\t}"""
content = content.replace(target_root, replacement_root)


# 2. Add _play_menu_music_random
target_play_m = "func _play_phase1_music_random() -> void:"
replacement_play_m = """func _play_menu_music_random() -> void:
\tvar available = []
\tfor track in ["Menu.mp3", "Menu1-2.mp3", "Menu1-3.MP3", "Menu1-4.mp3"]:
\t\tif audio_streams.has(track):
\t\t\tavailable.append(track)
\tif available.is_empty():
\t\t_play_music("Menu.mp3")
\t\treturn
\tvar chosen = String(available[rng.randi_range(0, available.size() - 1)])
\tif chosen == current_music and music_player != null:
\t\tmusic_player.stream = audio_streams[chosen]
\t\tmusic_player.stream_paused = false
\t\tmusic_player.volume_db = linear_to_db(max(0.001, _music_target_volume()))
\t\tmusic_player.play()
\t\tmusic_pause_fade_mode = "in"
\t\tmusic_pause_fade_timer = 0.0
\t\tmusic_pause_resume_volume = max(0.001, _music_target_volume())
\t\t_set_music_linear_volume(0.001)
\t\treturn
\t_play_music(chosen)


func _play_phase1_music_random() -> void:"""
content = content.replace(target_play_m, replacement_play_m)


# 3. Use _play_menu_music_random instead of _play_music("Menu.mp3")
# In _ready: 
content = content.replace("\t_play_music(\"Menu.mp3\")", "\t_play_menu_music_random()")


# 4. _on_music_finished check for menu
target_on_fin = """func _on_music_finished() -> void:"""
replacement_on_fin = """func _on_music_finished() -> void:
\tif current_music.begins_with("Menu"):
\t\t_play_menu_music_random()
\t\treturn"""
content = content.replace(target_on_fin, replacement_on_fin)


# 5. Fade IN on _play_music
target_play_music = """\t\tmusic_player.volume_db = linear_to_db(max(0.001, _music_target_volume()))
\t\tmusic_player.play()
\telse:
\t\tmusic_player.stop()"""
replacement_play_music = """\t\tmusic_player.volume_db = linear_to_db(max(0.001, _music_target_volume()))
\t\tmusic_player.play()
\t\tmusic_pause_fade_mode = "in"
\t\tmusic_pause_fade_timer = 0.0
\t\tmusic_pause_resume_volume = max(0.001, _music_target_volume())
\t\t_set_music_linear_volume(0.001)
\telse:
\t\tmusic_player.stop()"""
content = content.replace(target_play_music, replacement_play_music)


# 6. Auto Fade OUT on _update_music_pause_fade
target_fade_update = """func _update_music_pause_fade(delta: float) -> void:
\tif music_player == null or music_pause_fade_mode == "":
\t\treturn
\tmusic_pause_fade_timer += delta
\tvar progress = clamp(music_pause_fade_timer / MUSIC_PAUSE_FADE_TIME, 0.0, 1.0)
\tif music_pause_fade_mode == "out":
\t\t_set_music_linear_volume(lerp(music_pause_resume_volume, 0.001, progress))
\t\tif progress >= 1.0:
\t\t\tmusic_player.stream_paused = true
\t\t\tmusic_paused_by_pause = true
\t\t\tmusic_pause_fade_mode = ""
\telif music_pause_fade_mode == "in":
\t\tvar target = max(0.001, _music_target_volume())
\t\t_set_music_linear_volume(lerp(0.001, target, progress))
\t\tif progress >= 1.0:
\t\t\tmusic_paused_by_pause = false
\t\t\tmusic_pause_fade_mode = ""
\t\t\t_update_audio_volumes()"""
replacement_fade_update = """func _update_music_pause_fade(delta: float) -> void:
\tif music_player != null and music_player.playing and music_player.stream != null:
\t\tif music_pause_fade_mode == "":
\t\t\tvar length = music_player.stream.get_length()
\t\t\tif length > 0.0:
\t\t\t\tvar pos = music_player.get_playback_position()
\t\t\t\tif length - pos <= 2.5:
\t\t\t\t\tmusic_pause_fade_mode = "auto_out"
\t\t\t\t\tmusic_pause_fade_timer = 0.0
\t\t\t\t\tmusic_pause_resume_volume = max(0.001, _music_target_volume())

\tif music_player == null or music_pause_fade_mode == "":
\t\treturn
\tmusic_pause_fade_timer += delta
\tvar max_time = 2.5 if music_pause_fade_mode == "auto_out" else MUSIC_PAUSE_FADE_TIME
\tvar progress = clamp(music_pause_fade_timer / max_time, 0.0, 1.0)
\tif music_pause_fade_mode == "out" or music_pause_fade_mode == "auto_out":
\t\t_set_music_linear_volume(lerp(music_pause_resume_volume, 0.001, progress))
\t\tif progress >= 1.0 and music_pause_fade_mode == "out":
\t\t\tmusic_player.stream_paused = true
\t\t\tmusic_paused_by_pause = true
\t\t\tmusic_pause_fade_mode = ""
\telif music_pause_fade_mode == "in":
\t\tvar target = max(0.001, _music_target_volume())
\t\t_set_music_linear_volume(lerp(0.001, target, progress))
\t\tif progress >= 1.0:
\t\t\tmusic_paused_by_pause = false
\t\t\tmusic_pause_fade_mode = ""
\t\t\t_update_audio_volumes()"""
content = content.replace(target_fade_update, replacement_fade_update)

with open('scripts/main.gd', 'w', encoding='utf-8') as f:
    f.write(content)
