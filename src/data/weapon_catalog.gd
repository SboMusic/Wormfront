# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Dati locali, senza caricamento di codice o risorse indicate dal file.

const DEFAULTS := [
	{"name": "Lanciaproiettili", "trigger": "impact", "damage": 65.0, "crater_radius": 54.0, "damage_radius": 95.0, "impulse": 260.0, "fuse": 0.0, "bounce": 0.0, "gravity_scale": 1.0, "color": "ffe39d"},
	{"name": "Granata", "trigger": "fuse", "damage": 80.0, "crater_radius": 64.0, "damage_radius": 110.0, "impulse": 290.0, "fuse": 3.0, "bounce": 0.55, "gravity_scale": 1.0, "color": "a8e77d"}
]
const LIMITS := {
	"damage": Vector2(1, 100), "crater_radius": Vector2(8, 120),
	"damage_radius": Vector2(16, 180), "impulse": Vector2(0, 500),
	"fuse": Vector2(1, 6), "bounce": Vector2(0, 0.85), "gravity_scale": Vector2(0.25, 2.0)
}

static func load_definitions() -> Array[Dictionary]:
	var file := FileAccess.open("res://data/weapons.json", FileAccess.READ)
	if file == null:
		return sanitize(null)
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return sanitize(null)
	return sanitize(parser.data)

static func sanitize(data: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var count := clampi(data.size(), 2, 64) if data is Array else DEFAULTS.size()
	for i in range(count):
		var weapon: Dictionary = DEFAULTS[i % DEFAULTS.size()].duplicate(true)
		weapon["kind"] = "projectile"
		weapon["ammo"] = -1
		weapon["category"] = "Artiglieria"
		weapon["cluster"] = 0
		if data is Array and i < data.size() and data[i] is Dictionary:
			var entry: Dictionary = data[i]
			if entry.get("kind") in ["projectile", "beam", "scatter", "drill", "homing", "controlled", "airstrike", "placed", "melee", "teleport"]:
				weapon["kind"] = entry["kind"]
			if entry.get("category") in ["Artiglieria", "Bombe", "Precisione", "Speciali"]:
				weapon["category"] = entry["category"]
			weapon["cluster"] = clampi(int(entry.get("cluster",0)),0,8) if entry.get("cluster",0) is int or entry.get("cluster",0) is float else 0
			var ammo: Variant = entry.get("ammo")
			if (ammo is float or ammo is int) and is_finite(float(ammo)):
				weapon["ammo"] = clampi(int(ammo), -1, 20)
			if entry.get("name") is String:
				var title: String = entry["name"].strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ")
				if not title.is_empty():
					weapon["name"] = title.left(24)
			if entry.get("trigger") in ["impact", "fuse"]:
				weapon["trigger"] = entry["trigger"]
			for field in LIMITS:
				var value: Variant = entry.get(field)
				if (value is float or value is int) and is_finite(float(value)):
					var bounds: Vector2 = LIMITS[field]
					weapon[field] = clampf(float(value), bounds.x, bounds.y)
			var color: Variant = entry.get("color")
			if color is String and Color.html_is_valid(color):
				weapon["color"] = Color.html(color).to_html(false)
		if weapon["kind"] in ["beam", "scatter"]:
			weapon["trigger"] = "impact"
		if weapon["trigger"] == "impact":
			weapon["fuse"] = 0.0
		else:
			weapon["fuse"] = clampf(float(weapon["fuse"]), 1.0, 6.0)
		result.append(weapon)
	return result


