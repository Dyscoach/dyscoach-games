extends RefCounted
## Tests du planificateur de révision espacée (core/spaced_repetition.gd).

const SrTypes := preload("res://core/sr_types.gd")
const SpacedRepetition := preload("res://core/spaced_repetition.gd")

var fw: RefCounted


func _auto(skill: String, day: float) -> RefCounted:
	return SrTypes.LearningEvent.new(skill, day, true, false, false, false)


func _assisted(skill: String, day: float) -> RefCounted:
	return SrTypes.LearningEvent.new(skill, day, false, true, true, false)


func _fail(skill: String, day: float) -> RefCounted:
	return SrTypes.LearningEvent.new(skill, day, false, true, false, true)


func test_premiere_reussite_passe_en_phase_0() -> void:
	var sr := SpacedRepetition.new()
	var rec: Resource = sr.process_event(_auto("phoneme_a", 10.0))
	fw.assert_eq(rec.phase, 0, "phase découverte après 1 réussite")
	fw.assert_eq(rec.streak, 1, "série = 1")
	fw.assert_almost_eq(rec.mastery, 0.1, 0.001, "maîtrise 0.1")


func test_trois_reussites_autonomes_consolident() -> void:
	var sr := SpacedRepetition.new()
	sr.process_event(_auto("syl", 1.0))
	sr.process_event(_auto("syl", 2.0))
	var rec: Resource = sr.process_event(_auto("syl", 3.0))
	fw.assert_eq(rec.phase, 1, "phase consolidation après 3 réussites consécutives")
	fw.assert_almost_eq(rec.due_day, 4.0, 0.001, "révision à J+1")


func test_reussite_assistee_ne_consolide_pas() -> void:
	var sr := SpacedRepetition.new()
	sr.process_event(_auto("syl", 1.0))
	sr.process_event(_auto("syl", 2.0))
	var rec: Resource = sr.process_event(_assisted("syl", 3.0))
	fw.assert_eq(rec.phase, 0, "reste en découverte avec aide")
	fw.assert_eq(rec.streak, 0, "série remise à zéro")
	fw.assert_almost_eq(rec.due_day, 4.0, 0.001, "revoir le lendemain")


func test_intervalles_croissants_en_consolidation() -> void:
	var sr := SpacedRepetition.new()
	for day in [1.0, 2.0, 3.0]:
		sr.process_event(_auto("syl", day))
	var rec: Resource = sr.get_or_create("syl", 0.0)
	rec.due_day = 4.0
	# J4 : rep 1 → J5 ; J5 : rep 2 → J7 ; J7 : rep 3 → phase révision, J+4.
	rec = sr.process_event(_auto("syl", 4.0))
	fw.assert_almost_eq(rec.due_day, 5.0, 0.001, "rep 1 : +1 jour")
	rec = sr.process_event(_auto("syl", 5.0))
	fw.assert_almost_eq(rec.due_day, 7.0, 0.001, "rep 2 : +2 jours")
	rec = sr.process_event(_auto("syl", 7.0))
	fw.assert_eq(rec.phase, 2, "phase révision après 3 reps de consolidation")
	fw.assert_almost_eq(rec.due_day, 11.0, 0.001, "révision : +4 jours")


func test_intervalle_plafonne_a_45_jours() -> void:
	var sr := SpacedRepetition.new()
	var rec: Resource = sr.get_or_create("geo", 0.0)
	rec.phase = 2
	rec.interval_days = 40.0
	rec.ease = 2.5
	rec = sr.process_event(_auto("geo", 100.0))
	fw.assert_lte(rec.due_day, 145.0, "due_day plafonné à J+45")
	fw.assert_lte(rec.interval_days, 45.0, "intervalle max 45 j")


func test_echec_retourne_en_consolidation_sans_effacement() -> void:
	var sr := SpacedRepetition.new()
	var rec: Resource = sr.get_or_create("rim", 0.0)
	rec.phase = 2
	rec.mastery = 0.6
	rec.reps = 5
	rec = sr.process_event(_fail("rim", 50.0))
	fw.assert_eq(rec.phase, 1, "retour en consolidation")
	fw.assert_eq(rec.reps, 0, "reps remises à zéro")
	fw.assert_almost_eq(rec.mastery, 0.5, 0.001, "maîtrise amputée mais conservée")
	fw.assert_almost_eq(rec.due_day, 51.0, 0.001, "révision rapide dès le lendemain")


func test_compétence_inconnue_toujours_due() -> void:
	var sr := SpacedRepetition.new()
	fw.assert_true(sr.is_due("jamais_vue", 0.0), "compétence jamais travaillée = due")


func test_due_skills_trie_par_urgence() -> void:
	var sr := SpacedRepetition.new()
	var a: Resource = sr.get_or_create("a", 0.0)
	a.due_day = 5.0
	var b: Resource = sr.get_or_create("b", 0.0)
	b.due_day = 2.0
	var c: Resource = sr.get_or_create("c", 0.0)
	c.due_day = 9.0
	var due: Array[String] = sr.due_skills(6.0)
	fw.assert_eq(due, ["b", "a"], "tri par échéance, c non due exclue")


func test_priority_skills_revisions_d_abord() -> void:
	var sr := SpacedRepetition.new()
	var a: Resource = sr.get_or_create("rev", 0.0)
	a.due_day = 1.0
	var out: Array[String] = sr.priority_skills(10.0, ["nouvelle"])
	fw.assert_eq(out[0], "rev", "la révision due passe avant la nouvelle compétence")
	fw.assert_has(out, "nouvelle", "la compétence en cours reste proposée")
