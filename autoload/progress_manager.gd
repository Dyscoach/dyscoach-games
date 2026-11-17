extends Node
## ProgressManager — persistance locale des profils enfants (user://).
## Confidentialité par conception : fichiers locaux uniquement, aucun envoi
## réseau, aucune donnée médicale, suppression complète possible.

const ChildProfile := preload("res://core/child_profile.gd")

const PROFILES_DIR := "user://profiles"
const MANIFEST := "user://profiles/manifest.json"

signal profiles_changed

var profiles: Array = []      ## Array[RefCounted ChildProfile]
var active_profile: RefCounted = null
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILES_DIR))
	load_manifest()


## --- Cycle de vie des profils ---

func create_profile(display_name: String, age: int) -> RefCounted:
	var p := ChildProfile.new()
	p.display_name = display_name.strip_edges()
	p.age = age
	profiles.append(p)
	save_profile(p)
	profiles_changed.emit()
	return p


func delete_profile(p: RefCounted) -> void:
	profiles.erase(p)
	if active_profile == p:
		active_profile = null
	var path := "%s/%s.json" % [PROFILES_DIR, p.profile_id]
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_write_manifest()
	profiles_changed.emit()


func select_profile(p: RefCounted) -> void:
	active_profile = p
	if p != null:
		Access.apply_profile(p)
	profiles_changed.emit()


## --- Jour courant (epoch jours, fractionnaire) — injecté pour les tests ---

func today() -> float:
	return float(Time.get_unix_time_from_system()) / 86400.0


## --- Planification & adaptation ---

func current_level(skill_id: String, def: Resource) -> int:
	if active_profile == null:
		return def.base_level
	return active_profile.store.get_level(skill_id, def.base_level)


## Construit la session proposée à l'enfant (révision/entraînement/découverte).
func plan_next_session() -> Dictionary:
	if active_profile == null or Content.catalog.all().is_empty():
		return {}
	var SessionPlanner := preload("res://core/session_planner.gd")
	return SessionPlanner.plan(active_profile, Content.catalog, today(), _rng)


## À appeler quand une session se termine (stats du SessionRunner).
func on_session_finished(stats: Dictionary) -> void:
	if active_profile == null:
		return
	stats["day"] = stats.get("day", today())
	active_profile.on_session_finished(stats)
	var def: Resource = Content.get_def(String(stats.get("exercise_id", "")))
	if def != null:
		var AdaptiveEngine := preload("res://core/adaptive_engine.gd")
		var engine := AdaptiveEngine.new()
		stats["level"] = active_profile.store.get_level(def.skill, def.base_level)
		engine.apply_session_result(def, active_profile.store, def.skill, stats, today())
	save_profile(active_profile)


## --- Tableau de bord adulte ---

func dashboard_rows() -> Array:
	if active_profile == null:
		return []
	var rows: Array = []
	for skill_id in active_profile.ledger.worked_skills():
		var snap = active_profile.ledger.snapshot(skill_id)
		rows.append({
			"skill": skill_id,
			"label": Content.skill_label(skill_id),
			"status": snap.status,
			"mastery": snap.mastery,
			"sessions": snap.sessions_count,
			"items": snap.items_done,
			"failures": snap.failures,
			"level": snap.last_level,
		})
	return rows


## --- Persistance ---

func save_profile(p: RefCounted) -> void:
	var path := "%s/%s.json" % [PROFILES_DIR, p.profile_id]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Écriture impossible : %s" % path)
		return
	f.store_string(JSON.stringify(p.to_dict(), "\t", false))
	f.close()
	_write_manifest()


func _write_manifest() -> void:
	var ids := []
	for p in profiles:
		ids.append({"id": p.profile_id, "name": p.display_name, "age": p.age})
	var f := FileAccess.open(MANIFEST, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"profiles": ids}, "\t", false))
		f.close()


func load_manifest() -> void:
	profiles.clear()
	if not FileAccess.file_exists(MANIFEST):
		return
	var f := FileAccess.open(MANIFEST, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed == null or not parsed.has("profiles"):
		return
	for entry in parsed["profiles"]:
		var path := "%s/%s.json" % [PROFILES_DIR, String(entry["id"])]
		if not FileAccess.file_exists(path):
			continue
		var pf := FileAccess.open(path, FileAccess.READ)
		if pf == null:
			continue
		var data = JSON.parse_string(pf.get_as_text())
		pf.close()
		if data == null:
			continue
		var p := ChildProfile.new()
		p.load_dict(data)
		profiles.append(p)
