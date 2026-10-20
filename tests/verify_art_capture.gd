# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.mode = Window.MODE_WINDOWED
	root.position = Vector2i(-12000,-12000)
	root.size = Vector2i(1920,1080)
	await process_frame
	await process_frame
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or false:
		push_error("Usare il gioco esportato e indicare la cartella delle catture.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(args[0])
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0].path_join("menu-windows-0.19.png"))
	game.menu.team_field.value = 3
	game.menu.start_match()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0].path_join("partita-windows-0.19.png"))
	game.set_physics_process(false)
	game.spawn_crate()
	game.update_crates(0.7)
	game.queue_redraw()
	game.picker.refresh(game.weapons, game.ammo[0], 0)
	game.picker.set_opened(true)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0].path_join("arsenale-windows-0.19.png"))
	game.picker.set_opened(false)
	game.overview = true
	game.view_zoom = game.overview_zoom()
	game.update_view(1)
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0].path_join("panoramica-windows-0.19.png"))
	game.overview = false
	game.view_zoom = 1.5 * game.display_density
	game.update_view(1)
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0].path_join("vermi-windows-0.19.png"))
	game.open_map_editor()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[0].path_join("editor-windows-0.19.png"))
	print("PASS CAPTURE EXPORT: menu, partita e editor dal programma Windows")
	quit(0)













