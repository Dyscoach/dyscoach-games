extends Control
const AccessStyle := preload("res://ui/access_style.gd")
## Réglages d'accessibilité — fonctionnalité CŒUR (cahier des charges §5).
## Chaque réglage s'applique immédiatement (signal settings_changed) et
## se sauvegarde dans le profil actif.

func _ready() -> void:
	AccessStyle.apply(self)
	Access.settings_changed.connect(func(): AccessStyle.apply(self))
	%FontSizeSlider.value = int(Access.get_setting(Access.KEY_FONT_SIZE, 1))
	%LetterSlider.value = float(Access.get_setting(Access.KEY_LETTER_SPACING, 1.0))
	%LineSlider.value = float(Access.get_setting(Access.KEY_LINE_SPACING, 1.0))
	%ContrastCheck.button_pressed = bool(Access.get_setting(Access.KEY_HIGH_CONTRAST, false))
	%PlainBgCheck.button_pressed = bool(Access.get_setting(Access.KEY_PLAIN_BACKGROUND, false))
	%ReduceMotionCheck.button_pressed = bool(Access.get_setting(Access.KEY_REDUCE_MOTION, false))
	%ReduceEffectsCheck.button_pressed = bool(Access.get_setting(Access.KEY_REDUCE_EFFECTS, false))
	%SubtitlesCheck.button_pressed = bool(Access.get_setting(Access.KEY_SUBTITLES, true))
	%VolumeSlider.value = float(Access.get_setting(Access.KEY_AUDIO_VOLUME, 0.8))
	%VoiceRateSlider.value = float(Access.get_setting(Access.KEY_VOICE_RATE, 1.0))
	match String(Access.get_setting(Access.KEY_FONT, "defaut")):
		"lisible": %FontLisible.button_pressed = true
		"dys": %FontDys.button_pressed = true
		_: %FontDefaut.button_pressed = true
	%FontDefaut.toggled.connect(func(on): if on: Access.set_setting(Access.KEY_FONT, "defaut"))
	%FontLisible.toggled.connect(func(on): if on: Access.set_setting(Access.KEY_FONT, "lisible"))
	%FontDys.toggled.connect(func(on): if on: Access.set_setting(Access.KEY_FONT, "dys"))
	_refresh_labels()
	AudioMgr.play_hint()  # retour sonore léger pour vérifier le volume


func _refresh_labels() -> void:
	%FontSizeValue.text = ["Petit", "Moyen", "Grand", "Très grand"][int(%FontSizeSlider.value)]
	%VolumeValue.text = "%d %%" % int(%VolumeSlider.value * 100)
	%VoiceRateValue.text = "×%.1f" % %VoiceRateSlider.value


func _on_font_size_changed(v: float) -> void:
	Access.set_setting(Access.KEY_FONT_SIZE, int(v))
	_refresh_labels()


func _on_letter_changed(v: float) -> void:
	Access.set_setting(Access.KEY_LETTER_SPACING, clampf(v, 1.0, 2.0))


func _on_line_changed(v: float) -> void:
	Access.set_setting(Access.KEY_LINE_SPACING, clampf(v, 1.0, 2.0))


func _on_contrast_toggled(on: bool) -> void:
	Access.set_setting(Access.KEY_HIGH_CONTRAST, on)


func _on_plain_bg_toggled(on: bool) -> void:
	Access.set_setting(Access.KEY_PLAIN_BACKGROUND, on)


func _on_reduce_motion_toggled(on: bool) -> void:
	Access.set_setting(Access.KEY_REDUCE_MOTION, on)


func _on_reduce_effects_toggled(on: bool) -> void:
	Access.set_setting(Access.KEY_REDUCE_EFFECTS, on)


func _on_subtitles_toggled(on: bool) -> void:
	Access.set_setting(Access.KEY_SUBTITLES, on)


func _on_volume_changed(v: float) -> void:
	Access.set_setting(Access.KEY_AUDIO_VOLUME, clampf(v, 0.0, 1.0))
	_refresh_labels()


func _on_voice_rate_changed(v: float) -> void:
	Access.set_setting(Access.KEY_VOICE_RATE, clampf(v, 0.5, 1.5))
	_refresh_labels()



func _on_save_pressed() -> void:
	if Progress.active_profile != null:
		Access.export_to_profile(Progress.active_profile)
		Progress.save_profile(Progress.active_profile)
	get_tree().change_scene_to_file("res://ui/screens/home.tscn")
