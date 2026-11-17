extends "res://games/game_view.gd"
## Quiz générique à boutons : la fiche fournit la question (prompt_text,
## avec « ___ » pour les trous) et réponses/leurres. Mécanique réutilisable
## pour les homophones, le calcul, la conjugaison, le vocabulaire…

const GAME_BUTTON := preload("res://ui/components/game_button.tscn")

var _prompt_label: Label
var _buttons_grid: GridContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	add_child(box)

	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.custom_minimum_size = Vector2(900, 130)
	_prompt_label.add_theme_font_size_override("font_size", 46)
	box.add_child(_prompt_label)

	var center := CenterContainer.new()
	box.add_child(center)
	_buttons_grid = GridContainer.new()
	_buttons_grid.columns = 2
	_buttons_grid.add_theme_constant_override("h_separation", 28)
	_buttons_grid.add_theme_constant_override("v_separation", 20)
	center.add_child(_buttons_grid)


func present_item(p_item: Resource) -> void:
	super(p_item)
	_prompt_label.text = p_item.prompt_text
	for child in _buttons_grid.get_children():
		child.queue_free()
	var choices: Array = [String(p_item.answers[0])]
	for d in p_item.distractors:
		choices.append(String(d))
	choices.shuffle()
	for choice in choices:
		var b: Button = GAME_BUTTON.instantiate()
		b.text = choice
		b.custom_minimum_size = Vector2(240, 120)
		b.pressed.connect(_make_handler(choice))
		_buttons_grid.add_child(b)
	call_deferred("_apply_access_style", self)


func spoken_prompt(p_item: Resource) -> String:
	return "Complète : %s" % p_item.prompt_text


func _make_handler(answer: String) -> Callable:
	return func(): _on_answer_pressed(answer)
