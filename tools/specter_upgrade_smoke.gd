extends SceneTree

const MAIN_SCENE := "res://scenes/Main.tscn"
const OUTPUT_PATH := "res://.agent_logs/specter_upgrade_smoke.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	if packed == null:
		push_error("SPECTER_UPGRADE_SMOKE: failed to load %s" % MAIN_SCENE)
		quit(1)
		return
	var instance := packed.instantiate()
	if instance == null:
		push_error("SPECTER_UPGRADE_SMOKE: failed to instantiate main scene")
		quit(1)
		return
	root.add_child(instance)
	current_scene = instance
	for _i in range(18):
		await process_frame

	instance.persistent_spectral_coins = 48
	instance.spectral_coins = 48
	instance.selected_aura = 0
	instance.specter_upgrade_previous_mode = "game_over"
	instance.specter_upgrade_selected = 0
	instance.specter_upgrade_action_selected = 0
	instance.mode = "game_over"
	if instance.has_method("_sync_current_aura_from_progress"):
		instance.call("_sync_current_aura_from_progress")
	if instance.has_method("_open_specter_upgrade"):
		instance.call("_open_specter_upgrade", "game_over")
	for _i in range(16):
		await process_frame

	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("SPECTER_UPGRADE_SMOKE: viewport image is empty")
		quit(1)
		return
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("SPECTER_UPGRADE_SMOKE: failed to save screenshot: %s" % str(error))
		quit(1)
		return
	print("SPECTER_UPGRADE_SMOKE_OK path=%s" % ProjectSettings.globalize_path(OUTPUT_PATH))
	if instance.has_method("_cleanup_runtime_resources"):
		instance.call("_cleanup_runtime_resources")
	current_scene = null
	root.remove_child(instance)
	instance.free()
	for _i in range(4):
		await process_frame
	quit(0)
