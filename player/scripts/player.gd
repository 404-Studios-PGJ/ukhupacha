class_name Player extends CharacterBody2D

var velocidad_caminar : float = 80.0
var velocidad_correr : float = 140.0

@onready var sprite : Sprite2D = $Sprite2D
@onready var sprite_combate : Sprite2D = $SpriteCombate
@onready var sprite_espada : Sprite2D = $SpriteEspada
@onready var reproductor_animacion : AnimationPlayer = $AnimationPlayer

var direccion_mirando : String = "abajo"
var atacando : bool = false

const DURACION_TAJO : Array[float] = [0.16, 0.065, 0.065, 0.2]

# Variables para el salto
var saltando : bool = false
var altura_salto : float = 0.0
var velocidad_vertical : float = 0.0
const GRAVEDAD_SALTO : float = 300.0
const FUERZA_SALTO : float = 120.0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if not saltando:
		var direccion : Vector2 = Input.get_vector("izquierda", "derecha", "arriba", "abajo")
		var corriendo : bool = Input.is_action_pressed("correr")

		if Input.is_action_just_pressed("cuerpo a cuerpo"):
			atacar()
			return
		
		var velocidad_actual : float = velocidad_caminar
		if corriendo:
			velocidad_actual = velocidad_correr
		
		velocity = direccion * velocidad_actual
		move_and_slide()
		
		if Input.is_action_just_pressed("saltar"):
			iniciar_salto()
		else:
			actualizar_animacion(direccion, corriendo)
	else:
		procesar_salto(delta)

func atacar() -> void:
	atacando = true
	sprite.visible = false
	sprite_combate.visible = true
	sprite_espada.visible = true
	sprite_combate.flip_h = sprite.flip_h
	sprite_espada.flip_h = sprite.flip_h

	var primera_columna : int = 0
	match direccion_mirando:
		"arriba":
			primera_columna = 8
		"lado":
			primera_columna = 16

	for indice in 4:
		sprite_combate.frame = primera_columna + indice
		sprite_espada.frame = primera_columna + indice
		await get_tree().create_timer(DURACION_TAJO[indice]).timeout

	sprite.visible = true
	sprite_combate.visible = false
	sprite_espada.visible = false
	atacando = false
	actualizar_animacion(Vector2.ZERO, false)

func iniciar_salto() -> void:
	saltando = true
	velocidad_vertical = FUERZA_SALTO
	reproductor_animacion.play("salto_" + direccion_mirando)

func procesar_salto(delta: float) -> void:
	altura_salto += velocidad_vertical * delta
	velocidad_vertical -= GRAVEDAD_SALTO * delta
	
	# Eleva visualmente el sprite mientras salta
	sprite.position.y = -altura_salto
	
	move_and_slide()
	
	if altura_salto <= 0.0:
		altura_salto = 0.0
		sprite.position.y = 0.0
		saltando = false

func actualizar_animacion(direccion: Vector2, corriendo: bool) -> void:
	if direccion != Vector2.ZERO:
		if abs(direccion.x) > abs(direccion.y):
			direccion_mirando = "lado"
			sprite.flip_h = direccion.x < 0
		else:
			sprite.flip_h = false
			if direccion.y > 0:
				direccion_mirando = "abajo"
			else:
				direccion_mirando = "arriba"
		
		var estado : String = "caminar"
		if corriendo:
			estado = "correr"
			
		reproductor_animacion.play(estado + "_" + direccion_mirando)
	else:
		reproductor_animacion.play("quieto_" + direccion_mirando)
