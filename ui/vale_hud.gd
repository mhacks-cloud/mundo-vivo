class_name ValeHUD
extends CanvasLayer

const CREAM := Color("f1e6cc")
const GOLD := Color("e2b66f")
const SILVER := Color("c3cbb6")
var title_font := SystemFont.new()
var ui_font := SystemFont.new()
var date: Label
var time: Label
var weather: Label
var bridge: Label
var hint: Label
var toast_label: Label
var prefs: Label
var fill: ProgressBar
var toast_panel: PanelContainer
var hint_panel: PanelContainer
var toast_time := 0.0

func _ready() -> void:
	layer = 5
	title_font.font_names = PackedStringArray(["Georgia", "Liberation Serif", "DejaVu Serif"])
	ui_font.font_names = PackedStringArray(["Segoe UI", "Liberation Sans", "DejaVu Sans"])
	var canvas := Control.new()
	add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var identity := _panel(canvas, Control.PRESET_TOP_LEFT, Vector4(26, 24, 322, 136), 0.92)
	_label(identity, "M U N D O   V I V O    /    0 1", 12, GOLD)
	_label(identity, "Vale do Amieiro", 34, CREAM, true)
	_label(identity, "VILA DO RIO  ·  CRÔNICAS DO VALE", 10, SILVER)
	var calendar := _panel(canvas, Control.PRESET_TOP_RIGHT, Vector4(-260, 24, -26, 140), 0.92)
	date = _label(calendar, "", 12, GOLD)
	time = _label(calendar, "", 30, CREAM, true)
	weather = _label(calendar, "", 12, SILVER)

	var footer := _panel(canvas, Control.PRESET_BOTTOM_LEFT, Vector4(26, -114, 479, -24), 0.89)
	_label(footer, "WASD  Mover    ·    Q / R  Girar    ·    Roda  Zoom", 13, CREAM)
	_label(footer, "F5  Salvar    ·    F9  Carregar    ·    T  Avançar 3 h", 12, SILVER)
	prefs = _label(footer, "", 11, GOLD)
	var work := _panel(canvas, Control.PRESET_BOTTOM_RIGHT, Vector4(-316, -114, -26, -24), 0.90)
	_label(work, "O B R A   P Ú B L I C A   /   P O N T E   N O V A", 10, GOLD)
	bridge = _label(work, "", 15, CREAM, true)
	fill = ProgressBar.new()
	fill.max_value = 8
	fill.show_percentage = false
	fill.custom_minimum_size.y = 4
	fill.add_theme_stylebox_override("background", _style(Color("4c4435"), Color.TRANSPARENT))
	fill.add_theme_stylebox_override("fill", _style(GOLD, Color.TRANSPARENT))
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	work.add_child(fill)

	var prompt_box := _panel(canvas, Control.PRESET_CENTER_BOTTOM, Vector4(-190, -176, 190, -130), 0.94)
	hint_panel = prompt_box.get_parent()
	hint = _label(prompt_box, "", 15, CREAM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_panel.hide()
	var message_box := _panel(canvas, Control.PRESET_CENTER_BOTTOM, Vector4(-300, -228, 300, -188), 0.96)
	toast_panel = message_box.get_parent()
	toast_label = _label(message_box, "", 15, CREAM, true)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_panel.hide()

func update_clock(clock: WorldClock, season: String, sample: Dictionary) -> void:
	date.text = "%s  /  DIA %02d  /  ANO %d" % [season.to_upper(), clock.day_of_year(), clock.year()]
	time.text = clock.time_text()
	weather.text = "%s   ·   %d °C" % [sample.weather, roundi(sample.temperature)]

func update_bridge(construction: ConstructionManager) -> void:
	bridge.text = construction.status()
	fill.value = [0, 2, 5, 8][construction.stage] + construction.delivered

func update_options(quality: String, focus: bool) -> void:
	prefs.text = "F6  Gráficos %s    ·    F7  Desfoque %s    ·    E  Interagir" % [
		quality, "ligado" if focus else "desligado"]

func prompt(value: String) -> void:
	hint_panel.visible = not value.is_empty()
	hint.text = "E    ·    " + value

func show_message(value: String, duration := 4.7) -> void:
	toast_label.text = value
	toast_panel.show()
	toast_time = duration

func _process(delta: float) -> void:
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0:
			toast_panel.hide()

func _panel(canvas: Control, preset: int, offsets: Vector4, opacity: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	canvas.add_child(panel)
	panel.set_anchors_and_offsets_preset(preset)
	panel.offset_left = offsets.x
	panel.offset_top = offsets.y
	panel.offset_right = offsets.z
	panel.offset_bottom = offsets.w
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := _style(Color(0.073, 0.086, 0.070, opacity), Color("8f7953"))
	panel_style.content_margin_left = 15
	panel_style.content_margin_top = 10
	panel_style.content_margin_right = 15
	panel_style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(stack)
	return stack

func _label(parent: Control, value: String, size: int, color: Color, serif := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_override("font", title_font if serif else ui_font)
	parent.add_child(label)
	return label

func _style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	style.set_border_width_all(1)
	style.border_color = border
	return style
