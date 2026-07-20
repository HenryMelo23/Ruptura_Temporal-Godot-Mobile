extends SceneTree

var _frames: int = 300
var _scene_path: String = ""


func _init() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--frames="):
            _frames = max(1, int(argument.trim_prefix("--frames=")))
        elif argument.begins_with("--scene="):
            _scene_path = argument.trim_prefix("--scene=")

    call_deferred("_run_smoke_test")


func _run_smoke_test() -> void:
    if _scene_path.is_empty():
        _scene_path = str(ProjectSettings.get_setting("application/run/main_scene", ""))

    if _scene_path.is_empty():
        push_error("AGENT_SMOKE_TEST: No main scene is configured and no --scene argument was provided.")
        quit(1)
        return

    if not ResourceLoader.exists(_scene_path, "PackedScene"):
        push_error("AGENT_SMOKE_TEST: Scene does not exist or is not a PackedScene: %s" % _scene_path)
        quit(1)
        return

    var packed_scene := load(_scene_path) as PackedScene
    if packed_scene == null:
        push_error("AGENT_SMOKE_TEST: Failed to load scene: %s" % _scene_path)
        quit(1)
        return

    var instance := packed_scene.instantiate()
    if instance == null:
        push_error("AGENT_SMOKE_TEST: Failed to instantiate scene: %s" % _scene_path)
        quit(1)
        return

    root.add_child(instance)
    current_scene = instance

    for _frame in range(_frames):
        await process_frame

    print("AGENT_SMOKE_TEST_OK scene=%s frames=%d" % [_scene_path, _frames])
    if instance.has_method("_cleanup_runtime_resources"):
        instance.call("_cleanup_runtime_resources")
    if "textures" in instance:
        instance.textures.clear()
    if "audio_streams" in instance:
        instance.audio_streams.clear()
    current_scene = null
    root.remove_child(instance)
    instance.free()
    for _i in range(4):
        await process_frame
    quit(0)
