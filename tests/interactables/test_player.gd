extends CharacterBody2D
## Doble mínimo exclusivo del laboratorio; no sustituye al Player de Jhon.

var input_enabled: bool = true
var weapon_id: StringName = &"none"
var shield: bool = false
var equip_calls: int = 0


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = 2
	collision_mask = 5
	Level1Progress.progress_reset.connect(_on_reset)


func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("izquierda", "derecha", "arriba", "abajo") * 80.0 if input_enabled else Vector2.ZERO
	move_and_slide()


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func is_input_enabled() -> bool:
	return input_enabled


func equip_weapon(id: StringName) -> void:
	weapon_id = id
	equip_calls += 1


func equip_shield() -> void:
	shield = true
	equip_calls += 1


func _on_reset() -> void:
	weapon_id = &"none"
	shield = false
	equip_calls = 0
	input_enabled = true


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color("#d8c7a2"))
	draw_line(Vector2.ZERO, Vector2(0, -10), Color("#76518f"), 2.0)
