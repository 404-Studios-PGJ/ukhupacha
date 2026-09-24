class_name EquipmentMenu
extends Control

signal action_requested(action: StringName)
var player: Node
var selected_id: StringName = &"none"
var actual_weapon: StringName = &"none"
var actual_shield: bool = false
var actual_tier: int = 0
var _list: VBoxContainer
var _name_label: Label
var _description: Label
var _stats: Label
var _tier: Label
var _equip: Button
var _weapon_icon: HybridGeometry
var _shield_icon: HybridGeometry
var _bound_player: Node
const NAMES: Dictionary[StringName, String] = {&"none": "PUÑOS", &"sword": "ESPADA HELIX", &"axe": "HACHA HELIX", &"shield": "ESCUDO HELIX"}


func _ready() -> void:
	UIBuild.screen(self)
	UIBuild.panel(self, Rect2(0, 0, 640, 360))
	UIBuild.header(self, "DOSSIER DE EXPEDICIÓN", "EQUIPO DESCUBIERTO")
	UIBuild.panel(self, Rect2(18, 62, 126, 254), &"Dossier")
	UIBuild.panel(self, Rect2(158, 62, 462, 254), &"Dossier")
	UIBuild.label(self, "KIT ACTIVO", Rect2(34, 76, 108, 18), &"Accent")
	_weapon_icon = _slot(Vector2(34, 101))
	_shield_icon = _slot(Vector2(82, 101))
	UIBuild.rule(self, Rect2(34, 156, 92, 1))
	_list = VBoxContainer.new()
	UIBuild.place(_list, self, Rect2(28, 169, 106, 136))
	var plate: HybridGeometry = HybridGeometry.new()
	plate.kind = "title"
	UIBuild.place(plate, self, Rect2(176, 76, 324, 50))
	_name_label = UIBuild.label(self, "", Rect2(188, 83, 288, 25), &"Heading")
	UIBuild.label(self, "EQUIPO DE EXPEDICIÓN", Rect2(188, 109, 282, 14), &"Muted")
	UIBuild.patch(self, &"banner", Rect2(510, 76, 92, 24), &"gold")
	_tier = UIBuild.label(self, "T0", Rect2(536, 80, 50, 20), &"Small")
	UIBuild.label(self, "NOTAS DE CAMPO", Rect2(178, 144, 220, 18), &"Accent")
	_description = UIBuild.label(self, "", Rect2(178, 168, 216, 68))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIBuild.panel(self, Rect2(408, 139, 194, 98), &"WarmPanel")
	_stats = UIBuild.label(self, "", Rect2(422, 151, 174, 78), &"Accent")
	UIBuild.rule(self, Rect2(178, 245, 424, 1))
	_equip = UIBuild.button(self, "EQUIPAR", Rect2(432, 264, 166, 34), _request_equip, true)
	UIBuild.button(self, "VOLVER", Rect2(18, 322, 126, 26), func() -> void: action_requested.emit(&"close"))
	var footer: Label = UIBuild.footer(self, "TAB / ESC · CERRAR")
	footer.offset_left = 166
	Level1Progress.flag_changed.connect(_on_flag)
	bind_player(player)


func _slot(at: Vector2) -> HybridGeometry:
	var button: TextureButton = TextureButton.new()
	button.texture_normal = UIAssets.texture(&"slot")
	button.texture_hover = UIAssets.texture(&"slot_hover")
	button.texture_disabled = UIAssets.texture(&"slot_disabled")
	button.disabled = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIBuild.place(button, self, Rect2(at, Vector2(32, 32)))
	var geometry: HybridGeometry = HybridGeometry.new()
	UIBuild.place(geometry, self, Rect2(at, Vector2(32, 32)))
	return geometry


func bind_player(value: Node) -> void:
	if is_instance_valid(_bound_player) and _bound_player.has_signal("equipment_changed"):
		if _bound_player.is_connected("equipment_changed", _on_equipment):
			_bound_player.disconnect("equipment_changed", _on_equipment)
	player = value
	_bound_player = value
	if not is_node_ready():
		return
	var initial: Dictionary = UIBuild.state(player)
	_on_equipment(initial.get("weapon_id", &"none"), bool(initial.get("shield", false)), int(initial.get("tier", 0)))
	if is_instance_valid(player) and player.has_signal("equipment_changed"):
		player.connect("equipment_changed", _on_equipment)
	_rebuild_list()


func _on_equipment(weapon: StringName, shield: bool, tier: int) -> void:
	actual_weapon = weapon
	actual_shield = shield
	actual_tier = tier
	_weapon_icon.kind = str(weapon)
	_shield_icon.kind = "shield" if shield else "none"
	_weapon_icon.queue_redraw()
	_shield_icon.queue_redraw()
	_refresh()


func _on_flag(_flag: StringName, _value: bool) -> void:
	if is_inside_tree():
		_rebuild_list()


func _exit_tree() -> void:
	if is_instance_valid(_bound_player) and _bound_player.has_signal("equipment_changed"):
		if _bound_player.is_connected("equipment_changed", _on_equipment):
			_bound_player.disconnect("equipment_changed", _on_equipment)
	if Level1Progress.flag_changed.is_connected(_on_flag):
		Level1Progress.flag_changed.disconnect(_on_flag)


func discovered_ids() -> Array[StringName]:
	var ids: Array[StringName] = [&"none"]
	for id: StringName in [&"sword", &"axe", &"shield"]:
		if Level1Progress.get_flag(StringName("has_" + id)):
			ids.append(id)
	return ids


func _rebuild_list() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var ids: Array[StringName] = discovered_ids()
	if selected_id not in ids:
		selected_id = &"none"
	for id: StringName in ids:
		var button: Button = UIBuild.button(_list, NAMES[id], Rect2(0, 0, 106, 27), select_item.bind(id))
		button.custom_minimum_size.y = 27
		if id == selected_id:
			button.grab_focus()
	_refresh()


func select_item(id: StringName) -> void:
	if id not in discovered_ids():
		return
	selected_id = id
	_refresh()


func _refresh() -> void:
	_name_label.text = NAMES.get(selected_id, "EQUIPO")
	_tier.text = "T%d" % actual_tier
	_description.text = "Herramienta de expedición Helix.\nNo se atribuye como patrimonio cultural." if selected_id != &"none" else "Combate sin arma.\nExplora y descubre equipo."
	var damage: int = 8 if selected_id == &"none" else 20 if selected_id == &"sword" else 32 if selected_id == &"axe" else 0
	_stats.text = "DAÑO BASE   %d\nGUARDIA   %s\nTIER ACTUAL   %d" % [damage, "ESCUDO" if actual_shield else "NORMAL", actual_tier]
	var equipped: bool = actual_shield if selected_id == &"shield" else actual_weapon == selected_id
	_equip.text = "EQUIPADO" if equipped else "EQUIPAR"
	var method: StringName = &"equip_shield" if selected_id == &"shield" else &"equip_weapon"
	_equip.disabled = equipped or not is_instance_valid(player) or not player.has_method(method)


func _request_equip() -> void:
	if selected_id not in discovered_ids() or not is_instance_valid(player):
		return
	var method: StringName = &"equip_shield" if selected_id == &"shield" else &"equip_weapon"
	if not player.has_method(method):
		return
	if selected_id == &"shield":
		player.call(method)
	else:
		player.call(method, selected_id)
	# Sin actualización optimista: solo equipment_changed confirma el cambio.
