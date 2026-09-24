class_name DoorGate
extends StaticBody2D

@export_enum("door_1", "door_4", "rift") var door_id: String = "door_1"
@export var gate_size: Vector2 = Vector2(16, 48)
var opened: bool = false
var _collider: CollisionShape2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 6
	_collider = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _collider == null:
		_collider = CollisionShape2D.new()
		add_child(_collider)
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = gate_size
	_collider.shape = rectangle
	Level1Progress.door_state_changed.connect(_on_door_state_changed)
	_apply_state(Level1Progress.is_door_open(StringName(door_id)))


func _on_door_state_changed(changed_id: StringName, is_open: bool) -> void:
	if changed_id == StringName(door_id):
		_apply_state(is_open)


func _apply_state(is_open: bool) -> void:
	opened = is_open
	_collider.set_deferred("disabled", opened)
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(-gate_size / 2.0, gate_size)
	if opened:
		draw_rect(rect, Color("#4f9b68"), false, 2.0)
	else:
		draw_rect(rect, Color("#a94b4b"))
