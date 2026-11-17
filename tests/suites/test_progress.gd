extends RefCounted
## Tests de progression (core/skill_ledger.gd), coffre de confidentialité
## (core/privacy_vault.gd) et profil enfant (core/child_profile.gd).

const SkillLedger := preload("res://core/skill_ledger.gd")
const PrivacyVault := preload("res://core/privacy_vault.gd")
const ChildProfile := preload("res://core/child_profile.gd")
const ProgressStore := preload("res://core/progress_store.gd")
const SpacedRepetition := preload("res://core/spaced_repetition.gd")
const SrTypes := preload("res://core/sr_types.gd")

var fw: RefCounted


func _session(skill: String, items: int, auto: int, hint: int, fail: int, level: int = 3, day: float = 10.0) -> Dictionary:
	return {
		"skill": skill, "items": items, "auto_successes": auto, "hint_solves": hint,
		"failures": fail, "level": level, "day": day, "exercise_id": "x.y",
	}


# ---------------- SkillLedger ----------------

func test_premiere_session_passe_en_cours() -> void:
	var l := SkillLedger.new()
	l.apply_session(_session("rimes", 6, 4, 2, 0))
	fw.assert_eq(l.snapshot("rimes").status, "in_progress", "compétence travaillée → en cours")
	fw.assert_eq(l.snapshot("jamais_vue"), null, "compétence inconnue → null")


func test_statuts_de_progression() -> void:
	var l := SkillLedger.new()
	# 4 sessions solides (≥ 80 % d'autonomie) → maîtrisée.
	for i in 4:
		l.apply_session(_session("rimes", 6, 5, 1, 0, 3, 10.0 + i))
	fw.assert_eq(l.snapshot("rimes").status, "mastered", "4 sessions solides → maîtrisée")
	# Une compétence à mi-parcours reste en cours.
	var l2 := SkillLedger.new()
	l2.apply_session(_session("fusion", 6, 3, 2, 1))
	fw.assert_eq(l2.snapshot("fusion").status, "in_progress", "profil mitigé → en cours")


func test_listes_pour_tableau_de_bord() -> void:
	var l := SkillLedger.new()
	l.apply_session(_session("a", 6, 6, 0, 0))
	l.apply_session(_session("b", 6, 6, 0, 0))
	for i in 4:
		l.apply_session(_session("b", 6, 6, 0, 0, 3, 10.0 + i))
	fw.assert_eq(l.worked_skills().size(), 2, "deux compétences travaillées")
	fw.assert_eq(l.mastered_skills(), ["b"], "seule b est maîtrisée")
	fw.assert_eq(l.in_progress_skills(), ["a"], "a en cours d'acquisition")


func test_taux_autonomie_et_difficultes_recurrentes() -> void:
	var l := SkillLedger.new()
	l.apply_session(_session("orth", 6, 2, 1, 3, 3, 10.0))
	l.apply_session(_session("orth", 6, 1, 2, 3, 2, 11.0))
	var s = l.snapshot("orth")
	fw.assert_almost_eq(s.mastery, (3.0 + 1.5) / 12.0, 0.001, "taux d'autonomie global")
	fw.assert_eq(s.failures, 6, "échecs cumulés")
	fw.assert_eq(s.last_level, 2, "dernier niveau travaillé")


func test_serialisation_complexe() -> void:
	var l := SkillLedger.new()
	l.apply_session(_session("a", 6, 5, 1, 0))
	var l2 := SkillLedger.new()
	l2.load_dict(l.to_dict())
	fw.assert_eq(l2.snapshot("a").items_done, 6, "items conservés")
	fw.assert_eq(l2.snapshot("a").status, "in_progress", "statut conservé")


# ---------------- PrivacyVault ----------------

func test_coffre_sans_code_accessible() -> void:
	var v := PrivacyVault.new()
	fw.assert_true(v.is_unlocked(), "pas de code → espace adulte accessible")
	v.set_pin("1234")
	fw.assert_false(v.is_unlocked(), "après pose du code → verrouillé")


func test_code_correct_deverrouille() -> void:
	var v := PrivacyVault.new()
	v.set_pin("1234")
	fw.assert_false(v.unlock("0000"), "code faux refusé")
	fw.assert_true(v.unlock("1234"), "bon code accepté")
	fw.assert_true(v.is_unlocked(), "coffre ouvert")


func test_aucun_code_en_clair_dans_la_sauvegarde() -> void:
	var v := PrivacyVault.new()
	v.set_pin("1234")
	var data := v.to_dict()
	var blob := str(data)
	fw.assert_false(blob.contains("1234"), "le code n'apparaît jamais en clair")
	fw.assert_true(str(data["pin_hash"]).length() >= 64, "empreinte solide stockée")


func test_changement_de_code() -> void:
	var v := PrivacyVault.new()
	v.set_pin("1234")
	v.unlock("1234")
	v.set_pin("9999")
	v.lock()
	fw.assert_false(v.unlock("1234"), "ancien code refusé")
	fw.assert_true(v.unlock("9999"), "nouveau code accepté")


# ---------------- ChildProfile ----------------

func test_profil_roundtrip_complet() -> void:
	var p := ChildProfile.new()
	p.display_name = "Camille"
	p.avatar_color = "#3752ed"
	p.selected_domains.append("langage_ecrit")
	p.selected_domains.append("mathematiques")
	p.store.set_level("rimes", 4)
	p.ledger.apply_session(_session("rimes", 6, 6, 0, 0))
	p.sr.process_event(SrTypes.LearningEvent.new("rimes", 12.0, true))
	var p2 := ChildProfile.new()
	p2.load_dict(p.to_dict())
	fw.assert_eq(p2.display_name, "Camille", "prénom conservé")
	fw.assert_eq(p2.selected_domains.size(), 2, "domaines choisis conservés")
	fw.assert_eq(p2.store.get_level("rimes"), 4, "niveau conservé")
	fw.assert_eq(p2.ledger.snapshot("rimes").items_done, 6, "progression conservée")
	fw.assert_almost_eq(p2.sr.records["rimes"].mastery, 0.1, 0.001, "révisions conservées")


func test_donnees_minimales_du_profil() -> void:
	var p := ChildProfile.new()
	var d := p.to_dict()
	fw.assert_not_has(d.keys(), "diagnostic", "aucun champ diagnostic dans le profil")
	fw.assert_false(str(d).contains("diagnostic"), "le mot diagnostic n'apparaît nulle part")
