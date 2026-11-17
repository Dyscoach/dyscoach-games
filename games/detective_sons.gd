extends "res://games/game_view.gd"
## Le détective des sons : entends-tu [a] dans ce mot ? OUI / NON.
## Gros boutons avec icônes ✓/✗ — la couleur n'est jamais seule.

const GAME_BUTTON := preload("res://ui/components/game_button.tscn")

var _word_label: Label
var _emoji_label: Label
var _yes_button: Button
var _no_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	add_child(box)

	_emoji_label = Label.new()
	_emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emoji_label.add_theme_font_size_override("font_size", 110)
	_emoji_label.text = "🔎"
	box.add_child(_emoji_label)

	_word_label = Label.new()
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word_label.add_theme_font_size_override("font_size", 64)
	box.add_child(_word_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 48)
	box.add_child(buttons)

	_yes_button = GAME_BUTTON.instantiate()
	_yes_button.text = "✓ OUI"
	_yes_button.modulate = Color(0.55, 0.8, 0.65)
	_yes_button.pressed.connect(func(): _on_answer_pressed("oui"))
	buttons.add_child(_yes_button)

	_no_button = GAME_BUTTON.instantiate()
	_no_button.text = "✗ NON"
	_no_button.modulate = Color(0.9, 0.65, 0.62)
	_no_button.pressed.connect(func(): _on_answer_pressed("non"))
	buttons.add_child(_no_button)


func present_item(p_item: Resource) -> void:
	super(p_item)
	_word_label.text = p_item.prompt_text
	_emoji_label.text = String(p_item.metadata.get("emoji", "🔎"))
	_apply_access_style(self)


func spoken_prompt(p_item: Resource) -> String:
	return "Est-ce que tu entends le son a dans %s ?" % p_item.prompt_text
