class_name RTRuntimeCollectionUtils
extends RefCounted


static func compact_positive_float_field(items: Array, field: StringName) -> int:
	var original_size: int = items.size()
	var write_index: int = 0
	for read_index in range(original_size):
		var item = items[read_index]
		if not item is Dictionary or float(item.get(field, 0.0)) <= 0.0:
			continue
		if write_index != read_index:
			items[write_index] = item
		write_index += 1
	if write_index < original_size:
		items.resize(write_index)
	return original_size - write_index
