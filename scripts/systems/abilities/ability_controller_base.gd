class_name RTAbilityControllerBase
extends RefCounted

## Minimal common base for manifestation ability owners.
## Shared runtime state intentionally remains on Main during the extraction
## campaign; subclasses only coordinate one cohesive ability flow.

var core: Node


func configure(runtime_core: Node) -> void:
	core = runtime_core


func is_configured() -> bool:
	return core != null and is_instance_valid(core)
