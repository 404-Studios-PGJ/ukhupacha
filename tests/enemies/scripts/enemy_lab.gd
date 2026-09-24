extends Node2D
## Laboratorio F6 de enemigos: muestra el estado del dummy, las señales de
## los enemigos y avisa si un mismo attack_id llega dos veces al Player.
##   E = abrir/cerrar puerta   R = reiniciar escena

const MAX_LOG_LINES : int = 6

var _events : Array[String] = []
var _hits_per_attack : Dictionary = {}
var _duplicate_hits : int = 0

@onready var dummy : PlayerDummy = $PlayerDummy
@onready var hud : Label = $HUD/Label
@onready var door : StaticBody2D = $Door


func _ready() -> void:
	dummy.hit_resolved.connect(_on_hit_resolved)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.enemy_alerted.connect(_log.bind("alerta"))
		enemy.enemy_calmed.connect(_log.bind("calma"))
		enemy.enemy_died.connect(_log.bind("muerte"))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				_toggle_door()
			KEY_R:
				get_tree().reload_current_scene()


func _process(_delta: float) -> void:
	var lines : Array[String] = [
		"Defensa [1-4]: %s   HP: %d   Último: %s" % [dummy.defense_name(), dummy.hp, dummy.last_result],
		"Golpes duplicados por attack_id: %d" % _duplicate_hits,
		"E puerta  R reiniciar  Clic atacar",
	]
	lines.append_array(_events)
	hud.text = "\n".join(lines)


func _on_hit_resolved(hit: Dictionary, result: StringName) -> void:
	var count : int = _hits_per_attack.get(hit.attack_id, 0) + 1
	_hits_per_attack[hit.attack_id] = count
	if count > 1:
		_duplicate_hits += 1
	var kind := "blanco" if hit.parryable else "rojo"
	_push("#%d %s %s -> %s" % [hit.attack_id, hit.source.name, kind, result])


func _log(enemy: EnemyBase, event_name: String) -> void:
	_push("%s: %s" % [enemy.name, event_name])


func _push(line: String) -> void:
	_events.push_front(line)
	if _events.size() > MAX_LOG_LINES:
		_events.pop_back()


func _toggle_door() -> void:
	var closing := not door.visible
	door.visible = closing
	door.get_node("CollisionShape2D").set_deferred("disabled", not closing)
	_push("Puerta %s" % ("cerrada" if closing else "abierta"))
