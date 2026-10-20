# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.menu.set_opened(false)
	game.set_physics_process(false)
	for family in range(6):
		var data: Dictionary = game.TerrainFactory.create(4+family, 73)
		var image: Image = data["image"]
		var upper := 0
		for x in range(0,2200,8):
			for y in range(80,190,4):
				if image.get_pixel(x,y).a > 0.5:
					upper += 1
		assert(upper > 40, "Terreno nella nuova fascia alta: %d" % family)
		game.apply_editor_map(image, data["spawns"])
		game.menu.set_opened(false)
		game.overview = true
		game.view_zoom = game.overview_zoom()
		game.update_view(1)
		assert(absf((game.H - 84) * game.view_zoom + game.view_offset.y - game.screen_size.y * 0.94) < 1)
		game.spawn_crate()
		assert(game.crates[-1]["pos"].y == 35)
		for frame in range(660):
			game.update_crates(1.0/60)
		for crate in game.crates:
			assert(not game.solid(crate["pos"]))
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("PASS COMPLEX MAPS: upper terrain, bottom water, supplies from sky in all six families")
	quit()

