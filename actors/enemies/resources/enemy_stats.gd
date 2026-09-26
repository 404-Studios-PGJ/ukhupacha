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
## Opcional: ataque a distancia (EnemyAttack con ranged). Se usa cuando el
## Player está entre ranged_min_distance y ranged_max_distance y a la vista.
@export var ranged_attack : EnemyAttack
@export var ranged_min_distance : float = 40.0
@export var ranged_max_distance : float = 140.0
## Espera extra entre disparos.
@export var ranged_cooldown : float = 1.2
## Opcional: disparo especial que reemplaza a uno de cada special_every.
@export var special_ranged_attack : EnemyAttack
@export var special_every : int = 3
@export var attack_cooldown : float = 0.2
## Aturdimiento cuando el Player hace parry.
@export var parry_stagger_time : float = 1.0
## Pausa al recibir daño; cancela un windup o un golpe activo.
@export var hurt_time : float = 0.2

@export_group("En peligro")
## Opcional: ataque que solo usa con poca vida (por ejemplo, un salto).
@export var danger_attack : EnemyAttack
## Fracción de vida desde la que está "en peligro" (0.4 = 40 %).
@export_range(0.0, 1.0) var danger_hp_ratio : float = 0.4
## Espera entre dos usos del ataque de peligro.
@export var danger_cooldown : float = 5.0

@export_group("Invocación")
## Opcional: escena de los esbirros que suelta al perder vida.
@export var summon_scene : PackedScene
## Fracciones de vida en las que suelta una tanda (0.75 = al bajar del 75 %).
@export var summon_hp_ratios : PackedFloat32Array = PackedFloat32Array([0.75, 0.5, 0.25])
@export var summon_count : int = 2
## Máximo de esbirros vivos a la vez.
@export var summon_max_alive : int = 3

@export_group("Defensa")
## Mitad del arco frontal que bloquea el escudo, en grados (0 = sin escudo).
## Solo bloquea fuera de ataque, recuperación y stagger.
@export var front_block_arc_deg : float = 0.0
