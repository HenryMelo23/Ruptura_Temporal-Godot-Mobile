extends RefCounted

var path: String
var existed: bool
var contents: PackedByteArray


func _init(target_path: String) -> void:
	path = target_path
	existed = FileAccess.file_exists(path)
	if existed:
		contents = FileAccess.get_file_as_bytes(path)


func restore() -> void:
	if existed:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(contents)
			file.close()
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
