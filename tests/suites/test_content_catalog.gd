extends RefCounted
## Tests du catalogue de contenus (core/content_catalog.gd).

const ContentCatalog := preload("res://core/content_catalog.gd")
const ExerciseDefinition := preload("res://core/exercise_definition.gd")
const ExerciseItem := preload("res://core/exercise_item.gd")

var fw: RefCounted


func _def(id: String, domain: String, skill: String, age_min: int, age_max: int) -> Resource:
	var d: Resource = ExerciseDefinition.new()
	d.exercise_id = id
	d.display_name = id
	d.domain = domain
	d.skill = skill
	d.age_min = age_min
	d.age_max = age_max
	d.instruction_text = "Consigne."
	d.scene_path = "res://games/x.tscn"
	var it: Resource = ExerciseItem.new()
	it.item_id = "i1"
	it.prompt_text = "mot"
	it.add_answer("mot")
	it.add_hint("Indice.")
	d.add_item(it)
	return d


func test_enregistrement_et_recherche() -> void:
	var c := ContentCatalog.new()
	c.register(_def("lec.a", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE, "fusion_sons", 6, 8))
	fw.assert_ne(c.get_def("lec.a"), null, "fiche retrouvée par id")
	fw.assert_eq(c.get_def("inconnu"), null, "id inconnu → null")
	fw.assert_eq(c.all().size(), 1, "une fiche au catalogue")


func test_fiche_invalide_refusee() -> void:
	var c := ContentCatalog.new()
	var d := _def("lec.b", ExerciseDefinition.DOMAIN_MATH, "denombrement", 6, 8)
	d.domain = "sorcellerie"
	c.register(d)
	fw.assert_eq(c.all().size(), 0, "fiche invalide rejetée à l'enregistrement")
	fw.assert_true(c.validation_errors().has("lec.b"), "l'erreur est rapportée")


func test_fiche_en_double_refusee() -> void:
	var c := ContentCatalog.new()
	c.register(_def("math.a", ExerciseDefinition.DOMAIN_MATH, "comparaison", 6, 8))
	c.register(_def("math.a", ExerciseDefinition.DOMAIN_MATH, "comparaison", 6, 8))
	fw.assert_eq(c.all().size(), 1, "doublon d'id refusé")
	fw.assert_has(c.validation_errors()["math.a"], "exercise_id_duplique", "erreur de doublon explicite")


func test_filtrage_par_domaine_et_age() -> void:
	var c := ContentCatalog.new()
	c.register(_def("lec.a", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE, "rimes", 6, 7))
	c.register(_def("math.a", ExerciseDefinition.DOMAIN_MATH, "ligne_numerique", 8, 10))
	c.register(_def("math.b", ExerciseDefinition.DOMAIN_MATH, "denombrement", 5, 7))
	fw.assert_eq(c.by_domain(ExerciseDefinition.DOMAIN_MATH).size(), 2, "deux fiches maths")
	var age6: Array = c.available_for_age(6)
	fw.assert_eq(age6.size(), 2, "age 6 : lec.a et math.b")
	var age9: Array = c.available_for_age(9)
	fw.assert_eq(age9.size(), 1, "age 9 : math.a seule")


func test_filtrage_par_competence() -> void:
	var c := ContentCatalog.new()
	c.register(_def("lec.a", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE, "rimes", 6, 7))
	c.register(_def("lec.b", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE, "rimes", 6, 7))
	c.register(_def("lec.c", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE, "fusion_sons", 6, 7))
	fw.assert_eq(c.by_skill("rimes").size(), 2, "deux fiches pour la compétence rimes")


func test_prerequis_verifies() -> void:
	var c := ContentCatalog.new()
	var d := _def("lec.avance", ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE, "decodage", 6, 8)
	d.add_prerequisite("fusion_sons")
	c.register(d)
	fw.assert_false(c.prerequisites_ready(d, []), "sans acquis : pas prêt")
	fw.assert_true(c.prerequisites_ready(d, ["fusion_sons"]), "avec l'acquis : prêt")


func test_libelle_de_competence() -> void:
	var c := ContentCatalog.new()
	fw.assert_eq(c.skill_label("fusion_sons"), "Fusion de sons", "libellé lisible")
	fw.assert_eq(c.skill_label("competence_mystere"), "competence_mystere", "fallback = id")
