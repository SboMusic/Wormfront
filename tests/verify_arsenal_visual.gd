# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.menu.start_match()
	DirAccess.make_dir_recursive_absolute("res://verifiche")
	await process_frame
	press_key(KEY_F4)
	var editor = game.arsenal_editor
	assert(editor.editing, "F4 deve aprire l'editor")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/armi-0.5.png")
	# Numero digitato e applicato dal pulsante, senza Invio.
	var damage_field: SpinBox = editor.fields["damage"]
	damage_field.get_line_edit().grab_focus()
	damage_field.get_line_edit().text = "88"
	editor.name_field.text = "Arma di prova"
	editor.name_field.text_changed.emit(editor.name_field.text)
	click(editor.apply_button.get_global_rect().get_center())
	assert(not editor.editing and game.weapons[0]["damage"] == 88, "Il pulsante applica anche un numero digitato")
	assert(game.weapons[0]["name"] == "Arma di prova")
	press_key(KEY_F4)
	editor.tabs.current_tab = 1
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/regole-0.5.png")
	click(editor.self_damage_field.get_global_rect().get_center())
	assert(not editor.draft_rules["self_damage"], "La casella modifica la bozza")
	editor.health_field.get_line_edit().grab_focus()
	editor.health_field.get_line_edit().text = "175"
	editor.turn_field.get_line_edit().grab_focus()
	editor.turn_field.get_line_edit().text = "45"
	click(editor.apply_button.get_global_rect().get_center())
	assert(game.units[0]["hp"] == 175 and game.turn_time == 45 and not game.rules["self_damage"])
	press_key(KEY_F4)
	editor.tabs.current_tab = 0
	await process_frame
	editor.name_field.grab_focus()
	press_key(KEY_ESCAPE)
	assert(not editor.editing and game.hud.visible, "Esc torna al gioco anche con il nome selezionato")
	press_key(KEY_F4)
	editor.open_save()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/salva-arsenale-0.5.png")
	editor.save_dialog.hide()
	editor.close_editor()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/gioco-0.5.png")
	print("PASS: F4, modifica numerica, pulsante Applica, regole, casella autodanno, Esc, catture armi/regole/salvataggio/gioco")
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
