class_name SessionPlanner
extends RefCounted
## Choix du prochain exercice : révisions dues d'abord (répétition espacée),
## puis compétences en cours, puis découverte dans les domaines choisis.
## Composant PUR (profile/catalog injectés).

const ExerciseDefinition := preload("res://core/exercise_definition.gd")

const MODE_REVISION := "revision"
const MODE_TRAINING := "entrainement"
const MODE_DISCOVERY := "decouverte"


## Retourne {"def", "items", "skill", "mode"} ou {} si rien de jouable.
static func plan(profile, catalog, day: float, rng: RandomNumberGenerator) -> Dictionary:
	var level_cache := {}
	# 1. Révisions dues, les plus en retard d'abord.
	for skill_id in profile.sr.due_skills(day):
		var pick := _pick_for_skill(profile, catalog, skill_id, day, rng, level_cache)
		if not pick.is_empty():
			pick["mode"] = MODE_REVISION
			return pick
	# 2. Compétences en cours d'acquisition.
	for skill_id in profile.ledger.in_progress_skills():
		var pick := _pick_for_skill(profile, catalog, skill_id, day, rng, level_cache)
		if not pick.is_empty():
			pick["mode"] = MODE_TRAINING
			return pick
	# 3. Découverte : domaine(s) choisi(s) en priorité, sinon tout.
	var pool: Array = catalog.available_for_age(profile.age)
	if not profile.selected_domains.is_empty():
		var preferred: Array = []
		for d in pool:
			if profile.selected_domains.has(d.domain):
				preferred.append(d)
		if not preferred.is_empty():
			pool = preferred
	if pool.is_empty():
		return {}
	pool.shuffle()
	var def: Resource = pool[0]
	var skill_id: String = def.skill
	var level: int = profile.store.get_level(skill_id, def.base_level)
	return {
		"def": def,
		"items": _items_for_level(def, level, rng),
		"skill": skill_id,
		"mode": MODE_DISCOVERY,
	}


static func _pick_for_skill(profile, catalog, skill_id: String, day: float, rng: RandomNumberGenerator, level_cache: Dictionary) -> Dictionary:
	for def in catalog.by_skill(skill_id):
		if def.age_min > profile.age or def.age_max < profile.age:
			continue
		if not profile.selected_domains.is_empty() and not profile.selected_domains.has(def.domain):
			continue
		var level: int = profile.store.get_level(skill_id, def.base_level)
		var items := _items_for_level(def, level, rng)
		if items.is_empty():
			continue
		return {"def": def, "items": items, "skill": skill_id}
	return {}


## Tirage restreint au niveau adaptatif courant :
##   niveaux 1-2 → items facilités (delta ≤ 0), niveaux 5-6 → items exigeants (delta ≥ 0).
static func _items_for_level(def: Resource, level: int, rng: RandomNumberGenerator) -> Array:
	var count: int = int(def.param("items_per_session", 6))
	var pool: Array = def.pick_items(rng, count)
	if level <= 2:
		pool = pool.filter(func(it): return it.difficulty_delta <= 0)
	elif level >= 5:
		pool = pool.filter(func(it): return it.difficulty_delta >= 0)
	return pool
