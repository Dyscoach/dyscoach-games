extends SceneTree
## Entrée de la suite de tests headless de Dyscoach Jeux.
## Usage : godot --headless --path . -s tests/run_tests.gd
## Fail-fast : toute erreur de chargement/parsing arrête la suite avec exit 1.

const TestFramework := preload("res://tests/framework/test_framework.gd")
const SUITES: Array[String] = [
	"exercise_definition",
	"adaptive_engine",
	"spaced_repetition",
	"session_runner",
	"session_planner",
	"content_catalog",
	"progress",
]


func _init() -> void:
	var fw := TestFramework.new()
	var failed := 0
	var ran := 0
	var total := 0
	for suite_name in SUITES:
		var path := "res://tests/suites/test_%s.gd" % suite_name
		if not FileAccess.file_exists(path):
			# Suite pas encore écrite : échec explicite, mais on continue
			# d'exécuter les suites présentes (visibilité des cycles TDD).
			print("MANQUANT  %s" % suite_name)
			failed += 1
			continue
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			print("PARSE_KO %s (voir erreurs ci-dessus)" % suite_name)
			failed += 1
			continue
		var suite: RefCounted = script.new()
		suite.fw = fw
		for method in suite.get_method_list():
			var mname: String = method.name
			if not mname.begins_with("test_") or method.args.size() > 0:
				continue
			ran += 1
			fw.begin(suite_name, mname)
			var before := fw.failures
			suite.call(mname)
			total += fw.assertion_count
			if fw.failures == before:
				print("PASS  %s :: %s" % [suite_name, mname])
			else:
				failed += 1
	print("")
	if failed == 0:
		print("TOUS LES TESTS PASSENT — %d tests, %d assertions" % [ran, total])
		quit(0)
	else:
		print("ECHEC : %d test(s) en échec sur %d" % [failed, ran])
		quit(1)
