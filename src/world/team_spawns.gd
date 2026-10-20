# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Le due partenze della mappa restano i punti di riferimento delle squadre.

const MapData = preload("res://src/data/map_data.gd")

static func plan(image: Image, anchors: PackedVector2Array, team_size: int) -> Dictionary:
	var error := MapData.validate(image, anchors)
	if not error.is_empty():
		return {"error": error}
	if team_size < 1 or team_size > 4:
		return {"error": "Scegli da 1 a 4 personaggi per squadra."}
	# Ordine alternato: T1, A1, T2, A2… Riserva prima entrambe le partenze.
	var positions := anchors.duplicate()
	var floor_cache: Dictionary = {}
	for member in range(1, team_size):
		for team in range(2):
			var found := Vector2(-1, -1)
			var outward := -1.0 if anchors[team].x < anchors[1 - team].x else 1.0
			for distance in range(42, 253, 14):
				for side in [outward, -outward]:
					var x: float = anchors[team].x + distance * side
					if x < 12 or x > image.get_width() - 12:
						continue
					if not floor_cache.has(x):
						floor_cache[x] = MapData.find_spawn(image, Vector2(x, 64))
					var candidate: Vector2 = floor_cache[x]
					if candidate.x < 0 or candidate.distance_to(anchors[team]) > 280:
						continue
					var free := true
					for occupied in positions:
						if candidate.distance_to(occupied) < 34:
							free = false
							break
					if free:
						found = candidate
						break
				if found.x >= 0:
					break
			if found.x < 0:
				var name := "Turchese" if team == 0 else "Arancio"
				return {"error": "%s: spazio insufficiente per %d personaggi. Allarga gli appoggi o riduci la squadra in F4." % [name, team_size]}
			positions.append(found)
	return {"error": "", "positions": positions}


static func scattered(image: Image, anchors: PackedVector2Array, team_size: int, seed_value: int = -1) -> Dictionary:
	var fallback := plan(image, anchors, team_size)
	if not fallback["error"].is_empty():
		return fallback
	var rng := RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	var pool: Array[Vector2] = []
	for x in range(30, image.get_width() - 30, 32):
		for y in range(64, image.get_height() - 96):
			var point := Vector2(x, y)
			if MapData.solid(image, point + Vector2(0, 13)) and not MapData.blocked(image, point) and MapData.blocked(image, point + Vector2(0, 1)):
				pool.append(point)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	var positions := PackedVector2Array()
	for member in range(team_size):
		for team in range(2):
			var chosen := Vector2(-1, -1)
			# Un avversario della coppia parte nello stesso settore, su un appoggio libero.
			for pass_index in range(2):
				for candidate in pool:
					var free := true
					for used in positions:
						if candidate.distance_to(used) < 55:
							free = false
							break
					if not free:
						continue
					if team == 0 and pass_index == 0:
						var layer := 0 if candidate.y < image.get_height() * 0.47 else (1 if candidate.y < image.get_height() * 0.69 else 2)
						if layer != member % 3:
							continue
					if team == 1 and pass_index == 0:
						var distance := candidate.distance_to(positions[-1])
						if distance < 80 or distance > 280:
							continue
					chosen = candidate
					break
				if chosen.x >= 0:
					break
			if chosen.x < 0:
				return fallback
			positions.append(chosen)
	return {"error": "", "positions": positions}



