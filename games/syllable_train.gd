extends "res://games/game_view.gd"
## Le train des syllabes : reconstituer le mot en tapant les syllabes
## dans l'ordre (version tap robuste ; le glisser-déposé viendra avec
## l'habillage visuel). Chaque wagon tapé s'ajoute au train.

const GAME_BUTTON := preload("res://ui/components/game_button.tscn")

var _emoji_label: Label
var _target_word: Label
var _wagons_row: HBoxContainer
var _syllable_buttons: HBoxContainer
var _built: Array[String] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	add_child(box)

	_emoji_label = Label.new()
	_emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emoji_label.add_theme_font_size_override("font_size", 100)
	box.add_child(_emoji_label)

	_target_word = Label.new()
	_target_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_word.add_theme_font_size_override("font_size", 28)
	_target_word.text = "Écoute le mot à construire 🔊"
	box.add_child(_target_word)

	_wagons_row = HBoxContainer.new()
	_wagons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_wagons_row.add_theme_constant_override("separation", 16)
	box.add_child(_wagons_row)

	_syllable_buttons = HBoxContainer.new()
	_syllable_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_syllable_buttons.add_theme_constant_override("separation", 24)
	box.add_child(_syllable_buttons)


func present_item(p_item: Resource) -> void:
	super(p_item)
	_built.clear()
	for child in _wagons_row.get_children():
		child.queue_free()
	for child in _syllable_buttons.get_children():
		child.queue_free()
	_emoji_label.text = String(p_item.metadata.get("emoji", "🚂"))
	# Les syllabes proposées = segments de la fiche, mélangés.
	var syls: Array = p_item.segments.duplicate()
	syls.shuffle()
	for i in syls.size():
		var b: Button = GAME_BUTTON.instantiate()
		b.text = String(syls[i])
		b.custom_minimum_size = Vector2(150, 110)
		b.pressed.connect(_make_handler(String(syls[i])))
		_syllable_buttons.add_child(b)
	call_deferred("_apply_access_style", self)


func spoken_prompt(p_item: Resource) -> String:
	return "Construis le mot %s avec les wagons." % p_item.prompt_text


func _make_handler(syl: String) -> Callable:
	return func(): _on_syllable_tapped(syl)


func _on_syllable_tapped(syl: String) -> void:
	_built.append(syl)
	var wagon := Label.new()
	wagon.text = syl
	wagon.add_theme_font_size_override("font_size", 54)
	wagon.add_theme_color_override("font_color", Color("3752ed"))
	_wagons_row.add_child(wagon)
	var item: Resource = self.item
	var full: String = "".join(_built)
	var target: String = item.prompt_text
	if _built.size() >= (item.segments as Array).size():
		# Tous les wagons posés : on soumet le mot reconstitué.
		_on_answer_pressed(full)
		# En cas d'erreur le runner sert un indice ; on nettoie le train
		# pour permettre une nouvelle tentative dans de bonnes conditions.
		if not _accepted(full, target):
			_reset_wagons_only()


func _accepted(built: String, target: String) -> bool:
	return built.strip_edges().to_lower() == target.strip_edges().to_lower()


func _reset_wagons_only() -> void:
	_built.clear()
	for child in _wagons_row.get_children():
		child.queue_free()
