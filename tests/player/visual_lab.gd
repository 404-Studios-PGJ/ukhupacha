extends Node2D

@onready var player: Player = $Player
@onready var lbl_info: Label = $CanvasLayer/Panel/VBoxContainer/LblInfo

func _ready() -> void:
	if player != null:
		player.equipment_changed.connect(_on_equipment_changed)
		_update_ui()

func _process(_delta: float) -> void:
	_handle_lab_inputs()
	_update_ui()

func _handle_lab_inputs() -> void:
	if Input.is_key_pressed(KEY_1):
		_equip_preset(&"none", false)
	elif Input.is_key_pressed(KEY_2):
		_equip_preset(&"sword", false)
	elif Input.is_key_pressed(KEY_3):
		_equip_preset(&"axe", false)
	elif Input.is_key_pressed(KEY_4):
		_equip_preset(&"none", true)
	elif Input.is_key_pressed(KEY_5):
		_equip_preset(&"sword", true)
	elif Input.is_key_pressed(KEY_6):
		_equip_preset(&"axe", true)

func _equip_preset(weapon: StringName, shield: bool) -> void:
	if player == null:
		return
	player.equip_weapon(weapon)
	if shield:
		player.equip_shield()
	else:
		player.unequip_shield()

func _on_equipment_changed(_weapon: StringName, _shield: bool, _tier: int) -> void:
	_update_ui()

func _update_ui() -> void:
	if lbl_info == null or player == null:
		return
	
	var act: String = "stand"
	var frame: int = 0
	var total: int = 1
	if player.visual != null:
		act = player.visual.current_action
		frame = player.visual.frame_index
		total = player.visual.total_frames
	
	lbl_info.text = """[VISUAL LAB - CONTROLES]
WASD: Moverse (4 direcciones)
Shift: Correr (140 px/s vs 80 px/s)
Click Izq: Atacar (slash)

[ESTADO ACTUAL]
Arma: %s | Escudo: %s | Tier: %d
Acción: %s (Frame %d/%d)
Dirección: %s
Velocidad: (%.1f, %.1f)
Posición pies: (%.1f, %.1f)

[PRESETS DE EQUIPO (Teclas 1-6 o botones)]
[1] T0 Puños / Desarmado
[2] T1 Espada
[3] T1 Hacha
[4] T1 Solo Escudo
[5] T1 Espada + Escudo
[6] T1 Hacha + Escudo""" % [
		player.weapon_id,
		"Sí" if player.has_shield else "No",
		player.tier,
		act,
		frame + 1,
		total,
		player.direccion_mirando,
		player.velocity.x,
		player.velocity.y,
		player.global_position.x,
		player.global_position.y
	]

func _on_btn_t0_pressed() -> void:
	_equip_preset(&"none", false)

func _on_btn_sword_pressed() -> void:
	_equip_preset(&"sword", false)

func _on_btn_axe_pressed() -> void:
	_equip_preset(&"axe", false)

func _on_btn_shield_pressed() -> void:
	_equip_preset(&"none", true)

func _on_btn_sword_shield_pressed() -> void:
	_equip_preset(&"sword", true)

func _on_btn_axe_shield_pressed() -> void:
	_equip_preset(&"axe", true)
