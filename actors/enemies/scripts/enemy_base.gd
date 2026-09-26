class_name EnemyBase extends CharacterBody2D
## IA común de los guardias Helix. Las variantes y la élite solo cambian
## `stats` y el aspecto; no duplican esta máquina de estados.
##
## Contrato con el Player:
## - Cada swing crea un attack_id nuevo y llama a `receive_hit(hit)` como
##   máximo una vez por receptor y attack_id.
## - hit = {attack_id:int, source:Node, damage:float, parryable:bool,
##   unblockable:bool, direction:Vector2}
## - Si receive_hit devuelve "PARRIED", este enemigo se aturde.

signal enemy_died(enemy: EnemyBase)
signal enemy_alerted(enemy: EnemyBase)
## Dejó de buscar al Player y vuelve a su ruta (sirve para apagar la música de combate).
signal enemy_calmed(enemy: EnemyBase)
signal health_changed(current: float, maximum: float)

enum State { IDLE, PATROL, SUSPICIOUS, CHASE, INVESTIGATE, WINDUP, ACTIVE, RECOVERY, HURT, STAGGER, DEAD }

const EYE_OFFSET : Vector2 = Vector2(0, -12)
const TARGET_OFFSET : Vector2 = Vector2(0, -10)
const ARRIVE_DISTANCE : float = 4.0
const STUCK_TIME : float = 1.0
const LOOK_AROUND_STEP : float = 0.5
## Rebote al chocar contra un bloqueo del Player (px/s y frenado).
const BLOCK_KNOCKBACK_SPEED : float = 90.0
const KNOCKBACK_FRICTION : float = 400.0
const SFX_SWING_MISS : AudioStream = preload("res://actors/enemies/sfx/enemy_swing_miss.wav")
const SFX_HIT : AudioStream = preload("res://actors/enemies/sfx/enemy_hit.wav")
const SFX_CLANK : AudioStream = preload("res://actors/enemies/sfx/enemy_clank.wav")
const SFX_GUNSHOT : AudioStream = preload("res://actors/enemies/sfx/enemy_gunshot.wav")
const SFX_SLAM : AudioStream = preload("res://actors/enemies/sfx/enemy_slam.wav")
## Salto: cae a esta distancia antes de una pared; daña hurtboxes del Player.
const LEAP_WALL_MARGIN : float = 16.0
const MASK_PLAYER_HURTBOX : int = 8
## Marca del salto: esquinas que se cierran sobre el área mientras carga.
const MARKER_CORNER : Texture2D = preload("res://actors/enemies/sprites/fx/marker_corner.png")
const MARKER_SCALE : float = 2.0
const MARKER_OPEN : float = 1.5
## Línea de mira durante el windup de un disparo: un punto cada AIM_STEP px.
const AIM_DOT : Texture2D = preload("res://actors/enemies/sprites/fx/aim_dot.png")
const AIM_STEP : float = 10.0
## Tolerancia de orientación para empezar un ataque con giro lento.
const ATTACK_FACING_TOLERANCE : float = deg_to_rad(30.0)
## Un disparo necesita apuntar mucho más fino que un golpe.
const AIM_TOLERANCE : float = deg_to_rad(4.0)

static var _attack_counter : int = 0

@export var stats : EnemyStats
## Puntos de ruta relativos a la posición inicial. Vacío = guardia quieto.
@export var patrol_points : Array[Vector2] = []
@export var patrol_wait : float = 1.0
## Capas que bloquean la visión (mundo y puertas cerradas).
@export_flags_2d_physics var sight_blocking_mask : int = 1
## Segundos antes de borrar el cadáver; negativo lo deja en escena.
@export var corpse_time : float = 1.5
## Distancia del AttackPivot a la boca del arma, para disparos.
@export var muzzle_distance : float = 10.0

@onready var visual : Node2D = $Visual
@onready var hurtbox : Area2D = $Hurtbox
@onready var attack_pivot : Node2D = $AttackPivot
@onready var attack_area : Area2D = $AttackPivot/AttackArea
@onready var attack_shape : CollisionShape2D = $AttackPivot/AttackArea/CollisionShape2D
@onready var detection_area : Area2D = $DetectionArea
@onready var detection_shape : CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var telegraph : EnemyTelegraph = $Telegraph
@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D

var hp : float
var state : State = State.IDLE
var facing : Vector2 = Vector2.DOWN
var target : Node2D
var last_known_position : Vector2
var current_attack : EnemyAttack
var current_attack_id : int = -1

var _state_time : float = 0.0
var _state_duration : float = 0.0
var _lost_time : float = 0.0
var _cooldown : float = 0.0
var _alerted : bool = false
var _spawn_position : Vector2
var _patrol_index : int = 0
var _hit_receivers : Dictionary = {}
var _candidates : Array[Node2D] = []
var _stuck_time : float = 0.0
var _investigate_arrived : bool = false
var _look_timer : float = 0.0
var _desired_facing : Vector2 = Vector2.DOWN
var _attack_index : int = 0
var _knockback : Vector2 = Vector2.ZERO
var _ranged_cooldown : float = 0.0
var _shot_index : int = 0
## Fin de la línea de mira (global), fijado al empezar a apuntar.
var _aim_end : Vector2
var _danger_cooldown : float = 0.0
var _leap_from : Vector2
var _leap_to : Vector2
var _summon_index : int = 0
var _summons : Array[EnemyBase] = []
var _sfx : AudioStreamPlayer2D


func _ready() -> void:
	add_to_group("enemies")
	_sfx = AudioStreamPlayer2D.new()
	_sfx.max_distance = 400.0
	add_child(_sfx)
	if stats == null:
		stats = EnemyStats.new()
	if stats.white_attack == null and stats.red_attack == null:
		stats.white_attack = EnemyAttack.new()
	hp = stats.max_hp
	_spawn_position = global_position

	# Las formas vienen compartidas desde la escena; cada instancia usa la suya.
	var detection_circle := detection_shape.shape.duplicate() as CircleShape2D
	detection_circle.radius = stats.detection_radius
	detection_shape.shape = detection_circle
	var attack_rect := attack_shape.shape.duplicate() as RectangleShape2D
	attack_rect.size = Vector2(stats.attack_range, stats.attack_width)
	attack_shape.shape = attack_rect
	attack_shape.position = Vector2(stats.attack_range / 2.0, 0)
	_set_attack_enabled(false)

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	_enter(State.PATROL if not patrol_points.is_empty() else State.IDLE)
	_desired_facing = facing
	_set_facing(facing)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_state_time -= delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	_ranged_cooldown = maxf(_ranged_cooldown - delta, 0.0)
	_danger_cooldown = maxf(_danger_cooldown - delta, 0.0)
	if stats.turn_speed > 0.0 and not _facing_locked():
		var step := deg_to_rad(stats.turn_speed) * delta
		_set_facing(facing.rotated(clampf(facing.angle_to(_desired_facing), -step, step)))

	match state:
		State.IDLE:
			_process_idle()
		State.PATROL:
			_process_patrol()
		State.SUSPICIOUS:
			_process_suspicious()
		State.CHASE:
			_process_chase(delta)
		State.INVESTIGATE:
			_process_investigate(delta)
		State.WINDUP:
			_process_windup()
		State.ACTIVE:
			_process_active()
		State.RECOVERY:
			_process_recovery(delta)
		State.HURT, State.STAGGER:
			velocity = Vector2.ZERO
			if _state_time <= 0.0:
				_resume_after_interrupt()

	var wanted_speed := velocity.length()
	move_and_slide()
	if wanted_speed > 0.0 and get_real_velocity().length() < wanted_speed * 0.2:
		_stuck_time += delta
	else:
		_stuck_time = 0.0


# --- API pública ------------------------------------------------------------

## Daño recibido del Player. El crítico ya viene multiplicado por quien ataca.
func take_hit(amount: float, source: Node, was_critical: bool = false) -> StringName:
	if state == State.DEAD:
		return &"IGNORED"
	var impact := global_position + EYE_OFFSET
	if _blocks(source):
		EnemyImpactVfx.spawn(self, impact + facing * 7.0, EnemyImpactVfx.Kind.BLOCK, facing)
		if visual.has_method("block"):
			visual.block()
		_notice_attacker(source)
		return &"BLOCKED"

	hp = maxf(hp - amount, 0.0)
	health_changed.emit(hp, stats.max_hp)
	if visual.has_method("flash"):
		visual.flash(was_critical)
	EnemyImpactVfx.spawn(self, impact,
			EnemyImpactVfx.Kind.CRITICAL if was_critical else EnemyImpactVfx.Kind.HIT)
	if hp <= 0.0:
		_die()
		return &"DAMAGED"
	_check_summons()

	# Un stagger no se reinicia: mantiene abierta la ventana de crítico.
	# Un windup con armadura tampoco se cancela, ni un salto en el aire.
	var leaping := state == State.ACTIVE and current_attack != null and current_attack.leap
	var armored := (state == State.WINDUP or leaping) and current_attack != null \
			and current_attack.armored
	if state != State.STAGGER and not armored:
		_cancel_attack()
		_enter(State.HURT, stats.hurt_time)
	_notice_attacker(source)
	return &"DAMAGED"


## Entra en combate directo contra `new_target` (por ejemplo, al ser invocado).
func engage(new_target: Node2D) -> void:
	if state == State.DEAD or not is_instance_valid(new_target):
		return
	target = new_target
	last_known_position = target.global_position
	_lost_time = 0.0
	_alert()
	_enter(State.CHASE)


func stagger(seconds: float) -> void:
	if state == State.DEAD:
		return
	_cancel_attack()
	if state == State.STAGGER:
		_state_time = maxf(_state_time, seconds)
		_state_duration = maxf(_state_duration, _state_time)
	else:
		_enter(State.STAGGER, seconds)


## Avance del estado actual entre 0 y 1; sirve para sincronizar animaciones
## con windup, golpe y recuperación.
func state_progress() -> float:
	if _state_duration <= 0.0:
		return 0.0
	return clampf(1.0 - _state_time / _state_duration, 0.0, 1.0)


func is_staggered() -> bool:
	return state == State.STAGGER


func is_dead() -> bool:
	return state == State.DEAD


## El escudo solo cubre fuera de ataque, recuperación y stagger.
func is_shield_up() -> bool:
	if stats.front_block_arc_deg <= 0.0:
		return false
	return state in [State.IDLE, State.PATROL, State.SUSPICIOUS, State.CHASE, State.INVESTIGATE, State.HURT]


# --- Estados ------------------------------------------------------------------

func _enter(new_state: State, duration: float = 0.0) -> void:
	state = new_state
	_state_time = duration
	_state_duration = duration
	_stuck_time = 0.0
	if new_state == State.INVESTIGATE:
		_investigate_arrived = false


func _process_idle() -> void:
	if _look_for_target():
		return
	if _move_towards(_spawn_position):
		velocity = Vector2.ZERO


func _process_patrol() -> void:
	if _look_for_target():
		return
	if _state_time > 0.0:
		velocity = Vector2.ZERO
		return
	if _move_towards(_spawn_position + patrol_points[_patrol_index]):
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		_state_time = patrol_wait


func _process_suspicious() -> void:
	velocity = Vector2.ZERO
	if not is_instance_valid(target):
		_return_to_route()
		return
	var sees := _can_see(target, stats.detection_radius)
	if sees:
		last_known_position = target.global_position
		_face(target.global_position - global_position)
	if _state_time > 0.0:
		return
	if sees:
		_alert()
		_lost_time = 0.0
		_enter(State.CHASE)
	else:
		_enter(State.INVESTIGATE)


func _process_chase(delta: float) -> void:
	if not is_instance_valid(target) or (target.has_method("is_dead") and target.is_dead()):
		_return_to_route()
		return
	if _can_see(target, stats.lose_distance):
		last_known_position = target.global_position
		_lost_time = 0.0
	else:
		_lost_time += delta
		if _lost_time >= stats.lose_sight_time \
				or target.global_position.distance_to(last_known_position) > stats.lose_distance:
			_enter(State.INVESTIGATE)
			return

	var to_target := target.global_position - global_position
	var off_angle := absf(facing.angle_to(to_target))
	var aimed := off_angle <= ATTACK_FACING_TOLERANCE
	if _lost_time > 0.0:
		_move_towards(last_known_position)
	elif _in_danger():
		# Con poca vida usa su ataque especial en cuanto puede.
		velocity = Vector2.ZERO
		_face(to_target)
		if aimed:
			_start_windup(stats.danger_attack)
	elif to_target.length() <= stats.attack_range:
		velocity = Vector2.ZERO
		_face(to_target)
		if _cooldown <= 0.0 and aimed:
			_start_windup()
	elif _can_shoot(to_target.length()):
		# A distancia y a la vista: se detiene, gira y dispara.
		velocity = Vector2.ZERO
		_face(to_target)
		if off_angle <= AIM_TOLERANCE:
			_start_windup(_next_ranged_attack())
	else:
		_move_towards(target.global_position)


func _next_ranged_attack() -> EnemyAttack:
	_shot_index += 1
	if stats.special_ranged_attack and stats.special_every > 0 \
			and _shot_index % stats.special_every == 0:
		return stats.special_ranged_attack
	return stats.ranged_attack


func _in_danger() -> bool:
	return stats.danger_attack != null and _danger_cooldown <= 0.0 and _cooldown <= 0.0 \
			and hp <= stats.max_hp * stats.danger_hp_ratio


## Altura del arco durante el vuelo de un salto (para el aspecto).
func leap_height() -> float:
	if state != State.ACTIVE or current_attack == null or not current_attack.leap:
		return 0.0
	return sin(PI * state_progress()) * current_attack.leap_height


func _can_shoot(distance: float) -> bool:
	return stats.ranged_attack != null and _cooldown <= 0.0 and _ranged_cooldown <= 0.0 \
			and distance >= stats.ranged_min_distance and distance <= stats.ranged_max_distance


func _process_investigate(delta: float) -> void:
	var seen := _find_visible_target()
	if seen:
		target = seen
		last_known_position = seen.global_position
		if _alerted:
			telegraph.show_alert(stats.alert_time)
			_lost_time = 0.0
			_enter(State.CHASE)
		else:
			telegraph.show_suspicious(stats.suspicious_time)
			_enter(State.SUSPICIOUS, stats.suspicious_time)
		return

	if not _investigate_arrived:
		if _move_towards(last_known_position):
			_investigate_arrived = true
			_state_time = stats.investigate_time
			_look_timer = LOOK_AROUND_STEP
		return

	velocity = Vector2.ZERO
	_look_timer -= delta
	if _look_timer <= 0.0:
		_look_timer = LOOK_AROUND_STEP
		_face(facing.orthogonal())
	if _state_time <= 0.0:
		_return_to_route()


func _process_windup() -> void:
	velocity = Vector2.ZERO
	if current_attack.leap:
		queue_redraw()
	if _state_time <= 0.0:
		_attack_counter += 1
		current_attack_id = _attack_counter
		_hit_receivers.clear()
		telegraph.clear()
		if current_attack.ranged:
			_fire()
		elif not current_attack.leap:
			_set_attack_enabled(true)
		_enter(State.ACTIVE, current_attack.active)
		queue_redraw()


func _process_active() -> void:
	velocity = Vector2.ZERO
	if current_attack.leap:
		global_position = _leap_from.lerp(_leap_to, state_progress())
		queue_redraw()
		if _state_time <= 0.0:
			_land()
	elif not current_attack.ranged:
		_apply_hits()
	if state == State.ACTIVE and _state_time <= 0.0:
		if _hit_receivers.is_empty() and not current_attack.ranged and not current_attack.leap:
			_play_sfx(SFX_SWING_MISS)
		_set_attack_enabled(false)
		_enter(State.RECOVERY, current_attack.recovery)


func _process_recovery(delta: float) -> void:
	velocity = _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_FRICTION * delta)
	if _state_time <= 0.0:
		if current_attack.ranged:
			_ranged_cooldown = stats.ranged_cooldown
		current_attack = null
		_cooldown = stats.attack_cooldown
		_lost_time = 0.0
		_enter(State.CHASE)


func _resume_after_interrupt() -> void:
	if is_instance_valid(target) and _alerted:
		_lost_time = 0.0
		_enter(State.CHASE)
	else:
		_return_to_route()


func _return_to_route() -> void:
	target = null
	if _alerted:
		_alerted = false
		enemy_calmed.emit(self)
	_enter(State.PATROL if not patrol_points.is_empty() else State.IDLE)


# --- Combate ------------------------------------------------------------------

## Sin ataque indicado elige el cuerpo a cuerpo (blanco o rojo según el patrón).
func _start_windup(attack: EnemyAttack = null) -> void:
	current_attack = attack
	if current_attack == null:
		_attack_index += 1
		current_attack = stats.white_attack
		if stats.red_attack and (current_attack == null \
				or (stats.red_attack_every > 0 and _attack_index % stats.red_attack_every == 0)):
			current_attack = stats.red_attack
	# La orientación queda fija durante el windup para que esquivar funcione.
	_face(target.global_position - global_position)
	telegraph.show_attack(current_attack.kind)
	_enter(State.WINDUP, current_attack.windup)
	if current_attack.ranged:
		_aim_end = _aim_line_end()
		queue_redraw()
	if current_attack.leap:
		_leap_from = global_position
		_leap_to = _leap_landing(target.global_position)
		queue_redraw()


## Donde estaba el Player, sin pasar del alcance ni atravesar paredes.
func _leap_landing(wanted: Vector2) -> Vector2:
	var to_wanted := wanted - global_position
	var direction := to_wanted.normalized()
	var landing := global_position + direction * minf(to_wanted.length(), current_attack.leap_max_distance)
	var query := PhysicsRayQueryParameters2D.create(global_position, landing, sight_blocking_mask, [get_rid()])
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result:
		var free := maxf(global_position.distance_to(result.position) - LEAP_WALL_MARGIN, 0.0)
		landing = global_position + direction * free
	return landing


## Aterrizaje: daño en círculo a cada Player dentro, una sola vez.
func _land() -> void:
	global_position = _leap_to
	_danger_cooldown = stats.danger_cooldown
	EnemyImpactVfx.spawn(self, _leap_to, EnemyImpactVfx.Kind.SLAM)
	_play_sfx(SFX_SLAM)
	var circle := CircleShape2D.new()
	circle.radius = current_attack.impact_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, _leap_to)
	query.collision_mask = MASK_PLAYER_HURTBOX
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for found in get_world_2d().direct_space_state.intersect_shape(query):
		var receiver := _find_hit_receiver(found.collider)
		if receiver == null or _hit_receivers.has(receiver.get_instance_id()):
			continue
		_hit_receivers[receiver.get_instance_id()] = true
		var hit := {
			"attack_id": current_attack_id,
			"source": self,
			"damage": current_attack.damage,
			"parryable": current_attack.is_parryable(),
			"unblockable": current_attack.is_unblockable(),
			"direction": (receiver.global_position - _leap_to).normalized(),
		}
		if str(receiver.receive_hit(hit)) == "DAMAGED":
			EnemyImpactVfx.spawn(self, receiver.global_position + Vector2(0, -12), EnemyImpactVfx.Kind.HIT)


func _muzzle_position() -> Vector2:
	return attack_pivot.global_position + facing * muzzle_distance


## La mira llega hasta la primera pared o hasta el alcance del proyectil.
func _aim_line_end() -> Vector2:
	var from := _muzzle_position()
	var to := from + facing * current_attack.projectile_range
	var query := PhysicsRayQueryParameters2D.create(from, to, sight_blocking_mask, [get_rid()])
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	return result.position if result else to


func _fire() -> void:
	var muzzle := _muzzle_position()
	var hit := {
		"attack_id": current_attack_id,
		"source": self,
		"damage": current_attack.damage,
		"parryable": current_attack.is_parryable(),
		"unblockable": current_attack.is_unblockable(),
		"direction": facing,
	}
	var projectile := EnemyProjectile.fire(self, muzzle, facing, current_attack, hit)
	projectile.resolved.connect(_on_projectile_resolved)
	EnemyImpactVfx.spawn(self, muzzle, EnemyImpactVfx.Kind.MUZZLE, facing)
	_play_sfx(SFX_GUNSHOT)


func _on_projectile_resolved(result: StringName, at: Vector2) -> void:
	match result:
		&"DAMAGED":
			EnemyImpactVfx.spawn(self, at, EnemyImpactVfx.Kind.HIT)
			_play_sfx(SFX_HIT)
		&"WALL":
			EnemyImpactVfx.spawn(self, at, EnemyImpactVfx.Kind.BLOCK, -facing)


func _draw() -> void:
	if current_attack != null and current_attack.leap \
			and (state == State.WINDUP or state == State.ACTIVE):
		_draw_landing_marker()
		return
	if state != State.WINDUP or current_attack == null or not current_attack.ranged:
		return
	var from := to_local(_muzzle_position())
	var to := to_local(_aim_end)
	var step := (to - from).normalized()
	var half := AIM_DOT.get_size() / 2.0
	var d := AIM_STEP
	while d < from.distance_to(to):
		draw_texture(AIM_DOT, from + step * d - half)
		d += AIM_STEP


## Marca roja donde caerá el salto: cuatro esquinas que empiezan abiertas y
## se cierran hasta enmarcar el área de daño justo al aterrizar.
func _draw_landing_marker() -> void:
	var center := to_local(_leap_to)
	var charge := 0.5 * state_progress() if state == State.WINDUP else 0.5 + 0.5 * state_progress()
	var reach := current_attack.impact_radius * lerpf(MARKER_OPEN, 1.0, charge)
	var size := MARKER_CORNER.get_size() * MARKER_SCALE
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		# La esquina del sprite es la superior izquierda: se voltea para las demás.
		draw_set_transform(center + corner * reach, 0.0, -corner)
		draw_texture_rect(MARKER_CORNER, Rect2(Vector2.ZERO, size), false)
	draw_set_transform(Vector2.ZERO)


func _apply_hits() -> void:
	for area in attack_area.get_overlapping_areas():
		var receiver := _find_hit_receiver(area)
		if receiver == null or _hit_receivers.has(receiver.get_instance_id()):
			continue
		_hit_receivers[receiver.get_instance_id()] = true
		var hit := {
			"attack_id": current_attack_id,
			"source": self,
			"damage": current_attack.damage,
			"parryable": current_attack.is_parryable(),
			"unblockable": current_attack.is_unblockable(),
			"direction": facing,
		}
		var result : Variant = receiver.receive_hit(hit)
		var contact := attack_pivot.global_position + facing * stats.attack_range * 0.6
		if receiver is Node2D:
			contact = (receiver as Node2D).global_position + Vector2(0, -12)
		match str(result):
			"PARRIED":
				EnemyImpactVfx.spawn(self, contact, EnemyImpactVfx.Kind.PARRY)
				_play_sfx(SFX_CLANK)
				stagger(stats.parry_stagger_time)
				return
			"BLOCKED":
				# El arma rebota: chispas y el enemigo retrocede en su recuperación.
				EnemyImpactVfx.spawn(self, contact, EnemyImpactVfx.Kind.BLOCK, -facing)
				_play_sfx(SFX_CLANK)
				_knockback = -facing * BLOCK_KNOCKBACK_SPEED
			"DODGED":
				_play_sfx(SFX_SWING_MISS)
			"DAMAGED":
				EnemyImpactVfx.spawn(self, contact, EnemyImpactVfx.Kind.HIT)
				_play_sfx(SFX_HIT)


func _find_hit_receiver(area: Area2D) -> Node:
	var node : Node = area
	for i in 3:
		if node == null:
			return null
		if node != self and node.has_method("receive_hit"):
			return node
		node = node.get_parent()
	return null


func _play_sfx(stream: AudioStream) -> void:
	_sfx.stream = stream
	_sfx.play()


func _cancel_attack() -> void:
	_set_attack_enabled(false)
	telegraph.clear()
	current_attack = null
	_knockback = Vector2.ZERO
	queue_redraw()


func _set_attack_enabled(enabled: bool) -> void:
	# Diferido: take_hit/stagger pueden llegar desde un callback de física.
	attack_area.set_deferred("monitoring", enabled)
	attack_shape.set_deferred("disabled", not enabled)


func _blocks(source: Node) -> bool:
	if not is_shield_up() or not source is Node2D:
		return false
	var to_source := (source as Node2D).global_position - global_position
	return absf(facing.angle_to(to_source)) <= deg_to_rad(stats.front_block_arc_deg)


func _notice_attacker(source: Node) -> void:
	if source is Node2D and source.has_method("receive_hit"):
		target = source
		last_known_position = target.global_position
		_lost_time = 0.0
		_face(target.global_position - global_position)
		_alert()


## Suelta una tanda de esbirros por cada umbral de vida cruzado.
func _check_summons() -> void:
	if stats.summon_scene == null:
		return
	while _summon_index < stats.summon_hp_ratios.size() \
			and hp <= stats.max_hp * stats.summon_hp_ratios[_summon_index]:
		_summon_index += 1
		_summon_wave()


func _summon_wave() -> void:
	# Los esbirros muertos ya pueden estar liberados: se comprueba antes de usarlos.
	var alive : Array[EnemyBase] = []
	for summon in _summons:
		if is_instance_valid(summon) and not summon.is_dead():
			alive.append(summon)
	_summons = alive
	var parent := get_parent()
	var amount := mini(stats.summon_count, stats.summon_max_alive - _summons.size())
	for i in amount:
		var minion := stats.summon_scene.instantiate() as EnemyBase
		var at := _summon_position(i)
		minion.position = (parent as Node2D).to_local(at) if parent is Node2D else at
		# Diferido: take_hit puede llegar desde un callback de física.
		parent.add_child.call_deferred(minion)
		if is_instance_valid(target):
			minion.engage.call_deferred(target)
		EnemyImpactVfx.spawn(self, at, EnemyImpactVfx.Kind.DEATH)
		_summons.append(minion)


## A los lados del jefe, sin atravesar paredes.
func _summon_position(index: int) -> Vector2:
	var side := -1.0 if index % 2 == 0 else 1.0
	var wanted := global_position + Vector2(side * stats.attack_range, 12.0 + 8.0 * index)
	var query := PhysicsRayQueryParameters2D.create(global_position, wanted, sight_blocking_mask, [get_rid()])
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result:
		return result.position - (wanted - global_position).normalized() * LEAP_WALL_MARGIN
	return wanted


func _alert() -> void:
	if _alerted:
		return
	_alerted = true
	telegraph.show_alert(stats.alert_time)
	enemy_alerted.emit(self)


func _die() -> void:
	_cancel_attack()
	state = State.DEAD
	velocity = Vector2.ZERO
	target = null
	# Libera el paso y apaga toda interacción.
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	hurtbox.set_deferred("monitorable", false)
	detection_area.set_deferred("monitoring", false)
	EnemyImpactVfx.spawn(self, global_position + Vector2(0, -8), EnemyImpactVfx.Kind.DEATH)
	enemy_died.emit(self)
	if corpse_time >= 0.0:
		get_tree().create_timer(corpse_time).timeout.connect(queue_free)


# --- Percepción y movimiento ----------------------------------------------------

func _on_detection_body_entered(body: Node2D) -> void:
	if body != self and body.has_method("receive_hit") and not _candidates.has(body):
		_candidates.append(body)


func _on_detection_body_exited(body: Node2D) -> void:
	_candidates.erase(body)


func _look_for_target() -> bool:
	var seen := _find_visible_target()
	if seen == null:
		return false
	target = seen
	last_known_position = seen.global_position
	_face(seen.global_position - global_position)
	telegraph.show_suspicious(stats.suspicious_time)
	_enter(State.SUSPICIOUS, stats.suspicious_time)
	return true


func _find_visible_target() -> Node2D:
	for candidate in _candidates:
		if is_instance_valid(candidate) and _can_see(candidate, stats.detection_radius):
			return candidate
	return null


func _can_see(node: Node2D, max_distance: float) -> bool:
	if global_position.distance_to(node.global_position) > max_distance:
		return false
	var exclude : Array[RID] = [get_rid()]
	if node is CollisionObject2D:
		exclude.append((node as CollisionObject2D).get_rid())
	var query := PhysicsRayQueryParameters2D.create(
			global_position + EYE_OFFSET, node.global_position + TARGET_OFFSET,
			sight_blocking_mask, exclude)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Devuelve true al llegar o si quedó atascado contra una pared.
func _move_towards(destination: Vector2) -> bool:
	var to_destination := destination - global_position
	if to_destination.length() <= ARRIVE_DISTANCE or _stuck_time >= STUCK_TIME:
		velocity = Vector2.ZERO
		_stuck_time = 0.0
		return true
	var direction := to_destination.normalized()
	if _navigation_available():
		nav_agent.target_position = destination
		var next := nav_agent.get_next_path_position()
		if next.distance_to(global_position) > 0.5:
			direction = (next - global_position).normalized()
	velocity = direction * stats.move_speed
	_face(direction)
	return false


func _navigation_available() -> bool:
	return not NavigationServer2D.map_get_regions(nav_agent.get_navigation_map()).is_empty()


## Pide mirar hacia una dirección; con turn_speed > 0 el giro es gradual.
func _face(direction: Vector2) -> void:
	if direction == Vector2.ZERO or _facing_locked():
		return
	_desired_facing = direction.normalized()
	if stats.turn_speed <= 0.0:
		_set_facing(_desired_facing)


## Durante windup y golpe la orientación no cambia; aturdido tampoco gira.
func _facing_locked() -> bool:
	return state in [State.WINDUP, State.ACTIVE, State.STAGGER, State.DEAD]


func _set_facing(direction: Vector2) -> void:
	facing = direction.normalized()
	attack_pivot.rotation = facing.angle()
