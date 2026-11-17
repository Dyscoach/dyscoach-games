class_name SkillLedger
extends RefCounted
## Registre de progression par compétence — alimente le tableau de bord adulte.
## Composant PUR : reçoit les sessions terminées, produit des instantanés.
##
## Prudence pédagogique : « maîtrisée » = indicateur DANS l'application
## (4 sessions solides récentes), jamais une évaluation clinique.

const SrTypes := preload("res://core/sr_types.gd")

const STATUS_NOT_STARTED := "not_started"
const STATUS_IN_PROGRESS := "in_progress"
const STATUS_MASTERED := "mastered"

## Sessions solides consécutives requis pour l'état « maîtrisée ».
const MASTERED_SESSIONS := 4
## Taux d'autonomie pondéré (auto + 0.5 × aidée) au-delà duquel une session
## compte comme solide.
const SOLID_RATE := 0.8

var _skills: Dictionary = {}  ## skill_id -> Dictionary cumulatif


func apply_session(session: Dictionary) -> void:
	var skill_id: String = session.get("skill", "")
	if skill_id.is_empty():
		return
	var rec: Dictionary = _entry(skill_id)
	rec["sessions_count"] = int(rec["sessions_count"]) + 1
	rec["items_done"] = int(rec["items_done"]) + int(session.get("items", 0))
	rec["attempts"] = int(rec["attempts"]) + int(session.get("attempts", 0))
	rec["auto_successes"] = int(rec["auto_successes"]) + int(session.get("auto_successes", 0))
	rec["hint_uses"] = int(rec["hint_uses"]) + int(session.get("hint_solves", 0))
	rec["failures"] = int(rec["failures"]) + int(session.get("failures", 0))
	rec["last_level"] = int(session.get("level", rec["last_level"]))
	rec["last_day"] = float(session.get("day", rec["last_day"]))
	var ex: String = session.get("exercise_id", "")
	if not ex.is_empty() and not (rec["exercise_ids"] as Array).has(ex):
		(rec["exercise_ids"] as Array).append(ex)
	# Session solide = autonomie pondérée ≥ 80 %.
	var items: int = maxi(int(session.get("items", 0)), 1)
	var rate: float = (float(session.get("auto_successes", 0)) + 0.5 * float(session.get("hint_solves", 0))) / items
	if rate >= SOLID_RATE:
		rec["solid_streak"] = int(rec["solid_streak"]) + 1
	else:
		rec["solid_streak"] = 0
	rec["mastery"] = _auto_rate(rec)
	rec["status"] = STATUS_MASTERED if int(rec["solid_streak"]) >= MASTERED_SESSIONS else STATUS_IN_PROGRESS


func snapshot(skill_id: String):
	var rec: Dictionary = _skills.get(skill_id, {})
	if rec.is_empty():
		return null
	var snap = SrTypes.SkillSnapshot.new()
	snap.skill_id = skill_id
	snap.status = rec["status"]
	snap.mastery = rec["mastery"]
	snap.sessions_count = rec["sessions_count"]
	snap.items_done = rec["items_done"]
	snap.attempts = rec["attempts"]
	snap.auto_successes = rec["auto_successes"]
	snap.hint_uses = rec["hint_uses"]
	snap.failures = rec["failures"]
	snap.last_level = rec["last_level"]
	snap.last_day = rec["last_day"]
	snap.exercise_ids = (rec["exercise_ids"] as Array).duplicate()
	snap.error_tags = (rec["error_tags"] as Dictionary).duplicate()
	return snap


func worked_skills() -> Array[String]:
	return _skills.keys()


func mastered_skills() -> Array[String]:
	return _filter_status(STATUS_MASTERED)


func in_progress_skills() -> Array[String]:
	return _filter_status(STATUS_IN_PROGRESS)


func _filter_status(status: String) -> Array[String]:
	var out: Array[String] = []
	for skill_id in _skills.keys():
		if _skills[skill_id]["status"] == status:
			out.append(skill_id)
	return out


func _entry(skill_id: String) -> Dictionary:
	if not _skills.has(skill_id):
		_skills[skill_id] = {
			"status": STATUS_IN_PROGRESS, "mastery": 0.0,
			"sessions_count": 0, "items_done": 0, "attempts": 0,
			"auto_successes": 0, "hint_uses": 0, "failures": 0,
			"solid_streak": 0, "last_level": 0, "last_day": -1.0,
			"exercise_ids": [], "error_tags": {},
		}
	return _skills[skill_id]


func _auto_rate(rec: Dictionary) -> float:
	var done: int = int(rec["items_done"])
	if done <= 0:
		return 0.0
	return (float(rec["auto_successes"]) + 0.5 * float(rec["hint_uses"])) / float(done)


## --- Sérialisation ---

func to_dict() -> Dictionary:
	var out := {}
	for skill_id in _skills:
		var rec: Dictionary = _skills[skill_id]
		var copy := {}
		for key in rec:
			var value = rec[key]
			if value is Array:
				copy[key] = (value as Array).duplicate()
			elif value is Dictionary:
				copy[key] = (value as Dictionary).duplicate()
			else:
				copy[key] = value
		out[skill_id] = copy
	return {"skills": out}


func load_dict(data: Dictionary) -> void:
	_skills.clear()
	var skills: Dictionary = data.get("skills", {})
	for skill_id in skills:
		_skills[skill_id] = skills[skill_id].duplicate()
