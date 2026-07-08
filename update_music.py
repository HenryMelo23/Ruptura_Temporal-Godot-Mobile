import sys

with open('scripts/main.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update root_music
target_root = """\tvar root_music = {
\t\t"Menu.mp3": "res://Menu.mp3",
\t\t"Fase2.mp3": "res://Fase2.mp3",
\t\t"Boss1-1.mp3": "res://Boss1-1.mp3"
\t}"""
replacement_root = """\tvar root_music = {
\t\t"Menu.mp3": "res://Menu.mp3",
\t\t"Boss1-1.mp3": "res://Boss1-1.mp3"
\t}"""
content = content.replace(target_root, replacement_root)

# 2. Update phase1_tracks and add phase2_tracks
target_phase1 = """\tvar phase1_tracks = {
\t\t"Fase1.mp3": "res://Fase1.mp3",
\t\t"Fase1-2.mp3": "res://Fase1-2.mp3"
\t}
\tfor name in phase1_tracks:
\t\tvar stream = _safe_load_audio(phase1_tracks[name], false)
\t\tif stream:
\t\t\taudio_streams[name] = stream"""
replacement_phase1 = """\tvar phase1_tracks = {
\t\t"Fase1.mp3": "res://Fase1.mp3",
\t\t"Fase1-2.mp3": "res://Fase1-2.mp3",
\t\t"Fase1-4.mp3": "res://Fase1-4.mp3"
\t}
\tfor name in phase1_tracks:
\t\tvar stream = _safe_load_audio(phase1_tracks[name], false)
\t\tif stream:
\t\t\taudio_streams[name] = stream
\tvar phase2_tracks = {
\t\t"Fase2.mp3": "res://Fase2.mp3",
\t\t"Fase2-3.mp3": "res://Fase2-3.mp3",
\t\t"Fase2-4.mp3": "res://Fase2-4.mp3"
\t}
\tfor name in phase2_tracks:
\t\tvar stream = _safe_load_audio(phase2_tracks[name], false)
\t\tif stream:
\t\t\taudio_streams[name] = stream"""
content = content.replace(target_phase1, replacement_phase1)

# 3. Update _play_phase_music
target_play_phase = """\telif current_phase == 2:
\t\t_play_music("Fase2.mp3")"""
replacement_play_phase = """\telif current_phase == 2:
\t\t_play_phase2_music_random()"""
content = content.replace(target_play_phase, replacement_play_phase)

# 4. Update _on_music_finished
target_on_finished = """func _on_music_finished() -> void:
\tif current_music == "Fase1.mp3" or current_music == "Fase1-2.mp3":
\t\t_play_phase1_music_random()
\t\treturn
\tif current_music == "Fase3-1.mp3" or current_music == "Fase3-2.mp3":
\t\t_play_phase3_music_random()
\t\treturn"""
replacement_on_finished = """func _on_music_finished() -> void:
\tif current_music in ["Fase1.mp3", "Fase1-2.mp3", "Fase1-4.mp3"]:
\t\t_play_phase1_music_random()
\t\treturn
\tif current_music in ["Fase2.mp3", "Fase2-3.mp3", "Fase2-4.mp3"]:
\t\t_play_phase2_music_random()
\t\treturn
\tif current_music in ["Fase3-1.mp3", "Fase3-2.mp3"]:
\t\t_play_phase3_music_random()
\t\treturn"""
content = content.replace(target_on_finished, replacement_on_finished)

# 5. Update _play_phase1_music_random
target_play_p1 = """func _play_phase1_music_random() -> void:
\tvar available = []
\tfor track in ["Fase1.mp3", "Fase1-2.mp3"]:"""
replacement_play_p1 = """func _play_phase1_music_random() -> void:
\tvar available = []
\tfor track in ["Fase1.mp3", "Fase1-2.mp3", "Fase1-4.mp3"]:"""
content = content.replace(target_play_p1, replacement_play_p1)

# 6. Add _play_phase2_music_random
target_play_p3 = "func _play_phase3_music_random() -> void:"
replacement_play_p2 = """func _play_phase2_music_random() -> void:
\tvar available = []
\tfor track in ["Fase2.mp3", "Fase2-3.mp3", "Fase2-4.mp3"]:
\t\tif audio_streams.has(track):
\t\t\tavailable.append(track)
\tif available.is_empty():
\t\t_play_music("Fase2.mp3")
\t\treturn
\tvar chosen = String(available[rng.randi_range(0, available.size() - 1)])
\tif chosen == current_music and music_player != null:
\t\tmusic_player.stream = audio_streams[chosen]
\t\tmusic_player.stream_paused = false
\t\tmusic_player.volume_db = linear_to_db(max(0.001, _music_target_volume()))
\t\tmusic_player.play()
\t\treturn
\t_play_music(chosen)


func _play_phase3_music_random() -> void:"""
content = content.replace(target_play_p3, replacement_play_p2)

with open('scripts/main.gd', 'w', encoding='utf-8') as f:
    f.write(content)
