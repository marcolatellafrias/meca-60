class_name TerminalScreen
extends CanvasLayer

## LA PANTALLA DE UNA TERMINAL DE LA BASE (ver BaseTerminal): se abre con E frente a la consola, encima de todo, y se
## cierra con la cruz, E o Esc. Mientras está abierta el mouse queda suelto y el personaje no lee teclas (UIState).
## EN EL ESTILO MONOCROMO (Mono, docs/conceptual/interfaz.md, 18/11/2026): fondo negro, la letra de trazos en verde y,
## arriba, LA BARRA DE UNA RAYA: el título a la izquierda; a la derecha el capitán, la plata y la cruz; una raya debajo.
## Cada terminal arma su cuerpo en `build_content` (ocupa todo lo de abajo de la raya).

const LAYER := "base_terminal"
## Los márgenes de la pantalla y dónde empieza el cuerpo.
const MARGIN := 32.0
const BODY_TOP := 84.0

## La que está abierta (una sola a la vez).
static var opened: TerminalScreen

var state := BaseState.current
var _root: Control
var _money: MonoText


static func open_screen(screen: TerminalScreen, tree: SceneTree) -> void:
	if is_instance_valid(opened):
		screen.free()
		return
	opened = screen
	tree.root.add_child.call_deferred(screen)
	UIState.open(LAYER)


## El título de la barra (cada terminal el suyo).
func title() -> String:
	return ""


func _ready() -> void:
	layer = 50
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	# el cartel del mouse lo dibuja cada uno (Mono.overlay): sin el panel gris de siempre
	_root.theme = Theme.new()
	_root.theme.set_stylebox("panel", "TooltipPanel", StyleBoxEmpty.new())
	add_child(_root)
	var back := ColorRect.new()
	back.color = Mono.BLACK
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(back)
	_bar()
	var body := build_content()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_left = MARGIN
	body.offset_top = BODY_TOP
	body.offset_right = -MARGIN
	body.offset_bottom = -MARGIN
	_root.add_child(body)
	state.changed.connect(_refresh_all)
	_refresh_all()


## LA BARRA DE UNA RAYA.
func _bar() -> void:
	var name_text := MonoText.make(title(), Mono.TITLE)
	name_text.position = Vector2(MARGIN, 22)
	_root.add_child(name_text)
	var right := HBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -560
	right.offset_right = -MARGIN
	right.offset_top = 20
	right.offset_bottom = 56
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 28)
	_root.add_child(right)
	# sin red todavía: el que abre la terminal es el capitán
	var captain := MonoText.make("CAPITÁN: VOS", Mono.SMALL)
	captain.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_child(captain)
	_money = MonoText.make("", Mono.TEXT)
	_money.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_child(_money)
	var close_button := MonoButton.make("", Vector2(36, 36))
	close_button.is_close = true
	close_button.pressed.connect(close)
	right.add_child(close_button)
	var line := ColorRect.new()
	line.color = Mono.GREEN
	line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	line.offset_left = MARGIN
	line.offset_right = -MARGIN
	line.offset_top = 66
	line.offset_bottom = 68
	_root.add_child(line)


func _exit_tree() -> void:
	if state.changed.is_connected(_refresh_all):
		state.changed.disconnect(_refresh_all)


func _refresh_all() -> void:
	_money.words = "PLATA %d" % state.money
	refresh()


## El cuerpo de la terminal.
func build_content() -> Control:
	return Control.new()


## Vuelve a llenar lo que cambia con el estado.
func refresh() -> void:
	pass


func close() -> void:
	if opened == self:
		opened = null
	UIState.close(LAYER)
	queue_free()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and (key.keycode == KEY_ESCAPE or key.keycode == KEY_E):
		get_viewport().set_input_as_handled()
		close()
