extends Control
## EL MENÚ DE INICIO, el de character-parametric (traído el 11/11/2026): abrir partida o unirse por código de Steam, la
## sesión local para probar con dos instancias, Opciones y Salir. Desde el 18/11/2026 la partida es LA BASE (BaseWorld);
## el sandbox, con su propio botón (y su fila Multijugador, ver SandboxSession). Se llega al volver de una sesión que se cortó
## (SessionManager.return_to_menu, o «Salir de la partida» en la pausa) o desde la fila Multijugador, para unirse por
## código. Cuando la sesión se establece (session_ready) carga el sandbox; si falla (session_failed) se queda en el menú
## mostrando el error. Si se vuelve sin pedirlo (se cortó la partida), dice por qué (SessionManager.menu_notice).

const SANDBOX_SCENE := "res://game/sandbox/sandbox.tscn"
## La partida es la base (ver BaseWorld, docs/technical/flujo-de-partida.md); el sandbox, aparte, con su botón.
const GAME_SCENE := "res://game/base/base_world.tscn"

var _code_field: MonoField
var _status: MonoText
var _host_btn: MonoButton
var _join_btn: MonoButton
## La ventana de «unirse con código», abierta, o null.
var _join_window: MonoWindow = null
## La pantalla de Opciones abierta, o null (ver OptionsMenu).
var _options_menu: OptionsMenu = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# En el menú el mouse tiene que estar visible; se recaptura al entrar al juego.
	UIState.open(UIState.MENU)
	# Lo que el jugador eligió en Opciones, guardado en esta máquina: el menú es la escena con la que arranca el juego.
	GameOptions.load_and_apply()
	_build()
	# Por qué se volvió al menú, si no lo pidió el jugador (ver SessionManager.menu_notice).
	if SessionManager.menu_notice != "":
		_set_status(SessionManager.menu_notice)
		SessionManager.menu_notice = ""
	SessionManager.session_ready.connect(_on_session_ready)
	SessionManager.session_failed.connect(_on_session_failed)
	# Quien se une carga el mundo antes de conectarse (ver SessionManager._connect_after_world).
	SessionManager.world_requested.connect(_go_to_game)
	# Si Steam nos lanzó con +connect_lobby, la sesión ya se está estableciendo.
	if SessionManager.session_started or SessionManager.is_joining():
		_go_to_game()

## EN EL ESTILO MONOCROMO (Mono, docs/conceptual/interfaz.md, 18/11/2026): fondo negro, el nombre grande, los botones en
## columna (crear partida, la acción principal, llena) y, a la derecha, la meca tramada; «unirse con código» abre una
## ventana superpuesta con el campo.
func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Mono.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var art := _MechArt.new()
	art.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	art.offset_left = -560
	art.offset_right = -80
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	var column := VBoxContainer.new()
	column.position = Vector2(90, 110)
	column.custom_minimum_size = Vector2(380, 0)
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	column.add_child(MonoText.make("MECA", 84.0))
	column.add_child(MonoText.make("UNA SUCURSAL, UNA MECA, HASTA TRES TRIPULANTES", Mono.SMALL))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 20)
	column.add_child(gap)
	_host_btn = _button("CREAR PARTIDA", _on_host, true)
	column.add_child(_host_btn)
	_join_btn = _button("UNIRSE CON CÓDIGO", _open_join)
	column.add_child(_join_btn)
	column.add_child(_button("SANDBOX DE PRUEBAS", _on_sandbox))
	column.add_child(_button("OPCIONES", _on_options))
	column.add_child(_button("SALIR", _on_quit))
	# Dev: test multiplayer local con varias instancias (ENet, sin Steam).
	var dev := HBoxContainer.new()
	dev.add_theme_constant_override("separation", 10)
	dev.add_child(_small_button("HOST LOCAL", func() -> void: SessionManager.host_local()))
	dev.add_child(_small_button("JOIN LOCAL", func() -> void: SessionManager.join_local()))
	column.add_child(dev)
	_status = MonoText.make("", Mono.SMALL)
	column.add_child(_status)

	if not SessionManager.enabled:
		_join_btn.disabled = true
		_set_status("STEAM NO DISPONIBLE: CREAR PARTIDA CORRE LOCAL")

func _button(text: String, cb: Callable, primary := false) -> MonoButton:
	var b := MonoButton.make(text, Vector2(380, 50), primary)
	b.pressed.connect(cb)
	return b

func _small_button(text: String, cb: Callable) -> MonoButton:
	var b := MonoButton.make(text, Vector2(185, 36))
	b.pressed.connect(cb)
	return b

## LA VENTANA DE «UNIRSE CON CÓDIGO»: el campo y, abajo, cancelar y unirse.
func _open_join() -> void:
	if is_instance_valid(_join_window):
		return
	_join_window = MonoWindow.new()
	add_child(_join_window)
	_join_window.content.add_child(MonoText.make("UNIRSE CON CÓDIGO", Mono.TITLE))
	_code_field = MonoField.new()
	_code_field.placeholder = "CÓDIGO"
	_code_field.custom_minimum_size = Vector2(460, 64)
	_code_field.edit.max_length = SessionManager.CODE_LENGTH
	_code_field.submitted.connect(func(_t: String) -> void: _on_join())
	_join_window.content.add_child(_code_field)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	var cancel := MonoButton.make("CANCELAR", Vector2(220, 46))
	cancel.pressed.connect(_close_join)
	buttons.add_child(cancel)
	var join := MonoButton.make("UNIRSE", Vector2(220, 46), true)
	join.pressed.connect(_on_join)
	buttons.add_child(join)
	_join_window.content.add_child(buttons)
	_code_field.edit.grab_focus.call_deferred()

func _close_join() -> void:
	if is_instance_valid(_join_window):
		_join_window.queue_free()
	_join_window = null


## LA MECA TRAMADA de la derecha (un placeholder de ilustración).
class _MechArt extends Control:
	func _init() -> void:
		Mono.prepare(self)

	func _draw() -> void:
		var c := size.x * 0.5
		var top := size.y * 0.22
		for part: Rect2 in [Rect2(c - 120, top, 240, 280), Rect2(c - 200, top + 20, 64, 310), Rect2(c + 136, top + 20, 64, 310),
				Rect2(c - 80, top + 280, 64, 220), Rect2(c + 16, top + 280, 64, 220)]:
			Mono.dots(self, part, Mono.QUARTER)
			Mono.frame(self, part)

# ── Acciones ──────────────────────────────────────────────────────────────────

func _on_host() -> void:
	_set_busy("CREANDO PARTIDA…")
	SessionManager.host()

func _on_join() -> void:
	if not is_instance_valid(_code_field):
		return
	var code := _code_field.text().strip_edges()
	if code == "":
		_set_status("INGRESÁ UN CÓDIGO")
		return
	_close_join()
	_set_busy("UNIÉNDOSE A %s…" % code.to_upper())
	SessionManager.join_by_code(code)

func _on_sandbox() -> void:
	UIState.close(UIState.MENU)  # el sandbox arranca con el mouse capturado, como el juego
	get_tree().change_scene_to_file(SANDBOX_SCENE)

func _on_options() -> void:
	if is_instance_valid(_options_menu):
		return
	_options_menu = OptionsMenu.new()
	add_child(_options_menu)

func _on_quit() -> void:
	get_tree().quit()

# ── Sesión ────────────────────────────────────────────────────────────────────

func _on_session_ready(_id: int) -> void:
	_go_to_game()

func _on_session_failed(reason: String) -> void:
	_set_idle()
	_set_status("ERROR: " + reason.to_upper())

func _go_to_game() -> void:
	UIState.close(UIState.MENU)  # el juego arranca con el mouse capturado
	get_tree().change_scene_to_file(GAME_SCENE)

# ── UI helpers ────────────────────────────────────────────────────────────────

func _set_busy(msg: String) -> void:
	_host_btn.disabled = true
	_join_btn.disabled = true
	_set_status(msg)

func _set_idle() -> void:
	_host_btn.disabled = false
	_join_btn.disabled = not SessionManager.enabled

func _set_status(msg: String) -> void:
	_status.words = msg
