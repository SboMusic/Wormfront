# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends CanvasLayer
signal chosen(index: int)
const Art = preload("res://src/art/weapon_art.gd")
var opened := false
var panel: PanelContainer
var grid: GridContainer
var info: Label
var category := "Tutte"
var definitions: Array[Dictionary] = []
var stock: Array = []
var selected := 0

func _ready() -> void:
	layer = 4
	panel = PanelContainer.new()
	panel.position = Vector2(70, 162)
	panel.size = Vector2(960, 456)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("132b3af5")
	style.border_color = Color("c49a58")
	style.set_corner_radius_all(12)
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var title := Label.new()
	title.text = "ARSENALE  /  scegli un'arma"
	title.custom_minimum_size.x = 755
	title.add_theme_font_size_override("font_size", 23)
	heading.add_child(title)
	var close := Button.new()
	close.text = "Chiudi [M]"
	close.pressed.connect(func(): set_opened(false))
	heading.add_child(close)
	var filters := HBoxContainer.new()
	box.add_child(filters)
	for group in ["Tutte", "Artiglieria", "Bombe", "Precisione", "Speciali"]:
		var filter := Button.new()
		filter.text = group
		filter.focus_mode = Control.FOCUS_NONE
		filter.pressed.connect(func(): category = group; refresh(definitions, stock, selected))
		filters.add_child(filter)
	info = Label.new()
	info.text = "Scorte condivise dalla squadra · passa sulle armi per i dettagli"
	info.add_theme_font_size_override("font_size", 14)
	box.add_child(info)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(932, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	set_opened(false)

func refresh(items: Array[Dictionary], counts: Array, current: int) -> void:
	definitions = items
	stock = counts
	selected = current
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for i in range(items.size()):
		var weapon: Dictionary = items[i]
		if category != "Tutte" and weapon["category"] != category:
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(176, 126)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = stock[i] == 0
		var tile := VBoxContainer.new()
		tile.position = Vector2(5, 3)
		tile.size = Vector2(166, 120)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(tile)
		var art := TextureRect.new()
		art.custom_minimum_size = Vector2(166, 74)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture = make_icon(i, Color.html(weapon["color"]))
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(art)
		var label := Label.new()
		label.text = ("● " if i == selected else "") + weapon["name"] + "\n" + ("∞ munizioni" if stock[i] < 0 else "%d munizioni" % stock[i])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(label)
		var detail := "%s · danno %d · cratere %d px · %s" % [weapon["name"], weapon["damage"], weapon["crater_radius"], "miccia %.1f s" % weapon["fuse"] if weapon["trigger"] == "fuse" else "impatto"]
		var instructions := {"homing":"Mouse: indica il bersaglio prima del lancio", "controlled":"Mouse: guida il missile durante il volo", "airstrike":"Mouse: scegli la zona da colpire", "teleport":"Mouse: indica aria libera sopra un appoggio", "placed":"Posa vicino al verme, allontanati con le frecce", "melee":"Colpo ravvicinato nella direzione di mira"}
		if instructions.has(weapon["kind"]):
			detail += " · " + instructions[weapon["kind"]]
		button.tooltip_text = detail
		button.mouse_entered.connect(func(): info.text = detail)
		button.pressed.connect(func(): chosen.emit(i); set_opened(false))
		grid.add_child(button)

func set_opened(value: bool) -> void:
	opened = value
	if panel != null:
		panel.visible = value

func make_icon(index: int, color: Color) -> ImageTexture:
	var kind: String = definitions[index].get("kind", "projectile") if index < definitions.size() else "projectile"
	if index < definitions.size() and definitions[index]["trigger"] == "fuse":
		kind = "bomb"
	return Art.icon(kind, index, color)



