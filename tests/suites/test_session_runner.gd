extends RefCounted
## Tests du runner de session (core/session_runner.gd) :
## déroulé d'une session, feedback progressif, abandon, stats finales.

const SessionRunner := preload("res://core/session_runner.gd")
const ExerciseDefinition := preload("res://core/exercise_definition.gd")
const ExerciseItem := preload("res://core/exercise_item.gd")

var fw: RefCounted


func _def() -> Resource:
	var d: Resource = ExerciseDefinition.new()
	d.exercise_id = "test.runner"
	d.display_name = "Runner"
	d.domain = ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE
	d.skill = "fusion_sons"
	d.instruction_text = "Assemble les sons."
	d.scene_path = "res://games/placeholder.tscn"
	d.adaptive_params = {"max_attempts_per_item": 2}
	return d


func _item(id: String, word: String) -> Resource:
	var it: Resource = ExerciseItem.new()
	it.item_id = id
	it.prompt_text = "Compose « " + word + " »"
	it.add_answer(word)
	it.add_hint("Écoute le premier son.")
	it.add_hint("Il commence par « " + word.substr(0, 1) + " ».")
	return it


func _runner(words: Array) -> SessionRunner:
	var d := _def()
	for i in words.size():
		d.add_item(_item("i%d" % i, words[i]))
	return SessionRunner.new(d, d.items)


func test_demarrage_presente_le_premier_item() -> void:
	var r := _runner(["chat", "loup"])
	var seen: Array = []
	r.item_presented.connect(func(item): seen.append(item.item_id))
	r.start()
	fw.assert_eq(r.current_item().item_id, "i0", "premier item présenté")
	fw.assert_eq(seen.size(), 1, "signal item_presented émis une fois")


func test_bonne_reponse_du_premier_coup() -> void:
	var r := _runner(["chat", "loup"])
	r.start()
	var outcomes: Array = []
	r.item_completed.connect(func(o): outcomes.append(o))
	r.submit_answer("chat")
	fw.assert_eq(outcomes, ["auto"], "réussite autonome enregistrée")
	fw.assert_eq(r.current_item().item_id, "i1", "passe à l'item suivant")


func test_erreur_puis_reussite_avec_indices() -> void:
	var r := _runner(["chat", "loup"])
	r.start()
	var kinds: Array = []
	r.feedback.connect(func(ok, msg, kind): kinds.append(kind))
	var outcomes: Array = []
	r.item_completed.connect(func(o): outcomes.append(o))
	r.submit_answer("chien")     # erreur → indice proposé
	r.submit_answer("chat")      # réussite après indice
	fw.assert_eq(kinds, ["error_hint", "correct"], "erreur puis réussite")
	fw.assert_eq(outcomes, ["hinted"], "réussite aidée ≠ autonome")


func test_solution_montrée_apres_max_tentatives() -> void:
	var r := _runner(["chat"])
	r.start()
	var kinds: Array = []
	r.feedback.connect(func(ok, msg, kind): kinds.append(kind))
	var outcomes: Array = []
	r.item_completed.connect(func(o): outcomes.append(o))
	r.submit_answer("chien")
	r.submit_answer("chiot")     # 2e échec = max_attempts
	fw.assert_eq(kinks_len(kinds), 2, "deux feedbacks")
	fw.assert_eq(kinds[1], "solved_show", "solution montrée après épuisement des tentatives")
	fw.assert_eq(outcomes, ["failed"], "item marqué en échec")


func kinks_len(a: Array) -> int:
	return a.size()


func test_session_terminee_stats_exactes() -> void:
	var r := _runner(["chat", "loup"])
	var finished: Array = []
	r.session_finished.connect(func(stats): finished.append(stats.duplicate()))
	r.start()
	r.submit_answer("chat")      # auto
	r.submit_answer("x")         # erreur
	r.submit_answer("loup")      # hinted
	fw.assert_eq(finished.size(), 1, "session_finished émis")
	var s: Dictionary = finished[0]
	fw.assert_eq(s["items"], 2, "2 items vus")
	fw.assert_eq(s["auto_successes"], 1, "1 réussite autonome")
	fw.assert_eq(s["hint_solves"], 1, "1 réussite aidée")
	fw.assert_eq(s["failures"], 0, "0 échec")


func test_abandon_possible_a_tout_moment() -> void:
	var r := _runner(["chat", "loup"])
	r.start()
	r.submit_answer("chat")
	var finished: Array = []
	r.session_finished.connect(func(stats): finished.append(stats))
	r.abandon()
	fw.assert_eq(finished.size(), 1, "abandon termine la session proprement")
	fw.assert_eq(finished[0]["items"], 1, "seul l'item vu compte")
	fw.assert_true(r.is_finished(), "runner terminé")


func test_reponse_espaces_et_casse_tolérés() -> void:
	var r := _runner(["Chat"])
	r.start()
	var outcomes: Array = []
	r.item_completed.connect(func(o): outcomes.append(o))
	r.submit_answer("  chat ")
	fw.assert_eq(outcomes, ["auto"], "espaces et casse ignorés")


func test_accents_significatifs() -> void:
	# Garde pédagogique : en français, l'accent fait partie de l'orthographe.
	var r := _runner(["élève"])
	r.start()
	var outcomes: Array = []
	r.item_completed.connect(func(o): outcomes.append(o))
	r.submit_answer("eleve")
	fw.assert_eq(outcomes, [], "« eleve » n'est pas accepté pour « élève »")


func test_demande_indice_volontaire() -> void:
	var r := _runner(["chat"])
	r.start()
	var hints: Array = []
	r.hint_given.connect(func(h): hints.append(h))
	r.request_hint()
	r.request_hint()
	r.request_hint()             # au-delà : dernier indice répété
	fw.assert_eq(hints.size(), 3, "trois indices servis")
	fw.assert_eq(hints[2], hints[1], "le dernier indice se répète sans en inventer")


func test_session_vide_terminee_immediatement() -> void:
	var r := _runner([])
	var finished: Array = []
	r.session_finished.connect(func(stats): finished.append(stats))
	r.start()
	fw.assert_eq(finished.size(), 1, "session sans item : fin immédiate")
	fw.assert_true(r.is_finished(), "état terminé")
