extends Node
## SpacedRepetitionManager — point d'accès global au planificateur de révisions.
## Fine couche au-dessus de core/spaced_repetition.gd (logique testée unitairement).

const SpacedRepetition := preload("res://core/spaced_repetition.gd")

var engine: RefCounted = SpacedRepetition.new()


func due_skills(day: float) -> Array[String]:
	return engine.due_skills(day)


func is_due(skill_id: String, day: float) -> bool:
	return engine.is_due(skill_id, day)


## Révisions dues du profil actif.
func active_due_skills() -> Array[String]:
	if Progress.active_profile == null:
		return []
	return engine.due_skills(Progress.today())
