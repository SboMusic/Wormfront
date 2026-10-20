# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.menu.scatter_field.button_pressed = false
	game.menu.ai_field.button_pressed = false
	game.menu.team_field.value = 1
	game.menu.start_match()
	for slot in range(game.weapons.size()):
		game.reset_game()
		game.ground.fill(Color.TRANSPARENT)
		game.ground.fill_rect(Rect2i(0,500,game.W,200),Color.WHITE)
		game.terrain_revision += 1
		game.units[0]["pos"] = Vector2(250,487)
		game.units[1]["pos"] = Vector2(1400,487)
		game.angle = 30
		game.power = 380
		game.aim_at(Vector2(900,440))
		game.select_weapon(slot)
		var stock: int = game.ammo[0][slot]
		game.shoot()
		for frame in range(1000):
			game._physics_process(1.0/60)
			if not game.flying and not game.settling:
				break
		if game.flying or game.settling or (game.winner.is_empty() and game.active != 1) or (stock >= 0 and game.ammo[0][slot] != stock - 1):
			failed = true
			push_error("Tiro completo non riuscito: " + game.weapons[slot]["name"])
	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("PASS ALL 36 WEAPONS" if not failed else "FAIL ALL WEAPONS")
	quit(1 if failed else 0)

