extends Control

@onready var bg: TextureRect      = $Bg
@onready var dim: ColorRect       = $Dim
@onready var ui: MarginContainer  = $UI
@onready var box: VBoxContainer   = $UI/Box
@onready var text: RichTextLabel  = $UI/Box/Text
@onready var speaker_lbl: Label   = $UI/Box/Speaker
@onready var hint_lbl: Label      = $UI/Box/Nav/Hint
@onready var skip_btn: Button     = $UI/Box/Nav/SkipBtn
@onready var fade: ColorRect      = $Fade
@onready var type_timer: Timer    = $TypeTimer

const NEXT_SCENE := "res://scenes/Level1.tscn"

var story: Array[Dictionary] = [
	{
		"bg": "res://scenes/assets/img/Pic1.png",          
		"speaker": "",
		"text": "یه روز عادی مثل همیشه رفته بودم دانشگاه.",
	},
	{
		"bg": "res://scenes/assets/img/Pic2.png",
		"speaker": "",
		"text": "به‌خاطر کم‌خوابی دیشب خیلی خوابم گرفته بود و خواستم سر کلاس بخوابم.",
	},
	{
		"bg": "res://scenes/assets/img/Pic3.png",
		"speaker": "",
		"text": "فکر کردم فقط نیم ساعت خوابیدم! چرا همه جا تاریکه!!!",
	}
]

var step: int = 0
var showing_full: bool = false

@export_range(0.005, 0.08, 0.001) var type_speed: float = 0.02  # کوچک‌تر = سریع‌تر

func _ready() -> void:
	_fix_layout()
	_connect_signals()
	_play_fade_in()
	_show_step(step)

func _connect_signals() -> void:
	type_timer.timeout.connect(_on_type_tick)
	skip_btn.pressed.connect(_on_skip_pressed)
	set_process_input(true)

func _fix_layout() -> void:
	anchors_preset = PRESET_FULL_RECT
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	if is_instance_valid(bg):
		bg.anchors_preset = PRESET_FULL_RECT
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if is_instance_valid(dim):
		dim.anchors_preset = PRESET_FULL_RECT
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if dim.color.a == 0.0:
			dim.color = Color(0,0,0,0.28)

	if is_instance_valid(fade):
		fade.anchors_preset = PRESET_FULL_RECT
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if fade.color.a < 0.99:
			fade.color = Color(0,0,0,1)

	if is_instance_valid(ui):
		ui.anchors_preset = PRESET_BOTTOM_WIDE
		ui.offset_left = 64
		ui.offset_right = -64
		ui.offset_bottom = -32
		ui.offset_top = 0
		ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if is_instance_valid(box):
		box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.size_flags_vertical = Control.SIZE_SHRINK_END
		box.custom_minimum_size.x = 980

	if is_instance_valid(text):
		text.bbcode_enabled = true
		text.fit_content = false
		text.autowrap_mode = TextServer.AUTOWRAP_WORD
		text.text_direction = Control.TEXT_DIRECTION_RTL
		text.custom_minimum_size.y = 200
		text.scroll_active = false
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if is_instance_valid(speaker_lbl):
		speaker_lbl.text_direction = Control.TEXT_DIRECTION_RTL

	if is_instance_valid(hint_lbl):
		hint_lbl.text = "ادامه: Space / Enter    رد کردن: Esc"
		hint_lbl.text_direction = Control.TEXT_DIRECTION_RTL

func _play_fade_in() -> void:
	if not is_instance_valid(fade):
		return
	fade.modulate.a = 1.0
	var tw := get_tree().create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, 0.35)

func _show_step(i: int) -> void:
	if i >= story.size():
		_exit_to_next_scene()
		return

	var item: Dictionary = story[i] as Dictionary

	var bg_path: String = str(item.get("bg", ""))
	if is_instance_valid(bg):
		if bg_path != "" and ResourceLoader.exists(bg_path):
			bg.texture = load(bg_path)
			bg.visible = true
		else:
			bg.visible = false  # اگر چیزی ندادیم، مشکلی پیش نیاد

	if is_instance_valid(speaker_lbl):
		speaker_lbl.text = str(item.get("speaker", ""))

	if is_instance_valid(text):
		var s: String = str(item.get("text", ""))
		text.bbcode_text = s
		text.visible_characters = 0
	showing_full = false

	type_timer.wait_time = type_speed
	type_timer.start()

func _on_type_tick() -> void:
	if not is_instance_valid(text):
		return
	var total: int = text.get_total_character_count()
	if text.visible_characters < total:
		text.visible_characters += 1
	else:
		type_timer.stop()
		showing_full = true

func _input(event: InputEvent) -> void:
	var next_pressed := false
	if event.is_action_pressed("ui_accept"):
		next_pressed = true
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		next_pressed = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		next_pressed = true

	if next_pressed:
		if showing_full:
			_next_step()
		else:
			_reveal_all()

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_exit_to_next_scene()

func _reveal_all() -> void:
	type_timer.stop()
	if is_instance_valid(text):
		text.visible_characters = -1
	showing_full = true

func _next_step() -> void:
	step += 1
	_show_step(step)

func _on_skip_pressed() -> void:
	_exit_to_next_scene()

func _exit_to_next_scene() -> void:
	if not is_instance_valid(fade):
		_go_next()
		return
	var tw := get_tree().create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.3)
	tw.finished.connect(_go_next)

func _go_next() -> void:
	if ResourceLoader.exists(NEXT_SCENE):
		get_tree().change_scene_to_file(NEXT_SCENE)
	else:
		push_warning("NEXT_SCENE پیدا نشد: %s" % NEXT_SCENE)
