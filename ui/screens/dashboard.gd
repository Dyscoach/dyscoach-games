extends Control
const AccessStyle := preload("res://ui/access_style.gd")
## Tableau de bord adulte : suivi bienveillant, sans notes ni comparaison.
## Accès protégé par le coffre (code PIN local si défini).
##
## Rappel affiché à l'écran : ces indicateurs décrivent l'activité DANS
## l'application — ce ne sont ni des tests, ni un diagnostic.

const PrivacyVault := preload("res://core/privacy_vault.gd")

var vault: RefCounted = null


func _ready() -> void:
	AccessStyle.apply(self)
	Access.settings_changed.connect(func(): AccessStyle.apply(self))
	vault = _load_vault()
	if vault.has_pin() and not vault.is_unlocked():
		%PinPanel.show()
		%DashPanel.hide()
	else:
		_show_dashboard()


func _load_vault() -> RefCounted:
	var v := PrivacyVault.new()
	var path := "user://vault.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		var data = JSON.parse_string(f.get_as_text())
		f.close()
		if data is Dictionary:
			v.load_dict(data)
	return v


func _save_vault() -> void:
	var f := FileAccess.open("user://vault.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(vault.to_dict()))
		f.close()


func _on_pin_submitted() -> void:
	if vault.unlock(%PinEdit.text):
		%PinPanel.hide()
		_show_dashboard()
	else:
		%PinError.text = "Code incorrect — réessaie."


func _on_set_pin_pressed() -> void:
	var code: String = %NewPinEdit.text.strip_edges()
	if code.length() < 4:
		%PinError2.text = "Choisis au moins 4 caractères."
		return
	vault.set_pin(code)
	_save_vault()
	%PinError2.text = "Code enregistré ✅"


func _show_dashboard() -> void:
	%DashPanel.show()
	%ProfileLabel.text = "Profil : %s" % (Progress.active_profile.display_name if Progress.active_profile else "aucun")
	var rows: Array = Progress.dashboard_rows()
	var box: VBoxContainer = %RowsBox
	for child in box.get_children():
		child.queue_free()
	if rows.is_empty():
		var empty := Label.new()
		empty.text = "Aucun exercice encore réalisé. Les progrès s'afficheront ici après les premières sessions."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size", 20)
		box.add_child(empty)
		return
	for row in rows:
		box.add_child(_row_panel(row))


func _row_panel(row: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)

	var status := String(row["status"])
	var icon := "🌱" if status == "in_progress" else "🏆"
	var status_txt := "en cours d'acquisition" if status == "in_progress" else "maîtrisée (dans l'app)"

	var title := Label.new()
	title.text = "%s %s — %s" % [icon, String(row["label"]), status_txt]
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hbox.add_child(title)

	var detail := Label.new()
	detail.text = "%d session(s) · %d exercice(s) · niveau %d" % [int(row["sessions"]), int(row["items"]), int(row["level"])]
	detail.add_theme_font_size_override("font_size", 18)
	detail.add_theme_color_override("font_color", Color("555a66"))
	hbox.add_child(detail)

	margin.add_child(hbox)
	panel.add_child(margin)
	return panel


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/home.tscn")


func _on_data_info_pressed() -> void:
	%DataInfo.visible = not %DataInfo.visible
