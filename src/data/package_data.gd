# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Pacchetto autonomo: solo dati e PNG incorporato, senza percorsi da estrarre.

const MapData = preload("res://src/data/map_data.gd")
const ArsenalData = preload("res://src/data/arsenal_data.gd")
const TeamSpawns = preload("res://src/world/team_spawns.gd")
const MAX_BYTES := 9 * 1024 * 1024

static func save_package(path: String, image: Image, spawns: PackedVector2Array, weapons: Array[Dictionary], rules: Dictionary) -> String:
	var settings := ArsenalData.sanitize_rules(rules)
	var layout := TeamSpawns.plan(image, spawns, int(settings["team_size"]))
	if not layout["error"].is_empty():
		return layout["error"]
	var data := {"format": "wormfront-package", "version": 1, "map": MapData.encode_map(image, spawns), "arsenal": ArsenalData.encode_preset(weapons, settings)}
	var contents := JSON.stringify(data)
	if contents.to_utf8_buffer().size() > MAX_BYTES:
		return "Il pacchetto supera il limite di 9 MB."
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return "Non riesco a esportare qui. Scegli un'altra cartella."
	file.store_string(contents)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return "Esportazione non riuscita: la copia precedente è conservata."
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		return "Non riesco a completare l'esportazione. Scegli un altro nome."
	return ""

static func load_package(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Non riesco ad aprire questo pacchetto."}
	if file.get_length() > MAX_BYTES:
		return {"error": "Il pacchetto è troppo grande (massimo 9 MB)."}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"error": "Il pacchetto è incompleto o danneggiato."}
	return decode_package(parser.data)

static func decode_package(data: Variant) -> Dictionary:
	if not data is Dictionary or data.get("format") not in ["wormfront-package", "crateri-package"] or data.get("version") != 1:
		return {"error": "Questo file non è un pacchetto Wormfront compatibile."}
	var map := MapData.decode_map(data.get("map"))
	if not map["error"].is_empty():
		return {"error": "Mappa del pacchetto: " + map["error"]}
	var arsenal := ArsenalData.decode_preset(data.get("arsenal"))
	if not arsenal["error"].is_empty():
		return {"error": "Armi e regole del pacchetto: " + arsenal["error"]}
	var layout := TeamSpawns.plan(map["image"], map["spawns"], int(arsenal["rules"]["team_size"]))
	if not layout["error"].is_empty():
		return {"error": layout["error"]}
	return {"error": "", "image": map["image"], "spawns": map["spawns"], "weapons": arsenal["weapons"], "rules": arsenal["rules"]}
