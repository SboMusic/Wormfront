# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
func _initialize() -> void:
	var saved:=ConfigFile.new()
	saved.load("user://scenery.cfg")
	var previous:=int(saved.get_value("scenery","last",-1))
	var art=load("res://src/art/painted_art.gd")
	var texture: Texture2D=art.background()
	assert(texture != null and art.sky_index != previous)
	assert(texture == art.background(),"Sfondo stabile durante la sessione")
	for path in art.SKIES:
		assert(load(path) is Texture2D)
	print("PASS WALLPAPER: ",previous," -> ",art.sky_index)
	quit()
