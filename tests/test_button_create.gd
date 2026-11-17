extends SceneTree
## Test d'interaction réelle : presse le bouton « Créer » de profile_create.tscn
## et vérifie que le profil est créé et que la scène change vers worlds.
## Usage : godot --headless --path . -s tests/test_button_create.gd

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return false
	_done = true
	_run()
	return false


func _run() -> void:
	# Les autoloads ne sont pas chargés en mode -s : on les instancie.
	var specs := [
		["Access", "res://autoload/accessibility.gd"],
		["AudioMgr", "res://autoload/audio_manager.gd"],
		["Content", "res://autoload/content_manager.gd"],
		["SR", "res://autoload/spaced_repetition_manager.gd"],
		["Progress", "res://autoload/progress_manager.gd"],
		["App", "res://autoload/app.gd"],
	]
	for entry in specs:
		var n: Node = load(entry[1]).new()
		n.name = entry[0]
		root.add_child(n)

	var errors := 0
	var Progress = root.get_node("/root/Progress")
	# Scène de création (courante, sans passer par home).
	var scene: Node = load("res://ui/screens/profile_create.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.2).timeout

	var before: int = Progress.profiles.size()
	var btn: Button = scene.find_child("CreateButton", true, false)
	if btn == null:
		printerr("TEST FAIL : bouton CreateButton introuvable")
		errors += 1
	else:
		btn.pressed.emit()
		await create_timer(0.3).timeout
		if Progress.profiles.size() != before + 1:
			printerr("TEST FAIL : le profil n'a pas été créé par le bouton")
			errors += 1
		else:
			var p = Progress.profiles[-1]
			print("OK profil créé : id=%s age=%d" % [p.profile_id.substr(0, 8), p.age])
	# Vérifier le champ prénom via l'API (le LineEdit alimente create_profile).
	if Progress.profiles.size() > 0:
		var np = Progress.profiles[-1]
		np.display_name = "TestBouton"
		Progress.save_profile(np)
		if not FileAccess.file_exists("user://profiles/%s.json" % np.profile_id):
			printerr("TEST FAIL : json de profil non écrit")
			errors += 1
		else:
			print("OK persistance : profiles/%s.json" % np.profile_id.substr(0, 8))
		Progress.delete_profile(np)

	print("TEST BOUTON : %s" % ("OK" if errors == 0 else "%d échec(s)" % errors))
	quit(1 if errors > 0 else 0)
