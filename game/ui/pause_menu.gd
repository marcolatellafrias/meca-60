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

## EN EL ESTILO MONOCROMO (Mono, 18/11/2026): una ventana superpuesta (todo lo de atrás, atenuado con trama) con el
## título, los jugadores y los botones; seguir es la acción principal, llena.
func _build() -> void:
	var window := MonoWindow.new()
	add_child(window)
	_main = window
	window.content.add_child(MonoText.make("PAUSA", Mono.TITLE))
	window.content.add_child(MonoText.make("JUGADORES", Mono.SMALL))
	_players_box = VBoxContainer.new()
	_players_box.add_theme_constant_override("separation", 6)
	window.content.add_child(_players_box)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	window.content.add_child(gap)
	window.content.add_child(_make_button("SEGUIR", _resume, true))
	window.content.add_child(_make_button("OPCIONES", _options))
	window.content.add_child(_make_button("SALIR DE LA PARTIDA", _leave_match))
	window.content.add_child(_make_button("SALIR DEL JUEGO", _quit))

func _refresh_players() -> void:
	if not is_instance_valid(_players_box):
		return
	for child in _players_box.get_children():
		child.queue_free()
	for pid in SessionManager.players:
		var sp: SessionPlayer = SessionManager.players[pid]
		var display := sp.steam_name if sp.steam_name != "" else "Jugador %d" % pid
		_players_box.add_child(MonoText.make(("· %s (VOS)" % display if sp.is_local else "· %s" % display).to_upper()))

func _make_button(text: String, cb: Callable, primary := false) -> MonoButton:
	var b := MonoButton.make(text, Vector2(340, 46), primary)
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
