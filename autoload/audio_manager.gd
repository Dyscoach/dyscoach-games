extends Node
## AudioManager — consignes audio : écoute, répétition, volume, vitesse.
## Le TTS passe par DisplayServer.tts quand disponible (desktop/mobile) ;
## sinon dégradation propre : le texte reste affiché et sous-titré
## (l'audio ne porte JAMAIS seul une information essentielle).

signal speak_started
signal speak_finished

var _tts_available := false
var _speaking := false

## Files d'attente minimales : id de message -> callable de substitution.
var _fallback_by_id: Dictionary = {}


func _ready() -> void:
	_tts_available = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
	if not _tts_available:
		push_warning("TTS indisponible : les consignes resteront écrites et sous-titrées.")


func tts_available() -> bool:
	return _tts_available


## Prononce une consigne. `subtitle` est TOUJOURS affiché par la vue.
func speak(text: String, subtitle: String = "") -> void:
	var rate: float = float(Access.get_setting(Access.KEY_VOICE_RATE, 1.0))
	var volume: float = float(Access.get_setting(Access.KEY_AUDIO_VOLUME, 0.8))
	_speaking = true
	speak_started.emit()
	if _tts_available and not text.is_empty():
		DisplayServer.tts_speak(text, "fr_FR", rate * 100.0, pitch_ratio(), volume * 100.0, false)
	# Fin de parole estimée (pas de callback universel TTS) : les vues
	# n'en dépendent pas pour la logique, uniquement pour l'animation.
	var est := _estimate_duration(text, rate)
	get_tree().create_timer(est).timeout.connect(_on_speak_done)


func stop_speaking() -> void:
	if _tts_available:
		DisplayServer.tts_stop()
	_speaking = false
	speak_finished.emit()


func is_speaking() -> bool:
	return _speaking


## Sons d'interface (réussite/erreur/index) : buffers générés pour le
## prototype — remplacés par des .ogg au moment de l'habillage sonore.
func play_success() -> void:
	_play_tone(660.0, 0.12)
	_play_tone(880.0, 0.16, 0.10)


func play_error() -> void:
	_play_tone(220.0, 0.18)


func play_hint() -> void:
	_play_tone(520.0, 0.10)
	_play_tone(520.0, 0.10, 0.14)


func play_click() -> void:
	_play_tone(440.0, 0.05)


# --- interne ---

func pitch_ratio() -> float:
	return clampf(1.05, 0.5, 2.0)


func _on_speak_done() -> void:
	_speaking = false
	speak_finished.emit()


func _estimate_duration(text: String, rate: float) -> float:
	# ~14 caractères/s en français à vitesse 1.0 (estimation prudente).
	var chars: float = maxf(float(text.length()), 1.0)
	return clampf(chars / (14.0 * maxf(rate, 0.1)), 0.4, 12.0)


func _play_tone(freq: float, dur: float, delay: float = 0.0) -> void:
	if bool(Access.get_setting(Access.KEY_REDUCE_EFFECTS, false)):
		return
	var player := AudioStreamPlayer.new()
	player.volume_db = linear_to_db(float(Access.get_setting(Access.KEY_AUDIO_VOLUME, 0.8)))
	player.stream = _tone_stream(freq, dur)
	add_child(player)
	player.finished.connect(player.queue_free)
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	player.play()


func _tone_stream(freq: float, dur: float) -> AudioStreamWAV:
	# Sinusoïde douce avec enveloppe (prototype sans banque de sons).
	var rate := 22050
	var n: int = maxi(int(dur * rate), 1)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var env: float = minf(t / 0.01, 1.0) * minf((dur - t) / 0.02, 1.0)
		var v: float = sin(TAU * freq * t) * env * 0.4
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav
