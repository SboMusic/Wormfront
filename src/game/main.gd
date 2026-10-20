# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends Node2D
## Prototipo locale: maschera del terreno condivisa da grafica e collisioni.

var W := 1100
var H := 700
const R := 12.0
const GRAVITY := 420.0
const WALK_SPEED := 100.0
const WALK_ACCELERATION := 650.0
const JUMP_SPEED := 225.0
const STEP_HEIGHT := 5
const FLOOR_SNAP := 4
const WeaponCatalog = preload("res://src/data/weapon_catalog.gd")
const MapEditor = preload("res://src/editors/map_editor.gd")
const ArsenalEditor = preload("res://src/editors/arsenal_editor.gd")
const ArsenalData = preload("res://src/data/arsenal_data.gd")
const TeamSpawns = preload("res://src/world/team_spawns.gd")
const MatchMenu = preload("res://src/ui/match_menu.gd")
const PROJECTILE_RADIUS := 4.0
const COLORS := [Color("58d7da"), Color("ffad68")]
var ground: Image
var ground_texture: ImageTexture
var units: Array[Dictionary] = []
var active := 0
var team_cursor := PackedInt32Array([0, -1])
var angle := 45.0
var power := 380.0
var facing := 1.0
var projectile := Vector2.ZERO
var projectile_velocity := Vector2.ZERO
var flying := false
var settling := false
var settle_time := 0.0
var flight_time := 0.0
var turn_time := 35.0
var winner := ""
var blast_position := Vector2.ZERO
var blast_time := 0.0
var hud: Label
var help: Label
var weapons: Array[Dictionary] = []
var shot_weapon: Dictionary = {}
var projectile_resting := false
var blast_radius := 54.0
var map_template: Image
var template_spawns := PackedVector2Array()
var map_editor := MapEditor.new()
var arsenal_editor := ArsenalEditor.new()
var rules: Dictionary = ArsenalData.sanitize_rules(null)
var menu := MatchMenu.new()
var has_match := false
const TerrainFactory = preload("res://src/world/terrain_factory.gd")
const AIPlayer = preload("res://src/ai/ai_player.gd")
const WeaponPicker = preload("res://src/ui/weapon_picker.gd")
var ai := AIPlayer.new()
var picker := WeaponPicker.new()
var ammo: Array = [[], []]
var crates: Array[Dictionary] = []
var turn_number := 0
var supply_number := 0
var notice := ""
var notice_time := 0.0
var traces: Array[PackedVector2Array] = []
const GameAudio = preload("res://src/game/game_audio.gd")
var audio := GameAudio.new()
const TrajectoryPreview = preload("res://src/game/trajectory_preview.gd")
const WeaponArt = preload("res://src/art/weapon_art.gd")
var trajectory_preview := TrajectoryPreview.new()
var terrain_revision := 0
const Expanded = preload("res://src/game/expanded_weapons.gd")
var aim_target := Vector2(1100,400)
var secondary_projectiles: Array[Dictionary] = []
var arsenal_button: Button
var screen_size := Vector2(1600, 900)
var display_density := 1.0
var text_scale := 1.0
var help_open := false
var help_scroll: ScrollContainer
var action_row: HBoxContainer
var display_preferences := ConfigFile.new()
const PaintedArt = preload("res://src/art/painted_art.gd")
const VisualStyle = preload("res://src/art/visual_style.gd")
var scenery: TextureRect
var terrain_sprite: Sprite2D

func _ready() -> void:
	# Un'esecuzione senza display non ha una risoluzione del monitor da utilizzare.
	if DisplayServer.get_name() == "headless":
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = Vector2i(1600, 900)
	# Godot applica la modalita del progetto dopo le opzioni CLI: rispetta le prove in finestra.
	var args := OS.get_cmdline_args()
	if args.has("--windowed"):
		get_window().mode = Window.MODE_WINDOWED
		var resolution := args.find("--resolution")
		if resolution >= 0 and resolution + 1 < args.size():
			var parts := args[resolution + 1].split("x")
			if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
				get_window().size = Vector2i(int(parts[0]), int(parts[1]))
	load_display_preferences()
	prepare_painted_scene()
	add_child(audio)
	weapons = WeaponCatalog.load_definitions()
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(28, 20)
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_constant_override("line_spacing", 0)
	layer.add_child(hud)
	help = Label.new()
	help.position = Vector2(28, 634)
	help.text = "Mouse: mira · tieni clic sinistro: carica, rilascia: spara · trascina destro: potenza · M: arsenale\nRotella: zoom · C: panoramica · trascina rotella: visuale · A/D: muovi · Shift: salto · Q/E: potenza\n1–8: armi rapide · F2: mappe · F4: armi/regole · Invio: passa · R: ricomincia · Esc: pausa"
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_constant_override("line_spacing", 0)
	help_scroll = ScrollContainer.new()
	help_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	help_scroll.hide()
	layer.add_child(help_scroll)
	help_scroll.add_child(help)
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_game()
	add_child(map_editor)
	map_editor.close_requested.connect(close_map_editor)
	map_editor.play_requested.connect(apply_editor_map)
	add_child(arsenal_editor)
	arsenal_editor.close_requested.connect(close_map_editor)
	arsenal_editor.apply_requested.connect(apply_arsenal)
	add_child(picker)
	picker.chosen.connect(select_weapon)
	add_child(menu)
	menu.initialize(map_template, template_spawns, weapons)
	menu.start_requested.connect(start_menu_match)
	menu.resume_requested.connect(close_map_editor)
	arsenal_button = Button.new()
	arsenal_button.position = Vector2(856, 26)
	arsenal_button.size = Vector2(216, 38)
	arsenal_button.text = "Arsenale [M]"
	arsenal_button.focus_mode = Control.FOCUS_NONE
	action_row = HBoxContainer.new()
	layer.add_child(action_row)
	action_row.add_child(arsenal_button)
	add_display_button("Aiuto [F1]", toggle_help)
	add_display_button("A−", func(): set_text_scale(text_scale - 0.1))
	add_display_button("A+", func(): set_text_scale(text_scale + 0.1))
	arsenal_button.pressed.connect(toggle_picker)
	get_viewport().size_changed.connect(apply_display_layout)
	apply_display_layout()
	VisualStyle.apply_branch(self, VisualStyle.make_theme())
	apply_display_layout()
	call_deferred("apply_display_layout")
	open_menu()

func interaction_blocked() -> bool:
	return editor_active() or menu.opened or help_open

func open_menu() -> void:
	mouse_charging = false
	power_drag = false
	picker.set_opened(false)
	if editor_active():
		return
	action_row.hide()
	audio.set_paused(true)
	menu.show_menu(has_match, not winner.is_empty())
	hud.hide()
	help.hide()
	queue_redraw()

func start_menu_match(image: Image, positions: PackedVector2Array, definitions: Array[Dictionary], settings: Dictionary) -> void:
	var proposed := ArsenalData.sanitize_rules(settings)
	var layout := TeamSpawns.plan(image, positions, int(proposed["team_size"]))
	if not layout["error"].is_empty():
		menu.message.text = layout["error"]
		return
	map_template = image.duplicate()
	template_spawns = positions.duplicate()
	weapons = WeaponCatalog.sanitize(definitions)
	rules = proposed
	map_editor.clear_draft()
	arsenal_editor.initialized = false
	menu.set_opened(false)
	reset_game()
	has_match = true
	close_map_editor()

func sync_menu_to_match() -> void:
	menu.map_name = "Mappa della partita"
	menu.preset_name = "Configurazione della partita"
	menu.prepare(map_template, template_spawns, weapons, rules)

func generate_ground() -> Image:
	var generated := TerrainFactory.create(4)
	template_spawns = generated["spawns"]
	return generated["image"]

func generate_classic_ground() -> Image:
	var terrain := Image.create_empty(1100, 700, false, Image.FORMAT_RGBA8)
	for x in range(1100):
		var surface := int(440.0 + sin(x * 0.009) * 48.0 + sin(x * 0.024) * 19.0)
		for y in range(surface, 700):
			var color := Color("40554b") if (x * 7 + y * 13) % 23 < 3 else Color("795f49")
			if y < surface + 7:
				color = Color("91b979")
			terrain.set_pixel(x, y, color)
	return terrain

func reset_game() -> void:
	audio.stop_all()
	terrain_revision += 1
	mouse_charging = false
	power_drag = false
	ai.reset()
	picker.set_opened(false)
	crates.clear()
	secondary_projectiles.clear()
	traces.clear()
	turn_number = 0
	supply_number = 0
	notice_time = 0
	ammo = [[], []]
	for team in range(2):
		for weapon in weapons:
			ammo[team].append(int(weapon.get("ammo", -1)))
	if map_template == null:
		map_template = generate_ground()
	if template_spawns.is_empty():
		template_spawns = PackedVector2Array([TeamSpawns.MapData.find_spawn(map_template, Vector2(550, 174)), TeamSpawns.MapData.find_spawn(map_template, Vector2(map_template.get_width() * 0.68, 174))])
	var layout := TeamSpawns.plan(map_template, template_spawns, int(rules["team_size"]))
	if not layout["error"].is_empty():
		push_error(layout["error"])
		return
	W = map_template.get_width()
	H = map_template.get_height()
	if rules.get("scatter_spawns", false):
		layout = TeamSpawns.scattered(map_template, template_spawns, int(rules["team_size"]))
	ground = map_template.duplicate()
	ground_texture = ImageTexture.create_from_image(ground)
	terrain_sprite.texture = ground_texture
	units.clear()
	var positions: PackedVector2Array = layout["positions"]
	for i in range(positions.size()):
		units.append(make_unit(positions[i], i % 2, floori(i / 2.0) + 1))
	active = 0
	team_cursor = PackedInt32Array([0, -1])
	angle = 45.0
	power = 380.0
	facing = 1.0
	flying = false
	shot_weapon.clear()
	projectile_resting = false
	flight_time = 0.0
	settling = false
	winner = ""
	blast_time = 0.0
	turn_time = float(rules["turn_seconds"])
	overview = false
	manual_view = false
	camera_pan = false
	view_zoom = preferred_zoom * display_density
	view_center = units[active]["pos"]
	update_view(1)
	update_hud()
	queue_redraw()

func open_map_editor() -> void:
	mouse_charging = false
	power_drag = false
	picker.set_opened(false)
	if menu.opened or flying or settling or arsenal_editor.editing:
		return
	audio.set_paused(true)
	action_row.hide()
	map_editor.begin_edit(map_template, template_spawns, int(rules["team_size"]))
	hud.hide()
	help.hide()
	queue_redraw()

func editor_active() -> bool:
	return map_editor.editing or arsenal_editor.editing

func open_arsenal_editor() -> void:
	mouse_charging = false
	power_drag = false
	picker.set_opened(false)
	if menu.opened or flying or settling or map_editor.editing:
		return
	audio.set_paused(true)
	action_row.hide()
	arsenal_editor.begin_edit(weapons, rules)
	hud.hide()
	help.hide()
	queue_redraw()

func apply_arsenal(definitions: Array[Dictionary], settings: Dictionary) -> void:
	var proposed := ArsenalData.sanitize_rules(settings)
	var layout := TeamSpawns.plan(map_template, template_spawns, int(proposed["team_size"]))
	if not layout["error"].is_empty():
		arsenal_editor.set_editing(true)
		arsenal_editor.message.text = layout["error"]
		hud.hide()
		help.hide()
		return
	weapons = WeaponCatalog.sanitize(definitions)
	rules = proposed
	reset_game()
	sync_menu_to_match()
	close_map_editor()

func close_map_editor() -> void:
	audio.set_paused(false)
	action_row.show()
	hud.show()
	help.visible = help_open
	queue_redraw()

func apply_editor_map(image: Image, positions: PackedVector2Array) -> void:
	var layout := TeamSpawns.plan(image, positions, int(rules["team_size"]))
	if not layout["error"].is_empty():
		map_editor.set_editing(true)
		map_editor.message.text = layout["error"]
		return
	map_template = image.duplicate()
	template_spawns = positions.duplicate()
	reset_game()
	sync_menu_to_match()
	close_map_editor()

func restore_default_map() -> void:
	map_template = null
	template_spawns.clear()
	reset_game()
	sync_menu_to_match()

func make_unit(position: Vector2, team: int, number: int) -> Dictionary:
	return {"pos": position, "team": team, "number": number, "vel": Vector2.ZERO, "hp": int(rules["starting_health"]), "max_hp": int(rules["starting_health"]), "motor": 0.0, "grace": 0.0, "jump_buffer": 0.0, "weapon": 0}

func select_weapon(index: int) -> void:
	if not interaction_blocked() and winner.is_empty() and not flying and not settling and index >= 0 and index < weapons.size():
		if ammo[int(units[active]["team"])][index] != 0:
			units[active]["weapon"] = index

func selected_weapon() -> Dictionary:
	return weapons[int(units[active]["weapon"])]

func on_floor(unit: Dictionary) -> bool:
	var velocity: Vector2 = unit["vel"]
	return velocity.y >= 0.0 and blocked(unit["pos"] + Vector2(0, 2))

func request_jump() -> void:
	if not interaction_blocked() and winner.is_empty() and (not flying or shot_weapon.get("kind")=="placed") and not settling:
		units[active]["jump_buffer"] = 0.12

func solid(p: Vector2) -> bool:
	var x := int(floor(p.x))
	var y := int(floor(p.y))
	return x >= 0 and x < W and y >= 0 and y < H and ground.get_pixel(x, y).a > 0.5

func blocked(p: Vector2) -> bool:
	for i in range(16):
		if solid(p + Vector2.from_angle(TAU * i / 16.0) * R):
			return true
	return solid(p)

func _unhandled_key_input(event: InputEvent) -> void:
	if interaction_blocked():
		return
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode in [KEY_M, KEY_TAB] and not flying and not settling and not is_ai_turn():
		picker.refresh(weapons, ammo[int(units[active]["team"])], units[active]["weapon"])
		picker.set_opened(not picker.opened)
		return
	if picker.opened:
		if event.keycode == KEY_ESCAPE:
			picker.set_opened(false)
		return
	if event.keycode == KEY_R:
		reset_game()
	elif event.keycode == KEY_ESCAPE:
		open_menu()
	elif event.keycode == KEY_F2:
		open_map_editor()
	elif event.keycode == KEY_F3 and not flying and not settling:
		restore_default_map()
	elif event.keycode == KEY_F4:
		open_arsenal_editor()
	elif winner.is_empty() and not flying and not settling and not is_ai_turn():
		if event.keycode == KEY_SPACE:
			shoot()
		elif event.keycode == KEY_ENTER:
			next_turn()
		elif event.keycode == KEY_SHIFT:
			request_jump()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
			select_weapon(event.keycode - KEY_1)

func direction() -> Vector2:
	return Vector2(cos(deg_to_rad(angle)) * facing, -sin(deg_to_rad(angle)))

func shoot() -> void:
	mouse_charging = false
	if interaction_blocked() or flying or settling or not winner.is_empty():
		return
	if selected_weapon()["kind"]=="teleport" and Expanded.landing(self).x<0:
		notice="Indica uno spazio libero sopra un appoggio"
		notice_time=3
		return
	var stock: Array = ammo[int(units[active]["team"])]
	var slot := int(units[active]["weapon"])
	if stock[slot] == 0:
		return
	if stock[slot] > 0:
		stock[slot] -= 1
	picker.set_opened(false)
	manual_view = false
	shot_weapon = selected_weapon().duplicate(true)
	if is_ai_turn():
		aim_target=Expanded.nearest_enemy(self)
	traces.clear()
	audio.fire(shot_weapon)
	if Expanded.special(self,shot_weapon):
		return
	if shot_weapon["kind"] in ["beam", "scatter"]:
		fire_rays(shot_weapon)
		return
	projectile_resting = false
	projectile = muzzle_position()
	projectile_velocity = direction() * power
	if shot_weapon["kind"]=="placed":
		projectile_velocity=Vector2.ZERO
	flying = true
	flight_time = 0.0

func _physics_process(delta: float) -> void:
	if interaction_blocked():
		return
	blast_time = maxf(0.0, blast_time - delta)
	notice_time = maxf(0.0, notice_time - delta)
	if winner.is_empty():
		update_crates(delta)
		Expanded.update_fragments(self,delta)
		if not flying and not settling and units[active]["hp"] > 0:
			turn_time -= delta
			if mouse_charging:
				charge_elapsed += delta
				if charge_elapsed > 0.12:
					power = clampf(150 + (charge_elapsed - 0.12) * 240, 150, 650)
			var move := 0.0
			if is_ai_turn():
				ai.update(self, delta)
				move = ai.walk_axis
			elif not picker.opened:
				move = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
			if move != 0:
				facing = move
			set_walk_input(move, delta)
			if not is_ai_turn() and not picker.opened:
				angle = clampf(angle + (float(Input.is_physical_key_pressed(KEY_W)) - float(Input.is_physical_key_pressed(KEY_S))) * 45.0 * delta, -80.0, 85.0)
				power = clampf(power + (float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q))) * 180.0 * delta, 150.0, 650.0)
			if turn_time <= 0:
				next_turn()
		if flying and shot_weapon["kind"]=="placed" and not is_ai_turn():
			var retreat := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
			set_walk_input(retreat,delta)
			if Input.is_physical_key_pressed(KEY_SHIFT):
				request_jump()
		for unit in units:
			update_unit(unit, delta)
		if units[active]["hp"] <= 0 and not flying and not settling:
			finish_shot()
		elif not flying and not settling and (alive_count(0) == 0 or alive_count(1) == 0) and units_moving():
			# Una squadra appena eliminata può ancora trascinare l'altra in una caduta.
			finish_shot()
		if flying:
			update_projectile(delta)
		if settling:
			settle_time += delta
			if secondary_projectiles.is_empty() and settle_time > 1.5 and (not units_moving() or settle_time >= 5.0):
				settling = false
				next_turn()
		if not flying and not settling:
			check_winner()
	update_hud()
	if terrain_dirty:
		ground_texture.update(ground)
		terrain_dirty = false
	update_view(delta)
	queue_redraw()

func projectile_blocked(p: Vector2) -> bool:
	if solid(p):
		return true
	for i in range(8):
		if solid(p + Vector2.from_angle(TAU * i / 8.0) * PROJECTILE_RADIUS):
			return true
	return false

func terrain_normal(p: Vector2) -> Vector2:
	var normal := Vector2.ZERO
	for x in range(-7, 8):
		for y in range(-7, 8):
			if solid(p + Vector2(x, y)):
				normal -= Vector2(x, y)
	if normal.length_squared() < 0.01:
		return -projectile_velocity.normalized()
	return normal.normalized()

func finish_shot() -> void:
	flying = false
	settling = true
	settle_time = 0.0

func update_projectile(delta: float) -> void:
	var timed: bool = shot_weapon["trigger"] == "fuse"
	var gravity := GRAVITY * float(shot_weapon["gravity_scale"])
	if shot_weapon["kind"] in ["homing","controlled"]:
		gravity=0
		projectile_velocity=Expanded.steer(projectile_velocity,projectile,aim_target,delta)
	var duration := delta
	if timed:
		duration = minf(delta, maxf(0.0, float(shot_weapon["fuse"]) - flight_time))
	flight_time += duration
	if not projectile_resting:
		# Sottopassi: collisioni anche con pareti sottili e colpi veloci.
		var steps := maxi(1, ceili((projectile_velocity.length() + gravity * duration) * duration / 1.5))
		for step in range(steps):
			projectile_velocity.y += gravity * duration / steps
			var candidate := projectile + projectile_velocity * duration / steps
			var hit := projectile_blocked(candidate)
			var terrain_hit := hit
			var normal := Vector2.ZERO
			if hit:
				if terrain_hit and shot_weapon["kind"] == "drill" and flight_time < 1.1:
					carve(candidate, 13.0, false)
					projectile = candidate
					continue
				normal = terrain_normal(candidate)
			else:
				for i in range(units.size()):
					# Non urta il lanciatore nei primissimi istanti del lancio.
					if i == active and flight_time < 0.12:
						continue
					if units[i]["hp"] > 0 and candidate.distance_to(units[i]["pos"]) < R + PROJECTILE_RADIUS:
						hit = true
						normal = (candidate - Vector2(units[i]["pos"])).normalized()
						break
			if hit:
				if not timed:
					explode(projectile, shot_weapon)
					return
				if normal == Vector2.ZERO:
					normal = Vector2.UP
				if projectile_velocity.dot(normal) < 0.0:
					if projectile_velocity.length() > 65:
						audio.play_event("bounce", 0.45)
					projectile_velocity = projectile_velocity.bounce(normal) * float(shot_weapon["bounce"])
				if terrain_hit and normal.y < -0.35 and projectile_velocity.length() < 35.0 and projectile_blocked(projectile + Vector2(0, 2)):
					projectile_velocity = Vector2.ZERO
					projectile_resting = true
				# Rimane nell'ultima posizione libera; la miccia continua.
				break
			projectile = candidate
			if projectile.y > H + 10 or projectile.x < -100 or projectile.x > W + 100:
				finish_shot()
				return
	if timed and flight_time >= float(shot_weapon["fuse"]) - 0.00001:
		explode(projectile, shot_weapon)
	elif flight_time >= 12.0:
		finish_shot()

func set_walk_input(axis: float, delta: float) -> void:
	var unit: Dictionary = units[active]
	var acceleration := WALK_ACCELERATION if on_floor(unit) else WALK_ACCELERATION * 0.45
	unit["motor"] = move_toward(float(unit["motor"]), axis * WALK_SPEED, acceleration * delta)

func walk_unit(unit: Dictionary, amount: float) -> void:
	# Ogni passo misura al massimo un pixel: niente attraversamento dei muri.
	var steps := maxi(1, ceili(absf(amount)))
	for step in range(steps):
		var p: Vector2 = unit["pos"]
		var grounded := on_floor(unit)
		var target := Vector2(p.x + amount / steps, p.y)
		if blocked(target):
			var climbed := false
			if grounded:
				for rise in range(1, STEP_HEIGHT + 1):
					# Verifica anche lo spazio sopra la posizione di partenza.
					if blocked(p - Vector2(0, rise)):
						break
					var candidate := target - Vector2(0, rise)
					if not blocked(candidate):
						target = candidate
						climbed = true
						break
			if not climbed:
				unit["motor"] = 0.0
				return
		unit["pos"] = target
		if grounded:
			# Segue le discese brevi; dai precipizi si cade con la gravità.
			for drop in range(1, FLOOR_SNAP + 2):
				var lower: Vector2 = target + Vector2(0, drop)
				if blocked(lower):
					unit["pos"] = target + Vector2(0, drop - 1)
					break

func update_unit(unit: Dictionary, delta: float) -> void:
	if unit["hp"] <= 0:
		return
	var controlled: bool = unit == units[active] and (not flying or shot_weapon.get("kind")=="placed") and not settling and winner.is_empty()
	if on_floor(unit):
		unit["grace"] = 0.10
	else:
		unit["grace"] = maxf(0.0, float(unit["grace"]) - delta)
	unit["jump_buffer"] = maxf(0.0, float(unit["jump_buffer"]) - delta)
	var velocity: Vector2 = unit["vel"]
	if controlled and unit["jump_buffer"] > 0.0 and unit["grace"] > 0.0:
		velocity.y = -JUMP_SPEED
		unit["grace"] = 0.0
		unit["jump_buffer"] = 0.0
		unit["vel"] = velocity
	if not controlled:
		unit["motor"] = move_toward(float(unit["motor"]), 0.0, WALK_ACCELERATION * delta)
	walk_unit(unit, float(unit["motor"]) * delta)
	velocity.y += GRAVITY * delta
	var p: Vector2 = unit["pos"]
	var steps := maxi(1, int(ceil(velocity.length() * delta / 2.0)))
	for step in range(steps):
		var nx := Vector2(p.x + velocity.x * delta / steps, p.y)
		if not blocked(nx):
			p = nx
		else:
			velocity.x = 0
		var ny := p + Vector2(0, velocity.y * delta / steps)
		if not blocked(ny):
			p = ny
		else:
			velocity.y = 0
	velocity.x = move_toward(velocity.x, 0.0, 90.0 * delta)
	unit["pos"] = p
	unit["vel"] = velocity
	if p.y > H - 68 or p.x < -R or p.x > W + R:
		unit["hp"] = 0

func explode(center: Vector2, definition: Dictionary = {}) -> void:
	terrain_revision += 1
	var weapon: Dictionary = selected_weapon() if definition.is_empty() else definition
	finish_shot()
	blast_position = center
	blast_time = 0.4
	audio.play_event("explosion", float(weapon["damage"]) / 100)
	var radius := float(weapon["crater_radius"])
	blast_radius = radius
	Expanded.burst(self,center,weapon)
	for x in range(maxi(0, int(center.x - radius)), mini(W, int(center.x + radius) + 1)):
		for y in range(maxi(0, int(center.y - radius)), mini(H, int(center.y + radius) + 1)):
			if Vector2(x, y).distance_squared_to(center) <= radius * radius:
				ground.set_pixel(x, y, Color.TRANSPARENT)
	ground_texture.update(ground)
	for index in range(units.size()):
		var unit: Dictionary = units[index]
		var offset: Vector2 = unit["pos"] - center
		var strength := clampf(1.0 - offset.length() / float(weapon["damage_radius"]), 0.0, 1.0)
		if strength > 0 and unit["hp"] > 0:
			if unit["team"] != units[active]["team"] or rules["self_damage"]:
				unit["hp"] = maxi(0, unit["hp"] - int(float(weapon["damage"]) * strength))
			unit["vel"] = offset.normalized() * strength * float(weapon["impulse"]) + Vector2(0, -100.0 * strength)
	for index in range(crates.size() - 1, -1, -1):
		if Vector2(crates[index]["pos"]).distance_to(center) < radius:
			crates.remove_at(index)

func next_turn() -> void:
	mouse_charging = false
	power_drag = false
	ai.reset()
	picker.set_opened(false)
	turn_number += 1
	units[active]["jump_buffer"] = 0.0
	units[active]["motor"] = 0.0
	check_winner()
	if not winner.is_empty():
		return
	if rules.get("supplies", true) and turn_number % 2 == 0 and crates.size() < 3:
		spawn_crate()
	var team: int = 1 - int(units[active]["team"])
	var candidates: Array[int] = []
	for i in range(units.size()):
		if units[i]["team"] == team and units[i]["hp"] > 0:
			candidates.append(i)
	active = candidates[0]
	for index in candidates:
		if index > team_cursor[team]:
			active = index
			break
	team_cursor[team] = active
	facing = 1.0 if team == 0 else -1.0
	if ammo[team][int(units[active]["weapon"])] == 0:
		for slot in range(weapons.size()):
			if ammo[team][slot] != 0:
				units[active]["weapon"] = slot
				break
	turn_time = float(rules["turn_seconds"])
	overview = false
	manual_view = false
	camera_pan = false
	view_zoom = preferred_zoom * display_density
	view_center = units[active]["pos"]
	update_view(1)
	update_hud()
	queue_redraw()

func units_moving() -> bool:
	for unit in units:
		var velocity: Vector2 = unit["vel"]
		if unit["hp"] > 0 and (velocity.length() > 5.0 or not on_floor(unit)):
			return true
	return false

func alive_count(team: int) -> int:
	var count := 0
	for unit in units:
		if unit["team"] == team and unit["hp"] > 0:
			count += 1
	return count

func check_winner() -> void:
	var turquoise := alive_count(0)
	var orange := alive_count(1)
	if turquoise == 0 and orange == 0:
		winner = "Pareggio!"
	elif turquoise == 0:
		winner = "Vince la squadra Arancio!"
	elif orange == 0:
		winner = "Vince la squadra Turchese!"
	else:
		winner = ""

func update_hud() -> void:
	var team := "Turchese" if units[active]["team"] == 0 else "Arancio"
	team += " %d" % units[active]["number"]
	var state := "Proiettile in volo" if flying else ("Esplosione e assestamento" if settling else "Turno: " + team)
	var weapon: Dictionary = shot_weapon if flying else selected_weapon()
	var weapon_info := String(weapon["name"])
	var stock: int = ammo[int(units[active]["team"])][int(units[active]["weapon"])]
	weapon_info += " · ∞" if stock < 0 else " · %d colpi" % stock
	if is_ai_turn() and not flying and not settling:
		state = "IA Arancio: calcolo del tiro…"
	if weapon["trigger"] == "fuse":
		var seconds := maxf(0.0, float(weapon["fuse"]) - flight_time) if flying else float(weapon["fuse"])
		weapon_info += "  •  Miccia: %.1fs" % seconds
	hud.text = "%s · %ds · %d PV\n%s · Potenza %d" % [state, ceili(turn_time), units[active]["hp"], weapon_info, int(power)]
	if selected_weapon()["kind"] in ["homing","controlled","airstrike","teleport"]:
		hud.text += "\nMouse: scegli bersaglio" + (" · guida durante il volo" if selected_weapon()["kind"]=="controlled" else "")
	if notice_time > 0:
		hud.text += "\n" + notice
	if not winner.is_empty():
		hud.text = "CRATERI\n" + winner + "\nR: ricomincia  ·  Esc: menu"

func _draw() -> void:
	terrain_sprite.visible = not (editor_active() or menu.opened)
	if editor_active() or menu.opened:
		return
	if ground_texture == null:
		return
	draw_set_transform(view_offset, 0, Vector2.ONE * view_zoom)
	terrain_sprite.texture = ground_texture
	terrain_sprite.position = view_offset
	terrain_sprite.scale = Vector2.ONE * view_zoom
	draw_supplies()
	for piece in secondary_projectiles:
		draw_soft_circle(piece["pos"],5,Color("ffe19a"))
	if selected_weapon()["kind"] in ["homing","controlled","airstrike","teleport"]:
		draw_arc(aim_target,12,0,TAU,32,Color("9aefde"),2,true)
	var label_boxes: Array[Rect2] = []
	for i in range(units.size()):
		if units[i]["hp"] <= 0:
			continue
		var p: Vector2 = units[i]["pos"]
		var color: Color = COLORS[int(units[i]["team"])]
		draw_worm(p, Color("e9aa9a"), units[i])
		draw_held_weapon(p, units[i], i == active)
		if i == active and winner.is_empty():
			draw_arc(p, 17, 0, TAU, 32, Color.WHITE, 1.0)
			if not flying and not settling:
				var weapon_color := Color.html(String(selected_weapon()["color"]))

				var cross := p + direction() * 65
				draw_arc(cross, 7, 0, TAU, 20, weapon_color, 1.5)
				draw_line(cross - Vector2(10, 0), cross + Vector2(10, 0), weapon_color, 1)
				draw_line(cross - Vector2(0, 10), cross + Vector2(0, 10), weapon_color, 1)
				for path in trajectory_preview.paths(self):
					if path.size() >= 2:
						draw_polyline(path, Color(weapon_color, 0.65), 1.25, true)
						draw_arc(path[-1], 4, 0, TAU, 16, weapon_color, 1.4)
				var bar := Rect2(p + Vector2(-24, 24), Vector2(48, 5))
				draw_rect(bar, Color("142135"))
				draw_rect(Rect2(bar.position, Vector2(48 * (power - 150) / 500, 5)), weapon_color)
	draw_unit_labels(label_boxes)
	if flying:
		draw_painted_projectile()
		if shot_weapon["trigger"] == "fuse":
			draw_line(projectile + Vector2(0, -4), projectile + Vector2(2, -8), Color("ffe39d"), 2.0)
	if blast_time > 0:
		draw_blast_sparks()
		draw_soft_circle(blast_position, blast_radius * (1.0 - blast_time / 0.45), Color(1, 0.65, 0.2, blast_time * 2.0))
		for trace in traces:
			draw_polyline(trace, Color(0.6, 0.9, 1, blast_time * 2), 3)
	for wave in range(3):
		var water := PackedVector2Array([Vector2(0, 3000)])
		for x in range(0, W + 11, 10):
			water.append(Vector2(x, H - 84 + wave * 6 + sin(x * 0.025 + Time.get_ticks_msec() * 0.0015 + wave) * 3))
		water.append(Vector2(W + 10, 3000))
		draw_colored_polygon(water, Color("a0e7ce") if wave == 0 else (Color("36a5b3") if wave == 1 else Color("155678")))
	draw_set_transform(Vector2.ZERO)
	
	

func is_ai_turn() -> bool:
	return bool(rules.get("ai_enabled", false)) and not units.is_empty() and units[active]["team"] == 1

var terrain_dirty := false

func carve(center: Vector2, radius: float, refresh_texture: bool = true) -> void:
	terrain_revision += 1
	for x in range(maxi(0, int(center.x - radius)), mini(W, int(center.x + radius) + 1)):
		for y in range(maxi(0, int(center.y - radius)), mini(H, int(center.y + radius) + 1)):
			if Vector2(x, y).distance_squared_to(center) <= radius * radius:
				ground.set_pixel(x, y, Color.TRANSPARENT)
	if refresh_texture:
		ground_texture.update(ground)
	else:
		terrain_dirty = true

func fire_rays(weapon: Dictionary) -> void:
	var origin: Vector2 = units[active]["pos"]
	var pellets := 5 if weapon["kind"] == "scatter" else 1
	for pellet in range(pellets):
		var spread := (pellet - 2) * 0.055 if pellets > 1 else 0.0
		var dir := direction().rotated(spread)
		var point := origin
		for distance in range(1, W + 1):
			point = origin + dir * distance
			if solid(point):
				break
			var hit := false
			for index in range(units.size()):
				if index != active and units[index]["hp"] > 0 and point.distance_to(units[index]["pos"]) < R:
					hit = true
					break
			if hit or point.x < 0 or point.x > W or point.y > H-70:
				break
		traces.append(PackedVector2Array([origin + dir * 17, point]))
		explode(point, weapon)
	finish_shot()
	blast_time = 0.4

func spawn_crate() -> void:
	var x := 180.0 + fmod(supply_number * 277.0 + 83, W - 360.0)
	# Cerca un terreno raggiungibile, evitando le voragini.
	for attempt in range(20):
		var landing := TeamSpawns.MapData.find_spawn(ground, Vector2(x, 64))
		if landing.x >= 0 and landing.y < H-95:
			break
		x = 90.0 + fmod(x + 137, W - 180.0)
	var kind := "health" if supply_number % 2 == 1 else "weapon"
	if weapons.size() <= 2:
		kind = "health"
	crates.append({"pos": Vector2(x, 35), "kind": kind, "landed": false, "chute": true, "weapon": 2 + floori(supply_number / 2.0) % maxi(1, weapons.size() - 2)})
	supply_number += 1
	notice = "Rifornimento in arrivo: " + ("salute +35 PV" if kind == "health" else "munizioni")
	notice_time = 3.5

func update_crates(delta: float) -> void:
	for index in range(crates.size() - 1, -1, -1):
		var crate: Dictionary = crates[index]
		var p: Vector2 = crate["pos"]
		var supported := solid(p + Vector2(-8, 11)) or solid(p + Vector2(8, 11)) or solid(p + Vector2(0, 11))
		if not supported:
			crate["landed"] = false
			var speed := 65.0 if crate["chute"] else 170.0
			var steps := maxi(1, ceili(speed * delta))
			for step in range(steps):
				if solid(p + Vector2(-8, 12)) or solid(p + Vector2(8, 12)) or solid(p + Vector2(0, 12)):
					crate["landed"] = true
					crate["chute"] = false
					break
				p.y += speed * delta / steps
		else:
			crate["landed"] = true
			crate["chute"] = false
		crate["pos"] = p
		if p.y > H - 68 or p.x < -R or p.x > W + R:
			crates.remove_at(index)
			continue
		for unit in units:
			if unit["hp"] > 0 and p.distance_to(unit["pos"]) < 27:
				if collect_crate(crate, unit):
					crates.remove_at(index)
					break

func collect_crate(crate: Dictionary, unit: Dictionary) -> bool:
	if crate["kind"] == "health":
		if unit["hp"] >= unit["max_hp"]:
			return false
		var healed := mini(35, int(unit["max_hp"]) - int(unit["hp"]))
		unit["hp"] += healed
		notice = "Salute raccolta: +%d PV" % healed
	else:
		var slot := clampi(int(crate["weapon"]), 0, weapons.size() - 1)
		if ammo[int(unit["team"])][slot] < 0:
			# Le vecchie configurazioni possono contenere soltanto armi infinite.
			for candidate in range(weapons.size()):
				if ammo[int(unit["team"])][candidate] >= 0:
					slot = candidate
					break
		if ammo[int(unit["team"])][slot] < 0:
			return false
		ammo[int(unit["team"])][slot] = mini(99, ammo[int(unit["team"])][slot] + 2)
		notice = "Munizioni raccolte: %s +2" % weapons[slot]["name"]
	notice_time = 3.5
	audio.play_event("pickup", 0.7)
	return true

func draw_supplies() -> void:
	for crate in crates:
		var p: Vector2 = crate["pos"]
		var color := Color("ee877a") if crate["kind"] == "health" else Color("e9c362")
		if crate["chute"]:
			draw_line(p + Vector2(-9, -9), p + Vector2(-22, -44), Color("e1e6ef"), 1)
			draw_line(p + Vector2(9, -9), p + Vector2(22, -44), Color("e1e6ef"), 1)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-25, -44), p + Vector2(-19, -58), p + Vector2(0, -65), p + Vector2(19, -58), p + Vector2(25, -44)]), Color("e1d9ee"))
			draw_line(p + Vector2(0, -65), p + Vector2(0, -44), color, 2)
		draw_rect(Rect2(p - Vector2(11, 10), Vector2(22, 20)), Color("443b39"))
		draw_rect(Rect2(p - Vector2(9, 8), Vector2(18, 16)), color)
		if crate["kind"] == "health":
			draw_line(p - Vector2(5, 0), p + Vector2(5, 0), Color.WHITE, 3)
			draw_line(p - Vector2(0, 5), p + Vector2(0, 5), Color.WHITE, 3)
		else:
			draw_line(p + Vector2(-5, 5), p + Vector2(5, -5), Color("443b39"), 4)
			draw_line(p + Vector2(-7, -6), p + Vector2(7, 6), Color("443b39"), 2)

func toggle_picker() -> void:
	mouse_charging = false
	if interaction_blocked() or flying or settling or is_ai_turn() or not winner.is_empty():
		return
	picker.refresh(weapons, ammo[int(units[active]["team"])], units[active]["weapon"])
	picker.set_opened(not picker.opened)




var preferred_zoom := 1.35
var mouse_charging := false
var charge_elapsed := 0.0
var charge_start_power := 380.0
var power_drag := false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F1 and not editor_active() and not menu.opened:
			toggle_help()
			get_viewport().set_input_as_handled()
			return
		if help_open and event.keycode == KEY_ESCAPE:
			toggle_help()
			get_viewport().set_input_as_handled()
			return
	# Il rilascio sopra un pannello non deve lasciare il colpo in carica.
	if event is InputEventMouseMotion and flying and shot_weapon["kind"]=="controlled":
		aim_target=world_from_screen(event.position)
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			power_drag = false
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			camera_pan = false
	if mouse_charging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if interaction_blocked() or picker.opened:
			mouse_charging = false
		else:
			shoot()
var view_zoom := 1.0
var view_offset := Vector2.ZERO
var view_center := Vector2(550, 400)
var overview := false
var camera_pan := false
var manual_view := false

func update_view(delta: float) -> void:
	# Il campo occupa la larghezza disponibile anche con uno zoom salvato molto basso.
	view_zoom = maxf(view_zoom, overview_zoom())
	if (flying or settling) and not manual_view:
		return
	var target: Vector2 = Vector2(units[active]["pos"])
	if overview:
		target = Vector2(W / 2.0, H * 0.55)
	elif manual_view:
		target = view_center
	view_center = view_center.lerp(target, minf(1, delta * 7))
	view_offset = Vector2(screen_size.x * 0.5, screen_size.y * 0.52) - view_center * view_zoom
	if W * view_zoom >= screen_size.x:
		view_offset.x = clampf(view_offset.x, screen_size.x - W * view_zoom - 24 * display_density, 24 * display_density)
	else:
		view_offset.x = (screen_size.x - W * view_zoom) / 2

	# Il mare resta una striscia sul fondo, invece di riempire mezzo schermo.
	# Il trascinamento manuale e il volo dei proiettili possono mostrare il cielo.
	if not manual_view:
		view_offset.y = screen_size.y * 0.94 - (H - 84) * view_zoom
		if not overview:
			view_offset.y = maxf(view_offset.y, 155 * display_density - float(units[active]["pos"].y) * view_zoom)

func world_from_screen(point: Vector2) -> Vector2:
	return (point - view_offset) / view_zoom

func aim_at(point: Vector2) -> void:
	aim_target=point
	var offset := point - Vector2(units[active]["pos"])
	if offset.length() < 5:
		return
	facing = 1.0 if offset.x >= 0 else -1.0
	angle = clampf(rad_to_deg(atan2(-offset.y, absf(offset.x))), -80, 85)

func _unhandled_input(event: InputEvent) -> void:
	if interaction_blocked() or picker.opened:
		return
	if event is InputEventMouseMotion and flying and shot_weapon["kind"]=="controlled":
		aim_target=world_from_screen(event.position)
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			power_drag = false
		elif event.button_index == MOUSE_BUTTON_LEFT and mouse_charging:
			shoot()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		camera_pan = false
	if event is InputEventMouseButton and get_viewport_rect().has_point(event.position):
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			overview = false
			view_zoom = clampf(view_zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1 / 1.15), 0.45 * display_density, 2.2 * display_density)
			preferred_zoom = view_zoom / display_density
			save_display_preferences()
			update_view(0)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			camera_pan = event.pressed
			if event.pressed:
				manual_view = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			power_drag = event.pressed and not is_ai_turn() and not flying and not settling
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not is_ai_turn() and not flying and not settling:
			aim_at(world_from_screen(event.position))
			mouse_charging = true
			charge_elapsed = 0
			charge_start_power = power
	elif event is InputEventMouseMotion:
		if power_drag:
			power = clampf(power - event.relative.y * 2, 150, 650)
		elif camera_pan:
			view_center -= event.relative / view_zoom
			update_view(0)
		elif not is_ai_turn() and not flying and not settling and get_viewport_rect().has_point(event.position):
			aim_at(world_from_screen(event.position))
		queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		overview = not overview
		view_zoom = overview_zoom() if overview else preferred_zoom * display_density
		camera_pan = false
		manual_view = false
		update_view(1)

func draw_worm(p: Vector2, _color: Color, unit: Dictionary) -> void:
	var t := Time.get_ticks_msec() * 0.006
	var moving := minf(1.0, absf(float(unit["motor"])) / WALK_SPEED)
	var bounce := sin(t*2.4) * moving * 1.5
	var breath := sin(t) * 0.4
	var look := facing if unit == units[active] else (1.0 if unit["team"] == 0 else -1.0)
	draw_set_transform(view_offset+p*view_zoom,0,Vector2(look,1)*view_zoom)
	var rect := Rect2(Vector2(-30,-24 + bounce-breath),Vector2(46,36+breath))
	draw_texture_rect(PaintedArt.character(),rect,false)
	# Fascia colorata: la squadra resta leggibile anche con lo stesso personaggio.
	var head := Vector2(3,-18+bounce)
	draw_line(head-Vector2(6,0),head+Vector2(7,0),COLORS[int(unit["team"])],3.5,true)
	if unit["hp"] < 35:
		draw_soft_circle(head+Vector2(-look*10,4),1.5,Color("8bddf4"))
	draw_set_transform(view_offset,0,Vector2.ONE*view_zoom)

func muzzle_position() -> Vector2:
	var point: Vector2 = units[active]["pos"]
	for distance in range(1, int(R + 8)):
		var candidate: Vector2 = units[active]["pos"] + direction() * distance
		if projectile_blocked(candidate):
			break
		point = candidate
	return point

func draw_held_weapon(p: Vector2, unit: Dictionary, current: bool) -> void:
	var slot := clampi(int(unit["weapon"]), 0, weapons.size() - 1)
	var definition: Dictionary = weapons[slot]
	var kind: String = "bomb" if definition["trigger"] == "fuse" else definition["kind"]
	var texture := WeaponArt.icon(kind, slot, Color.html(definition["color"]))
	var aim := direction() if current else Vector2(1 if unit["team"] == 0 else -1, -0.2).normalized()
	var origin := p + aim * 17 + Vector2(0, 2)
	var scale_y := -0.4 if aim.x < 0 else 0.4
	draw_set_transform(view_offset + origin * view_zoom, aim.angle(), Vector2(0.4, scale_y) * view_zoom)
	var fit := minf(86.0 / texture.get_width(), 66.0 / texture.get_height())
	var size := Vector2(texture.get_size()) * fit
	draw_texture_rect(texture, Rect2(Vector2(-size.x*.42,-size.y*.55),size), false)
	draw_set_transform(view_offset, 0, Vector2.ONE * view_zoom)






func load_display_preferences() -> void:
	if display_preferences.load("user://display.cfg") != OK:
		return
	var saved_text: Variant = display_preferences.get_value("display", "text_scale", 1.0)
	var saved_zoom: Variant = display_preferences.get_value("display", "zoom", 1.35)
	if int(display_preferences.get_value("display", "framing_version", 0)) < 15:
		saved_zoom = 1.35
	if (saved_text is int or saved_text is float) and is_finite(float(saved_text)):
		text_scale = clampf(float(saved_text), 0.8, 1.6)
	if (saved_zoom is int or saved_zoom is float) and is_finite(float(saved_zoom)):
		preferred_zoom = clampf(float(saved_zoom), 0.45, 2.2)

func save_display_preferences() -> void:
	display_preferences.set_value("display", "text_scale", text_scale)
	display_preferences.set_value("display", "zoom", preferred_zoom)
	display_preferences.set_value("display", "framing_version", 15)
	display_preferences.save("user://display.cfg")

func add_display_button(title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	action_row.add_child(button)

func set_text_scale(value: float) -> void:
	text_scale = clampf(value, 0.8, 1.6)
	save_display_preferences()
	apply_display_layout()

func toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode in [Window.MODE_FULLSCREEN, Window.MODE_EXCLUSIVE_FULLSCREEN]:
		window.mode = Window.MODE_WINDOWED
		window.size = Vector2i(1280, 800)
	else:
		window.mode = Window.MODE_FULLSCREEN

func toggle_help() -> void:
	help_open = not help_open
	mouse_charging = false
	power_drag = false
	help.visible = help_open
	help_scroll.visible = help_open
	audio.set_paused(help_open)
	queue_redraw()

func overview_zoom() -> float:
	return minf((screen_size.x - 48 * display_density) / W, (screen_size.y - 110 * display_density) / float(H - 160))

func apply_display_layout() -> void:
	screen_size = get_viewport_rect().size
	if screen_size.x < 1 or screen_size.y < 1 or action_row == null:
		return
	display_density = clampf(screen_size.y / 900.0, 0.8, 3.0)
	scenery.size = screen_size
	view_zoom = overview_zoom() if overview else preferred_zoom * display_density
	var fit := minf(screen_size.x / 1100.0, screen_size.y / 700.0) * 0.96
	var offset := (screen_size - Vector2(1100, 700) * fit) / 2
	var modal_transform := Transform2D(0, Vector2.ONE * fit, 0, offset)
	for editor in [menu, arsenal_editor, map_editor]:
		if editor.layer != null:
			editor.layer.transform = modal_transform
		editor.queue_redraw()
	map_editor.position = offset
	map_editor.scale = Vector2.ONE * fit
	picker.transform = modal_transform
	# MSDF mantiene nitidi i caratteri anche nei pannelli centrati a grande scala.
	for property in ThemeDB.fallback_font.get_property_list():
		if property["name"] == "multichannel_signed_distance_field":
			ThemeDB.fallback_font.set("multichannel_signed_distance_field", true)
			break
	var factor := display_density * text_scale
	hud.position = Vector2(16, 16) * display_density
	hud.size = Vector2(minf(screen_size.x * 0.57, 560 * factor), 0)
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_theme_font_size_override("font_size", roundi(24 * factor))
	hud.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("112a37ed")
	style.border_color = Color("ba975d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(roundi(8 * display_density))
	style.set_content_margin_all(10 * display_density)
	hud.add_theme_stylebox_override("normal", style)
	help.add_theme_stylebox_override("normal", style)
	help.add_theme_font_size_override("font_size", roundi(23 * factor))
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_scroll.size = Vector2(minf(screen_size.x - 48 * display_density, 980 * factor), screen_size.y * 0.72)
	help_scroll.position = Vector2((screen_size.x - help_scroll.size.x) / 2, screen_size.y * 0.16)
	help.size = Vector2(help_scroll.size.x - 20 * display_density, 0)
	help.position = Vector2.ZERO
	help.mouse_filter = Control.MOUSE_FILTER_STOP
	help.text = "COMANDI  /  F1 o Esc per tornare\n\nMouse: mira · sinistro tenuto: carica · rilascio: spara\nDestro trascinato: potenza · M/Tab: arsenale\nA/D: movimento · Shift: salto · W/S: mira · Q/E: potenza · Spazio: tiro\nRotella: zoom · C: panoramica · trascina rotella: visuale\nInvio: passa · R: ricomincia · Esc: pausa\nF2: mappe · F3: mappa iniziale · F4: armi/regole\nF11 o Alt+Invio: schermo intero/finestra · A−/A+: dimensione testi"
	for button in action_row.get_children():
		button.add_theme_font_size_override("font_size", roundi(20 * factor))
		button.custom_minimum_size = Vector2(0, 38 * display_density)
	action_row.add_theme_constant_override("separation", roundi(7 * display_density))
	action_row.reset_size()
	var row_size := action_row.get_combined_minimum_size()
	var row_y := 16 * display_density
	if row_size.x + hud.size.x + 50 * display_density > screen_size.x:
		row_y = maxf(90 * factor, hud.position.y + hud.get_combined_minimum_size().y + 10 * display_density)
	action_row.position = Vector2(screen_size.x - row_size.x - 16 * display_density, row_y)
	apply_dialog_layout(menu)
	apply_dialog_layout(map_editor)
	apply_dialog_layout(arsenal_editor)
	if not units.is_empty():
		update_view(1)
		update_hud()
	queue_redraw()

func apply_dialog_layout(node: Node) -> void:
	for child in node.get_children():
		if child is FileDialog:
			var theme := Theme.new()
			theme.default_font_size = roundi(18 * display_density * text_scale)
			child.theme = theme
			child.min_size = Vector2i(Vector2(760, 440) * display_density)
		apply_dialog_layout(child)

func draw_unit_labels(boxes: Array[Rect2]) -> void:
	draw_set_transform(Vector2.ZERO)
	var factor := display_density * text_scale
	var font_size := roundi(19 * factor)
	for index in range(units.size()):
		var unit: Dictionary = units[index]
		if unit["hp"] <= 0:
			continue
		var point: Vector2 = Vector2(unit["pos"]) * view_zoom + view_offset
		if not Rect2(Vector2(-40, -40), screen_size + Vector2(80, 80)).has_point(point):
			continue
		var color: Color = COLORS[int(unit["team"])]
		var caption := ("Turchese " if unit["team"] == 0 else "Arancio ") + str(unit["number"]) + " · " + str(unit["hp"])
		var width := ThemeDB.fallback_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var box := Rect2(point - Vector2(width / 2 + 5 * factor, 37 * factor + 28 * view_zoom), Vector2(width + 10 * factor, 29 * factor))
		box.position.x = clampf(box.position.x, 4, maxf(4, screen_size.x - box.size.x - 4))
		for attempt in range(16):
			var overlap := false
			for previous in boxes:
				if box.grow(2 * factor).intersects(previous):
					overlap = true
					break
			if not overlap:
				break
			box.position.y -= 31 * factor
		box.position.y = maxf(4, box.position.y)
		boxes.append(box)
		draw_line(box.position + Vector2(box.size.x / 2, box.size.y), point - Vector2(0, 12 * view_zoom), Color(color, 0.35), 1)
		draw_rect(box, Color(0.035, 0.065, 0.11, 0.88))
		draw_string(ThemeDB.fallback_font, box.position + Vector2(5 * factor, 21 * factor), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		draw_rect(Rect2(box.position + Vector2(0, box.size.y - 3 * factor), Vector2(box.size.x * float(unit["hp"]) / float(unit["max_hp"]), 3 * factor)), color)
		if index == active and winner.is_empty():
			var arrow := box.position + Vector2(box.size.x / 2, -5 * factor)
			draw_colored_polygon(PackedVector2Array([arrow + Vector2(-5, -9) * factor, arrow + Vector2(5, -9) * factor, arrow]), Color.WHITE)
	draw_set_transform(view_offset, 0, Vector2.ONE * view_zoom)



func draw_soft_circle(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, color, true, -1.0, true)







func prepare_painted_scene() -> void:
	scenery = TextureRect.new()
	scenery.texture = PaintedArt.background()
	scenery.modulate = Color(0.72,0.77,0.86,1)
	scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scenery.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scenery.z_index = -2
	add_child(scenery)
	terrain_sprite = Sprite2D.new()
	terrain_sprite.centered = false
	terrain_sprite.z_index = -1
	var paint := ShaderMaterial.new()
	paint.shader = load("res://assets/art-018/terrain.gdshader")
	paint.set_shader_parameter("stone_texture",load("res://assets/art-018/stone.png"))
	paint.set_shader_parameter("theme_atlas",load("res://assets/art-019/materials.png"))
	terrain_sprite.material = paint
	add_child(terrain_sprite)


func draw_painted_projectile() -> void:
	var dir := projectile_velocity.normalized()
	if dir.length_squared() < 0.1:
		dir = Vector2.RIGHT
	if shot_weapon["trigger"] == "fuse":
		var icon := WeaponArt.icon("bomb",int(units[active]["weapon"]),Color.WHITE)
		draw_texture_rect(icon,Rect2(projectile-Vector2(7,9),Vector2(14,18)),false)
	else:
		for i in range(7,0,-1):
			draw_soft_circle(projectile-dir*i*4, maxf(1,4-i*.4),Color(1,.65,.2,.55-i*.06))
		var side := dir.orthogonal()*3.5
		draw_colored_polygon(PackedVector2Array([projectile+dir*9,projectile-dir*6+side,projectile-dir*6-side]),Color("f9d487"))
		draw_line(projectile-dir*6+side,projectile+dir*9,Color("534136"),1.2,true)

func draw_blast_sparks() -> void:
	var age := 1.0-clampf(blast_time/.4,0,1)
	var fade := 1.0-age
	draw_arc(blast_position,maxf(2,blast_radius*age),0,TAU,64,Color(1,.85,.48,fade),3,true)
	for i in range(16):
		var dir := Vector2.from_angle(i*TAU/16+sin(i*7.0)*.2)
		var pos := blast_position+dir*blast_radius*age*(.65+fmod(i*.37,.5))+Vector2(0,age*age*25)
		draw_line(pos,pos-dir*8*fade,Color(1,.6+i%3*.15,.22,fade),2.5,true)










