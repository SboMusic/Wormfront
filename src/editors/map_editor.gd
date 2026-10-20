# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends Node2D

signal play_requested(image: Image, spawns: PackedVector2Array)
signal close_requested

const MapData = preload("res://src/data/map_data.gd")
const TeamSpawns = preload("res://src/world/team_spawns.gd")
const COLORS := [Color("58d7da"), Color("ffad68")]
const AREA := Rect2(0, 162, 1100, 468)
const HISTORY_LIMIT := 16
var editing := false
var image: Image
var texture: ImageTexture
var spawns := PackedVector2Array()
var brush_radius := 24
var tool := 0
var drawing := false
var stroke_erase := false
var stroke_button := MOUSE_BUTTON_LEFT
var previous := Vector2.ZERO
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var layer: CanvasLayer
var message: Label
var tools_label: Label
var size_label: Label
var save_dialog: FileDialog
var load_dialog: FileDialog
var undo_button: Button
var redo_button: Button
var team_size := 1
var layout: Dictionary = {}

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var panel := Panel.new()
	panel.position = Vector2(12, 8)
	panel.size = Vector2(1076, 148)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.position = Vector2(12, 6)
	column.size = Vector2(1052, 136)
	panel.add_child(column)
	tools_label = Label.new()
	tools_label.add_theme_font_size_override("font_size", 21)
	column.add_child(tools_label)
	var row := HBoxContainer.new()
	column.add_child(row)
	add_button(row, "Terra [B]", func(): choose_tool(0))
	add_button(row, "Gomma [G]", func(): choose_tool(1))
	add_button(row, "Turchese [1]", func(): choose_tool(2))
	add_button(row, "Arancio [2]", func(): choose_tool(3))
	size_label = Label.new()
	row.add_child(size_label)
	var slider := HSlider.new()
	slider.min_value = 8
	slider.max_value = 64
	slider.step = 2
	slider.value = brush_radius
	slider.custom_minimum_size = Vector2(140, 28)
	slider.value_changed.connect(func(value: float): brush_radius = int(value); refresh_ui())
	row.add_child(slider)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	undo_button = add_button(actions, "Annulla", undo)
	redo_button = add_button(actions, "Rifai", redo)
	add_button(actions, "Salva…", open_save)
	add_button(actions, "Carica…", open_load)
	add_button(actions, "Prova mappa [Invio]", play_map)
	add_button(actions, "Torna alla partita [Esc]", close_editor)
	message = Label.new()
	message.clip_text = true
	message.add_theme_font_size_override("font_size", 15)
	column.add_child(message)
	var footer := Label.new()
	footer.position = Vector2(22, 640)
	footer.text = "Sinistro: disegna · destro: cancella · 1/2: partenze delle squadre, con i compagni vicini.\nLa bozza resta in memoria quando torni alla partita. Usa Salva per conservarla dopo la chiusura."
	footer.add_theme_font_size_override("font_size", 16)
	layer.add_child(footer)
	DirAccess.make_dir_recursive_absolute("user://maps")
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

func make_dialog(mode: FileDialog.FileMode) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = mode
	dialog.title = "Salva mappa" if mode == FileDialog.FILE_MODE_SAVE_FILE else "Carica mappa"
	dialog.get_ok_button().text = "Salva" if mode == FileDialog.FILE_MODE_SAVE_FILE else "Carica"
	dialog.get_cancel_button().text = "Annulla"
	dialog.filters = PackedStringArray(["*.wormfront,*.crateri;Mappe Wormfront e precedenti"])
	dialog.current_dir = ProjectSettings.globalize_path("user://maps")
	add_child(dialog)
	return dialog

func begin_edit(source: Image, positions: PackedVector2Array, count: int = 1) -> void:
	team_size = count
	if image == null:
		image = source.duplicate()
		spawns = positions.duplicate()
		texture = ImageTexture.create_from_image(image)
		undo_stack.clear()
		redo_stack.clear()
	set_editing(true)
	message.text = "Disegna il terreno e controlla le due partenze. Invio avvia una nuova partita sulla bozza."
	refresh_ui()

func set_editing(enabled: bool) -> void:
	editing = enabled
	visible = enabled
	layer.visible = enabled
	drawing = false
	set_process(enabled)
	set_process_unhandled_input(enabled)

func clear_draft() -> void:
	image = null
	texture = null
	undo_stack.clear()
	redo_stack.clear()

func close_editor() -> void:
	set_editing(false)
	close_requested.emit()

func choose_tool(value: int) -> void:
	drawing = false
	tool = value
	refresh_ui()

func refresh_ui() -> void:
	tools_label.text = "EDITOR MAPPE  /  " + ["Terra", "Gomma", "Partenza Turchese", "Partenza Arancio"][tool] + "  ·  %d per squadra" % team_size
	size_label.text = "  Pennello: %d  " % brush_radius
	undo_button.disabled = undo_stack.is_empty()
	redo_button.disabled = redo_stack.is_empty()
	if image != null:
		layout = TeamSpawns.plan(image, spawns, team_size)
	queue_redraw()

func remember() -> void:
	undo_stack.append({"image": image.duplicate(), "spawns": spawns.duplicate()})
	if undo_stack.size() > HISTORY_LIMIT:
		undo_stack.pop_front()
	redo_stack.clear()

func restore(snapshot: Dictionary) -> void:
	image = snapshot["image"].duplicate()
	spawns = snapshot["spawns"].duplicate()
	texture.set_image(image)
	drawing = false
	refresh_ui()
	message.text = "Modifica ripristinata. " + MapData.validate(image, spawns)

func undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append({"image": image.duplicate(), "spawns": spawns.duplicate()})
	restore(undo_stack.pop_back())

func redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append({"image": image.duplicate(), "spawns": spawns.duplicate()})
	restore(redo_stack.pop_back())

func paint_segment(from: Vector2, to: Vector2, erase: bool) -> void:
	# Distanza dal segmento: un tratto continuo anche con movimenti rapidi.
	var left := maxi(0, floori(minf(from.x, to.x) - brush_radius))
	var right := mini(image.get_width() - 1, ceili(maxf(from.x, to.x) + brush_radius))
	var top := maxi(64 if image.get_height() > 700 else 162, floori(minf(from.y, to.y) - brush_radius))
	var bottom := mini(image.get_height() - 1, ceili(maxf(from.y, to.y) + brush_radius))
	var segment := to - from
	var length_squared := segment.length_squared()
	for x in range(left, right + 1):
		for y in range(top, bottom + 1):
			var point := Vector2(x, y)
			var t := clampf((point - from).dot(segment) / length_squared, 0.0, 1.0) if length_squared > 0.0 else 0.0
			if point.distance_squared_to(from + segment * t) <= brush_radius * brush_radius:
				image.set_pixel(x, y, Color.TRANSPARENT if erase else (Color("40554b") if (x * 7 + y * 13) % 23 < 3 else Color("795f49")))
	texture.set_image(image)
	layout = TeamSpawns.plan(image, spawns, team_size)
	message.text = layout["error"]
	if message.text.is_empty():
		message.text = "Spazio valido per %d personaggi per squadra. Puoi salvare o provare la mappa." % team_size
	queue_redraw()

func place_spawn(index: int, point: Vector2) -> bool:
	var candidate := MapData.find_spawn(image, point)
	if candidate.x < 0:
		message.text = "Clicca nello spazio libero sopra un terreno che possa sostenere il personaggio."
		return false
	if candidate.distance_to(spawns[1 - index]) < 36:
		message.text = "Scegli due partenze più distanti."
		return false
	remember()
	spawns[index] = candidate
	message.text = "Partenza aggiornata. " + MapData.validate(image, spawns)
	refresh_ui()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if save_dialog.visible or load_dialog.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: close_editor()
			KEY_ENTER: play_map()
			KEY_B: choose_tool(0)
			KEY_G: choose_tool(1)
			KEY_1: choose_tool(2)
			KEY_2: choose_tool(3)
			KEY_Z:
				if event.ctrl_pressed: undo()
			KEY_Y:
				if event.ctrl_pressed: redo()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var point: Vector2 = world_point(to_local(event.position))
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			if not event.pressed:
				drawing = false
			elif AREA.has_point(canvas_point(point)):
				if tool >= 2 and event.button_index == MOUSE_BUTTON_LEFT:
					place_spawn(tool - 2, point)
				else:
					remember()
					drawing = true
					stroke_button = event.button_index
					stroke_erase = tool == 1 or event.button_index == MOUSE_BUTTON_RIGHT
					previous = point
					paint_segment(point, point, stroke_erase)
					refresh_ui()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and drawing:
		var point: Vector2 = world_point(to_local(event.position))
		if AREA.has_point(canvas_point(point)):
			paint_segment(previous, point, stroke_erase)
			previous = point
		else:
			drawing = false
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if drawing:
		if not Input.is_mouse_button_pressed(stroke_button) or not AREA.has_point(get_local_mouse_position()):
			drawing = false
	queue_redraw()

func open_save() -> void:
	drawing = false
	var error := MapData.validate(image, spawns)
	if not error.is_empty():
		message.text = "Prima di salvare: " + error
		return
	save_dialog.current_file = "La mia mappa.wormfront"
	save_dialog.popup_centered(Vector2i(820, 480))

func save_to(path: String) -> void:
	if not path.to_lower().ends_with(".wormfront"):
		path += ".wormfront"
	var error := MapData.save_map(path, image, spawns)
	message.text = "Salvata: " + path.get_file() if error.is_empty() else error

func open_load() -> void:
	drawing = false
	load_dialog.popup_centered(Vector2i(820, 480))

func load_from(path: String) -> void:
	var result := MapData.load_map(path)
	if not result["error"].is_empty():
		message.text = result["error"] + " La bozza è conservata."
		return
	remember()
	restore(result)
	message.text = "Caricata: " + path.get_file() + ". Premi Invio per giocare."

func play_map() -> void:
	drawing = false
	layout = TeamSpawns.plan(image, spawns, team_size)
	var error: String = layout["error"]
	if not error.is_empty():
		message.text = "Prima di giocare: " + error
		return
	set_editing(false)
	play_requested.emit(image.duplicate(), spawns.duplicate())

func _draw() -> void:
	if texture == null:
		return
	draw_rect(Rect2(0, 0, 1100, 700), Color("101c30"))
	for x in range(0, 1100, 50):
		draw_line(Vector2(x, 162), Vector2(x, 630), Color(1, 1, 1, 0.05))
	for y in range(162, 630, 50):
		draw_line(Vector2(0, y), Vector2(1100, y), Color(1, 1, 1, 0.05))
	draw_set_transform(Vector2(0, 162 if image.get_height() > 700 else 0), 0, Vector2(1100.0 / image.get_width(), 468.0 / image.get_height() if image.get_height() > 700 else 1.0))
	draw_texture(texture, Vector2.ZERO)
	if layout.get("error", "") == "" and layout.has("positions"):
		var positions: PackedVector2Array = layout["positions"]
		for i in range(2, positions.size()):
			draw_circle(positions[i], 12, Color(COLORS[i % 2], 0.55))
			draw_string(ThemeDB.fallback_font, positions[i] + Vector2(-4, -18), str(floori(i / 2.0) + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLORS[i % 2])
	for i in range(spawns.size()):
		var valid := MapData.spawn_error(image, spawns[i]).is_empty()
		draw_circle(spawns[i], 12, COLORS[i] if valid else Color("ef5e6f"))
		draw_arc(spawns[i], 17, 0, TAU, 32, Color.WHITE, 1.5)
		draw_line(spawns[i] + Vector2(0, -22), spawns[i] + Vector2(0, -38), COLORS[i], 3)
	var mouse := world_point(get_local_mouse_position())
	if AREA.has_point(canvas_point(mouse)) and not save_dialog.visible and not load_dialog.visible:
		if tool < 2:
			draw_arc(mouse, brush_radius, 0, TAU, 48, Color("ffad68") if tool == 1 else Color("cbe8ac"), 1.5)
		else:
			var position := MapData.find_spawn(image, mouse)
			if position.x >= 0:
				draw_arc(position, 12, 0, TAU, 32, COLORS[tool - 2], 2)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0, 630, 1100, 70), Color("111c30"))




func world_point(point: Vector2) -> Vector2:
	return Vector2(point.x * image.get_width() / 1100.0, (point.y - 162) * image.get_height() / 468.0 if image.get_height() > 700 else point.y)

func canvas_point(point: Vector2) -> Vector2:
	return Vector2(point.x * 1100.0 / image.get_width(), 162 + point.y * 468.0 / image.get_height() if image.get_height() > 700 else point.y)

