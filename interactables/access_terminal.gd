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
	if is_instance_valid(_dialog):
		_dialog.close()
	_dialog = DialogScript.instantiate() as InteractionDialog
	add_child(_dialog)
	_dialog.setup_puzzle(player, self)
