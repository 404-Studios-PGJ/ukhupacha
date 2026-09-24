extends SceneTree
## Prueba automática del laboratorio de enemigos.
## Ejecutar: godot --headless --path . -s res://tests/enemies/enemy_autotest.gd

const LAB : PackedScene = preload("res://tests/enemies/enemy_lab.tscn")

var _failures : int = 0
var _lab : Node2D
var _dummy : PlayerDummy
var _hits : Array[Dictionary] = []
var _signals : Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_lab = LAB.instantiate()
	root.add_child(_lab)
	_dummy = _lab.get_node("PlayerDummy")
	_dummy.hit_resolved.connect(func(hit: Dictionary, result: StringName) -> void:
		_hits.append({"attack_id": hit.attack_id, "source": hit.source, "result": result}))
	for enemy in get_nodes_in_group("enemies"):
		for signal_name in ["enemy_alerted", "enemy_calmed", "enemy_died"]:
			enemy.connect(signal_name, _count.bind(signal_name))

	var guard : EnemyBase = _lab.get_node("GuardSightWall")
	var patrol : EnemyBase = _lab.get_node("GuardPatrol")
	var room : EnemyBase = _lab.get_node("GuardRoom")
	# Solo un guardia activo por prueba.
	patrol.process_mode = Node.PROCESS_MODE_DISABLED

	await _wait(1.0)
	_check("pared bloquea la visión", guard.state == EnemyBase.State.IDLE)

	_dummy.global_position = Vector2(425, 180)
	await _wait(1.0)
	_check("puerta cerrada bloquea la visión", room.state == EnemyBase.State.IDLE)
	_dummy.global_position = Vector2(110, 250)

	# Sospecha y detección.
	_dummy.global_position = Vector2(200, 150)
	await _wait(0.1)
	_check("ve al Player: SUSPICIOUS", guard.state == EnemyBase.State.SUSPICIOUS)
	await _wait(0.6)
	_check("tras 0,5 s persigue", guard.state == EnemyBase.State.CHASE)
	_check("enemy_alerted una vez", _signal_count(guard, "enemy_alerted") == 1)

	# Golpe blanco recibido sin defensa: una sola llamada por attack_id.
	_dummy.defense = PlayerDummy.Defense.NONE
	await _until(func() -> bool: return guard.state == EnemyBase.State.RECOVERY, 5.0)
	var guard_hits := _hits.filter(func(h: Dictionary) -> bool: return h.source == guard)
	_check("recibe exactamente un golpe", guard_hits.size() == 1)
	_check("daño blanco 10", is_equal_approx(_dummy.hp, 90.0))

	# Parry: stagger de 1 s y crítico x2.
	_dummy.defense = PlayerDummy.Defense.PARRY
	await _until(func() -> bool: return guard.state == EnemyBase.State.STAGGER, 5.0)
	_check("parry aturde", guard.is_staggered())
	var hp_before := guard.hp
	guard.take_hit(20.0, _dummy, true)
	_check("crítico no cancela el stagger", guard.is_staggered())
	_check("crítico aplica daño", is_equal_approx(guard.hp, hp_before - 20.0))

	# Interrupción durante windup: ese attack_id nunca llega al Player.
	_dummy.defense = PlayerDummy.Defense.NONE
	await _until(func() -> bool: return guard.state == EnemyBase.State.WINDUP, 5.0)
	var hits_before := _hits.size()
	guard.take_hit(1.0, _dummy)
	_check("golpe en windup interrumpe", guard.state == EnemyBase.State.HURT)
	await _wait(0.4)
	_check("ataque interrumpido no golpea", _hits.size() == hits_before)

	# Esquiva por movimiento: el swing falla si el Player sale del alcance.
	await _until(func() -> bool: return guard.state == EnemyBase.State.WINDUP, 5.0)
	var locked_facing := guard.facing
	_dummy.global_position += (guard.global_position.direction_to(_dummy.global_position)).orthogonal() * 40.0
	await _wait(0.05)
	_check("orientación fija en windup", guard.facing == locked_facing)
	hits_before = _hits.size()
	await _until(func() -> bool: return guard.state == EnemyBase.State.RECOVERY, 2.0)
	_check("swing esquivado no golpea", _hits.size() == hits_before)

	# Pérdida de vista: el Player se esconde detrás de la pared.
	_dummy.global_position = Vector2(110, 290)
	await _until(func() -> bool: return guard.state == EnemyBase.State.INVESTIGATE, 3.0)
	_check("pierde de vista e investiga", guard.state == EnemyBase.State.INVESTIGATE)
	await _until(func() -> bool: return guard.state == EnemyBase.State.IDLE, 8.0)
	_check("vuelve a su puesto", guard.state == EnemyBase.State.IDLE)
	_check("enemy_calmed al rendirse", _signal_count(guard, "enemy_calmed") == 1)

	# Muerte: señal única, sin hitbox ni colisión.
	guard.take_hit(999.0, _dummy)
	guard.take_hit(999.0, _dummy)
	await _wait(0.1)
	_check("enemy_died una vez", _signal_count(guard, "enemy_died") == 1)
	_check("muerto sin colisión", guard.collision_layer == 0)
	_check("muerto sin hitbox", not guard.attack_area.monitoring)

	print("\n%s: %d fallos" % ["OK" if _failures == 0 else "FALLÓ", _failures])
	quit(1 if _failures > 0 else 0)


func _check(label: String, condition: bool) -> void:
	print("[%s] %s" % ["ok" if condition else "FALLA", label])
	if not condition:
		_failures += 1


func _count(enemy: EnemyBase, signal_name: String) -> void:
	var key := "%s:%s" % [enemy.get_instance_id(), signal_name]
	_signals[key] = _signals.get(key, 0) + 1


func _signal_count(enemy: EnemyBase, signal_name: String) -> int:
	return _signals.get("%s:%s" % [enemy.get_instance_id(), signal_name], 0)


func _wait(seconds: float) -> void:
	for i in ceili(seconds * Engine.physics_ticks_per_second):
		await physics_frame


func _until(condition: Callable, timeout: float) -> void:
	var frames := ceili(timeout * Engine.physics_ticks_per_second)
	for i in frames:
		if condition.call():
			return
		await physics_frame
