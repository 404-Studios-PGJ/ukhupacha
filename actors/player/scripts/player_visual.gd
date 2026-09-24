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

var frame_index: int = 0
var total_frames: int = 1
var frame_timer: float = 0.0
var fps: float = 6.0
var is_looping: bool = true
var is_playing: bool = true

@onready var sprite: Sprite2D = $Sprite

# Cache textures in memory to prevent repeated disk I/O
var _texture_cache: Dictionary = {}

# Explicit mapping table for tier 0 and tier 1
const SPRITE_TABLE: Dictionary = {
	# tier 0 (unarmed / none)
	[&"none", false]: {
		"stand": {"path": "res://assets/characters/player/p1/mc_p1_boxr_v01_base/stand", "frames": 1, "fps": 1.0, "loop": true},
		"walk": {"path": "res://assets/characters/player/p1/mc_p1_boxr_v01_base/walk", "frames": 6, "fps": 7.4, "loop": true},
		"run": {"path": "res://assets/characters/player/p1/mc_p1_boxr_v01_base/run", "frames": 2, "fps": 6.0, "loop": true},
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
	if not is_playing or total_frames <= 1 or fps <= 0.0:
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
	_update_sprite_frame()

func get_action_entry(action: String) -> Dictionary:
	for key in SPRITE_TABLE:
		if key[0] == weapon_id and key[1] == has_shield:
			var acts: Dictionary = SPRITE_TABLE[key]
			if acts.has(action):
				return acts[action]
	
	# Fallback to none, false
	for key in SPRITE_TABLE:
		if key[0] == &"none" and key[1] == false:
			var acts: Dictionary = SPRITE_TABLE[key]
			if acts.has(action):
				return acts[action]
	return {}

func _apply_animation(reset_frame: bool = true, custom_fps: float = -1.0, loop_override: Variant = null) -> void:
	if sprite == null:
		return
	
	var entry: Dictionary = get_action_entry(current_action)
	if entry.is_empty():
		push_warning("PlayerVisual: No animation entry for action '%s', weapon '%s', shield '%s'" % [current_action, weapon_id, has_shield])
		return
	
	var dir: String = current_direction
	if dir not in ["down", "up", "left", "right"]:
		dir = "down"
	
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
