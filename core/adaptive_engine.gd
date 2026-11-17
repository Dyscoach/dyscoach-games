class_name AdaptiveEngine
extends RefCounted
## Moteur de personnalisation : choisit le niveau de difficulté (1..6) et le
## niveau de guidage d'après la réussite, les tentatives et le besoin d'indices.
##
## Garde conceptuelle : le temps de réponse n'est JAMAIS un critère — ni ici,
## ni dans les stats produites par les sessions (champ absent par conception).

const ExerciseDefinition := preload("res://core/exercise_definition.gd")

const ACTION_STABLE := "stable"
const ACTION_UP := "up"
const ACTION_DOWN := "down"
const ACTION_UP_LIMIT := "up_plafond"
const ACTION_DOWN_LIMIT := "down_plancher"

const GUIDANCE_AUTONOMY := "autonomie"
const GUIDANCE_GUIDED := "guide"
const GUIDANCE_DEMO := "demonstration"

## Il faut 2 sessions consécutives bonnes pour monter, 2 difficiles pour
## descendre : la maîtrise se vérifie sur plusieurs séances, pas sur une série.
const STREAK_TO_MOVE := 2
## Fréquence d'indices au-delà de laquelle on renforce le guidage.
const HINT_RATE_GUIDED := 0.3
## Taux d'échecs au-delà duquel on repart d'une démonstration.
const FAIL_RATE_DEMO := 0.5


func level_for(def: Resource, store, skill_id: String) -> int:
	return store.get_level(skill_id, def.base_level)


## Applique le résultat d'une session et retourne l'action décidée.
## stats : {"items": int, "auto_successes": int, "hint_solves": int, "failures": int}
func apply_session_result(def: Resource, store, skill_id: String, stats: Dictionary, day: float) -> String:
	var items: int = maxi(int(stats.get("items", 0)), 1)
	var auto := int(stats.get("auto_successes", 0))
	var hint := int(stats.get("hint_solves", 0))
	var fail := int(stats.get("failures", 0))
	# Réussite pondérée : une résolution après indices vaut une demi-réussite
	# autonome (récupération active aidée ≠ maîtrise autonome).
	var assisted_rate: float = (float(auto) + 0.5 * float(hint)) / float(items)
	var th_up: float = float(def.param("success_threshold_up", 0.8))
	var th_down: float = float(def.param("failure_threshold_down", 0.4))
	var level := level_for(def, store, skill_id)

	var action := ACTION_STABLE
	if assisted_rate >= th_up:
		store.bump_up(skill_id, def.base_level)
		store.reset_down(skill_id, def.base_level)
		if store.up_streak(skill_id, def.base_level) >= STREAK_TO_MOVE:
			if level < 6:
				store.set_level(skill_id, level + 1, def.base_level)
				store.reset_up(skill_id, def.base_level)
				action = ACTION_UP
			else:
				action = ACTION_UP_LIMIT
		elif level >= 6:
			action = ACTION_UP_LIMIT
	elif assisted_rate < th_down:
		store.bump_down(skill_id, def.base_level)
		store.reset_up(skill_id, def.base_level)
		if store.down_streak(skill_id, def.base_level) >= STREAK_TO_MOVE:
			if level > 1:
				store.set_level(skill_id, level - 1, def.base_level)
				store.reset_down(skill_id, def.base_level)
				action = ACTION_DOWN
			else:
				action = ACTION_DOWN_LIMIT
		elif level <= 1:
			action = ACTION_DOWN_LIMIT
	else:
		# Session mitigée : on consolide sans bouger, séries remises à zéro.
		store.reset_up(skill_id, def.base_level)
		store.reset_down(skill_id, def.base_level)

	store.record_session({
		"skill": skill_id,
		"day": day,
		"items": items,
		"auto_successes": auto,
		"hint_solves": hint,
		"failures": fail,
		"level": level,
		"action": action,
	})
	return action


## Niveau de guidage recommandé pour la prochaine session.
func guidance(stats: Dictionary) -> String:
	var items: int = maxi(int(stats.get("items", 0)), 1)
	var hint_rate: float = float(stats.get("hint_solves", 0)) / float(items)
	var fail_rate: float = float(stats.get("failures", 0)) / float(items)
	if fail_rate >= FAIL_RATE_DEMO:
		return GUIDANCE_DEMO
	if hint_rate >= HINT_RATE_GUIDED:
		return GUIDANCE_GUIDED
	return GUIDANCE_AUTONOMY
