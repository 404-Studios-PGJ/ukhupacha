extends Node
## Música acotada a cuatro voces y SFX a ocho. Ningún nuevo autoload.
signal track_changed(track_id: StringName)
signal sfx_played(id: StringName)

@export_range(0.0, 5.0, 0.05) var crossfade_seconds: float = 0.8
@export_range(-40.0, 0.0, 1.0) var music_db: float = -18.0
@export_range(-40.0, 0.0, 1.0) var sfx_db: float = -12.0
const SILENCE_DB: float = -80.0
const TRACKS: Dictionary[StringName, String] = {
	&"A": "res://assets/audio/music/ambience_a.wav",
	&"B": "res://assets/audio/music/ambience_b.wav",
	&"C": "res://assets/audio/music/ambience_c.wav",
	&"combat": "res://assets/audio/music/combat.wav",
}
const SFX: Dictionary[StringName, String] = {
	&"menu": "res://assets/audio/sfx/menu.wav",
	&"door": "res://assets/audio/sfx/door.wav",
	&"pickup": "res://assets/audio/sfx/pickup.wav",
	&"alarm": "res://assets/audio/sfx/alarm.wav",
	&"hit": "res://assets/audio/sfx/hit.wav",
	&"parry": "res://assets/audio/sfx/parry.wav",
	&"rift": "res://assets/audio/sfx/rift.wav",
}
var current_region: StringName = &""
var current_track: StringName = &""
var _channels: Dictionary[StringName, AudioStreamPlayer] = {}
var _sfx_channels: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _fade: Tween
var _watched: Dictionary[int, WeakRef] = {}
var _active: Dictionary[int, WeakRef] = {}
var _dead: Dictionary[int, bool] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id: StringName in TRACKS:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "Music_" + id
		var stream: AudioStreamWAV = (load(TRACKS[id]) as AudioStreamWAV).duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		voice.stream = stream
		voice.volume_db = SILENCE_DB
		add_child(voice)
		_channels[id] = voice
	for index: int in range(8):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "SFX_%d" % index
		voice.volume_db = sfx_db
		add_child(voice)
		_sfx_channels.append(voice)
	Level1Progress.progress_reset.connect(reset_session)


func set_region(region: StringName) -> void:
	var resolved: StringName = region
	match region:
		&"MusicRegionA": resolved = &"A"
		&"MusicRegionB": resolved = &"B"
		&"MusicRegionC": resolved = &"C"
	if resolved not in [&"A", &"B", &"C"]:
		return
	current_region = resolved
	_select_track()


func watch_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var id: int = enemy.get_instance_id()
	if _watched.has(id):
		return
	_watched[id] = weakref(enemy)
	if enemy.has_signal("enemy_alerted"):
		enemy.connect("enemy_alerted", enemy_alerted)
	if enemy.has_signal("enemy_died"):
		enemy.connect("enemy_died", enemy_died)
	enemy.tree_exiting.connect(_enemy_exiting.bind(id), CONNECT_ONE_SHOT)


func enemy_alerted(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	watch_enemy(enemy)
	var id: int = enemy.get_instance_id()
	if _dead.has(id) or _active.has(id):
		return
	_active[id] = weakref(enemy)
	play_sfx(&"alarm")
	_select_track()


func enemy_died(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var id: int = enemy.get_instance_id()
	_active.erase(id)
	_dead[id] = true
	_select_track()


func _enemy_exiting(id: int) -> void:
	_active.erase(id)
	_watched.erase(id)
	_dead.erase(id)
	_select_track()


func active_enemy_count() -> int:
	return _active.size()


func _select_track() -> void:
	var target: StringName = &"combat" if not _active.is_empty() else current_region
	if target == current_track:
		return
	current_track = target
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween().set_parallel(true)
	for id: StringName in _channels:
		var voice: AudioStreamPlayer = _channels[id]
		if id == target and not voice.playing:
			voice.play()
		var target_db: float = music_db if id == target else SILENCE_DB
		_fade.tween_property(voice, "volume_db", target_db, crossfade_seconds)
	_fade.finished.connect(_stop_silent)
	track_changed.emit(target)


func _stop_silent() -> void:
	for id: StringName in _channels:
		if id != current_track:
			_channels[id].stop()
			_channels[id].volume_db = SILENCE_DB


func play_sfx(id: StringName) -> void:
	if not SFX.has(id) or _sfx_channels.is_empty():
		return
	var voice: AudioStreamPlayer = _sfx_channels[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_channels.size()
	voice.stop()
	voice.stream = load(SFX[id]) as AudioStream
	voice.volume_db = sfx_db
	voice.play()
	sfx_played.emit(id)


func reset_session() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	for voice: AudioStreamPlayer in _channels.values():
		voice.stop()
		voice.volume_db = SILENCE_DB
	for voice: AudioStreamPlayer in _sfx_channels:
		voice.stop()
	for id: int in _watched:
		var enemy: Node = _watched[id].get_ref() as Node
		if not is_instance_valid(enemy):
			continue
		for pair: Array in [["enemy_alerted", enemy_alerted], ["enemy_died", enemy_died], ["tree_exiting", _enemy_exiting.bind(id)]]:
			if enemy.has_signal(pair[0]) and enemy.is_connected(pair[0], pair[1]):
				enemy.disconnect(pair[0], pair[1])
	_watched.clear()
	_active.clear()
	_dead.clear()
	current_region = &""
	current_track = &""
	track_changed.emit(current_track)


func debug_state() -> Dictionary:
	var voices: Dictionary = {}
	for id: StringName in _channels:
		voices[id] = {"playing": _channels[id].playing, "db": _channels[id].volume_db}
	return {"region": current_region, "track": current_track, "enemies": active_enemy_count(), "voices": voices, "sfx_voices": _sfx_channels.size()}
