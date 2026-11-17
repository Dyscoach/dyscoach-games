class_name AccessStyle
## Application centralisée des réglages d'accessibilité à une sous-arborescence :
## taille de police, interligne, couleurs. Utilisée par les écrans et les vues.
##
## Styles CLAIRS explicites (fond crème de l'app, texte foncé) : indépendants
## du thème sombre par défaut de certains contrôles Godot.

static func apply(node: Node) -> void:
	var fg := Access.text_color()
	if node is Label:
		var l := node as Label
		if not l.has_meta("a_base_fs"):
			var base_fs: int = l.get_theme_font_size("font_size")
			if base_fs <= 0:
				base_fs = 20
			l.set_meta("a_base_fs", base_fs)
		var base: int = l.get_meta("a_base_fs")
		l.add_theme_font_size_override("font_size", int(float(base) * Access.font_scale()))
		l.add_theme_constant_override("line_spacing", int(6.0 * float(Access.get_setting(Access.KEY_LINE_SPACING, 1.0))))
		l.add_theme_color_override("font_color", fg)
	elif node is LineEdit:
		var le := node as LineEdit
		var field := StyleBoxFlat.new()
		field.bg_color = Color("ffffff")
		field.set_border_width_all(2)
		field.border_color = Color("8a8578")
		field.set_corner_radius_all(10)
		field.content_margin_left = 14
		field.content_margin_right = 14
		field.content_margin_top = 10
		field.content_margin_bottom = 10
		le.add_theme_stylebox_override("normal", field)
		le.add_theme_color_override("font_color", fg)
		le.add_theme_color_override("font_placeholder_color", Color("6f6a5e"))
	elif node is Button:
		var b := node as Button
		if not b.has_meta("a_base_fs"):
			var bfs: int = b.get_theme_font_size("font_size")
			if bfs <= 0:
				bfs = 16
			b.set_meta("a_base_fs", bfs)
		var bbase: int = b.get_meta("a_base_fs")
		b.add_theme_font_size_override("font_size", int(float(bbase) * Access.font_scale()))
		b.add_theme_color_override("font_color", fg)
		b.add_theme_color_override("font_pressed_color", fg)
		b.add_theme_color_override("font_hover_color", fg)
		b.add_theme_color_override("font_focus_color", fg)
		if not (b is CheckBox):
			# CheckBox garde son style natif (coche) — juste le texte coloré.
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("ffffff")
			sb.set_border_width_all(2)
			sb.border_color = fg
			sb.set_corner_radius_all(12)
			sb.set_content_margin_all(14)
			var pressed := sb.duplicate()
			pressed.bg_color = Color("e8e4da")
			b.add_theme_stylebox_override("normal", sb)
			b.add_theme_stylebox_override("hover", sb.duplicate())
			b.add_theme_stylebox_override("pressed", pressed)
			b.add_theme_stylebox_override("focus", sb.duplicate())
	for child in node.get_children():
		apply(child)
