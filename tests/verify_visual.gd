# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
## Catture reali del gioco con il renderer grafico, non in modalità headless.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.menu.start_match()
	DirAccess.make_dir_recursive_absolute("res://verifiche")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/gioco-0.4.png")
	press_key(KEY_F2)
	assert(game.map_editor.editing, "F2 deve aprire l'editor attraverso l'input")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/editor-0.4.png")
	click(Vector2(500, 250))
	assert(game.map_editor.image.get_pixel(500, 250).a > 0.5, "Il clic nel canvas deve disegnare")
	click(game.map_editor.undo_button.get_global_rect().get_center())
	assert(game.map_editor.image.get_pixel(500, 250).a < 0.5, "Il pulsante Annulla deve ricevere il clic")
	drag(Vector2(400, 250), Vector2(600, 250), MOUSE_BUTTON_LEFT)
	assert(game.map_editor.image.get_pixel(500, 250).a > 0.5, "Il trascinamento deve disegnare un tratto continuo")
	drag(Vector2(480, 250), Vector2(520, 250), MOUSE_BUTTON_RIGHT)
	assert(game.map_editor.image.get_pixel(500, 250).a < 0.5, "Il destro deve cancellare")
	click(game.map_editor.undo_button.get_global_rect().get_center())
	click(game.map_editor.undo_button.get_global_rect().get_center())
	assert(game.map_editor.image.get_pixel(500, 250).a < 0.5)
	press_key(KEY_1)
	assert(game.map_editor.tool == 2, "1 deve scegliere la partenza nell'editor")
	click(Vector2(600, 230))
	assert(game.map_editor.spawns[0].x == 600, "Il mouse deve spostare la partenza")
	press_key(KEY_ESCAPE)
	assert(not game.map_editor.editing and game.hud.visible, "Esc torna al gioco senza chiuderlo")
	press_key(KEY_F2)
	assert(game.map_editor.spawns[0].x == 600, "La bozza deve restare disponibile")
	game.map_editor.open_save()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/salva-mappa-0.4.png")
	print("PASS: input F2, mouse e trascinamento, gomma, pulsante Annulla, posizione iniziale, Esc, bozza; catture di gioco, editor e salvataggio")
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

func drag(from: Vector2, to: Vector2, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.position = from
	event.global_position = from
	event.button_index = button
	event.pressed = true
	root.push_input(event, true)
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.global_position = to
	motion.relative = to - from
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT if button == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
	root.push_input(motion, true)
	event = event.duplicate()
	event.position = to
	event.global_position = to
	event.pressed = false
	root.push_input(event, true)
