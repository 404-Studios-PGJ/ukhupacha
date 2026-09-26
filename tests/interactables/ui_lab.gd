extends Node2D

const SimPlayer = preload("res://tests/interactables/ui_player.gd")
var player: SimPlayer
var flow: UIFlow
var results: Array[Dictionary] = []
var _status: Label
var testing: bool = false
var _terminal_helper: Interactable


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Level1Progress.reset()
	player = SimPlayer.new()
	player.name = "SimPlayer"
	add_child(player)
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 0
	add_child(canvas)
	var root: Control = Control.new()
	canvas.add_child(root)
	UIBuild.screen(root)
	UIBuild.panel(root, Rect2(0, 0, 640, 360))
	UIBuild.label(root, "LAB / UI · PLAYER SIMULADO", Rect2(24, 100, 560, 24), &"Heading")
	UIBuild.label(root, "Esc: pausa · F: equipo · E: terminal", Rect2(24, 135, 560, 24))
	var button: Button = UIBuild.button(root, "Descubrir equipo", Rect2(24, 180, 180, 36), discover)
	button.name = "Discover"
	UIBuild.button(root, "Simular muerte", Rect2(220, 180, 180, 36), player.damage)
	UIBuild.button(root, "Pruebas", Rect2(416, 180, 180, 36), run_checks)
	UIBuild.button(root, "Continuará", Rect2(24, 230, 180, 36), func() -> void: flow.open_screen(&"ending"))
	_status = UIBuild.label(root, "Listo", Rect2(24, 320, 580, 24), &"Accent")
	flow = preload("res://ui/ui_flow.tscn").instantiate() as UIFlow
	flow.start_in_menu = true
	flow.allow_quit = false
	flow.restart_requested.connect(_restart)
	add_child(flow)


func _restart(_reason: StringName) -> void:
	player.reset_player()


func discover() -> void:
	for id: StringName in [&"has_sword", &"has_axe", &"has_shield"]:
		Level1Progress.set_flag(id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interactuar") and flow.current_screen == &"":
		if is_instance_valid(_terminal_helper) and is_instance_valid(_terminal_helper._dialog):
			return
		for id: StringName in [&"record_a", &"record_b", &"record_c"]:
			Level1Progress.set_flag(id)
		if not is_instance_valid(_terminal_helper):
			_terminal_helper = preload("res://interactables/access_terminal.tscn").instantiate() as Interactable
			_terminal_helper.name = "TerminalHelper"
			add_child(_terminal_helper)
		_terminal_helper.interact(player)


func _frames(count: int = 3) -> void:
	for index: int in range(count):
		await get_tree().process_frame


func _check(label: String, passed: bool) -> void:
	results.append({"case": label, "passed": passed})


func run_checks() -> Array[Dictionary]:
	if testing:
		return results
	testing = true
	results.clear()
	flow.close_screen()
	player.health = 84
	player.stamina = 63
	flow.bind_player(player)
	_check("HUD initial snapshot without signals", flow.hud.snapshot["health"] == 84 and flow.hud.snapshot["stamina"] == 63)
	player.health_changed.emit(47.0, 100.0)
	player.stamina_changed.emit(31.0, 100.0)
	_check("HUD health and stamina signals", flow.hud.snapshot["health"] == 47 and flow.hud.snapshot["stamina"] == 31)
	flow.open_screen(&"pause")
	var previous_ticks: int = player.ticks
	await _frames(6)
	_check("pause stops world and disables input", get_tree().paused and not player.input_enabled and player.ticks == previous_ticks)
	flow.open_screen(&"controls")
	flow.open_screen(&"pause")
	flow.close_screen()
	_check("nested controls restore pause and input", not get_tree().paused and player.input_enabled)
	player.set_input_enabled(false)
	flow.open_screen(&"pause")
	flow.close_screen()
	_check("previously disabled input stays disabled", not player.input_enabled)
	player.set_input_enabled(true)
	Level1Progress.reset()
	flow.open_screen(&"equipment")
	var equipment: EquipmentMenu = flow.modal as EquipmentMenu
	_check("undiscovered equipment hidden", equipment.discovered_ids() == [&"none"])
	discover()
	_check("inventory refreshes on discoveries", equipment.discovered_ids().size() == 4)
	equipment.select_item(&"sword")
	player.suppress_equipment_signal = true
	equipment._request_equip()
	_check("no optimistic equipment UI", equipment.actual_weapon == &"none")
	player.suppress_equipment_signal = false
	player.equipment_changed.emit(&"sword", false, 1)
	_check("equipment UI follows real signal", equipment.actual_weapon == &"sword" and flow.hud.snapshot["weapon_id"] == &"sword")
	equipment.select_item(&"shield")
	equipment._request_equip()
	_check("shield reflected from signal", equipment.actual_shield and flow.hud.snapshot["shield"])
	flow.close_screen()
	_check("equipment close restores input", player.input_enabled and not get_tree().paused)
	player.damage()
	_check("death offers retry/menu and pauses", flow.current_screen == &"death" and get_tree().paused)
	flow.restart_session(&"retry")
	await _frames()
	_check("retry resets flags equipment and HUD", not Level1Progress.get_flag(&"has_sword") and player.weapon_id == &"none" and flow.hud.snapshot["health"] == 100 and flow.hud.snapshot["stamina"] == 100 and not get_tree().paused and player.input_enabled)
	discover()
	flow.open_screen(&"main")
	flow.restart_session(&"new_game")
	_check("new game resets discovered inventory", not Level1Progress.get_flag(&"has_axe") and flow.hud.snapshot["health"] == 100)
	var extra_hud: GameHUD = preload("res://ui/hud.tscn").instantiate() as GameHUD
	add_child(extra_hud)
	await _frames()
	_check("single HUD", get_tree().get_nodes_in_group(&"game_hud").size() == 1)
	var legacy: Node = Node.new()
	add_child(legacy)
	flow.hud.bind_player(legacy)
	flow.open_screen(&"equipment")
	(flow.modal as EquipmentMenu).bind_player(legacy)
	_check("missing player members guarded", (flow.modal as EquipmentMenu)._equip.disabled)
	flow.close_screen()
	flow.bind_player(player)
	legacy.queue_free()
	var terminal: Interactable = preload("res://interactables/access_terminal.tscn").instantiate() as Interactable
	add_child(terminal)
	for id: StringName in [&"record_a", &"record_b", &"record_c"]:
		Level1Progress.set_flag(id)
	terminal.interact(player)
	await _frames()
	var view: PuzzleTerminalView = terminal._dialog._puzzle
	var terminal_animation: AnimationPlayer = view.get_node("AnimationPlayer")
	if terminal_animation.current_animation == &"terminal_enter":
		await terminal_animation.animation_finished
	view.select_evidence(&"record_c")
	view.select_evidence(&"record_a")
	_check("puzzle error gives hint without unlock", not Level1Progress.get_flag(&"puzzle_solved") and "Pista:" in view._rejected.text)
	view.select_evidence(&"record_a")
	view.select_evidence(&"record_b")
	view.select_evidence(&"record_b")
	view.select_evidence(&"record_c")
	_check("puzzle retry succeeds through view", Level1Progress.get_flag(&"puzzle_solved"))
	view.close()
	await _frames()
	_check("puzzle close restores input and pause", player.input_enabled and not get_tree().paused)
	terminal.queue_free()
	flow.open_screen(&"ending")
	_check("ending screen instantiated", flow.current_screen == &"ending")
	flow.close_screen()
	var passed: int = 0
	for item: Dictionary in results:
		if item["passed"]:
			passed += 1
	_status.text = "UI: %d/%d OK" % [passed, results.size()]
	print("UI_LAB ", JSON.stringify(results))
	testing = false
	return results
