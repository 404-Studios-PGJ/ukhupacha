class_name EnemyPlaceholderVisual extends Node2D
## Guardia dibujado con primitivas hasta que existan sprites.
## Muestra orientación, postura de windup, golpe, stagger, vida y muerte.

@export var body_color : Color = Color("3d5a80")
@export var trim_color : Color = Color("98c1d9")
@export var weapon_color : Color = Color("c8c8c8")

const LEG_COLOR : Color = Color("1f2a3a")
const SHADOW_COLOR : Color = Color(0, 0, 0, 0.35)
const DEAD_COLOR : Color = Color(0.35, 0.35, 0.4, 0.8)
const STAR_COLOR : Color = Color("ffd23f")
const CRITICAL_FLASH : Color = Color("ffd23f")

var _flash_time : float = 0.0
var _flash_critical : bool = false
var _t : float = 0.0

@onready var enemy : EnemyBase = get_parent()


func flash(critical: bool) -> void:
	_flash_time = 0.2 if critical else 0.12
	_flash_critical = critical


func _process(delta: float) -> void:
	_t += delta
	_flash_time = maxf(_flash_time - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 8.0, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO)

	if enemy.state == EnemyBase.State.DEAD:
		draw_rect(Rect2(-10, -6, 20, 6), DEAD_COLOR)
		draw_circle(Vector2(8, -3), 4.0, DEAD_COLOR)
		return

	var f := enemy.facing
	var attack_color := _attack_color()
	var red := enemy.current_attack != null and enemy.current_attack.kind == EnemyAttack.Kind.RED

	# Postura: se agacha en el windup, más si el ataque es rojo.
	var crouch := 0.0
	if enemy.state == EnemyBase.State.WINDUP:
		crouch = 3.0 if red else 1.5
	var up := Vector2(0, crouch)

	var body := body_color
	if _flash_time > 0.0:
		body = CRITICAL_FLASH if _flash_critical else Color.WHITE

	draw_rect(Rect2(-5, -7, 4, 7), LEG_COLOR)
	draw_rect(Rect2(1, -7, 4, 7), LEG_COLOR)
	draw_rect(Rect2(Vector2(-6, -21) + up, Vector2(12, 14)), body)
	draw_rect(Rect2(Vector2(-6, -10) + up, Vector2(12, 2)), trim_color)
	var head := Vector2(0, -26) + up
	draw_circle(head, 5.0, body.darkened(0.2))
	# Visor: indica hacia dónde mira.
	draw_circle(head + f * 3.0, 1.8, trim_color)

	_draw_weapon(f, Vector2(0, -14) + up + f * 4.0, attack_color)

	if enemy.state == EnemyBase.State.STAGGER:
		for i in 3:
			var angle := _t * 6.0 + i * TAU / 3.0
			draw_circle(head + Vector2(cos(angle) * 8.0, sin(angle) * 3.0 - 6.0), 1.5, STAR_COLOR)

	if enemy.hp < enemy.stats.max_hp:
		var ratio := enemy.hp / enemy.stats.max_hp
		draw_rect(Rect2(-8, -36, 16, 2), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-8, -36, 16 * ratio, 2), Color("e63946"))


func _draw_weapon(f: Vector2, hand: Vector2, attack_color: Color) -> void:
	match enemy.state:
		EnemyBase.State.WINDUP:
			# Arma atrás y en alto, con el color del aviso.
			draw_line(hand, hand - f * 6.0 + Vector2(0, -10), attack_color, 2.5)
		EnemyBase.State.ACTIVE:
			var reach := enemy.stats.attack_range
			draw_line(hand, hand + f * (reach - 4.0), weapon_color, 2.0)
			draw_arc(Vector2(0, -12), reach, f.angle() - 0.6, f.angle() + 0.6, 12, Color(attack_color, 0.8), 3.0)
		EnemyBase.State.RECOVERY:
			draw_line(hand, hand + f * 6.0 + Vector2(0, 6), weapon_color.darkened(0.3), 2.0)
		_:
			draw_line(hand, hand + f * 8.0 + Vector2(0, 4), weapon_color, 2.0)


func _attack_color() -> Color:
	if enemy.current_attack != null and enemy.current_attack.kind == EnemyAttack.Kind.RED:
		return EnemyTelegraph.COLOR_RED
	return EnemyTelegraph.COLOR_WHITE
