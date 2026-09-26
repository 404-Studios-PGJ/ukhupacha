class_name EnemyImpactVfx extends Node2D
## Efecto breve con sprites que se borra solo: chispas animadas (Spark effect
## de kurohina, CC0) y polvo (Kenney 1-Bit Pack, CC0), teñidos en
## sprites/fx/bake_fx.py. Se crea en el padre del enemigo para que sobreviva
## a su muerte.

enum Kind { HIT, CRITICAL, BLOCK, PARRY, DEATH, MUZZLE, SLAM }

const DURATION : Dictionary = {
	Kind.HIT: 0.18,
	Kind.CRITICAL: 0.28,
	Kind.BLOCK: 0.22,
	Kind.PARRY: 0.30,
	Kind.DEATH: 0.45,
	Kind.MUZZLE: 0.08,
	Kind.SLAM: 0.45,
}
## Tira de frames cuadrados y escala de cada efecto.
const STRIPS : Dictionary = {
	Kind.HIT: [preload("res://actors/enemies/sprites/fx/spark_hit.png"), 0.5],
	Kind.CRITICAL: [preload("res://actors/enemies/sprites/fx/spark_critical.png"), 1.0],
	Kind.BLOCK: [preload("res://actors/enemies/sprites/fx/spark_block.png"), 0.5],
	Kind.PARRY: [preload("res://actors/enemies/sprites/fx/spark_block.png"), 1.0],
	Kind.MUZZLE: [preload("res://actors/enemies/sprites/fx/muzzle_flash.png"), 0.5],
	Kind.SLAM: [preload("res://actors/enemies/sprites/fx/spark_slam.png"), 2.0],
}
const DEATH_DUST : Texture2D = preload("res://actors/enemies/sprites/fx/death_dust.png")
## El polvo de la muerte sube y se desvanece.
const DEATH_RISE : float = 8.0

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
	# Por encima de los tiles y decorados del nivel.
	vfx.z_index = 20
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
	if kind == Kind.DEATH:
		var size := DEATH_DUST.get_size()
		draw_texture(DEATH_DUST, -size / 2.0 + Vector2(0, -DEATH_RISE * p), Color(1, 1, 1, 1.0 - p))
		return
	var strip : Texture2D = STRIPS[kind][0]
	var scale_factor : float = STRIPS[kind][1]
	var side := strip.get_height()
	var frames := strip.get_width() / side
	var frame := mini(int(p * frames), frames - 1)
	var size := Vector2(side, side) * scale_factor
	draw_texture_rect_region(strip, Rect2(-size / 2.0, size), Rect2(frame * side, 0, side, side))
