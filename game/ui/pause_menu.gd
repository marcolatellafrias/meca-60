extends CanvasLayer

## EL MENÚ DE PAUSA (autoload `PauseMenu`): Escape lo abre y lo cierra. Como el juego es de un jugador, PAUSA DE
## VERDAD: el árbol se detiene y el mouse se suelta. Reanudar, Opciones (OptionsMenu) y Salir del juego. Es el de
## character-parametric sin lo de la red, traído del taxi sin lo de la voz.
##
## Al arrancar carga las opciones guardadas (GameOptions), así valen desde el primer cuadro en cualquier escena.

var _main: Control = null
var _options_menu: OptionsMenu = null
var _mouse_before := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameOptions.load_and_apply()
	_build()


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		set_open(not visible)
		get_viewport().set_input_as_handled()


func set_open(on: bool) -> void:
	if on == visible:
		return
	visible = on
	get_tree().paused = on
	if on:
		_mouse_before = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if is_instance_valid(_options_menu):
			_options_menu.close()
		Input.mouse_mode = _mouse_before


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_main = center
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", OptionsMenu.panel_style())
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(240.0, 0.0)
	margin.add_child(column)
	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	column.add_child(HSeparator.new())
	column.add_child(_button("Reanudar", func() -> void: set_open(false)))
	column.add_child(_button("Opciones", _options))
	column.add_child(_button("Salir del juego", func() -> void: get_tree().quit()))


func _button(text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_press)
	return button


## Las opciones en lugar de la pausa; Escape o «Volver» vuelven a la pausa.
func _options() -> void:
	if is_instance_valid(_options_menu):
		return
	_options_menu = OptionsMenu.new()
	_options_menu.closed.connect(func() -> void: _main.visible = true)
	_main.visible = false
	add_child(_options_menu)
