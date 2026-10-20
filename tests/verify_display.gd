# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
var failed := false
var initial_fullscreen := false
func _initialize() -> void:
	call_deferred("verify")
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
func settle() -> void:
	await process_frame
	await process_frame
func verify() -> void:
	await settle()
	initial_fullscreen = root.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(-12000, -12000)
	root.size = Vector2i(1920, 1080)
	await settle()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var original_text: float = game.text_scale
	var original_zoom: float = game.preferred_zoom
	game.text_scale = 1
	game.preferred_zoom = 1
	check(initial_fullscreen, "Avvio a schermo intero")
	check(root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED, "Rendering nativo, senza stiramento della vecchia viewport")
	game.menu.start_match()
	for dimensions in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(1920,1200), Vector2i(2560,1080), Vector2i(3840,2160)]:
		root.mode = Window.MODE_WINDOWED
		root.size = dimensions
		await settle()
		game.apply_display_layout()
		await settle()
		check(Vector2i(game.screen_size) == dimensions, "Area nativa: %s, ricevuta %s" % [dimensions, game.screen_size])
		check(root.get_texture().get_width() == dimensions.x and root.get_texture().get_height() == dimensions.y, "Texture alla risoluzione nativa")
		var target: Vector2 = game.units[game.active]["pos"] + Vector2(80, -50)
		var screen: Vector2 = target * game.view_zoom + game.view_offset
		check(game.world_from_screen(screen).distance_to(target) < 0.01, "Mira con rapporto %s" % dimensions)
		var old_zoom: float = game.view_zoom
		var old_font: int = game.hud.get_theme_font_size("font_size")
		game.set_text_scale(1.4)
		await settle()
		check(is_equal_approx(old_zoom, game.view_zoom) and game.hud.get_theme_font_size("font_size") > old_font, "Testi indipendenti dalla mappa")
		check(game.action_row.position.x >= 0 and game.action_row.position.x + game.action_row.size.x <= game.screen_size.x + 2, "Pulsanti dentro lo schermo")
		game.set_text_scale(1)
		var visible_area: Vector2 = game.screen_size / game.view_zoom
		check(visible_area.y > 700, "Campo verticale libero dalle vecchie fasce")
		print("PASS DISPLAY SIZE ", dimensions)
	game.set_text_scale(1.6)
	game.toggle_help()
	await settle()
	check(game.help_scroll.position.y + game.help_scroll.size.y <= game.screen_size.y, "Aiuto scorrevole entro lo schermo anche con testi grandi")
	var clock: float = game.turn_time
	game._physics_process(2)
	check(game.help.visible and game.turn_time == clock, "Aiuto richiamabile e partita in pausa")
	game.toggle_help()
	check(not game.help.visible and not game.interaction_blocked(), "Chiusura aiuto riprende partita")
	root.size = Vector2i(1920,1080)
	await settle()
	game.apply_display_layout()
	game.toggle_picker()
	await settle()
	var tile: Control = game.picker.grid.get_child(1)
	var tile_point: Vector2 = tile.get_global_transform_with_canvas() * (tile.size / 2)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = tile_point
	press.global_position = tile_point
	Input.parse_input_event(press)
	await settle()
	press = press.duplicate()
	press.pressed = false
	Input.parse_input_event(press)
	await settle()
	check(game.units[game.active]["weapon"] == 1 and not game.picker.opened and not game.flying, "Clic sul pannello scalato sceglie arma senza sparare")
	game.open_map_editor()
	var editor = game.map_editor
	var world_point := Vector2(1900, 200)
	editor.image.set_pixel(1900, 200, Color.TRANSPARENT)
	var local_point: Vector2 = editor.canvas_point(world_point)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = editor.to_global(local_point)
	editor._unhandled_input(mouse)
	check(editor.image.get_pixel(1900,200).a > 0.5, "Pennello coerente con il menu ridimensionato")
	mouse.pressed = false
	editor._unhandled_input(mouse)
	editor.close_editor()
	game.open_arsenal_editor()
	game.arsenal_editor.switch_weapon(23)
	check(game.arsenal_editor.selected == 23, "Editor armi adattato")
	game.arsenal_editor.open_save()
	await settle()
	check(game.arsenal_editor.save_dialog.visible, "Finestra salvataggio accessibile")
	game.arsenal_editor.save_dialog.hide()
	game.arsenal_editor.close_editor()
	game.open_menu()
	await settle()
	var sound_point: Vector2 = game.menu.sound_field.get_global_transform_with_canvas() * (game.menu.sound_field.size / 2)
	press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = sound_point
	press.global_position = sound_point
	press.pressed = true
	Input.parse_input_event(press)
	await settle()
	press = press.duplicate()
	press.pressed = false
	Input.parse_input_event(press)
	await settle()
	check(not game.audio.enabled, "Casella suoni cliccabile nel menu scalato")
	game.menu.sound_field.button_pressed = true
	game.menu.resume_match()
	game.audio.play_event("beam")
	var voice: AudioStreamPlayer = game.audio.voices[(game.audio.cursor - 1) % game.audio.voices.size()]
	await create_timer(0.06).timeout
	check(voice.playing and voice.get_playback_position() > 0, "Riproduzione audio nella nuova visuale")
	game.toggle_help()
	check(voice.stream_paused, "Finestra comandi mette in pausa i suoni")
	game.toggle_help()
	game.audio.stop_all()
	var fullscreen_key := InputEventKey.new()
	fullscreen_key.pressed = true
	fullscreen_key.keycode = KEY_F11
	Input.parse_input_event(fullscreen_key)
	await settle()
	check(root.mode == Window.MODE_FULLSCREEN, "Passaggio a schermo intero")
	check(game.screen_size == Vector2(root.size), "Camera aggiornata al monitor")
	fullscreen_key = fullscreen_key.duplicate()
	fullscreen_key.pressed = false
	Input.parse_input_event(fullscreen_key)
	await settle()
	fullscreen_key = fullscreen_key.duplicate()
	fullscreen_key.pressed = true
	Input.parse_input_event(fullscreen_key)
	root.position = Vector2i(-12000,-12000)
	await settle()
	check(root.mode == Window.MODE_WINDOWED, "Ritorno in finestra")
	game.text_scale = original_text
	game.preferred_zoom = original_zoom
	game.save_display_preferences()
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("PASS DISPLAY 0.14" if not failed else "FAIL DISPLAY 0.14")
	quit(1 if failed else 0)




