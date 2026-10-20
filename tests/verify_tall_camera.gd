# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.menu.use_terrain(4)
	game.menu.start_match()
	game.set_physics_process(false)
	assert(game.H == 1100)
	game.overview = true
	game.view_zoom = game.overview_zoom()
	game.update_view(1)
	var offset: Vector2 = game.view_offset
	game.overview = false
	game.flying = true
	for point in [Vector2(100,-400),Vector2(2000,900),Vector2(500,400)]:
		game.projectile = point
		game.update_view(1)
		assert(game.view_offset == offset, "Camera ferma durante il tiro")
	game.flying = false
	game.settling = true
	game.update_view(1)
	assert(game.view_offset == offset, "Camera ferma durante la risoluzione")
	game.settling = false
	game.update_view(1)
	var path := "user://tall.crateri"
	assert(game.TeamSpawns.MapData.save_map(path,game.ground,game.template_spawns).is_empty())
	var data: Dictionary = game.TeamSpawns.MapData.load_map(path)
	assert(data["error"].is_empty() and data["image"].get_height() == 1100)
	game.open_map_editor()
	for point in [Vector2(1300,200), Vector2(1800,900)]:
		var canvas: Vector2 = game.map_editor.canvas_point(point)
		assert(game.map_editor.world_point(canvas).distance_to(point) < 0.01)
		game.map_editor.paint_segment(point,point,false)
		assert(game.map_editor.image.get_pixelv(Vector2i(point)).a > 0.5)
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("PASS TALL MAP: 1100 height, camera fixed during shot and settling, save/load, editor upper/lower painting")
	quit()
