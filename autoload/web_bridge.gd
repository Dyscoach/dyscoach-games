extends Node
## GodotWebBridge — passerelle Web entre dyscoach.com et le moteur de jeux.
##
## Parent (dyscoach.com) → moteur : postMessage {"type":"dyscoach-profile", "profile":{...}}
## Moteur → parent : postMessage {"type":"dyscoach-ready"|"dyscoach-session", ...}
##
## En natif (hors Web) le pont est inactif : le profil local du moteur est utilisé.

signal profile_received(profile: Dictionary)
signal session_report(stats: Dictionary)

const SrTypes := preload("res://core/sr_types.gd")

var _web_ok := false
var has_remote_profile := false
var _profile: Dictionary = {}


func _ready() -> void:
	_web_ok = OS.has_feature("web")
	if not _web_ok:
		return
	# 1. Côté JS : stocke le dernier message reçu et prévient Godot par un flag.
	JavaScriptBridge.eval("""
		(function(){
			if (window.__dyscoachInstalled) return;
			window.__dyscoachInstalled = true;
			window.__dyscoachInbox = null;
			window.addEventListener('message', function(ev){
				if (ev.data && ev.data.type === 'dyscoach-profile') {
					window.__dyscoachInbox = ev.data;
				}
			});
		})();
	""", true)
	# 2. Annonce le moteur prêt au parent.
	send_to_parent({"type": "dyscoach-ready", "catalog": Content.all().size()})


## Polling continu : consomme le profil du parent dès qu'il arrive, où que soit
## le moteur (accueil, monde, session). Applique le profil puis bascule sur la
## carte des mondes si on était sur l'écran d'accueil local.
func _process(_delta: float) -> void:
	if _web_ok and not has_remote_profile:
		var remote := poll_profile()
		if not remote.is_empty():
			apply_remote_profile(remote)
			_go_to_worlds()


## Consomme le profil reçu du parent s'il y en a un (polling léger au démarrage).
func poll_profile() -> Dictionary:
	if not _web_ok or has_remote_profile:
		return _profile
	var inbox = JavaScriptBridge.eval("JSON.stringify(window.__dyscoachInbox || null)", true)
	var raw := str(inbox)
	if raw == "null" or raw.is_empty():
		return _profile
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary and parsed.get("type", "") == "dyscoach-profile":
		has_remote_profile = true
		_profile = parsed.get("profile", {})
		profile_received.emit(_profile)
		JavaScriptBridge.eval("window.__dyscoachInbox = null;", true)
	return _profile


## Applique le profil du parent au profil local du moteur :
## nom/âge/domaines repris, progression LOCALE conservée par identité (nom+âge).
func apply_remote_profile(profile: Dictionary) -> void:
	if profile.is_empty():
		return
	_profile = profile
	has_remote_profile = true
	var name := str(profile.get("name", ""))
	var age := int(profile.get("age", 0))
	var domains: Array = profile.get("domains", [])
	# Le profil local actif du moteur suit l'identité distante.
	if Progress.active_profile == null:
		var p := Progress.create_profile(name, maxi(age, 5))
		Progress.select_profile(p)
	else:
		Progress.active_profile.display_name = name
		if age > 0:
			Progress.active_profile.age = age
		Progress.save_profile(Progress.active_profile)
	if not domains.is_empty():
		Progress.active_profile.selected_domains.clear()
		for d in domains:
			Progress.active_profile.selected_domains.append(str(d))
		Progress.save_profile(Progress.active_profile)
	_progress_url = str(profile.get("progressUrl", ""))
	# Rejoue la progression serveur si disponible (asynchrone, non bloquant).
	if not _progress_url.is_empty():
		_fetch_progress(_progress_url)


var _progress_url := ""


## Récupère la progression serveur (URL fournie par le parent) et la rejoue
## dans le moteur : révisions espacées, niveaux adaptatifs et registre de
## compétences retrouvent leur état à l'identique.
## Le navigateur envoie les cookies de session dyscoach.com (fetch same-origin
## en prod ; le parent fournit l'URL absolue incluant childId en dev).
func _fetch_progress(url: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_progress_response.bind(http))
	var err := http.request(url, PackedStringArray(), HTTPClient.METHOD_GET)
	if err != OK:
		push_warning("godot-progress fetch impossible : %d" % err)


func _on_progress_response(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	if http != null:
		http.queue_free()
	if code != 200:
		push_warning("godot-progress HTTP %d" % code)
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed == null or not (parsed is Dictionary) or parsed.get("status", "") != "success":
		return
	var sessions: Array = parsed.get("sessions", [])
	if sessions.is_empty():
		return
	var profile = Progress.active_profile
	if profile == null:
		return
	# Rejoue les sessions dans l'ordre chronologique.
	for s in sessions:
		var day := float(s.get("day", 0.0))
		var skill_id := str(s.get("skill", ""))
		var stats := {
			"skill": skill_id,
			"exercise_id": str(s.get("exerciseId", "")),
			"items": int(s.get("items", 0)),
			"auto_successes": int(s.get("auto", 0)),
			"hint_solves": int(s.get("hints", 0)),
			"failures": int(s.get("failures", 0)),
			"level": profile.store.get_level(skill_id, 3),
			"day": day,
		}
		profile.ledger.apply_session(stats)
		if skill_id.is_empty():
			continue
		var auto := int(stats["auto_successes"])
		var hint := int(stats["hint_solves"])
		if int(stats["failures"]) > 0 and auto == 0 and hint == 0:
			profile.sr.process_event(SrTypes.LearningEvent.new(skill_id, day, false, false, false, true))
		elif hint > 0 and auto == 0:
			profile.sr.process_event(SrTypes.LearningEvent.new(skill_id, day, false, true, true, false))
		else:
			profile.sr.process_event(SrTypes.LearningEvent.new(skill_id, day, true, false, false, false))


## Bascule vers la carte des mondes si on est sur l'écran d'accueil local
## (l'enfant arrive avec son profil depuis dyscoach.com : pas de sélection locale).
func _go_to_worlds() -> void:
	var current := get_tree().current_scene
	if current == null:
		return
	if current.scene_file_path == "res://ui/screens/home.tscn":
		get_tree().change_scene_to_file("res://ui/screens/worlds.tscn")


## Envoie un message JSON à la page parente.
func send_to_parent(msg: Dictionary) -> void:
	if not _web_ok:
		return
	var json := JSON.stringify(msg)
	JavaScriptBridge.eval("""
		(function(m){
			if (window.parent !== window) {
				window.parent.postMessage(JSON.parse(m), '*');
			}
		})('%s');
	""" % json.replace("'", "\'"), true)


## Signale la fin d'une session au parent (progression pour le tableau de bord).
func report_session(stats: Dictionary) -> void:
	session_report.emit(stats)
	send_to_parent({
		"type": "dyscoach-session",
		"stats": {
			"exercise_id": stats.get("exercise_id", ""),
			"skill": stats.get("skill", ""),
			"items": stats.get("items", 0),
			"auto_successes": stats.get("auto_successes", 0),
			"hint_solves": stats.get("hint_solves", 0),
			"failures": stats.get("failures", 0),
		}
	})
