# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var generator = load("res://src/world/world_generator.gd")
	var textures: Array[ImageTexture] = []
	var labels: Array[String] = []
	for i in range(6):
		var result: Dictionary = generator.generate(i + 4, 73)
		textures.append(ImageTexture.create_from_image(result["image"]))
		labels.append(result["family"])
	var canvas := Node2D.new()
	root.add_child(canvas)
	canvas.draw.connect(func():
		canvas.draw_rect(Rect2(0, 0, 1100, 700), Color("102035"))
		canvas.draw_string(ThemeDB.fallback_font, Vector2(20, 30), "CRATERI 0.13 · SEI GEOMETRIE, VARIANTI CASUALI", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("61d9df"))
		for i in range(6):
			var origin := Vector2(20 + (i % 2) * 545, 58 + floori(i / 2.0) * 212)
			canvas.draw_rect(Rect2(origin, Vector2(520, 196)), Color("192c42"))
			canvas.draw_string(ThemeDB.fallback_font, origin + Vector2(10, 23), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
			canvas.draw_texture_rect(textures[i], Rect2(origin + Vector2(5, 28), Vector2(510, 162)), false)
	)
	canvas.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var target := args[0] if args.size() > 0 else "res://verifiche/mappe-varieta-0.13.png"
	root.get_texture().get_image().save_png(target)
	print("PASS SHOWCASE")
	quit()
