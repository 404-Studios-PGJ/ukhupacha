class_name PuzzleTerminalView
extends Control

signal closed()
var terminal: Node
var player: Node
var _prior_input: bool = false
var _prior_pause: bool = false
var _active: bool = false
var _transition_locked := true
var _exit_started := false
var _close_requested := false
var selected: StringName = &""
var linked: bool = false
var _cards: Dictionary[StringName, Button] = {}
var _detail: Label
var _detail_secondary: Label
var _rejected: Label
var _valid: Label
var _knowledge: Control
var _relation_a: Line2D
var _relation_b: Line2D
var _relation_a_tween: Tween
var _relation_b_tween: Tween
var _invalid_chip_tween: Tween
var _invalid_detail_tween: Tween
var _success_chip_tween: Tween
var _success_detail_tween: Tween
var _success_feedback_played := false
var _evidence_hit_areas: Control
var _retry_button: Button
var _close_button: Button
var _close_tween: Tween
var _close_press_locked := false
var _card_visuals: Dictionary[StringName, Control] = {}
var _card_press_tweens: Dictionary[StringName, Tween] = {}
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
const CLUES: Dictionary[StringName, String] = {
	&"record_a": "PUBLICIDAD\nAcceso público\nal archivo Helix.",
	&"record_b": "CLASIFICACIÓN\nEl mismo archivo\nes restringido.",
	&"record_c": "ANOMALÍA\nLa auditoría detecta\nla contradicción.",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIBuild.screen(self)
	_evidence_hit_areas = $EvidenceHitAreas
	_card_visuals = {
		&"record_a": $EvidenceAPanel,
		&"record_b": $EvidenceBPanel,
		&"record_c": $EvidenceCPanel,
	}
	var index: int = 0
	for id: StringName in CLUES:
		var x: int = 35 + index * 186
		var card: Button = UIBuild.hit_area(_evidence_hit_areas, Rect2(x, 83, 168, 116), _on_evidence_pressed.bind(id), str(id))
		card.name = str(id)
		card.disabled = not Level1Progress.get_flag(id)
		_cards[id] = card
		[$EvidenceATitle, $EvidenceBTitle, $EvidenceCTitle][index].text = ["PUBLICIDAD", "CLASIFICADO", "AUDITORÍA"][index]
		[$EvidenceASubtitle, $EvidenceBSubtitle, $EvidenceCSubtitle][index].text = ["ARCHIVO", "RESTRINGIDO", "ANOMALÍA"][index]
		[$EvidenceAVerified, $EvidenceBVerified, $EvidenceCVerified][index].visible = not card.disabled
		[$EvidenceAVerifiedLabel, $EvidenceBVerifiedLabel, $EvidenceCVerifiedLabel][index].text = "EVIDENCIA VERIFICADA" if not card.disabled else "EVIDENCIA PENDIENTE"
		index += 1
	_relation_a = _relation(Vector2(119, 208), Vector2(305, 208), &"helix_green")
	_relation_b = _relation(Vector2(305, 208), Vector2(491, 208), &"ukhu_purple")
	_reset_relation_a_visual()
	_reset_relation_b_visual()
	_rejected = $FalseStateLabel
	_valid = $ValidStateLabel
	_knowledge = $KnowledgePanel
	_detail = $KnowledgeLabel
	_detail_secondary = $KnowledgeSecondaryLabel
	_detail.size = Vector2(338, 12)
	_detail.clip_text = true
	_detail.text = "Selecciona A y B; después relaciona C."
	_detail_secondary.text = "Evidencia archivada de Helix."
	_rejected.clip_text = true
	_valid.text = "VÍNCULO PENDIENTE"
	_retry_button = $RetryButton
	_close_button = $CloseButton
	if not _retry_button.pressed.is_connected(clear_selection):
		_retry_button.pressed.connect(clear_selection)
	if not _close_button.pressed.is_connected(_on_close_pressed):
		_close_button.pressed.connect(_on_close_pressed)
	if Level1Progress.get_flag(&"puzzle_solved"):
		_valid.text = "VÍNCULO VÁLIDO"
		_detail.text = "Conocimiento cultural pendiente"
		_detail_secondary.text = "de validación."
		_set_relation_color(_relation_a, UIAssets.color(&"helix_green"))
		_show_relation_a_full()
		_set_relation_color(_relation_b, UIAssets.color(&"helix_green"))
		_show_relation_b_full()
	Level1Progress.progress_reset.connect(close)
	if is_instance_valid(player):
		_prior_input = UIBuild.input_enabled(player)
		if player.has_method("set_input_enabled"):
			player.call("set_input_enabled", false)
		_prior_pause = get_tree().paused
		get_tree().paused = true
		_active = true
	_set_terminal_interaction_enabled(false)
	call_deferred("_play_terminal_enter")


func _play_terminal_enter() -> void:
	if _close_requested or not is_instance_valid(_animation_player):
		return
	pivot_offset = size * 0.5
	scale = Vector2(0.96, 0.96)
	modulate.a = 0.0
	_animation_player.play("terminal_enter")
	await _animation_player.animation_finished
	if _close_requested or not is_instance_valid(self):
		return
	_transition_locked = false
	_set_terminal_interaction_enabled(true)
	for card: Button in _cards.values():
		if not card.disabled:
			card.grab_focus()
			break


func _set_terminal_interaction_enabled(enabled: bool) -> void:
	_transition_locked = not enabled
	var filter := Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(_evidence_hit_areas):
		_evidence_hit_areas.mouse_filter = filter
	if is_instance_valid(_retry_button):
		_retry_button.mouse_filter = filter
	if is_instance_valid(_close_button):
		_close_button.mouse_filter = filter


func _relation(at: Vector2, endpoint: Vector2, token: StringName) -> Line2D:
	var line: Line2D = Line2D.new()
	line.points = PackedVector2Array([at, endpoint - Vector2(7, 0)])
	line.width = 2
	line.default_color = UIAssets.color(token)
	line.z_index = 35
	$RelationLayer.add_child(line)
	line.set_meta("relation_start", at)
	line.set_meta("relation_end", endpoint - Vector2(7, 0))
	var arrow: Polygon2D = Polygon2D.new()
	arrow.polygon = PackedVector2Array([endpoint, endpoint - Vector2(7, 4), endpoint - Vector2(7, -4)])
	arrow.color = UIAssets.color(token)
	arrow.z_index = 35
	$RelationLayer.add_child(arrow)
	line.set_meta("arrow", arrow)
	return line


func _set_relation_color(line: Line2D, tint: Color) -> void:
	line.default_color = tint
	(line.get_meta("arrow") as Polygon2D).color = tint


func select_evidence(id: StringName) -> void:
	if _transition_locked or _exit_started:
		return
	if not Level1Progress.get_flag(id):
		return
	_detail.text = CLUES[id].replace("\n", " · ")
	_detail_secondary.text = "Registro Helix (ficción)."
	if selected == &"":
		selected = id
		_valid.text = "VÍNCULO PENDIENTE"
		return
	if selected == id:
		return
	var pair: Array[StringName] = [selected, id]
	if &"record_a" in pair and &"record_b" in pair:
		linked = true
		_set_relation_color(_relation_a, UIAssets.color(&"helix_green"))
		_animate_relation_a()
		_valid.text = "A–B VINCULADOS"
		_detail.text = "Publicidad y clasificación se contradicen."
		_detail_secondary.text = "Añade la evidencia C."
	elif linked and &"record_c" in pair:
		if is_instance_valid(terminal) and bool(terminal.call("submit_answer", &"contradiction")):
			_valid.text = "VÍNCULO VÁLIDO"
			_detail.text = "Conocimiento cultural pendiente"
			_detail_secondary.text = "de validación."
			_set_relation_color(_relation_b, UIAssets.color(&"helix_green"))
			_animate_relation_b()
			if not _success_feedback_played:
				_success_feedback_played = true
				_pulse_success_feedback()
	else:
		if is_instance_valid(terminal):
			terminal.call("submit_answer", &"agreement")
		_rejected.text = "Pista: compara primero el acceso público con la clasificación interna."
		_detail.text = "Pista: compara acceso público y clasificación."
		_detail_secondary.text = "Después añade la evidencia C."
		_set_relation_color(_relation_a, UIAssets.color(&"health_red"))
		_show_relation_a_full()
		_pulse_invalid_feedback()
	selected = &""


func clear_selection() -> void:
	if _transition_locked or _exit_started:
		return
	selected = &""
	linked = false
	_valid.text = "VÍNCULO PENDIENTE"
	_rejected.text = "VÍNCULO FALSO"
	_detail.text = "Selecciona A y B; después relaciona C."
	_detail_secondary.text = "Evidencia archivada de Helix."
	_set_relation_color(_relation_a, UIAssets.color(&"helix_green"))
	_set_relation_color(_relation_b, UIAssets.color(&"ukhu_purple"))
	_reset_relation_a_visual()
	_reset_invalid_feedback()
	_reset_success_feedback()
	if Level1Progress.get_flag(&"puzzle_solved"):
		_set_relation_color(_relation_b, UIAssets.color(&"helix_green"))
		_show_relation_b_full()
	else:
		_reset_relation_b_visual()


func _set_relation_a_progress(progress: float, start: Vector2, end: Vector2) -> void:
	_relation_a.points = PackedVector2Array([start, start.lerp(end, progress)])


func _animate_relation_a() -> void:
	_reset_relation_a_visual()
	var arrow: Polygon2D = _relation_a.get_meta("arrow") as Polygon2D
	var start: Vector2 = _relation_a.get_meta("relation_start")
	var end: Vector2 = _relation_a.get_meta("relation_end")
	arrow.scale = Vector2(0.8, 0.8)
	_relation_a_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_relation_a_tween.tween_method(_set_relation_a_progress.bind(start, end), 0.0, 1.0, 0.18)
	_relation_a_tween.tween_callback(func() -> void: arrow.visible = true)
	_relation_a_tween.tween_property(arrow, "scale", Vector2.ONE, 0.07)


func _show_relation_a_full() -> void:
	if _relation_a_tween != null and _relation_a_tween.is_valid():
		_relation_a_tween.kill()
	var arrow: Polygon2D = _relation_a.get_meta("arrow") as Polygon2D
	var start: Vector2 = _relation_a.get_meta("relation_start")
	var end: Vector2 = _relation_a.get_meta("relation_end")
	_relation_a.points = PackedVector2Array([start, end])
	arrow.scale = Vector2.ONE
	arrow.visible = true


func _reset_relation_a_visual() -> void:
	if _relation_a_tween != null and _relation_a_tween.is_valid():
		_relation_a_tween.kill()
	var arrow: Polygon2D = _relation_a.get_meta("arrow") as Polygon2D
	var start: Vector2 = _relation_a.get_meta("relation_start")
	_relation_a.points = PackedVector2Array([start, start])
	arrow.scale = Vector2.ONE
	arrow.visible = false


func _set_relation_b_progress(progress: float, start: Vector2, end: Vector2) -> void:
	_relation_b.points = PackedVector2Array([start, start.lerp(end, progress)])


func _animate_relation_b() -> void:
	_reset_relation_b_visual()
	var arrow: Polygon2D = _relation_b.get_meta("arrow") as Polygon2D
	var start: Vector2 = _relation_b.get_meta("relation_start")
	var end: Vector2 = _relation_b.get_meta("relation_end")
	arrow.scale = Vector2(0.8, 0.8)
	_relation_b_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_relation_b_tween.tween_method(_set_relation_b_progress.bind(start, end), 0.0, 1.0, 0.18)
	_relation_b_tween.tween_callback(func() -> void: arrow.visible = true)
	_relation_b_tween.tween_property(arrow, "scale", Vector2.ONE, 0.07)


func _show_relation_b_full() -> void:
	if _relation_b_tween != null and _relation_b_tween.is_valid():
		_relation_b_tween.kill()
	var arrow: Polygon2D = _relation_b.get_meta("arrow") as Polygon2D
	var start: Vector2 = _relation_b.get_meta("relation_start")
	var end: Vector2 = _relation_b.get_meta("relation_end")
	_relation_b.points = PackedVector2Array([start, end])
	arrow.scale = Vector2.ONE
	arrow.visible = true


func _reset_relation_b_visual() -> void:
	if _relation_b_tween != null and _relation_b_tween.is_valid():
		_relation_b_tween.kill()
	var arrow: Polygon2D = _relation_b.get_meta("arrow") as Polygon2D
	var start: Vector2 = _relation_b.get_meta("relation_start")
	_relation_b.points = PackedVector2Array([start, start])
	arrow.scale = Vector2.ONE
	arrow.visible = false


func _pulse_invalid_feedback() -> void:
	_reset_invalid_feedback()
	var chip: Control = $FalseStateChip
	var detail_nodes: Array[Control] = [$KnowledgePanel, $KnowledgeLabel, $KnowledgeSecondaryLabel]
	chip.pivot_offset = chip.size * 0.5
	for detail: Control in detail_nodes:
		detail.pivot_offset = detail.size * 0.5
	_invalid_chip_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_invalid_chip_tween.tween_property(chip, "scale", Vector2(0.94, 0.94), 0.05)
	_invalid_chip_tween.tween_property(chip, "scale", Vector2(1.03, 1.03), 0.06)
	_invalid_chip_tween.tween_property(chip, "scale", Vector2.ONE, 0.07)
	_invalid_detail_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for detail: Control in detail_nodes:
		_invalid_detail_tween.tween_property(detail, "scale", Vector2(0.98, 0.98), 0.05)
	_invalid_detail_tween.finished.connect(_restore_invalid_detail, CONNECT_ONE_SHOT)


func _restore_invalid_detail() -> void:
	var detail_nodes: Array[Control] = [$KnowledgePanel, $KnowledgeLabel, $KnowledgeSecondaryLabel]
	_invalid_detail_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for detail: Control in detail_nodes:
		_invalid_detail_tween.tween_property(detail, "scale", Vector2.ONE, 0.08)


func _reset_invalid_feedback() -> void:
	if _invalid_chip_tween != null and _invalid_chip_tween.is_valid():
		_invalid_chip_tween.kill()
	if _invalid_detail_tween != null and _invalid_detail_tween.is_valid():
		_invalid_detail_tween.kill()
	$FalseStateChip.scale = Vector2.ONE
	$KnowledgePanel.scale = Vector2.ONE
	$KnowledgeLabel.scale = Vector2.ONE
	$KnowledgeSecondaryLabel.scale = Vector2.ONE


func _pulse_success_feedback() -> void:
	_reset_success_feedback()
	_reset_invalid_feedback()
	var chip: Control = $ValidStateChip
	var detail_nodes: Array[Control] = [$KnowledgePanel, $KnowledgeLabel, $KnowledgeSecondaryLabel]
	chip.pivot_offset = chip.size * 0.5
	for detail: Control in detail_nodes:
		detail.pivot_offset = detail.size * 0.5
	_success_chip_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_success_chip_tween.tween_property(chip, "scale", Vector2(1.05, 1.05), 0.07)
	_success_chip_tween.tween_property(chip, "scale", Vector2.ONE, 0.10)
	_success_detail_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_success_detail_tween.set_parallel(true)
	for detail: Control in detail_nodes:
		_success_detail_tween.tween_property(detail, "scale", Vector2(1.02, 1.02), 0.08)
	_success_detail_tween.set_parallel(false)
	_success_detail_tween.tween_interval(0.08)
	_success_detail_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_success_detail_tween.set_parallel(true)
	for detail: Control in detail_nodes:
		_success_detail_tween.tween_property(detail, "scale", Vector2.ONE, 0.10)


func _reset_success_feedback() -> void:
	if _success_chip_tween != null and _success_chip_tween.is_valid():
		_success_chip_tween.kill()
	if _success_detail_tween != null and _success_detail_tween.is_valid():
		_success_detail_tween.kill()
	$ValidStateChip.scale = Vector2.ONE
	$KnowledgePanel.scale = Vector2.ONE
	$KnowledgeLabel.scale = Vector2.ONE
	$KnowledgeSecondaryLabel.scale = Vector2.ONE


func _on_evidence_pressed(id: StringName) -> void:
	if _transition_locked or _exit_started:
		return
	if not Level1Progress.get_flag(id):
		return
	_animate_evidence_card(id)
	select_evidence(id)


func _animate_evidence_card(id: StringName) -> void:
	var visual: Control = _card_visuals.get(id)
	if visual == null:
		return
	visual.pivot_offset = visual.size * 0.5
	visual.scale = Vector2.ONE
	var previous: Tween = _card_press_tweens.get(id)
	if previous != null and previous.is_valid():
		previous.kill()
	_card_press_tweens[id] = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_card_press_tweens[id].tween_property(visual, "scale", Vector2(0.96, 0.96), 0.05)
	_card_press_tweens[id].set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_card_press_tweens[id].tween_property(visual, "scale", Vector2.ONE, 0.07)


func _on_close_pressed() -> void:
	if _close_press_locked or _transition_locked or _exit_started:
		return
	_close_press_locked = true
	var visual: Control = $CloseButtonVisual
	var label: Control = $CloseButtonLabel
	visual.pivot_offset = visual.size * 0.5
	label.pivot_offset = label.size * 0.5
	var base_visual_scale := visual.scale
	var base_label_scale := label.scale
	if _close_tween != null and _close_tween.is_valid():
		_close_tween.kill()
	_close_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_close_tween.tween_property(visual, "scale", base_visual_scale * 0.94, 0.06)
	_close_tween.tween_property(label, "scale", base_label_scale * 0.94, 0.06)
	await _close_tween.finished
	var restore := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	restore.tween_property(visual, "scale", base_visual_scale, 0.08)
	restore.tween_property(label, "scale", base_label_scale, 0.08)
	await restore.finished
	_play_terminal_exit_and_close()


func _play_terminal_exit_and_close() -> void:
	if _close_requested or _exit_started:
		return
	_exit_started = true
	_set_terminal_interaction_enabled(false)
	if not is_instance_valid(_animation_player):
		close()
		return
	_animation_player.stop()
	_animation_player.play("terminal_exit")
	await _animation_player.animation_finished
	if not _close_requested:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pausa") and not _transition_locked and not _exit_started:
		_play_terminal_exit_and_close()
		get_viewport().set_input_as_handled()


func close() -> void:
	if _close_requested:
		return
	_close_requested = true
	_set_terminal_interaction_enabled(false)
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
