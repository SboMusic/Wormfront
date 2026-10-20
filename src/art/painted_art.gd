# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
const ROOT := "res://assets/art-018/"
static var sky: Texture2D
static var worm: Texture2D
static var atlas: Image
const SKIES := ["res://assets/art-018/twilight.png","res://assets/art-019/alpine.png","res://assets/art-019/desert.png"]
static var sky_index := -1
static func background() -> Texture2D:
	if sky == null:
		var preferences := ConfigFile.new()
		preferences.load("user://scenery.cfg")
		var previous: Variant = preferences.get_value("scenery","last",-1)
		var last := int(previous) if previous is int or previous is float else -1
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		sky_index = rng.randi_range(0,SKIES.size()-2) if last>=0 and last<SKIES.size() else rng.randi_range(0,SKIES.size()-1)
		if last>=0 and last<SKIES.size() and sky_index>=last:
			sky_index+=1
		sky = load(SKIES[sky_index])
		preferences.set_value("scenery","last",sky_index)
		preferences.save("user://scenery.cfg")
	return sky
static func character() -> Texture2D:
	if worm == null:
		worm = load(ROOT + "worm.png")
	return worm
static func weapon(kind: String, variant: int) -> ImageTexture:
	if atlas == null:
		var texture: Texture2D = load(ROOT + "weapons.png")
		atlas = texture.get_image()
	var slot := 1 if kind == "bomb" else (2 if kind == "beam" else (3 if kind == "scatter" else (4 if kind == "drill" else (5 if variant % 3 == 2 else 0))))
	var regions := [Rect2i(0,0,590,512),Rect2i(590,0,390,512),Rect2i(980,0,556,512),Rect2i(0,512,540,512),Rect2i(540,512,490,512),Rect2i(1030,512,506,512)]
	var cell := atlas.get_region(regions[slot])
	var used := cell.get_used_rect()
	if used.size.x > 0 and used.size.y > 0:
		cell = cell.get_region(used)
	return ImageTexture.create_from_image(cell)


