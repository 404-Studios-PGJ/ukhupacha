extends Node2D

const EnemyDouble = preload("res://tests/interactables/audio_enemy.gd")
var enemy_a: EnemyDouble
var enemy_b: EnemyDouble
var results: Array[Dictionary] = []
var _status: Label
var testing: bool = false
var _controls: Array[Button] = []


func _ready() -> void:
	MusicDirector.reset_session()
	enemy_a = EnemyDouble.new()
	enemy_b = EnemyDouble.new()
	add_child(enemy_a)
	add_child(enemy_b)
	MusicDirector.watch_enemy(enemy_a)
	MusicDirector.watch_enemy(enemy_b)
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	var root: Control = Control.new()
	canvas.add_child(root)
	UIBuild.screen(root)
	UIBuild.panel(root, Rect2(0, 0, 640, 360))
	UIBuild.label(root, "LAB / AUDIO SINTÉTICO    CROSSFADE · 0,8 s", Rect2(24, 20, 592, 26), &"Title")
	UIBuild.label(root, "A · público    B · restringido    C · cámara", Rect2(24, 58, 592, 22))
	var x: int = 24
	for region: StringName in [&"A", &"B", &"C"]:
		_controls.append(UIBuild.button(root, "Ambiente " + region, Rect2(x, 94, 180, 34), MusicDirector.set_region.bind(region), true))
		x += 204
	_controls.append(UIBuild.button(root, "Alertar dos", Rect2(24, 142, 180, 32), _alert_both))
	_controls.append(UIBuild.button(root, "Muere A", Rect2(228, 142, 180, 32), enemy_a.die))
	_controls.append(UIBuild.button(root, "Muere B", Rect2(432, 142, 180, 32), enemy_b.die))
	var index: int = 0
	for id: StringName in MusicDirector.SFX:
		_controls.append(UIBuild.button(root, str(id), Rect2(24 + (index % 4) * 150, 194 + floori(index / 4.0) * 38, 138, 30), MusicDirector.play_sfx.bind(id)))
		index += 1
	_controls.append(UIBuild.button(root, "Pruebas", Rect2(24, 288, 180, 34), run_checks, true))
	_status = UIBuild.label(root, "Listo", Rect2(220, 282, 396, 64), &"Small")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _alert_both() -> void:
	MusicDirector.watch_enemy(enemy_a)
	MusicDirector.watch_enemy(enemy_b)
	enemy_a.alert()
	enemy_b.alert()


func _check(label: String, passed: bool) -> void:
	results.append({"case": label, "passed": passed})


func _settle() -> void:
	await get_tree().create_timer(MusicDirector.crossfade_seconds + 0.08).timeout


func _move_to(at: Vector2) -> void:
	$TestPlayer.position = at
	for index: int in range(4):
		await get_tree().physics_frame


func run_checks() -> Array[Dictionary]:
	if testing:
		return results
	testing = true
	for button: Button in _controls:
		button.disabled = true
	results.clear()
	MusicDirector.reset_session()
	_check("default crossfade 0.8 s", is_equal_approx(MusicDirector.crossfade_seconds, 0.8))
	await _move_to(Vector2(100, 180))
	await _settle()
	_check("MusicRegionA body trigger", MusicDirector.current_region == &"A" and MusicDirector.current_track == &"A")
	_check("A reaches music volume", is_equal_approx(MusicDirector._channels[&"A"].volume_db, MusicDirector.music_db))
	await _move_to(Vector2(300, 180))
	await get_tree().create_timer(0.15).timeout
	_check("A/B overlap during crossfade", MusicDirector._channels[&"A"].playing and MusicDirector._channels[&"B"].playing)
	await _settle()
	_check("B finishes and stops old A", MusicDirector.current_track == &"B" and not MusicDirector._channels[&"A"].playing)
	await _move_to(Vector2(520, 180))
	await _settle()
	_check("MusicRegionC body trigger", MusicDirector.current_track == &"C")
	_alert_both()
	enemy_a.alert()
	_check("duplicate alert counted once", MusicDirector.active_enemy_count() == 2 and MusicDirector.current_track == &"combat")
	await _settle()
	enemy_a.die()
	_check("first death keeps combat", MusicDirector.current_track == &"combat" and MusicDirector.active_enemy_count() == 1)
	enemy_a.die()
	enemy_a.alert()
	_check("dead enemy cannot reactivate combat", MusicDirector.active_enemy_count() == 1)
	MusicDirector.set_region(&"B")
	_check("region updates while combat continues", MusicDirector.current_region == &"B" and MusicDirector.current_track == &"combat")
	enemy_b.die()
	await _settle()
	_check("last death returns to latest ambience", MusicDirector.current_track == &"B" and not MusicDirector._channels[&"combat"].playing)
	var temporary: EnemyDouble = EnemyDouble.new()
	add_child(temporary)
	MusicDirector.watch_enemy(temporary)
	temporary.alert()
	temporary.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_check("freed enemy releases combat", MusicDirector.active_enemy_count() == 0 and MusicDirector.current_track == &"B")
	MusicDirector.set_region(&"A")
	await get_tree().create_timer(0.1).timeout
	MusicDirector.set_region(&"C")
	await _settle()
	var playing: int = 0
	for voice: AudioStreamPlayer in MusicDirector._channels.values():
		if voice.playing:
			playing += 1
	_check("interrupted crossfade leaves one track", playing == 1 and MusicDirector.current_track == &"C")
	await get_tree().create_timer(4.1).timeout
	_check("ambience loops beyond file duration", MusicDirector._channels[&"C"].playing and MusicDirector._channels[&"C"].get_playback_position() < 4.0)
	MusicDirector.set_region(&"invalid")
	_check("unknown region ignored", MusicDirector.current_track == &"C")
	for id: StringName in MusicDirector.SFX:
		var voice_index: int = MusicDirector._sfx_cursor
		MusicDirector.play_sfx(id)
		await get_tree().create_timer(0.025).timeout
		var voice: AudioStreamPlayer = MusicDirector._sfx_channels[voice_index]
		_check("SFX " + id + " has playback", voice.playing and voice.stream.get_length() > 0.0)
	var cursor_before: int = MusicDirector._sfx_cursor
	MusicDirector.play_sfx(&"unknown")
	_check("unknown SFX ignored", MusicDirector._sfx_cursor == cursor_before)
	for index: int in range(20):
		MusicDirector.play_sfx(&"hit")
	_check("SFX voice pool stays bounded", MusicDirector._sfx_channels.size() == 8)
	var peak: float = AudioServer.get_bus_peak_volume_left_db(0, 0)
	_check("audio bus receives non-silent mix", peak > -70.0)
	Level1Progress.reset()
	var stopped: bool = true
	for voice: AudioStreamPlayer in MusicDirector._channels.values():
		stopped = stopped and not voice.playing
	_check("New Game reset stops music and clears enemies", stopped and MusicDirector.current_track == &"" and MusicDirector.active_enemy_count() == 0)
	var passed: int = 0
	for item: Dictionary in results:
		if item["passed"]:
			passed += 1
	_status.text = "AUDIO %d/%d OK · pico %.1f dB\nSíntesis original; mezcla final pendiente." % [passed, results.size(), peak]
	print("AUDIO_LAB ", JSON.stringify(results))
	for button: Button in _controls:
		button.disabled = false
	testing = false
	return results
