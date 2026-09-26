class_name UIBuild
extends RefCounted


static func place(node: Control, parent: Node, bounds: Rect2) -> void:
	parent.add_child(node)
	node.position = bounds.position
	node.size = bounds.size


static func label(parent: Node, text: String, bounds: Rect2, variant: StringName = &"Label") -> Label:
	var node: Label = Label.new()
	node.text = text
	node.theme_type_variation = variant
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(node, parent, bounds)
	return node


static func panel(parent: Node, bounds: Rect2, variant: StringName = &"Panel") -> Panel:
	var node: Panel = Panel.new()
	node.theme_type_variation = variant
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(node, parent, bounds)
	return node


static func button(parent: Node, text: String, bounds: Rect2, action: Callable, primary: bool = false) -> Button:
	var node: Button = Button.new()
	node.text = text
	if primary:
		node.theme_type_variation = &"PrimaryButton"
	node.pressed.connect(func() -> void: MusicDirector.play_sfx(&"menu"))
	node.pressed.connect(action)
	place(node, parent, bounds)
	return node


static func footer(parent: Node, text: String) -> Label:
	var node: Label = label(parent, text, Rect2(12, 340, 616, 20), &"Small")
	node.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	node.offset_left = 12
	node.offset_top = -20
	node.offset_right = -12
	return node


static func screen(root: Control) -> void:
	root.theme = UIAssets.theme_resource()
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.custom_minimum_size = Vector2(640, 360)


static func input_enabled(player: Node) -> bool:
	if not is_instance_valid(player):
		return false
	if player.has_method("is_input_enabled"):
		return bool(player.call("is_input_enabled"))
	for property: Dictionary in player.get_property_list():
		if property["name"] == &"input_enabled":
			return bool(player.get("input_enabled"))
	return false


static func state(player: Node) -> Dictionary:
	if is_instance_valid(player) and player.has_method("get_hud_state"):
		var result: Variant = player.call("get_hud_state")
		if result is Dictionary:
			return result
	return {}


static func hit_area(parent: Control, bounds: Rect2, action: Callable, name: String = "") -> Button:
	var hit_button := Button.new()
	hit_button.text = ""
	hit_button.flat = true
	for style_state: String in ["normal", "hover", "pressed", "disabled"]:
		hit_button.add_theme_stylebox_override(style_state, StyleBoxEmpty.new())
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color.TRANSPARENT
	focus_style.draw_center = false
	focus_style.border_color = UIAssets.color(&"light_gold")
	focus_style.set_border_width_all(1)
	hit_button.add_theme_stylebox_override("focus", focus_style)
	hit_button.pressed.connect(action)
	hit_button.name = name
	place(hit_button, parent, bounds)
	hit_button.z_index = 100
	return hit_button
