class_name EnemyStats extends Resource
## Perfil de un enemigo. Las variantes y la élite reutilizan EnemyBase
## cambiando solo este Resource.

@export_group("Vida y movimiento")
@export var max_hp : float = 40.0
@export var move_speed : float = 45.0

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
@export var white_attack : EnemyAttack
## Opcional: si existe, se elige con red_attack_chance.
@export var red_attack : EnemyAttack
@export_range(0.0, 1.0) var red_attack_chance : float = 0.0
@export var attack_cooldown : float = 0.2
## Aturdimiento cuando el Player hace parry.
@export var parry_stagger_time : float = 1.0
## Pausa al recibir daño; cancela un windup o un golpe activo.
@export var hurt_time : float = 0.2
