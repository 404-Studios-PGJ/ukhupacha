extends Node2D

@onready var player: Player = $Player
@onready var dummy_arena: Node2D = $DummyArena
@onready var dummy_wall: Node2D = $DummyBehindWall
@onready var lbl_combat_info: Label = $CanvasLayer/Panel/VBoxContainer/LblCombatInfo

var last_combat_event: String = "Ninguno"
var white_attack_counter: int = 1000
var red_attack_counter: int = 2000

# ---- Edge detection (activa solo en el frame del press) ----
var _key_j_prev: bool = false
var _key_k_prev: bool = false
var _key_r_prev: bool = false
var _key_1_prev: bool = false
var _key_2_prev: bool = false
var _key_3_prev: bool = false
var _key_4_prev: bool = false
var _key_h_prev: bool = false  # H = heal

# ---- Estado de telegrafía ----
var _attack_pending: bool = false   # true mientras hay un ataque en preparación

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
	# Leer estado actual
	var j_now: bool = Input.is_key_pressed(KEY_J)
	var k_now: bool = Input.is_key_pressed(KEY_K)
	var r_now: bool = Input.is_key_pressed(KEY_R)
	var k1_now: bool = Input.is_key_pressed(KEY_1)
	var k2_now: bool = Input.is_key_pressed(KEY_2)
	var k3_now: bool = Input.is_key_pressed(KEY_3)
	var k4_now: bool = Input.is_key_pressed(KEY_4)
	var h_now: bool = Input.is_key_pressed(KEY_H)
	
	# Equipamiento — solo en el frame del press
	if k1_now and not _key_1_prev:
		player.equip_weapon(&"none")
		player.unequip_shield()
	elif k2_now and not _key_2_prev:
		player.equip_weapon(&"sword")
		player.unequip_shield()
	elif k3_now and not _key_3_prev:
		player.equip_weapon(&"axe")
		player.unequip_shield()
	elif k4_now and not _key_4_prev:
		player.equip_shield()
	
	# Reset — solo en el frame del press
	if r_now and not _key_r_prev:
		reset_lab()
	
	# Curar — solo en el frame del press
	if h_now and not _key_h_prev:
		heal_player()
	
	# Ataques telegrafados — solo en el frame del press y sin un ataque en curso
	if not _attack_pending:
		if j_now and not _key_j_prev:
			trigger_white_attack()
		elif k_now and not _key_k_prev:
			trigger_red_attack()
	
	# Guardar estado previo
	_key_j_prev = j_now
	_key_k_prev = k_now
	_key_r_prev = r_now
	_key_1_prev = k1_now
	_key_2_prev = k2_now
	_key_3_prev = k3_now
	_key_4_prev = k4_now
	_key_h_prev = h_now

func _on_health_changed(_cur: float, _max: float) -> void:
	_update_ui()

func _on_stamina_changed(_cur: float, _max: float) -> void:
	_update_ui()

func _on_combat_state_changed(_new_state: String) -> void:
	_update_ui()

func _on_player_died() -> void:
	last_combat_event = "¡JUGADOR HA MUERTO! Pulsa R para reiniciar."
	_update_ui()

# ========================================================
# Ataques telegrafados (con delay para que puedas reaccionar)
# ========================================================

func trigger_white_attack() -> void:
	if player == null:
		return
	_attack_pending = true
	
	# Mensaje de aviso en pantalla
	last_combat_event = "⚠️ ATAQUE BLANCO en 1.5s — ¡Activa Parry (RMB) o Guardia (RMB hold)!"
	_update_ui()
	
	# Esperar 1.5 segundos antes de impactar
	await get_tree().create_timer(1.5).timeout
	
	if player == null:
		_attack_pending = false
		return
	
	white_attack_counter += 1
	var hit = {
		"attack_id": white_attack_counter,
		"source": dummy_arena,
		"damage": 15.0,           # reducido de 20 → 15
		"parryable": true,
		"unblockable": false,
		"direction": Vector2.LEFT
	}
	
	var was_state: String = PlayerCombat.State.keys()[player.combat.current_state]
	var res = player.receive_hit(hit)
	
	# Feedback con contexto
	match res:
		"parry_success":
			last_combat_event = "✅ PARRY PERFECTO — 0 daño, golpe devuelto. Estado era: %s" % was_state
		"parry_recovery":
			last_combat_event = "😵 PARRY EN RECOVERY — penalización ×1.25. Estado era: %s" % was_state
		"blocked":
			last_combat_event = "🛡 BLOQUEADO — daño reducido. Estado era: %s" % was_state
		"dodge":
			last_combat_event = "💨 ESQUIVADO (invulnerabilidad). Estado era: %s" % was_state
		"hit":
			last_combat_event = "💥 IMPACTO — 15 dmg. Estado era: %s. Tip: activa Parry o Guardia ANTES del golpe." % was_state
		_:
			last_combat_event = "Ataque Blanco: %s (estado era: %s)" % [res, was_state]
	
	_update_ui()
	_attack_pending = false

func trigger_red_attack() -> void:
	if player == null:
		return
	_attack_pending = true
	
	# Mensaje de aviso en pantalla
	last_combat_event = "🔴 ATAQUE ROJO (INBLOQUEABLE) en 1.5s — ¡Solo puedes esquivar! (Espacio)"
	_update_ui()
	
	await get_tree().create_timer(1.5).timeout
	
	if player == null:
		_attack_pending = false
		return
	
	red_attack_counter += 1
	var hit = {
		"attack_id": red_attack_counter,
		"source": dummy_arena,
		"damage": 20.0,           # reducido de 30 → 20
		"parryable": false,
		"unblockable": true,
		"direction": Vector2.LEFT
	}
	
	var was_state: String = PlayerCombat.State.keys()[player.combat.current_state]
	var res = player.receive_hit(hit)
	
	match res:
		"dodge":
			last_combat_event = "💨 ESQUIVADO — ataque rojo evadido. Estado era: %s" % was_state
		"hit":
			last_combat_event = "💥 IMPACTO ROJO — 20 dmg. Estado era: %s. Tip: esquiva (Espacio) 0.08–0.18s antes del golpe." % was_state
		_:
			last_combat_event = "Ataque Rojo: %s (estado era: %s)" % [res, was_state]
	
	_update_ui()
	_attack_pending = false

func heal_player() -> void:
	if player == null or player.combat == null:
		return
	player.combat.current_health = player.combat.max_health
	player.combat.current_stamina = player.combat.max_stamina
	# Re-habilitar si estaba muerto
	if player.combat.current_state == PlayerCombat.State.DEAD:
		player.combat.current_state = PlayerCombat.State.IDLE
		player.visual.play("stand", player.direccion_mirando)
		player.set_input_enabled(true)
	last_combat_event = "💊 Jugador curado (H)"
	_update_ui()

func reset_lab() -> void:
	if player == null:
		return
	player.combat.current_health = player.combat.max_health
	player.combat.current_stamina = player.combat.max_stamina
	player.combat.current_state = PlayerCombat.State.IDLE
	player.combat.cancel_attack()
	player.visual.play("stand", player.direccion_mirando)
	player.set_input_enabled(true)
	last_combat_event = "Laboratorio Reiniciado (R)"
	_attack_pending = false
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
	
	var pending_str = "\n⏳ Ataque entrante..." if _attack_pending else ""
	
	lbl_combat_info.text = """[ESTADO COMBATE]
Salud: %.1f / %.1f
Stamina: %.1f / %.1f
Estado: %s%s
Arma: %s | Escudo: %s
Modo Parry Debug: %s
Último Evento: %s%s

Teclas: J=Ataque blanco(parriable) K=Ataque rojo(inbloqueable)
        H=Curar  R=Reiniciar  1-4=Equipo
Parry/Guard: RMB | Esquivar: Espacio""" % [
		c.current_health,
		c.current_health if false else c.current_health,  # placeholder; max from signal
		c.current_stamina,
		c.max_stamina,
		PlayerCombat.State.keys()[c.current_state],
		invuln_str,
		player.weapon_id,
		"Sí" if player.has_shield else "No",
		debug_str,
		last_combat_event,
		pending_str
	]
	# fix: usar max_health directamente
	lbl_combat_info.text = """[ESTADO COMBATE]
Salud: %.1f / %.1f
Stamina: %.1f / %.1f
Estado: %s%s
Arma: %s | Escudo: %s
Modo Parry Debug: %s
Último Evento: %s%s

Teclas: J=Ataque blanco(parriable) K=Ataque rojo(inbloqueable)
        H=Curar  R=Reiniciar  1-4=Equipo
Parry/Guard: RMB | Esquivar: Espacio""" % [
		c.current_health,
		c.max_health,
		c.current_stamina,
		c.max_stamina,
		PlayerCombat.State.keys()[c.current_state],
		invuln_str,
		player.weapon_id,
		"Sí" if player.has_shield else "No",
		debug_str,
		last_combat_event,
		pending_str
	]

func _on_btn_white_attack_pressed() -> void:
	if not _attack_pending:
		trigger_white_attack()

func _on_btn_red_attack_pressed() -> void:
	if not _attack_pending:
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
