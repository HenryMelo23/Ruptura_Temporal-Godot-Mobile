extends RefCounted

const VALID_KINDS: = ["manifestation", "enemy", "boss", "fraction", "spectrum", "card"]
const REQUIRED_ENEMY_IDS: = [
	"comum", "espreitador", "projetador", "aglomerador", "cristalizado", 
	"curater", "larapio", "rebobinador", "briguer_escudeiro", 
	"pinguim_atirador", "pinguim_kamikaze", "pinguim_incendiario", 
	"devoto", "incensario", "guardiao", "cartografo_vazio", 
	"cronofago", "refrator_hostil", "tecelao_vetorial", "eco_entropico", 
	"enguia_miasma", "lodario", "pustula_fossil", "sanguessuga_cronal"
]
const REQUIRED_BOSS_IDS: = [
	"caranguejo_cosmico", "nevasca", "pai_rato", "nexo_ruptura", "umbra", "matriarca_chaga"
]
const REQUIRED_FACTION_IDS: = ["ruptura", "geovana", "arauto"]


static func validate(entries_by_tab: Array) -> Dictionary:
	var ids: = {}
	var issues: Array[String] = []
	var counts: = {}
	var entries: Array = []
	for tab_entries in entries_by_tab:
		if tab_entries is Array:
			for raw_item in tab_entries:
				var item: = Dictionary(raw_item)
				entries.append(item)
				var id: = String(item.get("id", item.get("key", item.get("name", "")))).strip_edges()
				var kind: = String(item.get("kind", "")).strip_edges()
				counts[kind] = int(counts.get(kind, 0)) + 1
				if id == "":
					issues.append("entrada sem id: %s" % String(item.get("name", "<sem nome>")))
					continue
				if ids.has(id):
					issues.append("id duplicado: %s" % id)
				ids[id] = true
				if not VALID_KINDS.has(kind):
					issues.append("categoria invalida em %s: %s" % [id, kind])
				if String(item.get("name", "")).strip_edges() == "":
					issues.append("nome vazio: %s" % id)
				if String(item.get("summary", item.get("desc", ""))).strip_edges().length() < 8:
					issues.append("resumo curto: %s" % id)
				if String(item.get("identity_text", item.get("desc", ""))).strip_edges().length() < 24:
					issues.append("identidade curta: %s" % id)
				if String(item.get("history_text", item.get("lore", ""))).strip_edges().length() < 24:
					issues.append("historia curta: %s" % id)
				if String(item.get("mechanics_text", item.get("mechanics", ""))).strip_edges().length() < 24:
					issues.append("mecanica curta: %s" % id)
				var combined_text: = "%s %s %s" % [
					String(item.get("summary", "")), 
					String(item.get("identity_text", "")), 
					String(item.get("history_text", ""))
				]
				if combined_text.find("TODO") >= 0 or combined_text.findn("lorem ipsum") >= 0:
					issues.append("placeholder textual: %s" % id)
	for required_id in REQUIRED_ENEMY_IDS:
		if not ids.has(required_id):
			issues.append("inimigo obrigatorio ausente: %s" % required_id)
	for required_id in REQUIRED_BOSS_IDS:
		if not ids.has(required_id):
			issues.append("chefe obrigatorio ausente: %s" % required_id)
	for required_id in REQUIRED_FACTION_IDS:
		if not ids.has(required_id):
			issues.append("fracao obrigatoria ausente: %s" % required_id)
	for item in entries:
		var owner_id: = String(item.get("id", item.get("key", item.get("name", ""))))
		for related in item.get("related_entry_ids", []):
			var related_id: = String(related)
			if related_id != "" and not ids.has(related_id):
				issues.append("relacao inexistente %s -> %s" % [owner_id, related_id])
	return {
		"ok": issues.is_empty(), 
		"issues": issues, 
		"counts": counts, 
		"total": entries.size()
	}
