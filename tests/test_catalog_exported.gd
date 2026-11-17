extends SceneTree
## Test du chargement du catalogue en conditions exportées :
## vérifie que ContentManager trouve les 5 fiches via _list_content_files().
## Usage : godot --headless --path . -s tests/test_catalog_exported.gd

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return false
	_done = true
	_run()
	return false


func _run() -> void:
	var errors := 0

	# 1. Les deux voies de listing, comparées.
	var cm := Node.new()
	cm.set_script(load("res://autoload/content_manager.gd"))
	root.add_child(cm)
	var files: Array = cm._list_content_files()
	print("fiches détectées : %d → %s" % [files.size(), files])
	if files.size() < 5:
		printerr("FAIL : moins de 5 fiches détectées")
		errors += 1

	# 2. Le catalogue réellement peuplé après _ready() du ContentManager.
	var count: int = cm.all().size()
	print("catalogue peuplé : %d fiches" % count)
	if count < 5:
		printerr("FAIL : catalogue incomplet")
		errors += 1

	# 3. Chaque fiche charge et valide (simulation du chemin d'export).
	for fname in files:
		var res = load("res://content/" + fname)
		if res == null or not res.has_method("validate"):
			printerr("FAIL : %s ne charge pas" % fname)
			errors += 1
		elif not res.validate().is_empty():
			printerr("FAIL : %s invalide : %s" % [fname, res.validate()])
			errors += 1
		else:
			print("  OK %s (%d items)" % [fname, res.items.size()])

	# 4. Une session planifiable pour un profil de 7 ans (le test utilisateur réel).
	var ChildProfile := load("res://core/child_profile.gd")
	var SessionPlanner := load("res://core/session_planner.gd")
	var p = ChildProfile.new()
	p.age = 7
	var plan: Dictionary = SessionPlanner.plan(p, cm.catalog, 0.0, RandomNumberGenerator.new())
	if plan.is_empty():
		printerr("FAIL : aucune session planifiable — c'est le symptôme « Aucun jeu disponible »")
		errors += 1
	else:
		print("session planifiable : %s (mode %s)" % [plan["def"].exercise_id, plan["mode"]])

	print("TEST CATALOGUE EXPORT : %s" % ("OK" if errors == 0 else "%d échec(s)" % errors))
	quit(1 if errors > 0 else 0)
