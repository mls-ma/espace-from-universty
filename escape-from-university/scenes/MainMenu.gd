extends Control

const INTRO_SCENE := "res://scenes/StoryIntro.tscn"

var btn_new_game: Button
var btn_continue: Button
var btn_setting: Button
var btn_exit: Button
var settings_panel: Control

func _ready() -> void:
	btn_new_game  = get_node_or_null("%NewGame")
	if btn_new_game == null:
		btn_new_game = get_node_or_null("VBoxContainer/NewGame")

	btn_continue  = get_node_or_null("%Continue")
	if btn_continue == null:
		btn_continue = get_node_or_null("VBoxContainer/Continue")

	btn_setting   = get_node_or_null("%Setting")
	if btn_setting == null:
		btn_setting = get_node_or_null("VBoxContainer/Setting")

	btn_exit      = get_node_or_null("%Exit")
	if btn_exit == null:
		btn_exit = get_node_or_null("VBoxContainer/Exit")

	settings_panel = get_node_or_null("%SettingsPanel")
	if settings_panel == null:
		settings_panel = get_node_or_null("SettingsPanel")

	if btn_new_game:
		btn_new_game.pressed.connect(_on_new_game_pressed)
	else:
		OS.alert("دکمه NewGame پیدا نشد. نام/مسیر را چک کن: VBoxContainer/NewGame", "Main Menu")

	if btn_continue:
		btn_continue.pressed.connect(_on_continue_pressed)
		btn_continue.disabled = true  

	if btn_setting:
		btn_setting.pressed.connect(_on_setting_pressed)

	if btn_exit:
		btn_exit.pressed.connect(_on_exit_pressed)

	_detect_blockers()

	if btn_new_game:
		print("[Menu] NewGame connected. disabled=%s visible=%s" % [str(btn_new_game.disabled), str(btn_new_game.visible)])
	print_tree()

func _on_new_game_pressed() -> void:
	print("[Menu] New Game pressed")
	if not ResourceLoader.exists(INTRO_SCENE):
		OS.alert("StoryIntro.tscn پیدا نشد:\n" + INTRO_SCENE, "New Game")
		return
	var err := get_tree().change_scene_to_file(INTRO_SCENE)
	if err != OK:
		push_error("change_scene_to_file failed: %s" % err)
		OS.alert("خطا در لود صحنه (کد: %s)" % err, "New Game")

func _on_continue_pressed() -> void:
	OS.alert("Continue هنوز پیاده‌سازی نشده.", "Continue")

func _on_setting_pressed() -> void:
	if settings_panel:
		settings_panel.visible = not settings_panel.visible
	else:
		OS.alert("SettingsPanel پیدا نشد. مسیر: SettingsPanel", "Settings")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _detect_blockers() -> void:
	var blockers: Array[String] = []
	_scan_blockers(self, blockers)
	if blockers.size() > 0:
		var msg := "ممکن است این نودها روی دکمه‌ها را پوشانده باشند (Mouse Filter آنها Ignore نیست):\n- " + String("\n- ").join(blockers)
		print_rich("[color=yellow]" + msg + "[/color]")

func _scan_blockers(n: Node, out: Array[String]) -> void:
	if n is Control:
		var c := n as Control
		var full_rect := (c.anchor_left == 0.0 and c.anchor_top == 0.0 and c.anchor_right == 1.0 and c.anchor_bottom == 1.0)
		var blocks_mouse := (c.mouse_filter != Control.MOUSE_FILTER_IGNORE)
		if full_rect and blocks_mouse and n != self:
			out.append("%s (mouse_filter=%s, z_index=%d)" % [n.get_path(), str(c.mouse_filter), c.z_index])
	for child in n.get_children():
		_scan_blockers(child, out)
