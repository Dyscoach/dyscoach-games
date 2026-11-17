extends Node
## ContentManager — catalogue des exercices : charge les fiches du dossier
## content/ (Resources .tres), les valide, expose les requêtes du moteur.
## Ajouter un exercice = déposer sa fiche : AUCUNE modification du moteur.

const ContentCatalog := preload("res://core/content_catalog.gd")
const ExerciseDefinition := preload("res://core/exercise_definition.gd")

const CONTENT_DIR := "res://content"

var catalog: RefCounted = ContentCatalog.new()


func _ready() -> void:
	load_all()


func load_all() -> void:
	var dir := DirAccess.open(CONTENT_DIR)
	if dir == null:
		push_warning("Dossier de contenus absent : %s" % CONTENT_DIR)
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while not file.is_empty():
		if file.ends_with(".tres"):
			var path := CONTENT_DIR + "/" + file
			var res = load(path)
			if res != null and res is Resource and res.has_method("validate"):
				catalog.register(res)
			else:
				push_error("Fiche ignorée (type inattendu) : %s" % path)
		file = dir.get_next()
	dir.list_dir_end()


func get_def(id: String) -> Resource:
	return catalog.get_def(id)


func all() -> Array:
	return catalog.all()


func by_domain(domain: String) -> Array:
	return catalog.by_domain(domain)


func available_for_age(age: int) -> Array:
	return catalog.available_for_age(age)


func skill_label(skill_id: String) -> String:
	return catalog.skill_label(skill_id)


## Renvoie les définitions du domaine, triées par niveau de difficulté croissant.
func by_domain_sorted(domain: String) -> Array:
	var defs: Array = catalog.by_domain(domain)
	defs.sort_custom(func(a, b): return a.base_level < b.base_level)
	return defs
