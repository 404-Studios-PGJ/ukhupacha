class_name UIAssets
extends RefCounted
## Único catálogo de texturas runtime. Los mockups nunca son recursos del juego.
const THEME_PATH: String = "res://ui/theme/ukhupacha_theme.tres"
const INK_SHADER: Shader = preload("res://ui/theme/ink.gdshader")
const PATHS: Dictionary[StringName, String] = {
	&"frame": "res://assets/ui/panels/UI_Flat_Frame02a.png",
	&"banner": "res://assets/ui/panels/UI_Flat_Banner03a.png",
	&"knowledge": "res://assets/ui/panels/UI_TravelBook_Popup01a.png",
	&"button_normal": "res://assets/ui/buttons/UI_Flat_Button01a_1.png",
	&"button_hover": "res://assets/ui/buttons/UI_Flat_Button01a_2.png",
	&"button_pressed": "res://assets/ui/buttons/UI_Flat_Button01a_3.png",
	&"button_disabled": "res://assets/ui/buttons/UI_Flat_Button01a_4.png",
	&"play": "res://assets/ui/buttons/UI_Flat_ButtonPlay01a.png",
	&"check": "res://assets/ui/icons/UI_Flat_IconCheck01a.png",
	&"cross": "res://assets/ui/icons/UI_Flat_IconCross01a.png",
	&"heart": "res://assets/ui/icons/UI_TravelBook_IconHeart01a.png",
	&"energy": "res://assets/ui/icons/UI_TravelBook_IconEnergy01a.png",
	&"star": "res://assets/ui/icons/UI_TravelBook_IconStar01a.png",
	&"marker": "res://assets/ui/decorations/UI_TravelBook_Marker01a.png",
	&"line": "res://assets/ui/decorations/UI_TravelBook_Line01a.png",
	&"point": "res://assets/ui/decorations/UI_TravelBook_Point01a.png",
	&"slot": "res://assets/ui/slots/UI_Flat_FrameSlot01a.png",
	&"slot_hover": "res://assets/ui/slots/UI_Flat_FrameSlot01b.png",
	&"slot_disabled": "res://assets/ui/slots/UI_Flat_FrameSlot01c.png",
	&"selected": "res://assets/ui/slots/UI_Flat_Select01a_2.png",
	&"bar": "res://assets/ui/bars/UI_Flat_Bar01a.png",
	&"fill": "res://assets/ui/bars/UI_Flat_BarFill01a.png",
	&"fill_health": "res://assets/ui/bars/UI_Flat_BarFill01c.png",
	&"press": "res://assets/ui/prompts/UI_TravelBook_CommandPress01a.png",
}
static var _theme: Theme
static var _inks: Dictionary[StringName, ShaderMaterial] = {}


static func ink(token: StringName) -> ShaderMaterial:
	if not _inks.has(token):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = INK_SHADER
		material.set_shader_parameter("ink", color(token))
		_inks[token] = material
	return _inks[token]


static func texture(id: StringName) -> Texture2D:
	if not PATHS.has(id):
		return null
	return load(PATHS[id]) as Texture2D


static func theme_resource() -> Theme:
	if _theme == null:
		_theme = load(THEME_PATH) as Theme
		_theme.default_font = ThemeDB.fallback_font
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
			var style: StyleBoxTexture = _theme.get_stylebox(state, &"PrimaryButton") as StyleBoxTexture
			style.texture = texture(StringName("button_" + state))
		(_theme.get_stylebox(&"panel", &"Dossier") as StyleBoxTexture).texture = texture(&"frame")
		(_theme.get_stylebox(&"panel", &"Knowledge") as StyleBoxTexture).texture = texture(&"knowledge")
	return _theme


static func color(token: StringName) -> Color:
	return theme_resource().get_color(token, &"Palette")
