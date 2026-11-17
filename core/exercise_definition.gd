class_name ExerciseDefinition
extends Resource
## Fiche normalisée d'un exercice (cf. cahier des charges §8).
## Toute la donnée pédagogique vit ici — le code des jeux reste générique.

const ExerciseItem := preload("res://core/exercise_item.gd")

## --- Domaines pédagogiques (modules 1 à 6) ---
const DOMAIN_WRITTEN_LANGUAGE := "langage_ecrit"
const DOMAIN_SPELLING := "orthographe"
const DOMAIN_MATH := "mathematiques"
const DOMAIN_COORDINATION_SPACE := "coordination_espace"
const DOMAIN_ORAL_LANGUAGE := "langage_oral"
const DOMAIN_ATTENTION_EXECUTIVE := "attention_executive"
const DOMAINS: Array[String] = [
	DOMAIN_WRITTEN_LANGUAGE, DOMAIN_SPELLING, DOMAIN_MATH,
	DOMAIN_COORDINATION_SPACE, DOMAIN_ORAL_LANGUAGE, DOMAIN_ATTENTION_EXECUTIVE,
]

## --- Niveaux pédagogiques (progression explicite, §6) ---
const LEVEL_DISCOVERY := 1       ## Découverte avec démonstration.
const LEVEL_GUIDED := 2          ## Exercice guidé.
const LEVEL_AUTONOMOUS_SIMPLE := 3  ## Autonome simple.
const LEVEL_INTERMEDIATE := 4    ## Intermédiaire.
const LEVEL_COMPLEX := 5         ## Complexe.
const LEVEL_TRANSFER := 6        ## Réinvestissement dans un nouveau contexte.

## --- Niveau de preuve scientifique (prudence, §12) ---
const EVIDENCE_ESTABLISHED := "etabli"          ## Mécanisme scientifiquement établi.
const EVIDENCE_PROMISING := "prometteur"        ## Hypothèse prometteuse.
const EVIDENCE_EXPERIMENTAL := "experimental"   ## Fonctionnalité expérimentale.
const EVIDENCE_LEVELS: Array[String] = [EVIDENCE_ESTABLISHED, EVIDENCE_PROMISING, EVIDENCE_EXPERIMENTAL]

## --- Statut de validation par un professionnel (§12) ---
const VALIDATION_DRAFT := "brouillon"
const VALIDATION_REVIEWED := "revu_par_specialiste"
const VALIDATION_APPROVED := "valide_par_specialiste"
const VALIDATION_STATUSES: Array[String] = [VALIDATION_DRAFT, VALIDATION_REVIEWED, VALIDATION_APPROVED]

## --- Modalités d'interaction ---
const INTERACTION_TAP := "tap"
const INTERACTION_DRAG := "drag"
const INTERACTION_LISTEN := "listen"
const INTERACTION_TYPE := "type"
const INTERACTION_SEQUENCE := "sequence"
const INTERACTIONS: Array[String] = [
	INTERACTION_TAP, INTERACTION_DRAG, INTERACTION_LISTEN, INTERACTION_TYPE, INTERACTION_SEQUENCE,
]

@export var exercise_id := ""                ## Identifiant unique (ex. "lec.train_syllabes").
@export var display_name := ""               ## Nom lisible (« Le train des syllabes »).
@export_multiline var description := ""      ## Objectif pédagogique en une phrase.
@export var domain := ""                     ## Un des DOMAINS.
@export var skill := ""                      ## Compétence ciblée (clé de progression).
@export var prerequisites: Array[String] = []  ## Compétences supposées acquises.
@export var base_level := LEVEL_AUTONOMOUS_SIMPLE  ## Niveau 1..6 visé par défaut.
@export var age_min := 5                     ## Tranche d'âge indicative.
@export var age_max := 10
@export_multiline var instruction_text := "" ## Consigne écrite courte.
@export var instruction_audio: String        ## Consigne audio (chemin ressource).
@export var scene_path := ""                 ## Scène de jeu (mécanique) qui exécute cet exercice.
@export_multiline var artwork_note := ""     ## Matériel graphique attendu.
@export var items: Array[Resource] = []      ## ExerciseItem (items pédagogiques contrôlés).
@export var interaction := INTERACTION_TAP   ## Modalité principale.
@export var duration_minutes := 5            ## Durée indicative d'une session.

## Paramètres adaptatifs (surchargables par fiche) :
##   items_per_session      : nombre d'items par session
##   success_threshold_up   : taux de réussite pour monter d'un niveau
##   failure_threshold_down : taux déclenchant un retour à une étape plus simple
##   max_attempts_per_item  : tentatives avant aide complète
@export var adaptive_params: Dictionary = {}

## Rattachement scientifique/pédagogique (§2, §12).
@export_multiline var source_note := ""
@export var evidence_level := EVIDENCE_PROMISING
@export var validation_status := VALIDATION_DRAFT

## Variante : id de la fiche dont celle-ci dérive (même mécanique, autre contenu).
@export var variant_of := ""


func add_item(item: Resource) -> void:
	items.append(item)


func add_prerequisite(skill_id: String) -> void:
	prerequisites.append(skill_id)


static func default_adaptive_params() -> Dictionary:
	return {
		"items_per_session": 6,
		"success_threshold_up": 0.8,
		"failure_threshold_down": 0.4,
		"max_attempts_per_item": 3,
	}


func param(key: String, fallback):
	if adaptive_params.has(key):
		return adaptive_params[key]
	return default_adaptive_params().get(key, fallback)


func validate() -> Array[String]:
	var errors: Array[String] = []
	if exercise_id.is_empty():
		errors.append("exercise_id_manquant")
	elif not exercise_id.to_lower() == exercise_id or " " in exercise_id:
		errors.append("exercise_id_invalide")
	if not DOMAINS.has(domain):
		errors.append("domaine_inconnu")
	if skill.is_empty():
		errors.append("competence_manquante")
	if instruction_text.is_empty():
		errors.append("consigne_manquante")
	if scene_path.is_empty():
		errors.append("scene_manquante")
	if base_level < LEVEL_DISCOVERY or base_level > LEVEL_TRANSFER:
		errors.append("niveau_hors_bornes")
	if age_min > age_max:
		errors.append("tranche_age_incoherente")
	if not INTERACTIONS.has(interaction):
		errors.append("interaction_inconnue")
	if not EVIDENCE_LEVELS.has(evidence_level):
		errors.append("niveau_preuve_inconnu")
	if not VALIDATION_STATUSES.has(validation_status):
		errors.append("statut_validation_inconnu")
	if items.is_empty():
		errors.append("aucun_item")
	var seen_ids := {}
	var codes := {}
	for i in items.size():
		var item = items[i]
		if item == null:
			errors.append("item_null:%d" % i)
			continue
		for code in item.validate():
			var keyed := "item%d_%s" % [i, code]
			if not codes.has(keyed):
				errors.append(keyed)
		if seen_ids.has(item.item_id):
			errors.append("item_id_duplique:%s" % item.item_id)
		seen_ids[item.item_id] = true
	return errors


## Tirage pédagogique : mélange puis sous-ensemble (jamais de contenu inventé).
func pick_items(rng: RandomNumberGenerator, count: int) -> Array:
	var pool: Array = items.duplicate()
	pool.shuffle()
	var n: int = mini(count, pool.size())
	var picked: Array = []
	for i in n:
		picked.append(pool[i])
	return picked


static func level_label(level: int) -> String:
	match level:
		LEVEL_DISCOVERY: return "Découverte (avec démonstration)"
		LEVEL_GUIDED: return "Guidé"
		LEVEL_AUTONOMOUS_SIMPLE: return "Autonome simple"
		LEVEL_INTERMEDIATE: return "Intermédiaire"
		LEVEL_COMPLEX: return "Complexe"
		LEVEL_TRANSFER: return "Réinvestissement"
		_: return "Niveau %d" % level
