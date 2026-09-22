class_name Player extends CharacterBody2D

var velocidad_caminar : float = 80.0
var velocidad_correr : float = 140.0

@onready var sprite : Sprite2D = $Sprite2D
@onready var reproductor_animacion : AnimationPlayer = $AnimationPlayer

var direccion_mirando : String = "abajo"

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	# Dirección del jugador
	var direccion : Vector2 = Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	
	# Determinar si está corriendo
	var corriendo : bool = Input.is_action_pressed("correr")
	
	# Determinar la velocidad actual
	var velocidad_actual : float = velocidad_correr if corriendo else velocidad_caminar
	
	velocity = direccion * velocidad_actual
	move_and_slide()
	
	actualizar_animacion(direccion, corriendo)

func actualizar_animacion(direccion: Vector2, corriendo: bool) -> void:
	if direccion != Vector2.ZERO:
		# Determinar la dirección a la que mira el personaje
		if abs(direccion.x) > abs(direccion.y):
			direccion_mirando = "lado"
			sprite.flip_h = direccion.x < 0
		else:
			sprite.flip_h = false
			direccion_mirando = "abajo" if direccion.y > 0 else "arriba"
		
		# Seleccionar estado (caminar o correr)
		var estado : String = "correr" if corriendo else "caminar"
		reproductor_animacion.play(estado + "_" + direccion_mirando)
		
	else:
		# Reproducir la animación de estar quieto según la última dirección
		reproductor_animacion.play("quieto_" + direccion_mirando)
