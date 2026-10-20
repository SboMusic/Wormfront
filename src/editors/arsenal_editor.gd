# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends Node2D

signal apply_requested(weapons: Array[Dictionary], rules: Dictionary)
signal close_requested

const WeaponCatalog = preload("res://src/data/weapon_catalog.gd")
const ArsenalData = preload("res://src/data/arsenal_data.gd")
const WeaponPreview = preload("res://src/ui/weapon_preview.gd")
var editing := false
var initialized := false
var draft_weapons: Array[Dictionary] = []
var draft_rules: Dictionary = {}
var selected := 0
var syncing := false
var layer: CanvasLayer
var tabs: TabContainer
var selector: OptionButton
var name_field: LineEdit
var trigger_field: OptionButton
var color_field: ColorPickerButton
var fields: Dictionary = {}
var health_field: SpinBox
var turn_field: SpinBox
var team_size_field: SpinBox
var self_damage_field: CheckBox
var preview := WeaponPreview.new()
var distance_slider: HSlider
var behavior_label: Label
var message: Label
var save_dialog: FileDialog
var load_dialog: FileDialog
var apply_button: Button
var close_button: Button
var defaults_button: Button

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var panel := Panel.new()
	panel.position = Vector2(16, 12)
	panel.size = Vector2(1068, 676)
	layer.add_child(panel)
	var title := Label.new()
	title.position = Vector2(18, 10)
	title.text = "EDITOR ARMI E REGOLE"
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)
	var note := Label.new()
	note.position = Vector2(18, 48)
	note.text = "Modifica la bozza. Applica avvia una nuova partita sulla mappa selezionata."
	note.add_theme_font_size_override("font_size", 15)
	panel.add_child(note)
	tabs = TabContainer.new()
	tabs.position = Vector2(18, 80)
	tabs.size = Vector2(1032, 498)
	panel.add_child(tabs)
	build_weapons_tab()
	build_rules_tab()
	var actions := HBoxContainer.new()
	actions.position = Vector2(18, 594)
	panel.add_child(actions)
	apply_button = add_button(actions, "Applica e nuova partita", apply_draft)
	add_button(actions, "Salva…", open_save)
	add_button(actions, "Carica…", open_load)
	defaults_button = add_button(actions, "Valori base", restore_defaults)
	close_button = add_button(actions, "Riprendi partita [Esc]", close_editor)
	message = Label.new()
	message.position = Vector2(18, 634)
	message.size = Vector2(1032, 28)
	message.clip_text = true
	message.add_theme_font_size_override("font_size", 15)
	panel.add_child(message)
	DirAccess.make_dir_recursive_absolute("user://arsenals")
	save_dialog = make_dialog(FileDialog.FILE_MODE_SAVE_FILE)
	save_dialog.file_selected.connect(save_to)
	load_dialog = make_dialog(FileDialog.FILE_MODE_OPEN_FILE)
	load_dialog.file_selected.connect(load_from)
	set_editing(false)

func add_button(parent: Node, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func add_field(grid: GridContainer, title: String, control: Control) -> void:
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 205
	grid.add_child(label)
	control.custom_minimum_size.x = 215
	grid.add_child(control)

func spin(low: float, high: float, step: float, suffix: String) -> SpinBox:
	var control := SpinBox.new()
	control.min_value = low
	control.max_value = high
	control.step = step
	control.suffix = suffix
	control.get_line_edit().focus_exited.connect(control.apply)
	return control

func build_weapons_tab() -> void:
	var page := Control.new()
	page.name = "Armi"
	tabs.add_child(page)
	var column := VBoxContainer.new()
	column.position = Vector2(14, 12)
	column.size = Vector2(450, 430)
	page.add_child(column)
	selector = OptionButton.new()
	selector.add_item("1 — Lanciaproiettili")
	selector.add_item("2 — Granata")
	selector.item_selected.connect(switch_weapon)
	column.add_child(selector)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("v_separation", 3)
	column.add_child(grid)
	name_field = LineEdit.new()
	name_field.max_length = 24
	name_field.text_changed.connect(func(_text: String): update_draft())
	add_field(grid, "Nome", name_field)
	trigger_field = OptionButton.new()
	trigger_field.add_item("All'impatto")
	trigger_field.add_item("A tempo, con rimbalzi")
	trigger_field.item_selected.connect(func(_index: int): update_draft())
	add_field(grid, "Esplosione", trigger_field)
	for spec in [
		["damage", "Danno massimo", 1, 100, 1, "PV"],
		["crater_radius", "Raggio del cratere", 8, 120, 1, "px"],
		["damage_radius", "Raggio del danno", 16, 180, 1, "px"],
		["impulse", "Spinta", 0, 500, 10, ""],
		["gravity_scale", "Gravità del proiettile", 0.25, 2.0, 0.05, "×"],
		["fuse", "Miccia (armi a tempo)", 1, 6, 0.1, "s"],
		["bounce", "Rimbalzo (armi a tempo)", 0, 85, 1, "%"]
	]:
		var control := spin(float(spec[2]), float(spec[3]), float(spec[4]), String(spec[5]))
		fields[spec[0]] = control
		control.value_changed.connect(func(_value: float): update_draft())
		add_field(grid, String(spec[1]), control)
	color_field = ColorPickerButton.new()
	color_field.edit_alpha = false
	color_field.edit_intensity = false
	color_field.color_changed.connect(func(_color: Color): update_draft())
	add_field(grid, "Colore", color_field)
	preview.position = Vector2(530, 8)
	preview.size = Vector2(440, 398)
	page.add_child(preview)
	distance_slider = HSlider.new()
	distance_slider.position = Vector2(545, 410)
	distance_slider.size = Vector2(400, 22)
	distance_slider.min_value = 0
	distance_slider.max_value = 180
	distance_slider.step = 1
	distance_slider.value = 65
	distance_slider.value_changed.connect(func(_value: float): refresh_preview())
	page.add_child(distance_slider)
	behavior_label = Label.new()
	behavior_label.position = Vector2(545, 439)
	behavior_label.add_theme_font_size_override("font_size", 14)
	page.add_child(behavior_label)

func build_rules_tab() -> void:
	var page := Control.new()
	page.name = "Regole partita"
	tabs.add_child(page)
	var column := VBoxContainer.new()
	column.position = Vector2(24, 24)
	column.size = Vector2(970, 420)
	column.add_theme_constant_override("separation", 20)
	page.add_child(column)
	var intro := Label.new()
	intro.text = "Regole condivise dalle due squadre"
	intro.add_theme_font_size_override("font_size", 22)
	column.add_child(intro)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("v_separation", 18)
	column.add_child(grid)
	health_field = spin(1, 300, 1, "PV")
	health_field.value_changed.connect(func(_value: float): update_rules())
	add_field(grid, "Vita iniziale", health_field)
	turn_field = spin(10, 120, 1, "s")
	turn_field.value_changed.connect(func(_value: float): update_rules())
	add_field(grid, "Durata del turno", turn_field)
	team_size_field = spin(1, 4, 1, "")
	team_size_field.value_changed.connect(func(_value: float): update_rules())
	add_field(grid, "Personaggi per squadra", team_size_field)
	self_damage_field = CheckBox.new()
	self_damage_field.text = "Attivi"
	self_damage_field.toggled.connect(func(_enabled: bool): update_rules())
	add_field(grid, "Danni alla propria squadra", self_damage_field)
	var explanation := Label.new()
	explanation.text = "I turni alternano le squadre e i personaggi superstiti.\nLa spinta delle esplosioni rimane attiva anche senza danni agli alleati.\nOgni turno consente un colpo. Le prime due armi hanno munizioni infinite.\nLe modifiche entrano in gioco solo con Applica e nuova partita.\nSalva conserva armi e regole. IA e casse si impostano nel menu."
	explanation.add_theme_font_size_override("font_size", 17)
	column.add_child(explanation)

func make_dialog(mode: FileDialog.FileMode) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = mode
	dialog.title = "Salva armi e regole" if mode == FileDialog.FILE_MODE_SAVE_FILE else "Carica armi e regole"
	dialog.get_ok_button().text = "Salva" if mode == FileDialog.FILE_MODE_SAVE_FILE else "Carica"
	dialog.get_cancel_button().text = "Annulla"
	dialog.filters = PackedStringArray(["*.arsenale;Armi e regole Wormfront"])
	dialog.current_dir = ProjectSettings.globalize_path("user://arsenals")
	add_child(dialog)
	return dialog

func begin_edit(weapons: Array[Dictionary], rules: Dictionary) -> void:
	if not initialized:
		draft_weapons = WeaponCatalog.sanitize(weapons)
		draft_rules = ArsenalData.sanitize_rules(rules)
		initialized = true
	set_editing(true)
	sync_form()
	message.text = "Bozza in memoria. Salva per conservarla dopo la chiusura del gioco."

func set_editing(enabled: bool) -> void:
	editing = enabled
	visible = enabled
	layer.visible = enabled
	set_process_input(enabled)
	set_process_unhandled_input(enabled)
	queue_redraw()

func sync_form() -> void:
	syncing = true
	selected = clampi(selected, 0, draft_weapons.size() - 1)
	selector.clear()
	for i in range(draft_weapons.size()):
		selector.add_item("" )
		selector.set_item_text(i, "%d — %s" % [i + 1, draft_weapons[i]["name"]])
	var weapon: Dictionary = draft_weapons[selected]
	selector.select(selected)
	name_field.text = weapon["name"]
	trigger_field.select(1 if weapon["trigger"] == "fuse" else 0)
	for field in fields:
		var control: SpinBox = fields[field]
		control.value = float(weapon[field]) * (100.0 if field == "bounce" else 1.0)
	color_field.color = Color.html(String(weapon["color"]))
	health_field.value = draft_rules["starting_health"]
	turn_field.value = draft_rules["turn_seconds"]
	team_size_field.value = draft_rules["team_size"]
	self_damage_field.button_pressed = draft_rules["self_damage"]
	syncing = false
	refresh_preview()

func switch_weapon(index: int) -> void:
	# Conferma i numeri digitati anche se non è stato premuto Invio.
	commit_numbers()
	selected = index
	sync_form()

func commit_numbers() -> void:
	for control: SpinBox in fields.values():
		if control.get_line_edit().has_focus():
			control.apply()
	if health_field.get_line_edit().has_focus():
		health_field.apply()
	if turn_field.get_line_edit().has_focus():
		turn_field.apply()
	if team_size_field.get_line_edit().has_focus():
		team_size_field.apply()
	update_draft()
	update_rules()

func update_draft() -> void:
	if syncing or draft_weapons.is_empty():
		return
	var weapon: Dictionary = draft_weapons[selected]
	var name := name_field.text.strip_edges()
	weapon["name"] = name if not name.is_empty() else "Arma %d" % (selected + 1)
	weapon["trigger"] = "fuse" if trigger_field.selected == 1 else "impact"
	for field in fields:
		weapon[field] = float(fields[field].value) / (100.0 if field == "bounce" else 1.0)
	weapon["fuse"] = float(fields["fuse"].value) if weapon["trigger"] == "fuse" else 0.0
	weapon["color"] = color_field.color.to_html(false)
	selector.set_item_text(selected, "%d — %s" % [selected + 1, weapon["name"]])
	refresh_preview()

func update_rules() -> void:
	if syncing or draft_rules.is_empty():
		return
	draft_rules = ArsenalData.sanitize_rules({"scatter_spawns": draft_rules.get("scatter_spawns", false), "ai_level": draft_rules.get("ai_level", 1), "ai_enabled": draft_rules.get("ai_enabled", false), "supplies": draft_rules.get("supplies", true), "starting_health": health_field.value, "turn_seconds": turn_field.value, "self_damage": self_damage_field.button_pressed, "team_size": team_size_field.value})

func refresh_preview() -> void:
	if draft_weapons.is_empty():
		return
	var weapon: Dictionary = draft_weapons[selected]
	var timed: bool = weapon["trigger"] == "fuse"
	var instant: bool = weapon.get("kind", "projectile") in ["beam", "scatter"]
	trigger_field.disabled = instant
	fields["gravity_scale"].editable = not instant
	fields["fuse"].editable = timed
	fields["bounce"].editable = timed
	preview.set_weapon(weapon, distance_slider.value)
	behavior_label.text = "Esplode dopo %.1f s · rimbalzo %d%%" % [weapon["fuse"], roundi(float(weapon["bounce"]) * 100)] if timed else "Esplode al primo impatto."
	if weapon.get("kind") == "beam":
		behavior_label.text = "Raggio rettilineo istantaneo: il terreno ferma il colpo."
	elif weapon.get("kind") == "scatter":
		behavior_label.text = "5 schegge istantanee: danno indicato per scheggia."
	elif weapon.get("kind") == "drill":
		behavior_label.text = "Scava per 1,1 s; poi esplode all'impatto."

func restore_defaults() -> void:
	draft_weapons = WeaponCatalog.load_definitions()
	draft_rules = ArsenalData.sanitize_rules(null)
	sync_form()
	message.text = "Valori base ripristinati nella bozza. Premi Applica per usarli."

func close_editor() -> void:
	commit_numbers()
	set_editing(false)
	close_requested.emit()

func apply_draft() -> void:
	commit_numbers()
	draft_weapons = WeaponCatalog.sanitize(draft_weapons)
	draft_rules = ArsenalData.sanitize_rules(draft_rules)
	sync_form()
	set_editing(false)
	apply_requested.emit(draft_weapons.duplicate(true), draft_rules.duplicate(true))

func open_save() -> void:
	commit_numbers()
	save_dialog.current_file = "Le mie armi.arsenale"
	save_dialog.popup_centered(Vector2i(820, 480))

func save_to(path: String) -> void:
	commit_numbers()
	if not path.to_lower().ends_with(".arsenale"):
		path += ".arsenale"
	var error := ArsenalData.save_preset(path, draft_weapons, draft_rules)
	message.text = "Salvata: " + path.get_file() if error.is_empty() else error

func open_load() -> void:
	commit_numbers()
	load_dialog.popup_centered(Vector2i(820, 480))

func load_from(path: String) -> void:
	var result := ArsenalData.load_preset(path)
	if not result["error"].is_empty():
		message.text = result["error"] + " La bozza è conservata."
		return
	draft_weapons = result["weapons"]
	draft_rules = result["rules"]
	sync_form()
	message.text = "Caricata: " + path.get_file() + ". Premi Applica per usarla."

func _unhandled_input(event: InputEvent) -> void:
	if save_dialog.visible or load_dialog.visible or color_field.get_popup().visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_editor()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	# Esc deve funzionare anche mentre si scrive in un campo.
	if save_dialog.visible or load_dialog.visible or color_field.get_popup().visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_editor()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("0b1525"))





