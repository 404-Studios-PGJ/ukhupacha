class_name HybridGeometry
extends Control

@export_enum("architecture", "title", "pause", "helix", "sword", "axe", "shield", "none") var kind: String = "architecture"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var gold: Color = UIAssets.color(&"gold")
	var warm: Color = UIAssets.color(&"warm_charcoal")
	match kind:
		"architecture":
			for x: int in range(-80, 700, 40):
				draw_line(Vector2(x, 360), Vector2(x + 100, 0), UIAssets.color(&"warm_charcoal"))
		"title", "pause":
			var w: float = size.x
			var h: float = size.y
			var points: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2(w - 36, 0), Vector2(w, h / 2), Vector2(w - 36, h), Vector2(0, h), Vector2.ZERO])
			draw_colored_polygon(points, warm)
			draw_polyline(points, gold, 1.0)
		"helix":
			var center: Vector2 = size / 2
			draw_arc(center, 88, 0.25, 5.85, 64, UIAssets.color(&"helix_green"), 2)
			draw_arc(center, 65, 0.8, 5.5, 48, gold, 1)
			draw_line(center + Vector2(0, -78), center + Vector2(0, 78), UIAssets.color(&"muted_green"))
			for y: int in [-54, -18, 18, 54]:
				draw_circle(center + Vector2(0, y), 4, gold, false)
				draw_line(center + Vector2(5, y), center + Vector2(58, y), UIAssets.color(&"outline"))
		"sword", "axe":
			draw_line(Vector2(8, 26), Vector2(25, 6), gold, 3)
			draw_line(Vector2(7, 18), Vector2(17, 26), gold, 2)
			if kind == "axe":
				draw_arc(Vector2(20, 10), 8, -1.5, 1, 8, gold, 5)
		"shield":
			draw_colored_polygon(PackedVector2Array([Vector2(7, 6), Vector2(25, 6), Vector2(25, 19), Vector2(16, 28), Vector2(7, 19)]), UIAssets.color(&"helix_green"))
		"none":
			draw_circle(Vector2(16, 16), 6, gold, false, 2)
