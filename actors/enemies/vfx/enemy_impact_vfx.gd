class_name EnemyImpactVfx extends Node2D
## Efecto breve dibujado con primitivas que se borra solo.
## Se crea en el padre del enemigo para que sobreviva a su muerte.

enum Kind { HIT, CRITICAL, BLOCK, PARRY, DEATH }

const DURATION : Dictionary = {
	Kind.HIT: 0.18,
	Kind.CRITICAL: 0.28,
	Kind.BLOCK: 0.22,
	Kind.PARRY: 0.30,
	Kind.DEATH: 0.45,
}
const COLOR_HIT : Color = Color("ffffff")
const COLOR_CRITICAL : Color = Color("ffd23f")
const COLOR_BLOCK : Color = Color("ffe08a")
const COLOR_DEATH : Color = Color(0.6, 0.6, 0.65)

var kind : Kind = Kind.HIT
var direction : Vector2 = Vector2.RIGHT
var _t : float = 0.0


static func spawn(host: Node2D, at: Vector2, vfx_kind: Kind, towards: Vector2 = Vector2.RIGHT) -> void:
	var parent := host.get_parent()
	if parent == null:
		return
	var vfx := EnemyImpactVfx.new()
	vfx.kind = vfx_kind
	vfx.direction = towards.normalized() if towards != Vector2.ZERO else Vector2.RIGHT
	vfx.position = (parent as Node2D).to_local(at) if parent is Node2D else at
	vfx.z_index = 10
	# Diferido: suele llamarse desde callbacks de física.
	parent.add_child.call_deferred(vfx)


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION[kind]:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var p : float = _t / DURATION[kind]
	match kind:
		Kind.HIT:
			_draw_rays(4, 3.0, 9.0, p, COLOR_HIT, 0.25 * PI)
		Kind.CRITICAL:
			_draw_rays(8, 4.0, 14.0, p, COLOR_CRITICAL, 0.0)
			draw_arc(Vector2.ZERO, lerpf(4.0, 12.0, p), 0.0, TAU, 20, Color(COLOR_CRITICAL, 1.0 - p), 1.5)
		Kind.BLOCK:
			# Chispas en abanico hacia quien golpeó y destello del escudo.
			for i in 5:
				var angle := direction.angle() + (i - 2) * 0.35
				var from := Vector2.from_angle(angle) * lerpf(2.0, 6.0, p)
				draw_line(from, from + Vector2.from_angle(angle) * 4.0, Color(COLOR_BLOCK, 1.0 - p), 1.5)
			draw_circle(Vector2.ZERO, lerpf(5.0, 2.0, p), Color(COLOR_HIT, 0.8 * (1.0 - p)))
		Kind.PARRY:
			draw_arc(Vector2.ZERO, lerpf(3.0, 18.0, p), 0.0, TAU, 24, Color(COLOR_HIT, 1.0 - p), 2.0)
			_draw_rays(4, 2.0, 12.0, p, COLOR_HIT, 0.0)
		Kind.DEATH:
			draw_arc(Vector2.ZERO, lerpf(4.0, 16.0, p), 0.0, TAU, 20, Color(COLOR_DEATH, 1.0 - p), 2.0)
			for i in 6:
				var dot := Vector2.from_angle(i * TAU / 6.0) * lerpf(4.0, 14.0, p) + Vector2(0, -6.0 * p)
				draw_circle(dot, 1.5, Color(COLOR_DEATH, 1.0 - p))


func _draw_rays(count: int, start: float, end: float, p: float, color: Color, offset: float) -> void:
	for i in count:
		var ray := Vector2.from_angle(offset + i * TAU / count)
		draw_line(ray * lerpf(start, end * 0.6, p), ray * lerpf(start + 3.0, end, p), Color(color, 1.0 - p), 1.5)
