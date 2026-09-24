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


func is_parryable() -> bool:
	return kind == Kind.WHITE


func is_unblockable() -> bool:
	return kind == Kind.RED
