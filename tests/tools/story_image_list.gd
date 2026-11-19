extends SceneTree

## Gera a tabela de imagens da HQ para o pedido ao Codex.
func _initialize() -> void:
	var lines: Array = []
	for item in RTStoryCatalog.all_images():
		var path := "res://assets/story/%s.jpg" % String(item[0])
		lines.append("| `%s.png` | %s | %s |" % [String(item[0]), String(item[1]), "ok" if ResourceLoader.exists(path) else "falta"])
	var f := FileAccess.open("res://.agent_logs/story_image_table.md", FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("STORY_IMAGES %d" % lines.size())
	quit(0)
