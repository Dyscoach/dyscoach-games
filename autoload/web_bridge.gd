extends Node
## GodotWebBridge — passerelle Web entre dyscoach.com et le moteur de jeux.
##
## Parent (dyscoach.com) → moteur : postMessage {"type":"dyscoach-profile", "profile":{...}}
## Moteur → parent : postMessage {"type":"dyscoach-ready"|"dyscoach-session", ...}
##
## En natif (hors Web) le pont est inactif : le profil local du moteur est utilisé.

signal profile_received(profile: Dictionary)
signal session_report(stats: Dictionary)

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
