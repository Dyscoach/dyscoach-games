extends Button
## Bouton géant adapté aux enfants : grande zone tactile, gros texte,
## feedback visuel + sonore. Jamais la couleur seule : icône + texte.

const BASE_FONT := 30


func _ready() -> void:
	custom_minimum_size = Vector2(0, 96)
	_apply()
	Access.settings_changed.connect(_apply)
	pressed.connect(func(): AudioMgr.play_click())


func _apply() -> void:
	add_theme_font_size_override("font_size", int(BASE_FONT * Access.font_scale()))
	add_theme_color_override("font_color", Access.text_color())
	add_theme_color_override("font_pressed_color", Access.text_color())
	add_theme_color_override("font_hover_color", Access.text_color())
	add_theme_color_override("font_focus_color", Access.text_color())
