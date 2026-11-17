extends Control
## Écran d'accueil : choix du profil (ou création), puis carte des mondes.
const AccessStyle := preload("res://ui/access_style.gd")
## Aucun chronomètre, aucune compétition — juste « Jouer ».

const ChildCard := preload("res://ui/components/child_card.tscn")


func _ready() -> void:
	%VersionLabel.text = "Dyscoach Jeux — outil d'accompagnement pédagogique"
	if Progress.profiles.is_empty():
		%NoProfileLabel.show()
	else:
		%NoProfileLabel.hide()
	for child in %ProfileList.get_children():
		child.queue_free()
	for p in Progress.profiles:
		var card := ChildCard.instantiate()
		%ProfileList.add_child(card)
		card.setup(p)
	AccessStyle.apply(self)
	Access.settings_changed.connect(func(): AccessStyle.apply(self))


func _on_new_profile_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/profile_create.tscn")



func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/settings.tscn")


func _on_adult_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/dashboard.tscn")
