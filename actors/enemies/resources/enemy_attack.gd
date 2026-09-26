class_name EnemyAttack extends Resource
## Un ataque de enemigo: tipo de aviso, daño y ventanas de tiempo.
## Blanco = se puede hacer parry; rojo = solo se esquiva.

enum Kind { WHITE, RED }

@export var kind : Kind = Kind.WHITE
@export var damage : float = 10.0
## Tiempo de aviso antes del impacto; la orientación queda fija aquí.
@export var windup : float = 0.45
## Ventana en la que el AttackArea está encendida.
@export var active : float = 0.10
@export var recovery : float = 0.60
## Con armadura, recibir daño durante el windup no cancela el ataque.
@export var armored : bool = false

@export_group("A distancia")
## Dispara un proyectil en vez de encender el AttackArea.
@export var ranged : bool = false
@export var projectile_speed : float = 200.0
## Distancia máxima que recorre el proyectil antes de desaparecer.
@export var projectile_range : float = 220.0
## Tamaño del proyectil (desde 3 se ve como bola de energía) y tinte de su
## sprite (blanco = sin teñir).
@export var projectile_radius : float = 2.0
@export var projectile_color : Color = Color.WHITE

@export_group("Salto")
## Salta hasta donde estaba el Player al empezar el windup y daña al caer.
## El vuelo dura "active"; el daño es en un círculo al aterrizar.
@export var leap : bool = false
@export var leap_max_distance : float = 170.0
@export var impact_radius : float = 36.0
## Altura máxima del arco del salto (solo visual).
@export var leap_height : float = 40.0


func is_parryable() -> bool:
	return kind == Kind.WHITE


func is_unblockable() -> bool:
	return kind == Kind.RED
