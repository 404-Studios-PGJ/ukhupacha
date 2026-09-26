class_name MenuScreen
extends Control

signal action_requested(action: StringName)
@export_enum("main", "pause", "controls", "death", "ending") var screen_id: String = "main"
var default_focus: Button
var _main_visuals: Dictionary = {}
var _focused_main_button: Button
var _focused_main_id: StringName = &""
var _main_focus_tween: Tween
var _main_press_locked: bool = false
var _main_selector_base_size: Vector2
var _main_compact_visual_color: Color
var _main_focus_visual_color: Color
var _main_compact_label_color: Color
var _main_focus_label_color: Color
var _main_compact_font_size: int
var _main_focus_font_size: int
var _main_compact_texture: Texture2D
var _main_focus_texture: Texture2D
var _main_intro_player: AnimationPlayer
var _main_intro_running := false
var _pause_visuals: Dictionary = {}
var _focused_pause_button: Button
var _focused_pause_id: StringName = &""
var _pause_focus_tween: Tween
var _pause_press_locked := false
var _pause_selector_base_size: Vector2
var _pause_compact_visual_color: Color
var _pause_focus_visual_color: Color
var _pause_compact_label_color: Color
var _pause_focus_label_color: Color
var _pause_compact_texture: Texture2D
var _pause_focus_texture: Texture2D
var _pause_animation_player: AnimationPlayer
var _pause_intro_running := false
var _pause_exit_running := false

const MAIN_FOCUS_TIME := 0.14
const MAIN_PRESS_DOWN_TIME := 0.07
const MAIN_PRESS_UP_TIME := 0.06
const MAIN_SELECTOR_FOCUS_SCALE := 1.12
const MAIN_SELECTOR_PRESS_SCALE := 0.92


func _ready() -> void:
	UIBuild.screen(self)
	match screen_id:
		"main":
			_build_main()
		"pause":
			_build_pause()
		"controls":
			_build_controls()
		"death":
			_build_death()
		"ending":
			_build_ending()
	if screen_id not in ["main", "pause", "controls", "death", "ending"]:
		UIBuild.footer(self, "UKHUPACHA / " + screen_id.to_upper())
	if default_focus != null and not _main_intro_running and not _pause_intro_running:
		default_focus.grab_focus()


func _action(id: StringName) -> void:
	action_requested.emit(id)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var side := -1
	match screen_id:
		"main":
			if _main_intro_running or _main_press_locked:
				return
			if event.is_action(&"arriba"):
				side = SIDE_TOP
			elif event.is_action(&"abajo"):
				side = SIDE_BOTTOM
		"pause":
			if _pause_intro_running or _pause_exit_running or _pause_press_locked:
				return
			if event.is_action(&"arriba"):
				side = SIDE_TOP
			elif event.is_action(&"abajo"):
				side = SIDE_BOTTOM
			elif event.is_action(&"izquierda"):
				side = SIDE_LEFT
			elif event.is_action(&"derecha"):
				side = SIDE_RIGHT
	if side >= 0 and _move_focus(side):
		get_viewport().set_input_as_handled()


func _move_focus(side: Side) -> bool:
	var current := get_viewport().gui_get_focus_owner()
	if current == null or not is_ancestor_of(current):
		return false
	var target := current.find_valid_focus_neighbor(side)
	if target == null or target == current:
		return false
	target.grab_focus()
	return true


func set_expedition_time(time_text: String) -> void:
	var time_label := get_node_or_null("TextHelixExpedition") as Label
	if time_label != null:
		time_label.text = "EXPEDICIÓN HÉLIX // " + time_text


func _build_main() -> void:
	default_focus = $BeginHit
	if not $BeginHit.pressed.is_connected(_action.bind(&"new_game")):
		_setup_main_menu_animation()
		_connect_main_action($BeginHit, &"new_game")
		_connect_main_action($ContinueHit, &"continue")
		_connect_main_action($ArchiveHit, &"archive")
	_apply_main_focus(&"new_game", true)
	_play_main_intro()


func _setup_main_menu_animation() -> void:
	var actions: Array[Dictionary] = [
		{"id": &"new_game", "button": $BeginHit, "visual": $BeginButton, "icon": $BeginIcon, "label": $TextBeginDescent},
		{"id": &"continue", "button": $ContinueHit, "visual": $ContinueButton, "icon": $ContinueIcon, "label": $TextContinue},
		{"id": &"archive", "button": $ArchiveHit, "visual": $ArchiveButton, "icon": $ArchiveIcon, "label": $TextArchive},
	]
	for entry: Dictionary in actions:
		var button: Button = entry["button"]
		var visual: NinePatchRect = entry["visual"]
		var icon: Control = entry["icon"]
		var label: Label = entry["label"]
		_main_visuals[entry["id"]] = {
			"button": button,
			"visual": visual,
			"icon": icon,
			"label": label,
			"button_position": visual.position,
			"button_size": visual.size,
			"icon_position": icon.position,
			"icon_size": icon.size,
			"label_position": label.position,
			"label_size": label.size,
			"font_size": label.get_theme_font_size(&"font_size"),
			"visual_color": visual.self_modulate,
			"icon_color": icon.self_modulate,
			"label_color": label.get_theme_color(&"font_color"),
			"texture": visual.texture,
			"focus_mode": button.focus_mode,
			"mouse_filter": button.mouse_filter,
		}
		button.focus_entered.connect(_focus_main_action.bind(entry["id"]))
		button.mouse_entered.connect(_hover_main_action.bind(entry["id"], button))
	_main_selector_base_size = $BeginLeftCap.size
	_main_compact_visual_color = _main_visuals[&"continue"]["visual_color"]
	_main_focus_visual_color = _main_visuals[&"new_game"]["visual_color"]
	_main_compact_label_color = _main_visuals[&"continue"]["label_color"]
	_main_focus_label_color = _main_visuals[&"new_game"]["label_color"]
	_main_compact_font_size = _main_visuals[&"continue"]["font_size"]
	_main_focus_font_size = maxi(_main_compact_font_size + 2, _main_visuals[&"new_game"]["font_size"])
	_main_compact_texture = _main_visuals[&"continue"]["texture"]
	_main_focus_texture = _main_visuals[&"new_game"]["texture"]
	$BeginLeftCap.z_index = 200


func _connect_main_action(button: Button, action: StringName) -> void:
	button.pressed.connect(_press_main_action.bind(action, button))


func _hover_main_action(id: StringName, button: Button) -> void:
	if _main_intro_running:
		return
	var already_focused := _focused_main_button == button
	button.grab_focus()
	if already_focused:
		_focus_main_action(id)


func _focus_main_action(id: StringName) -> void:
	if _main_intro_running:
		return
	if not _main_visuals.has(id):
		return
	_apply_main_focus(id)


func _apply_main_focus(id: StringName, immediate: bool = false) -> void:
	if not _main_visuals.has(id):
		return
	var duration := 0.0 if immediate else MAIN_FOCUS_TIME
	var previous_id := _focused_main_id
	_focused_main_id = id
	_focused_main_button = _main_visuals[id]["button"]
	if _main_focus_tween != null and _main_focus_tween.is_valid():
		_main_focus_tween.kill()
	_main_focus_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for action_id: StringName in _main_visuals:
		var focused := action_id == id
		if action_id == previous_id or action_id == id:
			_animate_main_action(_main_visuals[action_id], focused, _main_focus_tween, duration)
	_animate_main_selector(_main_visuals[id], _main_focus_tween, duration)
	if immediate:
		_main_focus_tween.custom_step(1.0)


func _animate_main_action(entry: Dictionary, focused: bool, tween: Tween, duration: float) -> void:
	var visual: NinePatchRect = entry["visual"]
	var icon: Control = entry["icon"]
	var label: Label = entry["label"]
	var target_rect: Rect2 = _main_target_rect(entry, focused)
	var icon_rect := _main_target_icon_rect(entry, focused)
	var label_rect := _main_target_label_rect(entry, focused)
	var visual_color: Color = _main_focus_visual_color if focused else _main_compact_visual_color
	var icon_color: Color = _main_visuals[&"new_game"]["icon_color"] if focused else entry["icon_color"]
	var label_color: Color = _main_focus_label_color if focused else _main_compact_label_color
	var font_size: int = _main_focus_font_size if focused else _main_compact_font_size
	visual.texture = _main_focus_texture if focused else _main_compact_texture
	tween.tween_property(visual, "position", target_rect.position, duration)
	tween.tween_property(visual, "size", target_rect.size, duration)
	tween.tween_property(icon, "position", icon_rect.position, duration)
	tween.tween_property(icon, "size", icon_rect.size, duration)
	tween.tween_property(label, "position", label_rect.position, duration)
	tween.tween_property(label, "size", label_rect.size, duration)
	tween.tween_property(label, "theme_override_font_sizes/font_size", font_size, duration)
	tween.tween_property(label, "self_modulate", Color.WHITE, duration)
	tween.tween_property(visual, "self_modulate", visual_color, duration)
	tween.tween_property(icon, "self_modulate", icon_color, duration)
	tween.tween_property(label, "theme_override_colors/font_color", label_color, duration)


func _main_target_rect(entry: Dictionary, focused: bool) -> Rect2:
	var base_position: Vector2 = entry["button_position"]
	var base_size: Vector2 = entry["button_size"]
	if focused:
		var large: Dictionary = _main_visuals[&"new_game"]
		var large_size: Vector2 = large["button_size"]
		return Rect2(base_position + (base_size - large_size) * 0.5, large_size)
	var compact: Dictionary = _main_visuals[&"continue"]
	var compact_size: Vector2 = compact["button_size"]
	return Rect2(base_position + (base_size - compact_size) * 0.5, compact_size)


func _animate_main_selector(entry: Dictionary, tween: Tween, duration: float) -> void:
	var icon_rect := _main_target_icon_rect(entry, true)
	_move_selector_to_rect(icon_rect, tween, duration, MAIN_SELECTOR_FOCUS_SCALE)


func _main_target_icon_rect(entry: Dictionary, focused: bool) -> Rect2:
	var target_rect := _main_target_rect(entry, focused)
	var template: Dictionary = _main_visuals[&"new_game"]
	if not focused:
		template = _main_visuals[&"continue"]
	var icon_position: Vector2 = target_rect.position + (template["icon_position"] - template["button_position"])
	var icon_size: Vector2 = template["icon_size"] if focused else _main_visuals[&"continue"]["icon_size"]
	return Rect2(icon_position, icon_size)


func _main_target_label_rect(entry: Dictionary, focused: bool) -> Rect2:
	var target_rect := _main_target_rect(entry, focused)
	var template: Dictionary = _main_visuals[&"new_game"] if focused else _main_visuals[&"continue"]
	var label_position: Vector2 = target_rect.position + (template["label_position"] - template["button_position"])
	var label_size: Vector2 = entry["label_size"]
	if focused and entry["font_size"] > 0:
		label_size *= float(_main_focus_font_size) / float(entry["font_size"])
	return Rect2(label_position, label_size)


func _move_selector_to(icon: Control) -> void:
	if not is_instance_valid(icon):
		return
	var selector_tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_move_selector_to_rect(_selector_rect_for_icon(icon, MAIN_SELECTOR_FOCUS_SCALE), selector_tween, MAIN_FOCUS_TIME, MAIN_SELECTOR_FOCUS_SCALE)


func _selector_rect_for_icon(icon: Control, selector_scale: float) -> Rect2:
	var target_size: Vector2 = _main_selector_base_size * selector_scale
	var center := icon.position + icon.size * 0.5
	return Rect2(center - target_size * 0.5, target_size)


func _move_selector_to_rect(icon_rect: Rect2, tween: Tween, duration: float, selector_scale: float) -> void:
	var selector: Control = $BeginLeftCap
	var selector_size: Vector2 = _main_selector_base_size * selector_scale
	var center := icon_rect.position + icon_rect.size * 0.5
	tween.tween_property(selector, "position", center - selector_size * 0.5, duration)
	tween.tween_property(selector, "size", selector_size, duration)


func _press_main_action(id: StringName, button: Button) -> void:
	if _main_intro_running or _main_press_locked or not _main_visuals.has(id):
		return
	_main_press_locked = true
	button.grab_focus()
	await _animate_main_press(_main_visuals[id])
	_action(id)
	_main_press_locked = false


func _animate_main_press(entry: Dictionary) -> void:
	var visual: NinePatchRect = entry["visual"]
	var icon: Control = entry["icon"]
	var label: Label = entry["label"]
	var focused_rect: Rect2 = _main_target_rect(entry, true)
	var pressed_size := focused_rect.size * 0.94
	var pressed_position := focused_rect.position + (focused_rect.size - pressed_size) * 0.5
	var selector: Control = $BeginLeftCap
	var selector_size := _main_selector_base_size * MAIN_SELECTOR_FOCUS_SCALE * MAIN_SELECTOR_PRESS_SCALE
	var pressed_selector_rect := _selector_rect_for_icon_rect(_main_target_icon_rect(entry, true), MAIN_SELECTOR_FOCUS_SCALE * MAIN_SELECTOR_PRESS_SCALE)
	var selector_position := pressed_selector_rect.position
	var press_delta := pressed_position - focused_rect.position
	var focused_icon_rect := _main_target_icon_rect(entry, true)
	var focused_label_rect := _main_target_label_rect(entry, true)
	var down := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	down.tween_property(visual, "position", pressed_position, MAIN_PRESS_DOWN_TIME)
	down.tween_property(visual, "size", pressed_size, MAIN_PRESS_DOWN_TIME)
	down.tween_property(icon, "position", focused_icon_rect.position + press_delta, MAIN_PRESS_DOWN_TIME)
	down.tween_property(label, "position", focused_label_rect.position + press_delta, MAIN_PRESS_DOWN_TIME)
	down.tween_property(selector, "position", selector_position, MAIN_PRESS_DOWN_TIME)
	down.tween_property(selector, "size", selector_size, MAIN_PRESS_DOWN_TIME)
	await down.finished
	var up := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	up.tween_property(visual, "position", focused_rect.position, MAIN_PRESS_UP_TIME)
	up.tween_property(visual, "size", focused_rect.size, MAIN_PRESS_UP_TIME)
	up.tween_property(icon, "position", focused_icon_rect.position, MAIN_PRESS_UP_TIME)
	up.tween_property(label, "position", focused_label_rect.position, MAIN_PRESS_UP_TIME)
	var focused_selector_rect := _selector_rect_for_icon_rect(_main_target_icon_rect(entry, true), MAIN_SELECTOR_FOCUS_SCALE)
	up.tween_property(selector, "position", focused_selector_rect.position, MAIN_PRESS_UP_TIME)
	up.tween_property(selector, "size", focused_selector_rect.size, MAIN_PRESS_UP_TIME)
	await up.finished


func _play_main_intro() -> void:
	_main_intro_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _main_intro_player == null or not _main_intro_player.has_animation(&"menu_enter"):
		return
	_main_intro_running = true
	_set_main_interaction_enabled(false)
	_main_intro_player.animation_finished.connect(_on_main_intro_finished, CONNECT_ONE_SHOT)
	_main_intro_player.play(&"menu_enter")


func _set_main_interaction_enabled(enabled: bool) -> void:
	for entry: Dictionary in _main_visuals.values():
		var button: Button = entry["button"]
		button.focus_mode = entry["focus_mode"] if enabled else Control.FOCUS_NONE
		button.mouse_filter = entry["mouse_filter"] if enabled else Control.MOUSE_FILTER_IGNORE


func _on_main_intro_finished(animation_name: StringName) -> void:
	if animation_name != &"menu_enter":
		return
	_main_intro_running = false
	_set_main_interaction_enabled(true)
	_apply_main_focus(&"new_game", true)
	default_focus.grab_focus()


func _selector_rect_for_icon_rect(icon_rect: Rect2, selector_scale: float) -> Rect2:
	var target_size: Vector2 = _main_selector_base_size * selector_scale
	var center := icon_rect.position + icon_rect.size * 0.5
	return Rect2(center - target_size * 0.5, target_size)


func _build_pause() -> void:
	default_focus = $ResumeHit
	_setup_pause_menu_animation()
	if not $ResumeHit.pressed.is_connected(_press_pause_action.bind(&"close", $ResumeHit)):
		_connect_pause_action($ResumeHit, &"close")
		_connect_pause_action($DossierHit, &"equipment")
		_connect_pause_action($SettingsHit, &"controls")
		_connect_pause_action($RestartHit, &"retry")
		_connect_pause_action($ExitHit, &"menu")
	_apply_pause_focus(&"close", true)
	_play_pause_intro()


func _setup_pause_menu_animation() -> void:
	if not _pause_visuals.is_empty():
		return
	var actions: Array[Dictionary] = [
		{"id": &"close", "button": $ResumeHit, "visual": $ResumeButton, "icon": $ResumeIcon, "label": $TextResumeDescent},
		{"id": &"equipment", "button": $DossierHit, "visual": $DossierButton, "icon": $DossierIcon, "label": $TextDossier},
		{"id": &"controls", "button": $SettingsHit, "visual": $SettingsButton, "icon": $SettingsIcon, "label": $TextSettings},
		{"id": &"retry", "button": $RestartHit, "visual": $RestartButton, "icon": $RestartIcon, "label": $TextRestart},
		{"id": &"menu", "button": $ExitHit, "visual": $ExitButton, "icon": $ExitIcon, "label": $TextExit},
	]
	for entry: Dictionary in actions:
		var button: Button = entry["button"]
		var visual: NinePatchRect = entry["visual"]
		var icon: Control = entry["icon"]
		var label: Label = entry["label"]
		_pause_visuals[entry["id"]] = {
			"button": button,
			"visual": visual,
			"icon": icon,
			"label": label,
			"button_position": visual.position,
			"button_size": visual.size,
			"icon_position": icon.position,
			"icon_size": icon.size,
			"label_position": label.position,
			"label_size": label.size,
			"visual_color": visual.self_modulate,
			"icon_color": icon.self_modulate,
			"label_color": label.get_theme_color(&"font_color"),
			"texture": visual.texture,
			"focus_mode": button.focus_mode,
			"mouse_filter": button.mouse_filter,
		}
		button.focus_entered.connect(_focus_pause_action.bind(entry["id"]))
		button.mouse_entered.connect(_hover_pause_action.bind(entry["id"], button))
	_pause_selector_base_size = $ResumeLeftCap.size
	_pause_compact_visual_color = _pause_visuals[&"equipment"]["visual_color"]
	_pause_focus_visual_color = _pause_visuals[&"close"]["visual_color"]
	_pause_compact_label_color = _pause_visuals[&"equipment"]["label_color"]
	_pause_focus_label_color = _pause_visuals[&"close"]["label_color"]
	_pause_compact_texture = _pause_visuals[&"equipment"]["texture"]
	_pause_focus_texture = _pause_visuals[&"close"]["texture"]
	$ResumeLeftCap.z_index = 200


func _connect_pause_action(button: Button, action: StringName) -> void:
	button.pressed.connect(_press_pause_action.bind(action, button))


func _hover_pause_action(id: StringName, button: Button) -> void:
	if _pause_intro_running or _pause_exit_running:
		return
	var already_focused := _focused_pause_button == button
	button.grab_focus()
	if already_focused:
		_focus_pause_action(id)


func _focus_pause_action(id: StringName) -> void:
	if _pause_intro_running or _pause_exit_running:
		return
	_apply_pause_focus(id)


func _apply_pause_focus(id: StringName, immediate: bool = false) -> void:
	if not _pause_visuals.has(id):
		return
	var duration := 0.0 if immediate else 0.13
	var previous_id := _focused_pause_id
	_focused_pause_id = id
	_focused_pause_button = _pause_visuals[id]["button"]
	if _pause_focus_tween != null and _pause_focus_tween.is_valid():
		_pause_focus_tween.kill()
	_pause_focus_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for action_id: StringName in _pause_visuals:
		if action_id == previous_id or action_id == id:
			_animate_pause_action(_pause_visuals[action_id], action_id == id, _pause_focus_tween, duration)
	_animate_pause_selector(_pause_visuals[id], _pause_focus_tween, duration, 1.12)
	if immediate:
		_pause_focus_tween.custom_step(1.0)


func _animate_pause_action(entry: Dictionary, focused: bool, tween: Tween, duration: float) -> void:
	var visual: NinePatchRect = entry["visual"]
	var icon: Control = entry["icon"]
	var label: Label = entry["label"]
	visual.texture = _pause_focus_texture if focused else _pause_compact_texture
	var visual_color := _pause_focus_visual_color if focused else _pause_compact_visual_color
	var label_color := _pause_focus_label_color if focused else _pause_compact_label_color
	tween.tween_property(visual, "self_modulate", visual_color, duration)
	tween.tween_property(label, "theme_override_colors/font_color", label_color, duration)
	tween.tween_property(icon, "self_modulate", entry["icon_color"], duration)


func _animate_pause_selector(entry: Dictionary, tween: Tween, duration: float, selector_scale: float) -> void:
	var icon: Control = entry["icon"]
	var target_size := _pause_selector_base_size * selector_scale
	var center := icon.position + icon.size * 0.5
	tween.tween_property($ResumeLeftCap, "position", center - target_size * 0.5, duration)
	tween.tween_property($ResumeLeftCap, "size", target_size, duration)


func _press_pause_action(id: StringName, button: Button) -> void:
	if _pause_intro_running or _pause_exit_running or _pause_press_locked or not _pause_visuals.has(id):
		return
	_pause_press_locked = true
	button.grab_focus()
	await _animate_pause_press(_pause_visuals[id])
	_action(id)
	_pause_press_locked = false


func _animate_pause_press(entry: Dictionary) -> void:
	var icon: Control = entry["icon"]
	var selector: Control = $ResumeLeftCap
	var icon_center := icon.position + icon.size * 0.5
	var focused_selector_size := _pause_selector_base_size * 1.12
	var pressed_selector_size := focused_selector_size * 0.92
	var down := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	down.tween_property(selector, "size", pressed_selector_size, 0.07)
	down.tween_property(selector, "position", icon_center - pressed_selector_size * 0.5, 0.07)
	await down.finished
	var up := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	up.tween_property(selector, "size", focused_selector_size, 0.06)
	up.tween_property(selector, "position", icon_center - focused_selector_size * 0.5, 0.06)
	await up.finished


func _play_pause_intro() -> void:
	_pause_animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _pause_animation_player == null or not _pause_animation_player.has_animation(&"pause_enter"):
		return
	_pause_intro_running = true
	_set_pause_interaction_enabled(false)
	_pause_animation_player.animation_finished.connect(_on_pause_enter_finished, CONNECT_ONE_SHOT)
	_pause_animation_player.stop()
	_pause_animation_player.seek(0.0, true)
	_pause_animation_player.play(&"pause_enter")


func _set_pause_interaction_enabled(enabled: bool) -> void:
	for entry: Dictionary in _pause_visuals.values():
		var button: Button = entry["button"]
		button.focus_mode = entry["focus_mode"] if enabled else Control.FOCUS_NONE
		button.mouse_filter = entry["mouse_filter"] if enabled else Control.MOUSE_FILTER_IGNORE


func _on_pause_enter_finished(animation_name: StringName) -> void:
	if animation_name != &"pause_enter":
		return
	_pause_intro_running = false
	_set_pause_interaction_enabled(true)
	_apply_pause_focus(&"close", true)
	default_focus.grab_focus()


func play_pause_exit() -> void:
	if _pause_exit_running:
		return
	_pause_exit_running = true
	_pause_intro_running = false
	_set_pause_interaction_enabled(false)
	if _pause_animation_player == null or not _pause_animation_player.has_animation(&"pause_exit"):
		_pause_exit_running = false
		return
	_pause_animation_player.stop()
	_pause_animation_player.animation_finished.connect(_on_pause_exit_finished, CONNECT_ONE_SHOT)
	_pause_animation_player.play(&"pause_exit")
	await _pause_animation_player.animation_finished


func _on_pause_exit_finished(animation_name: StringName) -> void:
	if animation_name == &"pause_exit":
		_pause_exit_running = false


func is_pause_intro_running() -> bool:
	return _pause_intro_running


func cancel_pause_transition() -> void:
	_pause_intro_running = false
	_pause_exit_running = false
	if _pause_animation_player != null:
		_pause_animation_player.stop()


func _build_controls() -> void:
	default_focus = $BackHit
	if not $BackHit.pressed.is_connected(_action.bind(&"back")):
		$BackHit.pressed.connect(_action.bind(&"back"))


func _build_death() -> void:
	default_focus = $RetryHit
	if not $RetryHit.pressed.is_connected(_action.bind(&"retry")):
		$RetryHit.pressed.connect(_action.bind(&"retry"))
		$MenuHit.pressed.connect(_action.bind(&"menu"))


func _build_ending() -> void:
	default_focus = $PrimaryHit
	if not $PrimaryHit.pressed.is_connected(_action.bind(&"menu")):
		$PrimaryHit.pressed.connect(_action.bind(&"menu"))
