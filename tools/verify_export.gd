# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree

func _initialize() -> void:
	call_deferred("verify")

func fail(message: String) -> void:
	push_error(message)
	quit(1)

func verify() -> void:
	if OS.has_feature("editor"):
		fail("La verifica deve usare l'eseguibile esportato.")
		return
	if FileAccess.file_exists("res://tests/verify.gd") or DirAccess.dir_exists_absolute("res://tools") or DirAccess.dir_exists_absolute("res://tests") or DirAccess.dir_exists_absolute("res://docs"):
		fail("L'esportazione contiene file di sviluppo non necessari.")
		return
	if not FileAccess.file_exists("res://data/weapons.json"):
		fail("Il file dei dati delle armi non è incluso.")
		return
	var scene = load("res://main.tscn")
	if scene == null:
		fail("Scena principale assente nell'esportazione.")
		return
	var game = scene.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	if game.get("menu") == null or not game.menu.opened:
		fail("Il menu non si inizializza nel gioco esportato.")
		return
	if game.weapons.size() != 36 or game.weapons[0]["damage"] != 65:
		fail("I dati delle armi non sono inclusi correttamente.")
		return
	game.menu.scatter_field.button_pressed = false
	game.menu.ai_field.button_pressed = false
	game.menu.team_field.value = 3
	game.menu.start_match()
	if game.units.size() != 6:
		fail("Avvio con tre personaggi per squadra non riuscito.")
		return
	game.open_map_editor()
	if not game.map_editor.editing:
		fail("Editor mappe non disponibile.")
		return
	game.map_editor.remember()
	game.map_editor.paint_segment(Vector2(1100, 280), Vector2(1300, 280), false)
	game.map_editor.play_map()
	if not game.solid(Vector2(1200, 280)):
		fail("La mappa modificata non viene applicata.")
		return
	game.open_arsenal_editor()
	game.arsenal_editor.fields["damage"].value = 88
	game.arsenal_editor.apply_draft()
	if game.weapons[0]["damage"] != 88:
		fail("Editor armi non funzionante nell'esportazione.")
		return
	game.open_menu()
	var package_path := "user://verify-export-only.crateripack"
	game.menu.export_to(package_path)
	game.menu.use_default_map()
	game.menu.use_default_preset()
	game.menu.load_package(package_path)
	game.menu.start_match()
	if game.units.size() != 6 or game.weapons[0]["damage"] != 88 or not game.solid(Vector2(1200, 280)):
		fail("Pacchetto non esportato/caricato correttamente.")
		return
	DirAccess.remove_absolute(package_path)
	game.select_weapon(1)
	game.shoot()
	game.open_menu()
	var flight: float = game.flight_time
	game._physics_process(2.0)
	if game.flight_time != flight:
		fail("Pausa non funzionante.")
		return
	game.menu.resume_match()
	for frame in range(600):
		game._physics_process(1.0 / 60.0)
	if game.flying or game.active == 0:
		fail("Granata o cambio turno non funzionanti.")
		return
	game.reset_game()
	for unit in game.units:
		if unit["team"] == 1:
			unit["hp"] = 0
	game.check_winner()
	if game.winner.is_empty():
		fail("Vittoria non rilevata.")
		return
	print("PASS EXPORT: template autonomo, menu, armi JSON, squadre, entrambi gli editor, pacchetti, pausa, granata, turni e vittoria")
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(0)








