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
				"damage": hit.damage, "parryable": hit.parryable, "unblockable": hit.unblockable}))
	for enemy in get_nodes_in_group("enemies"):
		for signal_name in ["enemy_alerted", "enemy_calmed", "enemy_died"]:
			enemy.connect(signal_name, _count.bind(signal_name))

	var guard : EnemyBase = _lab.get_node("Guard")
	var heavy : EnemyBase = _lab.get_node("Heavy")
	var shield : EnemyBase = _lab.get_node("Shield")
	var elite : EnemyBase = _lab.get_node("Elite")
	var pistol : EnemyBase = _lab.get_node("Pistol")
	# Solo un guardia activo por prueba.
	heavy.process_mode = Node.PROCESS_MODE_DISABLED
	shield.process_mode = Node.PROCESS_MODE_DISABLED
	elite.process_mode = Node.PROCESS_MODE_DISABLED
	pistol.process_mode = Node.PROCESS_MODE_DISABLED

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

	# El jefe está detrás de la puerta: cerrada no ve al Player; abierta, sí.
	elite.process_mode = Node.PROCESS_MODE_INHERIT
	_dummy.global_position = Vector2(425, 180)
	await _wait(1.0)
	_check("puerta cerrada bloquea la visión", elite.state == EnemyBase.State.IDLE)
	_lab._toggle_door()
	await _wait(0.3)
	_check("puerta abierta: el jefe ve al Player", elite.state == EnemyBase.State.SUSPICIOUS)
	elite.process_mode = Node.PROCESS_MODE_DISABLED
	_lab._toggle_door()
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
	await _test_feedback(shield)
	await _test_elite(elite)
	await _test_pistol(pistol)

	print("\n%s: %d fallos" % ["OK" if _failures == 0 else "FALLÓ", _failures])
	# Cierre ordenado: libera la escena y deja que el audio suelte sus sonidos.
	_lab.queue_free()
	for i in 30:
		await process_frame
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
	await _test_heavy_ranged(heavy)
	heavy.take_hit(999.0, _dummy)


## Pesado a distancia: pistola, pistola y cañón de energía (especial).
func _test_heavy_ranged(heavy: EnemyBase) -> void:
	_dummy.defense = PlayerDummy.Defense.DODGE
	var kinds : Array[StringName] = []
	var cannon_armored := false
	for i in 3:
		# Entre disparos avanza hacia el Player: el Player retrocede cada
		# frame para quedar siempre a distancia de disparo.
		await _until(func() -> bool:
			if heavy.state != EnemyBase.State.WINDUP:
				_dummy.global_position = heavy.global_position + Vector2(-90, 0)
			return heavy.state == EnemyBase.State.WINDUP and heavy.current_attack.ranged, 8.0)
		if heavy.current_attack == heavy.stats.special_ranged_attack:
			kinds.append(&"cañón")
			heavy.take_hit(1.0, _dummy)
			cannon_armored = heavy.state == EnemyBase.State.WINDUP
		else:
			kinds.append(&"pistola")
		await _until(func() -> bool: return heavy.state == EnemyBase.State.RECOVERY, 3.0)
	_check("pesado: pistola, pistola, cañón", kinds == [&"pistola", &"pistola", &"cañón"])
	_check("pesado: la carga del cañón tiene armadura", cannon_armored)
	var cannon := heavy.stats.special_ranged_attack
	_check("pesado: cañón rojo de 24, bola grande y lenta", cannon.kind == EnemyAttack.Kind.RED
			and is_equal_approx(cannon.damage, 24.0) and cannon.projectile_radius > 3.0
			and cannon.projectile_speed < heavy.stats.ranged_attack.projectile_speed)


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


## Efectos de DAMAGED, BLOCKED y DODGED en quien ataca.
func _test_feedback(enemy: EnemyBase) -> void:
	for step in [
		[PlayerDummy.Defense.BLOCK, &"BLOCKED", "enemy_clank.wav"],
		[PlayerDummy.Defense.NONE, &"DAMAGED", "enemy_hit.wav"],
		[PlayerDummy.Defense.DODGE, &"DODGED", "enemy_swing_miss.wav"],
	]:
		_dummy.defense = step[0]
		_dummy.global_position = enemy.global_position + enemy.facing * 22.0
		var start := _hits.size()
		await _until(func() -> bool: return _hits.size() > start, 6.0)
		var ok : bool = _hits.size() > start and _hits[start].result == step[1]
		_check("efecto %s: sonido propio" % step[1],
				ok and _sfx_playing(enemy, step[2]))
		if step[1] == &"BLOCKED":
			var distance := enemy.global_position.distance_to(_dummy.global_position)
			await _until(func() -> bool: return enemy.state == EnemyBase.State.RECOVERY, 1.0)
			await _wait(0.15)
			_check("efecto BLOCKED: el enemigo rebota hacia atrás",
					enemy.global_position.distance_to(_dummy.global_position) > distance + 3.0)

	# Swing que no toca a nadie: whoosh al terminar la ventana activa.
	_dummy.defense = PlayerDummy.Defense.NONE
	_dummy.global_position = enemy.global_position + enemy.facing * 22.0
	await _until(func() -> bool: return enemy.state == EnemyBase.State.WINDUP, 6.0)
	_dummy.global_position += enemy.facing.orthogonal() * 60.0
	await _until(func() -> bool: return enemy.state == EnemyBase.State.RECOVERY, 2.0)
	_check("swing al aire: whoosh", _sfx_playing(enemy, "enemy_swing_miss.wav"))
	enemy.process_mode = Node.PROCESS_MODE_DISABLED


## Guardia con pistola: dispara de lejos (rojo) y da culatazos de cerca (blanco).
func _test_pistol(pistol: EnemyBase) -> void:
	_check("pistola: 60 HP", is_equal_approx(pistol.hp, 60.0))
	_dummy.global_position = pistol.global_position + pistol.facing * 20.0
	_check("pistola: sin bloqueo frontal", pistol.take_hit(5.0, _dummy) == &"DAMAGED")

	# De lejos apunta con aviso rojo y dispara; el parry no sirve.
	# Dispara hacia la pared del cuarto, 55 px detrás del Player.
	_dummy.global_position = pistol.global_position + Vector2(100, 0)
	_dummy.defense = PlayerDummy.Defense.PARRY
	pistol.process_mode = Node.PROCESS_MODE_INHERIT
	await _until(func() -> bool: return pistol.state == EnemyBase.State.WINDUP, 6.0)
	_check("pistola: apunta con aviso rojo", pistol.current_attack != null
			and pistol.current_attack.ranged and pistol.telegraph.mode == EnemyTelegraph.Mode.ATTACK_RED)
	var start := _hits.size()
	await _until(func() -> bool: return _hits.size() > start, 3.0)
	_check("pistola: disparo rojo de 14", _hits.size() > start and not _hits[start].parryable
			and _hits[start].unblockable and is_equal_approx(_hits[start].damage, 14.0))
	_check("pistola: el parry no detiene la bala",
			_hits.size() > start and _hits[start].result == &"DAMAGED")

	# Esquivada, la bala sigue de largo y se detiene en la pared.
	_dummy.defense = PlayerDummy.Defense.DODGE
	start = _hits.size()
	await _until(func() -> bool: return _hits.size() > start, 4.0)
	await physics_frame
	_check("pistola: la bala esquivada sigue", _hits.size() > start
			and _hits[start].result == &"DODGED" and _projectiles() > 0)
	await _until(func() -> bool: return _projectiles() == 0, 3.0)
	_check("pistola: la bala se detiene en la pared", _projectiles() == 0)

	# De cerca, culatazo blanco de 12.
	_dummy.defense = PlayerDummy.Defense.NONE
	start = _hits.size()
	_dummy.global_position = pistol.global_position + pistol.facing * 18.0
	await _until(func() -> bool: return _hits.size() > start, 6.0)
	_check("pistola: culatazo blanco de 12 de cerca", _hits.size() > start
			and _hits[start].parryable and is_equal_approx(_hits[start].damage, 12.0))
	pistol.process_mode = Node.PROCESS_MODE_DISABLED


func _projectiles() -> int:
	return _lab.get_children().filter(func(n: Node) -> bool: return n is EnemyProjectile).size()


func _sfx_playing(enemy: EnemyBase, file: String) -> bool:
	return enemy._sfx.playing and enemy._sfx.stream.resource_path.get_file() == file


func _test_elite(elite: EnemyBase) -> void:
	_check("élite: 150 HP, más que los demás", is_equal_approx(elite.hp, 150.0))
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

	await _test_minions(elite)

	# Pelea completa: parry al blanco, esquiva al rojo y un crítico por
	# aturdimiento. Con poca vida salta; el primer salto no se esquiva.
	# Los robots que suelta se eliminan en cuanto aparecen.
	var wave_hp : Array[float] = []
	var max_alive := 0
	_dummy.hp = _dummy.max_hp
	var hp_before := _dummy.hp
	var criticals := 0
	var hit_this_stagger := false
	var previous := elite.state
	var leap_hp : Array[float] = []
	var first_leap_hit := -1
	var leap_armored := false
	var landed_near := false
	for i in ceili(90.0 * Engine.physics_ticks_per_second):
		if elite.is_dead():
			break
		var leaping := elite.current_attack != null and elite.current_attack.leap
		if elite.state == EnemyBase.State.WINDUP and previous != EnemyBase.State.WINDUP:
			if leaping:
				leap_hp.append(elite.hp)
				if leap_hp.size() == 1:
					first_leap_hit = _hits.size()
					_dummy.defense = PlayerDummy.Defense.NONE
					elite.take_hit(1.0, _dummy)
					leap_armored = elite.state == EnemyBase.State.WINDUP
				else:
					_dummy.defense = PlayerDummy.Defense.DODGE
			else:
				var red := elite.current_attack.kind == EnemyAttack.Kind.RED
				_dummy.defense = PlayerDummy.Defense.DODGE if red else PlayerDummy.Defense.PARRY
		if leaping and previous == EnemyBase.State.ACTIVE and elite.state == EnemyBase.State.RECOVERY \
				and leap_hp.size() == 1:
			landed_near = elite.global_position.distance_to(_dummy.global_position) \
					<= elite.current_attack.impact_radius
		var alive := _minions()
		max_alive = maxi(max_alive, alive.size())
		if not alive.is_empty():
			wave_hp.append(elite.hp)
			for minion in alive:
				minion.take_hit(999.0, _dummy)
		if elite.is_staggered() and not hit_this_stagger:
			elite.take_hit(20.0, _dummy, true)
			criticals += 1
			hit_this_stagger = true
		elif not elite.is_staggered():
			hit_this_stagger = false
		previous = elite.state
		await physics_frame
	print("  élite vencida con %d críticos y %d saltos" % [criticals, leap_hp.size()])
	_check("élite: vencible con parry, esquiva y crítico", elite.is_dead())
	var danger_hp := elite.stats.max_hp * elite.stats.danger_hp_ratio
	_check("élite: salta solo en peligro (≤40 % de vida)",
			not leap_hp.is_empty() and leap_hp.all(func(hp: float) -> bool: return hp <= danger_hp))
	_check("élite: la carga del salto tiene armadura", leap_armored)
	var leap_hit : Dictionary = _hits[first_leap_hit] if first_leap_hit >= 0 and first_leap_hit < _hits.size() else {}
	_check("élite: salto rojo de 30 al caer", not leap_hit.is_empty() and leap_hit.result == &"DAMAGED"
			and is_equal_approx(leap_hit.damage, 30.0) and not leap_hit.parryable and leap_hit.unblockable)
	_check("élite: cae donde estaba el Player", landed_near)
	_check("élite: solo el salto no esquivado hizo daño", is_equal_approx(_dummy.hp, hp_before - 30.0))
	var ratios := elite.stats.summon_hp_ratios
	_check("élite: suelta robots al 50 % y 25 %", wave_hp.size() == 2
			and wave_hp[0] <= elite.stats.max_hp * ratios[1] and wave_hp[0] > elite.stats.max_hp * ratios[2]
			and wave_hp[1] <= elite.stats.max_hp * ratios[2])
	_check("élite: nunca más de 3 robots vivos", max_alive <= elite.stats.summon_max_alive)
	_check("élite: enemy_died una vez", _signal_count(elite, "enemy_died") == 1)


## Robots pequeños: 2 al bajar del 75 %, 20 HP, solo tajo de sierra blanco.
func _test_minions(elite: EnemyBase) -> void:
	_dummy.defense = PlayerDummy.Defense.NONE
	elite.take_hit(40.0, _dummy)
	await _wait(0.2)
	var minions := _minions()
	_check("robots: 2 al bajar del 75 % de vida", minions.size() == 2)
	if minions.size() < 2:
		return
	var minion : EnemyBase = minions[0]
	_check("robots: 20 HP, versión pequeña del jefe", is_equal_approx(minion.hp, 20.0)
			and minion.visual.sprite_scale < elite.visual.sprite_scale)
	_check("robots: entran persiguiendo al Player", minion.target == _dummy)
	# Mientras los robots atacan, el jefe espera.
	elite.process_mode = Node.PROCESS_MODE_DISABLED
	var start := _hits.size()
	await _until(func() -> bool: return _hits.slice(start).any(
			func(h: Dictionary) -> bool: return h.source in minions), 6.0)
	var minion_hits := _hits.slice(start).filter(func(h: Dictionary) -> bool: return h.source in minions)
	_check("robots: solo tajo blanco de 8", not minion_hits.is_empty() and minion_hits.all(
			func(h: Dictionary) -> bool: return h.parryable and is_equal_approx(h.damage, 8.0)))
	minion.take_hit(10.0, _dummy)
	var alive_after_one := not minion.is_dead()
	minion.take_hit(10.0, _dummy)
	_check("robots: mueren con 2 golpes de 10", alive_after_one and minion.is_dead())
	minions[1].take_hit(999.0, _dummy)
	elite.process_mode = Node.PROCESS_MODE_INHERIT


func _minions() -> Array:
	return get_nodes_in_group("enemies").filter(func(n: Node) -> bool:
		return n.scene_file_path.ends_with("helix_minion.tscn") and not n.is_dead())


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
