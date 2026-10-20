# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends SceneTree
var failed := false
func check(condition: bool, message: String) -> void:
	if not condition:
		failed=true
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func arena(game) -> void:
	game.reset_game()
	game.ground.fill(Color.TRANSPARENT)
	game.ground.fill_rect(Rect2i(0,500,game.W,game.H-500),Color.WHITE)
	game.units[0]["pos"]=Vector2(250,487)
	game.units[1]["pos"]=Vector2(1400,487)
	game.aim_at(Vector2(900,440))
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.menu.team_field.value=1
	game.menu.ai_field.button_pressed=false
	game.menu.scatter_field.button_pressed=false
	game.menu.start_match()
	check(game.weapons.size()==36,"36 definizioni caricate")
	arena(game)
	game.select_weapon(25)
	game.angle=45
	game.shoot()
	var initial: Vector2=game.projectile_velocity
	game.update_projectile(.1)
	check(game.projectile_velocity!=initial,"Missile guidato modifica la direzione")
	var camera: Vector2=game.view_offset
	game.update_view(1)
	check(game.view_offset==camera,"Nessun inseguimento del missile")
	arena(game)
	game.select_weapon(26)
	game.shoot()
	var motion:=InputEventMouseMotion.new()
	var target:=Vector2(700,150)
	motion.position=target*game.view_zoom+game.view_offset
	game._unhandled_input(motion)
	check(game.aim_target.distance_to(target)<.1,"Telecomando segue il mouse durante il volo")
	arena(game)
	game.select_weapon(27)
	game.explode(Vector2(700,440),game.selected_weapon())
	check(game.secondary_projectiles.size()==5,"Grappolo genera cinque proiettili reali")
	for frame in range(600):
		game.Expanded.update_fragments(game,1.0/60)
	check(game.secondary_projectiles.is_empty(),"Frammenti terminano e colpiscono il terreno")
	arena(game)
	game.select_weapon(29)
	game.shoot()
	check(game.secondary_projectiles.size()==5,"Incursione crea cinque bombe dall'alto")
	for frame in range(900):
		game._physics_process(1.0/60)
		if not game.settling:
			break
	check(game.secondary_projectiles.is_empty() and not game.settling,"Incursione conclude il turno dopo l'ultima bomba")
	arena(game)
	game.select_weapon(35)
	game.aim_target=Vector2(900,550)
	var stock: int=game.ammo[0][35]
	game.shoot()
	check(game.ammo[0][35]==stock and not game.flying and not game.settling,"Teletrasporto invalido non consuma scorte")
	game.aim_target=Vector2(900,440)
	game.shoot()
	check(game.units[0]["pos"].distance_to(Vector2(900,487))<2 and game.ammo[0][35]==stock-1,"Teletrasporto valido trova l'appoggio e consuma una carica")
	arena(game)
	game.select_weapon(31)
	game.shoot()
	game.request_jump()
	game.update_unit(game.units[0],1.0/60)
	check(game.units[0]["vel"].y<0,"Fuga con salto durante la miccia della dinamite")
	arena(game)
	game.units[1]["pos"]=Vector2(300,487)
	game.select_weapon(33)
	game.shoot()
	check(game.units[1]["hp"]==75 and game.units[1]["vel"].x>400,"Mazza applica danno e spinta ravvicinata")
	var decoded: Dictionary=game.menu.PackageData.decode_package({"format":"wormfront-package","version":1,"map":game.TeamSpawns.MapData.encode_map(game.map_template,game.template_spawns),"arsenal":game.ArsenalData.encode_preset(game.weapons,game.rules)})
	check(decoded["error"].is_empty() and decoded["weapons"].size()==36 and decoded["weapons"][27]["cluster"]==5 and decoded["weapons"][25]["kind"]=="homing","Pacchetto conserva le nuove meccaniche")
	game.audio.stop_all()
	await create_timer(.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	print("PASS NEW WEAPONS: guidance, mouse control, cluster fragments, air strike, teleport validation, melee and roundtrip" if not failed else "FAIL NEW WEAPONS")
	quit(1 if failed else 0)
