class_name PrivacyVault
extends RefCounted
## Coffre de l'espace adulte : code PIN hashé (SHA-256 + sel), jamais en clair.
## Composant PUR ; la persistance passe par le profil (JSON local).

const SALT := "dyscoach-jeux-vault-v1"

var _pin_hash := ""
var _locked := true


func set_pin(pin: String) -> void:
	_pin_hash = _hash(pin)


func has_pin() -> bool:
	return not _pin_hash.is_empty()


func unlock(pin: String) -> bool:
	if not has_pin():
		_locked = false
		return true
	var ok := _hash(pin) == _pin_hash
	_locked = not ok
	return ok


func lock() -> void:
	_locked = true


func is_unlocked() -> bool:
	return not has_pin() or not _locked


func _hash(pin: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update((SALT + pin).to_utf8_buffer())
	return ctx.finish().hex_encode()


func to_dict() -> Dictionary:
	return {"pin_hash": _pin_hash}


func load_dict(data: Dictionary) -> void:
	_pin_hash = String(data.get("pin_hash", ""))
	_locked = not _pin_hash.is_empty()
