extends SceneTree

const RuntimeAssetController = preload("res://scripts/systems/assets/runtime_asset_controller.gd")

var failed := false


class FakeGame extends Node:
	var textures: Dictionary = {"enemy_common_phase_2_left": ["resident"]}

	func _safe_load(path: String):
		return path


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error("MOBILE_PHASE_ASSET_STREAMING_FAIL " + message)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(RuntimeAssetController.should_stream_phase_assets(true, false), "mobile full-quality profile must stream phase assets")
	_check(RuntimeAssetController.should_stream_phase_assets(false, true), "memory saver must stream phase assets")
	_check(not RuntimeAssetController.should_stream_phase_assets(false, false), "desktop full-quality profile should retain eager preload")
	_check(RuntimeAssetController.should_lazy_gallery_assets(true, false), "mobile full-quality profile must lazy-load gallery art")
	_check(RuntimeAssetController.should_lazy_gallery_assets(false, true), "memory saver must lazy-load gallery art")
	_check(not RuntimeAssetController.should_lazy_gallery_assets(false, false), "desktop full-quality gallery should retain eager preload")

	var full_quality_mobile := FakeGame.new()
	root.add_child(full_quality_mobile)
	RuntimeAssetController.prepare_phase(full_quality_mobile, 1, "res://assets/sprites/", true, false)
	_check(not full_quality_mobile.textures.has("enemy_common_phase_2_left"), "inactive phase assets remained resident")
	_check(Array(full_quality_mobile.textures.get("boss1_jump", [])).size() == 5, "mobile streaming removed authored jump frames")
	_check(Array(full_quality_mobile.textures.get("boss1_tide", [])).size() == 6, "mobile streaming removed authored ability frames")

	var memory_saver := FakeGame.new()
	root.add_child(memory_saver)
	RuntimeAssetController.prepare_phase(memory_saver, 1, "res://assets/sprites/", true, true)
	_check(Array(memory_saver.textures.get("boss1_jump", [])).size() == 3, "memory saver did not compact optional animation frames")
	_check(Array(memory_saver.textures.get("boss1_tide", [])).size() == 4, "memory saver lost the compact authored tide sequence")

	var gallery := FakeGame.new()
	gallery.textures = {
		"card_test": "resident",
		"manifestation_eletrica": "resident",
		"aura_racional": "resident",
		"cards_back": "persistent",
		"player_idle": ["persistent"]
	}
	root.add_child(gallery)
	var released := RuntimeAssetController.release_transient_gallery_assets(gallery)
	_check(released == 3, "gallery release count was not deterministic")
	_check(not gallery.textures.has("card_test") and not gallery.textures.has("manifestation_eletrica") and not gallery.textures.has("aura_racional"), "transient gallery art remained resident")
	_check(gallery.textures.has("cards_back") and gallery.textures.has("player_idle"), "gallery cleanup removed gameplay/shop shell assets")

	full_quality_mobile.free()
	memory_saver.free()
	gallery.free()
	print("MOBILE_PHASE_ASSET_STREAMING_OK mobile=phase_only gallery=lazy quality=full memory_saver=compact")
	quit(1 if failed else 0)
