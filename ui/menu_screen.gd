class_name MenuScreen
extends Control

signal action_requested(action: StringName)
@export_enum("main", "pause", "controls", "death", "ending") var screen_id: String = "main"
var default_focus: Button


func _ready() -> void:
	UIBuild.screen(self)
	UIBuild.panel(self, Rect2(0, 0, 640, 360))
	match screen_id:
		"main":
			_build_main()
		"pause":
			_build_pause()
		"controls":
			_build_controls()
		"death":
			_build_message("EXPEDICIÓN INTERRUMPIDA", "Puedes volver a intentarlo.", "Reintentar", &"retry")
		"ending":
			_build_message("Continuará", "El rescate de tu familia sigue pendiente.", "Menú principal", &"menu")
	UIBuild.footer(self, "UKHUPACHA / " + screen_id.to_upper())
	if default_focus != null:
		default_focus.grab_focus()


func _geometry(kind: String, bounds: Rect2) -> void:
	var geometry: HybridGeometry = HybridGeometry.new()
	geometry.kind = kind
	UIBuild.place(geometry, self, bounds)


func _action(id: StringName) -> void:
	action_requested.emit(id)


func _build_main() -> void:
	_geometry("architecture", Rect2(0, 0, 640, 360))
	_geometry("title", Rect2(40, 32, 380, 64))
	UIBuild.label(self, "UKHUPACHA", Rect2(62, 30, 312, 38), &"Title")
	UIBuild.label(self, "EXPEDICIÓN HELIX / ARCHIVO 01", Rect2(64, 73, 300, 18), &"Muted")
	UIBuild.icon(self, &"star", Rect2(374, 45, 24, 22), &"ukhu_purple")
	UIBuild.icon(self, &"line", Rect2(148, 99, 120, 8), &"gold")
	UIBuild.icon(self, &"point", Rect2(48, 98, 10, 10), &"ukhu_purple")
	UIBuild.label(self, "INICIAR DESCENSO", Rect2(58, 140, 220, 18), &"Accent")
	default_focus = UIBuild.button(self, "NUEVA PARTIDA", Rect2(54, 164, 270, 48), _action.bind(&"new_game"), true)
	default_focus.name = "NewGame"
	UIBuild.icon(self, &"play", Rect2(68, 180, 17, 16), &"light_gold")
	UIBuild.button(self, "CONTROLES", Rect2(54, 225, 126, 34), _action.bind(&"controls")).name = "Controls"
	UIBuild.button(self, "SALIR", Rect2(194, 225, 126, 34), _action.bind(&"quit")).name = "Quit"
	_geometry("helix", Rect2(398, 104, 208, 188))


func _build_pause() -> void:
	UIBuild.rule(self, Rect2(0, 0, 640, 360), &"dim")
	_geometry("pause", Rect2(0, 0, 474, 153))
	UIBuild.label(self, "OPERACIONES DE CAMPO", Rect2(50, 45, 300, 20), &"Muted")
	UIBuild.label(self, "PAUSA", Rect2(50, 78, 340, 40), &"Title")
	UIBuild.rule(self, Rect2(52, 122, 298, 1))
	UIBuild.label(self, "H-01", Rect2(474, 34, 100, 34), &"Heading")
	UIBuild.icon(self, &"star", Rect2(566, 43, 12, 11), &"ukhu_purple")
	default_focus = UIBuild.button(self, "REANUDAR EXPEDICIÓN", Rect2(52, 183, 298, 50), _action.bind(&"close"), true)
	default_focus.name = "Resume"
	UIBuild.icon(self, &"play", Rect2(65, 201, 17, 16), &"light_gold")
	var row: HBoxContainer = HBoxContainer.new()
	UIBuild.place(row, self, Rect2(52, 252, 424, 36))
	for entry: Array in [["Controles", &"controls"], ["Reintentar", &"retry"], ["Menú principal", &"menu"]]:
		var button: Button = UIBuild.button(row, entry[0], Rect2(0, 0, 130, 36), _action.bind(entry[1]))
		button.custom_minimum_size = Vector2(130, 36)
	UIBuild.rule(self, Rect2(52, 302, 424, 1), &"outline")
	UIBuild.label(self, "SESIÓN EN PAUSA / NODO HELIX", Rect2(52, 311, 440, 18), &"Small")


func _build_controls() -> void:
	UIBuild.header(self, "CONTROLES", "EXPEDICIÓN / 01")
	UIBuild.panel(self, Rect2(24, 64, 592, 220), &"Dossier")
	var rows: VBoxContainer = VBoxContainer.new()
	UIBuild.place(rows, self, Rect2(42, 78, 556, 192))
	for text: String in [
		"WASD · Mover     Shift · Correr     E · Interactuar",
		"LMB · Atacar     RMB · Defender     Space · Esquivar",
		"Tab · Equipo     Esc · Pausa / Volver",
		"Blanco · Parry posible     Rojo · Esquiva obligatoria",
		"Parry correcto: 95 % éxito; queda un 5 % de fallo residual.",
		"Error de timing: ×1,25 daño durante 0,30 s de recuperación.",
		"Tras parry: próximo golpe al enemigo aturdido ×2 (1 s).",
	]:
		UIBuild.label(rows, text, Rect2(0, 0, 556, 20))
	default_focus = UIBuild.button(self, "VOLVER", Rect2(430, 300, 184, 32), _action.bind(&"back"), true)


func _build_message(title: String, body: String, action_text: String, action: StringName) -> void:
	_geometry("architecture", Rect2(0, 0, 640, 360))
	_geometry("title", Rect2(36, 52, 550, 96))
	UIBuild.label(self, title, Rect2(56, 76, 504, 38), &"Heading")
	UIBuild.label(self, body, Rect2(56, 172, 528, 36))
	default_focus = UIBuild.button(self, action_text, Rect2(56, 232, 270, 48), _action.bind(action), true)
	if screen_id == "death":
		UIBuild.button(self, "Menú principal", Rect2(346, 238, 230, 36), _action.bind(&"menu"))
