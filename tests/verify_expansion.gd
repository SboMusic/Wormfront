# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("verify")
func check(condition: bool, text: String) -> void:
	if not condition:
		failed = true
		push_error(text)
func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.weapons.size() == 36, "24 armi caricate")
	check(game.menu.TerrainFactory.NAMES.size() == 24, "24 mappe disponibili")
	for index in range(24):
		game.menu.use_terrain(index)
		var layout: Dictionary = game.TeamSpawns.plan(game.menu.image, game.menu.spawns, 4)
		check(layout["error"].is_empty(), "Mappa %d valida con 4 personaggi: %s" % [index, layout["error"]])
		if index >= 4:
			var mixed: Dictionary = game.TeamSpawns.scattered(game.menu.image, game.menu.spawns, 4, 100 + index)
			check(mixed["error"].is_empty() and mixed["positions"].size() == 8, "Mappa %d: otto partenze mescolate" % index)
			for point in mixed["positions"]:
				check(game.TeamSpawns.MapData.spawn_error(game.menu.image, point).is_empty(), "Appoggio casuale valido nella mappa %d" % index)
	game.menu.scatter_field.button_pressed = false
	game.menu.use_terrain(4)
	game.menu.team_field.value = 3
	game.menu.ai_level.select(2)
	game.menu.update_rules()
	game.menu.start_match()
	check(game.W == 2200 and game.units.size() == 6 and game.rules["ai_level"] == 2, "Campo grande, squadre e difficolta")
	var target: Vector2 = game.units[0]["pos"] + Vector2(120, -90)
	var screen: Vector2 = target * game.view_zoom + game.view_offset
	check(game.world_from_screen(screen).distance_to(target) < 0.01, "Conversione mouse con zoom e camera")
	game.aim_at(game.world_from_screen(screen))
	check(absf(game.angle - 36.8699) < 0.01 and game.facing == 1, "Mira mouse angolo corretto")
	game.aim_at(game.units[0]["pos"] + Vector2(-100, 50))
	check(game.facing == -1 and game.angle < 0, "Mira verso sinistra e in basso")
	var wheel := InputEventMouseButton.new()
	wheel.position = Vector2(550, 400)
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	var old_zoom: float = game.view_zoom
	game._unhandled_input(wheel)
	check(game.view_zoom > old_zoom, "Rotella modifica zoom")
	var overview_key := InputEventKey.new()
	overview_key.pressed = true
	overview_key.keycode = KEY_C
	game._unhandled_input(overview_key)
	check(game.overview and game.W * game.view_zoom <= game.screen_size.x, "Panoramica contiene tutta la mappa")
	game._unhandled_input(overview_key)
	check(not game.overview and game.view_zoom > 1, "Ritorno al personaggio")
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = (Vector2(game.units[0]["pos"]) + Vector2(100, -70)) * game.view_zoom + game.view_offset
	game._unhandled_input(click)
	click.pressed = false
	game._unhandled_input(click)
	check(game.flying and game.angle > 0 and game.facing == 1, "Clic sul campo mira e spara")
	game.reset_game()
	game.picker.refresh(game.weapons, game.ammo[0], 0)
	check(game.picker.grid.get_child_count() == 36, "24 tessere illustrate")
	game.picker.grid.get_child(23).pressed.emit()
	check(game.units[0]["weapon"] == 23, "Selezione ultima arma")
	game.picker.category = "Bombe"
	game.picker.refresh(game.weapons, game.ammo[0], 23)
	check(game.picker.grid.get_child_count() > 0 and game.picker.grid.get_child_count() < 36, "Filtro categoria")
	game.open_map_editor()
	check(game.map_editor.image.get_width() == 2200, "Editor conserva campo grande")
	game.map_editor.paint_segment(Vector2(1900, 250), Vector2(1950, 250), false)
	check(game.map_editor.image.get_pixel(1920, 250).a > 0.5, "Editor dipinge nella meta destra")
	game.map_editor.play_map()
	check(game.W == 2200 and game.solid(Vector2(1920, 250)), "Applicazione mappa grande")
	var path := "user://verify-expansion.wormfrontpack"
	check(game.menu.PackageData.save_package(path, game.map_template, game.template_spawns, game.weapons, game.rules).is_empty(), "Salvataggio campo grande")
	var saved: Dictionary = game.menu.PackageData.load_package(path)
	check(saved["error"].is_empty() and saved["image"].get_width() == 2200 and saved["weapons"].size() == 36 and saved["rules"]["ai_level"] == 2, "Pacchetto preserva dimensioni armi difficolta")
	DirAccess.remove_absolute(path)
	# Ogni livello termina una decisione su uno scenario noto, con griglie diverse.
	var candidate_counts: Array[int] = []
	for level in range(3):
		game.rules["ai_level"] = level
		game.rules["ai_enabled"] = true
		game.reset_game()
		game.ground.fill(Color.TRANSPARENT)
		game.ground.fill_rect(Rect2i(0, 500, game.W, 200), Color.WHITE)
		game.units[0]["pos"] = Vector2(350, 487)
		game.units[1]["pos"] = Vector2(850, 487)
		game.next_turn()
		for frame in range(1200):
			game._physics_process(1.0 / 60)
			if game.flying or game.settling:
				break
		check(game.flying or game.settling, "Livello IA %d conclude il tiro" % level)
		candidate_counts.append(game.ai.candidates.size())
	check(candidate_counts[0] < candidate_counts[1] and candidate_counts[1] < candidate_counts[2], "Difficolta modifica risoluzione della ricerca")
	print("PASS EXPANSION 0.11" if not failed else "FAIL EXPANSION 0.11")
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if failed else 0)





