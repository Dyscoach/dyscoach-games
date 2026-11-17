class_name ContentCatalog
extends RefCounted
## Catalogue des exercices : enregistrement validé, recherche, filtres.
## Composant PUR (aucun autoload) — l'autoload Content en est un simple wrapper.

const ExerciseDefinition := preload("res://core/exercise_definition.gd")

## Compétence -> libellé lisible pour la carte des mondes et le tableau de bord.
const SKILL_LABELS := {
	"reconnaissance_sons": "Reconnaissance des sons",
	"syllabes": "Syllabes",
	"rimes": "Rimes et phonèmes",
	"fusion_sons": "Fusion de sons",
	"segmentation_phonemique": "Segmentation phonémique",
	"grapheme_phoneme": "Graphème-phonème",
	"graphies_complexes": "Graphies complexes",
	"assemblage_syllabes": "Assemblage de syllabes",
	"decodage_mots": "Décodage de mots",
	"lecture_phrases": "Lecture de phrases",
	"lecture_fluide": "Lecture fluide",
	"morphologie": "Morphologie et familles de mots",
	"comprehension_texte": "Compréhension de textes courts",
	"dictée_syllabes": "Dictées de syllabes",
	"dictée_mots": "Dictées de mots",
	"accords": "Accords grammaticaux",
	"conjugaison": "Conjugaison",
	"homophones": "Homophones",
	"construction_phrases": "Construction de phrases",
	"repérage_erreurs": "Repérage d'erreurs",
	"memoire_orthographique": "Mémorisation orthographique",
	"quantités": "Reconnaissance des quantités",
	"denombrement": "Dénombrement",
	"comparaison_quantites": "Comparaison de quantités",
	"chiffre_quantite": "Correspondance chiffre-quantité",
	"ligne_numerique": "Ligne numérique",
	"decomposition": "Décomposition des nombres",
	"unités_dizaines": "Unités, dizaines et centaines",
	"calcul_mental": "Calcul mental",
	"addition_soustraction": "Addition et soustraction",
	"multiplication_division": "Multiplication et division",
	"logique_math": "Logique mathématique",
	"resolution_problemes": "Résolution de problèmes",
	"reproduction_formes": "Reproduction de formes",
	"orientation_spatiale": "Orientation spatiale",
	"organisation_visuelle": "Organisation visuelle",
	"repérage_espace": "Repérage dans l'espace",
	"séquençage_gestes": "Séquençage de gestes",
	"coordination_yeux_main": "Coordination œil-main",
	"deplacements": "Déplacements dans un environnement",
	"manipulation_objets": "Manipulation d'objets",
	"organisation_etapes": "Organisation d'étapes",
	"comprehension_consignes": "Compréhension de consignes",
	"association_mot_image": "Association mot-image",
	"catégorisation": "Catégorisation",
	"vocabulaire": "Vocabulaire",
	"ordre_chronologique": "Ordre chronologique",
	"comprehension_orale": "Compréhension orale",
	"organisation_récit": "Organisation d'un récit",
	"attention_selective": "Attention sélective",
	"maintien_consigne": "Maintien d'une consigne",
	"planification": "Planification",
	"flexibilite_cognitive": "Flexibilité cognitive",
	"inhibition": "Inhibition dans une tâche",
	"memoire_travail": "Mémorisation d'informations utiles",
}

var _defs: Dictionary = {}    ## exercise_id -> ExerciseDefinition
var _errors: Dictionary = {}  ## exercise_id -> Array[String] (fiches rejetées)


func register(def: Resource) -> bool:
	var errors: Array = def.validate()
	if errors.is_empty() and _defs.has(def.exercise_id):
		errors = ["exercise_id_duplique"]
	if not errors.is_empty():
		_errors[def.exercise_id] = errors
		push_error("Fiche rejetée (%s) : %s" % [def.exercise_id, errors])
		return false
	_defs[def.exercise_id] = def
	return true


func get_def(id: String) -> Resource:
	return _defs.get(id)


func all() -> Array:
	return _defs.values()


func by_domain(domain: String) -> Array:
	var out: Array = []
	for d in _defs.values():
		if d.domain == domain:
			out.append(d)
	return out


func by_skill(skill: String) -> Array:
	var out: Array = []
	for d in _defs.values():
		if d.skill == skill:
			out.append(d)
	return out


func available_for_age(age: int) -> Array:
	var out: Array = []
	for d in _defs.values():
		if age >= d.age_min and age <= d.age_max:
			out.append(d)
	return out


func prerequisites_ready(def: Resource, acquired: Array) -> bool:
	for skill_id in def.prerequisites:
		if not acquired.has(skill_id):
			return false
	return true


func validation_errors() -> Dictionary:
	return _errors


func skill_label(skill_id: String) -> String:
	return SKILL_LABELS.get(skill_id, skill_id)
