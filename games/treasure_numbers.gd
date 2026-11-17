extends "res://games/game_view.gd"
## Le trésor des nombres : deux coffres, toucher celui qui contient
## le plus de trésors. Les quantités sont affichées en chiffres ET en
## constellation de gemmes (double codage, jamais la couleur seule).

const GAME_BUTTON := preload("res://ui/components/game_button.tscn")

var _prompt_label: Label
var _buttons: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	add_child(box)

	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 32)
	_prompt_label.text = "Quel coffre a le PLUS de trésors ? 👑"
	box.add_child(_prompt_label)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 56)
	box.add_child(_buttons)


func present_item(p_item: Resource) -> void:
	super(p_item)
	for child in _buttons.get_children():
		child.queue_free()
	# Le coffre gagnant = answers[0] ; leurre principal = distractors[0].
	var choices: Array = [String(p_item.answers[0]), String(p_item.distractors[0])]
	choices.shuffle()
	for choice in choices:
		var chest := VBoxContainer.new()
		chest.alignment = BoxContainer.ALIGNMENT_CENTER
		chest.add_theme_constant_override("separation", 8)
		_buttons.add_child(chest)

		var gem_label := Label.new()
		gem_label.text = _gems(int(choice))
		gem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gem_label.add_theme_font_size_override("font_size", 44)
		chest.add_child(gem_label)

		var b: Button = GAME_BUTTON.instantiate()
		b.text = choice
		b.custom_minimum_size = Vector2(180, 120)
		b.pressed.connect(_make_handler(choice))
		chest.add_child(b)
	call_deferred("_apply_access_style", self)


func spoken_prompt(p_item: Resource) -> String:
	return "Touche le coffre qui a le plus de trésors."


func _make_handler(answer: String) -> Callable:
	return func(): _on_answer_pressed(answer)


## Constellation de gemmes : groupes de 5 (repère perceptif canonique).
func _gems(n: int) -> String:
	var out := ""
	var full := n / 5
	var rest := n % 5
	for i in full:
		out += "💎💎💎💎💎\n"
	for i in rest:
		out += "💎"
	return out.strip_edges()
