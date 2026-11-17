extends Control
## Carte des mondes : les univers de jeu et, pour chacun, ses exercices.
## Bouton « C'est parti ! » = session planifiée par le moteur adaptatif
## (révision due → compétence en cours → découverte).

const WorldMap := preload("res://core/world_map.gd")


func _ready() -> void:
	var p := Progress.active_profile
	%HelloLabel.text = "Salut %s ! 👋" % (p.display_name if p != null and not p.display_name.is_empty() else "toi")
	var list: VBoxContainer = %WorldList
	for w in WorldMap.worlds():
		var card := _world_card(w)
		list.add_child(card)


func _world_card(w: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = "%s   %s" % [w.get("icon", "⭐"), w.get("title", "")]
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = String(w.get("subtitle", ""))
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color("555a66"))
	box.add_child(subtitle)

	# Exercices disponibles du profil actif dans ce monde.
	var count := 0
	if Progress.active_profile != null:
		for domain in w["domains"]:
			count += Content.by_domain(domain).size()
	var info := Label.new()
	info.text = "%d jeu(x) disponible(s)" % count
	info.add_theme_font_size_override("font_size", 18)
	box.add_child(info)

	margin.add_child(box)
	panel.add_child(margin)
	panel.modulate = Color(String(w.get("color", "#888888"))).lerp(Color.WHITE, 0.82)
	return panel


func _on_play_pressed() -> void:
	if App.start_planned_session():
		get_tree().change_scene_to_file("res://games/exercise_host.tscn")
	else:
		%PlayButton.text = "Aucun jeu disponible pour ton âge"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/home.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/settings.tscn")
