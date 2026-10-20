# Copyright (c) 2026 SboMusic
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
extends Node
## Effetti originali sintetizzati localmente, senza file audio esterni.
var enabled := true
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var last_event := ""
var explosion_frame := -1
func _ready() -> void:
	for event in ["rocket", "bomb", "beam", "scatter", "drill", "explosion", "bounce", "pickup"]:
		sounds[event] = synthesize(event)
	for i in range(12):
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
func play_event(event: String, strength: float = 1) -> void:
	last_event = event
	if not enabled or not sounds.has(event) or voices.is_empty():
		return
	if event == "explosion":
		if explosion_frame == Engine.get_process_frames():
			return
		explosion_frame = Engine.get_process_frames()
	var player: AudioStreamPlayer = voices[cursor % voices.size()]
	cursor += 1
	player.stream = sounds[event]
	player.volume_db = -12 + linear_to_db(clampf(strength, 0.2, 1))
	player.pitch_scale = 1.0
	player.play()
func fire(weapon: Dictionary) -> void:
	var event: String = weapon.get("kind", "projectile")
	if event == "projectile":
		event = "bomb" if weapon["trigger"] == "fuse" else "rocket"
	play_event(event)
	if enabled and not voices.is_empty():
		voices[(cursor - 1) % voices.size()].pitch_scale = clampf(1.2 - float(weapon["damage"]) * 0.004, 0.75, 1.2)
func set_paused(value: bool) -> void:
	for player in voices:
		player.stream_paused = value
func synthesize(event: String) -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.65 if event == "explosion" else (0.45 if event in ["rocket", "drill"] else 0.25)
	var count := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = event.hash()
	var phase := 0.0
	var filtered_noise := 0.0
	for i in range(count):
		var t := float(i) / rate
		var u := t / duration
		var noise := rng.randf_range(-1, 1)
		filtered_noise = lerpf(filtered_noise, noise, 0.18)
		var frequency := 100.0
		var sample := 0.0
		match event:
			"rocket":
				frequency = lerpf(180, 45, u)
				sample = noise * 0.35 + filtered_noise * 0.7
			"bomb":
				frequency = lerpf(520, 190, u)
				sample = sin(phase) * 0.65 + noise * 0.12
			"beam":
				frequency = lerpf(1700, 240, u * u)
				sample = sin(phase) * 0.55 + sin(phase * 1.5) * 0.2
			"scatter":
				frequency = 95
				sample = noise * 0.8 + filtered_noise * 0.5
			"drill":
				frequency = 95 + sin(t * 70) * 25
				sample = (1 if sin(phase) >= 0 else -1) * 0.35 + noise * 0.15
			"explosion":
				frequency = lerpf(95, 24, u)
				sample = filtered_noise * 1.6 + noise * 0.2 + sin(phase) * 0.25
			"bounce":
				frequency = lerpf(430, 150, u)
				sample = sin(phase) * 0.5
			"pickup":
				frequency = 620 if u < 0.5 else 930
				sample = sin(phase) * 0.4
		phase += TAU * frequency / rate
		var envelope := minf(1, t / 0.005) * pow(1 - u, 2.5)
		var value := clampf(sample * envelope * 0.7, -0.95, 0.95)
		bytes.encode_s16(i * 2, roundi(value * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop_all()

func stop_all() -> void:
	for player in voices:
		player.stop()
		player.stream = null
		player.stream_paused = false

func _exit_tree() -> void:
	stop_all()
	voices.clear()
	sounds.clear()
