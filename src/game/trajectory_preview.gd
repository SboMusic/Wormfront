# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
## Anteprime senza modifiche al mondo, campionate con gli stessi sottopassi del tiro.
var cache_key: Array = []
var cache: Array[PackedVector2Array] = []
func paths(game: Node) -> Array[PackedVector2Array]:
	var weapon: Dictionary = game.selected_weapon()
	var key := [game.angle, game.facing, game.power, game.units[game.active]["pos"], weapon.hash(), game.terrain_revision,game.aim_target]
	for unit in game.units:
		key.append(unit["pos"])
		key.append(unit["hp"])
	if key == cache_key:
		return cache
	cache_key = key
	cache = []
	if weapon["kind"] in ["melee","teleport","airstrike"]:
		return cache
	var origin: Vector2 = game.units[game.active]["pos"]
	var dir: Vector2 = game.direction()
	if weapon["kind"] in ["beam", "scatter"]:
		var count := 5 if weapon["kind"] == "scatter" else 1
		for pellet in range(count):
			var ray := dir.rotated((pellet - 2) * 0.055 if count > 1 else 0)
			var endpoint := origin
			for distance in range(1, game.W + 1):
				endpoint = origin + ray * distance
				if game.solid(endpoint) or hits_unit(game, endpoint, game.R) or endpoint.x < 0 or endpoint.x > game.W or endpoint.y > game.H-70:
					break
			cache.append(PackedVector2Array([origin + ray * 19, endpoint]))
		return cache
	var point: Vector2 = game.muzzle_position()
	var velocity := dir * float(game.power)
	if weapon["kind"]=="placed":
		velocity=Vector2.ZERO
	var path := PackedVector2Array([point])
	var timed: bool = weapon["trigger"] == "fuse"
	var duration := float(weapon["fuse"]) if timed else 12.0
	var gravity: float = game.GRAVITY * float(weapon["gravity_scale"])
	if weapon["kind"] in ["homing","controlled"]:
		gravity=0
	var elapsed := 0.0
	var resting := false
	while elapsed < duration:
		var dt := minf(1.0 / 60, duration - elapsed)
		elapsed += dt
		if weapon["kind"] in ["homing","controlled"]:
			velocity=game.Expanded.steer(velocity,point,game.aim_target,dt)
		if resting:
			break
		var steps := maxi(1, ceili((velocity.length() + gravity * dt) * dt / 1.5))
		for step in range(steps):
			velocity.y += gravity * dt / steps
			var candidate := point + velocity * dt / steps
			var terrain_hit: bool = game.projectile_blocked(candidate)
			var hit := terrain_hit or hits_unit(game, candidate, game.R + game.PROJECTILE_RADIUS, elapsed < 0.12)
			if terrain_hit and weapon["kind"] == "drill" and elapsed < 1.1:
				hit = false
			if hit:
				if not timed:
					path.append(point)
					cache.append(path)
					return cache
				var normal: Vector2 = game.terrain_normal(candidate) if terrain_hit else unit_normal(game, candidate)
				if normal.length_squared() < 0.1:
					normal = -velocity.normalized() if velocity.length() > 0 else Vector2.UP
				if velocity.dot(normal) < 0:
					velocity = velocity.bounce(normal) * float(weapon["bounce"])
				path.append(point)
				if terrain_hit and normal.y < -0.35 and velocity.length() < 35 and game.projectile_blocked(point + Vector2(0, 2)):
					resting = true
				break
			point = candidate
			if point.distance_to(path[-1]) > 10:
				path.append(point)
			if point.y > game.H + 10 or point.x < -100 or point.x > game.W + 100:
				path.append(point)
				cache.append(path)
				return cache
	path.append(point)
	cache.append(path)
	return cache

func hits_unit(game: Node, point: Vector2, radius: float, skip_shooter: bool = true) -> bool:
	for index in range(game.units.size()):
		if skip_shooter and index == game.active:
			continue
		if game.units[index]["hp"] > 0 and point.distance_to(game.units[index]["pos"]) < radius:
			return true
	return false

func unit_normal(game: Node, point: Vector2) -> Vector2:
	for unit in game.units:
		if unit["hp"] > 0 and point.distance_to(unit["pos"]) < 16:
			return (point - Vector2(unit["pos"])).normalized()
	return Vector2.UP


