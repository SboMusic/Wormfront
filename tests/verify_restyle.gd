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
	assert(game.terrain_sprite.material is ShaderMaterial)
	assert(game.scenery.texture != null)
	assert(game.PaintedArt.character().get_image().get_pixel(0,0).a == 0)
	for kind in ["projectile","bomb","beam","scatter","drill"]:
		var icon: Texture2D = game.WeaponArt.icon(kind,0,Color.WHITE)
		assert(icon.get_width() > 50 and icon.get_height() > 50)
	var before: Image = game.ground.duplicate()
	game.queue_redraw()
	await process_frame
	assert(before.get_data() == game.ground.get_data(), "Rendering non modifica la maschera fisica")
	var point := Vector2(-1,-1)
	for x in range(50,game.W-50,8):
		for y in range(100,game.H-100,8):
			if game.solid(Vector2(x,y)):
				point = Vector2(x,y)
				break
		if point.x >= 0:
			break
	assert(point.x >= 0)
	game.explode(point)
	assert(not game.solid(point))
	assert(game.terrain_sprite.texture == game.ground_texture)
	# Il renderer Dummy senza display non aggiorna i dati GPU riletti da get_image.
	# La prova con finestra verifica anche la texture effettivamente renderizzata.
	if DisplayServer.get_name() != "headless":
		await process_frame
		assert(game.terrain_sprite.texture.get_image().get_pixelv(Vector2i(point)).a == 0)
	for frame in range(600):
		game._physics_process(1.0/60)
		if not game.flying and not game.settling:
			break
	game.open_map_editor()
	assert(not game.map_editor.image.is_empty())
	game.audio.stop_all()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	print("PASS RESTYLE: painted assets, transparent character, weapon families, separate terrain shader, unchanged physics mask and visible crater alpha")
	quit()
