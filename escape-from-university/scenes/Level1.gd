extends Control


@onready var bg: TextureRect              = get_node_or_null("Bg")
@onready var dim: ColorRect               = get_node_or_null("Dim")
@onready var hotspots: Control            = get_node_or_null("Hotspots")
@onready var door_btn: Button             = get_node_or_null("Hotspots/DoorBtn")
@onready var clock_btn: Button            = get_node_or_null("Hotspots/PosterBtn") 
@onready var desk_btn: Button             = get_node_or_null("Hotspots/DeskBtn")  
@onready var note_btn: Button             = get_node_or_null("Hotspots/NoteBtn")   

@onready var modal_blocker: ColorRect     = get_node_or_null("ModalBlocker")
@onready var keypad_panel: PanelContainer = get_node_or_null("KeypadPanel")
@onready var code_lbl: Label              = get_node_or_null("KeypadPanel/VBox/CodeBox/CodeLbl")
@onready var keypad_grid: GridContainer   = get_node_or_null("KeypadPanel/VBox/Grid")
@onready var keypad_close: Button         = get_node_or_null("KeypadPanel/VBox/CloseBtn")

@onready var hint_panel: PanelContainer   = get_node_or_null("HintPanel")
@onready var hint_lbl: RichTextLabel      = get_node_or_null("HintPanel/VBox/HintLbl")
@onready var hint_close: Button           = get_node_or_null("HintPanel/VBox/CloseHint")

@onready var toast: Label                 = get_node_or_null("Toast")
@onready var fade: ColorRect              = get_node_or_null("Fade")

# ---------- Gameplay ----------
const BG_IMAGE     := "res://scenes/assets/img/withclock.png"
const NEXT_SCENE   := "res://scenes/ToBeContinued.tscn"
const CORRECT_CODE := "0237"
const CODE_LEN     := 4

var door_unlocked := false
var current_code := ""

var saw_clock := false
var door_examined_once := false

var debug_visible := false

func _ready() -> void:
	_setup_layout_and_bg()
	_place_hotspots_for_class_image()
	_style_hotspots_debug(debug_visible)
	_setup_keypad()
	_setup_hint()
	_setup_toast()
	_connect_signals()
	_fade_in()
	set_process_unhandled_input(true)


func _setup_layout_and_bg() -> void:
	# Bg
	if bg:
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if ResourceLoader.exists(BG_IMAGE):
			bg.visible = true
			bg.texture = load(BG_IMAGE)
		else:
			bg.visible = false

	# Dim
	if dim:
		var dim_alpha := 0.10
		if not (bg and bg.visible):
			dim_alpha = 0.05
		dim.color = Color(0,0,0, dim_alpha)
		dim.mouse_filter = MOUSE_FILTER_IGNORE

	# Hotspots layer
	if hotspots:
		hotspots.mouse_filter = MOUSE_FILTER_PASS

	# Fade
	if fade:
		fade.modulate.a = 0.0
		fade.mouse_filter = MOUSE_FILTER_IGNORE

	# Modal blocker
	if modal_blocker:
		modal_blocker.color = Color(0,0,0,0.5)
		modal_blocker.visible = false
		modal_blocker.mouse_filter = MOUSE_FILTER_STOP

	# Keypad
	if keypad_panel:
		keypad_panel.visible = false
		keypad_panel.custom_minimum_size = Vector2(420, 520)

	# Hint panel
	if hint_panel:
		hint_panel.visible = false
		hint_panel.offset_left = 64
		hint_panel.offset_right = -64
		hint_panel.offset_bottom = -32

	
	if desk_btn:
		desk_btn.visible = false
		desk_btn.mouse_filter = MOUSE_FILTER_IGNORE
	if note_btn:
		note_btn.visible = false
		note_btn.mouse_filter = MOUSE_FILTER_IGNORE

# ============== RELATIVE HOTSPOTS ==============
func _set_hotspot_rect(node: Control, x: float, y: float, w: float, h: float) -> void:
	if node == null:
		return
	node.anchor_left   = clamp(x, 0.0, 1.0)
	node.anchor_top    = clamp(y, 0.0, 1.0)
	node.anchor_right  = clamp(x + w, 0.0, 1.0)
	node.anchor_bottom = clamp(y + h, 0.0, 1.0)
	node.offset_left   = 0
	node.offset_top    = 0
	node.offset_right  = 0
	node.offset_bottom = 0

func _place_hotspots_for_class_image() -> void:
	
	_set_hotspot_rect(door_btn,  0.310, 0.385, 0.090, 0.28)
	_set_hotspot_rect(clock_btn, 0.950, 0.320, 0.080, 0.145)
	

# ============== DEBUG STYLES ==============
func _style_hotspots_debug(show: bool) -> void:
	var base_alpha := 0.18
	if not show:
		base_alpha = 0.0
	for btn in [door_btn, clock_btn]:
		if btn == null:
			continue
		if show:
			btn.text = btn.name.replace("Btn","")
		else:
			btn.text = ""
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.modulate = Color(1,1,1, base_alpha)

# ============== KEYPAD =================
func _setup_keypad() -> void:
	if keypad_panel == null:
		return

	# Title
	var title := keypad_panel.get_node_or_null("VBox/Title") as Label
	if title:
		title.text = "قفل عددی"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Code label
	if code_lbl:
		code_lbl.text = "— — — —"
		code_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		code_lbl.add_theme_font_size_override("font_size", 24)

	# Grid buttons
	if keypad_grid and keypad_grid.get_child_count() == 0:
		keypad_grid.columns = 3
		var buttons := [
			"1","2","3",
			"4","5","6",
			"7","8","9",
			"پاک","0","تایید",
		]
		for t in buttons:
			var b := Button.new()
			b.text = t
			b.custom_minimum_size = Vector2(100, 64)
			b.pressed.connect(func(): _on_keypad_button(t))
			keypad_grid.add_child(b)

	# Close
	if keypad_close:
		var vbox := keypad_panel.get_node_or_null("VBox") as VBoxContainer
		if vbox:
			vbox.move_child(keypad_close, 0) # بیارش اولین بچه
		keypad_close.text = "✕"
		keypad_close.flat = true
		keypad_close.custom_minimum_size = Vector2(36, 36)
		keypad_close.size_flags_horizontal = Control.SIZE_SHRINK_END
		keypad_close.pressed.connect(func():
			_close_keypad()
		)

func _close_keypad() -> void:
	if keypad_panel:
		keypad_panel.visible = false
	if modal_blocker:
		modal_blocker.visible = false

# ============== HINT / TOAST =================
func _setup_hint() -> void:
	if hint_lbl:
		hint_lbl.bbcode_enabled = true
		hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		hint_lbl.text = "[b]سرنخ:[/b] شاید ساعت چیز مهمی بگه…"
	if hint_close:
		hint_close.pressed.connect(func():
			if hint_panel:
				hint_panel.visible = false
		)

func _setup_toast() -> void:
	if toast:
		toast.visible = false
		toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		toast.text_direction = TEXT_DIRECTION_RTL
		toast.add_theme_font_size_override("font_size", 22)
		toast.modulate.a = 0.0

# ============== SIGNALS / FX =================
func _connect_signals() -> void:
	if door_btn:
		door_btn.pressed.connect(_on_door_pressed)
	if clock_btn:
		clock_btn.pressed.connect(_on_clock_pressed)

func _fade_in() -> void:
	if fade == null:
		return
	var tw := get_tree().create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, 0.35)

# ============== INPUT: toggle debug with H ==============
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			debug_visible = not debug_visible
			_style_hotspots_debug(debug_visible)
			await _show_toast(("Debug ON (H)" if debug_visible else "Debug OFF (H)"), 1.0)

# ================= GAMEPLAY =================
func _on_clock_pressed() -> void:
	await _say("از کی تا حالا تو کلاسا ساعت می‌ذارن؟", 1.6)
	await _say("اووه... ساعت 2:37 ـه — چرا انقدر دیره؟", 1.9)
	saw_clock = true

func _on_door_pressed() -> void:
	if door_unlocked:
		await _show_toast("در باز شد !", 1.2)
		_leave_room()
		return

	if not door_examined_once:
		door_examined_once = true
		await _say("عه؟ چرا رو در کیپد گذاشتن! قفله؟", 1.6)
		return

	if modal_blocker:
		modal_blocker.visible = true
	if keypad_panel:
		keypad_panel.visible = true
	if not saw_clock:
		await _show_toast("شاید ساعت یه چیزی میگه...", 1.4)

func _on_keypad_button(label: String) -> void:
	if label == "پاک":
		if current_code.length() > 0:
			current_code = current_code.substr(0, current_code.length()-1)
	elif label == "تایید":
		if current_code.length() == CODE_LEN:
			if current_code == CORRECT_CODE:
				door_unlocked = true
				if keypad_panel:
					keypad_panel.visible = false
				if modal_blocker:
					modal_blocker.visible = false
				await _show_toast("تق! قفل باز شد.", 1.2)
			else:
				await _show_toast("کد اشتباهه!", 1.2)
				current_code = ""
	else:
		if current_code.length() < CODE_LEN and label.is_valid_int():
			current_code += label
	_update_code_label()

func _update_code_label() -> void:
	if code_lbl == null:
		return
	if current_code.length() == 0:
		code_lbl.text = "— — — —"
	else:
		var out := PackedStringArray()
		for i in range(CODE_LEN):
			if i < current_code.length():
				out.append(str(current_code[i]))
			else:
				out.append("—")
		code_lbl.text = " ".join(out)

# ---- subtitle/toast helpers
func _say(msg: String, dur: float) -> void:
	await _show_toast(msg, dur)

func _show_toast(msg: String, dur: float = 1.5) -> void:
	if toast == null:
		return
	toast.text = msg
	toast.visible = true
	var tw := get_tree().create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.12)
	tw.tween_interval(dur)
	tw.tween_property(toast, "modulate:a", 0.0, 0.18)
	await tw.finished
	toast.visible = false

func _leave_room() -> void:
	if fade:
		var tw := get_tree().create_tween()
		tw.tween_property(fade, "modulate:a", 1.0, 0.25)
		await tw.finished
	if NEXT_SCENE != "" and ResourceLoader.exists(NEXT_SCENE):
		get_tree().change_scene_to_file(NEXT_SCENE)
	else:
		OS.alert("صحنهٔ بعدی (راهرو) هنوز تنظیم نشده.", "Level1")
