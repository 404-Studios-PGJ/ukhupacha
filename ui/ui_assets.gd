class_name UIAssets
extends RefCounted
## Shared runtime UI theme and palette access. Mockups are never runtime resources.
const THEME_PATH: String = "res://ui/theme/ukhupacha_theme.tres"
static var _theme: Theme


static func theme_resource() -> Theme:
	if _theme == null:
		_theme = load(THEME_PATH) as Theme
		_theme.default_font = ThemeDB.fallback_font
	return _theme


static func color(token: StringName) -> Color:
	return theme_resource().get_color(token, &"Palette")
