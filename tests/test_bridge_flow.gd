extends Node
## Test du flux bridge : application du profil distant.
## (La navigation post-profil est couverte par le code _go_to_worlds et le smoke.)

func _ready() -> void:
	await get_tree().process_frame
	var profile := {
		"name": "Lou", "age": 10, "animal": "Renard", "dysTypes": [],
		"domains": ["mathematiques"], "childId": "test-child", "progressUrl": "",
	}
	var bridge = get_tree().root.get_node_or_null("/root/Bridge")
	if bridge == null:
		var WebBridge = load("res://autoload/web_bridge.gd")
		bridge = WebBridge.new()
		bridge.name = "Bridge"
		get_tree().root.add_child(bridge)
	bridge.apply_remote_profile(profile)
	var p = Progress.active_profile
	var ok_name: bool = p.display_name == "Lou"
	var ok_age: bool = p.age == 10
	var ok_domains: bool = p.selected_domains.has("mathematiques")
	print("profil: name=%s age=%d domains=%s" % [p.display_name, p.age, str(p.selected_domains)])
	var ok: bool = ok_name and ok_age and ok_domains
	print("TEST BRIDGE FLOW : %s" % ("OK" if ok else "ECHEC"))
	get_tree().quit(0 if ok else 1)
