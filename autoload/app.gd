extends Node
## App — orchestrateur : navigation, session en cours, pause/arrêt.
## Les sessions sont courtes et interrompibles à tout moment (cahier des
## charges §4) : aucun état n'est perdu si l'enfant sort au milieu.

const SessionRunner := preload("res://core/session_runner.gd")

signal session_started
signal session_ended(stats: Dictionary)

var runner: RefCounted = null       ## SessionRunner actif (null hors session).
var current_def: Resource = null
var in_session: bool = false
var _paused := false


## Lance la session planifiée pour le profil actif (bouton « Jouer »).
func start_planned_session() -> bool:
	var plan: Dictionary = Progress.plan_next_session()
	if plan.is_empty():
		return false
	return start_session(plan["def"], plan["items"])


func start_session(def: Resource, items: Array) -> bool:
	if def == null or items.is_empty():
		return false
	current_def = def
	runner = SessionRunner.new(def, items)
	runner.session_finished.connect(_on_session_finished)
	in_session = true
	_paused = false
	session_started.emit()
	return true


func current_runner() -> RefCounted:
	return runner


func pause() -> void:
	if in_session:
		_paused = true


func resume() -> void:
	_paused = false


func is_paused() -> bool:
	return _paused


## Arrêt à tout moment, sans pénalité : la session est clôturée proprement.
func stop_session() -> void:
	if runner != null and in_session:
		runner.abandon()
	else:
		_cleanup()


func _on_session_finished(stats: Dictionary) -> void:
	Progress.on_session_finished(stats)
	session_ended.emit(stats)
	_cleanup()


func _cleanup() -> void:
	in_session = false
	runner = null
	current_def = null
