class_name EnemyTelegraph extends Node2D
## Avisos sobre la cabeza: "?" amarillo (sospecha), "!" rojo (detección)
## y el aviso de ataque. Blanco = rombo (parry); rojo = triángulo (esquiva).
## La forma cambia además del color para que se lea sin depender del color.

enum Mode { NONE, SUSPICIOUS, ALERT, ATTACK_WHITE, ATTACK_RED }

const COLOR_SUSPICIOUS : Color = Color("ffd23f")
const COLOR_ALERT : Color = Color("ff3b3b")
const COLOR_WHITE : Color = Color("ffffff")
const COLOR_RED : Color = Color("ff2a2a")
const COLOR_OUTLINE : Color = Color("10131a")
const BURST_TIME : float = 0.15
const FONT_SIZE : int = 14

var mode : Mode = Mode.NONE
var _time_left : float = 0.0
var _elapsed : float = 0.0


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
	match mode:
		Mode.SUSPICIOUS:
			_draw_symbol("?", COLOR_SUSPICIOUS)
		Mode.ALERT:
			_draw_symbol("!", COLOR_ALERT)
		Mode.ATTACK_WHITE:
			_draw_attack(COLOR_WHITE, false)
		Mode.ATTACK_RED:
			_draw_attack(COLOR_RED, true)


func _draw_symbol(text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var baseline := Vector2(-10, 5)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, 20, FONT_SIZE, 4, COLOR_OUTLINE)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, 20, FONT_SIZE, color)


func _draw_attack(color: Color, red: bool) -> void:
	# Destello inicial: anillo que se expande al empezar el windup.
	var burst := clampf(_elapsed / BURST_TIME, 0.0, 1.0)
	if burst < 1.0:
		draw_arc(Vector2.ZERO, lerpf(4.0, 14.0, burst), 0.0, TAU, 24, Color(color, 1.0 - burst), 2.0)

	var pulse := 1.0 + 0.15 * sin(_elapsed * (30.0 if red else 18.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(pulse, pulse))
	var shape : PackedVector2Array
	if red:
		shape = PackedVector2Array([Vector2(0, -7), Vector2(7, 5), Vector2(-7, 5)])
	else:
		shape = PackedVector2Array([Vector2(0, -6), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)])
	var outline := shape.duplicate()
	outline.append(shape[0])
	draw_polyline(outline, COLOR_OUTLINE, 3.0)
	draw_colored_polygon(shape, color)
	if red:
		draw_line(Vector2(0, -3), Vector2(0, 1), COLOR_OUTLINE, 2.0)
		draw_rect(Rect2(-1, 2, 2, 2), COLOR_OUTLINE)
	draw_set_transform(Vector2.ZERO)
