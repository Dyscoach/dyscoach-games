extends Node
## Test du replay de progression distante (scène bootée : autoloads réels).

func _ready() -> void:
	await get_tree().process_frame
	var body := JSON.stringify({
		"status": "success",
		"sessions": [
			{"exerciseId": "lec.detective_sons", "skill": "rimes", "items": 6, "auto": 6, "hints": 0, "failures": 0, "day": 20770.0},
			{"exerciseId": "lec.detective_sons", "skill": "rimes", "items": 6, "auto": 6, "hints": 0, "failures": 0, "day": 20771.0},
			{"exerciseId": "lec.detective_sons", "skill": "rimes", "items": 6, "auto": 5, "hints": 1, "failures": 0, "day": 20772.0},
		]
	})
	var WebBridge = load("res://autoload/web_bridge.gd")
	var bridge = WebBridge.new()
	add_child(bridge)
	var profile = Progress.create_profile("TestReplay", 10)
	Progress.select_profile(profile)
	bridge._on_progress_response(0, 200, PackedStringArray(), body.to_utf8_buffer(), null)
	var snap = profile.ledger.snapshot("rimes")
	print("ledger rimes: sessions=%d items=%d mastery=%.2f" % [snap.sessions_count, snap.items_done, snap.mastery])
	var rec = profile.sr.records.get("rimes")
	print("sr rimes: phase=%d streak=%d mastery=%.2f" % [rec.phase, rec.streak, rec.mastery])
	var ok: bool = snap.sessions_count == 3 and snap.items_done == 18 and rec.phase == 1 and rec.mastery > 0.25
	print("TEST REPLAY : %s" % ("OK" if ok else "ECHEC"))
	Progress.delete_profile(profile)
	get_tree().quit(0 if ok else 1)
