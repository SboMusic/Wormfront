# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/menu-0.12.png")
	game.menu.team_field.value = 3
	game.menu.start_match()
	game.spawn_crate()
	game.update_crates(0.7)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/partita-0.12.png")
	game.picker.refresh(game.weapons, game.ammo[0], 0)
	game.picker.set_opened(true)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/arsenale-0.12.png")
	game.picker.set_opened(false)
	game.open_arsenal_editor()
	game.arsenal_editor.switch_weapon(7)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verifiche/editor-0.12.png")
	print("PASS VISUAL 0.12")
	quit()


