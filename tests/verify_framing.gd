# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.match_menu.set_opened(false)
	game.set_physics_process(false)
	game.view_zoom = 0.45 * game.display_density
	game.update_view(1)
	assert(game.W * game.view_zoom >= game.screen_size.x - 49 * game.display_density)
	assert(616 * game.view_zoom + game.view_offset.y <= game.screen_size.y * 0.941)
	game.ground.fill(Color.TRANSPARENT)
	game.units[0]["pos"] = Vector2(-30,300)
	game.units[0]["vel"] = Vector2(-100,0)
	game.update_unit(game.units[0],1.0/60)
	assert(game.units[0]["hp"] == 0)
	game.units[1]["pos"] = Vector2(game.W+30,300)
	game.units[1]["vel"] = Vector2(100,0)
	game.update_unit(game.units[1],1.0/60)
	assert(game.units[1]["hp"] == 0)
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("PASS FRAMING AND BOTH SIDE ELIMINATIONS")
	quit()


