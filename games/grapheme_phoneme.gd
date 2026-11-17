extends "res://games/game_view.gd"
## La machine à sons : le son est prononcé, toucher la bonne lettre
## parmi 4 (réponse + 3 leurres de la fiche).

const GAME_BUTTON := preload("res://ui/components/game_button.tscn")

var _sound_label: Label
var _word_label: Label
var _buttons: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	add_child(box)

	_sound_label = Label.new()
	_sound_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sound_label.add_theme_font_size_override("font_size", 96)
	box.add_child(_sound_label)

	_word_label = Label.new()
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word_label.add_theme_font_size_override("font_size", 34)
	_word_label.text = "« … comme dans … »"
	box.add_child(_word_label)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 32)
	box.add_child(_buttons)


func present_item(p_item: Resource) -> void:
	super(p_item)
	_sound_label.text = "🔊 [%s]" % p_item.metadata.get("sound", p_item.prompt_text)
	_word_label.text = "comme dans %s %s" % [String(p_item.metadata.get("mot", "")), String(p_item.metadata.get("emoji", ""))]
	_rebuild_buttons(p_item)
	_apply_access_style(self)


func spoken_prompt(p_item: Resource) -> String:
	return "Quel est le son %s ? Touche la lettre." % String(p_item.metadata.get("sound", ""))


func _rebuild_buttons(p_item: Resource) -> void:
	for child in _buttons.get_children():
		child.queue_free()
	var choices: Array = [p_item.answers[0]]
	for d in p_item.distractors:
		choices.append(d)
	choices.shuffle()
	for i in choices.size():
		var b: Button = GAME_BUTTON.instantiate()
		b.text = String(choices[i])
		b.custom_minimum_size = Vector2(150, 120)
		b.pressed.connect(_make_handler(String(choices[i])))
		_buttons.add_child(b)
	# Les boutons sont recréés : on force la taille de police accessible.
	call_deferred("_apply_access_style", self)


func _make_handler(answer: String) -> Callable:
	return func(): _on_answer_pressed(answer)
