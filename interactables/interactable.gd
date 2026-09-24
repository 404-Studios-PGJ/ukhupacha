class_name Interactable
extends Area2D

signal interacted(player: Node)

const DialogScript = preload("res://ui/interaction_dialog.gd")
@export_range(1.0, 24.0, 1.0) var radius: float = 24.0
@export var display_name: String = "Interactuar"
@export var tint: Color = Color("#c99745")
var interaction_count: int = 0
var _prompt: Label
var _dialog: InteractionDialog


func _ready() -> void:
	add_to_group(&"interactables")
	collision_layer = 128
	collision_mask = 0
	monitoring = false
	var shape_node: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		add_child(shape_node)
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	shape_node.shape = circle
	_prompt = Label.new()
	_prompt.text = "E"
	_prompt.position = Vector2(-5, -32)
	_prompt.add_theme_font_size_override("font_size", 14)
	_prompt.visible = false
	add_child(_prompt)
	queue_redraw()


func is_available() -> bool:
	return true


func set_focused(focused: bool) -> void:
	if is_instance_valid(_prompt):
		_prompt.visible = focused and is_available()


func interact(player: Node) -> void:
	if not is_available():
		return
	interaction_count += 1
	interacted.emit(player)


func show_dialog(player: Node, heading: String, body: String) -> InteractionDialog:
	if is_instance_valid(_dialog):
		_dialog.close()
	var dialog: InteractionDialog = DialogScript.new()
	_dialog = dialog
	add_child(dialog)
	dialog.setup(player, heading, body)
	return dialog


func _draw() -> void:
	draw_rect(Rect2(-9, -12, 18, 24), tint)
	draw_rect(Rect2(-6, -9, 12, 6), Color("#1b1d1f"))
