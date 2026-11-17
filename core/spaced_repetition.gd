class_name SpacedRepetition
extends RefCounted
## Planification des révisions par répétition espacée (inspiration SM-2,
## adaptée à un usage pédagogique bienveillant, sans notation punitive).
##
## Principe : une compétence traverse trois phases —
##   phase 0 (découverte)   : travail rapproché, consolidation dès 3 réussites
##                            autonomes consécutives ;
##   phase 1 (consolidation): intervalles courts (1 → 2 → 4 jours) ;
##   phase 2 (révision)     : intervalles croissants modérés (×ease, plafond 45 j).
## Un échec (item non résolu même aidé) ramène la compétence en consolidation
## avec un intervalle court : on révise, on ne sanctionne pas.

const SrTypes := preload("res://core/sr_types.gd")

const CONSOLIDATION_STREAK := 3
const MIN_EASE := 1.3
const MAX_EASE := 2.5
const MAX_INTERVAL_DAYS := 45.0
const MASTERY_MAX := 1.0

## Records connus : skill_id -> SrTypes.SkillRecord
var records: Dictionary = {}


func get_or_create(skill_id: String, day: float) -> Resource:
	if records.has(skill_id):
		return records[skill_id]
	var rec: Resource = SrTypes.SkillRecord.new(skill_id, day)
	records[skill_id] = rec
	return rec


func process_event(ev: RefCounted) -> Resource:
	var rec: Resource = get_or_create(ev.skill_id, ev.day)
	var old_mastery: float = rec.mastery
	if ev.failure:
		_apply_failure(rec, ev.day)
	elif ev.auto_success:
		_apply_auto_success(rec, ev.day)
	else:
		_apply_assisted_success(rec, ev.day)
	rec.last_mastery_delta = rec.mastery - old_mastery
	return rec


func is_due(skill_id: String, day: float) -> bool:
	if not records.has(skill_id):
		return true
	var rec: Resource = records[skill_id]
	return day >= rec.due_day


func due_skills(day: float, exclude: Array = []) -> Array[String]:
	var out: Array[String] = []
	for skill_id in records.keys():
		if exclude.has(skill_id):
			continue
		if is_due(skill_id, day):
			out.append(skill_id)
	# On révise d'abord ce qui est le plus en retard.
	out.sort_custom(func(a, b): return records[a].due_day < records[b].due_day)
	return out


## Compétences à travailler en priorité : révisions dues d'abord, puis
## compétences en cours d'acquisition jamais terminées.
func priority_skills(day: float, in_progress: Array[String] = []) -> Array[String]:
	var out: Array[String] = due_skills(day)
	for skill_id in in_progress:
		if not out.has(skill_id):
			out.append(skill_id)
	return out


func _apply_auto_success(rec: Resource, day: float) -> void:
	match rec.phase:
		0:
			rec.streak += 1
			rec.mastery = clampf(rec.mastery + 0.1, 0.0, MASTERY_MAX)
			if rec.streak >= CONSOLIDATION_STREAK:
				rec.phase = 1
				rec.streak = 0
				rec.reps = 0
				rec.interval_days = 1.0
				rec.due_day = day + rec.interval_days
			else:
				rec.due_day = day  # revoir vite en phase découverte
		1:
			rec.reps += 1
			rec.mastery = clampf(rec.mastery + 0.1, 0.0, MASTERY_MAX)
			if rec.reps >= 3:
				rec.phase = 2
				rec.interval_days = 4.0
			else:
				rec.interval_days = float(1 << (rec.reps - 1))  # 1, 2
			rec.due_day = day + rec.interval_days
		_:
			rec.reps += 1
			rec.mastery = clampf(rec.mastery + 0.05, 0.0, MASTERY_MAX)
			rec.ease = clampf(rec.ease + 0.05, MIN_EASE, MAX_EASE)
			rec.interval_days = clampf(rec.interval_days * rec.ease, 1.0, MAX_INTERVAL_DAYS)
			rec.due_day = day + rec.interval_days


func _apply_assisted_success(rec: Resource, day: float) -> void:
	# Réussi, mais avec aide : on consolide sans progression d'intervalle.
	rec.mastery = clampf(rec.mastery + 0.05, 0.0, MASTERY_MAX)
	if rec.phase == 0:
		rec.streak = 0
	rec.due_day = day + 1.0


func _apply_failure(rec: Resource, day: float) -> void:
	rec.mastery = clampf(rec.mastery - 0.1, 0.0, MASTERY_MAX)
	rec.streak = 0
	rec.lapses += 1
	rec.ease = clampf(rec.ease - 0.2, MIN_EASE, MAX_EASE)
	if rec.phase == 2:
		rec.phase = 1  # retour temporaire, pas effacement
		rec.reps = 0
	rec.interval_days = 1.0
	rec.due_day = day + 1.0
