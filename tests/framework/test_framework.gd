extends RefCounted
## Micro-framework de tests headless, volontairement minimal (aucun plugin).
## Chaque assertion renvoie bool pour permettre `assert ... or fw.fail(...)`.
## Aucune erreur n'est avalée : un script qui ne charge pas plante la suite.

var _current_suite := ""
var _current_test := ""
var failures := 0
var assertion_count := 0


func begin(suite: String, test: String) -> void:
	_current_suite = suite
	_current_test = test


func fail(message: String) -> bool:
	failures += 1
	printerr("FAIL  %s :: %s — %s" % [_current_suite, _current_test, message])
	return false


func _check(cond: bool, label: String, got, expected) -> bool:
	assertion_count += 1
	if cond:
		return true
	var g := str(got)
	var e := str(expected)
	if g.length() > 110:
		g = g.substr(0, 107) + "..."
	if e.length() > 110:
		e = e.substr(0, 107) + "..."
	return fail("%s — obtenu=[%s] attendu=[%s]" % [label, g, e])


func assert_true(cond: bool, label: String = "doit être vrai") -> bool:
	return _check(cond, label, cond, true)


func assert_false(cond: bool, label: String = "doit être faux") -> bool:
	return _check(not cond, label, cond, false)


func assert_eq(got, expected, label: String = "égalité") -> bool:
	return _check(got == expected, label, got, expected)


func assert_ne(got, expected, label: String = "différence") -> bool:
	return _check(got != expected, label, got, expected)


func assert_gt(got, expected, label: String = "doit être supérieur") -> bool:
	return _check(got > expected, label, got, expected)


func assert_gte(got, expected, label: String = "doit être supérieur ou égal") -> bool:
	return _check(got >= expected, label, got, expected)


func assert_lt(got, expected, label: String = "doit être inférieur") -> bool:
	return _check(got < expected, label, got, expected)


func assert_lte(got, expected, label: String = "doit être inférieur ou égal") -> bool:
	return _check(got <= expected, label, got, expected)


func assert_almost_eq(got: float, expected: float, eps: float, label: String = "valeur approchée") -> bool:
	return _check(absf(got - expected) <= eps, label, got, expected)


func assert_has(arr: Array, value, label: String = "doit contenir") -> bool:
	return _check(arr.has(value), label, arr, value)


func assert_not_has(arr: Array, value, label: String = "ne doit pas contenir") -> bool:
	return _check(not arr.has(value), label, arr, value)


func assert_between(v: float, lo: float, hi: float, label: String = "intervalle") -> bool:
	return _check(v >= lo and v <= hi, label, v, "%s..%s" % [lo, hi])


func assert_valid(def, label: String = "fiche valide") -> bool:
	assertion_count += 1
	if def == null:
		return fail("%s : objet null" % label)
	if not def.has_method("validate"):
		return fail("%s : validate() absent sur %s" % [label, def])
	var errors: Array = def.validate()
	if errors.is_empty():
		return true
	return fail("%s — erreurs=%s" % [label, errors])
