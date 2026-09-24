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
	if start_in_menu:
		open_screen(&"main")


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
	hud.visible = id in [&"pause", &"equipment"]


func close_screen() -> void:
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
