# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	root.position = Vector2i(-12000,-12000)
	await process_frame
	await process_frame
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/menu-native-0.14.png")
	game.menu.start_match()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/game-native-0.14.png")
	game.toggle_help()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/help-native-0.14.png")
	game.toggle_help()
	game.open_map_editor()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/editor-native-0.14.png")
	game.audio.stop_all()
	await create_timer(0.2).timeout
	quit()

