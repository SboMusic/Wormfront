# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	assert(ProjectSettings.get_setting("application/config/name") == "Wormfront")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.menu.start_match()
	game.set_physics_process(false)
	var package = load("res://src/data/package_data.gd")
	var map = package.MapData.encode_map(game.map_template, game.template_spawns)
	var arsenal = package.ArsenalData.encode_preset(game.weapons, game.rules)
	assert(map["format"] == "wormfront-map")
	assert(arsenal["format"] == "wormfront-arsenal")
	var current = {"format":"wormfront-package", "version":1, "map":map, "arsenal":arsenal}
	assert(package.decode_package(current)["error"].is_empty())
	# Old serialized identifiers remain accepted; all newly saved data uses the new name.
	current["format"] = "crateri-package"
	current["map"]["format"] = "crateri-map"
	current["arsenal"]["format"] = "crateri-arsenal"
	assert(package.decode_package(current)["error"].is_empty())
	assert(not package.decode_package({"format":"unknown", "version":1})["error"].is_empty())
	game.queue_free()
	await process_frame
	print("PASS REBRAND: Wormfront identity, new formats and legacy map/arsenal/package compatibility")
	quit()
