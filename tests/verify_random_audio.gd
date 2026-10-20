# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("verify")
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)
func mask_distance(a: Image, b: Image) -> float:
	var changed := 0
	var count := 0
	for x in range(0, a.get_width(), 8):
		for y in range(190, 620, 4):
			count += 1
			if (a.get_pixel(x, y).a > 0.5) != (b.get_pixel(x, y).a > 0.5):
				changed += 1
	return float(changed) / count
func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	var examples: Array[Image] = []
	for family in range(6):
		for seed_value in [73, 218, 619]:
			var result: Dictionary = game.TerrainFactory.create(4 + family, seed_value)
			var layout: Dictionary = game.TeamSpawns.plan(result["image"], result["spawns"], 4)
			check(layout["error"].is_empty(), "Famiglia %d seme %d: %s" % [family, seed_value, layout["error"]])
			var mixed: Dictionary = game.TeamSpawns.scattered(result["image"], result["spawns"], 4, seed_value)
			check(mixed["error"].is_empty() and mixed["positions"].size() == 8, "Otto personaggi sulla nuova geometria")
			for point in mixed["positions"]:
				check(game.TeamSpawns.MapData.spawn_error(result["image"], point).is_empty(), "Appoggio valido su tutte le nuove famiglie")
			if seed_value == 73:
				examples.append(result["image"])
			else:
				check(mask_distance(examples[family], result["image"]) > 0.045, "Il seme cambia la geometria, non solo i colori")
	for family in range(1, 6):
		check(mask_distance(examples[0], examples[family]) > 0.12, "Archetipi con forme diverse")
	var first: Dictionary = game.TerrainFactory.create(6, 12345)
	var repeat: Dictionary = game.TerrainFactory.create(6, 12345)
	check(first["image"].get_data() == repeat["image"].get_data(), "Seme riproducibile")
	game.menu.use_terrain(5)
	var previous: Image = game.menu.image.duplicate()
	game.menu.regenerate_terrain()
	check(mask_distance(previous, game.menu.image) > 0.03, "Rigenera produce una nuova geometria")
	game.menu.start_match()
	for unit in game.units:
		check(game.TeamSpawns.MapData.spawn_error(game.ground, unit["pos"]).is_empty(), "Partita usa appoggi della mappa generata")
	var path := "user://verify-random-audio.wormfrontpack"
	check(game.menu.PackageData.save_package(path, game.map_template, game.template_spawns, game.weapons, game.rules).is_empty(), "Salvataggio nuova mappa")
	var loaded: Dictionary = game.menu.PackageData.load_package(path)
	check(loaded["error"].is_empty() and loaded["image"].get_data() == game.map_template.get_data(), "Il pacchetto conserva il terreno esatto senza rigenerarlo")
	DirAccess.remove_absolute(path)
	var signatures: Array[int] = []
	for event in game.audio.sounds:
		var data: PackedByteArray = game.audio.sounds[event].data
		check(data.size() > 8000, "Campione audio presente: " + event)
		var peak := 0
		for i in range(0, data.size(), 2):
			peak = maxi(peak, absi(data.decode_s16(i)))
		check(peak > 100 and peak < 32767, "Audio non muto e senza clipping: " + event)
		signatures.append(hash(data))
	var unique := {}
	for signature in signatures:
		unique[signature] = true
	check(unique.size() == 8, "Otto effetti distinti")
	game.select_weapon(4)
	game.shoot()
	check(game.audio.cursor > 0, "Il tiro avvia suoni")
	game.audio.set_enabled(false)
	var cursor: int = game.audio.cursor
	game.audio.play_event("rocket")
	check(game.audio.cursor == cursor, "Disattivazione suoni")
	if DisplayServer.get_name() != "headless":
		game.audio.set_enabled(true)
		game.audio.play_event("beam")
		var voice: AudioStreamPlayer = game.audio.voices[(game.audio.cursor - 1) % game.audio.voices.size()]
		await create_timer(0.06).timeout
		check(voice.playing and voice.get_playback_position() > 0, "Riproduzione audio effettiva nel motore grafico")
		game.audio.set_paused(true)
		check(voice.stream_paused, "Pausa delle voci audio")
		game.audio.set_enabled(false)
		check(not voice.playing, "Mute ferma anche un suono in corso")
	print("PASS RANDOM AUDIO 0.13" if not failed else "FAIL RANDOM AUDIO 0.13")
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	quit(1 if failed else 0)




