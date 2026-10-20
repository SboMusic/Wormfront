# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
func _initialize() -> void:
	call_deferred("report")
func report() -> void:
	print("INITIAL ",root.mode," window ",root.size," visible ",root.get_visible_rect().size, " scale ",root.content_scale_factor)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920,1080)
	root.position = Vector2i(-12000,-12000)
	await process_frame
	await process_frame
	print("FORCED ",root.mode," window ",root.size," visible ",root.get_visible_rect().size)
	quit()
