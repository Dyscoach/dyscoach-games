class_name AccessStyle
## Application centralisée des réglages d'accessibilité à une sous-arborescence :
## taille de police, interligne, couleurs. Utilisée par les écrans et les vues.

static func apply(node: Node) -> void:
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
		l.add_theme_color_override("font_color", Access.text_color())
	elif node is Button:
		# CheckBox hérite de Button : texte foncé lisible sur fond clair.
		var b := node as Button
		if not b.has_meta("a_base_fs"):
			var bfs: int = b.get_theme_font_size("font_size")
			if bfs <= 0:
				bfs = 16
			b.set_meta("a_base_fs", bfs)
		var bbase: int = b.get_meta("a_base_fs")
		b.add_theme_font_size_override("font_size", int(float(bbase) * Access.font_scale()))
		b.add_theme_color_override("font_color", Access.text_color())
		b.add_theme_color_override("font_pressed_color", Access.text_color())
		b.add_theme_color_override("font_hover_color", Access.text_color())
		b.add_theme_color_override("font_focus_color", Access.text_color())
	for child in node.get_children():
		apply(child)
