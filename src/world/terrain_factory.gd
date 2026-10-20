# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Maschere originali: tutta la roccia, incluse volte e isole, è distruttibile.
const MapData = preload("res://src/data/map_data.gd")
const NAMES := ["Colline", "Grotte di ambra", "Arcipelago", "Bastioni", "Cittadelle sospese", "Continente cavernoso", "Canyon e pilastri", "Rovine e torri", "Archi naturali", "Coste frantumate", "Isole sparse", "Grotte profonde", "Valle dei pilastri", "Rovine sospese", "Archi e anfratti", "Baia frantumata", "Isole gemelle", "Miniere", "Falesie e canyon", "Fortezze", "Volte di pietra", "Costa delle voragini", "Arcipelago remoto", "Caverne remote"]

const Generator = preload("res://src/world/world_generator.gd")

static func create(index: int, seed_value: int = -1) -> Dictionary:
	if index >= 4:
		return Generator.generate(index, seed_value)
	var image := Image.create_empty(1100, 700, false, Image.FORMAT_RGBA8)
	for x in range(1100):
		for y in range(174, 700):
			var p := Vector2(x, y)
			var filled := false
			if index == 1:
				var top := 350.0 + sin(x * 0.013) * 65.0 + sin(x * 0.028) * 24.0
				filled = y >= top
				# Due ampie camere con aperture laterali, più un arco centrale.
				if pow((x - 295.0) / 150.0, 2) + pow((y - 492.0) / 57.0, 2) < 1.0:
					filled = false
				if pow((x - 775.0) / 165.0, 2) + pow((y - 475.0) / 65.0, 2) < 1.0:
					filled = false
				if x > 475 and x < 620 and y > 425:
					filled = false
				if x > 245 and x < 340 and y > 490 and y < 615:
					filled = false
				if (x < 185 and absf(y - 495 + sin(x * 0.02) * 12) < 26) or (x > 900 and absf(y - 475 + sin(x * 0.016) * 13) < 28):
					filled = false
			elif index == 2:
				for island in [Vector4(190, 420, 180, 110), Vector4(555, 360, 155, 85), Vector4(900, 435, 180, 120), Vector4(520, 565, 230, 50)]:
					if pow((p.x - island.x) / island.z, 2) + pow((p.y - island.y) / island.w, 2) < 1.0:
						filled = true
				if x > 470 and x < 635 and y > 347 and y < 386:
					filled = false
			else:
				filled = y > 540 + sin(x * 0.018) * 24
				if (x > 110 and x < 370) or (x > 735 and x < 1000):
					filled = filled or y > 300 + sin(x * 0.03) * 12
				if ((x > 155 and x < 325) or (x > 780 and x < 955)) and y > 390 and y < 485:
					filled = false
				if x > 365 and x < 740 and y > 335 and y < 365:
					filled = true
			if filled:
				var seams := sin(x * 0.044 + sin(y * 0.065) * 1.9) + cos(y * 0.073 + sin(x * 0.012))
				var grain := float((x * 17 + y * 29) % 19) / 19.0
				var shade := clampf(0.44 + seams * 0.14 + grain * 0.045, 0.12, 0.85)
				var rock_x := fposmod(x + sin(y * 0.08) * 8 + floorf(y / 35.0) * 25, 70)
				var rock_y := fposmod(y + sin(x * 0.034) * 6, 35)
				var rock := Color("503b30").lerp(Color("ba8a51"), shade)
				if rock_x < 2 or rock_y < 2:
					rock = rock.darkened(0.42)
				elif rock_y < 5:
					rock = rock.lightened(0.17)
				image.set_pixel(x, y, rock)
	# Il mare è uno spazio vuoto reale; le coste restano modificabili nell'editor.
	for x in range(1100):
		for y in range(620, 700):
			image.set_pixel(x, y, Color.TRANSPARENT)
	for x in range(1100):
		for y in range(176, 619):
			if image.get_pixel(x, y).a > 0.5 and image.get_pixel(x, y - 2).a < 0.5:
				image.set_pixel(x, y, Color("d6be81"))
	var spawns := PackedVector2Array([MapData.find_spawn(image, Vector2(210, 174)), MapData.find_spawn(image, Vector2(890, 174))])
	return {"image": image, "spawns": spawns}




