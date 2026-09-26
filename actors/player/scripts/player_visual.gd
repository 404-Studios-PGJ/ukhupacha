class_name PlayerVisual
extends Node2D

signal animation_finished(action_name: String)
signal frame_changed(current_frame: int, total_frames: int)

@export var base_offset: Vector2 = Vector2(0, -12)

var weapon_id: StringName = &"none"
var has_shield: bool = false
var tier: int = 1

var current_action: String = "stand"
var current_direction: String = "down"

var frame_index: int = 0   # índice lógico dentro de la secuencia actual
var total_frames: int = 1
var frame_timer: float = 0.0
var fps: float = 6.0
var is_looping: bool = true
var is_playing: bool = true

@onready var sprite: Sprite2D = $Sprite
@onready var parry_flash_sprite: Sprite2D = $ParryFlash

# Cache textures in memory to prevent repeated disk I/O
var _texture_cache: Dictionary = {}
var _parry_flash_tween: Tween

# Secuencia actual: cada elemento es {tex: Texture2D, frame: int, fps: float}
# Se usa cuando la animación necesita combinar frames de múltiples strips.
var _sequence: Array = []  # Array of {tex, frame, dur}  (dur en segundos)
var _use_sequence: bool = false

# ============================================================
# Explicit mapping table - tier 0 and tier 1
# run de T0 usa "run_sequence" porque mezcla walk+run strips
# ============================================================
const SPRITE_TABLE: Dictionary = {
	# tier 0 (unarmed / none)
	[&"none", false]: {
		"stand": {"path": "res://assets/characters/player/p1/mc_p1_boxr_v01_base/stand", "frames": 1, "fps": 1.0, "loop": true},
		# walk: 6 frames, 135ms/frame
		"walk": {"path": "res://assets/characters/player/p1/mc_p1_boxr_v01_base/walk", "frames": 6, "fps": 7.4, "loop": true},
		# run: secuencia Mana Seed 1,2,7,4,5,8 → índices 0-based: 0,1,RUN0,3,4,RUN1
		# timings ms: 80/55/125/80/55/125 → fps por frame
		"run": {"run_sequence": true, "walk_path": "res://assets/characters/player/p1/mc_p1_boxr_v01_base/walk", "run_path": "res://assets/characters/player/p1/mc_p1_boxr_v01_base/run", "loop": true},
		"slash1": {"path": "res://assets/characters/player/pONE3/mc_t0_base/slash1", "frames": 4, "fps": 12.0, "loop": false},
		"slash2": {"path": "res://assets/characters/player/pONE3/mc_t0_base/slash2", "frames": 4, "fps": 12.0, "loop": false},
		"dodge": {"path": "res://assets/characters/player/pONE1/mc_pONE1_boxr_v01_base/dodge", "frames": 1, "fps": 5.0, "loop": false},
		"parry": {"path": "res://assets/characters/player/pONE1/mc_pONE1_boxr_v01_base/parry", "frames": 1, "fps": 5.0, "loop": false},
		"guard": {"path": "res://assets/characters/player/pONE1/mc_pONE1_boxr_v01_base/parry", "frames": 1, "fps": 5.0, "loop": true},
		"hurt": {"path": "res://assets/characters/player/pONE1/mc_pONE1_boxr_v01_base/hurt", "frames": 1, "fps": 5.0, "loop": false},
		"dead": {"path": "res://assets/characters/player/pONE1/mc_pONE1_boxr_v01_base/dead", "frames": 2, "fps": 4.0, "loop": false}
	},
	# tier 1 sword
	[&"sword", false]: {
		"stand": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_sword_t1/idle", "frames": 4, "fps": 5.0, "loop": true},
		"walk": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_sword_t1/move", "frames": 4, "fps": 6.0, "loop": true},
		"run": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_sword_t1/move", "frames": 4, "fps": 10.0, "loop": true},
		"slash1": {"path": "res://assets/characters/player/pONE3/mc_t1_sword/slash1", "frames": 4, "fps": 12.0, "loop": false},
		"slash2": {"path": "res://assets/characters/player/pONE3/mc_t1_sword/slash2", "frames": 4, "fps": 12.0, "loop": false},
		"dodge": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1/dodge", "frames": 1, "fps": 5.0, "loop": false},
		"parry": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1/parry", "frames": 1, "fps": 5.0, "loop": false},
		"guard": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1/parry", "frames": 1, "fps": 5.0, "loop": true},
		"hurt": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1/hurt", "frames": 1, "fps": 5.0, "loop": false},
		"dead": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1/dead", "frames": 2, "fps": 4.0, "loop": false}
	},
	# tier 1 axe
	[&"axe", false]: {
		"stand": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_axe_t1/idle", "frames": 4, "fps": 5.0, "loop": true},
		"walk": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_axe_t1/move", "frames": 4, "fps": 5.5, "loop": true},
		"run": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_axe_t1/move", "frames": 4, "fps": 9.0, "loop": true},
		"slash1": {"path": "res://assets/characters/player/pONE3/mc_t1_axe/slash1", "frames": 4, "fps": 10.0, "loop": false},
		"slash2": {"path": "res://assets/characters/player/pONE3/mc_t1_axe/slash2", "frames": 4, "fps": 10.0, "loop": false},
		"dodge": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1/dodge", "frames": 1, "fps": 5.0, "loop": false},
		"parry": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1/parry", "frames": 1, "fps": 5.0, "loop": false},
		"guard": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1/parry", "frames": 1, "fps": 5.0, "loop": true},
		"hurt": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1/hurt", "frames": 1, "fps": 5.0, "loop": false},
		"dead": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1/dead", "frames": 2, "fps": 4.0, "loop": false}
	},
	# tier 1 shield only
	[&"none", true]: {
		"stand": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_shield_t1/idle", "frames": 4, "fps": 5.0, "loop": true},
		"walk": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_shield_t1/move", "frames": 4, "fps": 6.0, "loop": true},
		"run": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_shield_t1/move", "frames": 4, "fps": 10.0, "loop": true},
		"slash1": {"path": "res://assets/characters/player/pONE3/mc_t1_shield/slash1", "frames": 4, "fps": 12.0, "loop": false},
		"slash2": {"path": "res://assets/characters/player/pONE3/mc_t1_shield/slash2", "frames": 4, "fps": 12.0, "loop": false},
		"dodge": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_shield_t1/dodge", "frames": 1, "fps": 5.0, "loop": false},
		"parry": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_shield_t1/parry", "frames": 1, "fps": 5.0, "loop": false},
		"guard": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_shield_t1/parry", "frames": 1, "fps": 5.0, "loop": true},
		"hurt": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_shield_t1/hurt", "frames": 1, "fps": 5.0, "loop": false},
		"dead": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_shield_t1/dead", "frames": 2, "fps": 4.0, "loop": false}
	},
	# tier 1 sword + shield
	[&"sword", true]: {
		"stand": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_sword_t1_shield_t1/idle", "frames": 4, "fps": 5.0, "loop": true},
		"walk": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_sword_t1_shield_t1/move", "frames": 4, "fps": 6.0, "loop": true},
		"run": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_sword_t1_shield_t1/move", "frames": 4, "fps": 10.0, "loop": true},
		"slash1": {"path": "res://assets/characters/player/pONE3/mc_t1_sword_shield/slash1", "frames": 4, "fps": 12.0, "loop": false},
		"slash2": {"path": "res://assets/characters/player/pONE3/mc_t1_sword_shield/slash2", "frames": 4, "fps": 12.0, "loop": false},
		"dodge": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1_shield_t1/dodge", "frames": 1, "fps": 5.0, "loop": false},
		"parry": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1_shield_t1/parry", "frames": 1, "fps": 5.0, "loop": false},
		"guard": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1_shield_t1/parry", "frames": 1, "fps": 5.0, "loop": true},
		"hurt": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1_shield_t1/hurt", "frames": 1, "fps": 5.0, "loop": false},
		"dead": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_sword_t1_shield_t1/dead", "frames": 2, "fps": 4.0, "loop": false}
	},
	# tier 1 axe + shield
	[&"axe", true]: {
		"stand": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_axe_t1_shield_t1/idle", "frames": 4, "fps": 5.0, "loop": true},
		"walk": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_axe_t1_shield_t1/move", "frames": 4, "fps": 5.5, "loop": true},
		"run": {"path": "res://assets/characters/player/pONE2/mc_pONE2_fstr_v01_boxr_v01_axe_t1_shield_t1/move", "frames": 4, "fps": 9.0, "loop": true},
		"slash1": {"path": "res://assets/characters/player/pONE3/mc_t1_axe_shield/slash1", "frames": 4, "fps": 10.0, "loop": false},
		"slash2": {"path": "res://assets/characters/player/pONE3/mc_t1_axe_shield/slash2", "frames": 4, "fps": 10.0, "loop": false},
		"dodge": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1_shield_t1/dodge", "frames": 1, "fps": 5.0, "loop": false},
		"parry": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1_shield_t1/parry", "frames": 1, "fps": 5.0, "loop": false},
		"guard": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1_shield_t1/parry", "frames": 1, "fps": 5.0, "loop": true},
		"hurt": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1_shield_t1/hurt", "frames": 1, "fps": 5.0, "loop": false},
		"dead": {"path": "res://assets/characters/player/pONE1/mc_pONE1_fstr_v01_boxr_v01_axe_t1_shield_t1/dead", "frames": 2, "fps": 4.0, "loop": false}
	}
}

func _ready() -> void:
	if sprite == null:
		sprite = $Sprite
	if sprite != null:
		sprite.position = base_offset
		sprite.centered = true
	_apply_animation()

func _process(delta: float) -> void:
	if not is_playing:
		return
	
	if _use_sequence:
		_process_sequence(delta)
		return
	
	if total_frames <= 1 or fps <= 0.0:
		return
	
	frame_timer += delta
	var frame_duration: float = 1.0 / fps
	if frame_timer >= frame_duration:
		frame_timer -= frame_duration
		var next_frame: int = frame_index + 1
		if next_frame >= total_frames:
			if is_looping:
				frame_index = 0
				_update_sprite_frame()
			else:
				is_playing = false
				animation_finished.emit(current_action)
		else:
			frame_index = next_frame
			_update_sprite_frame()

# ---- Sequence mode (para run T0 de Mana Seed) ----
# _sequence: Array de {tex: Texture2D, frame: int, dur: float}
func _process_sequence(delta: float) -> void:
	if _sequence.is_empty():
		return
	
	frame_timer += delta
	var step: Dictionary = _sequence[frame_index]
	if frame_timer >= step["dur"]:
		frame_timer -= step["dur"]
		var next: int = frame_index + 1
		if next >= _sequence.size():
			if is_looping:
				frame_index = 0
			else:
				is_playing = false
				animation_finished.emit(current_action)
				return
		else:
			frame_index = next
		_update_sequence_frame()

func _update_sequence_frame() -> void:
	if sprite == null or _sequence.is_empty():
		return
	var step: Dictionary = _sequence[frame_index]
	sprite.texture = step["tex"]
	sprite.hframes = step["hframes"]
	sprite.vframes = 1
	sprite.frame = step["frame"]
	frame_changed.emit(frame_index, _sequence.size())

func _build_run_sequence(dir: String) -> void:
	# Mana Seed run sequence: frames 0,1,RUN0,3,4,RUN1 del walk strip
	# Timings (ms): 80, 55, 125, 80, 55, 125
	var entry = get_action_entry("run")
	var walk_path: String = "%s/%s.png" % [entry["walk_path"], dir]
	var run_path: String = "%s/%s.png" % [entry["run_path"], dir]
	
	var walk_tex: Texture2D = _get_texture(walk_path)
	var run_tex: Texture2D = _get_texture(run_path)
	
	if walk_tex == null or run_tex == null:
		push_error("PlayerVisual: Could not load walk/run textures for sequence")
		return
	
	# Duraciones en segundos
	const MS_TO_S: float = 0.001
	var durs: Array[float] = [80.0*MS_TO_S, 55.0*MS_TO_S, 125.0*MS_TO_S,
	                          80.0*MS_TO_S, 55.0*MS_TO_S, 125.0*MS_TO_S]
	
	_sequence = [
		{"tex": walk_tex, "frame": 0, "hframes": 6, "dur": durs[0]},  # walk frame 1
		{"tex": walk_tex, "frame": 1, "hframes": 6, "dur": durs[1]},  # walk frame 2
		{"tex": run_tex,  "frame": 0, "hframes": 2, "dur": durs[2]},  # run frame 7 (alt frame 3)
		{"tex": walk_tex, "frame": 3, "hframes": 6, "dur": durs[3]},  # walk frame 4
		{"tex": walk_tex, "frame": 4, "hframes": 6, "dur": durs[4]},  # walk frame 5
		{"tex": run_tex,  "frame": 1, "hframes": 2, "dur": durs[5]},  # run frame 8 (alt frame 6)
	]
	
	_use_sequence = true
	total_frames = _sequence.size()

# ---- API pública ----

func set_equipment(p_weapon_id: StringName, p_has_shield: bool, p_tier: int = 1) -> void:
	weapon_id = p_weapon_id
	has_shield = p_has_shield
	tier = p_tier
	_apply_animation(false)

func play(action: String, direction: String = "", custom_fps: float = -1.0, loop_override: Variant = null) -> void:
	var dir_changed: bool = false
	if direction != "" and direction != current_direction:
		current_direction = direction
		dir_changed = true
	
	var action_changed: bool = (action != current_action)
	
	if not action_changed and not dir_changed and is_playing:
		if custom_fps > 0.0:
			fps = custom_fps
		if loop_override != null:
			is_looping = bool(loop_override)
		return
	
	current_action = action
	_apply_animation(true, custom_fps, loop_override)

func set_direction(direction: String) -> void:
	if direction != "" and direction != current_direction:
		current_direction = direction
		_apply_animation(false)

func stop() -> void:
	is_playing = false

func restart() -> void:
	frame_index = 0
	frame_timer = 0.0
	is_playing = true
	if _use_sequence:
		_update_sequence_frame()
	else:
		_update_sprite_frame()

func play_parry_success_flash() -> void:
	if parry_flash_sprite == null:
		return

	if _parry_flash_tween != null and _parry_flash_tween.is_valid():
		_parry_flash_tween.kill()

	parry_flash_sprite.visible = true
	parry_flash_sprite.frame = 0
	parry_flash_sprite.modulate = Color.WHITE
	_parry_flash_tween = create_tween()
	for frame in range(1, 9):
		_parry_flash_tween.tween_callback(_set_parry_flash_frame.bind(frame)).set_delay(0.04)
	_parry_flash_tween.tween_property(parry_flash_sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.08)
	_parry_flash_tween.tween_callback(_hide_parry_flash)

func _set_parry_flash_frame(frame: int) -> void:
	if parry_flash_sprite != null:
		parry_flash_sprite.frame = frame

func _hide_parry_flash() -> void:
	if parry_flash_sprite != null:
		parry_flash_sprite.visible = false

func get_action_entry(action: String) -> Dictionary:
	for key in SPRITE_TABLE:
		if key[0] == weapon_id and key[1] == has_shield:
			var acts: Dictionary = SPRITE_TABLE[key]
			if acts.has(action):
				return acts[action]
	
	# Fallback a none, false
	for key in SPRITE_TABLE:
		if key[0] == &"none" and key[1] == false:
			var acts: Dictionary = SPRITE_TABLE[key]
			if acts.has(action):
				return acts[action]
	return {}

func _apply_animation(reset_frame: bool = true, custom_fps: float = -1.0, loop_override: Variant = null) -> void:
	if sprite == null:
		return
	
	_use_sequence = false
	_sequence.clear()
	
	var entry: Dictionary = get_action_entry(current_action)
	if entry.is_empty():
		push_warning("PlayerVisual: No animation entry for action '%s', weapon '%s', shield '%s'" % [current_action, weapon_id, has_shield])
		return
	
	var dir: String = current_direction
	if dir not in ["down", "up", "left", "right"]:
		dir = "down"
	
	# Modo secuencia: run T0 de Mana Seed
	if entry.get("run_sequence", false):
		is_looping = entry.get("loop", true)
		if reset_frame:
			frame_index = 0
			frame_timer = 0.0
		_build_run_sequence(dir)
		if not _sequence.is_empty():
			sprite.position = base_offset
			sprite.centered = true
			is_playing = true
			_update_sequence_frame()
		return
	
	# Modo normal
	var texture_path: String = "%s/%s.png" % [entry["path"], dir]
	var tex: Texture2D = _get_texture(texture_path)
	if tex == null:
		push_error("PlayerVisual: Could not load texture at '%s'" % texture_path)
		return
	
	total_frames = entry.get("frames", 1)
	if loop_override != null:
		is_looping = bool(loop_override)
	else:
		is_looping = entry.get("loop", true)
	
	if custom_fps > 0.0:
		fps = custom_fps
	else:
		fps = entry.get("fps", 6.0)
	
	sprite.texture = tex
	sprite.hframes = total_frames
	sprite.vframes = 1
	sprite.position = base_offset
	sprite.centered = true
	
	if reset_frame:
		frame_index = 0
		frame_timer = 0.0
	else:
		if frame_index >= total_frames:
			frame_index = 0
	
	is_playing = true
	_update_sprite_frame()

func _update_sprite_frame() -> void:
	if sprite != null:
		sprite.frame = frame_index
		frame_changed.emit(frame_index, total_frames)

func _get_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex = load(path)
	if tex != null:
		_texture_cache[path] = tex
	return tex
