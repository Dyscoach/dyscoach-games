extends SceneTree
## Vérification headless des fiches pédagogiques .tres du dossier content/.
## Usage : godot --headless --path . -s tests/check_content.gd
## Toute fiche invalide ou non chargée → exit 1.

const ExerciseDefinition := preload("res://core/exercise_definition.gd")


func _init() -> void:
	var dir := DirAccess.open("res://content")
	if dir == null:
		print("ECHEC : dossier content/ introuvable")
		quit(1)
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var f := dir.get_next()
	while not f.is_empty():
		if f.ends_with(".tres"):
			files.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	files.sort()

	var failures := 0
	if files.is_empty():
		print("ECHEC : aucune fiche .tres dans content/")
		quit(1)
		return
	for file in files:
		var path := "res://content/" + file
		var res = load(path)
		if res == null:
			print("ECHEC chargement %s" % file)
			failures += 1
			continue
		if not res is Resource or not res.has_method("validate"):
			format_error(file, "ce n'est pas une fiche ExerciseDefinition")
			failures += 1
			continue
		var errors: Array = res.validate()
		if not errors.is_empty():
			format_error(file, str(errors))
			failures += 1
			continue
		# Contrôles pédagogiques additionnels.
		var warnings: Array[String] = []
		for item in res.items:
			if item.prompt_text.length() > 60:
				warnings.append("item %s : consigne longue (%d car.)" % [item.item_id, item.prompt_text.length()])
		print("OK  %-34s %2d items  %s" % [file, res.items.size(), res.display_name])
		for w in warnings:
			print("     ⚠ %s" % w)
	print("")
	if failures > 0:
		print("ECHEC : %d fiche(s) invalide(s)" % failures)
		quit(1)
	else:
		print("CATALOGUE VALIDE : %d fiche(s)" % files.size())
		quit(0)


func format_error(file: String, message: String) -> void:
	print("ECHEC %s : %s" % [file, message])
