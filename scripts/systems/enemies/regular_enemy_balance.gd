class_name RTRegularEnemyBalance
extends RefCounted

const HP_SCALING_RETENTION := 0.55
const ARMOR_SCALING_RETENTION := 0.55


static func scaled_hp(current_base_hp: float, original_base_hp: float) -> float:
	var growth := maxf(0.0, current_base_hp - original_base_hp)
	return original_base_hp + growth * HP_SCALING_RETENTION


static func softened_damage_taken(original_multiplier: float) -> float:
	var reduction := 1.0 - clampf(original_multiplier, 0.0, 1.0)
	return 1.0 - reduction * ARMOR_SCALING_RETENTION


static func health_scaling_exempt(enemy_type: String, larapio_type: String, amber_suturer_type: String, amber_node_type: String, sineiro_type: String) -> bool:
	return enemy_type in [larapio_type, amber_suturer_type, amber_node_type, sineiro_type]
