extends Control
## EL MENÚ DE INICIO, el de character-parametric (traído el 11/11/2026): abrir partida o unirse por código de Steam, la
## sesión local para probar con dos instancias, Opciones y Salir. Acá no hay otro juego que el sandbox: la partida ES
## el sandbox (con su fila Multijugador, ver SandboxSession). Se llega al volver de una sesión que se cortó
## (SessionManager.return_to_menu, o «Salir de la partida» en la pausa) o desde la fila Multijugador, para unirse por
## código. Cuando la sesión se establece (session_ready) carga el sandbox; si falla (session_failed) se queda en el menú
## mostrando el error. Si se vuelve sin pedirlo (se cortó la partida), dice por qué (SessionManager.menu_notice).

const SANDBOX_SCENE := "res://game/sandbox/sandbox.tscn"
const GAME_SCENE := SANDBOX_SCENE

var _code_field: LineEdit
var _status: Label
var _host_btn: Button
var _join_btn: Button
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

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 0)
	vbox.add_theme_constant_override("separation", 10)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "MECA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_host_btn = _button("Host", _on_host)
	vbox.add_child(_host_btn)

	var join_row := HBoxContainer.new()
	join_row.add_theme_constant_override("separation", 6)
	_code_field = LineEdit.new()
	_code_field.placeholder_text = "código"
	_code_field.max_length = SessionManager.CODE_LENGTH
	_code_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code_field.text_submitted.connect(func(_t): _on_join())
	join_row.add_child(_code_field)
	_join_btn = _button("Join", _on_join)
	join_row.add_child(_join_btn)
	vbox.add_child(join_row)

	vbox.add_child(_button("Design sandbox", _on_sandbox))
	vbox.add_child(_button("Opciones", _on_options))
	vbox.add_child(_button("Salir", _on_quit))

	# Dev: test multiplayer local con varias instancias (ENet, sin Steam).
	var dev_label := Label.new()
	dev_label.text = "— dev (test local) —"
	dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(dev_label)
	vbox.add_child(_button("Host local", func(): SessionManager.host_local()))
	vbox.add_child(_button("Join local", func(): SessionManager.join_local()))

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status)

	if not SessionManager.enabled:
		_join_btn.disabled = true
		_code_field.editable = false
		_set_status("Steam no disponible — Host corre local")

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b

# ── Acciones ──────────────────────────────────────────────────────────────────

func _on_host() -> void:
	_set_busy("Creando partida…")
	SessionManager.host()

func _on_join() -> void:
	var code := _code_field.text.strip_edges()
	if code == "":
		_set_status("Ingresá un código")
		return
	_set_busy("Uniéndose a %s…" % code.to_upper())
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
	_set_status("Error: " + reason)

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
	_status.text = msg
