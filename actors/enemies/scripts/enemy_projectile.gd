class_name EnemyProjectile extends Area2D
## Proyectil de un ataque a distancia. Lleva el mismo paquete de golpe que los
## ataques cuerpo a cuerpo y llama a receive_hit() una sola vez por receptor.
## Se detiene en paredes y puertas cerradas (capa 1); si el Player lo
## esquiva (DODGED), sigue de largo.

## Resultado de receive_hit, para que quien disparó reaccione.
signal resolved(result: StringName, at: Vector2)

const LAYER_ENEMY_ATTACK : int = 64   # capa 7
const MASK_WORLD_AND_PLAYER_HURTBOX : int = 1 | 8
## Sprites (Kenney 1-Bit Pack, CC0): bala y, desde ENERGY_RADIUS, bola de energía.
const BULLET : Texture2D = preload("res://actors/enemies/sprites/fx/bullet.png")
const ENERGY_BALL : Texture2D = preload("res://actors/enemies/sprites/fx/energy_ball.png")
const ENERGY_RADIUS : float = 3.0

var hit : Dictionary
var direction : Vector2 = Vector2.RIGHT
var speed : float = 200.0
var max_distance : float = 220.0
var radius : float = 2.0
## Tinte del sprite (blanco = color original del sprite).
var color : Color = Color.WHITE

var _travelled : float = 0.0
var _hit_receivers : Dictionary = {}


static func fire(host: Node2D, from: Vector2, towards: Vector2, attack: EnemyAttack,
		hit_data: Dictionary) -> EnemyProjectile:
	var projectile := EnemyProjectile.new()
	projectile.hit = hit_data
	projectile.direction = towards.normalized()
	projectile.speed = attack.projectile_speed
	projectile.max_distance = attack.projectile_range
	projectile.radius = attack.projectile_radius
	projectile.color = attack.projectile_color
	var parent := host.get_parent()
	projectile.position = (parent as Node2D).to_local(from) if parent is Node2D else from
	parent.add_child.call_deferred(projectile)
	return projectile


func _ready() -> void:
	collision_layer = LAYER_ENEMY_ATTACK
	collision_mask = MASK_WORLD_AND_PLAYER_HURTBOX
	monitorable = false
	z_index = 15
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	position += step
	_travelled += step.length()
	if _travelled >= max_distance:
		queue_free()


func _draw() -> void:
	var sprite := ENERGY_BALL if radius >= ENERGY_RADIUS else BULLET
	draw_texture(sprite, -sprite.get_size() / 2.0, color)


func _on_body_entered(_body: Node2D) -> void:
	# Pared o puerta cerrada.
	resolved.emit(&"WALL", global_position)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	var receiver := _find_receiver(area)
	if receiver == null or receiver == hit.get("source") \
			or _hit_receivers.has(receiver.get_instance_id()):
		return
	_hit_receivers[receiver.get_instance_id()] = true
	var result := StringName(str(receiver.receive_hit(hit)))
	resolved.emit(result, global_position)
	if result != &"DODGED":
		queue_free()


func _find_receiver(area: Area2D) -> Node:
	var node : Node = area
	for i in 3:
		if node == null:
			return null
		if node.has_method("receive_hit"):
			return node
		node = node.get_parent()
	return null
