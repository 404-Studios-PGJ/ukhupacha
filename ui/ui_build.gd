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
	if variant in [&"Dossier", &"Knowledge"]:
		node.material = UIAssets.ink(&"panel" if variant == &"Dossier" else &"warm_charcoal")
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


static func icon(parent: Node, id: StringName, bounds: Rect2, tint: StringName = &"warm_cream") -> TextureRect:
	var node: TextureRect = TextureRect.new()
	node.texture = UIAssets.texture(id)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.self_modulate = UIAssets.color(tint)
	node.material = UIAssets.ink(tint)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(node, parent, bounds)
	return node


static func patch(parent: Node, id: StringName, bounds: Rect2, tint: StringName) -> NinePatchRect:
	var node: NinePatchRect = NinePatchRect.new()
	node.texture = UIAssets.texture(id)
	node.patch_margin_left = 5
	node.patch_margin_top = 5
	node.patch_margin_right = 5
	node.patch_margin_bottom = 5
	node.self_modulate = UIAssets.color(tint)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(node, parent, bounds)
	return node


static func rule(parent: Node, bounds: Rect2, token: StringName = &"gold") -> ColorRect:
	var node: ColorRect = ColorRect.new()
	node.color = UIAssets.color(token)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(node, parent, bounds)
	return node


static func header(parent: Node, title: String, metadata: String) -> void:
	label(parent, title, Rect2(24, 9, 420, 28), &"Heading")
	label(parent, metadata, Rect2(460, 15, 160, 18), &"Muted")
	rule(parent, Rect2(0, 44, 640, 2))


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
