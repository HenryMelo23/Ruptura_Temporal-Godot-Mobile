class_name RTFormEvolutionController
extends RefCounted

## Evolucoes autorais por forma (pos-Chefe 2). Catalogo em RTFormEvolutionCatalog.

var core
var chosen: Dictionary = {}


func configure(runtime_core) -> void:
	core = runtime_core


func reset() -> void:
	chosen = {}


func form_key() -> String:
	if String(core.active_character_key) == String(core.CHARACTER_HENRY):
		return String(core.mutation_key)
	return String(core.manifestation_key)


func form_label() -> String:
	return String(RTFormEvolutionCatalog.form_label(form_key()))


func has(id: String) -> bool:
	return String(chosen.get("id", "")) == id


func active_id() -> String:
	return String(chosen.get("id", ""))


func roll_offer(count: int = 3) -> Array:
	if not chosen.is_empty():
		return []
	var pool: Array = RTFormEvolutionCatalog.for_form(form_key())
	var offer: Array = []
	while offer.size() < count and not pool.is_empty():
		var i: int = core.rng.randi_range(0, pool.size() - 1)
		offer.append(Dictionary(pool[i]).duplicate(true))
		pool.remove_at(i)
	return offer


func apply(option: Dictionary) -> void:
	chosen = option.duplicate(true)
