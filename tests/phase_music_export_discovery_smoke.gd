extends SceneTree

const AudioLifecycle = preload("res://scripts/systems/audio/audio_lifecycle.gd")


func _initialize() -> void:
	var pack_path := "user://phase_music_discovery.pck"
	var packer := PCKPacker.new()
	assert(packer.pck_start(pack_path) == OK)
	assert(packer.add_file("res://qa_music_pack/Fases1.mp3.import", "res://Sounds/Fases1.mp3.import") == OK)
	assert(packer.flush() == OK)
	assert(ProjectSettings.load_resource_pack(pack_path))
	assert(not FileAccess.file_exists("res://qa_music_pack/Fases1.mp3"))
	var tracks: Array = AudioLifecycle.discover_shared_phase_music_tracks("res://qa_music_pack")
	assert(tracks == ["Fases1.mp3"], "exported import entry was not discovered")
	var stream: AudioStream = load("res://qa_music_pack/Fases1.mp3")
	assert(stream != null and stream.get_length() > 1.0)
	print("PHASE_MUSIC_EXPORT_DISCOVERY_OK source_absent=true imported_stream_loaded=true")
	quit(0)
