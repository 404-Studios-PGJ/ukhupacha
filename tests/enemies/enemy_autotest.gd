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
		_hits.append({"attack_id": hit.attack_id, "source": hit.source, "result": result,
				"damage": hit.damage, "parryable": hit.parryable}))
	for enemy in get_nodes_in_group("enemies"):
		for signal_name in ["enemy_alerted", "enemy_calmed", "enemy_died"]:
			enemy.connect(signal_name, _count.bind(signal_name))

	var guard : EnemyBase = _lab.get_node("Guard")
	var heavy : EnemyBase = _lab.get_node("Heavy")
	var shield : EnemyBase = _lab.get_node("Shield")
	var elite : EnemyBase = _lab.get_node("Elite")
	# Solo un guardia activo por prueba.
	heavy.process_mode = Node.PROCESS_MODE_DISABLED
	elite.process_mode = Node.PROCESS_MODE_DISABLED

	await _wait(1.0)
	_check("pared bloquea la visión", guard.state == EnemyBase.State.IDLE)

	# Sonidos del laboratorio: ataque al aire y puerta.
	_dummy.attack()
	_check("whoosh al atacar al aire", _dummy._swing_audio.playing)
	_lab._toggle_door()
	_check("sonido al abrir la puerta", _lab._door_audio.playing)
	_lab._door_audio.stop()
	_lab._toggle_door()
	_check("mismo sonido al cerrar la puerta", _lab._door_audio.playing)
	await _wait(0.3)

	_dummy.global_position = Vector2(425, 180)
	await _wait(1.0)
	_check("puerta cerrada bloquea la visión", shield.state == EnemyBase.State.IDLE)
	_dummy.global_position = Vector2(110, 250)

	# Sospecha y detección.
	_dummy.global_position = Vector2(200, 150)
	await _wait(0.1)
	_check("ve al Player: SUSPICIOUS", guard.state == EnemyBase.State.SUSPICIOUS)
	_check("sonido de sospecha", _plays(guard, EnemyTelegraph.Mode.SUSPICIOUS))
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

	await _test_heavy(heavy)
	await _test_shield(shield)
	await _test_elite(elite)

	print("\n%s: %d fallos" % ["OK" if _failures == 0 else "FALLÓ", _failures])
	quit(1 if _failures > 0 else 0)


func _test_heavy(heavy: EnemyBase) -> void:
	heavy.process_mode = Node.PROCESS_MODE_INHERIT
	_dummy.defense = PlayerDummy.Defense.DODGE
	_dummy.global_position = heavy.global_position + Vector2(0, 40)
	var start := _hits.size()
	await _until(func() -> bool: return _hits.size() >= start + 3, 15.0)
	var h := _hits.slice(start)
	_check("pesado: patrón blanco, blanco, rojo",
			h.size() >= 3 and h[0].parryable and h[1].parryable and not h[2].parryable)
	_check("pesado: blanco 14 y rojo 20",
			h.size() >= 3 and is_equal_approx(h[0].damage, 14.0) and is_equal_approx(h[2].damage, 20.0))
	_check("pesado: rojo esquivado", h.size() >= 3 and h[2].result == &"DODGED")

	# El rojo no admite parry y su windup tiene armadura.
	_dummy.defense = PlayerDummy.Defense.PARRY
	await _until(func() -> bool:
		return heavy.state == EnemyBase.State.WINDUP and heavy.current_attack.kind == EnemyAttack.Kind.RED, 20.0)
	heavy.take_hit(1.0, _dummy)
	_check("pesado: sonido de aviso rojo", _plays(heavy, EnemyTelegraph.Mode.ATTACK_RED))
	_check("pesado: golpe no cancela windup rojo", heavy.state == EnemyBase.State.WINDUP)
	start = _hits.size()
	await _until(func() -> bool: return _hits.size() > start, 2.0)
	_check("pesado: parry contra rojo = daño",
			_hits.size() > start and _hits[start].result == &"DAMAGED" and not heavy.is_staggered())
	heavy.take_hit(999.0, _dummy)


func _test_shield(shield: EnemyBase) -> void:
	# Estático: sin procesar, la orientación no cambia entre golpes.
	shield.process_mode = Node.PROCESS_MODE_DISABLED
	var f := shield.facing
	_dummy.global_position = shield.global_position + f * 20.0
	_check("escudo: bloquea de frente", shield.take_hit(10.0, _dummy) == &"BLOCKED")
	_check("escudo: bloqueo sin daño", is_equal_approx(shield.hp, 60.0))
	_dummy.global_position = shield.global_position + f.rotated(deg_to_rad(50.0)) * 20.0
	_check("escudo: bloquea a 50°", shield.take_hit(10.0, _dummy) == &"BLOCKED")
	_dummy.global_position = shield.global_position + f.orthogonal() * 20.0
	_check("escudo: costado (90°) vulnerable", shield.take_hit(5.0, _dummy) == &"DAMAGED")
	_dummy.global_position = shield.global_position - f * 20.0
	_check("escudo: espalda vulnerable", shield.take_hit(5.0, _dummy) == &"DAMAGED")

	# Dinámico: persigue, ataca y en recovery baja el escudo.
	shield.process_mode = Node.PROCESS_MODE_INHERIT
	_dummy.defense = PlayerDummy.Defense.DODGE
	_dummy.global_position = shield.global_position + Vector2(-30, 0)
	await _until(func() -> bool: return shield.state == EnemyBase.State.RECOVERY, 6.0)
	_check("escudo: bajo en recovery", not shield.is_shield_up())
	var hp_before := shield.hp
	_check("escudo: golpe frontal en recovery", shield.take_hit(5.0, _dummy) == &"DAMAGED"
			and shield.hp < hp_before)

	# Contacto con un enemigo: no suena el whoosh.
	var to_shield := _dummy.global_position.direction_to(shield.global_position)
	_dummy.global_position = shield.global_position - to_shield * 14.0
	_dummy.facing = to_shield
	_dummy.attack_pivot.rotation = to_shield.angle()
	_dummy._swing_audio.stop()
	await physics_frame
	await physics_frame
	_dummy.attack()
	_check("sin whoosh al tocar un enemigo", not _dummy._swing_audio.playing)

	# Giro lento: si el Player salta a su espalda, no se da vuelta al instante.
	await _until(func() -> bool: return shield.state == EnemyBase.State.CHASE, 3.0)
	_dummy.global_position = shield.global_position - shield.facing * 22.0
	await physics_frame
	_check("escudo: giro lento deja la espalda expuesta", shield.take_hit(5.0, _dummy) == &"DAMAGED")

	shield.stagger(1.0)
	_dummy.global_position = shield.global_position + shield.facing * 20.0
	_check("escudo: aturdido recibe crítico de frente", shield.take_hit(20.0, _dummy, true) == &"DAMAGED")


func _test_elite(elite: EnemyBase) -> void:
	_check("élite: 100 HP", is_equal_approx(elite.hp, 100.0))
	elite.process_mode = Node.PROCESS_MODE_INHERIT
	_dummy.defense = PlayerDummy.Defense.DODGE
	_dummy.global_position = elite.global_position + Vector2(-50, 0)
	var start := _hits.size()

	# Sincronía: en la ventana activa se ve un frame de golpe de la hoja blanca.
	await _until(func() -> bool: return elite.state == EnemyBase.State.ACTIVE, 6.0)
	await process_frame
	var visual : EnemySpriteVisual = elite.visual
	_check("élite: frame de golpe en la ventana activa",
			visual.sprite.texture == visual.white_attack_sheet
			and visual.sprite.frame in visual.white_active_frames)

	await _until(func() -> bool: return _hits.size() >= start + 2, 8.0)
	var h := _hits.slice(start)
	_check("élite: alterna blanco 12 y rojo 20", h.size() >= 2
			and h[0].parryable and is_equal_approx(h[0].damage, 12.0)
			and not h[1].parryable and is_equal_approx(h[1].damage, 20.0))

	# Vencible solo con parry al blanco, esquiva al rojo y críticos.
	# Un solo crítico por aturdimiento, como jugando.
	var hp_before := _dummy.hp
	var criticals := 0
	var hit_this_stagger := false
	for i in ceili(60.0 * Engine.physics_ticks_per_second):
		if elite.is_dead():
			break
		if elite.state == EnemyBase.State.WINDUP:
			var red := elite.current_attack.kind == EnemyAttack.Kind.RED
			_dummy.defense = PlayerDummy.Defense.DODGE if red else PlayerDummy.Defense.PARRY
		if elite.is_staggered() and not hit_this_stagger:
			elite.take_hit(20.0, _dummy, true)
			criticals += 1
			hit_this_stagger = true
		elif not elite.is_staggered():
			hit_this_stagger = false
		await physics_frame
	print("  élite vencida con %d críticos" % criticals)
	_check("élite: vencible con parry, esquiva y crítico", elite.is_dead())
	_check("élite: sin recibir daño al defender bien", is_equal_approx(_dummy.hp, hp_before))
	_check("élite: enemy_died una vez", _signal_count(elite, "enemy_died") == 1)


func _plays(enemy: EnemyBase, mode: EnemyTelegraph.Mode) -> bool:
	var audio : AudioStreamPlayer2D = enemy.telegraph._audio
	return audio.playing and audio.stream == EnemyTelegraph.SOUNDS[mode]


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
