class_name ChildProfile
extends RefCounted
## Profil enfant : préférences, domaines choisis, progression, révisions.
## Confidentialité par conception : prénom (ou surnom) au choix, aucun champ
## diagnostic, aucune donnée médicale — stockage 100 % local (JSON).

const SrTypes := preload("res://core/sr_types.gd")
const SessionRunner := preload("res://core/session_runner.gd")
const ProgressStore := preload("res://core/progress_store.gd")
const SkillLedger := preload("res://core/skill_ledger.gd")
const SpacedRepetition := preload("res://core/spaced_repetition.gd")

const MAX_DAILY_MINUTES := 20   ## Garde-fou de fatigabilité (réglable par l'adulte).
const DEFAULT_DAILY_MINUTES := 15

var profile_id := ""            ## Identifiant local (uuid via crypto).
var display_name := ""          ## Prénom ou surnom — jamais obligatoire.
var avatar_color := "#3752ed"
var age := 7                    ## Âge déclaré par l'adulte (filtre de contenu).
var daily_minutes := DEFAULT_DAILY_MINUTES

## Domaines sélectionnés par l'enfant/l'adulte — plusieurs possibles,
## aucune étiquette imposée.
var selected_domains: Array[String] = []

## Sous-composants (tous purs).
var store: RefCounted = ProgressStore.new()      ## Niveaux adaptatifs.
var ledger: RefCounted = SkillLedger.new()       ## Progression affichée.
var sr: RefCounted = SpacedRepetition.new()      ## Révisions espacées.

## Réglages d'accessibilité (clés cf. AccessibilityManager).
var accessibility: Dictionary = {}


func _init() -> void:
	profile_id = Crypto.new().generate_random_bytes(8).hex_encode()


func new_session_runner(def: Resource, items: Array) -> RefCounted:
	return SessionRunner.new(def, items)


## À appeler quand une session se termine : alimente ledger + révisions espacées.
func on_session_finished(stats: Dictionary) -> void:
	ledger.apply_session(stats)
	var skill_id: String = stats.get("skill", "")
	if skill_id.is_empty():
		return
	var day: float = float(stats.get("day", _now_day()))
	var failures := int(stats.get("failures", 0))
	var auto := int(stats.get("auto_successes", 0))
	var hint := int(stats.get("hint_solves", 0))
	if failures > 0 and auto == 0 and hint == 0:
		sr.process_event(SrTypes.LearningEvent.new(skill_id, day, false, false, false, true))
	elif hint > 0 and auto == 0:
		sr.process_event(SrTypes.LearningEvent.new(skill_id, day, false, true, true, false))
	else:
		sr.process_event(SrTypes.LearningEvent.new(skill_id, day, true, false, false, false))


func _now_day() -> float:
	return float(Time.get_unix_time_from_system()) / 86400.0


## --- Sérialisation locale (user://profiles/<id>.json) ---

func to_dict() -> Dictionary:
	return {
		"profile_id": profile_id,
		"display_name": display_name,
		"avatar_color": avatar_color,
		"age": age,
		"daily_minutes": daily_minutes,
		"selected_domains": selected_domains.duplicate(),
		"store": store.to_dict(),
		"ledger": ledger.to_dict(),
		"sr": _sr_to_dict(),
		"accessibility": accessibility.duplicate(),
	}


func load_dict(data: Dictionary) -> void:
	profile_id = String(data.get("profile_id", profile_id))
	display_name = String(data.get("display_name", ""))
	avatar_color = String(data.get("avatar_color", avatar_color))
	age = int(data.get("age", age))
	daily_minutes = int(data.get("daily_minutes", DEFAULT_DAILY_MINUTES))
	selected_domains.clear()
	for d in data.get("selected_domains", []):
		selected_domains.append(d)
	store.load_dict(data.get("store", {}))
	ledger.load_dict(data.get("ledger", {}))
	_sr_load(data.get("sr", {}))
	accessibility = data.get("accessibility", {}).duplicate()


func _sr_to_dict() -> Dictionary:
	var out := {}
	for skill_id in sr.records:
		var r: Resource = sr.records[skill_id]
		out[skill_id] = {
			"phase": r.phase, "mastery": r.mastery, "streak": r.streak,
			"reps": r.reps, "interval_days": r.interval_days, "ease": r.ease,
			"due_day": r.due_day, "lapses": r.lapses,
		}
	return out


func _sr_load(data: Dictionary) -> void:
	sr.records.clear()
	for skill_id in data:
		var r: Dictionary = data[skill_id]
		var rec: Resource = SrTypes.SkillRecord.new(skill_id, float(r.get("due_day", 0.0)))
		rec.phase = int(r.get("phase", 0))
		rec.mastery = float(r.get("mastery", 0.0))
		rec.streak = int(r.get("streak", 0))
		rec.reps = int(r.get("reps", 0))
		rec.interval_days = float(r.get("interval_days", 1.0))
		rec.ease = float(r.get("ease", 2.5))
		rec.lapses = int(r.get("lapses", 0))
		sr.records[skill_id] = rec
