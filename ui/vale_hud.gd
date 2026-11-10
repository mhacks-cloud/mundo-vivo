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
var help_panel: PanelContainer

func _ready() -> void:
	layer = 5
	title_font.font_names = PackedStringArray(["Georgia", "Liberation Serif", "DejaVu Serif"])
	ui_font.font_names = PackedStringArray(["Segoe UI", "Liberation Sans", "DejaVu Sans"])
	var canvas := Control.new()
	add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var identity := _panel(canvas, Control.PRESET_TOP_LEFT, Vector4(22, 20, 224, 81), 0.78)
	_label(identity, "M U N D O   V I V O", 10, GOLD)
	_label(identity, "Vale do Amieiro", 24, CREAM, true)
	var calendar := _panel(canvas, Control.PRESET_TOP_RIGHT, Vector4(-218, 20, -22, 98), 0.78)
	date = _label(calendar, "", 12, GOLD)
	time = _label(calendar, "", 23, CREAM, true)
	weather = _label(calendar, "", 12, SILVER)

	var footer := _panel(canvas, Control.PRESET_BOTTOM_LEFT, Vector4(22, -137, 392, -62), 0.82)
	help_panel = footer.get_parent()
	help_panel.hide()
	_label(footer, "WASD  Mover    ·    Q / R  Girar    ·    Roda  Zoom", 13, CREAM)
	_label(footer, "F5  Salvar    ·    F9  Carregar    ·    T  Avançar 3 h", 12, SILVER)
	_label(footer, "E  Interagir  ·  F6  Gráficos  ·  F7  Efeitos", 12, GOLD)
	var options := _panel(canvas, Control.PRESET_BOTTOM_LEFT, Vector4(22, -54, 247, -20), 0.74)
	prefs = _label(options, "", 11, GOLD)
	var work := _panel(canvas, Control.PRESET_BOTTOM_RIGHT, Vector4(-248, -86, -22, -20), 0.78)
	_label(work, "P O N T E   N O V A", 10, GOLD)
	bridge = _label(work, "", 15, CREAM, true)
	fill = ProgressBar.new()
	fill.max_value = 8
	fill.show_percentage = false
	fill.custom_minimum_size.y = 4
	fill.add_theme_stylebox_override("background", _style(Color("4c4435"), Color.TRANSPARENT))
	fill.add_theme_stylebox_override("fill", _style(GOLD, Color.TRANSPARENT))
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	work.add_child(fill)

	var prompt_box := _panel(canvas, Control.PRESET_CENTER_BOTTOM, Vector4(-169, -67, 169, -25), 0.84)
	hint_panel = prompt_box.get_parent()
	hint = _label(prompt_box, "", 15, CREAM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_panel.hide()
	var message_box := _panel(canvas, Control.PRESET_CENTER_BOTTOM, Vector4(-270, -124, 270, -78), 0.86)
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
	prefs.text = "F1  Ajuda  ·  %s  ·  F10  HUD" % quality
	prefs.tooltip_text = "Efeitos ligados" if focus else "Efeitos desligados"

func toggle_help() -> void:
	help_panel.visible = not help_panel.visible
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
	panel_style.content_margin_top = 6
	panel_style.content_margin_right = 15
	panel_style.content_margin_bottom = 6
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
