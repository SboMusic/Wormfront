# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
## Eseguire con Godot --headless --path . --script verify.gd

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	assert(game.menu.opened and not game.has_match and not game.menu.resume_button.visible, "Avvio nel menu senza partita riprendibile")
	var initial_clock: float = game.turn_time
	game._physics_process(3.0)
	game.shoot()
	game.menu.resume_match()
	assert(game.menu.opened and game.turn_time == initial_clock and not game.flying, "Il menu iniziale blocca il gioco")
	var classic: Image = game.generate_classic_ground()
	var anchors := PackedVector2Array([game.TeamSpawns.MapData.find_spawn(classic, Vector2(210, 174)), game.TeamSpawns.MapData.find_spawn(classic, Vector2(890, 174))])
	game.menu.prepare(classic, anchors, game.weapons, game.rules)
	game.menu.ai_field.button_pressed = false
	game.menu.start_match()
	var impact: Vector2 = game.units[1]["pos"] + Vector2(0, 15)
	assert(game.solid(impact), "Il terreno iniziale deve sostenere il personaggio")
	game.explode(impact)
	assert(not game.solid(impact), "Il colpo deve scavare il terreno")
	assert(game.units[1]["hp"] < 100, "Il colpo vicino deve infliggere danno")
	assert(game.units[1]["vel"].length() > 0, "L'esplosione deve spingere il personaggio")
	for frame in range(120):
		game._physics_process(1.0 / 60.0)
	assert(game.active == 1, "Il turno deve passare dopo l'assestamento")
	game.reset_game()
	game.shoot()
	for frame in range(900):
		game._physics_process(1.0 / 60.0)
	assert(not game.flying, "Il proiettile deve concludere il volo")
	assert(game.active == 1, "Il colpo deve passare il turno")
	game.reset_game()
	game._physics_process(36.0)
	assert(game.active == 1, "La scadenza deve passare il turno")
	game.units[1]["hp"] = 0
	game.check_winner()
	assert(not game.winner.is_empty(), "La partita deve avere un vincitore")
	game.reset_game()
	assert(game.winner.is_empty() and game.units[1]["hp"] == 100)
	verify_movement(game)
	verify_weapons(game)
	verify_maps(game)
	verify_arsenal(game)
	verify_teams(game)
	verify_menu(game)
	verify_packages(game)
	print("PASS: cratere, danno, spinta, assestamento, tiro, turni, vittoria, riavvio")
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit()

func verify_movement(game) -> void:
	# Arena piatta e gradini noti per misurare salto e collisioni.
	game.ground.fill(Color.TRANSPARENT)
	game.ground.fill_rect(Rect2i(0, 500, 1100, 200), Color.WHITE)
	var unit: Dictionary = game.units[0]
	unit["pos"] = Vector2(200, 487)
	unit["vel"] = Vector2.ZERO
	game.request_jump()
	game.update_unit(unit, 1.0 / 60.0)
	assert(unit["vel"].y < -200, "Shift deve avviare il salto")
	var highest: float = unit["pos"].y
	for frame in range(20):
		game.update_unit(unit, 1.0 / 60.0)
		highest = minf(highest, unit["pos"].y)
	game.request_jump()
	var before: float = unit["vel"].y
	game.update_unit(unit, 1.0 / 60.0)
	assert(unit["vel"].y > before, "Niente doppio salto in aria")
	for frame in range(120):
		game.update_unit(unit, 1.0 / 60.0)
	assert(highest < 450 and game.on_floor(unit), "Salto e atterraggio sul terreno")
	assert(not game.blocked(unit["pos"]), "Nessuna compenetrazione dopo l'atterraggio")
	game.ground.fill_rect(Rect2i(250, 496, 150, 4), Color.WHITE)
	for frame in range(110):
		game.set_walk_input(1.0, 1.0 / 60.0)
		game.update_unit(unit, 1.0 / 60.0)
	assert(unit["pos"].x > 350, "Il personaggio deve superare il gradino basso")
	game.ground.fill_rect(Rect2i(420, 350, 30, 150), Color.WHITE)
	for frame in range(120):
		game.set_walk_input(1.0, 1.0 / 60.0)
		game.update_unit(unit, 1.0 / 60.0)
	assert(unit["pos"].x < 420 and not game.blocked(unit["pos"]), "Un muro alto deve fermare il personaggio")
	game.reset_game()
	game.flying = true
	game.request_jump()
	assert(game.units[0]["jump_buffer"] == 0.0, "Niente salto durante il tiro")
	game.reset_game()
	game.set_walk_input(1.0, 1.0 / 60.0)
	assert(game.units[0]["motor"] > 0 and game.units[0]["motor"] < game.WALK_SPEED, "Accelerazione graduale")
	game.set_walk_input(0.0, 1.0 / 60.0)
	assert(game.units[0]["motor"] == 0.0, "Frenata al rilascio")
	game.reset_game()
	assert(game.units[0]["motor"] == 0.0 and game.units[0]["jump_buffer"] == 0.0)
	game.ground.fill(Color.TRANSPARENT)
	game.ground.fill_rect(Rect2i(0, 500, 1100, 200), Color.WHITE)
	game.explode(Vector2(300, 500))
	game.flying = false
	game.settling = false
	unit = game.units[0]
	unit["pos"] = Vector2(220, 487)
	unit["vel"] = Vector2.ZERO
	var lowest := 487.0
	var jumped_out := false
	for frame in range(180):
		if unit["pos"].x > 310 and game.on_floor(unit) and not jumped_out:
			game.request_jump()
			jumped_out = true
		game.set_walk_input(1.0, 1.0 / 60.0)
		game.update_unit(unit, 1.0 / 60.0)
		lowest = maxf(lowest, unit["pos"].y)
		assert(not game.blocked(unit["pos"]), "Nessuna compenetrazione sui bordi del cratere")
	assert(lowest > 510, "Il personaggio deve scendere nel cratere")
	assert(unit["pos"].x > 365, "Il personaggio deve uscire dal cratere con un salto")
	game.reset_game()
	print("PASS: salto, atterraggio, blocco doppio salto, gradini, muri, accelerazione, frenata")

func flat_arena(game) -> void:
	classic_reset(game)
	game.ground.fill(Color.TRANSPARENT)
	game.ground.fill_rect(Rect2i(0, 500, 1100, 200), Color.WHITE)
	game.units[0]["pos"] = Vector2(100, 487)
	game.units[1]["pos"] = Vector2(1000, 487)

func verify_weapons(game) -> void:
	var catalog = load("res://src/data/weapon_catalog.gd")
	var fallback: Array[Dictionary] = catalog.sanitize(null)
	assert(fallback.size() == 2 and fallback[1]["fuse"] == 3.0, "Fallback su file non valido")
	var bounded: Array[Dictionary] = catalog.sanitize([{"damage": 99999, "crater_radius": -5, "trigger": "script", "color": "invalid", "name": "\n"}, {"fuse": -10, "bounce": 2}])
	assert(bounded[0]["damage"] == 100.0 and bounded[0]["crater_radius"] == 8.0)
	assert(bounded[0]["trigger"] == "impact" and bounded[0]["color"] == "ffe39d")
	assert(bounded[1]["fuse"] == 1.0 and is_equal_approx(bounded[1]["bounce"], 0.85))
	assert(bounded[0]["name"] == "Lanciaproiettili")
	game.reset_game()
	game.select_weapon(1)
	game.next_turn()
	assert(game.units[1]["weapon"] == 0, "Ogni squadra conserva la propria scelta")
	game.next_turn()
	assert(game.units[0]["weapon"] == 1)
	game.shoot()
	game.select_weapon(0)
	assert(game.units[0]["weapon"] == 1, "Niente cambio arma durante il tiro")
	var captured: float = game.shot_weapon["damage"]
	game.weapons[1]["damage"] = 1.0
	assert(game.shot_weapon["damage"] == captured, "I valori del colpo sono congelati al lancio")
	game.weapons[1]["damage"] = captured
	game.reset_game()
	assert(not game.flying and game.shot_weapon.is_empty() and game.units[0]["weapon"] == 0)

	flat_arena(game)
	game.select_weapon(1)
	game.shoot()
	game.projectile = Vector2(400, 480)
	game.projectile_velocity = Vector2(40, 160)
	var bounced := false
	for frame in range(30):
		game.update_projectile(1.0 / 60.0)
		assert(game.flying and not game.settling, "La granata non esplode all'impatto")
		assert(not game.projectile_blocked(game.projectile), "La granata non entra nel terreno")
		if game.projectile_velocity.y < 0:
			bounced = true
	assert(bounced, "La granata deve rimbalzare sul pavimento")
	assert(game.solid(Vector2(400, 500)), "Nessun cratere prima della miccia")
	# Ferma la granata in un punto noto, vicino al bersaglio.
	game.projectile = Vector2(950, 495)
	game.projectile_resting = true
	game.flight_time = 0.5
	for frame in range(149):
		game.update_projectile(1.0 / 60.0)
	assert(game.flying, "La miccia non deve scadere prima di 3 secondi")
	game.update_projectile(1.0 / 60.0)
	assert(not game.flying and game.settling, "La miccia esplode anche da ferma")
	assert(not game.solid(Vector2(950, 500)), "L'esplosione scava un cratere")
	assert(not game.solid(Vector2(1005, 500)), "Raggio del cratere specifico della granata")
	assert(game.units[1]["hp"] < 100, "Danni della granata al bersaglio vicino")
	for frame in range(100):
		game._physics_process(1.0 / 60.0)
	assert(not game.flying and not game.settling and (game.active == 1 or (game.units[1]["hp"] == 0 and not game.winner.is_empty())), "La granata conclude il turno o vince spingendo il bersaglio oltre bordo")

	flat_arena(game)
	game.ground.fill_rect(Rect2i(500, 250, 2, 250), Color.WHITE)
	game.select_weapon(1)
	game.shoot()
	game.projectile = Vector2(480, 400)
	game.projectile_velocity = Vector2(650, 0)
	game.update_projectile(0.1)
	assert(game.projectile_velocity.x < 0 and game.projectile.x < 500, "Rimbalzo anche su un muro sottile")
	game.reset_game()
	assert(not game.flying and game.flight_time == 0.0, "Riavvio durante una miccia")

	flat_arena(game)
	game.shoot()
	game.projectile = Vector2(400, 480)
	game.projectile_velocity = Vector2(0, 200)
	for frame in range(10):
		if game.flying:
			game.update_projectile(1.0 / 60.0)
	assert(not game.flying and game.settling, "Il lanciaproiettili mantiene l'esplosione all'impatto")
	flat_arena(game)
	game.select_weapon(1)
	game.shoot()
	game.projectile = Vector2(1199, 200)
	game.projectile_velocity = Vector2(650, 0)
	game.update_projectile(0.1)
	assert(not game.flying and game.settling, "Un tiro fuori mappa non blocca il turno")
	game.reset_game()
	print("PASS: scelta armi, validazione dati, rimbalzi, miccia, danni, crateri, fuori mappa, riavvio granata")

func verify_maps(game) -> void:
	var map_data = load("res://src/data/map_data.gd")
	classic_reset(game)
	game.open_map_editor()
	var editor = game.map_editor
	assert(editor.editing and not game.hud.visible, "F2 apre l'editor")
	var clock: float = game.turn_time
	game._physics_process(2.0)
	game.shoot()
	game.request_jump()
	assert(game.turn_time == clock and not game.flying and game.units[0]["jump_buffer"] == 0.0, "Editor in pausa e comandi di combattimento esclusi")
	assert(map_data.validate(editor.image, editor.spawns).is_empty(), "Mappa iniziale valida")
	editor.remember()
	editor.paint_segment(Vector2(400, 300), Vector2(600, 300), false)
	assert(map_data.solid(editor.image, Vector2(500, 300)), "Pennellata continua")
	assert(not game.solid(Vector2(500, 300)), "La bozza non modifica la partita in corso")
	editor.undo()
	assert(not map_data.solid(editor.image, Vector2(500, 300)), "Annullamento pennellata")
	editor.redo()
	assert(map_data.solid(editor.image, Vector2(500, 300)), "Ripetizione pennellata")
	editor.remember()
	editor.paint_segment(Vector2(480, 300), Vector2(520, 300), true)
	assert(not map_data.solid(editor.image, Vector2(500, 300)), "Gomma")
	editor.undo()
	assert(editor.place_spawn(0, Vector2(450, 230)), "Partenza su una piattaforma disegnata")
	assert(editor.spawns[0].x == 450 and editor.spawns[0].y < 300)
	assert(not editor.place_spawn(1, Vector2(450, 230)), "Partenze sovrapposte rifiutate")
	var expected: PackedVector2Array = editor.spawns.duplicate()
	assert(map_data.validate(editor.image, expected).is_empty())
	var path := "user://verify-map.crateri"
	assert(map_data.save_map(path, editor.image, expected).is_empty(), "Salvataggio mappa")
	var loaded: Dictionary = map_data.load_map(path)
	assert(loaded["error"].is_empty(), "Caricamento mappa")
	assert(loaded["spawns"] == expected and loaded["image"].get_data() == editor.image.get_data(), "Terreno e partenze identici dopo salvataggio")
	assert(map_data.save_map(path, editor.image, expected).is_empty(), "Sovrascrittura mappa esistente")
	editor.close_editor()
	assert(not editor.editing and game.hud.visible)
	game.open_map_editor()
	assert(editor.spawns == expected, "Bozza conservata tornando alla partita")
	editor.play_map()
	assert(not editor.editing and game.units[0]["pos"] == expected[0] and game.units[0]["hp"] == 100, "Avvio sulla mappa creata")
	assert(game.solid(Vector2(500, 300)))
	game.explode(Vector2(500, 300))
	assert(not game.solid(Vector2(500, 300)))
	game.reset_game()
	assert(game.solid(Vector2(500, 300)) and game.units[0]["pos"] == expected[0], "R ripristina la mappa personalizzata")
	game.open_map_editor()
	editor.load_from(path)
	assert(editor.spawns == expected)
	# Un caricamento fallito non deve sostituire la bozza.
	var invalid_path := "user://verify-map-invalid.crateri"
	var file := FileAccess.open(invalid_path, FileAccess.WRITE)
	file.store_string("{file interrotto")
	file.close()
	assert(not map_data.load_map(invalid_path)["error"].is_empty())
	editor.load_from(invalid_path)
	assert(editor.spawns == expected and map_data.solid(editor.image, Vector2(500, 300)))
	# Un PNG con dimensioni diverse va rifiutato prima della decompressione.
	var tiny := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	file = FileAccess.open(invalid_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"format": "crateri-map", "version": 1, "terrain_png": Marshalls.raw_to_base64(tiny.save_png_to_buffer()), "spawns": [[0, 0], [0, 0]]}))
	file.close()
	assert(not map_data.load_map(invalid_path)["error"].is_empty(), "Dimensioni incompatibili rifiutate")
	# Una mappa senza supporto non può essere salvata o giocata.
	editor.remember()
	editor.paint_segment(expected[0], expected[0] + Vector2(0, 25), true)
	assert(not map_data.validate(editor.image, editor.spawns).is_empty())
	editor.play_map()
	assert(editor.editing, "Avvio rifiutato per una partenza senza supporto")
	assert(not map_data.save_map(path, editor.image, editor.spawns).is_empty())
	assert(map_data.load_map(path)["error"].is_empty(), "Un salvataggio invalido conserva il file precedente")
	editor.undo()
	assert(map_data.validate(editor.image, editor.spawns).is_empty())
	editor.close_editor()
	classic_reset(game)
	assert(not game.solid(Vector2(500, 300)), "Ritorno alla mappa iniziale")
	# Pulizia dei soli file creati da questa verifica.
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(invalid_path)
	editor.clear_draft()
	print("PASS: editor, pausa, pennello, gomma, annulla/rifai, partenze, salvataggio/caricamento, bozza, riavvio mappa, file non validi")

func verify_arsenal(game) -> void:
	var data = load("res://src/data/arsenal_data.gd")
	var original_weapons: Array[Dictionary] = game.weapons.duplicate(true)
	var original_rules: Dictionary = game.rules.duplicate(true)
	var bounded: Dictionary = data.sanitize_rules({"starting_health": 9999, "turn_seconds": -9, "self_damage": "no"})
	assert(bounded["starting_health"] == 300 and bounded["turn_seconds"] == 10 and bounded["self_damage"] == true)
	game.open_arsenal_editor()
	var editor = game.arsenal_editor
	assert(editor.editing and not game.hud.visible, "F4 apre l'editor armi")
	var seconds: float = game.turn_time
	game._physics_process(5.0)
	game.shoot()
	game.request_jump()
	game.open_map_editor()
	assert(not game.map_editor.editing and not game.flying and game.turn_time == seconds, "Pausa e separazione degli editor")
	editor.name_field.text = "Prova plasma"
	editor.fields["damage"].value = 90
	editor.fields["crater_radius"].value = 80
	editor.fields["gravity_scale"].value = 0.5
	editor.color_field.color = Color("dd66ff")
	editor.health_field.value = 200
	editor.turn_field.value = 12
	editor.self_damage_field.button_pressed = false
	editor.commit_numbers()
	assert(editor.draft_weapons[0]["name"] == "Prova plasma")
	assert(game.weapons[0]["damage"] == 65 and game.rules["starting_health"] == 100, "La bozza non cambia la partita")
	assert(editor.preview.estimated_damage() == int(90.0 * (1.0 - 65.0 / 95.0)), "Anteprima danno coerente con la distanza")
	editor.switch_weapon(1)
	assert(editor.fields["fuse"].editable and editor.fields["bounce"].editable)
	editor.fields["fuse"].value = 2.5
	editor.fields["bounce"].value = 75
	editor.trigger_field.select(0)
	editor.update_draft()
	assert(not editor.fields["fuse"].editable and editor.draft_weapons[1]["fuse"] == 0.0)
	editor.trigger_field.select(1)
	editor.update_draft()
	assert(editor.fields["fuse"].editable and editor.draft_weapons[1]["fuse"] == 2.5)
	assert(editor.draft_weapons[1]["bounce"] == 0.75)
	var path := "user://verify-settings.arsenale"
	editor.save_to(path)
	var saved: Dictionary = data.load_preset(path)
	assert(saved["error"].is_empty())
	assert(saved["weapons"][0]["name"] == "Prova plasma" and saved["rules"]["starting_health"] == 200)
	assert(data.save_preset(path, editor.draft_weapons, editor.draft_rules).is_empty(), "Sovrascrittura configurazione")
	editor.close_editor()
	assert(game.rules["starting_health"] == 100 and game.hud.visible)
	game.open_arsenal_editor()
	assert(editor.draft_rules["starting_health"] == 200, "Bozza armi conservata")
	editor.restore_defaults()
	assert(editor.draft_rules["starting_health"] == 100)
	editor.load_from(path)
	assert(editor.draft_rules["starting_health"] == 200)
	var invalid := "user://verify-settings-invalid.arsenale"
	var file := FileAccess.open(invalid, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	editor.load_from(invalid)
	assert(editor.draft_rules["starting_health"] == 200, "Un file danneggiato conserva la bozza")
	file = FileAccess.open(invalid, FileAccess.WRITE)
	file.store_string(JSON.stringify({"format": "crateri-arsenal", "version": 1, "weapons": [{}], "rules": {}}))
	file.close()
	assert(not data.load_preset(invalid)["error"].is_empty(), "Configurazione incompleta rifiutata")
	var template: PackedByteArray = game.map_template.get_data()
	editor.apply_draft()
	assert(not editor.editing and game.hud.visible)
	assert(game.units[0]["hp"] == 200 and game.units[0]["max_hp"] == 200 and game.turn_time == 12)
	assert(game.weapons[0]["damage"] == 90 and game.weapons[0]["color"] == "dd66ff")
	assert(game.map_template.get_data() == template, "Applicare le regole conserva la mappa")
	game.next_turn()
	assert(game.turn_time == 12, "La durata vale anche nei turni successivi")
	game.reset_game()
	game.units[0]["pos"] = Vector2(400, 350)
	game.units[1]["pos"] = Vector2(450, 350)
	game.explode(Vector2(400, 365))
	assert(game.units[0]["hp"] == 200 and game.units[0]["vel"].length() > 0, "Autodanno disattivato, spinta attiva")
	assert(game.units[1]["hp"] < 200, "Il danno al nemico rimane attivo")
	game.reset_game()
	game.shoot()
	game.projectile = Vector2(500, 200)
	game.projectile_velocity = Vector2(100, 0)
	game.update_projectile(0.1)
	assert(is_equal_approx(game.projectile_velocity.y, 21.0), "Gravità del proiettile personalizzata")
	game.open_arsenal_editor()
	assert(not editor.editing, "Non si apre l'editor durante il volo")
	game.reset_game()
	assert(game.units[0]["hp"] == 200 and game.turn_time == 12, "R conserva le regole applicate")
	game.apply_arsenal(original_weapons, original_rules)
	editor.initialized = false
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(invalid)
	print("PASS: editor armi/regole, bozza, anteprima, campi, configurazioni, vita, turni, autodanno, gravità, riavvio")

func verify_teams(game) -> void:
	var placement = load("res://src/world/team_spawns.gd")
	var data = load("res://src/data/arsenal_data.gd")
	var original_rules: Dictionary = game.rules.duplicate(true)
	var settings: Dictionary = original_rules.duplicate(true)
	settings["team_size"] = 3
	game.apply_arsenal(game.weapons, settings)
	assert(game.units.size() == 6 and game.alive_count(0) == 3 and game.alive_count(1) == 3, "Tre personaggi per squadra")
	for i in range(game.units.size()):
		assert(game.units[i]["team"] == i % 2 and game.units[i]["number"] == floori(i / 2.0) + 1)
		assert(placement.MapData.spawn_error(game.ground, game.units[i]["pos"]).is_empty(), "Partenza libera con appoggio")
		for j in range(i):
			assert(game.units[i]["pos"].distance_to(game.units[j]["pos"]) >= 34, "Niente partenze sovrapposte")
	for expected in [1, 2, 3, 4, 5, 0]:
		game.next_turn()
		assert(game.active == expected, "Alternanza T1, A1, T2, A2, T3, A3")
	game.reset_game()
	game.units[2]["hp"] = 0
	game.next_turn()
	game.next_turn()
	assert(game.active == 4, "I personaggi eliminati vengono saltati")
	assert(game.winner.is_empty(), "Un'eliminazione non chiude la partita")
	game.reset_game()
	game.select_weapon(1)
	for turn in range(6):
		game.next_turn()
		if game.active != 0:
			assert(game.units[game.active]["weapon"] == 0, "Scelta dell'arma distinta per personaggio")
	assert(game.active == 0 and game.selected_weapon()["name"] == game.weapons[1]["name"])
	game.units[0]["pos"] = Vector2(200, 740)
	for frame in range(180):
		game._physics_process(1.0 / 60.0)
	assert(game.units[0]["hp"] == 0 and game.active == 1 and game.winner.is_empty(), "Caduta dell'attivo: passa al nemico senza blocchi")
	game.reset_game()
	for i in [1, 3, 5]:
		game.units[i]["hp"] = 0
	game.check_winner()
	assert(game.winner == "Vince la squadra Turchese!", "Serve eliminare tutta la squadra")
	for unit in game.units:
		unit["hp"] = 0
	game.check_winner()
	assert(game.winner == "Pareggio!")
	game.reset_game()
	game.select_weapon(1)
	game.shoot()
	game.projectile = Vector2(500, 200)
	game.projectile_resting = true
	for unit in game.units:
		unit["hp"] = 0
	game._physics_process(0.1)
	assert(game.flying and game.winner.is_empty(), "Il colpo continua anche se il lanciatore muore")
	for frame in range(300):
		game._physics_process(1.0 / 60.0)
	assert(not game.flying and game.winner == "Pareggio!", "Il risultato aspetta la fine del colpo")
	settings["self_damage"] = false
	game.apply_arsenal(game.weapons, settings)
	game.units[0]["pos"] = Vector2(400, 300)
	game.units[2]["pos"] = Vector2(430, 300)
	game.units[1]["pos"] = Vector2(450, 300)
	game.explode(Vector2(400, 315))
	assert(game.units[0]["hp"] == 100 and game.units[2]["hp"] == 100, "Protezione per lanciatore e alleati")
	assert(game.units[2]["vel"].length() > 0 and game.units[1]["hp"] < 100, "Spinta alleati e danni nemici")
	settings["self_damage"] = true
	game.apply_arsenal(game.weapons, settings)
	game.units[0]["pos"] = Vector2(400, 300)
	game.units[2]["pos"] = Vector2(430, 300)
	game.explode(Vector2(400, 315))
	assert(game.units[0]["hp"] < 100 and game.units[2]["hp"] < 100, "Danni alla propria squadra attivi")
	game.reset_game()
	var path := "user://verify-teams.arsenale"
	assert(data.save_preset(path, game.weapons, settings).is_empty())
	assert(data.load_preset(path)["rules"]["team_size"] == 3, "Numero di personaggi nel salvataggio")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"format": "crateri-arsenal", "version": 1, "weapons": game.weapons, "rules": {"starting_health": 100, "turn_seconds": 35, "self_damage": true}}))
	file.close()
	assert(data.load_preset(path)["rules"]["team_size"] == 1, "Configurazioni precedenti compatibili")
	DirAccess.remove_absolute(path)
	assert(data.sanitize_rules({"team_size": 999})["team_size"] == 4)
	assert(data.sanitize_rules({"team_size": -9})["team_size"] == 1)
	var tiny := Image.create_empty(1100, 700, false, Image.FORMAT_RGBA8)
	tiny.fill_rect(Rect2i(186, 500, 28, 10), Color.WHITE)
	tiny.fill_rect(Rect2i(886, 500, 28, 10), Color.WHITE)
	var anchors := PackedVector2Array([Vector2(200, 487), Vector2(900, 487)])
	assert(placement.plan(tiny, anchors, 1)["error"].is_empty())
	assert(not placement.plan(tiny, anchors, 2)["error"].is_empty(), "Mappa stretta rifiutata per squadre numerose")
	# Una mappa inadatta non deve sostituire la partita a tre personaggi.
	var previous: PackedByteArray = game.map_template.get_data()
	game.open_map_editor()
	game.map_editor.image = tiny.duplicate()
	game.map_editor.texture.set_image(tiny)
	game.map_editor.spawns = anchors.duplicate()
	game.map_editor.play_map()
	assert(game.map_editor.editing and game.map_template.get_data() == previous)
	game.map_editor.close_editor()
	game.map_editor.clear_draft()
	# Con un personaggio la stessa mappa è valida; l'aumento deve fallire senza cambiare le regole attive.
	game.apply_arsenal(game.weapons, original_rules)
	game.apply_editor_map(tiny, anchors)
	game.arsenal_editor.initialized = false
	game.open_arsenal_editor()
	game.arsenal_editor.team_size_field.value = 2
	game.arsenal_editor.apply_draft()
	assert(game.arsenal_editor.editing and game.rules["team_size"] == 1 and game.units.size() == 2)
	game.arsenal_editor.close_editor()
	classic_reset(game)
	game.arsenal_editor.initialized = false
	settings["team_size"] = 4
	game.apply_arsenal(game.weapons, settings)
	assert(game.units.size() == 8, "Massimo quattro personaggi per squadra")
	game.reset_game()
	assert(game.active == 0 and game.alive_count(0) == 4 and game.alive_count(1) == 4)
	game.apply_arsenal(game.weapons, original_rules)
	print("PASS: squadre 1–4, posizioni, rotazione, eliminazioni, caduta, fine colpo, vittoria, pareggio, alleati, compatibilità, mappe strette")

func verify_menu(game) -> void:
	var map_data = load("res://src/data/map_data.gd")
	var arsenal_data = load("res://src/data/arsenal_data.gd")
	var initial_rules: Dictionary = game.rules.duplicate(true)
	var initial_weapons: Array[Dictionary] = game.weapons.duplicate(true)
	classic_reset(game)
	game.open_menu()
	var menu = game.menu
	menu.team_field.value = 3
	menu.health_field.value = 175
	menu.turn_field.value = 45
	menu.friendly_field.button_pressed = false
	menu.commit_numbers()
	assert(game.units.size() == 2 and game.rules["starting_health"] == 100, "Le scelte del menu non modificano la partita in pausa")
	var terrain: Image = game.map_template.duplicate()
	terrain.set_pixel(500, 300, Color.WHITE)
	var map_path := "user://verify-menu.crateri"
	var preset_path := "user://verify-menu.arsenale"
	var bad_path := "user://verify-menu-invalid.crateri"
	assert(map_data.save_map(map_path, terrain, game.template_spawns).is_empty())
	var definitions: Array[Dictionary] = game.weapons.duplicate(true)
	definitions[0]["name"] = "Menu test"
	assert(arsenal_data.save_preset(preset_path, definitions, menu.rules).is_empty())
	menu.load_map(map_path)
	menu.load_preset(preset_path)
	assert(menu.image.get_pixel(500, 300).a > 0.5 and menu.rules["team_size"] == 3 and menu.weapons[0]["name"] == "Menu test")
	assert(game.units.size() == 2 and game.weapons[0]["name"] != "Menu test")
	menu.start_match()
	assert(not menu.opened and game.has_match and game.hud.visible)
	assert(game.units.size() == 6 and game.units[0]["hp"] == 175 and game.turn_time == 45)
	assert(not game.rules["self_damage"] and game.weapons[0]["name"] == "Menu test" and game.solid(Vector2(500, 300)))
	game.reset_game()
	assert(game.units.size() == 6 and game.units[0]["hp"] == 175)
	game.select_weapon(1)
	game.shoot()
	var flight: float = game.flight_time
	var position: Vector2 = game.projectile
	var velocity: Vector2 = game.projectile_velocity
	game.open_menu()
	game._physics_process(4.0)
	game.shoot()
	game.request_jump()
	game.select_weapon(0)
	assert(game.flying and game.flight_time == flight and game.projectile == position and game.projectile_velocity == velocity, "Pausa esatta di volo e miccia")
	assert(game.units[game.active]["weapon"] == 1 and game.units[game.active]["jump_buffer"] == 0.0)
	menu.team_field.value = 2
	menu.resume_match()
	assert(not menu.opened and game.units.size() == 6 and game.flying, "Riprendi non applica le scelte della nuova partita")
	game._physics_process(1.0 / 60.0)
	assert(game.flight_time > flight, "Il tiro riparte dopo Riprendi")
	game.reset_game()
	game.open_map_editor()
	game.map_editor.close_editor()
	game.open_arsenal_editor()
	game.arsenal_editor.close_editor()
	game.open_menu()
	menu.start_match()
	assert(game.units.size() == 4 and game.map_editor.image == null and not game.arsenal_editor.initialized, "Nuova partita inizializza gli editor sulla nuova selezione")
	for unit in game.units:
		if unit["team"] == 1:
			unit["hp"] = 0
	game.check_winner()
	game.open_menu()
	assert(menu.resume_button.text.contains("risultato"))
	menu.resume_match()
	assert(not game.winner.is_empty(), "Ritorno al risultato senza riavvio")
	game.open_menu()
	var file := FileAccess.open(bad_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	menu.load_map(bad_path)
	menu.load_preset(map_path)
	assert(menu.image.get_pixel(500, 300).a > 0.5 and menu.weapons[0]["name"] == "Menu test", "Caricamenti falliti conservano le scelte")
	var tiny := Image.create_empty(1100, 700, false, Image.FORMAT_RGBA8)
	tiny.fill_rect(Rect2i(186, 500, 28, 10), Color.WHITE)
	tiny.fill_rect(Rect2i(886, 500, 28, 10), Color.WHITE)
	var anchors := PackedVector2Array([Vector2(200, 487), Vector2(900, 487)])
	assert(map_data.save_map(map_path, tiny, anchors).is_empty())
	menu.load_map(map_path)
	menu.team_field.value = 3
	assert(menu.start_button.disabled)
	var old_terrain: PackedByteArray = game.map_template.get_data()
	menu.start_match()
	assert(menu.opened and game.map_template.get_data() == old_terrain, "Mappa troppo stretta non sostituisce la partita")
	menu.team_field.value = 1
	assert(not menu.start_button.disabled)
	menu.use_default_map()
	menu.use_default_preset()
	assert(menu.rules["team_size"] == 1 and menu.rules["starting_health"] == 100 and menu.weapons[0]["name"] != "Menu test")
	menu.start_match()
	assert(game.winner.is_empty() and game.units.size() == 2)
	game.apply_arsenal(initial_weapons, initial_rules)
	DirAccess.remove_absolute(map_path)
	DirAccess.remove_absolute(preset_path)
	DirAccess.remove_absolute(bad_path)
	print("PASS: menu iniziale, caricamento mappa/configurazione, scelte separate, pausa volo/miccia, ripresa, nuova partita, risultato, errori e spazio")

func verify_packages(game) -> void:
	var package = load("res://src/data/package_data.gd")
	var original_weapons: Array[Dictionary] = game.weapons.duplicate(true)
	var original_rules: Dictionary = game.rules.duplicate(true)
	classic_reset(game)
	game.open_menu()
	var menu = game.menu
	var terrain: Image = game.map_template.duplicate()
	terrain.set_pixel(500, 300, Color("ad45da"))
	var definitions: Array[Dictionary] = original_weapons.duplicate(true)
	definitions[0]["name"] = "Sfera lunare"
	definitions[0]["damage"] = 91
	definitions[0]["gravity_scale"] = 0.5
	definitions[1]["fuse"] = 4.5
	definitions[1]["color"] = "88aaff"
	var settings: Dictionary = game.ArsenalData.sanitize_rules({"team_size": 3, "starting_health": 180, "turn_seconds": 55, "self_damage": false})
	menu.prepare(terrain, game.template_spawns, definitions, settings)
	var path := "user://verify-package.crateripack"
	var invalid := "user://verify-package-invalid.crateripack"
	menu.export_to("user://verify-package")
	assert(FileAccess.file_exists(path), "Estensione del pacchetto aggiunta all'esportazione")
	var result: Dictionary = package.load_package(path)
	assert(result["error"].is_empty())
	assert(result["image"].get_data() == terrain.get_data() and result["spawns"] == game.template_spawns, "Terreno e partenze identici nel pacchetto")
	assert(result["weapons"][0]["name"] == "Sfera lunare" and result["weapons"][0]["damage"] == 91 and result["weapons"][1]["fuse"] == 4.5)
	assert(result["rules"] == settings, "Regole complete nel pacchetto")
	assert(package.save_package(path, terrain, game.template_spawns, definitions, settings).is_empty(), "Sovrascrittura pacchetto")
	var fresh = load("res://main.tscn").instantiate()
	root.add_child(fresh)
	fresh.set_physics_process(false)
	fresh.menu.load_package(path)
	assert(fresh.menu.rules["team_size"] == 3 and fresh.menu.image.get_data() == terrain.get_data(), "Caricamento in una nuova sessione senza altri file")
	fresh.menu.start_match()
	assert(fresh.units.size() == 6 and fresh.units[0]["hp"] == 180 and fresh.turn_time == 55)
	assert(fresh.weapons[0]["name"] == "Sfera lunare" and not fresh.rules["self_damage"])
	fresh.queue_free()
	menu.use_default_map()
	menu.use_default_preset()
	var paused_terrain: PackedByteArray = game.map_template.get_data()
	menu.load_package(path)
	assert(game.map_template.get_data() == paused_terrain and game.rules == original_rules, "Caricare il pacchetto non cambia la partita in pausa")
	assert(menu.map_name == path.get_file() and menu.preset_name == path.get_file())
	var valid_data := {"format": "crateri-package", "version": 1, "map": package.MapData.encode_map(terrain, game.template_spawns), "arsenal": package.ArsenalData.encode_preset(definitions, settings)}
	var file := FileAccess.open(invalid, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	menu.load_package(invalid)
	assert(menu.image.get_data() == terrain.get_data() and menu.rules == settings, "Pacchetto interrotto conserva la scelta completa")
	var unsupported := valid_data.duplicate(true)
	unsupported["version"] = 999
	assert(not package.decode_package(unsupported)["error"].is_empty(), "Versione sconosciuta rifiutata")
	var incomplete := valid_data.duplicate(true)
	incomplete.erase("arsenal")
	assert(not package.decode_package(incomplete)["error"].is_empty(), "Pacchetto incompleto rifiutato")
	var bad_image := valid_data.duplicate(true)
	bad_image["map"]["terrain_png"] = "AAAA"
	assert(not package.decode_package(bad_image)["error"].is_empty(), "PNG non valido rifiutato")
	var bad_position := valid_data.duplicate(true)
	bad_position["map"]["spawns"][0] = [200, 650]
	assert(not package.decode_package(bad_position)["error"].is_empty(), "Partenza non valida rifiutata")
	var tiny := Image.create_empty(1100, 700, false, Image.FORMAT_RGBA8)
	tiny.fill_rect(Rect2i(186, 500, 28, 10), Color.WHITE)
	tiny.fill_rect(Rect2i(886, 500, 28, 10), Color.WHITE)
	var anchors := PackedVector2Array([Vector2(200, 487), Vector2(900, 487)])
	var incompatible := valid_data.duplicate(true)
	incompatible["map"] = package.MapData.encode_map(tiny, anchors)
	assert(not package.decode_package(incompatible)["error"].is_empty(), "Mappa e numero di personaggi incompatibili rifiutati")
	assert(not package.save_package(path, tiny, anchors, definitions, settings).is_empty())
	assert(package.load_package(path)["error"].is_empty(), "Esportazione non valida conserva il pacchetto precedente")
	file = FileAccess.open(invalid, FileAccess.WRITE)
	file.store_string(JSON.stringify(incomplete))
	file.close()
	menu.load_package(invalid)
	assert(menu.weapons[0]["name"] == "Sfera lunare" and menu.rules == settings and menu.image.get_data() == terrain.get_data())
	# Limite verificato prima della lettura e della decodifica.
	file = FileAccess.open(invalid, FileAccess.WRITE)
	var oversized := PackedByteArray()
	oversized.resize(package.MAX_BYTES + 1)
	file.store_buffer(oversized)
	file.close()
	assert(not package.load_package(invalid)["error"].is_empty(), "File troppo grande rifiutato")
	menu.start_match()
	assert(game.units.size() == 6 and game.units[0]["hp"] == 180 and game.solid(Vector2(500, 300)), "Avvio dalla selezione del pacchetto")
	# L'esportazione non è un salvataggio dei crateri e delle vite della partita.
	game.explode(Vector2(500, 300))
	game.units[0]["hp"] = 1
	game.open_menu()
	menu.export_to(path)
	var clean: Dictionary = package.load_package(path)
	assert(clean["image"].get_data() == terrain.get_data() and clean["rules"]["starting_health"] == 180)
	menu.use_default_map()
	menu.use_default_preset()
	menu.start_match()
	game.apply_arsenal(original_weapons, original_rules)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(invalid)
	print("PASS: pacchetto autonomo, terreno/partenze/armi/regole, nuova sessione, avvio, sovrascrittura, conservazione scelte, file invalidi/versione/dimensione, mappa incompatibile")




func classic_reset(game) -> void:
	# Verifica il generatore reale, poi usa Colline per le vecchie coordinate note.
	game.restore_default_map()
	assert(game.TeamSpawns.MapData.validate(game.map_template, game.template_spawns).is_empty())
	game.map_template = game.generate_classic_ground()
	game.template_spawns = PackedVector2Array([game.TeamSpawns.MapData.find_spawn(game.map_template, Vector2(210, 174)), game.TeamSpawns.MapData.find_spawn(game.map_template, Vector2(890, 174))])
	game.reset_game()
	game.sync_menu_to_match()





