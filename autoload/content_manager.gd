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


## Liste les fiches pédagogiques quel que soit le mode d'exécution.
## En PROJET EXPORTÉ, DirAccess renvoie des noms remappés (.tres.remap,
## conversion binaire .res…) — cf. docs DirAccess : « file names may change
## or be remapped after export ». On utilise donc :
##   1. ResourceLoader.list_directory() (noms d'origine, Godot 4.4+) ;
##   2. en repli, DirAccess avec retrait des suffixes de remap.
## Dans les deux cas, load("res://…/fiche.tres") reste transparent grâce au
## remappage du moteur.
func _list_content_files() -> Array[String]:
	var names: Array[String] = []
	if ResourceLoader.has_method("list_directory"):
		var listed: PackedStringArray = ResourceLoader.list_directory(CONTENT_DIR)
		for f in listed:
			var fname := String(f)
			if fname.ends_with(".tres"):
				names.append(fname)
			elif fname.ends_with(".tres.remap"):
				names.append(fname.trim_suffix(".remap"))
	if not names.is_empty():
		return names
	var dir := DirAccess.open(CONTENT_DIR)
	if dir == null:
		return names
	dir.list_dir_begin()
	var file := dir.get_next()
	while not file.is_empty():
		if file.ends_with(".tres"):
			names.append(file)
		elif file.ends_with(".tres.remap"):
			names.append(file.trim_suffix(".remap"))
		elif file.ends_with(".res"):
			# Ressource convertie en binaire : load() attend le chemin .tres.
			names.append(file.trim_suffix(".res") + ".tres")
		file = dir.get_next()
	dir.list_dir_end()
	return names


func load_all() -> void:
	var files := _list_content_files()
	if files.is_empty():
		push_warning("Aucune fiche trouvée dans %s (vérifier l'export)" % CONTENT_DIR)
		return
	for fname in files:
		var path := CONTENT_DIR + "/" + fname
		var res = load(path)
		if res != null and res is Resource and res.has_method("validate"):
			catalog.register(res)
		else:
			push_error("Fiche ignorée (type inattendu) : %s" % path)


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
