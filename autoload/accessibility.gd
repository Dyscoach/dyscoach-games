extends Node
## AccessibilityManager — l'accessibilité est un service CŒUR du moteur,
## pas une option : toutes les vues s'y réfèrent pour la présentation.
##
## Règles d'or (cahier des charges §5) :
##   - jamais d'information essentielle portée par la seule couleur ou le son ;
##   - consignes courtes, écoutables et répétables ;
##   - pas de défilement automatique des textes importants ;
##   - animations désactivables, effets réduits ;
##   - police « adaptée dyslexie » proposée comme PRÉFÉRENCE, jamais comme
##     traitement (affichage du libellé exact dans les réglages).

signal settings_changed

## --- Clés de réglage et valeurs par défaut ---
const KEY_FONT_SIZE := "font_size"                 # 0=petit 1=moyen 2=grand 3=très grand
const KEY_LETTER_SPACING := "letter_spacing"       # ratio 1.0..2.0
const KEY_LINE_SPACING := "line_spacing"           # ratio 1.0..2.0
const KEY_HIGH_CONTRAST := "high_contrast"         # bool
const KEY_FONT := "font"                           # "defaut" | "lisible" | "dys"
const KEY_PLAIN_BACKGROUND := "plain_background"   # bool (fonds simples)
const KEY_REDUCE_MOTION := "reduce_motion"         # bool (désactive animations)
const KEY_REDUCE_EFFECTS := "reduce_effects"       # bool (réduit effets visuels)
const KEY_SUBTITLES := "subtitles"                 # bool (sous-titres de l'audio utile)
const KEY_AUDIO_VOLUME := "audio_volume"           # 0.0..1.0
const KEY_VOICE_RATE := "voice_rate"               # 0.5..1.5 (vitesse consignes)

const FONTS := ["defaut", "lisible", "dys"]

## Préréglages de corps de texte (multiplicateurs de la taille de base).
const FONT_SCALES := [0.85, 1.0, 1.25, 1.6]

var settings: Dictionary = {}


func _ready() -> void:
	_reset_defaults()


func _reset_defaults() -> void:
	settings = {
		KEY_FONT_SIZE: 1,
		KEY_LETTER_SPACING: 1.0,
		KEY_LINE_SPACING: 1.0,
		KEY_HIGH_CONTRAST: false,
		KEY_FONT: "defaut",
		KEY_PLAIN_BACKGROUND: false,
		KEY_REDUCE_MOTION: false,
		KEY_REDUCE_EFFECTS: false,
		KEY_SUBTITLES: true,
		KEY_AUDIO_VOLUME: 0.8,
		KEY_VOICE_RATE: 1.0,
	}


func get_setting(key: String, fallback = null):
	return settings.get(key, fallback)


func set_setting(key: String, value) -> void:
	settings[key] = value
	settings_changed.emit()


func apply_profile(profile) -> void:
	_reset_defaults()
	for key in profile.accessibility:
		settings[key] = profile.accessibility[key]
	settings_changed.emit()


func export_to_profile(profile) -> void:
	profile.accessibility = settings.duplicate()


## Multiplicateur de taille de police pour la vue.
func font_scale() -> float:
	return FONT_SCALES[clampi(int(settings.get(KEY_FONT_SIZE, 1)), 0, FONT_SCALES.size() - 1)]


func font_size_step(delta: int) -> void:
	set_setting(KEY_FONT_SIZE, clampi(int(settings.get(KEY_FONT_SIZE, 1)) + delta, 0, 3))


## Nom lisible de la police (affichage réglages).
func font_label() -> String:
	match String(settings.get(KEY_FONT, "defaut")):
		"lisible": return "Lisible (sans serif, formes simples)"
		"dys": return "Adaptée dyslexie (préférence de confort de lecture)"
		_: return "Par défaut"


func reduce_motion() -> bool:
	return bool(settings.get(KEY_REDUCE_MOTION, false))


## Palette : jamais la couleur seule ne porte l'information — les vues
## combinent toujours couleur + forme/icône/texte.
func color_correct() -> Color:
	return Color("2e9e5b")   # vert + icône ✓ dans les vues

func color_error() -> Color:
	return Color("d9534f")   # rouge + icône ✗ et message écrit

func color_highlight() -> Color:
	return Color("ffd166")   # surbrillance douce

func text_color() -> Color:
	if bool(settings.get(KEY_HIGH_CONTRAST, false)):
		return Color("000000")
	return Color("22262e")

func background_color() -> Color:
	if bool(settings.get(KEY_HIGH_CONTRAST, false)):
		return Color("ffffff")
	if bool(settings.get(KEY_PLAIN_BACKGROUND, false)):
		return Color("f4f2ec")
	return Color("f9f5ec")   # crème doux par défaut
