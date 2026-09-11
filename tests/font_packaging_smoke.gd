extends SceneTree

var game: Node


func _check(condition: bool, message: String) -> void:
	if not condition:
		push_error("FONT_PACKAGING_FAIL " + message)
		quit(1)


func _initialize() -> void:
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_check(ResourceLoader.exists("res://assets/fonts/Top_Menu.otf"), "Top_Menu.otf missing from res://")
	_check(ResourceLoader.exists("res://assets/fonts/World.otf"), "World.otf missing from res://")
	_check(game.menu_title_font != null, "menu title font was not loaded")
	_check(game.menu_button_font != null, "menu button font was not loaded")
	_check(game.menu_title_font != ThemeDB.fallback_font, "menu title font fell back to ThemeDB")
	_check(game.menu_button_font != ThemeDB.fallback_font, "menu button font fell back to ThemeDB")
	_check(game.font == game.menu_button_font, "global draw font was not replaced by the packaged font")
	print("FONT_PACKAGING_OK packaged_menu_fonts_active")
	game.queue_free()
	await process_frame
	quit(0)
