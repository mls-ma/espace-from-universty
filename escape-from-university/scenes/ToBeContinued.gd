extends Control

@onready var art  : TextureRect = $Art
@onready var fade : ColorRect   = $Fade

const END_IMAGE := "res://scenes/assets/img/to_be_continued.png"
@export var hold_seconds: float = 3.0   

func _ready() -> void:
	if ResourceLoader.exists(END_IMAGE):
		art.texture = load(END_IMAGE)
		art.visible = true
	else:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0,0,0,1)
		add_theme_stylebox_override("panel", sb)

	if fade:
		fade.modulate.a = 1.0
		var tw := get_tree().create_tween()
		tw.tween_property(fade, "modulate:a", 0.0, 0.35)
		await tw.finished

	await get_tree().create_timer(hold_seconds).timeout

	await _fade_out_and_quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fade_out_and_quit()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		_fade_out_and_quit()

func _fade_out_and_quit() -> void:
	if fade:
		var tw := get_tree().create_tween()
		tw.tween_property(fade, "modulate:a", 1.0, 0.25)
		await tw.finished
	get_tree().quit()
