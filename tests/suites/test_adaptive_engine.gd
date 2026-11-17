extends RefCounted
## Tests du moteur adaptatif (core/adaptive_engine.gd).
## Le temps de réponse n'est volontairement pas un critère de maîtrise.

const AdaptiveEngine := preload("res://core/adaptive_engine.gd")
const ProgressStore := preload("res://core/progress_store.gd")
const ExerciseDefinition := preload("res://core/exercise_definition.gd")
const ExerciseItem := preload("res://core/exercise_item.gd")

var fw: RefCounted


func _def(base_level: int = 3) -> Resource:
	var d: Resource = ExerciseDefinition.new()
	d.exercise_id = "test.adaptive"
	d.display_name = "Adaptatif"
	d.domain = ExerciseDefinition.DOMAIN_MATH
	d.skill = "comparaison_quantites"
	d.base_level = base_level
	d.instruction_text = "Choisis le plus grand."
	d.scene_path = "res://games/placeholder.tscn"
	return d


func _stats(items: int, auto: int, hint: int, fail: int) -> Dictionary:
	return {"items": items, "auto_successes": auto, "hint_solves": hint, "failures": fail}


func test_niveau_par_defaut_celui_de_la_fiche() -> void:
	var engine := AdaptiveEngine.new()
	var store := ProgressStore.new()
	fw.assert_eq(engine.level_for(_def(), store, "comp"), 3, "niveau de départ = base_level")


func test_une_session_reussie_ne_suffit_pas_pour_monter() -> void:
	var engine := AdaptiveEngine.new()
	var store := ProgressStore.new()
	var d := _def()
	var action: String = engine.apply_session_result(d, store, "comp", _stats(6, 6, 0, 0), 10.0)
	fw.assert_eq(action, "stable", "1 seule bonne session : on reste")
	fw.assert_eq(engine.level_for(d, store, "comp"), 3, "niveau inchangé")


func test_deux_sessions_reussies_font_monter() -> void:
	var engine := AdaptiveEngine.new()
	var store := ProgressStore.new()
	var d := _def()
	engine.apply_session_result(d, store, "comp", _stats(6, 6, 0, 0), 10.0)
	var action: String = engine.apply_session_result(d, store, "comp", _stats(6, 5, 1, 0), 11.0)
	fw.assert_eq(action, "up", "2 sessions ≥ seuil : montée")
	fw.assert_eq(engine.level_for(d, store, "comp"), 4, "niveau +1")


func test_session_mitigee_remet_les_series_a_zero() -> void:
	var engine := AdaptiveEngine.new()
	var store := ProgressStore.new()
	var d := _def()
	engine.apply_session_result(d, store, "comp", _stats(6, 6, 0, 0), 10.0)
	engine.apply_session_result(d, store, "comp", _stats(6, 3, 2, 1), 11.0)  # neutre
	var action: String = engine.apply_session_result(d, store, "comp", _stats(6, 6, 0, 0), 12.0)
	fw.assert_eq(action, "stable", "la série a été remise à zéro par la session neutre")
	fw.assert_eq(engine.level_for(d, store, "comp"), 3, "toujours niveau 3")


func test_deux_sessions_difficiles_font_redescendre() -> void:
	var engine := AdaptiveEngine.new()
	var store := ProgressStore.new()
	var d := _def(4)
	engine.apply_session_result(d, store, "comp", _stats(6, 1, 1, 4), 10.0)
	var action: String = engine.apply_session_result(d, store, "comp", _stats(6, 1, 2, 3), 11.0)
	fw.assert_eq(action, "down", "2 sessions difficiles : descente")
	fw.assert_eq(engine.level_for(d, store, "comp"), 3, "retour à une étape plus simple")


func test_niveau_plancher_et_plafond() -> void:
	var engine := AdaptiveEngine.new()
	var store := ProgressStore.new()
	var d1 := _def(1)
	engine.apply_session_result(d1, store, "c1", _stats(6, 1, 1, 4), 10.0)
	var action: String = engine.apply_session_result(d1, store, "c1", _stats(6, 0, 2, 4), 11.0)
	fw.assert_eq(action, "down_plancher", "descente refusée sous le niveau 1")
	fw.assert_eq(engine.level_for(d1, store, "c1"), 1, "plancher 1")
	var d6 := _def(6)
	engine.apply_session_result(d6, store, "c6", _stats(6, 6, 0, 0), 10.0)
	action = engine.apply_session_result(d6, store, "c6", _stats(6, 6, 0, 0), 11.0)
	fw.assert_eq(action, "up_plafond", "montée refusée au-delà du niveau 6")
	fw.assert_eq(engine.level_for(d6, store, "c6"), 6, "plafond 6")


func test_seuils_personnalises_par_fiche() -> void:
	var engine := AdaptiveEngine.new()
	var store := ProgressStore.new()
	var d := _def()
	d.adaptive_params = {"success_threshold_up": 1.0}
	engine.apply_session_result(d, store, "comp", _stats(6, 5, 1, 0), 10.0)
	var action: String = engine.apply_session_result(d, store, "comp", _stats(6, 5, 1, 0), 11.0)
	fw.assert_eq(action, "stable", "avec seuil 100%, 5/6 ne suffit pas pour monter")


func test_guidance_selon_les_besoins_d_aide() -> void:
	var engine := AdaptiveEngine.new()
	fw.assert_eq(engine.guidance(_stats(6, 6, 0, 0)), "autonomie", "aucune aide nécessaire")
	fw.assert_eq(engine.guidance(_stats(6, 3, 3, 0)), "guide", "indices fréquents → guidage")
	fw.assert_eq(engine.guidance(_stats(6, 0, 2, 4)), "demonstration", "échecs massifs → démonstration")


func test_aucun_critere_temporel() -> void:
	# Garde-fou conceptuel : les stats n'ont pas de champ de temps de réponse.
	var engine := AdaptiveEngine.new()
	var s := _stats(6, 6, 0, 0)
	fw.assert_false(s.has("response_time"), "le moteur ne juge pas sur le temps de réponse")
