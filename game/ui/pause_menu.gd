extends CanvasLayer
## Menú de pausa in-game (Escape). Overlay que NO frena el mundo (co-op: la simulación
## sigue), solo libera el mouse y bloquea el input de gameplay vía UIState. Muestra la lista
## de jugadores en la partida (nombres de Steam vía el registro de SessionManager).

var _players_box: VBoxContainer
## Lo de la pausa, que se esconde mientras está abierta la pantalla de Opciones (ver OptionsMenu).
var _main: Control
var _options_menu: OptionsMenu = null

func _ready() -> void:
	layer = 80
	visible = false
	UIState.changed.connect(_on_ui_changed)
	SessionManager.players_changed.connect(_refresh_players)
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		UIState.toggle(UIState.PAUSE)
		get_viewport().set_input_as_handled()

func _on_ui_changed() -> void:
	var was_visible := visible
	visible = UIState.is_open(UIState.PAUSE)
	if visible and not was_visible:
		_refresh_players()
	if not visible and is_instance_valid(_options_menu):
		_options_menu.close()

func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_main = center

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.custom_minimum_size = Vector2(240, 0)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var players_title := Label.new()
	players_title.text = "Jugadores"
	vbox.add_child(players_title)
	_players_box = VBoxContainer.new()
	vbox.add_child(_players_box)

	vbox.add_child(HSeparator.new())

	vbox.add_child(_make_button("Reanudar", _resume))
	vbox.add_child(_make_button("Opciones", _options))
	vbox.add_child(_make_button("Salir de la partida", _leave_match))
	vbox.add_child(_make_button("Salir del juego", _quit))

func _refresh_players() -> void:
	if not is_instance_valid(_players_box):
		return
	for child in _players_box.get_children():
		child.queue_free()
	for pid in SessionManager.players:
		var sp: SessionPlayer = SessionManager.players[pid]
		var display := sp.steam_name if sp.steam_name != "" else "Jugador %d" % pid
		var label := Label.new()
		label.text = "• %s (vos)" % display if sp.is_local else "• %s" % display
		_players_box.add_child(label)

func _make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

func _resume() -> void:
	UIState.close(UIState.PAUSE)

## La pantalla de Opciones en lugar de la pausa; Escape o «Volver» vuelven a la pausa.
func _options() -> void:
	if is_instance_valid(_options_menu):
		return
	_options_menu = OptionsMenu.new()
	_options_menu.closed.connect(func() -> void: _main.visible = true)
	_main.visible = false
	add_child(_options_menu)

## Deja la sesión y vuelve al main menu (sin cerrar el juego).
func _leave_match() -> void:
	UIState.close(UIState.PAUSE)
	SessionManager.return_to_menu()

func _quit() -> void:
	get_tree().quit()
