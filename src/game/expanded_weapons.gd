# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends RefCounted
static func steer(velocity: Vector2, point: Vector2, target: Vector2, dt: float) -> Vector2:
	if target.distance_to(point) < 1 or velocity.length() < 1:
		return velocity
	var angle := velocity.angle()
	var change := clampf(angle_difference(angle,(target-point).angle()),-2.0*dt,2.0*dt)
	return Vector2.from_angle(angle+change)*maxf(250,velocity.length())
static func nearest_enemy(game: Node) -> Vector2:
	var origin: Vector2 = game.units[game.active]["pos"]
	var target: Vector2 = origin+game.direction()*400
	var best := INF
	for unit in game.units:
		if unit["hp"]>0 and unit["team"] != game.units[game.active]["team"] and origin.distance_to(unit["pos"])<best:
			target=unit["pos"]
			best=origin.distance_to(target)
	return target
static func landing(game: Node) -> Vector2:
	if game.aim_target.x<game.R or game.aim_target.x>game.W-game.R:
		return Vector2(-1,-1)
	var point: Vector2 = game.TeamSpawns.MapData.find_spawn(game.ground,Vector2(game.aim_target.x,maxf(64,game.aim_target.y)))
	if point.x<0:
		return point
	for unit in game.units:
		if unit["hp"]>0 and point.distance_to(unit["pos"])<game.R*2.5:
			return Vector2(-1,-1)
	return point
static func special(game: Node, weapon: Dictionary) -> bool:
	var origin: Vector2 = game.units[game.active]["pos"]
	if weapon["kind"] == "teleport":
		game.units[game.active]["pos"]=landing(game)
		game.units[game.active]["vel"]=Vector2.ZERO
		game.finish_shot()
		return true
	if weapon["kind"] == "melee":
		for index in range(game.units.size()):
			var unit: Dictionary=game.units[index]
			var offset: Vector2=Vector2(unit["pos"])-origin
			if index!=game.active and unit["hp"]>0 and offset.length()<float(weapon["damage_radius"]) and offset.dot(game.direction())>0:
				if unit["team"]!=game.units[game.active]["team"] or game.rules["self_damage"]:
					unit["hp"]=maxi(0,int(unit["hp"])-int(weapon["damage"]))
				unit["vel"]=game.direction()*float(weapon["impulse"])+Vector2(0,-120)
		game.traces.append(PackedVector2Array([origin,origin+game.direction()*float(weapon["damage_radius"])]))
		game.blast_time=.4
		game.finish_shot()
		return true
	if weapon["kind"] == "airstrike":
		var count := maxi(1,int(weapon["cluster"]))
		for i in range(count):
			var point:=Vector2(clampf(game.aim_target.x+(i-(count-1)/2.0)*58,25,game.W-25),35-i*12)
			add_fragment(game,point,Vector2(20,170),weapon)
		game.finish_shot()
		return true
	return false
static func add_fragment(game: Node, point: Vector2, velocity: Vector2, weapon: Dictionary) -> void:
	var child:=weapon.duplicate(true)
	child["cluster"]=0
	child["trigger"]="impact"
	game.secondary_projectiles.append({"pos":point,"vel":velocity,"age":0.0,"weapon":child})
static func burst(game: Node, point: Vector2, weapon: Dictionary) -> void:
	var count:=int(weapon.get("cluster",0))
	if count<=0 or weapon["kind"]=="airstrike":
		return
	var child:=weapon.duplicate(true)
	child["damage"]=float(weapon["damage"])*.65
	child["crater_radius"]=float(weapon["crater_radius"])*.65
	child["damage_radius"]=float(weapon["damage_radius"])*.7
	for i in range(count):
		var direction:=Vector2.from_angle(-PI+PI*(i+1)/(count+1))
		add_fragment(game,point+Vector2(0,-7),direction*230,child)
static func update_fragments(game: Node, delta: float) -> void:
	for index in range(game.secondary_projectiles.size()-1,-1,-1):
		var piece: Dictionary=game.secondary_projectiles[index]
		piece["age"]+=delta
		var velocity: Vector2=piece["vel"]
		var point: Vector2=piece["pos"]
		var steps:=maxi(1,ceili((velocity.length()+game.GRAVITY*delta)*delta/2))
		var hit:=false
		for step in range(steps):
			velocity.y+=game.GRAVITY*delta/steps
			point+=velocity*delta/steps
			if game.projectile_blocked(point):
				hit=true
				break
			for unit in game.units:
				if unit["hp"]>0 and point.distance_to(unit["pos"])<game.R+3:
					hit=true
		piece["pos"]=point
		piece["vel"]=velocity
		if hit or float(piece["age"])>6 or point.y>game.H or point.x<0 or point.x>game.W:
			game.secondary_projectiles.remove_at(index)
			if hit:
				game.explode(point,piece["weapon"])

