class_name EndingScreen
extends MenuScreen

const ENDING_FOCUS_SCALE := 1.08
const PRESS_SCALE := 0.94
const PRESS_DOWN_TIME := 0.06
const PRESS_UP_TIME := 0.08

var _animation_player: AnimationPlayer
var _ending_enter_running := true
var _ending_exit_running := false
var _ending_action_locked := false
var _ending_press_tween: Tween
var _button_base_scale := Vector2.ONE
var _label_base_scale := Vector2.ONE
var _button_focus_mode := Control.FOCUS_ALL
var _button_mouse_filter := Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	super._ready()


func _build_ending() -> void:
	super._build_ending()
	_button_base_scale = $PrimaryActionVisual.scale
	_label_base_scale = $PrimaryActionLabel.scale
	_button_focus_mode = $PrimaryHit.focus_mode
	_button_mouse_filter = $PrimaryHit.mouse_filter
	$PrimaryActionVisual.pivot_offset = $PrimaryActionVisual.size * 0.5
	$PrimaryActionLabel.pivot_offset = $PrimaryActionLabel.size * 0.5
	$PrimaryHit.focus_entered.connect(_on_ending_focus)
	$PrimaryHit.mouse_entered.connect(_on_ending_mouse_enter)
	default_focus = null
	_set_ending_interaction_enabled(false)
	call_deferred("_play_ending_enter")


func _action(id: StringName) -> void:
	if screen_id == "ending" and id == &"menu":
		if _ending_enter_running or _ending_exit_running or _ending_action_locked:
			return
		_ending_action_locked = true
		_set_ending_focus(true)
		await _animate_ending_press()
		if not is_inside_tree():
			return
		await _play_ending_exit()
		if is_inside_tree():
			super._action(id)
		return
	super._action(id)


func _on_ending_focus() -> void:
	if _ending_enter_running or _ending_exit_running or _ending_action_locked:
		return
	_set_ending_focus()


func _on_ending_mouse_enter() -> void:
	if _ending_enter_running or _ending_exit_running or _ending_action_locked:
		return
	$PrimaryHit.grab_focus()
	_set_ending_focus()


func _set_ending_focus(immediate: bool = false) -> void:
	var duration := 0.0 if immediate else 0.1
	if _ending_press_tween != null and _ending_press_tween.is_valid():
		_ending_press_tween.kill()
	_ending_press_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_ending_press_tween.tween_property($PrimaryActionVisual, "scale", _button_base_scale * ENDING_FOCUS_SCALE, duration)
	_ending_press_tween.parallel().tween_property($PrimaryActionLabel, "scale", _label_base_scale * ENDING_FOCUS_SCALE, duration)
	if immediate:
		_ending_press_tween.custom_step(1.0)


func _animate_ending_press() -> void:
	var button_target := _button_base_scale * ENDING_FOCUS_SCALE
	var label_target := _label_base_scale * ENDING_FOCUS_SCALE
	var down := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	down.tween_property($PrimaryActionVisual, "scale", button_target * PRESS_SCALE, PRESS_DOWN_TIME)
	down.tween_property($PrimaryActionLabel, "scale", label_target * PRESS_SCALE, PRESS_DOWN_TIME)
	await down.finished
	var up := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	up.tween_property($PrimaryActionVisual, "scale", button_target, PRESS_UP_TIME)
	up.tween_property($PrimaryActionLabel, "scale", label_target, PRESS_UP_TIME)
	await up.finished


func _play_ending_enter() -> void:
	_ending_enter_running = true
	_ending_exit_running = false
	_ending_action_locked = false
	_set_ending_interaction_enabled(false)
	if _animation_player == null or not _animation_player.has_animation(&"ending_enter"):
		_on_ending_enter_finished(&"ending_enter")
		return
	_animation_player.stop()
	_animation_player.seek(0.0, true)
	_animation_player.animation_finished.connect(_on_ending_enter_finished, CONNECT_ONE_SHOT)
	_animation_player.play(&"ending_enter")


func _on_ending_enter_finished(animation_name: StringName) -> void:
	if animation_name != &"ending_enter":
		return
	_ending_enter_running = false
	_set_ending_interaction_enabled(true)
	_set_ending_focus(true)
	$PrimaryHit.grab_focus()


func _play_ending_exit() -> void:
	_ending_exit_running = true
	_set_ending_interaction_enabled(false)
	if _animation_player == null or not _animation_player.has_animation(&"ending_exit"):
		_ending_exit_running = false
		return
	_animation_player.stop()
	_animation_player.seek(0.0, true)
	_animation_player.play(&"ending_exit")
	await _animation_player.animation_finished
	_ending_exit_running = false


func _set_ending_interaction_enabled(enabled: bool) -> void:
	$PrimaryHit.focus_mode = _button_focus_mode if enabled else Control.FOCUS_NONE
	$PrimaryHit.mouse_filter = _button_mouse_filter if enabled else Control.MOUSE_FILTER_IGNORE
