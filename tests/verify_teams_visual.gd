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
	editor.tabs.current_tab = 1
	await process_frame
	await process_frame
	editor.team_size_field.get_line_edit().grab_focus()
	editor.team_size_field.get_line_edit().text = "3"
	click(editor.apply_button.get_global_rect().get_center())
	assert(game.units.size() == 6 and not editor.editing, "Numero di personaggi applicato dall'interfaccia")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/squadre-0.6.png")
	press_key(KEY_ENTER)
	assert(game.active == 1)
	press_key(KEY_ENTER)
	assert(game.active == 2 and game.units[2]["number"] == 2)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/turno-personaggio-0.6.png")
	game.units[0]["hp"] = 0
	game.units[1]["hp"] = 0
	game.check_winner()
	game.update_hud()
	game.queue_redraw()
	assert(game.winner.is_empty() and game.alive_count(0) == 2 and game.alive_count(1) == 2)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/eliminazioni-0.6.png")
	press_key(KEY_F2)
	assert(game.map_editor.editing and game.map_editor.layout["positions"].size() == 6)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/editor-squadre-0.6.png")
	press_key(KEY_ESCAPE)
	press_key(KEY_F4)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/regole-squadre-0.6.png")
	print("PASS: numero squadra digitato, Applica, Invio alterna i personaggi, contatori, anteprima mappa; catture squadre/turni/eliminazioni/editor/regole")
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
