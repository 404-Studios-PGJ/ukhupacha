extends Node2D

@onready var player: Player = $Player
@onready var dummy_arena: Node2D = $DummyArena
@onready var dummy_wall: Node2D = $DummyBehindWall
@onready var lbl_combat_info: Label = $CanvasLayer/Panel/VBoxContainer/LblCombatInfo

var last_combat_event: String = "Ninguno"
var white_attack_counter: int = 1000
var red_attack_counter: int = 2000

func _ready() -> void:
	if player != null:
		player.health_changed.connect(_on_health_changed)
		player.stamina_changed.connect(_on_stamina_changed)
		player.combat.combat_state_changed.connect(_on_combat_state_changed)
		player.player_died.connect(_on_player_died)
		player.equip_weapon(&"sword")
	_update_ui()

func _process(_delta: float) -> void:
	_handle_lab_inputs()
	_update_ui()

func _handle_lab_inputs() -> void:
	if Input.is_key_pressed(KEY_1):
		player.equip_weapon(&"none")
		player.unequip_shield()
	elif Input.is_key_pressed(KEY_2):
		player.equip_weapon(&"sword")
		player.unequip_shield()
	elif Input.is_key_pressed(KEY_3):
		player.equip_weapon(&"axe")
		player.unequip_shield()
	elif Input.is_key_pressed(KEY_4):
		player.equip_shield()
	elif Input.is_key_pressed(KEY_J):
		trigger_white_attack()
	elif Input.is_key_pressed(KEY_K):
		trigger_red_attack()
	elif Input.is_key_pressed(KEY_R):
		reset_lab()

func _on_health_changed(_cur: float, _max: float) -> void:
	_update_ui()

func _on_stamina_changed(_cur: float, _max: float) -> void:
	_update_ui()

func _on_combat_state_changed(_new_state: String) -> void:
	_update_ui()

func _on_player_died() -> void:
	last_combat_event = "¡JUGADOR HA MUERTO!"
	_update_ui()

func trigger_white_attack() -> void:
	if player == null:
		return
	white_attack_counter += 1
	var hit = {
		"attack_id": white_attack_counter,
		"source": dummy_arena,
		"damage": 20.0,
		"parryable": true,
		"unblockable": false,
		"direction": Vector2.LEFT
	}
	var res = player.receive_hit(hit)
	last_combat_event = "Ataque Blanco: Resultado = %s" % res
	_update_ui()

func trigger_red_attack() -> void:
	if player == null:
		return
	red_attack_counter += 1
	var hit = {
		"attack_id": red_attack_counter,
		"source": dummy_arena,
		"damage": 30.0,
		"parryable": false,
		"unblockable": true,
		"direction": Vector2.LEFT
	}
	var res = player.receive_hit(hit)
	last_combat_event = "Ataque Rojo (Inbloqueable): Resultado = %s" % res
	_update_ui()

func reset_lab() -> void:
	if player == null:
		return
	player.combat.current_health = player.combat.max_health
	player.combat.current_stamina = player.combat.max_stamina
	player.combat.current_state = PlayerCombat.State.IDLE
	player.combat.cancel_attack()
	player.visual.play("stand", player.direccion_mirando)
	last_combat_event = "Laboratorio Reiniciado"
	if dummy_arena != null and dummy_arena.has_method("reset_dummy"):
		dummy_arena.reset_dummy()
	if dummy_wall != null and dummy_wall.has_method("reset_dummy"):
		dummy_wall.reset_dummy()
	_update_ui()

func _update_ui() -> void:
	if lbl_combat_info == null or player == null or player.combat == null:
		return
	
	var c = player.combat
	var invuln_str = " (¡INVULNERABLE!)" if c.is_dodge_invulnerable() else ""
	var debug_str = "RNG 95%/5%"
	if c.debug_force_parry == true:
		debug_str = "FORZADO 100% ÉXITO"
	elif c.debug_force_parry == false:
		debug_str = "FORZADO 100% FALLO"
	
	lbl_combat_info.text = """[ESTADO COMBATE]
Salud: %.1f / %.1f
Stamina: %.1f / %.1f
Estado: %s%s
Arma: %s | Escudo: %s
Modo Parry Debug: %s
Último Evento: %s""" % [
		c.current_health,
		c.max_health,
		c.current_stamina,
		c.max_stamina,
		PlayerCombat.State.keys()[c.current_state],
		invuln_str,
		player.weapon_id,
		"Sí" if player.has_shield else "No",
		debug_str,
		last_combat_event
	]

func _on_btn_white_attack_pressed() -> void:
	trigger_white_attack()

func _on_btn_red_attack_pressed() -> void:
	trigger_red_attack()

func _on_btn_force_parry_success_pressed() -> void:
	if player != null and player.combat != null:
		player.combat.debug_force_parry = true
		last_combat_event = "Debug: Forzado 100% éxito parry"
		_update_ui()

func _on_btn_force_parry_fail_pressed() -> void:
	if player != null and player.combat != null:
		player.combat.debug_force_parry = false
		last_combat_event = "Debug: Forzado 100% fallo fortuito parry"
		_update_ui()

func _on_btn_reset_parry_rng_pressed() -> void:
	if player != null and player.combat != null:
		player.combat.debug_force_parry = null
		last_combat_event = "Debug: Restaurado RNG normal (95% / 5%)"
		_update_ui()

func _on_btn_reset_pressed() -> void:
	reset_lab()
