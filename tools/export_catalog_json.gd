extends SceneTree

const OUTPUT_PATH := "res://docs/catalogo_temporal_textos.json"

var game: Node


func _initialize() -> void:
	game = load("res://scripts/main.gd").new()
	call_deferred("_run")


func _run() -> void:
	var payload := {
		"schema_version": 1,
		"arquivo": OUTPUT_PATH,
		"observacao": "Textos extraidos do Catalogo Temporal. Edite os campos dentro de abas[].entradas[] e me passe de volta quando quiser aplicar no jogo.",
		"abas": []
	}
	for tab_index in range(game.CATALOG_TABS.size()):
		game._catalog_reset_tab(tab_index)
		var entries: Array = []
		for raw_item in game._catalog_items():
			var item: Dictionary = Dictionary(raw_item)
			entries.append(_export_entry(item))
		payload["abas"].append({
			"indice": tab_index,
			"id": String(game.CATALOG_TABS[tab_index]),
			"rotulo": game._catalog_tab_label(tab_index),
			"entradas": entries
		})
	var json_text := JSON.stringify(_sanitize(payload), "\t", false)
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("EXPORT_CATALOG_JSON_FAIL nao abriu arquivo: %s erro=%s" % [OUTPUT_PATH, error_string(FileAccess.get_open_error())])
		_cleanup_and_quit(1)
		return
	file.store_string(json_text + "\n")
	file.close()
	print("EXPORT_CATALOG_JSON_OK path=%s entries=%d" % [ProjectSettings.globalize_path(OUTPUT_PATH), _entry_count(payload)])
	_cleanup_and_quit(0)


func _export_entry(item: Dictionary) -> Dictionary:
	var kind: String = game._catalog_item_kind(item)
	return {
		"id": String(item.get("id", item.get("key", ""))),
		"kind": kind,
		"categoria": String(item.get("category", "")),
		"nome": String(item.get("name", "")),
		"nome_curto": String(item.get("short_name", item.get("name", ""))),
		"subtitulo": String(item.get("subtitle", "")),
		"classificacao": String(item.get("classification", "")),
		"funcao": String(item.get("role", "")),
		"raridade": String(item.get("rarity", "")),
		"fonte": String(item.get("source_type", "")),
		"desbloqueio": String(item.get("unlock_rule", "")),
		"texto_curto_lista": String(game._catalog_short_text(item)),
		"resumo": String(item.get("summary", "")),
		"descricao_detalhada": String(game._catalog_detail_description(item)),
		"lore": String(game._catalog_detail_lore(item)),
		"mecanicas": String(game._catalog_detail_mechanics(item)),
		"nota_de_campo": String(item.get("field_note", "")),
		"texto_identidade_bruto": String(item.get("identity_text", item.get("desc", ""))),
		"texto_historia_bruto": String(item.get("history_text", item.get("lore", ""))),
		"texto_mecanicas_bruto": String(item.get("mechanics_text", item.get("mechanics", ""))),
		"sprite_ou_textura": String(item.get("texture", item.get("icon", ""))),
		"icone": String(item.get("icon", "")),
		"cor": _color_to_json(item.get("accent_color", item.get("color", Color.WHITE))),
		"ids_relacionados": _sanitize(item.get("related_entry_ids", [])),
		"palavras_chave": _sanitize(item.get("keywords", [])),
		"aliases": _sanitize(item.get("aliases", [])),
		"campos_originais": _sanitize(item)
	}


func _entry_count(payload: Dictionary) -> int:
	var total := 0
	for tab in payload.get("abas", []):
		total += Array(Dictionary(tab).get("entradas", [])).size()
	return total


func _color_to_json(value: Variant) -> Dictionary:
	if value is Color:
		var color: Color = value
		return {
			"r": color.r,
			"g": color.g,
			"b": color.b,
			"a": color.a,
			"html": color.to_html(true)
		}
	return {
		"r": 1.0,
		"g": 1.0,
		"b": 1.0,
		"a": 1.0,
		"html": "ffffffff"
	}


func _sanitize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL:
			return null
		TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_COLOR:
			return _color_to_json(value)
		TYPE_VECTOR2:
			var vector2: Vector2 = value
			return {"x": vector2.x, "y": vector2.y}
		TYPE_VECTOR2I:
			var vector2i: Vector2i = value
			return {"x": vector2i.x, "y": vector2i.y}
		TYPE_RECT2:
			var rect2: Rect2 = value
			return {
				"x": rect2.position.x,
				"y": rect2.position.y,
				"w": rect2.size.x,
				"h": rect2.size.y
			}
		TYPE_ARRAY:
			var output_array: Array = []
			for item in value:
				output_array.append(_sanitize(item))
			return output_array
		TYPE_DICTIONARY:
			var output_dict := {}
			var dict: Dictionary = value
			for key in dict.keys():
				output_dict[String(key)] = _sanitize(dict[key])
			return output_dict
		_:
			return str(value)


func _cleanup_and_quit(code: int) -> void:
	if game != null:
		game.free()
		game = null
	for _i in range(4):
		await process_frame
	quit(code)
