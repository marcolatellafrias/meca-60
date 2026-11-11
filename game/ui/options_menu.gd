class_name OptionsMenu
extends CenterContainer

## LA PANTALLA DE OPCIONES, colgada del menú de pausa (como en character-parametric): el volumen, la sensibilidad del
## mouse, el campo de visión y la pantalla completa. Cada cambio se aplica y se guarda en el acto (GameOptions).
## «Volver» o Escape la cierran.

signal closed()

const WIDTH := 380.0


func _init() -> void:
	name = "Opciones"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style())
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	rows.custom_minimum_size = Vector2(WIDTH, 0.0)
	margin.add_child(rows)
	var title := Label.new()
	title.text = "OPCIONES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(title)

	_slider(rows, "Volumen general", 0.0, 1.0, GameOptions.master_volume, "%d %%", 100.0,
		func(v: float) -> void: GameOptions.set_master(v))
	_slider(rows, "Sensibilidad del mouse", GameOptions.SENSITIVITY_MIN, GameOptions.SENSITIVITY_MAX,
		GameOptions.mouse_sensitivity, "× %.2f", 1.0, func(v: float) -> void: GameOptions.set_sensitivity(v))
	_slider(rows, "Campo de visión", GameOptions.FOV_MIN, GameOptions.FOV_MAX, GameOptions.field_of_view,
		"%d°", 1.0, func(v: float) -> void: GameOptions.set_field_of_view(v))
	var full := CheckBox.new()
	full.text = "Pantalla completa"
	full.button_pressed = GameOptions.fullscreen
	full.focus_mode = Control.FOCUS_NONE
	full.toggled.connect(func(on: bool) -> void: GameOptions.set_fullscreen(on))
	rows.add_child(full)
	rows.add_child(HSeparator.new())
	var back := Button.new()
	back.text = "Volver"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(close)
	rows.add_child(back)


## El fondo de los menús: opaco, para que no se lea lo de atrás (los subtítulos, el panel del sandbox).
static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.14, 0.16)
	style.set_corner_radius_all(6)
	return style


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


## Escape vuelve a la pausa (le llega antes que a ella: está después en el árbol).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Un renglón con su nombre, el valor a la derecha y el deslizador debajo. `shown` multiplica el valor para mostrarlo.
func _slider(rows: VBoxContainer, label_text: String, low: float, high: float, value: float, format: String,
		shown: float, on_change: Callable) -> void:
	var head := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(label)
	var amount := Label.new()
	amount.text = format % (value * shown)
	head.add_child(amount)
	rows.add_child(head)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = 0.01
	slider.value = value
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(v: float) -> void:
		amount.text = format % (v * shown)
		on_change.call(v))
	rows.add_child(slider)
