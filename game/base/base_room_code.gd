class_name BaseRoomCode
extends CanvasLayer

## EL CÓDIGO DE LA SALA (23/11/2026): el host lo ve arriba al medio para pasárselo a su amigo, mientras todavía se puede unir
## alguien (hasta abrir la esclusa, ver SessionManager.close_to_new_players).

const TOP := 14.0

var _label: Label = null


func _ready() -> void:
	name = "Codigo de sala"
	layer = 28
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = TOP
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _process(_delta: float) -> void:
	var code := SessionManager.lobby_code
	_label.visible = SessionManager.is_host and not code.is_empty() and not SessionManager.closed
	if _label.visible:
		_label.text = "CÓDIGO DE SALA: %s" % code
