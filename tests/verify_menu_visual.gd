# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	DirAccess.make_dir_recursive_absolute("res://verifiche")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/menu-0.7.png")
	var menu = game.menu
	assert(menu.opened and not game.has_match)
	menu.health_field.get_line_edit().grab_focus()
	menu.health_field.get_line_edit().text = "77"
	menu.use_default_preset()
	menu.commit_numbers()
	assert(menu.rules["starting_health"] == 100, "Valori iniziali scarta anche un numero digitato non ancora confermato")
	menu.team_field.get_line_edit().grab_focus()
	menu.team_field.get_line_edit().text = "3"
	menu.health_field.get_line_edit().grab_focus()
	menu.health_field.get_line_edit().text = "150"
	menu.turn_field.get_line_edit().grab_focus()
	menu.turn_field.get_line_edit().text = "40"
	click(menu.start_button.get_global_rect().get_center())
	assert(not menu.opened and game.units.size() == 6 and game.units[0]["hp"] == 150 and game.turn_time == 40, "Avvio dalle scelte digitate")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/partita-menu-0.7.png")
	press_key(KEY_2)
	press_key(KEY_SPACE)
	assert(game.flying)
	press_key(KEY_ESCAPE)
	var time: float = game.flight_time
	await process_frame
	await RenderingServer.frame_post_draw
	assert(menu.opened and game.flight_time == time, "Esc mette in pausa il tiro")
	root.get_texture().get_image().save_png("res://verifiche/menu-pausa-0.7.png")
	click(menu.resume_button.get_global_rect().get_center())
	assert(not menu.opened and game.flying)
	press_key(KEY_ESCAPE)
	menu.preset_dialog.popup_centered(Vector2i(820, 480))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/menu-carica-0.7.png")
	menu.preset_dialog.hide()
	press_key(KEY_ESCAPE)
	assert(not menu.opened and game.flying, "Esc riprende dal menu")
	print("PASS: menu renderizzato, numeri digitati, pulsante Avvia, Esc durante il tiro, Riprendi, finestra caricamento")
	quit()

func press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)

func click(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
