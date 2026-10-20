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
	root.get_texture().get_image().save_png("res://verifiche/pacchetti-menu-0.8.png")
	var menu = game.menu
	menu.team_field.value = 3
	menu.health_field.get_line_edit().grab_focus()
	menu.health_field.get_line_edit().text = "160"
	click(menu.export_button.get_global_rect().get_center())
	assert(menu.export_dialog.visible and menu.rules["starting_health"] == 160, "Esporta conferma il numero digitato e apre la finestra")
	assert(menu.export_dialog.get_ok_button().text == "Esporta")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/esporta-pacchetto-0.8.png")
	var path := "user://verify-visual-package.crateripack"
	menu.export_dialog.file_selected.emit(path)
	menu.export_dialog.hide()
	assert(FileAccess.file_exists(path))
	menu.use_default_preset()
	click(menu.import_button.get_global_rect().get_center())
	assert(menu.package_dialog.visible, "Carica pacchetto apre la finestra")
	menu.package_dialog.file_selected.emit(path)
	menu.package_dialog.hide()
	assert(menu.rules["team_size"] == 3 and menu.rules["starting_health"] == 160, "Il pacchetto ripristina la preparazione")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/pacchetto-caricato-0.8.png")
	click(menu.start_button.get_global_rect().get_center())
	assert(game.units.size() == 6 and game.units[0]["hp"] == 160)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/partita-pacchetto-0.8.png")
	DirAccess.remove_absolute(path)
	print("PASS: pulsanti Esporta/Carica pacchetto, finestre e segnali file, numero digitato, anteprima e avvio")
	quit()

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
