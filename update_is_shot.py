import sys

with open('scripts/main.gd', 'r', encoding='utf-8') as f:
    content = f.read()

target = """func _is_shot_audio(name: String) -> bool:
\tif name.begins_with("atk_"):
\t\treturn true
\treturn name in ["eletrica_travel", "retornante_wave", "retornante_reverse", "gravitante_orbit_loop"]"""

replacement = """func _is_shot_audio(name: String) -> bool:
\tif name.begins_with("atk_") or name.begins_with("skill_") or name.begins_with("ult_"):
\t\treturn true
\tif name.ends_with("_hit") or name.ends_with("_hit.wav") or name.ends_with("_hit.mp3"):
\t\treturn true
\tif name.begins_with("Hit_Boss"):
\t\treturn true
\tvar specific = [
\t\t"eletrica_travel", "retornante_wave", "retornante_reverse", 
\t\t"gravitante_orbit_loop", "prismatica_shatter", "Disparo.MP3", 
\t\t"Frasco.mp3", "Inimigo3_hit.mp3", "Inimigo1_hit.wav"
\t]
\treturn name in specific"""

content = content.replace(target, replacement)

with open('scripts/main.gd', 'w', encoding='utf-8') as f:
    f.write(content)
