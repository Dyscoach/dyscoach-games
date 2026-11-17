class_name ProgressStore
extends RefCounted
## Stockage de la progression par compétence — composant PUR (aucun autoload),
## sérialisable en JSON pour la sauvegarde locale du profil enfant.

## skill_id -> {"level": int, "up_streak": int, "down_streak": int}
var _skills: Dictionary = {}
## Historique des sessions (locales, minimales, jamais envoyées nulle part).
var session_history: Array = []


func _entry(skill_id: String, default_level: int) -> Dictionary:
	if not _skills.has(skill_id):
		_skills[skill_id] = {"level": default_level, "up_streak": 0, "down_streak": 0}
	return _skills[skill_id]


func get_level(skill_id: String, default_level: int = 3) -> int:
	return int(_entry(skill_id, default_level)["level"])


func set_level(skill_id: String, level: int, default_level: int = 3) -> void:
	_entry(skill_id, default_level)["level"] = clampi(level, 1, 6)


func up_streak(skill_id: String, default_level: int = 3) -> int:
	return int(_entry(skill_id, default_level)["up_streak"])


func down_streak(skill_id: String, default_level: int = 3) -> int:
	return int(_entry(skill_id, default_level)["down_streak"])


func bump_up(skill_id: String, default_level: int = 3) -> void:
	var e := _entry(skill_id, default_level)
	e["up_streak"] = int(e["up_streak"]) + 1


func bump_down(skill_id: String, default_level: int = 3) -> void:
	var e := _entry(skill_id, default_level)
	e["down_streak"] = int(e["down_streak"]) + 1


func reset_up(skill_id: String, default_level: int = 3) -> void:
	_entry(skill_id, default_level)["up_streak"] = 0


func reset_down(skill_id: String, default_level: int = 3) -> void:
	_entry(skill_id, default_level)["down_streak"] = 0


func reset_skill(skill_id: String) -> void:
	_skills.erase(skill_id)


func record_session(entry: Dictionary) -> void:
	session_history.append(entry)


## --- Sérialisation (profil enfant, fichier local) ---

func to_dict() -> Dictionary:
	var skills := {}
	for skill_id in _skills:
		skills[skill_id] = _skills[skill_id].duplicate()
	return {"skills": skills, "session_history": session_history.duplicate()}


func load_dict(data: Dictionary) -> void:
	_skills.clear()
	session_history.clear()
	if data.has("skills"):
		for skill_id in data["skills"]:
			var e: Dictionary = data["skills"][skill_id]
			_skills[skill_id] = {
				"level": int(e.get("level", 3)),
				"up_streak": int(e.get("up_streak", 0)),
				"down_streak": int(e.get("down_streak", 0)),
			}
	if data.has("session_history"):
		for e in data["session_history"]:
			session_history.append(e)
