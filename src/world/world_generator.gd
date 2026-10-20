# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Sei geometrie differenti. Il seme controlla forme, aperture, spessori e collegamenti.
const MapData = preload("res://src/data/map_data.gd")
const TeamSpawns = preload("res://src/world/team_spawns.gd")
const WIDTH := 2200
const HEIGHT := 1100
const FAMILIES := ["Isole sospese", "Continente cavernoso", "Canyon e pilastri", "Rovine e torri", "Archi naturali", "Coste frantumate"]

static func generate(index: int, requested_seed: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	if requested_seed < 0:
		rng.randomize()
		rng.seed = rng.randi_range(0, 2147483647)
	else:
		rng.seed = requested_seed
	var used_seed := rng.seed
	rng.seed = used_seed ^ (index * 2654435761)
	var family := (index - 4) % FAMILIES.size()
	var image := preload("res://src/world/terrain_architecture.gd").create(family,rng)
	var phase := rng.randf_range(0,TAU)
	var anchors := choose_anchors(image)
	if anchors.is_empty():
		# Solo per geometrie troppo frammentate: due piccoli appoggi di recupero.
		for x in [320, 1600]:
			image.fill_rect(Rect2i(x, 520, 280, 40), Color.TRANSPARENT)
			image.fill_rect(Rect2i(x, 560, 280, 35), Color.WHITE)
		anchors = PackedVector2Array([Vector2(460, 547), Vector2(1740, 547)])
	var hue := rng.randf_range(0.055, 0.15) if family != 3 else 0.58
	for x in range(WIDTH):
		for y in range(64, 1020):
			if image.get_pixel(x, y).a < 0.5:
				continue
			var rx := fposmod(x + sin(y * 0.07 + phase) * 9 + floorf(y / 33.0) * 27, 68)
			var ry := fposmod(y + sin(x * 0.03) * 7, 33)
			var base := Color("a77549") if family in [0,3] else (Color("428bcc") if family in [1,4] else Color("b93426"))
			var color := base * (0.8+sin(x*.03+y*.09+phase)*.1)
			color.a=1.0
			if rx < 2 or ry < 2:
				color = color.darkened(0.4)
			elif ry < 5:
				color = color.lightened(0.18)
			if image.get_pixel(x, y - 1).a < 0.5:
				color = color.lightened(0.3)
			image.set_pixel(x, y, color)
	return {"image": image, "spawns": anchors, "seed": used_seed, "family": FAMILIES[family]}

static func column(image: Image, x: int, top: float, bottom: float, filled: bool) -> void:
	var first := clampi(ceili(top), 190, 620)
	var last := clampi(ceili(bottom), 190, 620)
	if last > first:
		image.fill_rect(Rect2i(x, first, 1, last - first), Color.WHITE if filled else Color.TRANSPARENT)

static func ellipse(image: Image, center: Vector2, radius: Vector2, filled: bool) -> void:
	for x in range(maxi(0, floori(center.x - radius.x)), mini(WIDTH, ceili(center.x + radius.x))):
		var portion := 1 - pow((x - center.x) / radius.x, 2)
		if portion <= 0:
			continue
		var dy := radius.y * sqrt(portion)
		column(image, x, center.y - dy, center.y + dy, filled)

static func slope(image: Image, from_x: int, to_x: int, from_y: float, to_y: float, thickness: float) -> void:
	for x in range(maxi(0, from_x), mini(WIDTH, to_x + 1)):
		var y := lerpf(from_y, to_y, float(x - from_x) / maxi(1, to_x - from_x))
		column(image, x, y, y + thickness, true)

static func choose_anchors(image: Image) -> PackedVector2Array:
	var candidates: Array[Vector2] = []
	for x in range(100, WIDTH - 100, 40):
		var point := MapData.find_spawn(image, Vector2(x, 64))
		if point.x >= 0:
			candidates.append(point)
	for left in candidates:
		for i in range(candidates.size() - 1, -1, -1):
			var right := candidates[i]
			if right.x - left.x < 600:
				continue
			var anchors := PackedVector2Array([left, right])
			if TeamSpawns.plan(image, anchors, 4)["error"].is_empty():
				return anchors
	return PackedVector2Array()







