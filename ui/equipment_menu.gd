class_name EquipmentMenu
extends Control

signal action_requested(action: StringName)
var player: Node
var selected_id: StringName = &"none"
var actual_weapon: StringName = &"none"
var actual_shield: bool = false
var actual_tier: int = 0
var _list: Control
var _name_label: Label
var _description: Label
var _stats: Label
var _tier: Label
var _equip: Button
var _weapon_icon: TextureRect
var _shield_icon: TextureRect
var _equipped_label: Label
var _ready_label: Label
var _field_slots: Array[Control] = []
var _field_slot_icons: Array[Control] = []
var _field_slot_base_scales: Array[Vector2] = []
var _field_icon_base_scales: Array[Vector2] = []
var _selection_overlay: Control
var _selector: TextureRect
var _slot_tween: Tween
var _tab_visuals: Dictionary = {}
var _active_tab: StringName = &"loadout"
var _tab_tween: Tween
var _equip_press_tween: Tween
var _equip_press_locked := false
var _back_tween: Tween
var _back_press_locked := false
var _right_title: Label
var _right_subtitle: Label
var _guard_value: Label
var _reach_value: Label
var _note_second_line: Label
var _bar_fills: Array[Control] = []
var _field_kit_label: Label
var _bound_player: Node
var _field_note_panel: NinePatchRect
var _field_note_normal_rect: Rect2
var _field_note_expanded_rect: Rect2
var _note_label_normal_position: Vector2
var _note_label_normal_size: Vector2
var _description_normal_position: Vector2
var _description_normal_size: Vector2
var _description_normal_autowrap: TextServer.AutowrapMode
var _stats_controls: Array[Control] = []
var _presentation_tween: Tween
var _detail_transition_tween: Tween
var _detail_nodes: Array[Control] = []
var _detail_base_alphas: Dictionary = {}
var _selection_transition_generation := 0
var _animation_player: AnimationPlayer
var _transition_locked := false
const NAMES: Dictionary[StringName, String] = {&"none": "PUÑOS", &"sword": "ESPADA HELIX", &"axe": "HACHA HELIX", &"shield": "ESCUDO HELIX"}


func _ready() -> void:
	UIBuild.screen(self)
	_name_label = $ItemNameLabel
	_tier = $TierLabel
	_description = $DescriptionLabel
	_stats = $PowerValueLabel
	_right_title = $RightTitleLabel
	_right_subtitle = $RightSubtitleLabel
	_guard_value = $GuardValueLabel
	_reach_value = $ReachValueLabel
	_note_second_line = $FieldNoteLabel
	_field_note_panel = $FieldNotePanel
	_field_note_normal_rect = Rect2(_field_note_panel.position, _field_note_panel.size)
	_field_note_expanded_rect = Rect2(_field_note_normal_rect.position + Vector2(0, -88), Vector2(_field_note_normal_rect.size.x, _field_note_normal_rect.size.y + 88))
	_note_label_normal_position = _note_second_line.position
	_note_label_normal_size = _note_second_line.size
	_description_normal_position = _description.position
	_description_normal_size = _description.size
	_description_normal_autowrap = _description.autowrap_mode
	_stats_controls = [$PowerLabel, $PowerBarFrame, $PowerBarFill, $PowerValueLabel, $GuardLabel, $GuardBarFrame, $GuardBarFill, $GuardValueLabel, $ReachLabel, $ReachBarFrame, $ReachBarFill, $ReachValueLabel]
	_detail_nodes = [$SelectedItemIcon, $RightTitleLabel, $RightSubtitleLabel, $TierLabel, $FieldNotePanel, $FieldNoteLabel, $DescriptionLabel, $PowerLabel, $PowerBarFrame, $PowerBarFill, $PowerValueLabel, $GuardLabel, $GuardBarFrame, $GuardBarFill, $GuardValueLabel, $ReachLabel, $ReachBarFrame, $ReachBarFill, $ReachValueLabel, $EquippedBadge, $EquippedLabel, $EquipButton]
	for detail: Control in _detail_nodes:
		_detail_base_alphas[detail] = detail.self_modulate.a
	_field_kit_label = $FieldKitLabel
	_bar_fills.append($PowerBarFill)
	_bar_fills.append($GuardBarFill)
	_bar_fills.append($ReachBarFill)
	_weapon_icon = $SelectedItemIcon
	_shield_icon = $ReadyIcon
	_equipped_label = $EquippedLabel
	_ready_label = $ReadyLabel
	_selection_overlay = $SelectionOverlay
	_selector = $SelectionOverlay/SelectedItemFrame
	_animation_player = $AnimationPlayer # Scene-authored transition clips.
	_selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field_slots = [$FieldSlot1, $FieldSlot2, $FieldSlot3, $FieldSlot4]
	_field_slot_icons = [$FieldSlotIcon1, $FieldSlotIcon2, $FieldSlotIcon3]
	for slot: Control in _field_slots:
		_field_slot_base_scales.append(slot.scale)
	for icon: Control in _field_slot_icons:
		_field_icon_base_scales.append(icon.scale)
	_list = $DiscoveryHitAreas
	_equip = $EquipButton
	_setup_tab_visuals()
	_selection_overlay.z_index = 200
	_selector.z_index = 1
	$ReadyIcon.self_modulate = Color("#c24f4f")
	$ReadyLabel.add_theme_color_override(&"font_color", Color("#c24f4f"))
	if not _equip.pressed.is_connected(_on_equip_pressed):
		_equip.pressed.connect(_on_equip_pressed)
	if not $CloseButton.pressed.is_connected(request_close):
		$CloseButton.pressed.connect(request_close)
	Level1Progress.flag_changed.connect(_on_flag)
	_set_active_tab(&"loadout", true)
	bind_player(player)
	_play_equipment_enter()


func _play_equipment_enter() -> void:
	_transition_locked = true
	_set_transition_input_locked(true)
	_animation_player.play(&"equipment_enter")
	var finished: StringName = await _animation_player.animation_finished
	if finished == &"equipment_enter":
		_transition_locked = false
		_set_transition_input_locked(false)
		_refresh()


func _set_transition_input_locked(locked: bool) -> void:
	var filter: int = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP
	$LoadoutTabHit.mouse_filter = filter
	$PackTabHit.mouse_filter = filter
	$NotesTabHit.mouse_filter = filter
	$CloseButton.mouse_filter = filter
	$EquipButton.mouse_filter = filter
	$LoadoutTabHit.disabled = locked
	$PackTabHit.disabled = locked
	$NotesTabHit.disabled = locked
	$CloseButton.disabled = locked
	$EquipButton.disabled = true if locked else $EquipButton.disabled
	for child: Node in _list.get_children():
		if child is Button:
			(child as Button).disabled = locked


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var direction := 0
	if event.is_action(&"izquierda") or event.is_action(&"ui_left"):
		direction = -1
	elif event.is_action(&"derecha") or event.is_action(&"ui_right"):
		direction = 1
	elif event.is_action(&"arriba") or event.is_action(&"abajo") or event.is_action(&"ui_up") or event.is_action(&"ui_down"):
		get_viewport().set_input_as_handled()
		return
	else:
		return
	get_viewport().set_input_as_handled()
	if _transition_locked or _active_tab != &"loadout":
		return
	var ids := discovered_ids()
	var current_index := ids.find(selected_id)
	if current_index < 0:
		current_index = 0
	var next_index := clampi(current_index + direction, 0, ids.size() - 1)
	if next_index == current_index:
		return
	var next_id: StringName = ids[next_index]
	select_item(next_id)
	var button := _list.get_node_or_null(str(next_id)) as Button
	if button != null:
		button.grab_focus()


func request_close() -> void:
	if _back_press_locked or _transition_locked:
		return
	_back_press_locked = true
	_transition_locked = true
	var base_icon_scale: Vector2 = $ReadyIcon.scale
	var base_label_scale: Vector2 = $ReadyLabel.scale
	$ReadyIcon.pivot_offset = $ReadyIcon.size * 0.5
	$ReadyLabel.pivot_offset = $ReadyLabel.size * 0.5
	if _back_tween != null and _back_tween.is_valid():
		_back_tween.kill()
	_back_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_back_tween.tween_property($ReadyIcon, "scale", base_icon_scale * 0.92, 0.07)
	_back_tween.tween_property($ReadyLabel, "scale", base_label_scale * 0.94, 0.07)
	await _back_tween.finished
	var restore := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	restore.tween_property($ReadyIcon, "scale", base_icon_scale, 0.06)
	restore.tween_property($ReadyLabel, "scale", base_label_scale, 0.06)
	await restore.finished
	_animation_player.play(&"equipment_exit")
	var finished: StringName = await _animation_player.animation_finished
	if finished != &"equipment_exit":
		_back_press_locked = false
		_transition_locked = false
		return
	action_requested.emit(&"close")
	_back_press_locked = false
	_transition_locked = false


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
	_refresh()


func _setup_tab_visuals() -> void:
	var tabs: Array[Dictionary] = [
		{"id": &"loadout", "button": $LoadoutTabHit, "visual": $LoadoutTab, "label": $LoadoutText, "active_color": Color("#4f7a4a"), "inactive_color": Color("#304b32"), "active_label_color": Color("#f1e1b8"), "inactive_label_color": Color("#c8b78f")},
		{"id": &"pack", "button": $PackTabHit, "visual": $PackTab, "label": $PackText, "active_color": Color("#2a2422"), "inactive_color": Color("#201c1a"), "active_label_color": Color("#f1e1b8"), "inactive_label_color": Color("#c8b78f")},
		{"id": &"notes", "button": $NotesTabHit, "visual": $NotesTab, "label": $NotesText, "active_color": Color("#6a4d78"), "inactive_color": Color("#44334f"), "active_label_color": Color("#f1e1b8"), "inactive_label_color": Color("#c8b78f")},
	]
	for entry: Dictionary in tabs:
		var visual: NinePatchRect = entry["visual"]
		var label: Label = entry["label"]
		visual.pivot_offset = visual.size * 0.5
		label.pivot_offset = label.size * 0.5
		_tab_visuals[entry["id"]] = {
			"button": entry["button"],
			"visual": visual,
			"label": label,
			"active_color": entry["active_color"],
			"inactive_color": entry["inactive_color"],
			"active_label_color": entry["active_label_color"],
			"inactive_label_color": entry["inactive_label_color"],
		}
		entry["button"].pressed.connect(_set_active_tab.bind(entry["id"]))


func _set_active_tab(tab_id: StringName, immediate: bool = false) -> void:
	if _transition_locked or not _tab_visuals.has(tab_id):
		return
	_active_tab = tab_id
	if _tab_tween != null and _tab_tween.is_valid():
		_tab_tween.kill()
	_tab_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var duration := 0.0 if immediate else 0.12
	for id: StringName in _tab_visuals:
		var entry: Dictionary = _tab_visuals[id]
		var active := id == tab_id
		var visual: NinePatchRect = entry["visual"]
		var label: Label = entry["label"]
		var target_scale := Vector2.ONE * (1.06 if active else 1.0)
		var target_color: Color = entry["active_color"] if active else entry["inactive_color"]
		var target_label_color: Color = entry["active_label_color"] if active else entry["inactive_label_color"]
		_tab_tween.tween_property(visual, "scale", target_scale, duration)
		_tab_tween.tween_property(label, "scale", target_scale, duration)
		_tab_tween.tween_property(visual, "self_modulate", target_color, duration)
		_tab_tween.tween_property(label, "theme_override_colors/font_color", target_label_color, duration)
	if immediate:
		_tab_tween.custom_step(1.0)
	_refresh()


func _set_tab_presentation(immediate: bool = false) -> void:
	var notes_active: bool = _active_tab == &"notes"
	if _presentation_tween != null and _presentation_tween.is_valid():
		_presentation_tween.kill()
	_presentation_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var duration := 0.0 if immediate else 0.18
	var target_rect: Rect2 = _field_note_expanded_rect if notes_active else _field_note_normal_rect
	var target_note_position: Vector2 = _note_label_normal_position + (Vector2(0, -88) if notes_active else Vector2.ZERO)
	var target_note_size: Vector2 = Vector2(160, 13) if notes_active else _note_label_normal_size
	var target_description_position: Vector2 = _description_normal_position + (Vector2(0, -88) if notes_active else Vector2.ZERO)
	var target_description_size: Vector2 = Vector2(185, 112) if notes_active else _description_normal_size
	_presentation_tween.tween_property(_field_note_panel, "position", target_rect.position, duration)
	_presentation_tween.tween_property(_field_note_panel, "size", target_rect.size, duration)
	_presentation_tween.tween_property(_note_second_line, "position", target_note_position, duration)
	_presentation_tween.tween_property(_note_second_line, "size", target_note_size, duration)
	_presentation_tween.tween_property(_description, "position", target_description_position, duration)
	_presentation_tween.tween_property(_description, "size", target_description_size, duration)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if notes_active else _description_normal_autowrap
	for stat: Control in _stats_controls:
		stat.visible = true
		_presentation_tween.tween_property(stat, "self_modulate:a", 0.0 if notes_active else 1.0, duration * 0.65)
	if immediate:
		_presentation_tween.custom_step(1.0)
		_finish_tab_presentation(notes_active)
	else:
		_presentation_tween.finished.connect(_finish_tab_presentation.bind(notes_active), CONNECT_ONE_SHOT)


func _finish_tab_presentation(notes_active: bool) -> void:
	for stat: Control in _stats_controls:
		stat.visible = not notes_active
		stat.self_modulate.a = 0.0 if notes_active else 1.0


func _animate_selected_slot() -> void:
	if _slot_tween != null and _slot_tween.is_valid():
		_slot_tween.kill()
	_slot_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var slot_ids: Array[StringName] = [&"none", &"sword", &"axe", &"shield"]
	var selected_index: int = maxi(slot_ids.find(selected_id), 0)
	for index: int in range(_field_slots.size()):
		var selected: bool = index == selected_index
		var slot_scale: Vector2 = _field_slot_base_scales[index] * (1.08 if selected else 1.0)
		_slot_tween.tween_property(_field_slots[index], "scale", slot_scale, 0.12)
		if index > 0 and index - 1 < _field_slot_icons.size():
			var icon_scale: Vector2 = _field_icon_base_scales[index - 1] * (1.08 if selected else 1.0)
			_slot_tween.tween_property(_field_slot_icons[index - 1], "scale", icon_scale, 0.12)
	var selected_slot: Control = _field_slots[selected_index]
	var slot_global_center: Vector2 = selected_slot.get_global_transform_with_canvas() * (selected_slot.size * 0.5)
	var target_local_center: Vector2 = _selection_overlay.get_global_transform_with_canvas().affine_inverse() * slot_global_center
	var target_position: Vector2 = target_local_center - _selector.size * 0.5
	_slot_tween.tween_property(_selector, "position", target_position, 0.12)


func _start_selection_transition() -> void:
	if _active_tab != &"loadout":
		_refresh()
		return
	_selection_transition_generation += 1
	var generation := _selection_transition_generation
	if _detail_transition_tween != null and _detail_transition_tween.is_valid():
		_detail_transition_tween.kill()
	_detail_transition_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for detail: Control in _detail_nodes:
		_detail_transition_tween.tween_property(detail, "self_modulate:a", _detail_base_alphas[detail] * 0.12, 0.06)
	_detail_transition_tween.finished.connect(_finish_selection_transition.bind(generation), CONNECT_ONE_SHOT)


func _finish_selection_transition(generation: int) -> void:
	if generation != _selection_transition_generation:
		return
	_refresh()
	if _detail_transition_tween != null and _detail_transition_tween.is_valid():
		_detail_transition_tween.kill()
	_detail_transition_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for detail: Control in _detail_nodes:
		_detail_transition_tween.tween_property(detail, "self_modulate:a", _detail_base_alphas[detail], 0.08)


func _on_equip_pressed() -> void:
	if _equip_press_locked or _transition_locked:
		return
	_equip_press_locked = true
	var badge: Control = $EquippedBadge
	badge.pivot_offset = badge.size * 0.5
	var base_scale := badge.scale
	if _equip_press_tween != null and _equip_press_tween.is_valid():
		_equip_press_tween.kill()
	_equip_press_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_equip_press_tween.tween_property(badge, "scale", base_scale * 0.94, 0.07)
	await _equip_press_tween.finished
	var restore := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	restore.tween_property(badge, "scale", base_scale, 0.06)
	await restore.finished
	_request_equip()
	_equip_press_locked = false


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
	_field_kit_label.text = "KIT DE CAMPO  %02d / 04" % ids.size()
	if selected_id not in ids:
		selected_id = &"none"
	var positions: Array[Vector2] = [Vector2(82, 222), Vector2(133, 222), Vector2(184, 222), Vector2(235, 222)]
	for index: int in range(4):
		var id: StringName = [&"none", &"sword", &"axe", &"shield"][index]
		if id in ids:
			var button: Button = UIBuild.hit_area(_list, Rect2(positions[index], Vector2(44, 44)), select_item.bind(id), str(id))
			button.mouse_entered.connect(_on_item_hover.bind(id, button))
			button.disabled = _transition_locked
			if id == selected_id:
				button.grab_focus()
		if index > 0:
			_field_slot_icons[index - 1].visible = id in ids
	_refresh()


func _on_item_hover(id: StringName, button: Button) -> void:
	if _transition_locked or button.disabled:
		return
	button.grab_focus()
	select_item(id)


func select_item(id: StringName) -> void:
	if id not in discovered_ids():
		return
	if id == selected_id:
		return
	selected_id = id
	_start_selection_transition()


func _refresh() -> void:
	_name_label.text = NAMES.get(selected_id, "EQUIPO")
	if _active_tab == &"notes":
		_right_title.text = "NOTA DE CAMPO 07"
		_right_subtitle.text = "Registro recuperado"
		_note_second_line.text = "NOTA DE CAMPO 07"
		_description.text = "Sin nota seleccionada."
	else:
		_right_title.text = _name_label.text
		_right_subtitle.text = "Equipo Helix registrado" if selected_id != &"none" else "Sin equipo seleccionado"
		_note_second_line.text = "NOTA DE CAMPO 07"
		_description.text = "Herramienta Helix." if selected_id != &"none" else "Sin arma equipada."
	_tier.text = "NIVEL %d" % actual_tier
	_stats.text = "--"
	_guard_value.text = "ON" if actual_shield else "OFF"
	_reach_value.text = "--"
	for fill: Control in _bar_fills:
		fill.modulate.a = 0.35
	_weapon_icon.modulate.a = 1.0 if selected_id != &"none" else 0.35
	var equipped: bool = selected_id != &"none" and (actual_shield if selected_id == &"shield" else actual_weapon == selected_id)
	var action_text := "LEER [E]" if _active_tab == &"notes" else "EQUIPAR [E]"
	if _active_tab == &"loadout" and equipped:
		action_text = "DESEQUIPAR [E]"
	_equipped_label.text = action_text
	_ready_label.text = "VOLVER"
	var equipped_state: bool = equipped and _active_tab == &"loadout"
	$EquippedBadge.self_modulate = Color("#c99b45") if equipped_state else Color("#4f9b68")
	_equipped_label.add_theme_color_override(&"font_color", Color("#322721") if equipped_state else Color("#f1e1b8"))
	var method: StringName = &"equip_shield" if selected_id == &"shield" else &"equip_weapon"
	_equip.disabled = _active_tab == &"notes" or not is_instance_valid(player) or (equipped and not _can_unequip()) or (not equipped and not player.has_method(method))
	_animate_selected_slot()
	_set_tab_presentation()


func _request_equip() -> void:
	if selected_id not in discovered_ids() or not is_instance_valid(player):
		return
	var equipped: bool = selected_id != &"none" and (actual_shield if selected_id == &"shield" else actual_weapon == selected_id)
	if equipped:
		_request_unequip()
		return
	var method: StringName = &"equip_shield" if selected_id == &"shield" else &"equip_weapon"
	if not player.has_method(method):
		return
	if selected_id == &"shield":
		player.call(method)
	else:
		player.call(method, selected_id)
	# Sin actualización optimista: solo equipment_changed confirma el cambio.


func _can_unequip() -> bool:
	if not is_instance_valid(player):
		return false
	if selected_id == &"shield":
		return player.has_method(&"unequip_shield") or player.has_method(&"clear_shield") or player.has_method(&"clear_equipment") or player.has_method(&"reset_equipment")
	return player.has_method(&"unequip_weapon") or player.has_method(&"clear_equipment") or player.has_method(&"reset_equipment") or player.has_method(&"equip_weapon")


func _request_unequip() -> void:
	if not _can_unequip():
		return
	if selected_id == &"shield":
		if player.has_method(&"unequip_shield"):
			player.call(&"unequip_shield")
		elif player.has_method(&"clear_shield"):
			player.call(&"clear_shield")
		elif player.has_method(&"clear_equipment"):
			player.call(&"clear_equipment")
		else:
			player.call(&"reset_equipment")
		return
	if player.has_method(&"unequip_weapon"):
		player.call(&"unequip_weapon")
	elif player.has_method(&"clear_equipment"):
		player.call(&"clear_equipment")
	elif player.has_method(&"reset_equipment"):
		player.call(&"reset_equipment")
	else:
		player.call(&"equip_weapon", &"none")
