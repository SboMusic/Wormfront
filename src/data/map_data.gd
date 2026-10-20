# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Un solo file con terreno PNG e due posizioni iniziali. Nessun codice incluso.

const WIDTH := 1100
const HEIGHT := 700
const RADIUS := 12.0
const MAX_FILE_BYTES := 8 * 1024 * 1024

static func solid(image: Image, point: Vector2) -> bool:
	var x := floori(point.x)
	var y := floori(point.y)
	return x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height() and image.get_pixel(x, y).a > 0.5

static func blocked(image: Image, point: Vector2) -> bool:
	if solid(image, point):
		return true
	for i in range(16):
		if solid(image, point + Vector2.from_angle(TAU * i / 16.0) * RADIUS):
			return true
	return false

static func spawn_error(image: Image, point: Vector2) -> String:
	if not point.is_finite() or point.x < RADIUS or point.x > image.get_width() - RADIUS or point.y < 64 or point.y > image.get_height() - 83:
		return "scegli una posizione nell'area di disegno"
	if blocked(image, point):
		return "la posizione è dentro il terreno"
	if not blocked(image, point + Vector2(0, 2)):
		return "manca un appoggio sotto il personaggio"
	return ""

static func validate(image: Image, spawns: PackedVector2Array) -> String:
	if image == null or not image.get_width() in [1100, 2200, 3300] or not image.get_height() in [700, 1100]:
		return "Dimensioni ammesse: 1100, 2200 o 3300 per 700 o 1100 pixel."
	if spawns.size() != 2:
		return "Servono due posizioni iniziali."
	for i in range(2):
		var error := spawn_error(image, spawns[i])
		if not error.is_empty():
			return ("Turchese: " if i == 0 else "Arancio: ") + error + "."
	if spawns[0].distance_to(spawns[1]) < RADIUS * 3:
		return "Le posizioni iniziali sono troppo vicine."
	return ""

static func find_spawn(image: Image, point: Vector2) -> Vector2:
	var p := Vector2(roundf(point.x), roundf(point.y))
	if p.x < RADIUS or p.x > image.get_width() - RADIUS or p.y < 64 or blocked(image, p):
		return Vector2(-1, -1)
	while p.y <= image.get_height() - 83:
		if blocked(image, p + Vector2(0, 1)):
			return p
		p.y += 1
	return Vector2(-1, -1)

static func save_map(path: String, image: Image, spawns: PackedVector2Array) -> String:
	var error := validate(image, spawns)
	if not error.is_empty():
		return error
	var data := encode_map(image, spawns)
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return "Non riesco a scrivere qui. Scegli un'altra cartella."
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return "Scrittura non riuscita: la copia precedente è conservata."
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		return "Non riesco a completare il salvataggio. Scegli un altro nome."
	return ""

static func encode_map(image: Image, spawns: PackedVector2Array) -> Dictionary:
	return {"format": "wormfront-map", "version": 1, "terrain_png": Marshalls.raw_to_base64(image.save_png_to_buffer()), "spawns": [[spawns[0].x, spawns[0].y], [spawns[1].x, spawns[1].y]]}

static func load_map(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Non riesco ad aprire questo file."}
	if file.get_length() > MAX_FILE_BYTES:
		return {"error": "Il file è troppo grande (massimo 8 MB)."}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"error": "Il file è incompleto o danneggiato."}
	return decode_map(parser.data)

static func decode_map(data: Variant) -> Dictionary:
	if not data is Dictionary or data.get("format") not in ["wormfront-map", "crateri-map"] or data.get("version") != 1:
		return {"error": "Questo file non è una mappa Wormfront compatibile."}
	var encoded: Variant = data.get("terrain_png")
	var entries: Variant = data.get("spawns")
	if not encoded is String or not entries is Array or entries.size() != 2:
		return {"error": "Mappa incompleta: terreno o posizioni mancanti."}
	var png := Marshalls.base64_to_raw(encoded)
	if png.size() < 24 or png.slice(0, 8) != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]):
		return {"error": "Il terreno salvato non è valido."}
	# Verifica le dimensioni prima di decomprimere il PNG.
	var width := int(png[16]) * 16777216 + int(png[17]) * 65536 + int(png[18]) * 256 + int(png[19])
	var height := int(png[20]) * 16777216 + int(png[21]) * 65536 + int(png[22]) * 256 + int(png[23])
	if not width in [1100, 2200, 3300] or not height in [700, 1100]:
		return {"error": "Le dimensioni del terreno non sono compatibili."}
	var image := Image.new()
	if image.load_png_from_buffer(png) != OK:
		return {"error": "Il terreno salvato è danneggiato."}
	image.convert(Image.FORMAT_RGBA8)
	var spawns := PackedVector2Array()
	for entry in entries:
		if not entry is Array or entry.size() != 2:
			return {"error": "Una posizione iniziale non è valida."}
		for coordinate in entry:
			if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)):
				return {"error": "Una posizione iniziale non è valida."}
		spawns.append(Vector2(float(entry[0]), float(entry[1])))
	var error := validate(image, spawns)
	if not error.is_empty():
		return {"error": error}
	return {"image": image, "spawns": spawns, "error": ""}



