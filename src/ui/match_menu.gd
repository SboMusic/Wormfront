# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends Node2D

signal start_requested(image: Image, spawns: PackedVector2Array, weapons: Array[Dictionary], rules: Dictionary)
signal resume_requested

const MapData = preload("res://src/data/map_data.gd")
const ArsenalData = preload("res://src/data/arsenal_data.gd")
const WeaponCatalog = preload("res://src/data/weapon_catalog.gd")
const TeamSpawns = preload("res://src/world/team_spawns.gd")
const PackageData = preload("res://src/data/package_data.gd")
var opened := false
var can_resume := false
var image: Image
var spawns := PackedVector2Array()
var weapons: Array[Dictionary] = []
var rules: Dictionary = {}
var default_image: Image
var default_spawns := PackedVector2Array()
var default_weapons: Array[Dictionary] = []
var map_name := "Isole sospese"
var preset_name := "Configurazione iniziale"
var syncing := false
var layer: CanvasLayer
var map_label: Label
var preset_label: Label
var summary: Label
var message: Label
var preview: TextureRect
var team_field: SpinBox
var health_field: SpinBox
var turn_field: SpinBox
var friendly_field: CheckBox
var start_button: Button
var resume_button: Button
var map_dialog: FileDialog
var preset_dialog: FileDialog
var package_dialog: FileDialog
var export_dialog: FileDialog
var export_button: Button
var import_button: Button
const TerrainFactory = preload("res://src/world/terrain_factory.gd")
var terrain_choice: OptionButton
var scatter_field: CheckBox
var current_seed := -1
var current_terrain := 4
var sound_field: CheckBox
var ai_level: OptionButton
var ai_field: CheckBox
var supplies_field: CheckBox

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	var panel := Panel.new()
	panel.position = Vector2(24, 18)
	panel.size = Vector2(1052, 664)
	layer.add_child(panel)
	sound_field = CheckBox.new()
	sound_field.text = "Suoni attivi"
	sound_field.position = Vector2(420, 24)
	sound_field.button_pressed = true
	sound_field.toggled.connect(func(value: bool): get_parent().audio.set_enabled(value))
	panel.add_child(sound_field)
	var text_actions := HBoxContainer.new()
	text_actions.position = Vector2(680, 24)
	panel.add_child(text_actions)
	var text_label := Label.new()
	text_label.text = "Testi partita"
	text_actions.add_child(text_label)
	add_button(text_actions, "A−", func(): get_parent().set_text_scale(get_parent().text_scale - 0.1))
	add_button(text_actions, "A+", func(): get_parent().set_text_scale(get_parent().text_scale + 0.1))
	var fullscreen_actions := HBoxContainer.new()
	fullscreen_actions.position = Vector2(900, 24)
	panel.add_child(fullscreen_actions)
	add_button(fullscreen_actions, "Schermo [F11]", func(): get_parent().toggle_fullscreen())
	var title := label_at(panel, "WORMFRONT", Vector2(28, 16), 36)
	title.modulate = Color("58d7da")
	label_at(panel, "PREPARA LA PARTITA  /  Alpha 0.20.0", Vector2(30, 68), 18)
	label_at(panel, "MAPPA + ARMI + REGOLE", Vector2(582, 84), 13)
	var package_actions := HBoxContainer.new()
	package_actions.position = Vector2(582, 108)
	panel.add_child(package_actions)
	import_button = add_button(package_actions, "Carica pacchetto…", open_package)
	export_button = add_button(package_actions, "Esporta pacchetto…", open_export)
	var left := VBoxContainer.new()
	left.position = Vector2(30, 118)
	left.size = Vector2(510, 430)
	left.add_theme_constant_override("separation", 6)
	panel.add_child(left)
	map_label = Label.new()
	map_label.clip_text = true
	left.add_child(map_label)
	var map_actions := HBoxContainer.new()
	left.add_child(map_actions)
	terrain_choice = OptionButton.new()
	for title_text in TerrainFactory.NAMES:
		terrain_choice.add_item(title_text)
	terrain_choice.add_item("Personalizzata")
	terrain_choice.set_item_disabled(TerrainFactory.NAMES.size(), true)
	terrain_choice.selected = 4
	terrain_choice.item_selected.connect(use_terrain)
	map_actions.add_child(terrain_choice)
	add_button(map_actions, "Carica mappa…", func(): map_dialog.popup_centered(Vector2i(820, 480)))
	add_button(map_actions, "Rigenera", regenerate_terrain)
	preset_label = Label.new()
	preset_label.clip_text = true
	left.add_child(preset_label)
	var preset_actions := HBoxContainer.new()
	left.add_child(preset_actions)
	add_button(preset_actions, "Carica armi e regole…", func(): preset_dialog.popup_centered(Vector2i(820, 480)))
	add_button(preset_actions, "Valori iniziali", use_default_preset)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("v_separation", 6)
	left.add_child(grid)
	team_field = add_spin(grid, "Personaggi per squadra", 1, 4, "")
	health_field = add_spin(grid, "Vita di ogni personaggio", 1, 300, "PV")
	turn_field = add_spin(grid, "Durata del turno", 10, 120, "s")
	var friendly_label := Label.new()
	friendly_label.text = "Danni alla propria squadra"
	grid.add_child(friendly_label)
	friendly_field = CheckBox.new()
	friendly_field.text = "Attivi"
	friendly_field.toggled.connect(func(_enabled: bool): update_rules())
	grid.add_child(friendly_field)
	var ai_label := Label.new()
	ai_label.text = "Avversario Arancio"
	grid.add_child(ai_label)
	ai_field = CheckBox.new()
	ai_field.text = "Computer (IA)"
	ai_field.toggled.connect(func(_value: bool): update_rules())
	var ai_row := HBoxContainer.new()
	ai_row.add_child(ai_field)
	ai_level = OptionButton.new()
	for difficulty in ["Facile", "Normale", "Difficile"]:
		ai_level.add_item(difficulty)
	ai_level.item_selected.connect(func(_value: int): update_rules())
	ai_row.add_child(ai_level)
	grid.add_child(ai_row)
	var supplies_label := Label.new()
	supplies_label.text = "Casse ogni 2 turni"
	grid.add_child(supplies_label)
	supplies_field = CheckBox.new()
	supplies_field.text = "Armi e salute"
	supplies_field.toggled.connect(func(_value: bool): update_rules())
	grid.add_child(supplies_field)
	var scatter_label := Label.new()
	scatter_label.text = "Partenze mescolate"
	grid.add_child(scatter_label)
	scatter_field = CheckBox.new()
	scatter_field.text = "Casuali, squadre vicine"
	scatter_field.toggled.connect(func(_value: bool): update_rules())
	grid.add_child(scatter_field)
	preview = TextureRect.new()
	preview.position = Vector2(582, 150)
	preview.size = Vector2(440, 280)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(preview)
	summary = label_at(panel, "", Vector2(582, 444), 16)
	summary.size = Vector2(440, 96)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_at(panel, "Per creare o modificare: avvia una partita, poi usa F2 per le mappe e F4 per armi e regole.", Vector2(30, 546), 15)
	var actions := HBoxContainer.new()
	actions.position = Vector2(30, 584)
	panel.add_child(actions)
	start_button = add_button(actions, "Avvia nuova partita", start_match)
	resume_button = add_button(actions, "Riprendi partita [Esc]", resume_match)
	add_button(actions, "Esci dal gioco", func(): get_tree().quit())
	message = label_at(panel, "", Vector2(30, 628), 15)
	message.size.x = 992
	message.clip_text = true
	map_dialog = make_dialog("*.wormfront,*.crateri;Mappe Wormfront e precedenti", "Carica mappa", "user://maps")
	map_dialog.file_selected.connect(load_map)
	preset_dialog = make_dialog("*.arsenale;Armi e regole Wormfront", "Carica armi e regole", "user://arsenals")
	preset_dialog.file_selected.connect(load_preset)
	DirAccess.make_dir_recursive_absolute("user://packages")
	package_dialog = make_dialog("*.wormfrontpack,*.crateripack;Pacchetti Wormfront e precedenti", "Carica pacchetto completo", "user://packages")
	package_dialog.file_selected.connect(load_package)
	export_dialog = make_dialog("*.wormfrontpack,*.crateripack;Pacchetti Wormfront e precedenti", "Esporta mappa, armi e regole", "user://packages", FileDialog.FILE_MODE_SAVE_FILE)
	export_dialog.file_selected.connect(export_to)
	set_opened(false)

func label_at(parent: Node, title: String, position: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = title
	label.position = position
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func add_button(parent: Node, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func add_spin(grid: GridContainer, title: String, low: float, high: float, suffix: String) -> SpinBox:
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 260
	grid.add_child(label)
	var control := SpinBox.new()
	control.min_value = low
	control.max_value = high
	control.step = 1
	control.suffix = suffix
	control.custom_minimum_size.x = 200
	control.get_line_edit().focus_exited.connect(control.apply)
	control.value_changed.connect(func(_value: float): update_rules())
	grid.add_child(control)
	return control

func make_dialog(filter: String, title: String, directory: String, mode: FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = mode
	dialog.title = title
	dialog.get_ok_button().text = "Esporta" if mode == FileDialog.FILE_MODE_SAVE_FILE else "Carica"
	dialog.get_cancel_button().text = "Annulla"
	dialog.filters = PackedStringArray([filter])
	dialog.current_dir = ProjectSettings.globalize_path(directory)
	add_child(dialog)
	return dialog

func initialize(terrain: Image, anchors: PackedVector2Array, definitions: Array[Dictionary]) -> void:
	default_image = terrain.duplicate()
	default_spawns = anchors.duplicate()
	default_weapons = WeaponCatalog.sanitize(definitions)
	prepare(terrain, anchors, definitions, ArsenalData.sanitize_rules(null))
	rules["ai_enabled"] = true
	rules["scatter_spawns"] = true
	rules["team_size"] = 3
	sync_form()

func prepare(terrain: Image, anchors: PackedVector2Array, definitions: Array[Dictionary], settings: Dictionary) -> void:
	image = terrain.duplicate()
	spawns = anchors.duplicate()
	weapons = WeaponCatalog.sanitize(definitions)
	rules = ArsenalData.sanitize_rules(settings)
	sync_form()

func sync_form() -> void:
	syncing = true
	var terrain_index := current_terrain if current_seed >= 0 else TerrainFactory.NAMES.find(map_name)
	terrain_choice.select(terrain_index if terrain_index >= 0 else TerrainFactory.NAMES.size())
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	team_field.value = rules["team_size"]
	health_field.value = rules["starting_health"]
	turn_field.value = rules["turn_seconds"]
	friendly_field.button_pressed = rules["self_damage"]
	ai_field.button_pressed = rules.get("ai_enabled", false)
	ai_level.select(int(rules.get("ai_level", 1)))
	scatter_field.button_pressed = rules.get("scatter_spawns", false)
	supplies_field.button_pressed = rules.get("supplies", true)
	syncing = false
	refresh()

func update_rules() -> void:
	if syncing or rules.is_empty():
		return
	rules = ArsenalData.sanitize_rules({"team_size": team_field.value, "starting_health": health_field.value, "turn_seconds": turn_field.value, "self_damage": friendly_field.button_pressed, "scatter_spawns": scatter_field.button_pressed, "ai_level": ai_level.selected, "ai_enabled": ai_field.button_pressed, "supplies": supplies_field.button_pressed})
	refresh()

func commit_numbers() -> void:
	for control in [team_field, health_field, turn_field]:
		if control.get_line_edit().has_focus():
			control.apply()
	update_rules()

func refresh() -> void:
	if image == null:
		return
	map_label.text = "MAPPA  /  " + map_name
	map_label.tooltip_text = map_name
	preset_label.text = "ARMI E REGOLE  /  " + preset_name
	preset_label.tooltip_text = preset_name
	var layout := TeamSpawns.plan(image, spawns, int(rules["team_size"]))
	start_button.disabled = not layout["error"].is_empty()
	export_button.disabled = start_button.disabled
	message.text = layout["error"] if start_button.disabled else ("Avvia sostituisce partita e bozze degli editor. Riprendi le conserva." if can_resume else "Scegli le impostazioni e premi Avvia nuova partita.")
	# Anteprima del terreno e delle posizioni iniziali, separata dalla partita.
	var thumbnail := image.duplicate()
	thumbnail.resize(440, 280, Image.INTERPOLATE_NEAREST)
	if rules.get("scatter_spawns", false) and layout["error"].is_empty():
		layout = TeamSpawns.scattered(image, spawns, int(rules["team_size"]), 42)
		preview.tooltip_text = "Partenze indicative: vengono mescolate a ogni avvio."
	else:
		preview.tooltip_text = "Posizioni iniziali delle squadre."
	if layout.has("positions"):
		var positions: PackedVector2Array = layout["positions"]
		for i in range(positions.size()):
			var p := Vector2(positions[i].x * 440.0 / image.get_width(), positions[i].y * 280.0 / image.get_height())
			for x in range(maxi(0, int(p.x) - 4), mini(440, int(p.x) + 5)):
				for y in range(maxi(0, int(p.y) - 4), mini(280, int(p.y) + 5)):
					if Vector2(x, y).distance_to(p) <= 4:
						thumbnail.set_pixel(x, y, Color("58d7da") if i % 2 == 0 else Color("ffad68"))
	preview.texture = ImageTexture.create_from_image(thumbnail)
	if preview.material == null:
		preview.material=get_parent().terrain_sprite.material.duplicate()
	preview.material.set_shader_parameter("world_dimensions",Vector2(image.get_size()))
	var members := "personaggio" if rules["team_size"] == 1 else "personaggi"
	summary.text = "Due squadre da %d %s · %d armi\n%d PV ciascuno · turni da %d s\nM: arsenale con munizioni di squadra\n%s" % [rules["team_size"], members, weapons.size(), rules["starting_health"], rules["turn_seconds"], "Turchese contro IA Arancio" if rules.get("ai_enabled", false) else "Due giocatori sullo stesso PC"]

func show_menu(resumable: bool, finished: bool = false) -> void:
	can_resume = resumable
	resume_button.visible = resumable
	resume_button.text = "Torna al risultato [Esc]" if finished else "Riprendi partita [Esc]"
	set_opened(true)
	refresh()

func set_opened(enabled: bool) -> void:
	opened = enabled
	visible = enabled
	layer.visible = enabled
	set_process_input(enabled)
	queue_redraw()

func start_match() -> void:
	commit_numbers()
	var layout := TeamSpawns.plan(image, spawns, int(rules["team_size"]))
	if not layout["error"].is_empty():
		message.text = layout["error"]
		return
	start_requested.emit(image.duplicate(), spawns.duplicate(), weapons.duplicate(true), rules.duplicate(true))

func resume_match() -> void:
	if not can_resume:
		return
	commit_numbers()
	set_opened(false)
	resume_requested.emit()

func use_default_map() -> void:
	current_seed = -1
	current_terrain = 4
	commit_numbers()
	image = default_image.duplicate()
	spawns = default_spawns.duplicate()
	map_name = "Isole sospese"
	terrain_choice.select(4)
	refresh()

func use_terrain(index: int) -> void:
	current_terrain = index
	commit_numbers()
	if index == 0:
		image = get_parent().generate_classic_ground()
		spawns = PackedVector2Array([MapData.find_spawn(image, Vector2(210, 174)), MapData.find_spawn(image, Vector2(890, 174))])
	else:
		var terrain := TerrainFactory.create(index)
		image = terrain["image"]
		spawns = terrain["spawns"]
		current_seed = int(terrain.get("seed", -1))
	map_name = TerrainFactory.NAMES[index]
	if index >= 4:
		map_name = TerrainFactory.Generator.FAMILIES[(index - 4) % 6] + " · " + str(current_seed)
	refresh()

func use_default_preset() -> void:
	weapons = default_weapons.duplicate(true)
	rules = ArsenalData.sanitize_rules(null)
	preset_name = "Configurazione iniziale"
	sync_form()

func load_map(path: String) -> void:
	var result := MapData.load_map(path)
	if not result["error"].is_empty():
		message.text = result["error"] + " La scelta precedente è conservata."
		return
	commit_numbers()
	image = result["image"]
	spawns = result["spawns"]
	current_seed = -1
	map_name = path.get_file()
	terrain_choice.select(TerrainFactory.NAMES.size())
	refresh()

func load_preset(path: String) -> void:
	var result := ArsenalData.load_preset(path)
	if not result["error"].is_empty():
		message.text = result["error"] + " La scelta precedente è conservata."
		return
	weapons = result["weapons"]
	rules = result["rules"]
	preset_name = path.get_file()
	sync_form()

func open_package() -> void:
	commit_numbers()
	package_dialog.popup_centered(Vector2i(820, 480))

func load_package(path: String) -> void:
	var result := PackageData.load_package(path)
	if not result["error"].is_empty():
		message.text = result["error"] + " La scelta precedente è conservata."
		return
	current_seed = -1
	map_name = path.get_file()
	preset_name = path.get_file()
	prepare(result["image"], result["spawns"], result["weapons"], result["rules"])
	message.text = "Pacchetto caricato. Controlla l'anteprima e premi Avvia nuova partita."

func open_export() -> void:
	commit_numbers()
	if export_button.disabled:
		return
	export_dialog.current_file = "La mia partita.wormfrontpack"
	export_dialog.popup_centered(Vector2i(820, 480))

func export_to(path: String) -> void:
	commit_numbers()
	if not path.to_lower().ends_with(".wormfrontpack"):
		path += ".wormfrontpack"
	var error := PackageData.save_package(path, image, spawns, weapons, rules)
	message.text = "Esportato: " + path.get_file() + ". Puoi copiare questo file su un altro PC." if error.is_empty() else error

func _input(event: InputEvent) -> void:
	if map_dialog.visible or preset_dialog.visible or package_dialog.visible or export_dialog.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		resume_match()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_texture_rect(preload("res://src/art/painted_art.gd").background(), Rect2(Vector2.ZERO,get_viewport_rect().size),false)
	draw_rect(Rect2(Vector2.ZERO,get_viewport_rect().size),Color(0.02,0.06,0.1,0.32))




func regenerate_terrain() -> void:
	var index := terrain_choice.selected
	if index < 4 or index >= TerrainFactory.NAMES.size():
		index = 4
	terrain_choice.select(index)
	use_terrain(index)











