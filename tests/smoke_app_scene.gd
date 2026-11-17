extends Node
## Test de fumée end-to-end : VERSION SCÈNE (boot normal du projet, autoloads
## réels — conditions identiques à la production).
## Usage : godot --headless --path . res://tests/smoke_app.tscn

var _failures: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_run()


func _fail(msg: String) -> void:
	_failures.append(msg)
	printerr("SMOKE FAIL : " + msg)


func _run() -> void:
	if Content.all().is_empty():
		_fail("catalogue vide à l'exécution")
		_finish()
		return

	# 1. Écrans d'interface.
	await _check_screen("res://ui/screens/home.tscn")
	await _check_screen("res://ui/screens/profile_create.tscn")
	await _check_screen("res://ui/screens/settings.tscn")
	await _check_screen("res://ui/screens/dashboard.tscn")

	# 2. Profil + carte des mondes.
	var profile = Progress.create_profile("Test", 7)
	profile.selected_domains.append("langage_ecrit")
	Progress.select_profile(profile)
	await _check_screen("res://ui/screens/worlds.tscn")

	# 3. Session planifiée par le moteur adaptatif.
	if not App.start_planned_session():
		_fail("planification de session impossible")
	else:
		await _play_current_session()

	# 4. Une session explicite pour CHAQUE exercice du catalogue.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for def in Content.all():
		if not App.start_session(def, def.pick_items(rng, 3)):
			_fail("démarrage impossible : " + def.exercise_id)
			continue
		await _play_current_session()

	# 5. Persistance effective.
	if not FileAccess.file_exists("user://profiles/manifest.json"):
		_fail("manifeste des profils non écrit")
	if Progress.active_profile == null or Progress.dashboard_rows().is_empty():
		_fail("aucune progression enregistrée après les sessions")

	Progress.delete_profile(profile)
	_finish()


func _check_screen(path: String) -> void:
	if not ResourceLoader.exists(path):
		_fail("écran introuvable : " + path)
		return
	var screen = load(path).instantiate()
	if screen == null:
		_fail("instanciation impossible : " + path)
		return
	add_child(screen)
	await get_tree().create_timer(0.05).timeout
	screen.queue_free()
	await get_tree().create_timer(0.05).timeout
	print("SMOKE OK écran : " + path)


## Joue la session en cours via le vrai hôte : bonnes réponses au premier
## coup, avec erreurs volontaires régulières pour exercer indices/feedbacks.
func _play_current_session() -> void:
	var ex_id: String = App.current_def.exercise_id if App.current_def != null else "?"
	var host = load("res://games/exercise_host.tscn").instantiate()
	add_child(host)
	await get_tree().create_timer(0.05).timeout
	var runner = App.current_runner()
	if runner == null:
		_fail("runner absent dans l'hôte")
		host.queue_free()
		return
	var guard := 0
	while not runner.is_finished() and guard < 50:
		guard += 1
		var item = runner.current_item()
		if item == null:
			runner.next()
			continue
		if guard % 4 == 0:
			runner.submit_answer("zz_reponse_fausse")
		else:
			runner.submit_answer(String(item.answers[0]))
		await get_tree().create_timer(0.02).timeout
	if not runner.is_finished():
		_fail("session sans fin (garde-fou déclenché)")
	await get_tree().create_timer(0.05).timeout
	host.queue_free()
	await get_tree().create_timer(0.05).timeout
	if App.current_def != null:
		App.stop_session()
	print("SMOKE OK session : %s (%d interactions)" % [ex_id, guard])


func _finish() -> void:
	await get_tree().create_timer(0.4).timeout
	print("")
	if _failures.is_empty():
		print("SMOKE : APPLICATION ENTIERE VERIFIEE")
		get_tree().quit(0)
	else:
		print("SMOKE : %d échec(s)" % _failures.size())
		get_tree().quit(1)
