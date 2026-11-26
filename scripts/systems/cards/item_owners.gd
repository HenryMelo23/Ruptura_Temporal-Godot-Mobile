extends RefCounted
## Fachada dos donos de itens novos: o nucleo chama uma linha so por evento
## comum (configurar, zerar, atualizar, abate, velocidade) e a fachada repassa
## para cada dono. Ganchos especificos continuam chamando o dono direto.

var owners: Array = []


func _init(list: Array) -> void:
	owners = list


func configure(runtime_core: Node) -> void:
	for owner in owners:
		if owner.core != runtime_core:
			owner.configure(runtime_core)


func reset() -> void:
	for owner in owners:
		owner.reset()


func update(delta: float) -> void:
	for owner in owners:
		owner.update(delta)


func on_enemy_killed(enemy: Dictionary) -> void:
	for owner in owners:
		owner.on_enemy_killed(enemy)


func movement_speed_bonus() -> float:
	var bonus := 0.0
	for owner in owners:
		bonus += float(owner.movement_speed_bonus())
	return bonus
