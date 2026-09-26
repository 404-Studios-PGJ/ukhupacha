class_name UIFlow
extends CanvasLayer
## Instancia por sesión; no es autoload. El host reconstruye/reinicia su sala.
signal restart_requested(reason: StringName)
signal quit_requested()

@export var start_in_menu: bool = true
@export var allow_quit: bool = true
var player: Node
var hud: GameHUD
var modal: Control
var current_screen: StringName = &""
var _return_screen: StringName = &"main"
var _prior_input: bool = false
var _prior_pause: bool = false
var _locked: bool = false
var _prior_focus: Control
var _closing_screen := false
var run_elapsed_seconds: float = 0.0
var _run_active := false
const SCENES: Dictionary[StringName, PackedScene] = {
	&"main": preload("res://ui/main_menu.tscn"),
	&"pause": preload("res://ui/pause_menu.tscn"),
	&"equipment": preload("res://ui/equipment_menu.tscn"),
	&"controls": preload("res://ui/controls.tscn"),
	&"death": preload("res://ui/death_screen.tscn"),
	&"ending": preload("res://ui/ending.tscn"),
}


func _ready() -> void:
	if get_tree().get_first_node_in_group(&"ui_flow") != null:
		queue_free()
		return
	add_to_group(&"ui_flow")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	hud = get_tree().get_first_node_in_group(&"game_hud") as GameHUD
	if hud == null:
		hud = preload("res://ui/hud.tscn").instantiate() as GameHUD
		add_child(hud)
	bind_player(get_tree().get_first_node_in_group(&"player"))
	_run_active = not start_in_menu
	if start_in_menu:
		open_screen(&"main")


func _process(delta: float) -> void:
	if _run_active and current_screen == &"" and not get_tree().paused:
		run_elapsed_seconds += delta


func get_run_time_text() -> String:
	var total := maxi(0, int(run_elapsed_seconds))
	var hours := int(total / 3600.0)
	var minutes := int((total % 3600) / 60.0)
	var seconds := total % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


func bind_player(value: Node) -> void:
	if is_instance_valid(player) and player.has_signal("player_died") and player.is_connected("player_died", _on_death):
		player.disconnect("player_died", _on_death)
	player = value
	if is_instance_valid(hud):
		hud.bind_player(player)
	if is_instance_valid(player) and player.has_signal("player_died"):
		player.connect("player_died", _on_death)
	if _locked and is_instance_valid(player) and player.has_method("set_input_enabled"):
		player.call("set_input_enabled", false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pausa") and not event.is_echo():
		if current_screen in [&"pause", &"equipment"]:
			if current_screen == &"equipment" and modal is EquipmentMenu:
				(modal as EquipmentMenu).request_close()
			else:
				close_screen()
		elif current_screen == &"controls":
			open_screen(_return_screen)
		elif current_screen == &"" and UIBuild.input_enabled(player):
			open_screen(&"pause")
		else:
			return
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"equipo") and not event.is_echo():
		if current_screen == &"equipment":
			if modal is EquipmentMenu:
				(modal as EquipmentMenu).request_close()
			else:
				close_screen()
		elif current_screen == &"" and UIBuild.input_enabled(player):
			open_screen(&"equipment")
		else:
			return
		get_viewport().set_input_as_handled()


func open_screen(id: StringName) -> void:
	if not SCENES.has(id):
		return
	if not _locked:
		_prior_pause = get_tree().paused
		_prior_input = UIBuild.input_enabled(player)
		_prior_focus = get_viewport().gui_get_focus_owner()
		_locked = true
		if is_instance_valid(player) and player.has_method("set_input_enabled"):
			player.call("set_input_enabled", false)
		get_tree().paused = true
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	current_screen = id
	modal = SCENES[id].instantiate() as Control
	if modal is EquipmentMenu:
		(modal as EquipmentMenu).player = player
	add_child(modal)
	modal.connect("action_requested", _on_action)
	if id == &"pause" and modal is MenuScreen:
		(modal as MenuScreen).set_expedition_time(get_run_time_text())
	hud.visible = id in [&"pause", &"equipment"]


func close_screen() -> void:
	if _closing_screen:
		return
	if current_screen == &"pause" and modal is MenuScreen:
		var pause_menu := modal as MenuScreen
		if pause_menu.is_pause_intro_running():
			pause_menu.cancel_pause_transition()
		else:
			_closing_screen = true
			await pause_menu.play_pause_exit()
			_closing_screen = false
			if modal != pause_menu:
				return
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null
	current_screen = &""
	hud.visible = true
	_restore_lock()


func _restore_lock() -> void:
	if not _locked:
		return
	if is_instance_valid(player) and player.has_method("set_input_enabled"):
		player.call("set_input_enabled", _prior_input)
	get_tree().paused = _prior_pause
	_locked = false
	if is_instance_valid(_prior_focus) and _prior_focus.is_visible_in_tree():
		_prior_focus.grab_focus()


func restart_session(reason: StringName) -> bool:
	# El host es obligatorio: la UI no inventa setters de salud para Jhon.
	if get_signal_connection_list("restart_requested").is_empty():
		return false
	close_screen()
	Level1Progress.reset()
	run_elapsed_seconds = 0.0
	_run_active = true
	restart_requested.emit(reason)
	bind_player(get_tree().get_first_node_in_group(&"player"))
	hud.bind_player(player)
	return true


func _on_action(action: StringName) -> void:
	match action:
		&"new_game", &"retry":
			restart_session(action)
		&"close":
			close_screen()
		&"controls":
			_return_screen = current_screen
			open_screen(&"controls")
		&"equipment":
			open_screen(&"equipment")
		&"continue":
			close_screen()
		&"archive":
			_return_screen = current_screen
			open_screen(&"controls")
		&"back":
			open_screen(_return_screen)
		&"menu":
			open_screen(&"main")
		&"quit":
			quit_requested.emit()
			if allow_quit:
				get_tree().quit()


func _on_death() -> void:
	open_screen(&"death")


func _exit_tree() -> void:
	_restore_lock()
