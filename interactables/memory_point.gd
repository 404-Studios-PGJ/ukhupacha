extends Interactable

@export_multiline var memory_text: String = "TODO_CULTURAL: nombre del conocimiento y fuente oficial.\nTODO_CULTURAL: descripción factual validada por Nayeli.\nTODO_CULTURAL: distinguir este hecho de la ficción Helix."


func register_memory() -> void:
	Level1Progress.set_flag(&"memory_restored")


func interact(player: Node) -> void:
	super.interact(player)
	var dialog: InteractionDialog = show_dialog(player, "Memoria · lectura y protección", memory_text)
	dialog.add_choice("Registrar y proteger",
		func() -> void:
			register_memory()
			dialog.set_body("Memoria registrada. Puerta 4 abierta.\n" + memory_text))
	dialog.add_choice("Cerrar", dialog.close)
