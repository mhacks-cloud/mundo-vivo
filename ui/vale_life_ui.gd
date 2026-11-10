class_name ValeLifeUI
extends CanvasLayer

const CREAM := Color("f1e6cc")
const GOLD := Color("e2b66f")
const SILVER := Color("c3cbb6")
var service: Node
var panel: PanelContainer
var body: VBoxContainer
var title: Label
var subtitle: Label
var status: Label
var feedback: Label
var form_name: LineEdit
var form_class: OptionButton
var form_nation: OptionButton
var form_plot: OptionButton
var form_coat: OptionButton
var form_hair: OptionButton
var form_preview: TextureRect
var form_desc: Label
var confirm_button: Button
var page := ""
var selected := ""
var initial_plot := "sul-01"
var banner: PanelContainer
var banner_text: Label
var font := SystemFont.new()

func setup(controller: Node) -> void:
	service = controller
	layer = 6
	font.font_names = PackedStringArray(["Georgia", "Liberation Serif", "DejaVu Serif"])
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	root.add_child(panel)
	panel.add_theme_stylebox_override("panel", _frame(Color("aa8955"), Color("1b211b")))
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	panel.add_child(section)
	subtitle = _label(section, "", 11, GOLD)
	var heading := HBoxContainer.new()
	section.add_child(heading)
	title = _label(heading, "", 27, CREAM, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := _button(heading, "×", hide_panel)
	close.name = "Close"
	var divider := HSeparator.new()
	section.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	section.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	scroll.add_child(body)
	feedback = _label(section, "", 12, GOLD)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.hide()
	banner = PanelContainer.new()
	root.add_child(banner)
	banner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	banner.offset_left = 22
	banner.offset_right = 435
	banner.offset_top = -112
	banner.offset_bottom = -64
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_stylebox_override("panel", _frame(Color("816640"), Color(0.09, 0.12, 0.085, 0.91)))
	banner_text = _label(banner, "", 12, CREAM)
	banner_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.hide()
	var vitals := PanelContainer.new()
	root.add_child(vitals)
	vitals.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	vitals.offset_left = 22
	vitals.offset_right = 224
	vitals.offset_top = 90
	vitals.offset_bottom = 122
	vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals.add_theme_stylebox_override("panel", _frame(Color("816640"), Color(0.09, 0.12, 0.085, 0.86)))
	status = _label(vitals, "", 12, CREAM)
	vitals.hide()

func update_status() -> void:
	var life: PlayerLife = service.life
	status.get_parent().visible = not life.profile.is_empty() and service.setup_stage.is_empty()
	status.text = "%d PV  ·  %d mana  ·  %d ouro" % [ceili(life.hp), ceili(life.mana), life.gold]

func creator() -> void:
	_reset("creator", "M U N D O  V I V O   /   0 4", "Sua vida começa aqui", true)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 18)
	body.add_child(split)
	var preview_side := VBoxContainer.new()
	split.add_child(preview_side)
	form_preview = TextureRect.new()
	form_preview.custom_minimum_size = Vector2(144, 178)
	form_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	form_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	form_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_side.add_child(form_preview)
	_label(preview_side, "Traje de viajante", 12, GOLD)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 6)
	split.add_child(form)
	_label(form, "Nome do personagem", 12, SILVER)
	form_name = LineEdit.new()
	form_name.max_length = 22
	form_name.placeholder_text = "Ex. Elian do Vale"
	form.add_child(form_name)
	_label(form, "Classe permanente", 12, SILVER)
	form_class = _select(form, LifeCatalog.CLASSES.keys(), func(id: String) -> String: return LifeCatalog.CLASSES[id].name)
	_label(form, "Nação inicial", 12, SILVER)
	form_nation = _select(form, LifeCatalog.NATIONS.keys(), func(id: String) -> String: return LifeCatalog.NATIONS[id].name)
	for i in form_nation.item_count:
		var id: String = form_nation.get_item_metadata(i)
		form_nation.set_item_disabled(i, not LifeCatalog.NATIONS[id].playable)
		if not LifeCatalog.NATIONS[id].playable:
			form_nation.set_item_text(i, LifeCatalog.NATIONS[id].name + " · futura")
	_label(form, "Cor do traje e cabelo", 12, SILVER)
	var colors := HBoxContainer.new()
	form.add_child(colors)
	form_coat = _select(colors, ["Azul do rio", "Vinho", "Verde folha", "Ameixa", "Ocre"], func(id: String) -> String: return id)
	form_hair = _select(colors, ["Louro", "Castanho", "Escuro", "Grisalho"], func(id: String) -> String: return id)
	form_desc = _label(body, "", 13, SILVER)
	form_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form_class.item_selected.connect(func(_index: int) -> void: _creator_preview())
	form_coat.item_selected.connect(func(_index: int) -> void: _creator_preview())
	form_hair.item_selected.connect(func(_index: int) -> void: _creator_preview())
	confirm_button = _button(body, "Confirmar personagem e escolher terreno", func() -> void:
		feedback.text = service.confirm_character(form_name.text, _selected(form_class), _selected(form_nation), form_coat.selected, form_hair.selected))
	_creator_preview()

func _creator_preview() -> void:
	form_desc.text = LifeCatalog.CLASSES[_selected(form_class)].summary
	form_preview.texture = service.preview_actor(form_coat.selected, form_hair.selected)

func plots() -> void:
	_reset("plots", "C A R T Ó R I O   /   C O R O A   D O   A M I E I R O", "Seu primeiro terreno", false)
	_body_text("Compare os lotes e veja a localização pela câmera. Cada terreno mede 7,5 × 7,5 m.")
	var chooser := _select(body, Homestead.PLOTS.keys(), func(id: String) -> String: return "%s  ·  %d ouro" % [Homestead.PLOTS[id].name, Homestead.PLOTS[id].price])
	form_plot = chooser
	var index := Homestead.PLOTS.keys().find(initial_plot)
	chooser.select(maxi(0, index))
	chooser.item_selected.connect(func(_index: int) -> void:
		initial_plot = _selected(chooser)
		service.show_plot(initial_plot))
	_body_text("Saldo inicial: %d ouro. O lote escolhido ficará registrado em seu nome." % service.life.gold)
	confirm_button = _button(body, "Adquirir terreno e entrar na vila", func() -> void:
		feedback.text = service.confirm_plot(_selected(chooser)))
	service.show_plot(_selected(chooser))

func open(next_page: String) -> void:
	var life: PlayerLife = service.life
	if life.profile.is_empty():
		return
	match next_page:
		"character":
			_reset(next_page, "C A R T A   D E   C I D A D A N I A", life.profile.name)
			var nation: Dictionary = LifeCatalog.NATIONS[life.profile.nation]
			var role: Dictionary = LifeCatalog.CLASSES[life.role()]
			_body_text("%s · nível %d · %d XP\n%s · %s\nTesouro %d ouro · imposto %d%% · reputação %d" % [
				role.name, life.level(), life.xp, nation.name, nation.king, life.treasury, int(nation.tax * 100), life.reputation])
			_body_text(role.skill + "\n" + role.summary)
			var land := life.estate.owned(PlayerLife.ID)
			_body_text("Terreno · " + Homestead.PLOTS[land].name if not land.is_empty() else "Sem terreno registrado.")
			_button(body, "Ver equipamentos", func() -> void: open("equipment"))
			_button(body, "Registros pessoais", func() -> void: open("ledger"))
		"inventory", "equipment", "chest":
			_reset(next_page, "B O L S A   /   E Q U I P A M E N T O", "Baú do terreno" if next_page == "chest" else "Equipamentos" if next_page == "equipment" else "Inventário")
			_inventory(next_page)
		"build":
			_reset(next_page, "T E R R E N O   /   O F I C I N A", "Construir e decorar")
			_body_text("Escolha uma peça. Aponte para uma célula. Z gira, clique esquerdo confirma e Esc cancela.")
			for id in Homestead.PIECES:
				var item: String = id
				var piece: Dictionary = Homestead.PIECES[id]
				_button(body, piece.name + " · " + _cost(piece.cost), func() -> void: service.start_build(item))
			_action("Montar casa inicial · 20 madeira / 4 pedra", "starter", "")
			_button(body, "Abrir baú do terreno", func() -> void: service.open_near("chest"))
			if life.role() == "farmer":
				_button(body, "Cuidar dos canteiros", func() -> void: service.open_near("farm"))
		"farm":
			_reset(next_page, "L A V O U R A   P A R T I C U L A R", "Canteiros")
			_body_text("Instale um canteiro pelo menu H. Regue após plantar ou aguarde chuva.")
			for part in life.estate.pieces:
				if part.kind != "garden":
					continue
				var key := "%d:%d" % [part.cell.x, part.cell.y]
				var bed: Dictionary = life.plants.get(key, {})
				_body_text("Canteiro " + key + (" · vazio" if bed.is_empty() else " · " + LifeCatalog.label(bed.crop) + (" · regado" if bed.wet else " · seco")))
				if bed.is_empty():
					_action("Plantar trigo", "plant", key + ":seed")
					_action("Plantar erva medicinal", "plant", key + ":herb_seed")
				else:
					_action("Regar", "plant", key + ":water")
					_action("Colher", "plant", key + ":harvest")
		"store":
			_reset(next_page, "M E R C A D O   R E G I O N A L", "Banca de Lina")
			_body_text("07:00–19:00 · Saldo %d ouro. As compras usam estoque finito. Vendas de trigo abastecem a vila." % life.gold)
			var items := []
			for id in LifeCatalog.GOODS:
				if int(life.stock.get(id, 0)) > 0 or life.bag.amount(id) > 0:
					items.append(id)
			var picker := _pick(items, func(id: String) -> String: return "%s · %d ouro · banca %d / bolsa %d" % [
				LifeCatalog.label(id), LifeCatalog.GOODS[id][4], life.stock.get(id, 0), life.bag.amount(id)])
			_button(body, "Comprar 1", func() -> void: _perform("buy", _selected(picker)))
			_button(body, "Vender 1", func() -> void: _perform("sell", _selected(picker)))
		"forge", "alchemy", "carpentry":
			_reset(next_page, "O F Í C I O   /   N Í V E L   %d" % life.level(), {"forge": "Forja", "alchemy": "Alquimia", "carpentry": "Marcenaria"}[next_page])
			var count := 0
			for id in LifeCatalog.RECIPES:
				var recipe: Dictionary = LifeCatalog.RECIPES[id]
				if recipe.station == next_page and recipe["class"] == life.role():
					count += 1
					_action("%s ×%d · %s · nv. %d" % [LifeCatalog.label(id), recipe.qty, _cost(recipe.cost), recipe.level], "craft", id)
			if count == 0:
				_body_text("As receitas desta bancada pertencem à profissão responsável.")
			if next_page == "forge":
				_body_text("Reparo na forja. Serviço: 6 ouro. Ferreiros também podem usar 1 ferro.")
				for id in life.bag.items:
					if LifeCatalog.max_durability(id) > 0:
						_action("Reparar " + LifeCatalog.label(id), "repair", id)
						if life.role() == "smith":
							_action("Reparar por ofício · " + LifeCatalog.label(id), "self_repair", id)
		"contracts":
			_reset(next_page, "A V I S O S   D O   V A L E", "Contratos")
			_body_text("Leve as entregas ao quadro público da praça.")
			for id in PlayerLife.CONTRACTS:
				var job: Dictionary = PlayerLife.CONTRACTS[id]
				if id in life.completed:
					_body_text("Concluído · " + job.title)
				else:
					_action("%s · %d ouro · %s ×%d" % [job.title, job.pay, LifeCatalog.label(job.item), job.qty], "contract", id)
		"ledger":
			_reset(next_page, "L I V R O   D E   C O N T A S", "Registros pessoais")
			for i in range(life.journal.size() - 1, -1, -1):
				_body_text(life.journal[i])

func _inventory(next_page: String) -> void:
	var life: PlayerLife = service.life
	_body_text("Peso %.1f / %.0f kg · Ouro %d" % [life.bag.weight(), life.bag.capacity, life.gold])
	if next_page == "equipment":
		for slot in ["weapon", "armor", "tool", "accessory"]:
			var id: String = life.equipment.get(slot, "")
			var label: String = {"weapon": "Arma", "armor": "Armadura", "tool": "Ferramenta", "accessory": "Acessório"}[slot]
			_body_text(label + " · " + ("vazio" if id.is_empty() else "%s (%d/%d)" % [LifeCatalog.label(id), life.bag.condition.get(id, 0), LifeCatalog.max_durability(id)]))
	var items := life.bag.items.keys()
	if next_page == "chest":
		_body_text("Baú %.1f / %.0f kg" % [life.chest.weight(), life.chest.capacity])
		for id in life.chest.items:
			if id not in items:
				items.append(id)
	var picker := _pick(items, func(id: String) -> String: return "%s · bolsa %d%s" % [LifeCatalog.label(id),
		life.bag.amount(id), " / baú %d" % life.chest.amount(id) if next_page == "chest" else ""])
	if items.is_empty():
		return
	var detail := _body_text("")
	var describe := func() -> void:
		var id := _selected(picker)
		var meta: Array = LifeCatalog.GOODS[id]
		var extra := ""
		if LifeCatalog.max_durability(id) > 0:
			extra = "\nDurabilidade %d/%d · " % [life.bag.condition.get(id, life.chest.condition.get(id, 0)), LifeCatalog.max_durability(id)]
			var roles := PackedStringArray()
			for role_id in meta[7]:
				roles.append(LifeCatalog.CLASSES[role_id].name)
			extra += ", ".join(roles)
		detail.text = "%s · %s · %.2f kg · valor %d%s" % [meta[1], LifeCatalog.RARITIES[meta[3]], meta[2], meta[4], extra]
	describe.call()
	picker.item_selected.connect(func(_index: int) -> void: describe.call())
	if next_page == "chest":
		_button(body, "Guardar 1 no baú", func() -> void: _perform("store", _selected(picker)))
		_button(body, "Retirar 1 do baú", func() -> void: _perform("take", _selected(picker)))
	else:
		_button(body, "Usar ou equipar", func() -> void: _perform("use", _selected(picker)))
		_button(body, "Desequipar", func() -> void: _perform("unequip", _selected(picker)))
		_button(body, "Descartar 1", func() -> void: _perform("discard", _selected(picker)))

func build_hint(text_value: String) -> void:
	banner.visible = not text_value.is_empty()
	banner_text.text = text_value

func hide_panel() -> void:
	if not service.setup_stage.is_empty():
		return
	panel.hide()
	page = ""

func _reset(next_page: String, kicker: String, headline: String, centered := false) -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	page = next_page
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER if centered else Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -310 if centered else -418
	panel.offset_right = 310 if centered else -22
	panel.offset_top = -235 if centered else -151 if next_page == "plots" else -248
	panel.offset_bottom = 237 if centered else 153 if next_page == "plots" else 243
	title.text = headline
	subtitle.text = kicker
	feedback.text = ""
	title.get_parent().get_node("Close").visible = service.setup_stage.is_empty()
	panel.show()

func _selected(choice: OptionButton) -> String:
	return String(choice.get_item_metadata(choice.selected)) if choice.selected >= 0 else ""

func _select(parent: Control, values: Array, format: Callable) -> OptionButton:
	var choice := OptionButton.new()
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice.custom_minimum_size.y = 32
	for value in values:
		choice.add_item(format.call(value))
		choice.set_item_metadata(choice.item_count - 1, value)
	parent.add_child(choice)
	return choice

func _pick(values: Array, format: Callable) -> OptionButton:
	var picker := _select(body, values, format)
	var index := values.find(selected)
	if index >= 0:
		picker.select(index)
	picker.item_selected.connect(func(_index: int) -> void: selected = _selected(picker))
	return picker

func _body_text(text_value: String) -> Label:
	var label := _label(body, text_value, 13, SILVER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _action(label: String, verb: String, id: String) -> void:
	_button(body, label, func() -> void: _perform(verb, id))

func _perform(verb: String, id: String) -> void:
	var current := page
	var result: String = service.perform(verb, id)
	if not current.is_empty() and service.build_kind.is_empty():
		open(current)
		feedback.text = result

func _cost(cost: Dictionary) -> String:
	var values := PackedStringArray()
	for id in cost:
		values.append("%d %s" % [cost[id], LifeCatalog.label(id).to_lower()])
	return ", ".join(values)

func _label(parent: Control, value: String, size: int, color: Color, serif := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if serif:
		label.add_theme_font_override("font", font)
	parent.add_child(label)
	return label

func _button(parent: Control, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 32
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _frame(Color("61553d"), Color("2a3024"), 7, 4))
	button.add_theme_stylebox_override("hover", _frame(GOLD, Color("3e3e2b"), 7, 4))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _frame(border: Color, color: Color, margin := 13, vertical := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = vertical
	style.content_margin_bottom = vertical
	return style
