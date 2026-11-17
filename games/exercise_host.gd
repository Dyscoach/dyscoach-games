extends Control
## ExerciseHost — écran générique d'exécution d'une session : barre de
## progression, consigne, vue du jeu, feedback, pause et abandon.
## UNE SEULE scène pour TOUS les exercices : la vue est chargée selon la fiche.

## Registre fiche → vue. Ajouter un exercice = une ligne ici + sa scène.
const AccessStyle := preload("res://ui/access_style.gd")
const VIEW_SCENES := {
	"lec.detective_sons": "res://games/detective_sons.tscn",
	"lec.grapheme_phoneme": "res://games/grapheme_phoneme.tscn",
	"lec.train_syllabes": "res://games/syllable_train.tscn",
	"math.tresor_nombres": "res://games/treasure_numbers.tscn",
	"espace.robot_a_guider": "res://games/robot_guide.tscn",
}

var runner: RefCounted = null
var def: Resource = null
var view = null


func _ready() -> void:
	runner = App.current_runner()
	def = App.current_def
	if runner == null or def == null:
		_go_home()
		return
	var view_path: String = VIEW_SCENES.get(def.exercise_id, "")
	if view_path.is_empty() or not ResourceLoader.exists(view_path):
		push_error("Aucune vue pour l'exercice %s" % def.exercise_id)
		_go_home()
		return
	view = load(view_path).instantiate()
	%ViewHolder.add_child(view)
	view.answer_submitted.connect(_on_answer)
	view.hint_requested.connect(func(): runner.request_hint())

	%TitleLabel.text = def.display_name
	%InstructionLabel.text = def.instruction_text
	AccessStyle.apply(self)
	Access.settings_changed.connect(func(): AccessStyle.apply(self))

	runner.item_presented.connect(_on_item)
	runner.feedback.connect(_on_feedback)
	runner.session_finished.connect(_on_finished)
	runner.start()
	AudioMgr.speak(def.instruction_text, def.instruction_text)


func _on_item(p_item: Resource) -> void:
	%ProgressLabel.text = "%d / %d" % [runner.progress().x, runner.progress().y]
	%FeedbackLabel.text = ""
	view.present_item(p_item)
	if def.interaction == "listen":
		AudioMgr.speak(view.spoken_prompt(p_item), p_item.prompt_text)


func _on_answer(answer: String) -> void:
	runner.submit_answer(answer)


func _on_feedback(ok: bool, message: String, kind: String) -> void:
	match kind:
		"correct":
			%FeedbackLabel.text = "✓ " + message
			%FeedbackLabel.add_theme_color_override("font_color", Access.color_correct())
			AudioMgr.play_success()
		"error_hint":
			%FeedbackLabel.text = "✗ " + message
			%FeedbackLabel.add_theme_color_override("font_color", Access.color_error())
			AudioMgr.play_error()
		"hint":
			%FeedbackLabel.text = "💡 " + message
			%FeedbackLabel.add_theme_color_override("font_color", Access.text_color())
			AudioMgr.play_hint()
		"solved_show":
			%FeedbackLabel.text = "✨ " + message
			%FeedbackLabel.add_theme_color_override("font_color", Access.text_color())
			AudioMgr.play_hint()


func _on_finished(stats: Dictionary) -> void:
	var total: int = int(stats.get("items", 0))
	var wins: int = int(stats.get("auto_successes", 0)) + int(stats.get("hint_solves", 0))
	%EndPanel.show()
	%EndLabel.text = "Bravo, tu as travaillé %d exercice(s) et réussi %d !\nOn est fiers de toi." % [total, wins]
	%EndLabel.text += "\n(Tu peux continuer une autre fois.)" if total == 0 else ""
	AudioMgr.play_success()


func _on_pause_pressed() -> void:
	App.pause()
	AudioMgr.stop_speaking()
	%PauseOverlay.show()


func _on_resume_pressed() -> void:
	App.resume()
	%PauseOverlay.hide()


func _on_quit_pressed() -> void:
	App.stop_session()
	_go_home()


func _on_repeat_pressed() -> void:
	AudioMgr.speak(def.instruction_text, def.instruction_text)


func _go_home() -> void:
	get_tree().change_scene_to_file("res://ui/screens/home.tscn")
