class_name RTFormEvolutionCatalog
extends RefCounted

## Catalogo das evolucoes autorais (preenchido por forma).

const LABELS := {
	"eletrica": "Eletrica", "lacerante": "Lacerante", "prismatica": "Prismatica",
	"parasitica": "Parasitica", "gravitante": "Gravitante",
	"incendiario": "Incendiario", "barometrico": "Barometrico", "colosso": "Colosso",
}

const EVOLUTIONS: Array[Dictionary] = []


static func form_label(key: String) -> String:
	return String(LABELS.get(key, key.capitalize()))


static func for_form(key: String) -> Array:
	var out: Array = []
	for evo in EVOLUTIONS:
		if String(evo.get("form", "")) == key:
			out.append(evo)
	return out
