class_name EnemyOverlay
## Piezas comunes que dibujan los aspectos de los enemigos con sprites:
## sombra, barra de vida y estrellas de aturdido.

const SHADOW : Texture2D = preload("res://actors/enemies/sprites/fx/shadow.png")
const HP_BACK : Texture2D = preload("res://actors/enemies/sprites/fx/hp_bar_back.png")
const HP_FILL : Texture2D = preload("res://actors/enemies/sprites/fx/hp_bar_fill.png")
const STUN_STAR : Texture2D = preload("res://actors/enemies/sprites/fx/stun_star.png")
const SHADOW_ALPHA : Color = Color(1, 1, 1, 0.7)
const STAR_SIZE : Vector2 = Vector2(8, 8)


## Sombra centrada en los pies, del ancho pedido.
static func draw_shadow(canvas: CanvasItem, width: float) -> void:
	var size := Vector2(width, width * SHADOW.get_height() / SHADOW.get_width())
	canvas.draw_texture_rect(SHADOW, Rect2(-size / 2.0, size), false, SHADOW_ALPHA)


## Barra de vida con su borde superior en `top` (centrada en x).
static func draw_hp_bar(canvas: CanvasItem, top: Vector2, ratio: float, width: float = 24.0) -> void:
	var height := HP_BACK.get_height()
	var rect := Rect2(top.x - width / 2.0, top.y, width, height)
	canvas.draw_texture_rect(HP_BACK, rect, false)
	ratio = clampf(ratio, 0.0, 1.0)
	canvas.draw_texture_rect_region(HP_FILL, Rect2(rect.position, Vector2(width * ratio, height)),
			Rect2(0, 0, HP_FILL.get_width() * ratio, height))


## Tres estrellas girando alrededor de la cabeza.
static func draw_stun_stars(canvas: CanvasItem, head: Vector2, t: float, spread: float = 8.0) -> void:
	for i in 3:
		var angle := t * 6.0 + i * TAU / 3.0
		var center := head + Vector2(cos(angle) * spread, sin(angle) * 3.0 + 4.0)
		canvas.draw_texture_rect(STUN_STAR, Rect2(center - STAR_SIZE / 2.0, STAR_SIZE), false)
