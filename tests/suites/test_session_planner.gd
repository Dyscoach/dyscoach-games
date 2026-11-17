extends RefCounted
## Tests du planificateur de session (core/session_planner.gd).

const SessionPlanner := preload("res://core/session_planner.gd")
const ContentCatalog := preload("res://core/content_catalog.gd")
const ExerciseDefinition := preload("res://core/exercise_definition.gd")
const ExerciseItem := preload("res://core/exercise_item.gd")
const ChildProfile := preload("res://core/child_profile.gd")
const SrTypes := preload("res://core/sr_types.gd")

var fw: RefCounted


func _def(id: String, skill: String, domain: String, age_min: int = 5, age_max: int = 9) -> Resource:
	var d: Resource = ExerciseDefinition.new()
	d.exercise_id = id
	d.display_name = id
	d.domain = domain
	d.skill = skill
	d.age_min = age_min
	d.age_max = age_max
	d.instruction_text = "Consigne."
	d.scene_path = "res://games/x.tscn"
	for i in 6:
		var it: Resource = ExerciseItem.new()
		it.item_id = "%s_i%d" % [id, i]
		it.prompt_text = "mot%d" % i
		it.add_answer("mot%d" % i)
		it.add_hint("Indice.")
		it.difficulty_delta = -1 if i < 3 else 1
		d.add_item(it)
	return d


func _profile(age: int = 7) -> RefCounted:
	var p := ChildProfile.new()
	p.age = age
	return p


func _rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 42
	return r


func test_revision_due_prioritaire() -> void:
	var c := ContentCatalog.new()
	c.register(_def("m.a", "rimes", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE))
	c.register(_def("m.b", "fusion", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE))
	var p := _profile()
	# "fusion" devient due (travaillée hier, intervalle 1 j).
	p.sr.process_event(SrTypes.LearningEvent.new("fusion", 10.0, true))
	var plan: Dictionary = SessionPlanner.plan(p, c, 20.0, _rng())
	fw.assert_eq(plan["skill"], "fusion", "la compétence due passe en premier")
	fw.assert_eq(plan["mode"], SessionPlanner.MODE_REVISION, "mode révision")


func test_en_cours_si_rien_de_du() -> void:
	var c := ContentCatalog.new()
	c.register(_def("m.a", "rimes", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE))
	var p := _profile()
	p.ledger.apply_session({"skill": "rimes", "items": 6, "auto_successes": 3,
		"hint_solves": 2, "failures": 1, "level": 3, "day": 10.0, "exercise_id": "m.a"})
	# Pas encore due (due J+1 = 11, on est à J=10.5 → due ? non : on prend in_progress).
	var plan: Dictionary = SessionPlanner.plan(p, c, 10.5, _rng())
	fw.assert_eq(plan["mode"], SessionPlanner.MODE_TRAINING, "compétence en cours proposée")
	fw.assert_eq(plan["skill"], "rimes", "même compétence")


func test_decouverte_dans_domaines_choisis() -> void:
	var c := ContentCatalog.new()
	c.register(_def("m.a", "rimes", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE))
	c.register(_def("n.a", "denombrement", ExerciseDefinition.DOMAIN_MATH))
	var p := _profile()
	p.selected_domains.append(ExerciseDefinition.DOMAIN_MATH)
	var plan: Dictionary = SessionPlanner.plan(p, c, 0.0, _rng())
	fw.assert_eq(plan["def"].domain, ExerciseDefinition.DOMAIN_MATH, "domaine choisi privilégié")


func test_filtre_age_respecte() -> void:
	var c := ContentCatalog.new()
	c.register(_def("v.a", "rimes", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE, 8, 10))
	var p := _profile(6)
	var plan: Dictionary = SessionPlanner.plan(p, c, 0.0, _rng())
	fw.assert_true(plan.is_empty(), "aucun exercice adapté → plan vide, pas de crash")


func test_items_facilites_aux_petits_niveaux() -> void:
	var c := ContentCatalog.new()
	c.register(_def("m.a", "rimes", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE))
	var p := _profile()
	p.store.set_level("rimes", 1)
	var plan: Dictionary = SessionPlanner.plan(p, c, 0.0, _rng())
	for it in plan["items"]:
		fw.assert_lte(it.difficulty_delta, 0, "niveau ≤ 2 : item facilité")


func test_decouverte_quand_catalogue_vide_de_progression() -> void:
	var c := ContentCatalog.new()
	c.register(_def("m.a", "rimes", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE))
	var plan: Dictionary = SessionPlanner.plan(_profile(), c, 0.0, _rng())
	fw.assert_eq(plan["mode"], SessionPlanner.MODE_DISCOVERY, "profil vierge → découverte")
	fw.assert_false(plan["items"].is_empty(), "items fournis")
