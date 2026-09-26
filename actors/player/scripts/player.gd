class_name Player extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal equipment_changed(weapon_id: StringName, shield: bool, tier: int)
signal player_died()

@export var velocidad_caminar: float = 80.0
@export var velocidad_correr: float = 140.0

@export var weapon_id: StringName = &"none"
@export var has_shield: bool = false
@export var tier: int = 1

var input_enabled: bool = true
var direccion_mirando: String = "down"

# Nodos
@onready var visual: Node2D = $Visual
@onready var combat: PlayerCombat = $Combat
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_pivot: Node2D = $AttackPivot
@onready var attack_area: Area2D = $AttackPivot/AttackArea
@onready var attack_shape: CollisionShape2D = $AttackPivot/AttackArea/CollisionShape2D

# Nodos legados preservados
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_combate: Sprite2D = $SpriteCombate
@onready var sprite_espada: Sprite2D = $SpriteEspada
@onready var reproductor_animacion: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if not is_in_group("player"):
		add_to_group("player")
	
	_ensure_node_references()
	
	if visual != null:
		visual.set_equipment(weapon_id, has_shield, tier)
		visual.play("stand", direccion_mirando)

func _on_combat_health_changed(c: float, m: float) -> void:
	health_changed.emit(c, m)

func _on_combat_stamina_changed(c: float, m: float) -> void:
	stamina_changed.emit(c, m)

func _on_combat_player_died() -> void:
	player_died.emit()

func _ensure_node_references() -> void:
	if visual == null:
		visual = get_node_or_null("Visual")
	if combat == null:
		combat = get_node_or_null("Combat")
	if hurtbox == null:
		hurtbox = get_node_or_null("Hurtbox")
	if attack_pivot == null:
		attack_pivot = get_node_or_null("AttackPivot")
	if attack_area == null and attack_pivot != null:
		attack_area = attack_pivot.get_node_or_null("AttackArea")
	if attack_shape == null and attack_area != null:
		attack_shape = attack_area.get_node_or_null("CollisionShape2D")
	
	if combat != null:
		combat.setup(self, visual, hurtbox, attack_pivot, attack_area, attack_shape)
		if not combat.health_changed.is_connected(_on_combat_health_changed):
			combat.health_changed.connect(_on_combat_health_changed)
		if not combat.stamina_changed.is_connected(_on_combat_stamina_changed):
			combat.stamina_changed.connect(_on_combat_stamina_changed)
		if not combat.player_died.is_connected(_on_combat_player_died):
			combat.player_died.connect(_on_combat_player_died)

func _physics_process(delta: float) -> void:
	_ensure_node_references()
	
	if combat != null:
		combat.process_combat(delta)
		
		# Prioridad: muerte > daño > esquiva
		if combat.current_state == PlayerCombat.State.DEAD:
			velocity = Vector2.ZERO
			move_and_slide()
			return
		
		if combat.current_state in [PlayerCombat.State.HURT, PlayerCombat.State.DODGE]:
			# En HURT se detiene el movimiento; en DODGE el movimiento lo procesa combat
			return
	
	if not input_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		if visual != null and combat != null and combat.current_state in [PlayerCombat.State.IDLE, PlayerCombat.State.MOVE]:
			visual.play("stand", direccion_mirando)
		return
	
	_process_player_inputs(delta)

func _process_player_inputs(_delta: float) -> void:
	# 1. Esquiva (Espacio: "esquivar" o alias "saltar")
	var dodge_pressed: bool = false
	if InputMap.has_action("esquivar") and Input.is_action_just_pressed("esquivar"):
		dodge_pressed = true
	elif InputMap.has_action("saltar") and Input.is_action_just_pressed("saltar"):
		dodge_pressed = true
	
	var dir_input: Vector2 = Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	if dodge_pressed and combat != null and combat.can_dodge():
		combat.start_dodge(dir_input, direccion_mirando)
		return
	
	# 2. Defensa / Parry / Guardia (RMB: "defender" o alias "disparar")
	var defend_just_pressed: bool = false
	var defend_held: bool = false
	if InputMap.has_action("defender"):
		defend_just_pressed = Input.is_action_just_pressed("defender")
		defend_held = Input.is_action_pressed("defender")
	elif InputMap.has_action("disparar"):
		defend_just_pressed = Input.is_action_just_pressed("disparar")
		defend_held = Input.is_action_pressed("disparar")
	
	if defend_just_pressed and combat != null and combat.can_parry():
		combat.start_parry(direccion_mirando)
		return
	elif defend_held and combat != null and combat.current_state not in [PlayerCombat.State.PARRY, PlayerCombat.State.PARRY_RECOVERY]:
		combat.start_guard(direccion_mirando)
	else:
		if combat != null and combat.current_state == PlayerCombat.State.GUARD:
			combat.stop_guard()
	
	# 3. Ataque (LMB: "atacar" o alias "cuerpo a cuerpo")
	var attack_pressed: bool = false
	if InputMap.has_action("atacar") and Input.is_action_just_pressed("atacar"):
		attack_pressed = true
	elif InputMap.has_action("cuerpo a cuerpo") and Input.is_action_just_pressed("cuerpo a cuerpo"):
		attack_pressed = true
	
	if attack_pressed and combat != null and combat.can_attack():
		combat.start_attack(direccion_mirando)
		return
	
	# 4. Locomoción
	if combat != null and combat.current_state in [PlayerCombat.State.IDLE, PlayerCombat.State.MOVE]:
		var corriendo: bool = Input.is_action_pressed("correr")
		if dir_input != Vector2.ZERO:
			dir_input = dir_input.normalized()
			actualizar_orientacion(dir_input)
			var vel_target: float = velocidad_correr if corriendo else velocidad_caminar
			velocity = dir_input * vel_target
			combat.current_state = PlayerCombat.State.MOVE
			if visual != null:
				visual.play("run" if corriendo else "walk", direccion_mirando)
		else:
			velocity = Vector2.ZERO
			combat.current_state = PlayerCombat.State.IDLE
			if visual != null:
				visual.play("stand", direccion_mirando)
		
		move_and_slide()
	elif combat != null and combat.current_state in [PlayerCombat.State.GUARD, PlayerCombat.State.ATTACK_1, PlayerCombat.State.ATTACK_2]:
		velocity = Vector2.ZERO
		move_and_slide()

func actualizar_orientacion(dir_input: Vector2) -> void:
	if abs(dir_input.x) >= abs(dir_input.y):
		if dir_input.x < 0.0:
			direccion_mirando = "left"
		elif dir_input.x > 0.0:
			direccion_mirando = "right"
	else:
		if dir_input.y > 0.0:
			direccion_mirando = "down"
		elif dir_input.y < 0.0:
			direccion_mirando = "up"

# ==================== CONTRATO DE INTEGRACIÓN ====================

func receive_hit(hit: Dictionary) -> StringName:
	_ensure_node_references()
	if combat != null:
		return combat.receive_hit(hit)
	return &"DAMAGED"

func equip_weapon(p_weapon_id: StringName) -> void:
	weapon_id = p_weapon_id
	_ensure_node_references()
	if visual != null:
		visual.set_equipment(weapon_id, has_shield, tier)
	equipment_changed.emit(weapon_id, has_shield, tier)

func equip_shield() -> void:
	has_shield = true
	_ensure_node_references()
	if visual != null:
		visual.set_equipment(weapon_id, has_shield, tier)
	equipment_changed.emit(weapon_id, has_shield, tier)

func unequip_shield() -> void:
	has_shield = false
	_ensure_node_references()
	if visual != null:
		visual.set_equipment(weapon_id, has_shield, tier)
	equipment_changed.emit(weapon_id, has_shield, tier)

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled

func is_input_enabled() -> bool:
	return input_enabled

func get_hud_state() -> Dictionary:
	_ensure_node_references()
	var h: float = combat.current_health if combat != null else 100.0
	var mh: float = combat.max_health if combat != null else 100.0
	var s: float = combat.current_stamina if combat != null else 100.0
	var ms: float = combat.max_stamina if combat != null else 100.0
	return {
		"health": h,
		"max_health": mh,
		"stamina": s,
		"max_stamina": ms,
		"weapon_id": weapon_id,
		"shield": has_shield,
		"tier": tier
	}
