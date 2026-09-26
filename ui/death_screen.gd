class_name DeathScreen
extends MenuScreen

const RETRY_FOCUS_SCALE := 1.08
const MENU_FOCUS_SCALE := 0.96
const PRESS_SCALE := 0.94
const PRESS_DOWN_TIME := 0.06
const PRESS_UP_TIME := 0.08

var _animation_player: AnimationPlayer
var _death_enter_running := true
var _death_exit_running := false
var _death_action_locked := false
var _death_press_tween: Tween
var _focused_death_id: StringName = &"retry"
var _retry_base_scale := Vector2.ONE
var _menu_base_scale := Vector2.ONE
var _retry_label_base_scale := Vector2.ONE
var _menu_label_base_scale := Vector2.ONE
var _retry_focus_mode := Control.FOCUS_ALL
var _menu_focus_mode := Control.FOCUS_ALL
var _retry_mouse_filter := Control.MOUSE_FILTER_STOP
var _menu_mouse_filter := Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	super._ready()


func _build_death() -> void:
	super._build_death()
	_retry_base_scale = $RetryVisual.scale
	_menu_base_scale = $MenuVisual.scale
	_retry_label_base_scale = $RetryLabel.scale
	_menu_label_base_scale = $MenuLabel.scale
	_retry_focus_mode = $RetryHit.focus_mode
	_menu_focus_mode = $MenuHit.focus_mode
	_retry_mouse_filter = $RetryHit.mouse_filter
	_menu_mouse_filter = $MenuHit.mouse_filter
	$RetryVisual.pivot_offset = $RetryVisual.size * 0.5
	$RetryLabel.pivot_offset = $RetryLabel.size * 0.5
	$MenuVisual.pivot_offset = $MenuVisual.size * 0.5
	$MenuLabel.pivot_offset = $MenuLabel.size * 0.5
	$RetryHit.focus_entered.connect(_on_death_focus.bind(&"retry"))
	$MenuHit.focus_entered.connect(_on_death_focus.bind(&"menu"))
	$RetryHit.mouse_entered.connect(_on_death_mouse_enter.bind(&"retry"))
	$MenuHit.mouse_entered.connect(_on_death_mouse_enter.bind(&"menu"))
	default_focus = null
	_set_death_interaction_enabled(false)
	call_deferred("_play_death_enter")


func _action(id: StringName) -> void:
	if screen_id == "death" and id in [&"retry", &"menu"]:
		if _death_enter_running or _death_exit_running or _death_action_locked:
			return
		_death_action_locked = true
		_focused_death_id = id
		_set_selected_button(id, true)
		await _animate_death_press(id)
		if not is_inside_tree():
			return
		await _play_death_exit()
		if is_inside_tree():
			super._action(id)
		return
	super._action(id)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or _death_enter_running or _death_exit_running or _death_action_locked:
		return
	var side := -1
	if event.is_action(&"izquierda"):
		side = SIDE_LEFT
	elif event.is_action(&"derecha"):
		side = SIDE_RIGHT
	if side >= 0 and _move_focus(side):
		get_viewport().set_input_as_handled()


func _on_death_focus(id: StringName) -> void:
	if _death_enter_running or _death_exit_running or _death_action_locked:
		return
	_focused_death_id = id
	_set_selected_button(id)


func _on_death_mouse_enter(id: StringName) -> void:
	if _death_enter_running or _death_exit_running or _death_action_locked:
		return
	var button: Button = $RetryHit if id == &"retry" else $MenuHit
	button.grab_focus()
	_focused_death_id = id
	_set_selected_button(id)


func _set_selected_button(id: StringName, immediate: bool = false) -> void:
	var duration := 0.0 if immediate else 0.12
	if _death_press_tween != null and _death_press_tween.is_valid():
		_death_press_tween.kill()
	_death_press_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var retry_scale := _retry_base_scale * (RETRY_FOCUS_SCALE if id == &"retry" else MENU_FOCUS_SCALE)
	var menu_scale := _menu_base_scale * (MENU_FOCUS_SCALE if id == &"retry" else RETRY_FOCUS_SCALE)
	var retry_label_scale := _retry_label_base_scale * (RETRY_FOCUS_SCALE if id == &"retry" else MENU_FOCUS_SCALE)
	var menu_label_scale := _menu_label_base_scale * (MENU_FOCUS_SCALE if id == &"retry" else RETRY_FOCUS_SCALE)
	_death_press_tween.tween_property($RetryVisual, "scale", retry_scale, duration)
	_death_press_tween.tween_property($RetryLabel, "scale", retry_label_scale, duration)
	_death_press_tween.tween_property($MenuVisual, "scale", menu_scale, duration)
	_death_press_tween.tween_property($MenuLabel, "scale", menu_label_scale, duration)
	if immediate:
		_death_press_tween.custom_step(1.0)


func _animate_death_press(id: StringName) -> void:
	var retry_target := _retry_base_scale * (RETRY_FOCUS_SCALE if id == &"retry" else MENU_FOCUS_SCALE)
	var menu_target := _menu_base_scale * (MENU_FOCUS_SCALE if id == &"retry" else RETRY_FOCUS_SCALE)
	var retry_label_target := _retry_label_base_scale * (RETRY_FOCUS_SCALE if id == &"retry" else MENU_FOCUS_SCALE)
	var menu_label_target := _menu_label_base_scale * (MENU_FOCUS_SCALE if id == &"retry" else RETRY_FOCUS_SCALE)
	var down := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	down.tween_property($RetryVisual, "scale", retry_target * PRESS_SCALE, PRESS_DOWN_TIME)
	down.tween_property($RetryLabel, "scale", retry_label_target * PRESS_SCALE, PRESS_DOWN_TIME)
	down.tween_property($MenuVisual, "scale", menu_target * PRESS_SCALE, PRESS_DOWN_TIME)
	down.tween_property($MenuLabel, "scale", menu_label_target * PRESS_SCALE, PRESS_DOWN_TIME)
	await down.finished
	var up := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	up.tween_property($RetryVisual, "scale", retry_target, PRESS_UP_TIME)
	up.tween_property($RetryLabel, "scale", retry_label_target, PRESS_UP_TIME)
	up.tween_property($MenuVisual, "scale", menu_target, PRESS_UP_TIME)
	up.tween_property($MenuLabel, "scale", menu_label_target, PRESS_UP_TIME)
	await up.finished


func _play_death_enter() -> void:
	_death_enter_running = true
	_death_exit_running = false
	_death_action_locked = false
	_set_death_interaction_enabled(false)
	if _animation_player == null or not _animation_player.has_animation(&"death_enter"):
		_on_death_enter_finished(&"death_enter")
		return
	_animation_player.stop()
	_animation_player.seek(0.0, true)
	_animation_player.animation_finished.connect(_on_death_enter_finished, CONNECT_ONE_SHOT)
	_animation_player.play(&"death_enter")


func _on_death_enter_finished(animation_name: StringName) -> void:
	if animation_name != &"death_enter":
		return
	_death_enter_running = false
	_set_death_interaction_enabled(true)
	_set_selected_button(&"retry", true)
	_focused_death_id = &"retry"
	$RetryHit.grab_focus()


func _play_death_exit() -> void:
	_death_exit_running = true
	_set_death_interaction_enabled(false)
	if _animation_player == null or not _animation_player.has_animation(&"death_exit"):
		_death_exit_running = false
		return
	_animation_player.stop()
	_animation_player.seek(0.0, true)
	_animation_player.play(&"death_exit")
	await _animation_player.animation_finished
	_death_exit_running = false


func _set_death_interaction_enabled(enabled: bool) -> void:
	$RetryHit.focus_mode = _retry_focus_mode if enabled else Control.FOCUS_NONE
	$MenuHit.focus_mode = _menu_focus_mode if enabled else Control.FOCUS_NONE
	$RetryHit.mouse_filter = _retry_mouse_filter if enabled else Control.MOUSE_FILTER_IGNORE
	$MenuHit.mouse_filter = _menu_mouse_filter if enabled else Control.MOUSE_FILTER_IGNORE
