class_name SrTypes
extends RefCounted
## Types de données partagés du système de révision espacée + progression.
## RefCounted « statique » : uniquement des classes internes et des constantes.


## Suivi d'une compétence dans le temps (répétition espacée).
class SkillRecord:
	extends Resource
	var skill_id := ""
	## Phase d'apprentissage : 0 = découverte, 1 = consolidation, 2 = révision.
	var phase := 0
	## Degré de maîtrise (0.0–1.0) pour l'affichage, jamais un diagnostic.
	var mastery := 0.0
	## Nombre de bonnes réponses autonomes consécutives en phase 0.
	var streak := 0
	## Répétitions déjà réussies en phase de révision.
	var reps := 0
	## Intervalle actuel en jours (1 minimum).
	var interval_days := 1.0
	## Facilité (1.3 = difficile … 2.5 = facile), style SM-2.
	var ease := 2.5
	## Prochaine révision (epoch jours, float).
	var due_day := 0.0
	## Nombre de fois où un retour en arrière a été nécessaire.
	var lapses := 0
	## Dernière variation de maîtrise (debug/tableau de bord).
	var last_mastery_delta := 0.0


	func _init(p_skill_id: String = "", p_due_day: float = 0.0) -> void:
		skill_id = p_skill_id
		due_day = p_due_day


## Événement d'apprentissage brut, tel que produit par une session.
class LearningEvent:
	extends RefCounted
	var skill_id := ""
	var day := 0.0                ## Epoch en jours (fractionnaire).
	var auto_success := false     ## Réussite sans aide.
	var used_hint := false        ## Un indice a été consulté.
	var solved_after_hints := false  ## Résolu après indices.
	var failure := false          ## Item non résolu même aidé.


	func _init(
		p_skill_id: String = "",
		p_day: float = 0.0,
		p_auto_success: bool = false,
		p_used_hint: bool = false,
		p_solved_after_hints: bool = false,
		p_failure: bool = false
	) -> void:
		skill_id = p_skill_id
		day = p_day
		auto_success = p_auto_success
		used_hint = p_used_hint
		solved_after_hints = p_solved_after_hints
		failure = p_failure


## Instantané de progression d'une compétence, pour l'affichage adulte.
class SkillSnapshot:
	extends RefCounted
	var skill_id := ""
	var status := ""              # not_started / in_progress / consolidating / mastered
	var mastery := 0.0
	var sessions_count := 0
	var items_done := 0
	var attempts := 0
	var auto_successes := 0
	var hint_uses := 0
	var failures := 0
	var last_level := 0
	var last_day := -1.0
	var exercise_ids: Array[String] = []
	var error_tags: Dictionary = {}   # tag -> occurrences
