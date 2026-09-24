extends Interactable

@export_enum("record_a", "record_b", "record_c") var record_id: String = "record_a"

const TITLES: Dictionary[String, String] = {
	"record_a": "A · Publicidad Helix (ficción)",
	"record_b": "B · Clasificación interna (ficción)",
	"record_c": "C · Anomalía del archivo (ficción)",
}
const CLUES: Dictionary[String, String] = {
	"record_a": "Helix anuncia acceso público al archivo.",
	"record_b": "El registro interno clasifica ese mismo archivo como restringido.",
	"record_c": "La auditoría detecta la contradicción entre publicidad y clasificación. TODO_CULTURAL: contenido por validar.",
}


func interact(player: Node) -> void:
	super.interact(player)
	Level1Progress.set_flag(StringName(record_id))
	var dialog: InteractionDialog = show_dialog(player, TITLES[record_id], CLUES[record_id])
	dialog.add_choice("Cerrar · volver a explorar", dialog.close)
