class_name WorldMap
extends RefCounted
## Carte des mondes : habillage pédagogique des six domaines.
## Un monde = un univers visuel + les domaines qu'il accueille.
## Couleurs douces, jamais porteuses d'information seules (toujours + icône
## + libellé écrit dans les vues).

const ExerciseDefinition := preload("res://core/exercise_definition.gd")

const WORLD_LETTERS := "monde_des_lettres"          # Forêt des sons → langage écrit
const WORLD_NUMBERS := "planete_des_nombres"        # mathématiques
const WORLD_WORDS := "atelier_des_mots"             # orthographe + langage oral
const WORLD_SHAPES := "royaume_des_formes"          # coordination/espace
const WORLD_ENIGMAS := "laboratoire_des_enigmes"    # attention/fonctions exécutives


static func worlds() -> Array[Dictionary]:
	return [
		{
			"id": WORLD_LETTERS,
			"title": "Forêt des sons",
			"subtitle": "Lettres, sons et lecture",
			"icon": "letters",
			"color": "#3752ed",
			"domains": [ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE],
		},
		{
			"id": WORLD_NUMBERS,
			"title": "Planète des nombres",
			"subtitle": "Nombres et calcul",
			"icon": "numbers",
			"color": "#e0852f",
			"domains": [ExerciseDefinition.DOMAIN_MATH],
		},
		{
			"id": WORLD_WORDS,
			"title": "Atelier des mots",
			"subtitle": "Mots, phrases et histoires",
			"icon": "words",
			"color": "#2e9e5b",
			"domains": [ExerciseDefinition.DOMAIN_SPELLING, ExerciseDefinition.DOMAIN_ORAL_LANGUAGE],
		},
		{
			"id": WORLD_SHAPES,
			"title": "Royaume des formes",
			"subtitle": "Formes, gestes et repères",
			"icon": "shapes",
			"color": "#b0568f",
			"domains": [ExerciseDefinition.DOMAIN_COORDINATION_SPACE],
		},
		{
			"id": WORLD_ENIGMAS,
			"title": "Laboratoire des énigmes",
			"subtitle": "Mémoire, attention et stratégie",
			"icon": "enigmas",
			"color": "#5a4fcf",
			"domains": [ExerciseDefinition.DOMAIN_ATTENTION_EXECUTIVE],
		},
	]


static func world_of_domain(domain: String) -> Dictionary:
	for w in worlds():
		if w["domains"].has(domain):
			return w
	return {}


static func title_of_domain(domain: String) -> String:
	var w := world_of_domain(domain)
	return String(w.get("title", domain))
