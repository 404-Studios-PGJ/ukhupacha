class_name ControlsScreen
extends MenuScreen

var _animation_player: AnimationPlayer
var _controls_enter_running := true
var _controls_exit_running := false
var _controls_press_tween: Tween


func _ready() -> void:
	_animation_player = $AnimationPlayer
	super._ready()


func _build_controls() -> void:
	super._build_controls()
	call_deferred("_play_controls_enter")


func _action(id: StringName) -> void:
	if screen_id == "controls" and id == &"back":
		_request_controls_exit()
		return
	super._action(id)


func _play_controls_enter() -> void:
	_controls_enter_running = true
	_controls_exit_running = false
	$BackHit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5
	$BackButtonVisual.pivot_offset = $BackButtonVisual.size * 0.5
	$BackLabel.pivot_offset = $BackLabel.size * 0.5
	_animation_player.play("controls_enter")
	await _animation_player.animation_finished
	if not is_inside_tree() or _controls_exit_running:
		return
	_controls_enter_running = false
	$BackHit.mouse_filter = Control.MOUSE_FILTER_STOP
	$BackHit.grab_focus()


func _request_controls_exit() -> void:
	if _controls_enter_running or _controls_exit_running:
		return
	_controls_exit_running = true
	$BackHit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _controls_press_tween != null and _controls_press_tween.is_valid():
		_controls_press_tween.kill()
	$BackButtonVisual.scale = Vector2.ONE
	$BackLabel.scale = Vector2.ONE
	$BackButtonVisual.pivot_offset = $BackButtonVisual.size * 0.5
	$BackLabel.pivot_offset = $BackLabel.size * 0.5
	_controls_press_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_controls_press_tween.tween_property($BackButtonVisual, "scale", Vector2(0.94, 0.94), 0.06)
	_controls_press_tween.tween_property($BackLabel, "scale", Vector2(0.94, 0.94), 0.06)
	await _controls_press_tween.finished
	var restore := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	restore.tween_property($BackButtonVisual, "scale", Vector2.ONE, 0.08)
	restore.tween_property($BackLabel, "scale", Vector2.ONE, 0.08)
	await restore.finished
	_animation_player.play("controls_exit")
	await _animation_player.animation_finished
	if is_inside_tree():
		super._action(&"back")

