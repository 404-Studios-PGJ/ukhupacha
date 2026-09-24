extends Node2D
## Simulación del contrato de Jhon; solo laboratorio.
signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal equipment_changed(weapon_id: StringName, shield: bool, tier: int)
signal player_died()

var health: float = 84.0
var stamina: float = 63.0
var weapon_id: StringName = &"none"
var shield: bool = false
var input_enabled: bool = true
var suppress_equipment_signal: bool = false
var ticks: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group(&"player")


func _physics_process(_delta: float) -> void:
	ticks += 1


func get_hud_state() -> Dictionary:
	return {"health": health, "max_health": 100.0, "stamina": stamina, "max_stamina": 100.0, "weapon_id": weapon_id, "shield": shield, "tier": 0 if weapon_id == &"none" else 1}


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func is_input_enabled() -> bool:
	return input_enabled


func equip_weapon(id: StringName) -> void:
	weapon_id = id
	if not suppress_equipment_signal:
		equipment_changed.emit(weapon_id, shield, 0 if weapon_id == &"none" else 1)


func equip_shield() -> void:
	shield = true
	if not suppress_equipment_signal:
		equipment_changed.emit(weapon_id, shield, 1)


func reset_player() -> void:
	health = 100.0
	stamina = 100.0
	weapon_id = &"none"
	shield = false
	input_enabled = true
	health_changed.emit(health, 100.0)
	stamina_changed.emit(stamina, 100.0)
	equipment_changed.emit(weapon_id, shield, 0)


func damage() -> void:
	health = 0.0
	health_changed.emit(health, 100.0)
	player_died.emit()
