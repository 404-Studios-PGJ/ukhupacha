extends Node2D

const LabPlayer = preload("res://tests/interactables/test_player.gd")
var results: Array[Dictionary] = []
var testing: bool = false
@onready var player: LabPlayer = $TestPlayer
@onready var interaction: InteractionSystem = $InteractionSystem
@onready var terminal: Interactable = $PuzzleTerminal
@onready var door: DoorGate = $Door1
@onready var status_label: Label = $UI/Status


func _ready() -> void:
	$UI/Reset.pressed.connect(reset_lab)
	$UI/Tests.pressed.connect(run_checks)
	reset_lab()


func reset_lab() -> void:
	Level1Progress.reset()
	player.position = Vector2(64, 150)
	for node: Node in get_tree().get_nodes_in_group(&"interactables"):
		(node as Interactable).interaction_count = 0
	status_label.text = "WASD · E interactuar · botones para reset/pruebas"


func _frames(count: int = 3) -> void:
	for index: int in range(count):
		await get_tree().physics_frame
	await get_tree().process_frame


func _press(held_frames: int = 3) -> void:
	Input.action_press(&"interactuar")
	await _frames(held_frames)
	Input.action_release(&"interactuar")
	await _frames()


func _close_dialogs() -> void:
	for item: Node in get_tree().get_nodes_in_group(&"interactables"):
		for child: Node in item.get_children():
			if child is InteractionDialog:
				(child as InteractionDialog).close()
	await _frames()


func _check(case_name: String, passed: bool) -> void:
	results.append({"case": case_name, "passed": passed})


func _blocked_at_gate(gate: DoorGate) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		gate.global_position - Vector2(24, 0), gate.global_position + Vector2(24, 0), 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func run_checks() -> Array[Dictionary]:
	if testing:
		return results
	testing = true
	$UI/Tests.disabled = true
	$UI/Reset.disabled = true
	results.clear()
	reset_lab()
	await _frames()
	var events: Dictionary[String, int] = {"flags": 0, "doors": 0}
	var on_flag: Callable = func(_flag: StringName, _value: bool) -> void:
		events["flags"] += 1
	var on_door: Callable = func(_id: StringName, _opened: bool) -> void:
		events["doors"] += 1
	Level1Progress.flag_changed.connect(on_flag)
	Level1Progress.door_state_changed.connect(on_door)
	_check("door initially blocks physics ray", _blocked_at_gate(door))
	_check("cannot solve without records", not bool(terminal.call("submit_answer", &"contradiction")))
	_check("unknown flag rejected", not Level1Progress.set_flag(&"unknown"))

	player.position = Vector2(64, 260)
	await _frames()
	await _press(12)
	_check("held E fires once; nearest only", $Near.interaction_count == 1 and $Far.interaction_count == 0)
	await _press()
	_check("second E fires once more", $Near.interaction_count == 2)
	player.set_input_enabled(false)
	await _press()
	_check("disabled player ignores E", $Near.interaction_count == 2)
	player.set_input_enabled(true)
	player.position = Vector2(32, 260)
	await _frames()
	await _press()
	_check("outside 24 px ignores E", $Near.interaction_count == 2)
	player.position = Vector2(204, 260)
	await _frames()
	await _press()
	_check("E blocked through layer 1 wall", $BehindWall.interaction_count == 0 and interaction.focused == null)

	for record_name: String in ["RecordC", "RecordA", "RecordB"]:
		var record: Interactable = get_node(record_name) as Interactable
		player.position = record.position + Vector2(0, 18)
		await _frames()
		await _press()
		_check("read " + record_name, record.interaction_count == 1 and not player.input_enabled)
		await _close_dialogs()
	_check("any order records do not auto-open door", Level1Progress.all_records_read() and not door.opened)
	player.position = $RecordA.position + Vector2(0, 18)
	await _frames()
	await _press()
	await _close_dialogs()
	_check("record can be reread", $RecordA.interaction_count == 2)
	_check("rereading emits no duplicate flag changes", events["flags"] == 3)
	_check("incorrect answer gives hint", not bool(terminal.call("submit_answer", &"agreement")) and "Pista:" in str(terminal.get("feedback")))
	_check("retry correct answer", bool(terminal.call("submit_answer", &"contradiction")))
	terminal.call("submit_answer", &"contradiction")
	_check("solving twice emits one door change", events["doors"] == 1)
	await _frames()
	_check("door actually disables collider", door.opened and not _blocked_at_gate(door))
	player.position = door.position - Vector2(22, 0)
	player.move_and_collide(Vector2(44, 0))
	_check("body crosses open gate", player.position.x > door.position.x)

	player.position = $SwordPickup.position + Vector2(0, 18)
	await _frames()
	await _press()
	await _press()
	_check("pickup equips exactly once", player.weapon_id == &"sword" and player.equip_calls == 1 and Level1Progress.get_flag(&"has_sword"))
	$AxePickup.interact(player)
	$ShieldPickup.interact(player)
	_check("axe and shield update player and flags", player.weapon_id == &"axe" and player.shield and Level1Progress.get_flag(&"has_axe") and Level1Progress.get_flag(&"has_shield"))
	$MemoryPoint.register_memory()
	Level1Progress.set_flag(&"elite_defeated")
	await _frames()
	_check("memory and elite open door4 and rift", not _blocked_at_gate($Door4) and not _blocked_at_gate($Rift))
	Level1Progress.set_flag(&"demo_complete")
	_check("completion flag available after elite", Level1Progress.get_flag(&"demo_complete"))

	var late_gate: DoorGate = preload("res://interactables/door_gate.tscn").instantiate() as DoorGate
	late_gate.position = Vector2(600, 300)
	add_child(late_gate)
	await _frames()
	_check("new room gate reads existing progress", late_gate.opened and not _blocked_at_gate(late_gate))
	late_gate.queue_free()
	reset_lab()
	await _frames()
	var all_clear: bool = true
	for flag: StringName in Level1Progress.FLAGS:
		all_clear = all_clear and not Level1Progress.get_flag(flag)
	_check("reset clears every flag and closes doors", all_clear and _blocked_at_gate(door) and _blocked_at_gate($Door4) and _blocked_at_gate($Rift))
	_check("reset restores pickups and input", $SwordPickup.visible and $AxePickup.visible and $ShieldPickup.visible and player.input_enabled and player.weapon_id == &"none")
	var legacy: Node2D = Node2D.new()
	add_child(legacy)
	_check("legacy player without input bridge is blocked", not interaction.player_can_interact(legacy))
	$SwordPickup.interact(legacy)
	_check("legacy pickup keeps equipment available", not Level1Progress.get_flag(&"has_sword") and $SwordPickup.visible)
	await _close_dialogs()
	legacy.queue_free()
	terminal.interact(player)
	Level1Progress.reset()
	await _frames()
	var has_dialog: bool = false
	for child: Node in terminal.get_children():
		has_dialog = has_dialog or child is InteractionDialog
	_check("reset closes modal and restores input", not has_dialog and player.input_enabled)
	Level1Progress.flag_changed.disconnect(on_flag)
	Level1Progress.door_state_changed.disconnect(on_door)
	player.position = Vector2(64, 150)
	var passed: int = 0
	for result: Dictionary in results:
		if result["passed"]:
			passed += 1
	status_label.text = "Pruebas: %d/%d OK · WASD / E" % [passed, results.size()]
	print("PUZZLE_LAB ", JSON.stringify(results))
	testing = false
	$UI/Tests.disabled = false
	$UI/Reset.disabled = false
	return results


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("#1b1d1f"))
	draw_rect(Rect2(210, 232, 8, 56), Color("#6f8f70"))
