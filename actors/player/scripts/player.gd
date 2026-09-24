class_name Player extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal equipment_changed(weapon_id: StringName, shield: bool, tier: int)
signal player_died()

@export var velocidad_caminar: float = 80.0
@export var velocidad_correr: float = 140.0

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var max_stamina: float = 100.0
@export var current_stamina: float = 100.0

@export var weapon_id: StringName = &"none"
@export var has_shield: bool = false
@export var tier: int = 1

var input_enabled: bool = true
var direccion_mirando: String = "down"
var atacando: bool = false

# Visual controller
@onready var visual: Node2D = $Visual

# Legacy nodes preserved for backward compatibility
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_combate: Sprite2D = $SpriteCombate
@onready var sprite_espada: Sprite2D = $SpriteEspada
@onready var reproductor_animacion: AnimationPlayer = $AnimationPlayer

const DURACION_TAJO: Array[float] = [0.16, 0.065, 0.065, 0.2]

# Variables para el salto (legado)
var saltando: bool = false
var altura_salto: float = 0.0
var velocidad_vertical: float = 0.0
const GRAVEDAD_SALTO: float = 300.0
const FUERZA_SALTO: float = 120.0

func _ready() -> void:
	if visual == null:
		visual = get_node_or_null("Visual")
	if not is_in_group("player"):
		add_to_group("player")
	if visual != null:
		visual.set_equipment(weapon_id, has_shield, tier)
		visual.play("stand", direccion_mirando)

func _physics_process(delta: float) -> void:
	if not input_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		if visual != null and not atacando:
			visual.play("stand", direccion_mirando)
		return
	
	if atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if not saltando:
		var dir_input: Vector2 = Input.get_vector("izquierda", "derecha", "arriba", "abajo")
		var corriendo: bool = Input.is_action_pressed("correr")
		
		# Verificación de entrada de ataque (respetando migración de Kevin)
		var attack_pressed: bool = false
		if InputMap.has_action("atacar") and Input.is_action_just_pressed("atacar"):
			attack_pressed = true
		elif InputMap.has_action("cuerpo a cuerpo") and Input.is_action_just_pressed("cuerpo a cuerpo"):
			attack_pressed = true
		
		if attack_pressed:
			atacar()
			return
		
		var vel_target: float = velocidad_correr if corriendo else velocidad_caminar
		if dir_input != Vector2.ZERO:
			dir_input = dir_input.normalized()
			actualizar_orientacion(dir_input)
			velocity = dir_input * vel_target
			if visual != null:
				visual.play("run" if corriendo else "walk", direccion_mirando)
		else:
			velocity = Vector2.ZERO
			if visual != null:
				visual.play("stand", direccion_mirando)
		
		move_and_slide()
		
		if InputMap.has_action("saltar") and Input.is_action_just_pressed("saltar"):
			iniciar_salto()
	else:
		procesar_salto(delta)

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

func atacar() -> void:
	atacando = true
	if visual != null:
		visual.play("slash1", direccion_mirando)
		await get_tree().create_timer(0.33).timeout
	else:
		# Fallback legacy si visual no estuviese
		if sprite != null: sprite.visible = false
		if sprite_combate != null: sprite_combate.visible = true
		if sprite_espada != null: sprite_espada.visible = true
		await get_tree().create_timer(0.33).timeout
		if sprite != null: sprite.visible = true
		if sprite_combate != null: sprite_combate.visible = false
		if sprite_espada != null: sprite_espada.visible = false
	
	atacando = false
	if visual != null:
		visual.play("stand", direccion_mirando)

func iniciar_salto() -> void:
	saltando = true
	velocidad_vertical = FUERZA_SALTO

func procesar_salto(delta: float) -> void:
	altura_salto += velocidad_vertical * delta
	velocidad_vertical -= GRAVEDAD_SALTO * delta
	
	# Eleva visualmente el nodo Visual sin tocar sprite.position.y
	if visual != null:
		visual.position.y = -altura_salto
	elif sprite != null:
		sprite.position.y = -altura_salto - 10.0
	
	move_and_slide()
	
	if altura_salto <= 0.0:
		altura_salto = 0.0
		if visual != null:
			visual.position.y = 0.0
		elif sprite != null:
			sprite.position.y = -10.0
		saltando = false

# Contrato de integración
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled

func is_input_enabled() -> bool:
	return input_enabled

func equip_weapon(p_weapon_id: StringName) -> void:
	weapon_id = p_weapon_id
	if visual == null:
		visual = get_node_or_null("Visual")
	if visual != null:
		visual.set_equipment(weapon_id, has_shield, tier)
	equipment_changed.emit(weapon_id, has_shield, tier)

func equip_shield() -> void:
	has_shield = true
	if visual == null:
		visual = get_node_or_null("Visual")
	if visual != null:
		visual.set_equipment(weapon_id, has_shield, tier)
	equipment_changed.emit(weapon_id, has_shield, tier)

func unequip_shield() -> void:
	has_shield = false
	if visual == null:
		visual = get_node_or_null("Visual")
	if visual != null:
		visual.set_equipment(weapon_id, has_shield, tier)
	equipment_changed.emit(weapon_id, has_shield, tier)

func get_hud_state() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"stamina": current_stamina,
		"max_stamina": max_stamina,
		"weapon_id": weapon_id,
		"shield": has_shield,
		"tier": tier
	}
