class_name PuzzleTerminalView
extends Control

signal closed()
var terminal: Node
var player: Node
var _prior_input: bool = false
var _prior_pause: bool = false
var _active: bool = false
var selected: StringName = &""
var linked: bool = false
var _cards: Dictionary[StringName, Button] = {}
var _detail: Label
var _rejected: Label
var _valid: Label
var _knowledge: Panel
var _relation_a: Line2D
var _relation_b: Line2D
const CLUES: Dictionary[StringName, String] = {
	&"record_a": "PUBLICIDAD\nAcceso público\nal archivo Helix.",
	&"record_b": "CLASIFICACIÓN\nEl mismo archivo\nes restringido.",
	&"record_c": "ANOMALÍA\nLa auditoría detecta\nla contradicción.",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIBuild.screen(self)
	UIBuild.panel(self, Rect2(0, 0, 640, 360))
	UIBuild.header(self, "HELIX // TERMINAL DE ARCHIVO", "NODO H-03")
	UIBuild.rule(self, Rect2(0, 46, 640, 2), &"helix_green")
	UIBuild.panel(self, Rect2(18, 58, 604, 202), &"WarmPanel")
	UIBuild.label(self, "MAPA DE EVIDENCIAS · SELECCIONA DOS", Rect2(32, 65, 420, 18), &"Accent")
	var index: int = 0
	var count: int = 0
	for id: StringName in CLUES:
		var x: int = 32 + index * 206
		UIBuild.panel(self, Rect2(x, 91, 164, 94), &"Dossier")
		var card: Button = UIBuild.button(self, CLUES[id] if Level1Progress.get_flag(id) else "EVIDENCIA\nPENDIENTE", Rect2(x + 6, 95, 152, 86), select_evidence.bind(id))
		card.name = str(id)
		card.disabled = not Level1Progress.get_flag(id)
		_cards[id] = card
		if not card.disabled:
			count += 1
		index += 1
	UIBuild.label(self, "%d / 3 LEÍDAS" % count, Rect2(506, 66, 100, 18), &"Small")
	_relation_a = _relation(Vector2(196, 136), &"gold")
	_relation_b = _relation(Vector2(402, 136), &"ukhu_purple")
	UIBuild.panel(self, Rect2(32, 201, 229, 46), &"Rejected")
	UIBuild.icon(self, &"cross", Rect2(42, 211, 15, 15), &"health_red")
	_rejected = UIBuild.label(self, "Selecciona dos evidencias.", Rect2(64, 206, 187, 36), &"Small")
	_rejected.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIBuild.panel(self, Rect2(282, 201, 324, 46), &"Valid")
	_valid = UIBuild.label(self, "Contrasta publicidad con clasificación.", Rect2(294, 208, 300, 34), &"Small")
	_valid.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_knowledge = UIBuild.panel(self, Rect2(18, 274, 604, 54), &"Knowledge")
	UIBuild.icon(_knowledge, &"marker", Rect2(14, 12, 20, 14), &"ukhu_purple")
	_detail = UIBuild.label(_knowledge, "Selecciona para releer. A ↔ B; después relaciona C.", Rect2(44, 8, 536, 44))
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIBuild.button(self, "LIMPIAR", Rect2(18, 334, 110, 24), clear_selection)
	UIBuild.button(self, "CERRAR", Rect2(512, 334, 110, 24), close)
	if Level1Progress.get_flag(&"puzzle_solved"):
		_valid.text = "PUERTA 1 ABIERTA · ARCHIVO REGISTRADO"
		_detail.text = "TODO_CULTURAL: conocimiento recuperado pendiente de validación."
	Level1Progress.progress_reset.connect(close)
	if is_instance_valid(player):
		_prior_input = UIBuild.input_enabled(player)
		if player.has_method("set_input_enabled"):
			player.call("set_input_enabled", false)
		_prior_pause = get_tree().paused
		get_tree().paused = true
		_active = true
	for card: Button in _cards.values():
		if not card.disabled:
			card.grab_focus()
			break


func _relation(at: Vector2, token: StringName) -> Line2D:
	var line: Line2D = Line2D.new()
	line.points = PackedVector2Array([at, at + Vector2(40, 0)])
	line.width = 2
	line.default_color = UIAssets.color(token)
	add_child(line)
	var arrow: Polygon2D = Polygon2D.new()
	arrow.polygon = PackedVector2Array([at + Vector2(42, 0), at + Vector2(34, -4), at + Vector2(34, 4)])
	arrow.color = UIAssets.color(token)
	add_child(arrow)
	return line


func select_evidence(id: StringName) -> void:
	if not Level1Progress.get_flag(id):
		return
	_detail.text = CLUES[id].replace("\n", " · ") + " (Ficción Helix)"
	if selected == &"":
		selected = id
		_valid.text = "Origen seleccionado. Elige otra evidencia."
		return
	if selected == id:
		return
	var pair: Array[StringName] = [selected, id]
	if &"record_a" in pair and &"record_b" in pair:
		linked = true
		_relation_a.default_color = UIAssets.color(&"helix_green")
		_valid.text = "Publicidad y clasificación se contradicen. Añade C."
	elif linked and &"record_c" in pair:
		if is_instance_valid(terminal) and bool(terminal.call("submit_answer", &"contradiction")):
			_valid.text = "PUERTA 1 ABIERTA · RELACIÓN VÁLIDA"
			_detail.text = "TODO_CULTURAL: conocimiento recuperado pendiente de validación."
			_relation_b.default_color = UIAssets.color(&"helix_green")
	else:
		if is_instance_valid(terminal):
			terminal.call("submit_answer", &"agreement")
		_rejected.text = "Pista: compara primero el acceso público con la clasificación interna."
		_relation_a.default_color = UIAssets.color(&"health_red")
	selected = &""


func clear_selection() -> void:
	selected = &""
	linked = false
	_valid.text = "Contrasta publicidad con clasificación."


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pausa"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	_release()
	closed.emit()
	queue_free()


func _release() -> void:
	if not _active:
		return
	_active = false
	if is_instance_valid(player) and player.has_method("set_input_enabled"):
		player.call("set_input_enabled", _prior_input)
	get_tree().paused = _prior_pause


func _exit_tree() -> void:
	_release()
