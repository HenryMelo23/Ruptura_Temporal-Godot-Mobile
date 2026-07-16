extends SceneTree

var game: Node
var probe_request: HTTPRequest
var trace_path: String = ""


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("QA_FRAME_STREAM_FAIL " + message)
	quit(1)


func _initialize() -> void:
	trace_path = OS.get_environment("QA_STREAM_TRACE_PATH").strip_edges()
	_trace("init")
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	probe_request = HTTPRequest.new()
	root.add_child(probe_request)
	call_deferred("_run")


func _run() -> void:
	_trace("run")
	var base := OS.get_environment("QA_STREAM_SMOKE_BASE_URL").strip_edges()
	if base == "":
		base = "http://127.0.0.1:18080"
	game.qa_stream_base_url = base
	game.player_nickname = "qa-smoke"
	game.online_room_code = "smoke-%d" % Time.get_ticks_msec()
	game.qa_streaming_enabled = false
	game._start_game()
	for i in range(4):
		await process_frame
	_trace("capturable")

	game.qa_streaming_unlocked = true
	game.qa_streaming_quality_mode = "360p"
	game.qa_streaming_enabled = true
	game._start_qa_streaming_session()
	await _wait_for_session()
	_trace("session " + game.qa_streaming_session_id)
	_check(game.qa_streaming_frame_active, "session did not activate frame streaming")
	_check(game.qa_streaming_frame_url.begins_with(base), "frame URL did not use smoke relay")

	var encoded: PackedByteArray = game._capture_qa_stream_frame()
	_trace("encoded " + str(encoded.size()))
	_check(encoded.size() > 1024, "captured viewport frame is too small")
	_check(_looks_like_image(encoded), "captured viewport bytes are not an image")

	if OS.get_environment("QA_STREAM_DIRECT_POST") == "1":
		var direct_headers := PackedStringArray([
			"Content-Type: " + game.qa_streaming_frame_content_type,
			"X-Frame-Seq: 1"
		])
		var direct_response := await _request(HTTPClient.METHOD_POST, game.qa_streaming_frame_url, direct_headers, encoded)
		_trace("direct post code " + str(direct_response["code"]))
		_check(int(direct_response["code"]) >= 200 and int(direct_response["code"]) < 300, "direct Godot frame post failed")
	else:
		_trace("waiting automatic stream busy=" + str(game.qa_streaming_frame_in_flight_count) + " status=" + game.qa_streaming_status)
		await _wait_for_frame_post()
		_trace("posted " + str(game.qa_streaming_frame_count))
		if game.qa_streaming_frame_count < 1:
			_check(false, "relay did not acknowledge first visual frame")
			return

	var frame_response := await _request(HTTPClient.METHOD_GET, game.qa_streaming_frame_url, PackedStringArray(), PackedByteArray())
	_trace("got frame code " + str(frame_response["code"]))
	_check(int(frame_response["code"]) == 200, "GET /frame did not return image")
	var frame_body: PackedByteArray = frame_response["body"]
	_check(frame_body.size() > 1024, "returned frame is too small")
	_check(_looks_like_image(frame_body), "returned frame is not an image")
	_check(_image_decode_ok(frame_body), "returned frame could not be decoded")
	var image_size := _image_size(frame_body)
	_check(image_size.x >= game._qa_stream_target_size().x and image_size.y >= game._qa_stream_target_size().y, "returned frame is below stream profile resolution")
	var save_path := OS.get_environment("QA_STREAM_FRAME_SAVE_PATH").strip_edges()
	if save_path != "":
		var out := FileAccess.open(save_path, FileAccess.WRITE)
		if out != null:
			out.store_buffer(frame_body)
			out.close()

	var viewer_response := await _request(HTTPClient.METHOD_GET, game.qa_streaming_viewer_url, PackedStringArray(), PackedByteArray())
	_trace("got viewer code " + str(viewer_response["code"]))
	_check(int(viewer_response["code"]) == 200, "viewer did not load")
	_check(String(viewer_response["body"].get_string_from_utf8()).contains("/mjpeg"), "viewer is not using mjpeg visual endpoint")

	var json_response := await _request(HTTPClient.METHOD_GET, game.qa_streaming_viewer_url + "?format=json", PackedStringArray(), PackedByteArray())
	_trace("got json code " + str(json_response["code"]))
	var payload = JSON.parse_string(json_response["body"].get_string_from_utf8())
	_check(typeof(payload) == TYPE_DICTIONARY and int(payload.get("frameCount", 0)) >= 1, "stream status did not report visual frames")
	_check(int(payload.get("streamWidth", 0)) >= game._qa_stream_target_size().x, "server did not expose high stream width")
	_check(int(payload.get("streamHeight", 0)) >= game._qa_stream_target_size().y, "server did not expose high stream height")

	print("QA_FRAME_STREAM_SMOKE_OK bytes=%d returned=%d size=%dx%d frames=%d viewer=true" % [encoded.size(), frame_body.size(), image_size.x, image_size.y, int(payload.get("frameCount", 0))])
	_trace("ok")
	game._reset_qa_streaming_runtime()
	root.remove_child(game)
	game.queue_free()
	probe_request.queue_free()
	_trace("quit")
	quit(0)


func _wait_for_session() -> void:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 6000:
		if game.qa_streaming_session_id != "" or game.qa_streaming_status.contains("indisponivel") or game.qa_streaming_status.contains("invalida"):
			return
		await process_frame
	_check(false, "session timeout")


func _wait_for_frame_post() -> void:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 15000:
		if game.qa_streaming_frame_count > 0:
			return
		if game.qa_streaming_status.contains("recusado") or game.qa_streaming_status.contains("falha"):
			return
		if (Time.get_ticks_msec() - started) % 1000 < 20:
			_trace("wait active=" + str(game.qa_streaming_frame_active) + " timer=" + str(game.qa_streaming_frame_timer) + " busy=" + str(game.qa_streaming_frame_in_flight_count) + " avail=" + str(game._qa_stream_available_request_index()) + " status=" + game.qa_streaming_status)
		await process_frame
	_check(false, "frame post timeout")


func _request(method: int, url: String, headers: PackedStringArray, body: PackedByteArray) -> Dictionary:
	_trace("request " + str(method) + " " + url)
	var err: Error
	if body.is_empty():
		err = probe_request.request(url, headers, method)
	else:
		err = probe_request.request_raw(url, headers, method, body)
	_check(err == OK, "request failed to start: " + error_string(err))
	var result = await probe_request.request_completed
	_trace("response " + str(method) + " " + url + " code=" + str(result[1]))
	return {
		"result": int(result[0]),
		"code": int(result[1]),
		"headers": result[2],
		"body": result[3]
	}


func _looks_like_image(bytes: PackedByteArray) -> bool:
	if bytes.size() < 8:
		return false
	var is_jpeg := bytes[0] == 0xFF and bytes[1] == 0xD8
	var is_png := bytes[0] == 0x89 and bytes[1] == 0x50 and bytes[2] == 0x4E and bytes[3] == 0x47
	return is_jpeg or is_png


func _image_decode_ok(bytes: PackedByteArray) -> bool:
	var image := _decode_image(bytes)
	return image != null and image.get_width() >= 240 and image.get_height() >= 135


func _image_size(bytes: PackedByteArray) -> Vector2i:
	var image := _decode_image(bytes)
	if image == null:
		return Vector2i.ZERO
	return Vector2i(image.get_width(), image.get_height())


func _decode_image(bytes: PackedByteArray) -> Image:
	var image := Image.new()
	var err := ERR_UNAVAILABLE
	if bytes[0] == 0xFF and bytes[1] == 0xD8:
		err = image.load_jpg_from_buffer(bytes)
	else:
		err = image.load_png_from_buffer(bytes)
	if err != OK:
		return null
	return image


func _trace(message: String) -> void:
	if trace_path == "":
		return
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(trace_path) else FileAccess.WRITE
	var file := FileAccess.open(trace_path, mode)
	if file == null:
		return
	file.seek_end()
	file.store_line("%d %s" % [Time.get_ticks_msec(), message])
