class_name EnemyTelegraph extends Node2D
## Avisos sobre la cabeza: "?" amarillo (sospecha), "!" rojo (detección)
## y el aviso de ataque. Blanco = destello (parry); rojo = triángulo (esquiva).
## La forma cambia además del color para que se lea sin depender del color.
## Sprites de Kenney 1-Bit Pack (CC0), teñidos en sprites/fx/bake_fx.py.

enum Mode { NONE, SUSPICIOUS, ALERT, ATTACK_WHITE, ATTACK_RED }

## Colores de cada tipo de ataque (los usa también el aspecto provisional).
const COLOR_WHITE : Color = Color("ffffff")
const COLOR_RED : Color = Color("ff2a2a")
const ICONS : Dictionary = {
	Mode.SUSPICIOUS: preload("res://actors/enemies/sprites/fx/telegraph_suspicious.png"),
	Mode.ALERT: preload("res://actors/enemies/sprites/fx/telegraph_alert.png"),
	Mode.ATTACK_WHITE: preload("res://actors/enemies/sprites/fx/telegraph_white.png"),
	Mode.ATTACK_RED: preload("res://actors/enemies/sprites/fx/telegraph_red.png"),
}
## Cada aviso suena distinto para no depender solo del color.
const SOUNDS : Dictionary = {
	Mode.SUSPICIOUS: preload("res://actors/enemies/sfx/suspicious.wav"),
	Mode.ALERT: preload("res://actors/enemies/sfx/alert.wav"),
	Mode.ATTACK_WHITE: preload("res://actors/enemies/sfx/telegraph_white.wav"),
	Mode.ATTACK_RED: preload("res://actors/enemies/sfx/telegraph_red.wav"),
}
const VOLUME_DB : Dictionary = {
	Mode.SUSPICIOUS: -12.0,
	Mode.ALERT: -8.0,
	Mode.ATTACK_WHITE: -6.0,
	Mode.ATTACK_RED: -2.0,
}

## Bus de audio de los avisos (por ejemplo, "SFX" cuando exista).
@export var audio_bus : StringName = &"Master"

var mode : Mode = Mode.NONE
var _time_left : float = 0.0
var _elapsed : float = 0.0
var _audio : AudioStreamPlayer2D


func _ready() -> void:
	_audio = AudioStreamPlayer2D.new()
	_audio.bus = audio_bus
	_audio.max_distance = 400.0
	add_child(_audio)


func show_suspicious(seconds: float) -> void:
	_show(Mode.SUSPICIOUS, seconds)


func show_alert(seconds: float) -> void:
	_show(Mode.ALERT, seconds)


## Se mantiene hasta clear(): dura todo el windup y no cambia de tipo.
func show_attack(kind: EnemyAttack.Kind) -> void:
	_show(Mode.ATTACK_RED if kind == EnemyAttack.Kind.RED else Mode.ATTACK_WHITE, -1.0)


func clear() -> void:
	mode = Mode.NONE
	queue_redraw()


func is_attack_warning() -> bool:
	return mode == Mode.ATTACK_WHITE or mode == Mode.ATTACK_RED


func _show(new_mode: Mode, seconds: float) -> void:
	# Un "?" o "!" no tapa un aviso de ataque en curso.
	if is_attack_warning() and (new_mode == Mode.SUSPICIOUS or new_mode == Mode.ALERT):
		return
	mode = new_mode
	_time_left = seconds
	_elapsed = 0.0
	queue_redraw()
	_audio.stream = SOUNDS[new_mode]
	_audio.volume_db = VOLUME_DB[new_mode]
	_audio.play()


func _process(delta: float) -> void:
	if mode == Mode.NONE:
		return
	_elapsed += delta
	if _time_left >= 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			clear()
			return
	queue_redraw()


func _draw() -> void:
	if mode == Mode.NONE:
		return
	var icon : Texture2D = ICONS[mode]
	# El aviso de ataque late; el rojo, más rápido.
	var pulse := 1.0
	if is_attack_warning():
		pulse += 0.15 * sin(_elapsed * (30.0 if mode == Mode.ATTACK_RED else 18.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(pulse, pulse))
	draw_texture(icon, -icon.get_size() / 2.0)
	draw_set_transform(Vector2.ZERO)
