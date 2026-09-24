extends Node
## Estado persistente entre salas; reset solo en Nueva partida.

signal flag_changed(flag: StringName, value: bool)
signal progress_reset()
signal door_state_changed(door_id: StringName, opened: bool)

const FLAGS: Array[StringName] = [
	&"record_a", &"record_b", &"record_c", &"puzzle_solved",
	&"has_sword", &"has_axe", &"has_shield", &"memory_restored",
	&"elite_defeated", &"demo_complete",
]
const DOORS: Array[StringName] = [&"door_1", &"door_4", &"rift"]
var _flags: Dictionary[StringName, bool] = {}


func get_flag(flag: StringName) -> bool:
	return _flags.get(flag, false)


func set_flag(flag: StringName, value: bool = true) -> bool:
	if flag not in FLAGS:
		return false
	if value and flag == &"puzzle_solved" and not all_records_read():
		return false
	if value and flag == &"demo_complete" and not get_flag(&"elite_defeated"):
		return false
	if get_flag(flag) == value:
		return false
	var previous: Dictionary[StringName, bool] = _door_snapshot()
	_flags[flag] = value
	flag_changed.emit(flag, value)
	if not value and flag in [&"record_a", &"record_b", &"record_c"]:
		if get_flag(&"puzzle_solved"):
			_flags[&"puzzle_solved"] = false
			flag_changed.emit(&"puzzle_solved", false)
	if not value and flag == &"elite_defeated" and get_flag(&"demo_complete"):
		_flags[&"demo_complete"] = false
		flag_changed.emit(&"demo_complete", false)
	_emit_door_changes(previous)
	return true


func all_records_read() -> bool:
	return get_flag(&"record_a") and get_flag(&"record_b") and get_flag(&"record_c")


func is_door_open(door_id: StringName) -> bool:
	match door_id:
		&"door_1":
			return all_records_read() and get_flag(&"puzzle_solved")
		&"door_4":
			return get_flag(&"memory_restored")
		&"rift":
			return get_flag(&"elite_defeated")
	return false


func reset() -> void:
	var previous: Dictionary[StringName, bool] = _door_snapshot()
	var changed: Array[StringName] = []
	for flag: StringName in FLAGS:
		if get_flag(flag):
			changed.append(flag)
	_flags.clear()
	for flag: StringName in changed:
		flag_changed.emit(flag, false)
	_emit_door_changes(previous)
	progress_reset.emit()


func _door_snapshot() -> Dictionary[StringName, bool]:
	var snapshot: Dictionary[StringName, bool] = {}
	for door_id: StringName in DOORS:
		snapshot[door_id] = is_door_open(door_id)
	return snapshot


func _emit_door_changes(previous: Dictionary[StringName, bool]) -> void:
	for door_id: StringName in DOORS:
		var opened: bool = is_door_open(door_id)
		if previous[door_id] != opened:
			door_state_changed.emit(door_id, opened)
