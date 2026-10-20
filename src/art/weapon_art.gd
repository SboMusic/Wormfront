# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Sei illustrazioni dipinte condivise tra arsenale e arma equipaggiata.
static var cache: Dictionary = {}
static func icon(kind: String, variant: int, color: Color) -> ImageTexture:
	var key := kind + str(variant) + color.to_html()
	if not cache.has(key):
		cache[key] = preload("res://src/art/special_weapon_art.gd").icon(variant) if variant >= 24 else preload("res://src/art/painted_art.gd").weapon(kind,variant)
	return cache[key]

