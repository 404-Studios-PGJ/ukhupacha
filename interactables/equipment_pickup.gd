extends Interactable

@export_enum("sword", "axe", "shield") var equipment_id: String = "sword"


func _ready() -> void:
	super._ready()
	Level1Progress.flag_changed.connect(_on_flag_changed)
	Level1Progress.progress_reset.connect(_refresh)
	_refresh()


func is_available() -> bool:
	return not Level1Progress.get_flag(StringName("has_" + equipment_id))


func interact(player: Node) -> void:
	if not is_available():
		return
	var method: StringName = &"equip_shield" if equipment_id == "shield" else &"equip_weapon"
	if not player.has_method(method):
		var dialog: InteractionDialog = show_dialog(player, "Equipo Helix", "Player pendiente de migración: equipo conservado para recoger después.")
		dialog.add_choice("Cerrar", dialog.close)
		return
	super.interact(player)
	if equipment_id == "shield":
		player.call(method)
	else:
		player.call(method, StringName(equipment_id))
	Level1Progress.set_flag(StringName("has_" + equipment_id))
	MusicDirector.play_sfx(&"pickup")


func _on_flag_changed(_flag: StringName, _value: bool) -> void:
	_refresh()


func _refresh() -> void:
	visible = is_available()
