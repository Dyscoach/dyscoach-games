extends Button
## Carte de profil enfant : prénom, avatar couleur, bouton jouer.
## Un appui long (ou bouton ⋯) permet la suppression par l'adulte
## (avec confirmation) — données locales uniquement.

var profile: RefCounted = null


func setup(p: RefCounted) -> void:
	profile = p
	var name_shown: String = p.display_name if not p.display_name.is_empty() else "Joueur"
	text = "🧒 %s (%d ans)" % [name_shown, p.age]
	modulate = Color(String(p.avatar_color)).lerp(Color.WHITE, 0.55)
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	Progress.select_profile(profile)
	get_tree().change_scene_to_file("res://ui/screens/worlds.tscn")
