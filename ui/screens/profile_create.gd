extends Control
const AccessStyle := preload("res://ui/access_style.gd")
## Création de profil : prénom (optionnel), âge, choix des domaines
## (plusieurs possibles — aucune étiquette). Tout est local.

const ExerciseDefinition := preload("res://core/exercise_definition.gd")

const DOMAIN_LABELS := {
	ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE: "🔤 Lettres et lecture",
	ExerciseDefinition.DOMAIN_SPELLING: "✏️ Orthographe",
	ExerciseDefinition.DOMAIN_MATH: "🔢 Nombres et calcul",
	ExerciseDefinition.DOMAIN_COORDINATION_SPACE: "🧭 Formes et repères",
	ExerciseDefinition.DOMAIN_ORAL_LANGUAGE: "💬 Mots et histoires",
	ExerciseDefinition.DOMAIN_ATTENTION_EXECUTIVE: "🧩 Attention et mémoire",
}


func _ready() -> void:
	AccessStyle.apply(self)
	Access.settings_changed.connect(func(): AccessStyle.apply(self))
	var box: VBoxContainer = %DomainsBox
	for domain in ExerciseDefinition.DOMAINS:
		var cb := CheckBox.new()
		cb.text = DOMAIN_LABELS.get(domain, domain)
		cb.add_theme_font_size_override("font_size", 22)
		cb.custom_minimum_size = Vector2(0, 56)
		cb.toggled.connect(func(_on): AudioMgr.play_click())
		cb.set_meta("domain", domain)
		box.add_child(cb)
	%AgeSlider.value_changed.connect(func(_v): %AgeValue.text = "%d ans" % int(%AgeSlider.value))


func _on_create_pressed() -> void:
	var display_name: String = %NameEdit.text.strip_edges()
	var age := int(%AgeSlider.value)
	var p := Progress.create_profile(display_name, age)
	for cb in %DomainsBox.get_children():
		if cb is CheckBox and cb.button_pressed:
			p.selected_domains.append(String(cb.get_meta("domain")))
	Progress.save_profile(p)
	Progress.select_profile(p)
	get_tree().change_scene_to_file("res://ui/screens/worlds.tscn")


func _on_cancel_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/home.tscn")
