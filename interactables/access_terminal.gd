extends Interactable

const RecordScript = preload("res://interactables/record_terminal.gd")
var feedback: String = ""


func _ready() -> void:
	super._ready()
	Level1Progress.progress_reset.connect(_on_reset)


func _on_reset() -> void:
	feedback = ""


func submit_answer(relation: StringName) -> bool:
	if not Level1Progress.all_records_read():
		feedback = "Faltan evidencias. Lee los registros A, B y C en cualquier orden."
		return false
	if relation != &"contradiction":
		feedback = "Pista: compara el acceso público anunciado con la clasificación restringida."
		return false
	Level1Progress.set_flag(&"puzzle_solved")
	feedback = "Contradicción documentada. Puerta 1 abierta. TODO_CULTURAL: validar contenido."
	return true


func interact(player: Node) -> void:
	super.interact(player)
	var initial: String = "Relaciona publicidad, clasificación y anomalía. Puedes releer cada evidencia."
	if Level1Progress.get_flag(&"puzzle_solved"):
		initial = "Puzzle resuelto. Puerta 1 abierta. Puedes releer las evidencias."
	var dialog: InteractionDialog = show_dialog(player, "Terminal de acceso · tres evidencias", initial)
	for record_id: String in ["record_a", "record_b", "record_c"]:
		var read: bool = Level1Progress.get_flag(StringName(record_id))
		var button: Button = dialog.add_choice(
			RecordScript.TITLES[record_id] if read else "Evidencia pendiente",
			func() -> void: dialog.set_body(RecordScript.CLUES[record_id]))
		button.disabled = not read
	dialog.add_choice("Relacionar: los tres registros confirman acceso público",
		func() -> void:
			submit_answer(&"agreement")
			dialog.set_body(feedback))
	dialog.add_choice("Relacionar: la anomalía revela una contradicción",
		func() -> void:
			submit_answer(&"contradiction")
			dialog.set_body(feedback))
	dialog.add_choice("Cerrar · volver a explorar", dialog.close)
