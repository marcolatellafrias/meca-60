class_name MechCrewHud
extends CanvasLayer

## LOS CUADRADOS DE LAS TECLAS DE LA MECA (22/11/2026; el usuario: «cuadrados blancos, cuadrados planos, sin border
## radius… con algún símbolo, alguna letra, y que si vos lo apretás se pone de un color, y que si apretás la tecla Alt…
## te figura el mouse… lo pasás por encima de estos cuadrados, te dice qué hace cada uno»). Se ven yendo arriba.

const SIDE := 56.0
const GAP := 6.0
const MARGIN := 24.0
const IDLE := Color.WHITE
const WORKING := Color(0.25, 0.7, 1.0)
const LOCKED := Color(0.95, 0.25, 0.2)

var crew: MechCrew = null

var _squares: Array[ColorRect] = []
var _tip: Label = null
var _peeking := false
var _hovered := -1


func _ready() -> void:
	layer = 30
	var columns := 6
	var rows := 2
	var whole := Vector2(columns, rows) * SIDE + Vector2(columns - 1, rows - 1) * GAP
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.anchor_left = 0.5
	root.anchor_right = 0.5
	root.anchor_top = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = -whole.x * 0.5
	root.offset_right = whole.x * 0.5
	root.offset_top = -whole.y - MARGIN
	root.offset_bottom = -MARGIN
	add_child(root)
	for slot in MechCrew.SLOTS.size():
		_squares.append(_square(root, slot))
	_tip = Label.new()
	var back := StyleBoxFlat.new()
	back.bg_color = IDLE
	back.set_content_margin_all(8.0)
	_tip.add_theme_stylebox_override("normal", back)
	_tip.add_theme_color_override("font_color", Color.BLACK)
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.visible = false
	root.add_child(_tip)
	visible = false


func _square(root: Control, slot: int) -> ColorRect:
	var entry: Dictionary = MechCrew.SLOTS[slot]
	var cell: Vector2i = entry["cell"]
	var square := ColorRect.new()
	square.color = IDLE
	square.size = Vector2(SIDE, SIDE)
	square.position = Vector2(cell) * (SIDE + GAP)
	square.mouse_filter = Control.MOUSE_FILTER_STOP
	square.mouse_entered.connect(func() -> void: _hovered = slot)
	square.mouse_exited.connect(func() -> void:
		if _hovered == slot:
			_hovered = -1)
	root.add_child(square)
	var letter := Label.new()
	letter.text = entry["text"]
	letter.add_theme_color_override("font_color", Color.BLACK)
	letter.add_theme_font_size_override("font_size", 24)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter.set_anchors_preset(Control.PRESET_FULL_RECT)
	square.add_child(letter)
	return square


func _exit_tree() -> void:
	_peek(false)


func _process(_delta: float) -> void:
	var aboard := crew.local_aboard()
	visible = aboard
	_peek(aboard and Input.is_physical_key_pressed(KEY_ALT))
	if not aboard:
		return
	for slot in _squares.size():
		var count := crew.counts[slot]
		_squares[slot].color = IDLE if count == 0 else (WORKING if count == 1 else LOCKED)
	_tip.visible = _peeking and _hovered >= 0
	if _tip.visible:
		_tip.text = MechCrew.SLOTS[_hovered]["tip"]
		_tip.size = Vector2.ZERO
		_tip.position = _squares[_hovered].position + Vector2(0.0, -_tip.get_combined_minimum_size().y - GAP)


## ALT: el mouse aparece mientras se mantiene (ver UIState.peek_mouse). Sólo al cambiar: hay una por meca.
func _peek(on: bool) -> void:
	if on == _peeking:
		return
	_peeking = on
	UIState.peek_mouse(on)
