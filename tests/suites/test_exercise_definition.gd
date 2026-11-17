extends RefCounted
## Tests de core/exercise_definition.gd : validation des fiches et des items.

const ExerciseDefinition := preload("res://core/exercise_definition.gd")
const ExerciseItem := preload("res://core/exercise_item.gd")

var fw: RefCounted


func _def() -> Resource:
	var def: Resource = ExerciseDefinition.new()
	def.exercise_id = "test.exemple"
	def.display_name = "Exemple"
	def.domain = ExerciseDefinition.DOMAIN_WRITTEN_LANGUAGE
	def.skill = "segmentation_syllabique"
	def.age_min = 6
	def.age_max = 8
	def.instruction_text = "Touche le wagon où tu entends [o]."
	def.scene_path = "res://games/syllable_train.tscn"
	def.add_item(_item_ok("chat"))
	def.add_item(_item_ok("robot"))
	return def


func _item_ok(word: String) -> Resource:
	var it: Resource = ExerciseItem.new()
	it.item_id = "it_" + word
	it.prompt_text = word
	it.add_answer(word)
	it.add_hint("Écoute bien la première syllabe.")
	it.add_hint("Compte les syllabes sur tes doigts.")
	return it


func test_fiche_minimale_valide() -> void:
	fw.assert_valid(_def(), "fiche complète")


func test_fiche_sans_id_invalide() -> void:
	var d := _def()
	d.exercise_id = ""
	fw.assert_has(d.validate(), "exercise_id_manquant", "doit signaler l'id manquant")


func test_domaine_inconnu_invalide() -> void:
	var d := _def()
	d.domain = "telepathie"
	fw.assert_has(d.validate(), "domaine_inconnu", "domaine non répertorié rejeté")


func test_item_sans_reponse_invalide() -> void:
	var it: Resource = ExerciseItem.new()
	it.item_id = "x1"
	it.prompt_text = "mot"
	var d := _def()
	d.items.clear()
	d.add_item(it)
	fw.assert_has(d.validate(), "item0_item_sans_reponse", "item sans réponse refusé")


func test_item_doit_avoir_au_moins_un_indice() -> void:
	var it: Resource = ExerciseItem.new()
	it.item_id = "x2"
	it.prompt_text = "mot"
	it.add_answer("chat")
	var d := _def()
	d.items.clear()
	d.add_item(it)
	fw.assert_has(d.validate(), "item0_item_sans_indice", "indice progressif obligatoire")


func test_ids_d_items_dupliques_refuses() -> void:
	var d := _def()
	var a := _item_ok("chat")
	var b := _item_ok("loup")
	b.item_id = a.item_id
	d.items.clear()
	d.add_item(a)
	d.add_item(b)
	fw.assert_has(d.validate(), "item_id_duplique:it_chat", "doublon d'id item détecté")
