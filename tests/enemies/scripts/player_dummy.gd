class_name PlayerDummy extends CharacterBody2D
## Player temporal del laboratorio de enemigos. Usa la misma firma
## receive_hit(hit) -> StringName que tendrá el Player real, pero la defensa
## se elige con teclas en vez de timing (eso lo implementa el Player de Jhon).
##   1 = sin defensa   2 = parry   3 = esquiva   4 = bloqueo
## WASD mover, Shift correr, clic izquierdo atacar (x2 si el enemigo está aturdido).

signal hit_resolved(hit: Dictionary, result: StringName)

enum Defense { NONE, PARRY, DODGE, BLOCK }

const WALK_SPEED : float = 80.0
const RUN_SPEED : float = 140.0
const ATTACK_DAMAGE : float = 10.0
const ATTACK_TIME : float = 0.25
const CRITICAL_MULTIPLIER : float = 2.0
const DEFENSE_NAMES : Array[String] = ["sin defensa", "parry", "esquiva", "bloqueo"]

@export var max_hp : float = 100.0

var hp : float
var defense : Defense = Defense.NONE
var facing : Vector2 = Vector2.RIGHT
var last_result : StringName = &""

var _attack_timer : float = 0.0
var _flash_time : float = 0.0

@onready var attack_pivot : Node2D = $AttackPivot
@onready var attack_area : Area2D = $AttackPivot/AttackArea


func _ready() -> void:
	hp = max_hp


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				defense = Defense.NONE
			KEY_2:
				defense = Defense.PARRY
			KEY_3:
				defense = Defense.DODGE
			KEY_4:
				defense = Defense.BLOCK


func _physics_process(delta: float) -> void:
	_attack_timer -= delta
	_flash_time = maxf(_flash_time - delta, 0.0)
	var direction := Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	var speed := RUN_SPEED if Input.is_action_pressed("correr") else WALK_SPEED
	velocity = direction * speed if _attack_timer <= 0.0 else Vector2.ZERO
	if direction != Vector2.ZERO and _attack_timer <= 0.0:
		facing = direction.normalized()
		attack_pivot.rotation = facing.angle()
	move_and_slide()

	if Input.is_action_just_pressed("cuerpo a cuerpo") and _attack_timer <= 0.0:
		attack()
	queue_redraw()


func attack() -> void:
	_attack_timer = ATTACK_TIME
	for area in attack_area.get_overlapping_areas():
		var enemy := area.get_parent()
		if enemy.has_method("take_hit"):
			var critical : bool = enemy.has_method("is_staggered") and enemy.is_staggered()
			var damage := ATTACK_DAMAGE * (CRITICAL_MULTIPLIER if critical else 1.0)
			enemy.take_hit(damage, self, critical)


func receive_hit(hit: Dictionary) -> StringName:
	var result := &"DAMAGED"
	match defense:
		Defense.PARRY:
			if hit.parryable:
				result = &"PARRIED"
		Defense.DODGE:
			result = &"DODGED"
		Defense.BLOCK:
			if not hit.unblockable:
				result = &"BLOCKED"
	if result == &"DAMAGED":
		hp -= hit.damage
		_flash_time = 0.15
		if hp <= 0.0:
			hp = max_hp
	last_result = result
	hit_resolved.emit(hit, result)
	return result


func is_dead() -> bool:
	return false


func defense_name() -> String:
	return DEFENSE_NAMES[defense]


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	var body := Color("e63946") if _flash_time > 0.0 else Color("52b788")
	draw_rect(Rect2(-6, -22, 12, 22), body)
	draw_circle(Vector2(0, -12) + facing * 5.0, 2.0, Color.WHITE)
	if _attack_timer > 0.0:
		draw_arc(Vector2(0, -12), 20.0, facing.angle() - 0.7, facing.angle() + 0.7, 10, Color("b7e4c7"), 2.0)
