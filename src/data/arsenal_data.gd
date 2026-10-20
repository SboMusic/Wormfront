# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted

const WeaponCatalog = preload("res://src/data/weapon_catalog.gd")
const DEFAULT_RULES := {"starting_health": 100, "turn_seconds": 35, "self_damage": true, "team_size": 1, "ai_enabled": false, "supplies": true, "ai_level": 1, "scatter_spawns": false}

static func sanitize_rules(data: Variant) -> Dictionary:
	var result := DEFAULT_RULES.duplicate()
	if not data is Dictionary:
		return result
	for field in ["starting_health", "turn_seconds", "team_size", "ai_level"]:
		var value: Variant = data.get(field)
		if (value is int or value is float) and is_finite(float(value)):
			var low := 1.0 if field == "starting_health" else 10.0
			var high := 300.0 if field == "starting_health" else 120.0
			if field == "ai_level":
				low = 0.0
				high = 2.0
			if field == "team_size":
				low = 1.0
				high = 4.0
			result[field] = roundi(clampf(float(value), low, high))
	for field in ["ai_enabled", "supplies", "scatter_spawns"]:
		if data.get(field) is bool:
			result[field] = data[field]
	if data.get("self_damage") is bool:
		result["self_damage"] = data["self_damage"]
	return result

static func save_preset(path: String, weapons: Array[Dictionary], rules: Dictionary) -> String:
	var data := encode_preset(weapons, rules)
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return "Non riesco a scrivere qui. Scegli un'altra cartella."
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return "Scrittura non riuscita: la copia precedente è conservata."
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		return "Non riesco a completare il salvataggio. Scegli un altro nome."
	return ""

static func encode_preset(weapons: Array[Dictionary], rules: Dictionary) -> Dictionary:
	return {"format": "crateri-arsenal", "version": 1, "weapons": WeaponCatalog.sanitize(weapons), "rules": sanitize_rules(rules)}

static func load_preset(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Non riesco ad aprire questo file."}
	if file.get_length() > 65536:
		return {"error": "Il file è troppo grande per una configurazione."}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"error": "Il file è incompleto o danneggiato."}
	return decode_preset(parser.data)

static func decode_preset(data: Variant) -> Dictionary:
	if not data is Dictionary or data.get("format") != "crateri-arsenal" or data.get("version") != 1:
		return {"error": "Questo file non è una configurazione Crateri compatibile."}
	var weapons: Variant = data.get("weapons")
	if not weapons is Array or weapons.size() < 2 or weapons.size() > 64 or not weapons[0] is Dictionary or not weapons[1] is Dictionary or not data.get("rules") is Dictionary:
		return {"error": "La configurazione deve contenere da 2 a 64 armi e le regole."}
	for entry in weapons:
		if not entry is Dictionary:
			return {"error": "Arma non valida nella configurazione."}
	return {"error": "", "weapons": WeaponCatalog.sanitize(weapons), "rules": sanitize_rules(data["rules"])}




