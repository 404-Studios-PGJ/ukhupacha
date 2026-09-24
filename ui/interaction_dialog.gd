class_name InteractionDialog
extends CanvasLayer
## Vista funcional: texto runtime y geometría propia. Acabado Hybrid v2 posterior.

var _player: Node
var _locked_player: bool = false
var _body: Label
var _choices: VBoxContainer


func setup(player: Node, heading: String, body: String) -> void:
	_player = player
	layer = 20
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color("#1b1d1ff5")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var panel: VBoxContainer = VBoxContainer.new()
	panel.position = Vector2(24, 18)
	panel.size = Vector2(592, 324)
	panel.add_theme_constant_override("separation", 6)
	add_child(panel)
	var title: Label = Label.new()
	title.text = heading
	title.add_theme_color_override("font_color", Color("#e0bd6d"))
	panel.add_child(title)
	_body = Label.new()
	_body.text = body
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(580, 66)
	_body.add_theme_font_size_override("font_size", 14)
	panel.add_child(_body)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 4)
	panel.add_child(_choices)
	if is_instance_valid(_player) and _player.has_method("set_input_enabled"):
		_player.call("set_input_enabled", false)
		_locked_player = true
	Level1Progress.progress_reset.connect(close)


func add_choice(caption: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.add_theme_font_size_override("font_size", 14)
	button.custom_minimum_size.y = 28
	button.pressed.connect(action)
	_choices.add_child(button)
	if _choices.get_child_count() == 1:
		button.grab_focus()
	return button


func set_body(body: String) -> void:
	_body.text = body


func close() -> void:
	if is_instance_valid(_player) and _locked_player:
		_player.call("set_input_enabled", true)
	_locked_player = false
	queue_free()


func _exit_tree() -> void:
	if is_instance_valid(_player) and _locked_player:
		_player.call("set_input_enabled", true)
