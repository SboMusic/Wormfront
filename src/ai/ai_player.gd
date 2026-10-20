# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Ricerca a budget per fotogramma sulla maschera reale, senza bloccare il gioco.
var elapsed := 0.0
var cursor := 0
var best: Dictionary = {}
var candidates: Array[Dictionary] = []
var walk_axis := 0.0

func reset() -> void:
	elapsed = 0
	cursor = 0
	candidates.clear()
	walk_axis = 0
	best = {"score": -INF, "angle": 45.0, "power": 380.0, "facing": -1.0, "weapon": 0}

func update(game: Node, delta: float) -> void:
	elapsed += delta
	walk_axis = 0
	if elapsed < 0.65:
		var origin: Vector2 = game.units[game.active]["pos"]
		var objective := origin
		var closest := INF
		for crate in game.crates:
			var useful: bool = crate["kind"] == "weapon" or game.units[game.active]["hp"] < game.units[game.active]["max_hp"]
			if useful and crate["landed"] and origin.distance_to(crate["pos"]) < closest:
				objective = crate["pos"]
				closest = origin.distance_to(objective)
		if closest == INF:
			for unit in game.units:
				if unit["hp"] > 0 and unit["team"] == 0 and origin.distance_to(unit["pos"]) < closest:
					objective = unit["pos"]
					closest = origin.distance_to(objective)
		var side := signf(objective.x - origin.x)
		if absf(objective.x - origin.x) > 35 and not game.blocked(origin + Vector2(side * 18, 0)) and game.solid(origin + Vector2(side * 25, 20)):
			walk_axis = side
		return
	if candidates.is_empty():
		var origin: Vector2 = game.units[game.active]["pos"]
		var target: Vector2 = origin + Vector2.LEFT
		var distance := INF
		for unit in game.units:
			if unit["hp"] > 0 and unit["team"] != game.units[game.active]["team"] and origin.distance_to(unit["pos"]) < distance:
				target = unit["pos"]
				distance = origin.distance_to(target)
		var side := -1.0 if target.x < origin.x else 1.0
		for slot in range(game.weapons.size()):
			if game.weapons[slot]["kind"] in ["melee","teleport","airstrike","homing","controlled","placed"]:
				continue
			if game.ammo[1][slot] == 0:
				continue
			var level := int(game.rules.get("ai_level", 1))
			var angle_step: int = [20, 10, 5][level]
			var power_step: int = [150, 75, 40][level]
			for degrees in range(10, 86, angle_step):
				for strength in range(200, 651, power_step):
					candidates.append({"angle": float(degrees), "power": float(strength), "facing": side, "weapon": slot})
	for iteration in range(24):
		if cursor >= candidates.size():
			break
		var plan: Dictionary = candidates[cursor]
		cursor += 1
		var score := evaluate(game, plan)
		if score > float(best["score"]):
			best = plan.duplicate()
			best["score"] = score
	if elapsed > 1.2 and cursor >= candidates.size():
		if float(best["score"]) < -5:
			game.notice = "IA: nessun tiro sicuro, passo il turno"
			game.notice_time = 3.0
			game.next_turn()
			return
		var difficulty := int(game.rules.get("ai_level", 1))
		game.angle = clampf(float(best["angle"]) + (sin(game.turn_number * 2.7 + 1.0) * 7 if difficulty == 0 else 0), -80, 85)
		game.power = best["power"]
		game.facing = best["facing"]
		game.select_weapon(best["weapon"])
		game.shoot()

func evaluate(game: Node, plan: Dictionary) -> float:
	var weapon: Dictionary = game.weapons[plan["weapon"]]
	var origin: Vector2 = game.units[game.active]["pos"]
	var dir := Vector2(cos(deg_to_rad(plan["angle"])) * plan["facing"], -sin(deg_to_rad(plan["angle"])))
	var point := origin + dir * 19
	var velocity := dir * float(plan["power"])
	var instant: bool = weapon["kind"] in ["beam", "scatter"]
	var timed: bool = weapon["trigger"] == "fuse" and not instant
	var duration := float(weapon["fuse"]) if timed else 5.0
	for step in range(ceili(duration / 0.025)):
		var last := point
		if instant:
			point += dir * 8
		else:
			velocity.y += game.GRAVITY * float(weapon["gravity_scale"]) * 0.025
			point += velocity * 0.025
		if game.projectile_blocked(point):
			point = last
			if timed:
				var normal: Vector2 = game.terrain_normal(point)
				if normal.length_squared() < 0.1:
					normal = Vector2.UP
				velocity = velocity.bounce(normal) * float(weapon["bounce"])
			else:
				break
		var hit := false
		for unit in game.units:
			if unit["hp"] > 0 and unit != game.units[game.active] and point.distance_to(unit["pos"]) < 16:
				hit = true
				break
		if hit and not timed:
			break
		if point.y > game.H or point.x < 0 or point.x > game.W:
			return -100.0
	var score := -1.0 - float(plan["weapon"]) * 0.01
	for unit in game.units:
		if unit["hp"] <= 0:
			continue
		var damage := float(weapon["damage"]) * maxf(0, 1 - point.distance_to(unit["pos"]) / float(weapon["damage_radius"]))
		if unit["team"] == game.units[game.active]["team"]:
			score -= damage * 2.2
		else:
			score += minf(damage, unit["hp"]) + (20 if damage >= unit["hp"] else 0)
	return score




