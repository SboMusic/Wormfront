# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends Control
## Anteprima del calcolo dei danni, con le stesse distanze usate dal gioco.

const PREVIEW_SCALE := 0.85
var weapon: Dictionary = {}
var distance := 65.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_weapon(definition: Dictionary, target_distance: float) -> void:
	weapon = definition.duplicate(true)
	distance = target_distance
	queue_redraw()

func estimated_damage() -> int:
	if weapon.is_empty():
		return 0
	return int(float(weapon["damage"]) * clampf(1.0 - distance / float(weapon["damage_radius"]), 0.0, 1.0))

func _draw() -> void:
	if weapon.is_empty():
		return
	var center := Vector2(220, 200)
	var color := Color.html(String(weapon["color"]))
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1929"))
	for x in range(0, 440, 25):
		draw_line(Vector2(x, 15), Vector2(x, 395), Color(1, 1, 1, 0.035))
	draw_circle(center, float(weapon["crater_radius"]) * PREVIEW_SCALE, Color(color, 0.3))
	draw_arc(center, float(weapon["crater_radius"]) * PREVIEW_SCALE, 0, TAU, 96, color, 2)
	draw_arc(center, float(weapon["damage_radius"]) * PREVIEW_SCALE, 0, TAU, 96, Color("ffad68"), 1.5)
	draw_circle(center, 5, color)
	var target := center + Vector2(distance * PREVIEW_SCALE, 0)
	draw_line(center, target, Color(1, 1, 1, 0.5), 1)
	draw_circle(target, 10, Color("58d7da"))
	draw_circle(target + Vector2(-3, -2), 2, Color.WHITE)
	draw_circle(target + Vector2(3, -2), 2, Color.WHITE)
	var font := get_theme_default_font()
	draw_string(font, Vector2(12, 24), "ANTEPRIMA ESPLOSIONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(font, Vector2(12, 369), "Disco colorato: cratere  •  Cerchio arancio: danno", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("bdcbd9"))
	draw_string(font, Vector2(12, 391), "Bersaglio a %d px  →  %d punti danno" % [int(distance), estimated_damage()], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
