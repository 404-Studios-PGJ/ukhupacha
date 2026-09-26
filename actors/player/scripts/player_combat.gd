class_name PlayerCombat
extends Node

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal combat_state_changed(new_state: String)
signal player_died()

enum State {
	IDLE,
	MOVE,
	ATTACK_1,
	ATTACK_2,
	DODGE,
	GUARD,
	PARRY,
	PARRY_RECOVERY,
	HURT,
	DEAD,
	INTERACT
}

var current_state: State = State.IDLE

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var max_stamina: float = 100.0
@export var current_stamina: float = 100.0

@export var stamina_regen_rate: float = 30.0 # 30 / s
@export var stamina_regen_delay: float = 0.5  # 0.5 s tras consumo
var _stamina_timer: float = 0.0

# Reglas de esquiva
const DODGE_DURATION: float = 0.20
const DODGE_SPEED: float = 220.0 # ~44 px en 0.20 s
const DODGE_INVULN_START: float = 0.08
const DODGE_INVULN_END: float = 0.18
const DODGE_STAMINA_COST: float = 25.0
var _dodge_timer: float = 0.0
var dodge_velocity: Vector2 = Vector2.ZERO

# Reglas de parry y guardia
const PARRY_STAMINA_COST: float = 10.0
const GUARD_STAMINA_COST_PER_HIT: float = 10.0
const PARRY_RECOVERY_DURATION: float = 0.30
var _parry_timer: float = 0.0
var _parry_recovery_timer: float = 0.0
var _current_parry_window: float = 0.18

# Depuración de parry
var debug_force_parry: Variant = null # null = RNG normal, true = fuerza 95% éxito, false = fuerza 5% fallo
var parry_success_chance: float = 0.95

# Marcadores de crítico garantizado tras parry perfecto (fuente -> tiempo restante)
var staggered_critical_enemies: Dictionary = {}

# Ataque y combos
var current_attack_id: int = 1
var _combo_buffered: bool = false
var _attack_timer: float = 0.0
var _attack_duration: float = 0.33
var _impact_start: float = 0.08
var _impact_end: float = 0.25
var _combo_window_start: float = 0.15
var _combo_window_end: float = 0.30
var damaged_targets_in_current_swing: Array[Node] = []

# Nodos asignados por Player
var player: CharacterBody2D
var visual: PlayerVisual
var hurtbox: Area2D
var attack_pivot: Node2D
var attack_area: Area2D
var attack_shape: CollisionShape2D

func setup(p_player: CharacterBody2D, p_visual: PlayerVisual, p_hurtbox: Area2D, p_pivot: Node2D, p_area: Area2D, p_shape: CollisionShape2D) -> void:
	player = p_player
	visual = p_visual
	hurtbox = p_hurtbox
	attack_pivot = p_pivot
	attack_area = p_area
	attack_shape = p_shape

	if attack_area != null:
		attack_area.monitoring = false
		attack_area.monitorable = false
		if not attack_area.area_entered.is_connected(_on_attack_area_entered):
			attack_area.area_entered.connect(_on_attack_area_entered)

func process_combat(delta: float) -> void:
	_update_stamina(delta)
	_update_staggered_enemies(delta)

	match current_state:
		State.DODGE:
			_process_dodge(delta)
		State.PARRY:
			_process_parry(delta)
		State.PARRY_RECOVERY:
			_process_parry_recovery(delta)
		State.ATTACK_1, State.ATTACK_2:
			_process_attack(delta)
		State.HURT:
			pass
		State.DEAD:
			pass
		_:
			pass

func _update_stamina(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if _stamina_timer < stamina_regen_delay:
		_stamina_timer += delta
	else:
		if current_stamina < max_stamina:
			current_stamina = min(max_stamina, current_stamina + stamina_regen_rate * delta)
			stamina_changed.emit(current_stamina, max_stamina)

func consume_stamina(amount: float) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		_stamina_timer = 0.0
		stamina_changed.emit(current_stamina, max_stamina)
		return true
	return false

func _update_staggered_enemies(delta: float) -> void:
	var to_remove = []
	for enemy in staggered_critical_enemies.keys():
		staggered_critical_enemies[enemy] -= delta
		if staggered_critical_enemies[enemy] <= 0.0 or not is_instance_valid(enemy):
			to_remove.append(enemy)
	for enemy in to_remove:
		staggered_critical_enemies.erase(enemy)

# ==================== ESQUIVA ====================

func can_dodge() -> bool:
	if current_state in [State.DEAD, State.HURT, State.DODGE, State.PARRY]:
		return false
	return current_stamina >= DODGE_STAMINA_COST

func start_dodge(dir_vector: Vector2, facing_dir: String) -> void:
	if not consume_stamina(DODGE_STAMINA_COST):
		return

	current_state = State.DODGE
	combat_state_changed.emit("DODGE")
	_dodge_timer = 0.0

	var dodge_dir = dir_vector.normalized()
	if dodge_dir == Vector2.ZERO:
		match facing_dir:
			"down": dodge_dir = Vector2.DOWN
			"up": dodge_dir = Vector2.UP
			"left": dodge_dir = Vector2.LEFT
			"right": dodge_dir = Vector2.RIGHT

	dodge_velocity = dodge_dir * DODGE_SPEED
	if visual != null:
		visual.play("dodge", facing_dir)

func _process_dodge(delta: float) -> void:
	_dodge_timer += delta
	if player != null:
		player.velocity = dodge_velocity
		player.move_and_slide()

	if _dodge_timer >= DODGE_DURATION:
		current_state = State.IDLE
		combat_state_changed.emit("IDLE")

func is_dodge_invulnerable() -> bool:
	return current_state == State.DODGE and _dodge_timer >= DODGE_INVULN_START and _dodge_timer <= DODGE_INVULN_END

# ==================== PARRY Y GUARDIA ====================

func get_parry_window() -> float:
	if player == null:
		return 0.18
	if player.has_shield:
		return 0.22
	elif player.weapon_id == &"axe":
		return 0.14
	elif player.weapon_id == &"sword":
		return 0.18
	return 0.0 # T0 puños no tiene parry

func can_parry() -> bool:
	if current_state in [State.DEAD, State.HURT, State.DODGE, State.PARRY, State.PARRY_RECOVERY]:
		return false
	if player != null and player.weapon_id == &"none" and not player.has_shield:
		return false # T0 sin armas no parry
	return current_stamina >= PARRY_STAMINA_COST

func start_parry(facing_dir: String) -> void:
	var win = get_parry_window()
	if win <= 0.0 or not consume_stamina(PARRY_STAMINA_COST):
		return

	current_state = State.PARRY
	combat_state_changed.emit("PARRY")
	_current_parry_window = win
	_parry_timer = 0.0

	if visual != null:
		visual.play("parry", facing_dir)

func _process_parry(delta: float) -> void:
	_parry_timer += delta
	if _parry_timer >= _current_parry_window:
		# Ventana expirada sin impacto: entrar a recuperación
		current_state = State.PARRY_RECOVERY
		combat_state_changed.emit("PARRY_RECOVERY")
		_parry_recovery_timer = 0.0

func _process_parry_recovery(delta: float) -> void:
	_parry_recovery_timer += delta
	if _parry_recovery_timer >= PARRY_RECOVERY_DURATION:
		current_state = State.IDLE
		combat_state_changed.emit("IDLE")

func start_guard(facing_dir: String) -> void:
	if current_state in [State.DEAD, State.HURT, State.DODGE, State.PARRY, State.PARRY_RECOVERY, State.ATTACK_1, State.ATTACK_2]:
		return
	if player != null and player.weapon_id == &"none" and not player.has_shield:
		return # T0 puños no tiene guardia

	current_state = State.GUARD
	combat_state_changed.emit("GUARD")
	if visual != null:
		visual.play("guard", facing_dir)

func stop_guard() -> void:
	if current_state == State.GUARD:
		current_state = State.IDLE
		combat_state_changed.emit("IDLE")

# ==================== ATAQUES Y COMBOS ====================

func get_attack_params() -> Dictionary:
	var weapon = player.weapon_id if player != null else &"none"
	match weapon:
		&"sword":
			return {"damage": 20.0, "reach": 28.0, "width": 20.0, "duration": 0.33, "recup": 0.33}
		&"axe":
			return {"damage": 32.0, "reach": 30.0, "width": 22.0, "duration": 0.40, "recup": 0.40}
		_:
			# T0 puño
			return {"damage": 8.0, "reach": 18.0, "width": 18.0, "duration": 0.33, "recup": 0.33}

func can_attack() -> bool:
	if current_state in [State.DEAD, State.HURT, State.DODGE]:
		return false
	if current_state == State.ATTACK_1:
		# Comprobar si puede buffer combo
		if _attack_timer >= _combo_window_start and _attack_timer <= _combo_window_end:
			_combo_buffered = true
		return false
	if current_state == State.ATTACK_2:
		return false
	return true

func start_attack(facing_dir: String) -> void:
	current_state = State.ATTACK_1
	combat_state_changed.emit("ATTACK_1")
	_init_swing(1, facing_dir)

func _init_swing(step: int, facing_dir: String) -> void:
	current_attack_id += 1
	_combo_buffered = false
	_attack_timer = 0.0
	damaged_targets_in_current_swing.clear()

	var params = get_attack_params()
	_attack_duration = params["duration"]

	_update_hitbox_shape(params["reach"], params["width"], facing_dir)

	var anim_name = "slash1" if step == 1 else "slash2"
	if visual != null:
		visual.play(anim_name, facing_dir)

func _update_hitbox_shape(reach: float, width: float, facing_dir: String) -> void:
	if attack_pivot == null or attack_shape == null:
		return

	# Rotación del pivote según dirección
	match facing_dir:
		"right": attack_pivot.rotation = 0.0
		"down": attack_pivot.rotation = PI / 2.0
		"left": attack_pivot.rotation = PI
		"up": attack_pivot.rotation = -PI / 2.0

	if attack_shape.shape is RectangleShape2D:
		var rect: RectangleShape2D = attack_shape.shape
		rect.size = Vector2(reach, width)
		# Centro delante de los pies / pivote: nunca atrás
		attack_shape.position = Vector2(reach / 2.0, 0.0)

func _process_attack(delta: float) -> void:
	_attack_timer += delta

	# Activación precisa de frames de impacto
	var is_impact_frame: bool = (_attack_timer >= _impact_start and _attack_timer <= _impact_end)
	if attack_area != null:
		attack_area.monitoring = is_impact_frame

	if _attack_timer >= _attack_duration:
		if attack_area != null:
			attack_area.monitoring = false

		if current_state == State.ATTACK_1 and _combo_buffered:
			current_state = State.ATTACK_2
			combat_state_changed.emit("ATTACK_2")
			var facing = player.direccion_mirando if player != null else "down"
			_init_swing(2, facing)
		else:
			current_state = State.IDLE
			combat_state_changed.emit("IDLE")

func cancel_attack() -> void:
	if attack_area != null:
		attack_area.monitoring = false
	damaged_targets_in_current_swing.clear()
	_combo_buffered = false

func _on_attack_area_entered(area: Area2D) -> void:
	var target = area.owner if area.owner != null else area.get_parent()
	if target == null or target == player:
		return
	if damaged_targets_in_current_swing.has(target):
		return # Un daño por objetivo y attack_id

	# Comprobar línea de visión contra capa 1 (mundo): no atravesar paredes
	if not _has_line_of_sight_to(area.global_position):
		return

	damaged_targets_in_current_swing.append(target)

	var params = get_attack_params()
	var damage = params["damage"]
	var was_critical: bool = false

	if staggered_critical_enemies.has(target):
		was_critical = true
		damage *= 2.0 # Crítico 2x garantizado
		staggered_critical_enemies.erase(target)

	if target.has_method("take_hit"):
		target.take_hit(damage, player, was_critical)

func _has_line_of_sight_to(target_pos: Vector2) -> bool:
	if player == null or not player.is_inside_tree():
		return true
	var world_2d = player.get_world_2d()
	if world_2d == null:
		return true
	var space_state = world_2d.direct_space_state
	if space_state == null:
		return true
	var origin = player.global_position + Vector2(0, -12)
	var query = PhysicsRayQueryParameters2D.create(origin, target_pos, 1) # Capa 1: mundo
	query.hit_from_inside = true
	var result = space_state.intersect_ray(query)
	return result.is_empty()

# ==================== RECIBIR GOLPE (CONTRATO) ====================

func receive_hit(hit: Dictionary) -> StringName:
	if current_state == State.DEAD:
		return &"DAMAGED"

	# 1. Esquiva
	if is_dodge_invulnerable():
		return &"DODGED"

	var dmg: float = hit.get("damage", 10.0)
	var unblockable: bool = hit.get("unblockable", false)

	# 2. Ataque rojo (unblockable) ignora guardia y parry
	if unblockable:
		_apply_damage(dmg)
		return &"DAMAGED"

	# 3. Parry
	if current_state == State.PARRY:
		var success: bool = false
		if debug_force_parry != null:
			success = bool(debug_force_parry)
		else:
			success = (randf() < parry_success_chance)

		if success:
			# Parry perfecto: 0 daño, stagger al atacante 1.0s
			if visual != null:
				visual.play_parry_success_flash()
			var source = hit.get("source")
			if source != null and is_instance_valid(source):
				if source.has_method("stagger"):
					source.stagger(1.0)
				staggered_critical_enemies[source] = 1.0
			return &"PARRIED"
		else:
			# Fallo fortuito (5%): daño normal, sin stagger
			_apply_damage(dmg)
			return &"DAMAGED"

	# 4. Error de tiempo en parry (recuperación 0.30s) -> 1.25x daño
	if current_state == State.PARRY_RECOVERY:
		_apply_damage(dmg * 1.25)
		return &"DAMAGED"

	# 5. Guardia
	if current_state == State.GUARD:
		if current_stamina >= GUARD_STAMINA_COST_PER_HIT:
			consume_stamina(GUARD_STAMINA_COST_PER_HIT)
			var pass_ratio: float = 0.20 if (player != null and player.has_shield) else 0.30
			_apply_damage(dmg * pass_ratio, false)
			return &"BLOCKED"
		else:
			# Guardia rota por falta de stamina
			_apply_damage(dmg)
			return &"DAMAGED"

	# 6. Daño directo
	_apply_damage(dmg)
	return &"DAMAGED"

func _apply_damage(amount: float, trigger_hurt: bool = true) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)

	cancel_attack()

	if current_health <= 0.0:
		current_state = State.DEAD
		combat_state_changed.emit("DEAD")
		if visual != null:
			var facing = player.direccion_mirando if player != null else "down"
			visual.play("dead", facing)
		player_died.emit()
	elif trigger_hurt:
		current_state = State.HURT
		combat_state_changed.emit("HURT")
		if visual != null:
			var facing = player.direccion_mirando if player != null else "down"
			visual.play("hurt", facing)

		# Salir de estado HURT tras breve flinch
		if player != null and player.is_inside_tree():
			var tree = player.get_tree()
			if tree != null:
				await tree.create_timer(0.20).timeout
				if current_state == State.HURT:
					current_state = State.IDLE
					combat_state_changed.emit("IDLE")
					if visual != null:
						visual.play("stand", player.direccion_mirando)
