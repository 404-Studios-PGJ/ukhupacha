class_name EnemyStats extends Resource
## Perfil de un enemigo. Las variantes y la élite reutilizan EnemyBase
## cambiando solo este Resource.

@export_group("Vida y movimiento")
@export var max_hp : float = 40.0
@export var move_speed : float = 45.0
## Grados por segundo al girar; 0 = gira al instante.
## Un giro lento permite rodear al enemigo y atacarle por la espalda.
@export var turn_speed : float = 0.0

@export_group("Percepción")
## Radio del DetectionArea y distancia máxima para ver al Player en reposo.
@export var detection_radius : float = 120.0
## Si el Player se aleja más que esto del último punto visible, se pierde.
@export var lose_distance : float = 160.0
## Segundos sin línea de visión antes de perder al Player.
@export var lose_sight_time : float = 1.0
@export var suspicious_time : float = 0.5
@export var alert_time : float = 0.5
## Segundos mirando alrededor en la última posición conocida.
@export var investigate_time : float = 1.5

@export_group("Combate")
## Distancia a la que empieza el windup y largo del AttackArea.
@export var attack_range : float = 22.0
## Ancho del AttackArea (perpendicular al golpe).
@export var attack_width : float = 16.0
@export var white_attack : EnemyAttack
## Opcional. Sin white_attack, todos los ataques son rojos.
@export var red_attack : EnemyAttack
## Patrón fijo para que sea aprendible: cada N ataques, uno es rojo (0 = nunca).
@export var red_attack_every : int = 0
@export var attack_cooldown : float = 0.2
## Aturdimiento cuando el Player hace parry.
@export var parry_stagger_time : float = 1.0
## Pausa al recibir daño; cancela un windup o un golpe activo.
@export var hurt_time : float = 0.2

@export_group("Defensa")
## Mitad del arco frontal que bloquea el escudo, en grados (0 = sin escudo).
## Solo bloquea fuera de ataque, recuperación y stagger.
@export var front_block_arc_deg : float = 0.0
