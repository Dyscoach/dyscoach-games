extends "res://games/game_view.gd"
## Le robot à guider : séquencer des ordres (avancer / droite / gauche)
## pour amener le robot au cadeau. La grille affiche le robot 🤖, la cible 🎁,
## et le chemin déjà parcouru. Les flèches portent icône + couleur + texte.

const GAME_BUTTON := preload("res://ui/components/game_button.tscn")

## Directions (repère écran : +x = droite, +y = bas).
const DIRS := {
	"avant": Vector2i(0, -1),
	"droite": Vector2i(1, 0),
	"gauche": Vector2i(-1, 0),
	"arrière": Vector2i(0, 1),
}

var _grid: GridContainer
var _cells: Array = []
var _pos := Vector2i.ZERO
var _start := Vector2i.ZERO
var _target := Vector2i.ZERO
var _grid_size := Vector2i(3, 3)
var _pending: Array[String] = []
var _orders_label: Label
var _run_button: Button
var _reset_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	_orders_label = Label.new()
	_orders_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_orders_label.add_theme_font_size_override("font_size", 30)
	_orders_label.text = "Mission : "
	box.add_child(_orders_label)

	_grid = GridContainer.new()
	_grid.columns = 3
	box.add_child(_grid)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 20)
	box.add_child(controls)

	var up := GAME_BUTTON.instantiate()
	up.text = "▲ Avance"
	up.pressed.connect(func(): _add_order("avant"))
	controls.add_child(up)

	var right := GAME_BUTTON.instantiate()
	right.text = "▶ Droite"
	right.pressed.connect(func(): _add_order("droite"))
	controls.add_child(right)

	var left := GAME_BUTTON.instantiate()
	left.text = "◀ Gauche"
	left.pressed.connect(func(): _add_order("gauche"))
	controls.add_child(left)

	_run_button = GAME_BUTTON.instantiate()
	_run_button.text = "✅ Go robot !"
	_run_button.pressed.connect(_run_orders)
	controls.add_child(_run_button)

	_reset_button = GAME_BUTTON.instantiate()
	_reset_button.text = "↺ Recommencer"
	_reset_button.pressed.connect(_reset_orders)
	controls.add_child(_reset_button)


func present_item(p_item: Resource) -> void:
	super(p_item)
	_grid_size = Vector2i(int(p_item.metadata.get("grid_w", 3)), int(p_item.metadata.get("grid_h", 3)))
	_start = Vector2i(int(p_item.metadata.get("start", [0, 0])[0]), int(p_item.metadata.get("start", [0, 0])[1]))
	var t: Array = p_item.metadata.get("target", [0, 1])
	_target = Vector2i(int(t[0]), int(t[1]))
	_grid.columns = _grid_size.x
	_orders_label.text = "Mission : %s" % p_item.prompt_text
	_reset_orders()


func spoken_prompt(p_item: Resource) -> String:
	return p_item.prompt_text


func _add_order(dir_name: String) -> void:
	_pending.append(dir_name)
	_refresh_orders()
	AudioMgr.play_click()


func _reset_orders() -> void:
	_pending.clear()
	_pos = _start
	_rebuild_grid()
	_refresh_orders()


func _refresh_orders() -> void:
	var names := []
	for d in _pending:
		names.append(_arrow_of(d))
	_orders_label.text = "Mission : %s\nOrdres : %s" % [item.prompt_text if item else "", " ".join(names)]


func _arrow_of(dir_name: String) -> String:
	match dir_name:
		"avant": return "▲"
		"droite": return "▶"
		"gauche": return "◀"
		"arrière": return "▼"
		_: return "?"


func _run_orders() -> void:
	if item == null or _pending.is_empty():
		return
	var answer := "/".join(_pending)
	_pending.clear()
	_refresh_orders()
	_on_answer_pressed(answer)


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_cells.clear()
	for y in _grid_size.y:
		for x in _grid_size.x:
			var l := Label.new()
			l.custom_minimum_size = Vector2(96, 96)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			l.add_theme_font_size_override("font_size", 48)
			_grid.add_child(l)
			_cells.append(l)
	_refresh_grid()


func _refresh_grid() -> void:
	for y in _grid_size.y:
		for x in _grid_size.x:
			var l: Label = _cells[y * _grid_size.x + x]
			if Vector2i(x, y) == _pos:
				l.text = "🤖"
			elif Vector2i(x, y) == _target:
				l.text = String(item.metadata.get("target_emoji", "🎁")) if item else "🎁"
			else:
				l.text = "·"


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree() and item != null:
		_refresh_grid()
