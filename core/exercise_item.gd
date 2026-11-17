class_name ExerciseItem
extends Resource
## Un item (= une « question ») d'un exercice.
## Les données pédagogiques sont TOUJOURS contrôlées : pas de génération
## aléatoire de mots ou de consignes hors de ces fiches.

@export var item_id := ""
@export var prompt_text := ""            ## Ce que l'enfant voit/entend comme question.
@export var prompt_audio: String         ## Chemin ressource de l'énoncé audio (optionnel).
@export var prompt_image: String         ## Chemin ressource d'une image (optionnel).
@export_multiline var instruction_override := ""  ## Consigne spécifique à l'item (sinon celle de la fiche).

@export var answers: Array = []        ## Réponses acceptées (première = référence).
@export var distractors: Array = []    ## Leurres proposés (choix multiples).
@export var hints: Array = []          ## Indices PROGRESSIFS (du plus léger au plus fort).
@export var feedback_correct: Array = []  ## Valorisation de la démarche.
@export var feedback_error: Array = []    ## Explication sans culpabilisation.

## Découpage pédagogique piloté par la fiche (syllabes, phonèmes, étapes…).
@export var segments: Array = []
@export var difficulty_delta := 0          ## -1..+1 : décalage au sein du niveau de la fiche.
@export var tags: Array = []       ## Ex. "voyelle_longue", "graphie_an", "dizaines".
@export var metadata: Dictionary = {}      ## Extension contrôlée (données additionnelles des jeux).


func _init() -> void:
	# Identifiant unique par défaut, écrasé par la valeur enregistrée au chargement.
	if item_id.is_empty():
		item_id = "it_%d" % get_instance_id()


func add_answer(a: String) -> void:
	answers.append(a)


## Les helpers add_* évitent le piège des littéraux non typés vers les
## propriétés Array[...] (refusé en runtime depuis un autre script).

func add_hint(h: String) -> void:
	hints.append(h)


func add_distractor(d: String) -> void:
	distractors.append(d)


func add_feedback_correct(t: String) -> void:
	feedback_correct.append(t)


func add_feedback_error(t: String) -> void:
	feedback_error.append(t)


func add_segment(s: String) -> void:
	segments.append(s)


func add_tag(t: String) -> void:
	tags.append(t)


## Erreurs pédagogiques courtes (codes retenus par le moteur adaptatif).
func validate() -> Array[String]:
	var errors: Array[String] = []
	if item_id.is_empty():
		errors.append("item_sans_id")
	if prompt_text.is_empty() and prompt_image.is_empty() and prompt_audio.is_empty():
		errors.append("item_sans_prompt")
	if answers.is_empty():
		errors.append("item_sans_reponse")
	if hints.is_empty():
		errors.append("item_sans_indice")
	for answer in answers:
		if answer.is_empty():
			errors.append("item_reponse_vide")
	for d in distractors:
		if answers.has(d):
			errors.append("item_distracteur_est_reponse")
	return errors


## Réponse de référence (celle qu'on montre si l'enfant est en difficulté).
func reference_answer() -> String:
	return String(answers[0]) if not answers.is_empty() else ""


## Indice n° `attempt` (0 = premier) ; au-delà, renvoie le dernier.
func hint_for(attempt: int) -> String:
	if hints.is_empty():
		return ""
	return String(hints[clampi(attempt, 0, hints.size() - 1)])
