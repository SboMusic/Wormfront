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
func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.weapons.size() == 36, "24 armi iniziali")
	check(game.menu.ai_field.button_pressed, "IA selezionabile e attiva inizialmente")
	for map_index in range(4):
		game.menu.use_terrain(map_index)
		for count in range(1, 5):
			game.menu.team_field.value = count
			check(not game.menu.start_button.disabled, "Mappa %d: %d membri" % [map_index, count])
	game.menu.scatter_field.button_pressed = false
	game.menu.team_field.value = 2
	game.menu.use_terrain(1)
	game.menu.start_match()
	check(game.units.size() == 4, "Squadre complete nella mappa complessa")
	var original: PackedByteArray = game.map_template.get_data()
	game.select_weapon(2)
	game.shoot()
	check(game.ammo[0][2] == 1 and game.flying, "Munizioni consumate al lancio")
	game.reset_game()
	check(game.ammo[0][2] == 2 and game.ground.get_data() == original, "Riavvio ripristina terreno e munizioni")
	game.ammo[0][2] = 0
	game.select_weapon(2)
	check(game.units[0]["weapon"] == 0, "Arma esaurita non selezionabile")
	game.picker.refresh(game.weapons, game.ammo[0], 0)
	check(game.picker.grid.get_child_count() == 36 and game.picker.grid.get_child(2).disabled, "Pannello con 24 armi e stato esaurito")
	game.picker.set_opened(true)
	game.picker.grid.get_child(6).pressed.emit()
	check(game.units[0]["weapon"] == 6 and not game.picker.opened, "Clic sulla tessera seleziona esattamente la sua arma")
	game.spawn_crate()
	check(game.crates.size() == 1 and game.crates[0]["chute"], "Cassa con paracadute")
	for frame in range(600):
		game.update_crates(1.0 / 60)
	check(game.crates.size() == 1 and game.crates[0]["landed"], "Cassa atterra sul terreno")
	var crate_position: Vector2 = game.crates[0]["pos"]
	game.carve(crate_position + Vector2(0, 20), 45)
	game.update_crates(0.1)
	check(game.crates[0]["pos"].y > crate_position.y, "Cassa ricade se il suolo viene scavato")
	game.crates.clear()
	game.units[0]["hp"] = 90
	check(game.collect_crate({"kind": "health"}, game.units[0]) and game.units[0]["hp"] == 100, "Salute limitata al massimo")
	check(not game.collect_crate({"kind": "health"}, game.units[0]), "Salute piena: cassa conservata")
	check(game.collect_crate({"kind": "weapon", "weapon": 2}, game.units[0]) and game.ammo[0][2] == 2 and game.ammo[1][2] == 2, "Munizioni assegnate soltanto alla squadra che raccoglie")
	game.reset_game()
	game.next_turn()
	game.next_turn()
	check(game.crates.size() == 1, "Rifornimento ogni due turni")
	game.open_menu()
	var p: Vector2 = game.crates[0]["pos"]
	game._physics_process(2)
	check(game.crates[0]["pos"] == p, "Pausa blocca le casse")
	game.menu.resume_match()
	# Arena nota: i due colpi istantanei devono danneggiare un bersaglio visibile.
	for slot in [4, 5]:
		game.reset_game()
		game.ground.fill(Color.TRANSPARENT)
		game.ground.fill_rect(Rect2i(0, 500, 1100, 200), Color.WHITE)
		game.units[0]["pos"] = Vector2(200, 487)
		game.units[1]["pos"] = Vector2(390, 487)
		game.angle = 0
		game.facing = 1
		game.select_weapon(slot)
		game.shoot()
		check(game.settling and game.units[1]["hp"] < 100, "Colpo istantaneo %d infligge danno" % slot)
	game.reset_game()
	game.ground.fill(Color.TRANSPARENT)
	game.ground.fill_rect(Rect2i(0, 500, 1100, 200), Color.WHITE)
	game.ground.fill_rect(Rect2i(230, 440, 30, 60), Color.WHITE)
	game.units[0]["pos"] = Vector2(200, 487)
	game.angle = 0
	game.select_weapon(6)
	game.shoot()
	for frame in range(20):
		game.update_projectile(1.0 / 60)
		if not game.flying:
			break
	check(not game.solid(Vector2(240, 487)), "Trivella scava durante il percorso")
	game.reset_game()
	game.ground.fill(Color.TRANSPARENT)
	game.ground.fill_rect(Rect2i(0, 500, 1100, 200), Color.WHITE)
	game.units[0]["pos"] = Vector2(300, 487)
	game.units[1]["pos"] = Vector2(800, 487)
	game.rules["ai_enabled"] = true
	game.next_turn()
	for frame in range(400):
		game._physics_process(1.0 / 60)
		if game.flying or game.settling:
			break
	check(game.flying or game.settling, "IA termina il calcolo e spara")
	game.open_menu()
	var ai_elapsed: float = game.ai.elapsed
	game._physics_process(1)
	check(game.ai.elapsed == ai_elapsed, "Pausa blocca anche il pianificatore IA")
	game.menu.resume_match()
	for frame in range(600):
		game._physics_process(1.0 / 60)
	var hurt := false
	for unit in game.units:
		if unit["team"] == 0 and unit["hp"] < 100:
			hurt = true
	check(hurt, "Il tiro IA danneggia un avversario in arena")
	var path := "user://verify-upgrade.crateripack"
	check(game.menu.PackageData.save_package(path, game.map_template, game.template_spawns, game.weapons, game.rules).is_empty(), "Salvataggio pacchetto esteso")
	var package: Dictionary = game.menu.PackageData.load_package(path)
	check(package["error"].is_empty() and package["weapons"].size() == 36 and package["rules"]["ai_enabled"], "24 armi e IA conservate nel pacchetto")
	check(package["weapons"][6]["kind"] == "drill" and package["weapons"][2]["ammo"] == 2, "Comportamenti e scorte iniziali conservati")
	DirAccess.remove_absolute(path)
	var legacy: Dictionary = game.ArsenalData.decode_preset({"format":"crateri-arsenal", "version":1, "weapons":[game.weapons[0],game.weapons[1]], "rules":{"starting_health":100}})
	check(legacy["error"].is_empty() and legacy["weapons"].size() == 2, "Compatibilità configurazioni precedenti")
	game.reset_game()
	var rewards: Array[int] = []
	for drop in range(12):
		game.spawn_crate()
		if game.crates[-1]["kind"] == "weapon":
			rewards.append(int(game.crates[-1]["weapon"]))
		game.crates.clear()
	check(rewards == [2, 3, 4, 5, 6, 7], "Tutte le sei armi limitate possono ricevere munizioni")
	print("PASS UPGRADE" if not failed else "FAIL UPGRADE")
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if failed else 0)






