class_name MatchEnd
extends CanvasLayer

## EL CARTEL DEL FINAL DE LA PELEA (22/11/2026; el usuario: «si me matan puedo reiniciar»): dice quién cayó y cómo se sigue.

var _label: Label = null


## Lo cuelga de `parent` y escucha la vida de la meca y la del jefe.
static func watch(parent: Node, mech: Node, boss: Node) -> void:
	var made := MatchEnd.new()
	made.name = "Final"
	parent.add_child(made)
	var mech_life := Health.of(mech)
	if mech_life != null:
		mech_life.died.connect(made._show.bind("LA MECA CAYÓ"))
	var boss_life := Health.of(boss)
	if boss_life != null:
		boss_life.died.connect(made._show.bind("JEFE DERROTADO"))


func _ready() -> void:
	layer = 40
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = 90.0
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 34)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 8)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	add_child(_label)


func _show(title: String) -> void:
	if _label.visible:
		return
	var next := "F6 para reiniciar" if BaseState.is_captain(get_tree()) else "El host puede reiniciar"
	_label.text = "%s\n%s" % [title, next]
	_label.visible = true
