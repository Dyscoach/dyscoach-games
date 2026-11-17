class_name SessionRunner
extends RefCounted
## Machine à états d'une session d'exercice — composant PUR (testable headless).
##
## Une session = présentation d'items, réponses de l'enfant, feedbacks
## progressifs (erreur → indice → solution montrée), puis stats consolidées.
## Les vues (scènes de jeu) s'y branchent par signaux ; elles ne font que de
## l'affichage, toute la logique vit ici.

const ExerciseDefinition := preload("res://core/exercise_definition.gd")

## Résultats possibles d'un item.
const OUTCOME_AUTO := "auto"        ## Réussi sans aide.
const OUTCOME_HINTED := "hinted"    ## Réussi après indice(s).
const OUTCOME_FAILED := "failed"    ## Non résolu : solution montrée.

## Types de feedback pour la vue.
const FB_CORRECT := "correct"
const FB_ERROR_HINT := "error_hint"
const FB_SOLVED_SHOW := "solved_show"
const FB_HINT := "hint"
const FB_PRAISE := "praise"

## Ouvertures statistiques ; volontairement sans temps de réponse.
signal item_presented(item: Resource)
signal item_completed(outcome: String)
signal feedback(ok: bool, message: String, kind: String)
signal session_finished(stats: Dictionary)
signal hint_given(hint: String)

var def: Resource
var items: Array = []
var _index := -1
var _attempts := 0
var _hint_level := 0            ## Dernier niveau d'indice servi pour l'item courant.
var _hint_used := false
var _started := false
var _finished := false
var _accepted: Array[String] = []   ## Réponses acceptées, normalisées (casse/espaces).

## Stats de session, consolidées à la fin (items/auto/hinted/failed, tags d'erreur).
var _stats := {
	"items": 0, "auto_successes": 0, "hint_solves": 0, "failures": 0,
}


func _init(p_def: Resource, p_items: Array) -> void:
	def = p_def
	items = p_items


func start() -> void:
	if _started:
		return
	_started = true
	if items.is_empty():
		_finish()
		return
	_present_next()


func current_item() -> Resource:
	if _index < 0 or _index >= items.size():
		return null
	return items[_index]


func is_finished() -> bool:
	return _finished


func progress() -> Vector2i:
	return Vector2i(_index + 1, items.size())


## Réponse de l'enfant (tap, drag séquence, saisie…). Normalisation douce :
## trim + casse ignorée, accents PRESERVÉS (orthographe française).
func submit_answer(raw: String) -> void:
	if _finished:
		return
	var item: Resource = current_item()
	if item == null:
		return
	var answer := _normalize(raw)
	if answer.is_empty():
		return
	if _accepted.has(answer):
		var outcome := OUTCOME_AUTO if not _hint_used else OUTCOME_HINTED
		if _hint_used:
			_stats["hint_solves"] = int(_stats["hint_solves"]) + 1
		else:
			_stats["auto_successes"] = int(_stats["auto_successes"]) + 1
		feedback.emit(true, _pick(item.feedback_correct), FB_CORRECT)
		item_completed.emit(outcome)
		_advance()
	else:
		_attempts += 1
		var max_attempts: int = int(def.param("max_attempts_per_item", 3))
		if _attempts >= max_attempts:
			_stats["failures"] = int(_stats["failures"]) + 1
			feedback.emit(false, "La réponse était « %s ». On va s'entraîner encore, tu y es presque." % item.reference_answer(), FB_SOLVED_SHOW)
			item_completed.emit(OUTCOME_FAILED)
			_advance()
		else:
			_hint_used = true
			var hint: String = item.hint_for(_attempts)
			if hint.is_empty():
				hint = "On réessaie ensemble ?"
			feedback.emit(false, hint, FB_ERROR_HINT)


## L'enfant (ou la vue) demande explicitement un indice.
func request_hint() -> void:
	if _finished:
		return
	var item: Resource = current_item()
	if item == null:
		return
	_hint_used = true
	_hint_level += 1
	var hint: String = item.hint_for(_hint_level - 1)
	hint_given.emit(hint)
	feedback.emit(false, hint, FB_HINT)


## Passage manuel (bouton « suivant ») : l'item non résolu est compté échec.
func next() -> void:
	if _finished:
		return
	if _index < items.size():
		_advance()
	else:
		_finish()


## Abandon à tout moment — la session se termine proprement, sans pénalité.
func abandon() -> void:
	if _finished:
		return
	_finish()


func _present_next() -> void:
	_index += 1
	if _index >= items.size():
		_finish()
		return
	_attempts = 0
	_hint_used = false
	_hint_level = 0
	_accepted.clear()
	for a in items[_index].answers:
		_accepted.append(_normalize(a))
	item_presented.emit(items[_index])


func _advance() -> void:
	_stats["items"] = int(_stats["items"]) + 1
	if _index + 1 >= items.size():
		_finish()
	else:
		_present_next()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	var final_stats := _stats.duplicate()
	final_stats["exercise_id"] = def.exercise_id
	final_stats["skill"] = def.skill
	session_finished.emit(final_stats)


func _normalize(s: String) -> String:
	return s.strip_edges().to_lower()


func _pick(arr: Array) -> String:
	if arr.is_empty():
		return "Bravo ! Tu as bien cherché."
	return arr[randi() % arr.size()]
