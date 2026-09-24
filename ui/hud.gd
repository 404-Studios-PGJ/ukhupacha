class_name GameHUD
extends CanvasLayer

var player: Node
var snapshot: Dictionary = {}
var _health: TextureProgressBar
var _stamina: TextureProgressBar
var _hp_text: Label
var _st_text: Label
var _weapon: HybridGeometry
var _shield: HybridGeometry
var _prompt: Control
var _prompt_text: Label


func _ready() -> void:
	if get_tree().get_first_node_in_group(&"game_hud") != null:
		queue_free()
		return
	add_to_group(&"game_hud")
	layer = 10
	var root: Control = Control.new()
	root.name = "SafeArea"
	add_child(root)
	UIBuild.screen(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIBuild.panel(root, Rect2(8, 8, 176, 44), &"StatusRail")
	UIBuild.rule(root, Rect2(15, 11, 157, 1))
	UIBuild.icon(root, &"heart", Rect2(12, 18, 13, 10), &"health_red")
	UIBuild.icon(root, &"energy", Rect2(12, 31, 12, 14), &"helix_green")
	_health = _bar(root, Vector2(28, 18), &"health_red")
	_stamina = _bar(root, Vector2(28, 33), &"helix_green")
	_hp_text = UIBuild.label(root, "—", Rect2(151, 15, 32, 14), &"Small")
	_st_text = UIBuild.label(root, "—", Rect2(151, 30, 32, 14), &"Small")
	var kit: Control = Control.new()
	UIBuild.place(kit, root, Rect2(546, 8, 86, 48))
	kit.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	kit.offset_left = -94
	kit.offset_right = -8
	kit.offset_top = 8
	kit.offset_bottom = 56
	UIBuild.panel(kit, Rect2(0, 0, 86, 48), &"StatusRail")
	UIBuild.icon(kit, &"selected", Rect2(5, 7, 32, 32), &"gold")
	UIBuild.icon(kit, &"slot", Rect2(44, 7, 32, 32), &"outline")
	_weapon = HybridGeometry.new()
	_shield = HybridGeometry.new()
	UIBuild.place(_weapon, kit, Rect2(5, 7, 32, 32))
	UIBuild.place(_shield, kit, Rect2(44, 7, 32, 32))
	_prompt = Control.new()
	UIBuild.place(_prompt, root, Rect2(236, 296, 164, 24))
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -84
	_prompt.offset_right = 80
	_prompt.offset_top = -64
	_prompt.offset_bottom = -40
	UIBuild.panel(_prompt, Rect2(0, 0, 164, 24), &"WarmPanel")
	_prompt_text = UIBuild.label(_prompt, "E · INTERACTUAR", Rect2(10, 4, 144, 18), &"Accent")
	_prompt.visible = false
	bind_player(player if is_instance_valid(player) else get_tree().get_first_node_in_group(&"player"))


func _bar(parent: Node, at: Vector2, token: StringName) -> TextureProgressBar:
	var bar: TextureProgressBar = TextureProgressBar.new()
	bar.texture_under = UIAssets.texture(&"bar")
	bar.texture_progress = UIAssets.texture(&"fill_health" if token == &"health_red" else &"fill")
	bar.tint_progress = UIAssets.color(token)
	bar.tint_under = UIAssets.color(&"outline")
	bar.nine_patch_stretch = true
	bar.stretch_margin_left = 3
	bar.stretch_margin_right = 3
	bar.max_value = 100
	UIBuild.place(bar, parent, Rect2(at, Vector2(116, 8)))
	return bar


func bind_player(value: Node) -> void:
	if not is_instance_valid(_health):
		player = value
		return
	for pair: Array in [["health_changed", _on_health], ["stamina_changed", _on_stamina], ["equipment_changed", _on_equipment]]:
		if is_instance_valid(player) and player.has_signal(pair[0]) and player.is_connected(pair[0], pair[1]):
			player.disconnect(pair[0], pair[1])
	player = value
	snapshot = UIBuild.state(player)
	_on_health(float(snapshot.get("health", 0)), float(snapshot.get("max_health", 100)))
	_on_stamina(float(snapshot.get("stamina", 0)), float(snapshot.get("max_stamina", 100)))
	_on_equipment(snapshot.get("weapon_id", &"none"), bool(snapshot.get("shield", false)), int(snapshot.get("tier", 0)))
	if not is_instance_valid(player):
		return
	for pair: Array in [["health_changed", _on_health], ["stamina_changed", _on_stamina], ["equipment_changed", _on_equipment]]:
		if player.has_signal(pair[0]):
			player.connect(pair[0], pair[1])


func _on_health(current: float, maximum: float) -> void:
	snapshot["health"] = current
	snapshot["max_health"] = maximum
	_health.max_value = maxf(1, maximum)
	_health.value = current
	_hp_text.text = str(int(current))


func _on_stamina(current: float, maximum: float) -> void:
	snapshot["stamina"] = current
	snapshot["max_stamina"] = maximum
	_stamina.max_value = maxf(1, maximum)
	_stamina.value = current
	_st_text.text = str(int(current))


func _on_equipment(weapon_id: StringName, shield: bool, tier: int) -> void:
	snapshot.merge({"weapon_id": weapon_id, "shield": shield, "tier": tier}, true)
	_weapon.kind = str(weapon_id)
	_shield.kind = "shield" if shield else "none"
	_weapon.queue_redraw()
	_shield.queue_redraw()


func set_prompt(text: String) -> void:
	_prompt.visible = not text.is_empty()
	_prompt_text.text = "E · " + text
