class_name OptionsMenu
extends MonoWindow

## LA PANTALLA DE OPCIONES, colgada del menú de pausa (como en character-parametric): el volumen, la sensibilidad del
## mouse, el campo de visión y la pantalla completa. Cada cambio se aplica y se guarda en el acto (GameOptions).
## «Volver» o Escape la cierran. En el estilo monocromo (una ventana superpuesta, MonoWindow; 18/11/2026).

signal closed()

const WIDTH := 440.0


func _init() -> void:
	super()
	name = "Opciones"
	content.custom_minimum_size = Vector2(WIDTH, 0.0)
	content.add_child(MonoText.make("OPCIONES", Mono.TITLE))
	_slider(content, "VOLUMEN GENERAL", 0.0, 1.0, GameOptions.master_volume, "%d %%", 100.0,
		func(v: float) -> void: GameOptions.set_master(v))
	_slider(content, "SENSIBILIDAD DEL MOUSE", GameOptions.SENSITIVITY_MIN, GameOptions.SENSITIVITY_MAX,
		GameOptions.mouse_sensitivity, "× %.2f", 1.0, func(v: float) -> void: GameOptions.set_sensitivity(v))
	_slider(content, "CAMPO DE VISIÓN", GameOptions.FOV_MIN, GameOptions.FOV_MAX, GameOptions.field_of_view,
		"%d°", 1.0, func(v: float) -> void: GameOptions.set_field_of_view(v))
	var full := MonoCheck.make("PANTALLA COMPLETA", GameOptions.fullscreen)
	full.toggled.connect(func(on: bool) -> void: GameOptions.set_fullscreen(on))
	content.add_child(full)
	var back := MonoButton.make("VOLVER", Vector2(WIDTH, 46), true)
	back.pressed.connect(close)
	content.add_child(back)


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
	var label := MonoText.make(label_text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(label)
	var amount := MonoText.make(format % (value * shown))
	head.add_child(amount)
	rows.add_child(head)
	var slider := MonoSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.value = value
	slider.custom_minimum_size = Vector2(WIDTH, 30)
	slider.value_changed.connect(func(v: float) -> void:
		amount.words = format % (v * shown)
		on_change.call(v))
	rows.add_child(slider)
