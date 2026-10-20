# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("verify")
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
func arena(game) -> void:
	game.rules["scatter_spawns"] = false
	game.rules["team_size"] = 1
	game.rules["ai_enabled"] = false
	game.reset_game()
	game.ground.fill(Color.TRANSPARENT)
	game.ground.fill_rect(Rect2i(0, 500, game.W, 200), Color.WHITE)
	game.terrain_revision += 1
	game.units[0]["pos"] = Vector2(200, 487)
	game.units[1]["pos"] = Vector2(700, 487)
	game.angle = 30
	game.power = 380
	game.facing = 1
	game.view_center = game.units[0]["pos"]
	game.update_view(1)
func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.menu.scatter_field.button_pressed = false
	game.menu.start_match()
	arena(game)
	var wheel := InputEventMouseButton.new()
	wheel.position = Vector2(500, 400)
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	game._unhandled_input(wheel)
	var chosen_zoom: float = game.view_zoom
	game.next_turn()
	check(game.view_zoom == chosen_zoom, "Zoom mantenuto al cambio turno")
	game.reset_game()
	check(game.view_zoom == chosen_zoom, "Zoom mantenuto al riavvio")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_C
	game._unhandled_input(key)
	game._unhandled_input(key)
	check(game.view_zoom == chosen_zoom, "Panoramica ripristina esattamente lo zoom precedente")
	key.keycode = KEY_M
	game._unhandled_key_input(key)
	check(game.picker.opened, "M apre arsenale")
	game._unhandled_key_input(key)
	check(not game.picker.opened, "M chiude arsenale")
	var right := InputEventMouseButton.new()
	right.position = Vector2(500, 400)
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	game._unhandled_input(right)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(500, 400)
	motion.relative = Vector2(0, -50)
	var before: float = game.power
	game._unhandled_input(motion)
	check(not game.picker.opened and game.power > before, "Destro modifica potenza senza aprire arsenale")
	motion.relative.y = 80
	game._unhandled_input(motion)
	check(game.power < before, "Potenza riducibile con il mouse")
	right.pressed = false
	game._unhandled_input(right)
	arena(game)
	var left := InputEventMouseButton.new()
	left.position = game.units[0]["pos"] * game.view_zoom + game.view_offset + Vector2(100, -50)
	left.button_index = MOUSE_BUTTON_LEFT
	left.pressed = true
	game._unhandled_input(left)
	check(game.mouse_charging and not game.flying, "Clic premuto prepara il colpo")
	game._physics_process(1)
	check(game.power > 150 and game.power < 650, "Carica progressiva con mouse")
	left.pressed = false
	game._unhandled_input(left)
	check(game.flying and not game.mouse_charging, "Rilascio spara")
	arena(game)
	game.select_weapon(4)
	game.angle = 0
	var rays: Array = game.trajectory_preview.paths(game)
	check(rays.size() == 1 and rays[0].size() == 2 and rays[0][0].y == rays[0][1].y, "Raggio ha anteprima rettilinea")
	var ray_end: Vector2 = rays[0][-1]
	game.shoot()
	check(game.traces[0][-1].distance_to(ray_end) < 0.01, "Anteprima raggio coincide con impatto reale")
	arena(game)
	game.select_weapon(5)
	check(game.trajectory_preview.paths(game).size() == 5, "Ventaglio mostra cinque traiettorie")
	for slot in [0, 1]:
		arena(game)
		game.select_weapon(slot)
		game.angle = 30
		game.power = 290
		var original: PackedByteArray = game.ground.get_data()
		var predicted: Vector2 = game.trajectory_preview.paths(game)[0][-1]
		check(game.ground.get_data() == original, "Anteprima non scava ne infligge danni")
		game.shoot()
		for frame in range(900):
			game.update_projectile(1.0 / 60)
			if not game.flying:
				break
		check(game.blast_position.distance_to(predicted) < 3, "Impatto anteprima/tiro arma %d: errore %.2f" % [slot, game.blast_position.distance_to(predicted)])
	# Mappa nuova: una squadra distribuita tra le tre quote, avversari vicini.
	var terrain: Dictionary = game.TerrainFactory.create(4, 73)
	var first: Dictionary = game.TeamSpawns.scattered(terrain["image"], terrain["spawns"], 3, 123)
	var second: Dictionary = game.TeamSpawns.scattered(terrain["image"], terrain["spawns"], 3, 456)
	check(first["error"].is_empty() and first["positions"] != second["positions"], "Semi diversi producono partenze diverse")
	var levels: Array[int] = []
	var positions: PackedVector2Array = first["positions"]
	for i in range(positions.size()):
		check(game.TeamSpawns.MapData.spawn_error(terrain["image"], positions[i]).is_empty(), "Partenza casuale libera e sostenuta")
		if i % 2 == 0:
			levels.append(0 if positions[i].y < 330 else (1 if positions[i].y < 480 else 2))
			check(positions[i].distance_to(positions[i + 1]) <= 280, "Nemico nello stesso settore")
		for j in range(i):
			check(positions[i].distance_to(positions[j]) >= 55, "Nessuna sovrapposizione iniziale")
	check(levels == [0, 1, 2], "Tre livelli usati nelle partenze")
	print("PASS FIXES 0.12" if not failed else "FAIL FIXES 0.12")
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if failed else 0)



