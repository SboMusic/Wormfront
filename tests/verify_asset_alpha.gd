# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
func _initialize() -> void:
	for filename in ["worm.png","weapons.png","twilight.png"]:
		var image := Image.load_from_file("res://assets/art-018/"+filename)
		print(filename, " ",image.get_size()," corner=",image.get_pixel(0,0)," center=",image.get_pixel(image.get_width()/2,image.get_height()/2))
	quit()
